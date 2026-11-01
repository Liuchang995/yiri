import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/date_utils.dart';
import '../../data/schedule/schedule_store.dart';
import 'home_actions.dart';
import 'mini_month_calendar.dart';

class FuturePage extends ConsumerStatefulWidget {
  const FuturePage({super.key});

  @override
  ConsumerState<FuturePage> createState() => _FuturePageState();
}

class _FuturePageState extends ConsumerState<FuturePage> {
  DateTime _selected = dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final store = ref.read(scheduleStoreProvider);
    final marked = store.allMarkedDates();
    final items = store.read(_selected);
    final calendarHeight =
        (MediaQuery.sizeOf(context).height * 0.6).clamp(300.0, 520.0);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                SizedBox(
                  height: 52,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 4,
                        top: 2,
                        child: HomeMenuButton(displayedMonth: _selected),
                      ),
                      Center(
                        child: Text(
                          '将来',
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Positioned(
                        right: 4,
                        top: 2,
                        child: HomeThemeButton(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Column(
                      children: [
                        SizedBox(
                          height: calendarHeight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: MiniMonthCalendar(
                              initialMonth: _selected,
                              markedDates: marked,
                              selectedDate: _selected,
                              onDateTap: (date) =>
                                  setState(() => _selected = dateOnly(date)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildList(context, items, store),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<ScheduleItem> items,
    ScheduleStore store,
  ) {
    final colors = context.colors;
    final now = dateOnly(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Row(
            children: [
              Text(
                _selected == now
                    ? '今天'
                    : '${_selected.month}月${_selected.day}日',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addSchedule(store, items),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('添加'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.primary,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 56),
            child: Center(
              child: Text(
                '这一天还没有日程',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 12,
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.divider),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            items[index].title,
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _removeSchedule(
                            store,
                            items,
                            items[index],
                          ),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 17,
                            color: colors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index != items.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _addSchedule(
    ScheduleStore store,
    List<ScheduleItem> existing,
  ) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('添加日程'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '只写标题即可'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty || !mounted) return;
    await store.write(_selected, [
      ...existing,
      ScheduleItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: trimmed,
      ),
    ]);
    if (mounted) setState(() {});
  }

  Future<void> _removeSchedule(
    ScheduleStore store,
    List<ScheduleItem> existing,
    ScheduleItem item,
  ) async {
    await store.write(
      _selected,
      existing.where((entry) => entry.id != item.id).toList(),
    );
    if (mounted) setState(() {});
  }
}
