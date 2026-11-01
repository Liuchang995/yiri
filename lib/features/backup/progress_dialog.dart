import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

Future<void> showTaskProgressDialog(
  BuildContext context, {
  required String title,
  required ValueNotifier<double> progress,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (context) => _TaskProgressDialog(title: title, progress: progress),
  );
}

class _TaskProgressDialog extends StatefulWidget {
  const _TaskProgressDialog({required this.title, required this.progress});

  final String title;
  final ValueNotifier<double> progress;

  @override
  State<_TaskProgressDialog> createState() => _TaskProgressDialogState();
}

class _TaskProgressDialogState extends State<_TaskProgressDialog>
    with WidgetsBindingObserver {
  bool _background = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final background =
        state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    if (background != _background && mounted) {
      setState(() => _background = background);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: colors.surface,
        title: Text(widget.title),
        content: ValueListenableBuilder<double>(
          valueListenable: widget.progress,
          builder: (context, value, child) {
            final percent = (value.clamp(0.0, 1.0) * 100).round();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value <= 0 ? null : value.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: colors.field,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$percent%',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _background
                      ? '应用在后台，任务会在返回后继续；请勿强制关闭应用。'
                      : '正在本机处理，不会上传任何内容。',
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

void closeTaskProgressDialog(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) navigator.pop();
}

/// 用于需要等待动画稳定的一帧。
Future<void> waitOneFrame() => WidgetsBinding.instance.endOfFrame;
