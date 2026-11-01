import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/date_utils.dart';
import '../../data/database/diary_repository.dart';
import '../../models/diary_entry.dart';
import 'backup_models.dart';
import 'backup_worker.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(diaryRepositoryProvider));
});

class BackupService {
  BackupService(this.repository);

  final DiaryRepository repository;

  Future<List<DiaryEntry>> collect(ExportScope scope) async {
    switch (scope.kind) {
      case ExportKind.all:
        return repository.getAll();
      case ExportKind.month:
        return repository.getMonth(scope.month ?? DateTime.now());
      case ExportKind.single:
        final entry = await repository.getById(scope.entryId ?? '');
        if (entry == null) {
          throw const BackupFormatException('这篇日记已经不存在');
        }
        return [entry];
    }
  }

  Future<int> estimateBytes(List<DiaryEntry> entries) async {
    final root = await getApplicationDocumentsDirectory();
    var total = 0;
    for (final entry in entries) {
      total += entry.content.length * 2 + (entry.title?.length ?? 0) * 2;
      for (final relative in entry.images) {
        try {
          final file = File(p.join(root.path, relative));
          if (await file.exists()) total += await file.length();
        } catch (_) {
          // ignore missing
        }
      }
    }
    return total;
  }

  Future<BackupExportResult> export({
    required ExportScope scope,
    required List<DiaryEntry> entries,
    required void Function(double) onProgress,
  }) async {
    final root = await getApplicationDocumentsDirectory();
    final temp = await getTemporaryDirectory();
    final exportDir = Directory(p.join(temp.path, 'yiri_exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final stamp = exportDateStamp(DateTime.now());
    final suffix = switch (scope.kind) {
      ExportKind.all => '全部',
      ExportKind.month => yearMonthStamp(scope.month ?? DateTime.now()),
      ExportKind.single =>
        entries.length == 1 ? dateKey(entries.first.date) : stamp,
    };
    final fileName = '一日-$stamp-$suffix.zip';
    final outputPath = p.join(exportDir.path, fileName);

    final args = <String, dynamic>{
      'outputPath': outputPath,
      'rootPath': root.path,
      'entries': entries.map((entry) => entry.toJson()).toList(),
    };
    final result = await _runWorker(
      backupExportWorker,
      args,
      onProgress: onProgress,
    );
    return BackupExportResult(
      path: result['path'] as String,
      fileName: result['fileName'] as String? ?? fileName,
      entryCount: (result['entries'] as num?)?.toInt() ?? entries.length,
      imageCount: (result['images'] as num?)?.toInt() ?? 0,
      missingImageCount: (result['missing'] as num?)?.toInt() ?? 0,
      bytes: (result['bytes'] as num?)?.toInt() ?? 0,
    );
  }

  Future<BackupManifest> readManifest(String zipPath) async {
    final result = await _runWorker(backupReadManifestWorker, {
      'zipPath': zipPath,
    });
    final rawManifest = result['manifest'];
    if (rawManifest is! Map) {
      throw const BackupFormatException('备份清单无效');
    }
    final manifest = Map<String, dynamic>.from(rawManifest);
    final rawEntries = manifest['entries'];
    if (rawEntries is! List) {
      throw const BackupFormatException('备份清单缺少 entries');
    }
    final entries = rawEntries
        .whereType<Map>()
        .map(
          (raw) => BackupEntry.fromManifestJson(Map<String, dynamic>.from(raw)),
        )
        .toList(growable: false);
    if (entries.isEmpty) {
      throw const BackupFormatException('备份中没有日记');
    }
    return BackupManifest(
      exportedAt:
          DateTime.tryParse((manifest['exportedAt'] as String?) ?? '') ??
          DateTime.now(),
      entries: entries,
    );
  }

  Future<BackupExtractionResult> extract({
    required String zipPath,
    required List<BackupEntry> entries,
    required void Function(double) onProgress,
  }) async {
    final root = await getApplicationDocumentsDirectory();
    final result = await _runWorker(backupExtractWorker, {
      'zipPath': zipPath,
      'rootPath': root.path,
      'entries': entries.map((entry) => entry.toManifestJson()).toList(),
    }, onProgress: onProgress);
    final rawEntries = result['entries'];
    if (rawEntries is! List) {
      throw const BackupFormatException('解包结果无效');
    }
    final extracted = <BackupEntry>[];
    for (final raw in rawEntries.whereType<Map>()) {
      final json = Map<String, dynamic>.from(raw);
      final localImages = <String>[
        if (json['images'] is List)
          for (final image in json['images'] as List)
            if (image is String) image,
      ];
      extracted.add(
        BackupEntry.fromManifestJson({...json, 'images': <String>[]})
            .copyWithLocalImages(localImages),
      );
    }
    return BackupExtractionResult(
      entries: extracted,
      imageCount: (result['images'] as num?)?.toInt() ?? 0,
      missingImageCount: (result['missing'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Map<String, dynamic>> _runWorker(
    Future<void> Function(Map<String, dynamic>) worker,
    Map<String, dynamic> args, {
    void Function(double)? onProgress,
  }) async {
    final receivePort = ReceivePort();
    final completer = Completer<Map<String, dynamic>>();
    StreamSubscription<dynamic>? subscription;
    Isolate? isolate;
    try {
      isolate = await Isolate.spawn<Map<String, dynamic>>(
        worker,
        {...args, 'sendPort': receivePort.sendPort},
        onError: receivePort.sendPort,
        onExit: receivePort.sendPort,
      );
      subscription = receivePort.listen((message) {
        if (message is Map && message['type'] == 'progress') {
          final value = message['value'];
          if (value is num) onProgress?.call(value.toDouble());
          return;
        }
        if (message is Map && message['type'] == 'result') {
          if (!completer.isCompleted) {
            completer.complete(Map<String, dynamic>.from(message));
          }
          return;
        }
        if (message is Map && message['type'] == 'error') {
          if (!completer.isCompleted) {
            completer.completeError(
              BackupFormatException(
                (message['message'] as String?) ?? '备份处理失败',
              ),
            );
          }
          return;
        }
        if (message is List) {
          if (!completer.isCompleted) {
            completer.completeError(const BackupFormatException('后台处理失败'));
          }
        }
      });

      return await completer.future.timeout(
        const Duration(minutes: 15),
        onTimeout: () => throw const BackupFormatException('处理超时，请重试'),
      );
    } finally {
      await subscription?.cancel();
      receivePort.close();
      isolate?.kill(priority: Isolate.immediate);
    }
  }
}

extension on BackupEntry {
  BackupEntry copyWithLocalImages(List<String> localImages) {
    return BackupEntry(
      id: id,
      date: date,
      title: title,
      content: content,
      mood: mood,
      weatherCode: weatherCode,
      temperature: temperature,
      imageNames: localImages,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
