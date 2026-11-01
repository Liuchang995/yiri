import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../core/app_colors.dart';
import '../../core/widgets.dart';
import '../../models/diary_entry.dart';
import 'backup_models.dart';
import 'backup_service.dart';
import 'progress_dialog.dart';

class ExportFlow {
  static Future<void> start(
    BuildContext context, {
    required ExportScope scope,
  }) async {
    final service = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(backupServiceProvider);

    List<DiaryEntry> entries;
    try {
      entries = await service.collect(scope);
    } catch (error) {
      if (context.mounted) {
        showAppSnackBar(context, _messageFor(error));
      }
      return;
    }
    if (entries.isEmpty) {
      if (context.mounted) showAppSnackBar(context, '没有可导出的日记');
      return;
    }

    final estimatedBytes = await service.estimateBytes(entries);
    if (estimatedBytes > 200 * 1024 * 1024 && context.mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('文件较大'),
          content: Text(
            '本次导出的图片约 ${_formatBytes(estimatedBytes)}，'
            '建议连接充电器后再继续。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('继续导出'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    if (!context.mounted) return;

    final progress = ValueNotifier<double>(0);
    var dialogVisible = true;
    unawaited(
      showTaskProgressDialog(
        context,
        title: '正在打包备份',
        progress: progress,
      ).whenComplete(() => dialogVisible = false),
    );

    BackupExportResult? result;
    Object? failure;
    try {
      result = await service.export(
        scope: scope,
        entries: entries,
        onProgress: (value) => progress.value = value,
      );
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
      showAppSnackBar(context, '导出失败：${_messageFor(failure)}');
      return;
    }
    if (result == null) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _ExportResultSheet(result: result!),
    );
  }
}

class _ExportResultSheet extends StatefulWidget {
  const _ExportResultSheet({required this.result});

  final BackupExportResult result;

  @override
  State<_ExportResultSheet> createState() => _ExportResultSheetState();
}

class _ExportResultSheetState extends State<_ExportResultSheet> {
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? Rect.fromCenter(
              center: MediaQuery.sizeOf(context).center(Offset.zero),
              width: 1,
              height: 1,
            )
          : box.localToGlobal(Offset.zero) & box.size;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(widget.result.path)],
          title: '一日日记备份',
          subject: '一日日记备份',
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (mounted) showAppSnackBar(context, '无法打开系统分享面板');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveToFolder() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final directory = await FilePicker.getDirectoryPath(
        dialogTitle: '选择保存文件夹',
      );
      if (directory == null) return;
      var target = p.join(directory, widget.result.fileName);
      var index = 1;
      while (await File(target).exists()) {
        final base = p.basenameWithoutExtension(widget.result.fileName);
        final extension = p.extension(widget.result.fileName);
        target = p.join(directory, '$base-$index$extension');
        index++;
      }
      await File(widget.result.path).copy(target);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('已保存'),
          content: SelectableText(target),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('好'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) showAppSnackBar(context, '保存失败，请换一个文件夹重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final result = widget.result;
    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
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
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: colors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '导出完成',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '共 ${result.entryCount} 篇 · ${result.imageCount} 张图片 · '
                '${_formatBytes(result.bytes)}',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 13.5,
                  height: 1.6,
                ),
              ),
              if (result.missingImageCount > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '${result.missingImageCount} 张图片文件缺失，已跳过。',
                  style: TextStyle(color: colors.danger, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _share,
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: const Text('系统分享'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _saveToFolder,
                      icon: const Icon(Icons.folder_outlined, size: 18),
                      label: const Text('保存到文件夹'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        minimumSize: const Size(0, 48),
                        side: BorderSide(color: colors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                result.fileName,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.secondaryText, fontSize: 10.5),
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
  final message = error.toString();
  if (message.startsWith('BackupFormatException: ')) {
    return message.replaceFirst('BackupFormatException: ', '');
  }
  if (error is BackupFormatException) return error.message;
  return '请稍后重试';
}
