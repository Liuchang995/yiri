import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_colors.dart';

/// 返回被长按确认删除的索引；未删除返回 null。
Future<int?> showImagePreview(
  BuildContext context, {
  required List<String> absolutePaths,
  required int initialIndex,
}) {
  return showGeneralDialog<int>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '图片预览',
    barrierColor: Colors.black,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondary) => _ImagePreviewDialog(
      absolutePaths: absolutePaths,
      initialIndex: initialIndex,
    ),
    transitionBuilder: (context, animation, secondary, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _ImagePreviewDialog extends StatefulWidget {
  const _ImagePreviewDialog({
    required this.absolutePaths,
    required this.initialIndex,
  });

  final List<String> absolutePaths;
  final int initialIndex;

  @override
  State<_ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<_ImagePreviewDialog> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = AppColors.of(dialogContext);
        return AlertDialog(
          title: const Text('删除这张图片？'),
          content: const Text('保存日记后，这张图片会从本地移除。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: colors.danger),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop(_index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: widget.absolutePaths.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onLongPress: _requestDelete,
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: Image.file(
                          File(widget.absolutePaths[index]),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 4,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 24),
                  color: Colors.white,
                  tooltip: '关闭',
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Column(
                  children: [
                    Text(
                      '${_index + 1} / ${widget.absolutePaths.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '长按删除',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
