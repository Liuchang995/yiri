import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/date_utils.dart';
import '../../core/widgets.dart';
import '../../data/database/diary_repository.dart';
import '../../models/diary_entry.dart';
import '../backup/backup_models.dart';
import '../backup/export_flow.dart';
import '../backup/import_flow.dart';
import '../theme/theme_controller.dart';
import '../theme/theme_reveal.dart';
import 'month_picker_sheet.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key, this.fadeOnMount = false});

  final bool fadeOnMount;

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  static const int _firstYear = 2000;
  static const int _pageCount = 2401;

  late DateTime _now;
  late DateTime _displayedMonth;
  late final PageController _pageController;
  DateTime? _pulseDate;
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _displayedMonth = DateTime(_now.year, _now.month);
    _pageController = PageController(
      initialPage: _indexForMonth(_displayedMonth),
    );
  }

  int _indexForMonth(DateTime month) =>
      (month.year - _firstYear) * 12 + month.month - 1;

  DateTime _monthForIndex(int index) =>
      DateTime(_firstYear + index ~/ 12, index % 12 + 1);

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openDate(DateTime date) async {
    if (isFutureDay(date, now: DateTime.now())) return;
    final saved = await context.push<bool>('/editor?date=${dateKey(date)}');
    if (!mounted || saved != true) return;
    _pulseTimer?.cancel();
    setState(() => _pulseDate = dateOnly(date));
    _pulseTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _pulseDate = null);
    });
  }

  Future<void> _showMenu() async {
    final action = await showModalBottomSheet<_MenuAction>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => const _BackupMenuSheet(),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _MenuAction.exportAll:
        await ExportFlow.start(context, scope: const ExportScope.all());
      case _MenuAction.exportMonth:
        final month = await showMonthPicker(
          context,
          initialMonth: _displayedMonth,
          lastMonth: DateTime(_now.year, _now.month),
        );
        if (!mounted || month == null) return;
        await ExportFlow.start(context, scope: ExportScope.month(month));
      case _MenuAction.importBackup:
        await ImportFlow.start(context);
        if (mounted) ref.invalidate(diaryEntriesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(diaryEntriesProvider);
    final entries = entriesAsync.asData?.value ?? const <DiaryEntry>[];
    final entriesByDate = <String, DiaryEntry>{
      for (final entry in entries) entry.dateKeyValue: entry,
    };
    final colors = context.colors;
    final now = DateTime.now();

    final content = Scaffold(
      backgroundColor: colors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.34
                      : 0.18,
                ),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => _openDate(now),
            tooltip: '写今天的日记',
            child: const Icon(Icons.edit_outlined, size: 24),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, pageConstraints) {
            final horizontalPadding = pageConstraints.maxWidth > 560
                ? (pageConstraints.maxWidth - 560) / 2
                : 0.0;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _CalendarHeader(month: _displayedMonth, onMenu: _showMenu),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        for (final label in weekdayLabels)
                          Expanded(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.secondaryText.withValues(
                                  alpha: 0.82,
                                ),
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final naturalGridHeight =
                            ((constraints.maxWidth - 32) / 7) * 6;
                        // 横屏/平板时给下方空状态留出足够空间，避免 6 行
                        // 网格把整页高度吃光。
                        final gridHeight = math
                            .min(
                              naturalGridHeight,
                              math.max(0, constraints.maxHeight - 64),
                            )
                            .toDouble();
                        return Column(
                          children: [
                            SizedBox(
                              height: gridHeight,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: _pageCount,
                                onPageChanged: (index) {
                                  setState(
                                    () =>
                                        _displayedMonth = _monthForIndex(index),
                                  );
                                },
                                itemBuilder: (context, index) {
                                  final month = _monthForIndex(index);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: _MonthGrid(
                                      month: month,
                                      today: now,
                                      entriesByDate: entriesByDate,
                                      pulseDate: _pulseDate,
                                      onTapDate: _openDate,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: entries.isEmpty
                                  ? Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 18,
                                          left: 24,
                                          right: 24,
                                        ),
                                        child: Text(
                                          '从今天开始，留一页给自己',
                                          style: TextStyle(
                                            color: colors.secondaryText
                                                .withValues(alpha: 0.72),
                                            fontSize: 12,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (!widget.fadeOnMount) return content;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: content,
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({required this.month, required this.onMenu});

  final DateTime month;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            top: 4,
            bottom: 4,
            child: TopIconButton(
              icon: Icons.menu_rounded,
              tooltip: '备份与迁移',
              onTap: onMenu,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 10,
            bottom: 10,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 210),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  monthLabel(month),
                  key: ValueKey('${month.year}-${month.month}'),
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            right: 8,
            top: 4,
            bottom: 4,
            child: _ThemeToggleButton(),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggleButton extends ConsumerWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Builder(
      builder: (buttonContext) {
        return TopIconButton(
          icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          tooltip: isDark ? '切换到浅色' : '切换到深色',
          onTap: () {
            final brightness = Theme.of(context).brightness;
            final reveal = ThemeRevealScope.of(context);
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
        );
      },
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.entriesByDate,
    required this.pulseDate,
    required this.onTapDate,
  });

  final DateTime month;
  final DateTime today;
  final Map<String, DiaryEntry> entriesByDate;
  final DateTime? pulseDate;
  final ValueChanged<DateTime> onTapDate;

  @override
  Widget build(BuildContext context) {
    final leading = leadingDayCount(month.year, month.month);
    final days = daysInMonth(month.year, month.month);
    final currentMonth = month.year == today.year && month.month == today.month;
    final todayOnly = DateTime(today.year, today.month, today.day);

    Widget buildCell(int cellIndex) {
      final day = cellIndex - leading + 1;
      if (day < 1 || day > days) {
        return const Expanded(child: SizedBox.shrink());
      }
      final date = DateTime(month.year, month.month, day);
      final key = dateKey(date);
      final isToday = currentMonth && isSameDay(date, today);
      final isFuture = date.isAfter(todayOnly);
      final pulse = pulseDate != null && isSameDay(date, pulseDate!);
      return _DayCell(
        date: date,
        isToday: isToday,
        isFuture: isFuture,
        hasEntry: entriesByDate[key] != null,
        pulse: pulse,
        onTap: isFuture ? null : () => onTapDate(date),
      );
    }

    return Column(
      children: [
        for (var row = 0; row < 6; row++)
          Expanded(
            child: Row(
              children: [
                for (var column = 0; column < 7; column++)
                  buildCell(row * 7 + column),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.isFuture,
    required this.hasEntry,
    required this.pulse,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool isFuture;
  final bool hasEntry;
  final bool pulse;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final numberColor = isToday
        ? colors.onPrimary
        : isFuture
        ? colors.secondaryText.withValues(alpha: 0.34)
        : colors.text;
    final dotColor = isToday ? colors.onPrimary : colors.primary;

    return Expanded(
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: pulse
                ? colors.primary.withValues(alpha: 0.11)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkResponse(
              onTap: onTap,
              radius: 22,
              containedInkWell: true,
              highlightShape: BoxShape.circle,
              splashColor: colors.primary.withValues(alpha: 0.12),
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isToday ? colors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: numberColor,
                          fontSize: 14.5,
                          height: 1,
                          fontWeight: isToday
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (hasEntry) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _MenuAction { exportAll, exportMonth, importBackup }

class _BackupMenuSheet extends StatelessWidget {
  const _BackupMenuSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '备份与迁移',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.archive_outlined,
                title: '导出全部',
                subtitle: '打包所有日记与图片',
                onTap: () => Navigator.of(context).pop(_MenuAction.exportAll),
              ),
              _MenuItem(
                icon: Icons.calendar_month_outlined,
                title: '按月份导出',
                subtitle: '选择一个月单独打包',
                onTap: () => Navigator.of(context).pop(_MenuAction.exportMonth),
              ),
              _MenuItem(
                icon: Icons.unarchive_outlined,
                title: '导入备份',
                subtitle: '从「一日」导出的 zip 恢复',
                onTap: () =>
                    Navigator.of(context).pop(_MenuAction.importBackup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
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
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.field,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 21, color: colors.primary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
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
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colors.secondaryText.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
