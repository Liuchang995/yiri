import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/widgets.dart';
import '../../data/database/diary_repository.dart';
import '../backup/backup_models.dart';
import '../backup/export_flow.dart';
import '../backup/import_flow.dart';
import '../calendar/month_picker_sheet.dart';
import '../theme/theme_controller.dart';
import '../theme/theme_reveal.dart';

class HomeMenuButton extends ConsumerWidget {
  const HomeMenuButton({super.key, required this.displayedMonth});

  final DateTime displayedMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TopIconButton(
      icon: Icons.menu_rounded,
      tooltip: '备份与迁移',
      onTap: () => _showMenu(context, ref),
    );
  }

  Future<void> _showMenu(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<_HomeMenuAction>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      useSafeArea: true,
      builder: (context) => const _HomeMenuSheet(),
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case _HomeMenuAction.exportAll:
        await ExportFlow.start(context, scope: const ExportScope.all());
      case _HomeMenuAction.exportMonth:
        final now = DateTime.now();
        final month = await showMonthPicker(
          context,
          initialMonth: displayedMonth,
          lastMonth: DateTime(now.year, now.month),
        );
        if (!context.mounted || month == null) return;
        await ExportFlow.start(context, scope: ExportScope.month(month));
      case _HomeMenuAction.importBackup:
        await ImportFlow.start(context);
        ref.invalidate(diaryEntriesProvider);
    }
  }
}

class HomeThemeButton extends ConsumerWidget {
  const HomeThemeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Builder(
      builder: (buttonContext) => TopIconButton(
        icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        tooltip: isDark ? '切换到浅色' : '切换到深色',
        onTap: () {
          final reveal = ThemeRevealScope.of(context);
          final brightness = Theme.of(context).brightness;
          unawaited(
            reveal.reveal(
              originContext: buttonContext,
              applyNewTheme: () {
                ref
                    .read(themeModeControllerProvider.notifier)
                    .toggleFrom(brightness);
              },
            ),
          );
        },
      ),
    );
  }
}

enum _HomeMenuAction { exportAll, exportMonth, importBackup }

class _HomeMenuSheet extends StatelessWidget {
  const _HomeMenuSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
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
              const SizedBox(height: 18),
              Text(
                '备份与迁移',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.archive_outlined,
                title: '导出全部',
                subtitle: '打包所有日记与图片',
                onTap: () =>
                    Navigator.of(context).pop(_HomeMenuAction.exportAll),
              ),
              _MenuTile(
                icon: Icons.calendar_month_outlined,
                title: '按月份导出',
                subtitle: '选择一个月单独打包',
                onTap: () =>
                    Navigator.of(context).pop(_HomeMenuAction.exportMonth),
              ),
              _MenuTile(
                icon: Icons.unarchive_outlined,
                title: '导入备份',
                subtitle: '从「一日」导出的 zip 恢复',
                onTap: () =>
                    Navigator.of(context).pop(_HomeMenuAction.importBackup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: colors.text, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.secondaryText),
          ],
        ),
      ),
    );
  }
}
