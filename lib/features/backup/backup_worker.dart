import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import 'backup_codec.dart';
import 'backup_models.dart';

Map<String, dynamic> _ok(Map<String, dynamic> payload) => {
  'type': 'result',
  ...payload,
};

Map<String, dynamic> _error(Object error) => {
  'type': 'error',
  'message': error is BackupFormatException ? error.message : '$error',
};

void _sendProgress(SendPort port, double value) {
  port.send({'type': 'progress', 'value': value.clamp(0.0, 1.0).toDouble()});
}

/// 在后台 isolate 里打包；主线程只接收百分比。
Future<void> backupExportWorker(Map<String, dynamic> args) async {
  final sendPort = args['sendPort'] as SendPort;
  final outputPath = args['outputPath'] as String;
  final rootPath = args['rootPath'] as String;
  final rawEntries = (args['entries'] as List).cast<Map>();
  ZipFileEncoder? encoder;
  try {
    final outputFile = File(outputPath);
    await outputFile.parent.create(recursive: true);
    if (await outputFile.exists()) await outputFile.delete();

    final prepared = <_PreparedEntry>[];
    var missingImages = 0;
    for (final raw in rawEntries) {
      final entry = Map<String, dynamic>.from(raw);
      final id = (entry['id'] as String?) ?? '';
      final localImages = <String>[
        if (entry['images'] is List)
          for (final image in entry['images'] as List)
            if (image is String) image,
      ];
      final packedNames = <String>[];
      final packedFiles = <String>[];
      for (var i = 0; i < localImages.length; i++) {
        final relative = localImages[i];
        final file = File(p.join(rootPath, relative));
        if (!await file.exists()) {
          missingImages++;
          continue;
        }
        final extension = p.extension(relative);
        final name = BackupCodec.imageFileName(id, i + 1, extension);
        packedNames.add(name);
        packedFiles.add(file.path);
      }
      prepared.add(
        _PreparedEntry(
          raw: entry,
          imageNames: packedNames,
          imagePaths: packedFiles,
        ),
      );
    }

    final manifestEntries = prepared.map((entry) {
      final raw = entry.raw;
      return BackupEntry(
        id: (raw['id'] as String?) ?? '',
        date: (raw['date'] as String?) ?? '',
        title: (raw['title'] as String?),
        content: (raw['content'] as String?) ?? '',
        mood: raw['mood'] is num ? (raw['mood'] as num).round() : null,
        weatherCode: raw['weatherCode'] as String?,
        temperature: raw['temperature'] is num
            ? (raw['temperature'] as num).round()
            : null,
        imageNames: entry.imageNames,
        createdAt:
            (raw['createdAt'] as String?) ?? DateTime.now().toIso8601String(),
        updatedAt:
            (raw['updatedAt'] as String?) ?? DateTime.now().toIso8601String(),
      );
    }).toList();

    final manifest = BackupManifest(
      exportedAt: DateTime.now(),
      entries: manifestEntries,
    );
    final totalSteps =
        1 +
        prepared.length +
        prepared.fold<int>(0, (sum, entry) => sum + entry.imagePaths.length) +
        1;
    var done = 0;

    encoder = ZipFileEncoder();
    encoder.create(outputPath);

    final manifestBytes = utf8.encode(
      BackupCodec.buildManifestJsonString(manifest),
    );
    encoder.addArchiveFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );
    done++;
    _sendProgress(sendPort, done / totalSteps * 0.9);

    for (var i = 0; i < prepared.length; i++) {
      final entry = prepared[i];
      final backupEntry = manifestEntries[i];
      final markdown = BackupCodec.buildMarkdown(
        backupEntry,
        imageNames: entry.imageNames,
      );
      final markdownBytes = utf8.encode(markdown);
      encoder.addArchiveFile(
        ArchiveFile(
          'entries/${backupEntry.date}.md',
          markdownBytes.length,
          markdownBytes,
        ),
      );
      done++;
      _sendProgress(sendPort, done / totalSteps * 0.9);

      for (var j = 0; j < entry.imagePaths.length; j++) {
        await encoder.addFile(
          File(entry.imagePaths[j]),
          'images/${entry.imageNames[j]}',
        );
        done++;
        _sendProgress(sendPort, done / totalSteps * 0.9);
      }
    }

    await encoder.close();
    encoder = null;
    done++;
    _sendProgress(sendPort, 1);

    final size = await outputFile.length();
    final imageCount = prepared.fold<int>(
      0,
      (sum, entry) => sum + entry.imagePaths.length,
    );
    sendPort.send(
      _ok({
        'path': outputPath,
        'fileName': p.basename(outputPath),
        'entries': prepared.length,
        'images': imageCount,
        'missing': missingImages,
        'bytes': size,
      }),
    );
  } catch (error) {
    try {
      encoder?.closeSync();
    } catch (_) {
      // ignore
    }
    try {
      final file = File(outputPath);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // ignore
    }
    sendPort.send(_error(error));
  }
}

class _PreparedEntry {
  _PreparedEntry({
    required this.raw,
    required this.imageNames,
    required this.imagePaths,
  });

  final Map<String, dynamic> raw;
  final List<String> imageNames;
  final List<String> imagePaths;
}

/// 第一阶段：只读取并校验 manifest，供「已存在 N 篇」确认使用。
Future<void> backupReadManifestWorker(Map<String, dynamic> args) async {
  final sendPort = args['sendPort'] as SendPort;
  final zipPath = args['zipPath'] as String;
  InputFileStream? input;
  try {
    input = InputFileStream(zipPath);
    final archive = ZipDecoder().decodeStream(input);
    final manifestFile = archive.find('manifest.json');
    if (manifestFile == null || !manifestFile.isFile) {
      throw const BackupFormatException('压缩包里找不到 manifest.json');
    }
    final bytes = manifestFile.readBytes();
    if (bytes == null) {
      throw const BackupFormatException('manifest.json 无法读取');
    }
    final manifest = BackupCodec.parseManifest(utf8.decode(bytes));
    sendPort.send(
      _ok({
        'manifest': {
          'exportedAt': manifest.exportedAt.toIso8601String(),
          'entries': manifest.entries
              .map((entry) => entry.toManifestJson())
              .toList(),
        },
      }),
    );
  } catch (error) {
    sendPort.send(_error(error));
  } finally {
    input?.close();
  }
}

/// 第二阶段：解包图片到私有目录。数据库写入由 drift 的后台 isolate 执行。
Future<void> backupExtractWorker(Map<String, dynamic> args) async {
  final sendPort = args['sendPort'] as SendPort;
  final zipPath = args['zipPath'] as String;
  final rootPath = args['rootPath'] as String;
  final rawEntries = (args['entries'] as List).cast<Map>();
  InputFileStream? input;
  try {
    final imagesDir = Directory(p.join(rootPath, 'images'));
    await imagesDir.create(recursive: true);
    input = InputFileStream(zipPath);
    final archive = ZipDecoder().decodeStream(input);

    final totalImages = rawEntries.fold<int>(
      0,
      (sum, raw) =>
          sum + ((raw['images'] is List) ? (raw['images'] as List).length : 0),
    );
    var processedImages = 0;
    var missing = 0;
    final resultEntries = <Map<String, dynamic>>[];

    for (final raw in rawEntries) {
      final entry = Map<String, dynamic>.from(raw);
      final names = <String>[
        if (entry['images'] is List)
          for (final name in entry['images'] as List)
            if (name is String) name,
      ];
      final localImages = <String>[];
      for (final name in names) {
        if (p.basename(name) != name ||
            name.contains('..') ||
            !RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(name)) {
          missing++;
          processedImages++;
          _sendProgress(
            sendPort,
            totalImages == 0 ? 0.9 : processedImages / totalImages * 0.88,
          );
          continue;
        }
        final archiveFile = archive.find('images/$name');
        if (archiveFile == null || !archiveFile.isFile) {
          missing++;
          processedImages++;
          _sendProgress(
            sendPort,
            totalImages == 0 ? 0.9 : processedImages / totalImages * 0.88,
          );
          continue;
        }
        final bytes = archiveFile.readBytes();
        if (bytes == null) {
          missing++;
        } else {
          final destination = File(p.join(imagesDir.path, name));
          await destination.writeAsBytes(bytes, flush: true);
          localImages.add(p.posix.join('images', name));
        }
        processedImages++;
        _sendProgress(
          sendPort,
          totalImages == 0 ? 0.9 : processedImages / totalImages * 0.88,
        );
      }
      entry['images'] = localImages;
      resultEntries.add(entry);
    }

    _sendProgress(sendPort, 0.9);
    sendPort.send(
      _ok({
        'entries': resultEntries,
        'images': processedImages - missing,
        'missing': missing,
      }),
    );
  } catch (error) {
    sendPort.send(_error(error));
  } finally {
    input?.close();
  }
}
