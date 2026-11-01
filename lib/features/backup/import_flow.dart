import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/date_utils.dart';
import '../../core/widgets.dart';
import '../../data/database/diary_repository.dart';
import '../../data/images/app_image_storage.dart';
import '../../data/preferences/draft_store.dart';
import '../../models/diary_entry.dart';
import 'backup_models.dart';
import 'backup_service.dart';
import 'progress_dialog.dart';

enum _ImportChoice { skip, overwrite }

class ImportFlow {
  static Future<void> start(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final service = container.read(backupServiceProvider);
    final repository = container.read(diaryRepositoryProvider);
    final storage = container.read(appImageStorageProvider);
    final drafts = container.read(draftStoreProvider);

    PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile(
        dialogTitle: '选择一日备份',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
    } catch (_) {
      if (context.mounted) showAppSnackBar(context, '无法打开文件选择器');
      return;
    }
    if (picked == null) return;
    final zipPath = picked.path;
    if (zipPath == null || !await File(zipPath).exists()) {
      if (context.mounted) showAppSnackBar(context, '无法读取该文件');
      return;
    }

    int? length;
    try {
      length = await picked.length();
    } catch (_) {
      length = null;
    }
    if (length != null && length > 200 * 1024 * 1024 && context.mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('文件较大'),
          content: Text('该备份约 ${_formatBytes(length!)}，建议连接充电器后再导入。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('继续导入'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    if (!context.mounted) return;

    BackupManifest manifest;
    try {
      manifest = await service.readManifest(zipPath);
    } catch (error) {
      if (context.mounted) {
        await _showError(context, '无法导入', _messageFor(error));
      }
      return;
    }
    if (!context.mounted) return;

    final existingEntries = await repository.getAll();
    if (!context.mounted) return;
    final existingByDate = <String, DiaryEntry>{
      for (final entry in existingEntries) entry.dateKeyValue: entry,
    };
    final conflicts = manifest.entries
        .where((entry) => existingByDate.containsKey(entry.date))
        .length;
    final choice = await showModalBottomSheet<_ImportChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _ImportConfirmSheet(
        total: manifest.entries.length,
        conflicts: conflicts,
      ),
    );
    if (choice == null || !context.mounted) return;

    final accepted = choice == _ImportChoice.skip
        ? manifest.entries
              .where((entry) => !existingByDate.containsKey(entry.date))
              .toList(growable: false)
        : manifest.entries;
    if (accepted.isEmpty) {
      showAppSnackBar(context, '所有日记都已存在，没有需要导入的内容');
      return;
    }

    final progress = ValueNotifier<double>(0);
    var dialogVisible = true;
    unawaited(
      showTaskProgressDialog(
        context,
        title: '正在导入备份',
        progress: progress,
      ).whenComplete(() => dialogVisible = false),
    );

    BackupExtractionResult? extracted;
    ImportCommitResult? committed;
    Object? failure;
    try {
      extracted = await service.extract(
        zipPath: zipPath,
        entries: accepted,
        onProgress: (value) => progress.value = value * 0.85,
      );
      final diaryEntries = extracted.entries
          .map((entry) => entry.toDiaryEntry(localImages: entry.imageNames))
          .toList(growable: false);
      progress.value = 0.88;
      committed = await repository.importEntries(
        diaryEntries,
        overwrite: choice == _ImportChoice.overwrite,
        onProgress: (done, total) {
          if (total <= 0) return;
          progress.value = 0.88 + 0.12 * (done / total);
        },
      );
      progress.value = 1;
    } catch (error) {
      failure = error;
    }

    if (context.mounted && dialogVisible) {
      closeTaskProgressDialog(context);
    }
    await Future<void>.delayed(const Duration(milliseconds: 260));
    progress.dispose();
    if (!context.mounted) return;

    if (failure != null) {
      await _showError(context, '导入失败', _messageFor(failure));
      return;
    }
    if (extracted == null || committed == null) return;
    final extractionResult = extracted;
    final importResult = committed;

    for (final entry in accepted) {
      final date = tryParseDateKey(entry.date);
      if (date != null) await drafts.clear(date);
    }

    if (choice == _ImportChoice.overwrite) {
      final oldImages = <String>{
        for (final entry in accepted)
          if (existingByDate[entry.date] != null)
            ...existingByDate[entry.date]!.images,
      };
      final allAfter = await repository.getAll();
      final referenced = allAfter.expand((entry) => entry.images).toSet();
      oldImages.removeAll(referenced);
      if (oldImages.isNotEmpty) {
        await storage.deletePaths(oldImages);
      }
    }
    if (!context.mounted) return;

    final skipped = choice == _ImportChoice.skip ? conflicts : 0;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = context.colors;
        return AlertDialog(
          title: const Text('导入完成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('已导入 ${importResult.imported} 篇，跳过 $skipped 篇。'),
              const SizedBox(height: 6),
              Text('写入 ${extractionResult.imageCount} 张图片。'),
              if (extractionResult.missingImageCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${extractionResult.missingImageCount} 张图片在压缩包中缺失。',
                  style: TextStyle(color: colors.danger, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('好'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showError(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('好'),
          ),
        ],
      ),
    );
  }
}

class _ImportConfirmSheet extends StatelessWidget {
  const _ImportConfirmSheet({required this.total, required this.conflicts});

  final int total;
  final int conflicts;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '导入备份',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                conflicts == 0
                    ? '共 $total 篇，可以全部导入。'
                    : '共 $total 篇，其中 $conflicts 篇日期已存在。',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              if (conflicts == 0)
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_ImportChoice.skip),
                  child: const Text('开始导入'),
                )
              else ...[
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_ImportChoice.skip),
                  child: const Text('跳过已存在'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_ImportChoice.overwrite),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.danger,
                    minimumSize: const Size(0, 48),
                    side: BorderSide(color: colors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('覆盖重写'),
                ),
              ],
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  '取消',
                  style: TextStyle(color: colors.secondaryText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}

String _messageFor(Object error) {
  if (error is BackupFormatException) return error.message;
  final message = error.toString();
  if (message.startsWith('BackupFormatException: ')) {
    return message.replaceFirst('BackupFormatException: ', '');
  }
  return '请确认文件完整后重试';
}
