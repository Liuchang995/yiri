import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

Future<DateTime?> showMonthPicker(
  BuildContext context, {
  required DateTime initialMonth,
  required DateTime lastMonth,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) =>
        _MonthPickerSheet(initialMonth: initialMonth, lastMonth: lastMonth),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  const _MonthPickerSheet({
    required this.initialMonth,
    required this.lastMonth,
  });

  final DateTime initialMonth;
  final DateTime lastMonth;

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;

  @override
  void initState() {
    super.initState();
    final clamped = widget.initialMonth.isAfter(widget.lastMonth)
        ? widget.lastMonth
        : widget.initialMonth;
    _year = clamped.year;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canGoPrevious = _year > 2000;
    final canGoNext = _year < widget.lastMonth.year;

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                '选择月份',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: canGoPrevious
                        ? () => setState(() => _year--)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded, size: 24),
                    color: colors.text,
                    disabledColor: colors.secondaryText.withValues(alpha: 0.3),
                    tooltip: '上一年',
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      '$_year 年',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: canGoNext ? () => setState(() => _year++) : null,
                    icon: const Icon(Icons.chevron_right_rounded, size: 24),
                    color: colors.text,
                    disabledColor: colors.secondaryText.withValues(alpha: 0.3),
                    tooltip: '下一年',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisExtent: 52,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final enabled =
                      DateTime(_year, month).isAfter(
                        DateTime(widget.lastMonth.year, widget.lastMonth.month),
                      ) ==
                      false;
                  final selected =
                      _year == widget.initialMonth.year &&
                      month == widget.initialMonth.month;
                  return InkWell(
                    onTap: enabled
                        ? () =>
                              Navigator.of(context).pop(DateTime(_year, month))
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: selected ? colors.primary : colors.field,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '$month 月',
                          style: TextStyle(
                            color: !enabled
                                ? colors.secondaryText.withValues(alpha: 0.3)
                                : selected
                                ? colors.onPrimary
                                : colors.text,
                            fontSize: 13.5,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
