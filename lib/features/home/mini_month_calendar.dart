import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';

import '../../core/app_colors.dart';
import '../../core/date_utils.dart';
import '../../core/widgets.dart';

class MiniMonthCalendar extends StatefulWidget {
  const MiniMonthCalendar({
    super.key,
    required this.initialMonth,
    required this.onDateTap,
    this.markedDates = const <String>{},
    this.selectedDate,
  });

  final DateTime initialMonth;
  final ValueChanged<DateTime> onDateTap;
  final Set<String> markedDates;
  final DateTime? selectedDate;

  @override
  State<MiniMonthCalendar> createState() => _MiniMonthCalendarState();
}

class _MiniMonthCalendarState extends State<MiniMonthCalendar> {
  late DateTime _month = DateTime(
    widget.initialMonth.year,
    widget.initialMonth.month,
  );

  void _moveMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Future<void> _showMonthPicker() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthPickerDialog(initialMonth: _month),
    );
    if (picked == null || !mounted) return;
    setState(() => _month = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: 2),
                  TopIconButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: '上个月',
                    onTap: () => _moveMonth(-1),
                  ),
                  Expanded(
                    child: Center(
                      child: InkWell(
                        onTap: _showMonthPicker,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: colors.field,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_month.year}年${_month.month}月',
                                style: TextStyle(
                                  color: colors.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.expand_more_rounded,
                                size: 17,
                                color: colors.secondaryText,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  TopIconButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: '下个月',
                    onTap: () => _moveMonth(1),
                  ),
                  TextButton(
                    onPressed: () {
                      final today = dateOnly(DateTime.now());
                      setState(() => _month = today);
                      widget.onDateTap(today);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('今天', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 22,
              child: Row(
                children: [
                  for (final label in const ['一', '二', '三', '四', '五', '六', '日'])
                    Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: colors.secondaryText.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _MonthGrid(
                month: _month,
                markedDates: widget.markedDates,
                selectedDate: widget.selectedDate,
                onDateTap: widget.onDateTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.initialMonth});

  final DateTime initialMonth;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year = widget.initialMonth.year;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      backgroundColor: colors.surface,
      title: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _year--),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              '$_year 年',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.text, fontSize: 16),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _year++),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        height: 260,
        child: GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: [
            for (var month = 1; month <= 12; month++)
              InkWell(
                onTap: () => Navigator.of(context).pop(DateTime(_year, month)),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        month == widget.initialMonth.month &&
                            _year == widget.initialMonth.year
                        ? colors.primary.withValues(alpha: 0.14)
                        : colors.field,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$month 月',
                    style: TextStyle(color: colors.text, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.markedDates,
    required this.selectedDate,
    required this.onDateTap,
  });

  final DateTime month;
  final Set<String> markedDates;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateTap;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final start = first.subtract(Duration(days: first.weekday - 1));
    final today = dateOnly(DateTime.now());

    return Column(
      children: [
        for (var week = 0; week < 6; week++)
          Expanded(
            child: Row(
              children: [
                for (var weekday = 0; weekday < 7; weekday++)
                  Expanded(
                    child: _DayCell(
                      date: start.add(Duration(days: week * 7 + weekday)),
                      month: month.month,
                      today: today,
                      selected: selectedDate == null
                          ? null
                          : dateOnly(selectedDate!),
                      marked: markedDates.contains(
                        dateKey(start.add(Duration(days: week * 7 + weekday))),
                      ),
                      onTap: onDateTap,
                    ),
                  ),
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
    required this.month,
    required this.today,
    required this.selected,
    required this.marked,
    required this.onTap,
  });

  final DateTime date;
  final int month;
  final DateTime today;
  final DateTime? selected;
  final bool marked;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final inMonth = date.month == month;
    final isToday = date == today;
    final isSelected = selected != null && date == selected;
    String? lunarLabel;
    try {
      final lunar = Lunar.fromDate(date);
      final day = lunar.getDayInChinese();
      if (day == '初一') {
        final monthName = lunar.getMonthInChinese();
        lunarLabel = monthName.endsWith('月') ? monthName : '$monthName月';
      } else {
        lunarLabel = day;
      }
    } catch (_) {
      lunarLabel = null;
    }

    return InkWell(
      onTap: () => onTap(date),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday ? colors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: isSelected && !isToday
                    ? Border.all(color: colors.primary, width: 1)
                    : null,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isToday
                        ? colors.onPrimary
                        : inMonth
                        ? colors.text
                        : colors.secondaryText.withValues(alpha: 0.35),
                    fontSize: 13,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 1),
            SizedBox(
              height: 11,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  lunarLabel ?? '',
                  maxLines: 1,
                  style: TextStyle(
                    color: inMonth
                        ? colors.secondaryText.withValues(alpha: 0.8)
                        : colors.secondaryText.withValues(alpha: 0.25),
                    fontSize: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 3,
              height: 3,
              child: marked
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
