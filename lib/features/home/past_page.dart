import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/date_utils.dart';
import '../../data/database/diary_repository.dart';
import '../../models/diary_entry.dart';
import 'diary_preview_card.dart';
import 'home_actions.dart';
import 'mini_month_calendar.dart';

class PastPage extends ConsumerStatefulWidget {
  const PastPage({super.key});

  @override
  ConsumerState<PastPage> createState() => _PastPageState();
}

class _PastPageState extends ConsumerState<PastPage> {
  bool _showFavorites = false;
  bool _showBackToTop = false;
  DateTime _selected = dateOnly(DateTime.now());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final visible =
        _showFavorites && _scrollController.offset > 220;
    if (visible != _showBackToTop) {
      setState(() => _showBackToTop = visible);
    }
  }

  void _backToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final entries = ref.watch(diaryEntriesProvider).asData?.value ?? const [];
    final today = dateOnly(DateTime.now());
    final past = entries.where((entry) => entry.date.isBefore(today)).toList();
    final marked = past.map((entry) => entry.dateKeyValue).toSet();
    final favorites = past.where((entry) => entry.isFavorite).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    DiaryEntry? selectedEntry;
    for (final entry in past) {
      if (entry.dateKeyValue == dateKey(_selected)) {
        selectedEntry = entry;
        break;
      }
    }

    final calendarHeight =
        (MediaQuery.sizeOf(context).height * 0.6).clamp(300.0, 520.0);

    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: _showBackToTop
          ? FloatingActionButton.small(
              heroTag: null,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              tooltip: '回到顶部',
              onPressed: _backToTop,
              child: const Icon(Icons.arrow_upward_rounded, size: 19),
            )
          : null,
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
                          '过去',
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ModeSwitch(
                    favorites: _showFavorites,
                    onChanged: (value) =>
                        setState(() => _showFavorites = value),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
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
                              onDateTap: (date) {
                                setState(() => _selected = dateOnly(date));
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_showFavorites)
                          _FavoriteList(entries: favorites)
                        else
                          _SelectedDay(date: _selected, entry: selectedEntry),
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
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.favorites, required this.onChanged});

  final bool favorites;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget item(String label, bool value) {
      final selected = favorites == value;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? colors.text : colors.secondaryText,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.field,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [item('日记', false), item('收藏', true)]),
    );
  }
}

class _SelectedDay extends StatelessWidget {
  const _SelectedDay({required this.date, required this.entry});

  final DateTime date;
  final DiaryEntry? entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${date.month}月${date.day}日',
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (entry == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 42),
              alignment: Alignment.center,
              child: Text(
                '这天没有日记',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 12,
                ),
              ),
            )
          else
            DiaryPreviewCard(
              entry: entry!,
              onTap: () =>
                  context.push('/detail?date=${entry!.dateKeyValue}'),
            ),
        ],
      ),
    );
  }
}

class _FavoriteList extends StatelessWidget {
  const _FavoriteList({required this.entries});

  final List<DiaryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Center(
          child: Text(
            '还没有收藏的日记',
            style: TextStyle(color: colors.secondaryText, fontSize: 12),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            DiaryPreviewCard(
              entry: entries[index],
              onTap: () => context.push(
                '/detail?date=${entries[index].dateKeyValue}',
              ),
            ),
            if (index != entries.length - 1)
              Divider(height: 1, color: colors.divider),
          ],
        ],
      ),
    );
  }
}
