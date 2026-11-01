import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

final appImageStorageProvider = Provider<AppImageStorage>((ref) {
  return AppImageStorage();
});

class AppImageStorage {
  static const String imageFolder = 'images';
  static const int maxLongEdge = 2000;
  static const int jpegQuality = 85;
  static const Uuid _uuid = Uuid();

  Directory? _cachedDirectory;

  Future<Directory> imagesDirectory() async {
    if (_cachedDirectory != null) return _cachedDirectory!;
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, imageFolder));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    _cachedDirectory = directory;
    return directory;
  }

  Future<String> absolutePath(String relativePath) async {
    final directory = await imagesDirectory();
    return p.join(directory.parent.path, relativePath);
  }

  Future<File> fileFor(String relativePath) async {
    return File(await absolutePath(relativePath));
  }

  Future<List<String>> existingOnly(Iterable<String> relativePaths) async {
    final result = <String>[];
    for (final relative in relativePaths) {
      if (await File(await absolutePath(relative)).exists()) {
        result.add(relative);
      }
    }
    return result;
  }

  Future<void> deletePaths(Iterable<String> relativePaths) async {
    for (final relative in relativePaths) {
      try {
        final file = await fileFor(relative);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // 单张图片删不掉不应阻塞日记删除。
      }
    }
  }

  /// 相册/相机返回的临时文件 → 应用私有目录。只保留压缩后的一份。
  Future<String> importAndCompress(String sourcePath) async {
    final directory = await imagesDirectory();
    final filename = '${_uuid.v4()}.jpg';
    final destination = File(p.join(directory.path, filename));
    final relativePath = p.posix.join(imageFolder, filename);

    final sourceBytes = await File(sourcePath).readAsBytes();
    final dimensions = _readImageDimensions(sourceBytes);
    final target = _targetDimensions(dimensions);

    Uint8List? compressed;
    try {
      compressed = await _compressInIsolate(
        sourcePath: sourcePath,
        targetWidth: target.$1,
        targetHeight: target.$2,
      );
    } catch (_) {
      compressed = null;
    }
    compressed ??= await _compressOnPlatformThread(
      sourcePath: sourcePath,
      targetWidth: target.$1,
      targetHeight: target.$2,
    );
    if (compressed == null || compressed.isEmpty) {
      // 压缩失败时保留原图，不能因为插件问题丢掉用户刚拍的照片。
      await destination.writeAsBytes(sourceBytes, flush: true);
    } else {
      await destination.writeAsBytes(compressed, flush: true);
    }
    return relativePath;
  }

  Future<Uint8List?> _compressInIsolate({
    required String sourcePath,
    required int targetWidth,
    required int targetHeight,
  }) async {
    final token = ui.RootIsolateToken.instance;
    if (token == null) return null;
    return Isolate.run<Uint8List?>(() async {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      ui.DartPluginRegistrant.ensureInitialized();
      return FlutterImageCompress.compressWithFile(
        sourcePath,
        minWidth: targetWidth,
        minHeight: targetHeight,
        quality: jpegQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
    });
  }

  Future<Uint8List?> _compressOnPlatformThread({
    required String sourcePath,
    required int targetWidth,
    required int targetHeight,
  }) {
    // flutter_image_compress 的 Android/iOS 实现本身在原生线程解码压缩。
    return FlutterImageCompress.compressWithFile(
      sourcePath,
      minWidth: targetWidth,
      minHeight: targetHeight,
      quality: jpegQuality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
  }

  (int, int) _targetDimensions((int, int)? source) {
    if (source == null) {
      // 未知格式（如部分 HEIC）：只重编码，不做尺寸缩放，避免误放大。
      return (999999, 999999);
    }
    final (width, height) = source;
    if (width <= 0 || height <= 0) return (999999, 999999);
    final longEdge = math.max(width, height);
    if (longEdge <= maxLongEdge) return (width, height);
    if (width >= height) {
      return (maxLongEdge, (height * maxLongEdge / width).round());
    }
    return ((width * maxLongEdge / height).round(), maxLongEdge);
  }
}

(int, int)? _readImageDimensions(Uint8List bytes) {
  try {
    if (bytes.length < 24) return null;
    // PNG: signature + IHDR.
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      final width = _readUint32BE(bytes, 16);
      final height = _readUint32BE(bytes, 20);
      return (width, height);
    }
    // JPEG: scan SOF markers.
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      var offset = 2;
      while (offset + 9 < bytes.length) {
        while (offset < bytes.length && bytes[offset] != 0xFF) {
          offset++;
        }
        while (offset < bytes.length && bytes[offset] == 0xFF) {
          offset++;
        }
        if (offset >= bytes.length) break;
        final marker = bytes[offset++];
        if (marker == 0xD9 || marker == 0xDA) break;
        if (offset + 2 > bytes.length) break;
        final length = (bytes[offset] << 8) | bytes[offset + 1];
        if (length < 2 || offset + length > bytes.length) break;
        final isSof =
            marker >= 0xC0 &&
            marker <= 0xCF &&
            marker != 0xC4 &&
            marker != 0xC8 &&
            marker != 0xCC;
        if (isSof) {
          final height = (bytes[offset + 3] << 8) | bytes[offset + 4];
          final width = (bytes[offset + 5] << 8) | bytes[offset + 6];
          if (width > 0 && height > 0) return (width, height);
        }
        offset += length;
      }
    }
  } catch (_) {
    return null;
  }
  return null;
}

int _readUint32BE(Uint8List bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}
