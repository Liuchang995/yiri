import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lunar/lunar.dart';

import '../../core/app_colors.dart';
import '../../core/date_utils.dart';
import '../../core/widgets.dart';
import '../../data/database/diary_repository.dart';
import '../../data/schedule/schedule_store.dart';
import '../../data/startup_state.dart';
import '../../data/weather/weather_service.dart';
import '../../models/diary_entry.dart';
import 'home_actions.dart';

class TodayPage extends ConsumerStatefulWidget {
  const TodayPage({super.key});

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage> {
  bool _poemExpanded = false;
  bool _loadingWeather = false;
  WeatherSnapshot? _weather;
  String? _manualCity;

  @override
  void initState() {
    super.initState();
    unawaited(_loadWeather());
  }

  Future<void> _loadWeather({bool requestPermission = false}) async {
    if (_loadingWeather) return;
    setState(() => _loadingWeather = true);
    final snapshot = await ref
        .read(weatherServiceProvider)
        .currentWeather(requestPermission: requestPermission);
    if (!mounted) return;
    setState(() {
      _loadingWeather = false;
      if (snapshot != null) _weather = snapshot;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final startup = ref.watch(startupStateProvider);
    final entries = ref.watch(diaryEntriesProvider).asData?.value ?? const [];
    DiaryEntry? today;
    for (final entry in entries) {
      if (entry.date == dateOnly(now)) {
        today = entry;
        break;
      }
    }
    final schedules = ref
        .read(scheduleStoreProvider)
        .read(dateOnly(now))
        .toList(growable: false);
    final lunar = _lunarLabel(now);
    final city = _manualCity ?? _weather?.city;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 54,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 4,
                          top: 3,
                          child: HomeMenuButton(displayedMonth: now),
                        ),
                        Center(
                          child: Text(
                            '今日',
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
                          top: 3,
                          child: HomeThemeButton(),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 2, 24, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      FadeSlideIn(
                        child: _PoemCard(
                          poem: startup.initialPoem,
                          expanded: _poemExpanded,
                          onToggle: () =>
                              setState(() => _poemExpanded = !_poemExpanded),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${now.month}月${now.day}日',
                                  style: TextStyle(
                                    color: colors.text,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w600,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_weekday(now)} · $lunar',
                                  style: TextStyle(
                                    color: colors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: _loadingWeather
                                ? null
                                : () => _loadWeather(requestPermission: true),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colors.field,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: colors.divider),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: colors.secondaryText,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _weatherLine(city),
                                    style: TextStyle(
                                      color: colors.secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _DiaryCard(
                        entry: today,
                        onWrite: () => context.push(
                          '/editor?date=${dateKey(dateOnly(now))}',
                        ),
                      ),
                      if (schedules.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          '今日日程',
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 11,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final item in schedules)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Container(
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
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  color: colors.text,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _weatherLine(String? city) {
    if (_loadingWeather) return '定位中…';
    final prefix = city?.trim();
    final weather = _weather;
    final suffix = weather == null
        ? '获取天气'
        : weather.temperature == null
        ? weather.code.label
        : '${weather.code.label} ${weather.temperature}°';
    return prefix?.isNotEmpty == true ? '$prefix · $suffix' : suffix;
  }

  String _lunarLabel(DateTime date) {
    try {
      final lunar = Lunar.fromDate(date);
      var month = lunar.getMonthInChinese();
      if (!month.endsWith('月')) month = '$month月';
      return '农历$month${lunar.getDayInChinese()}';
    } catch (_) {
      return '';
    }
  }

  String _weekday(DateTime date) {
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[date.weekday - 1];
  }
}

class _PoemCard extends StatelessWidget {
  const _PoemCard({
    required this.poem,
    required this.expanded,
    required this.onToggle,
  });

  final dynamic poem;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lines = (poem.lines as List).cast<String>();
    final hasMore = lines.length > 3;
    final visible = expanded ? lines : lines.take(3).toList();

    return InkWell(
      onTap: hasMore ? onToggle : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          children: [
            for (final line in visible)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  line,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 17,
                    height: 1.7,
                    fontFamily: 'Songti SC',
                    fontFamilyFallback: const [
                      'Noto Serif SC',
                      'Noto Serif CJK SC',
                      'STSong',
                      'SimSun',
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              '${poem.dynasty} · ${poem.author} · ${poem.title}',
              style: TextStyle(color: colors.secondaryText, fontSize: 11),
            ),
            if (hasMore) ...[
              const SizedBox(height: 6),
              Text(
                expanded ? '收起' : '展开全诗',
                style: TextStyle(color: colors.primary, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  const _DiaryCard({required this.entry, required this.onWrite});

  final DiaryEntry? entry;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasDiary = entry != null;
    final preview = entry?.content.trim().replaceAll('\n', ' ') ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasDiary ? Icons.check_circle_outline : Icons.edit_note,
                size: 18,
                color: hasDiary ? colors.primary : colors.secondaryText,
              ),
              const SizedBox(width: 7),
              Text(
                hasDiary ? '今天已经写过了' : '今天还没有写',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            hasDiary
                ? (preview.isEmpty ? '点下面继续补写。' : preview)
                : '不用写很多，留一页给自己就好。',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 12.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: onWrite,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(hasDiary ? '继续编辑' : '写今日的日记'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
