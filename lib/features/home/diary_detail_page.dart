import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lunar/lunar.dart';

import '../../core/app_colors.dart';
import '../../core/date_utils.dart';
import '../../core/widgets.dart';
import '../../data/database/diary_repository.dart';
import '../../data/images/app_image_storage.dart';
import '../../models/diary_entry.dart';

class DiaryDetailPage extends ConsumerStatefulWidget {
  const DiaryDetailPage({super.key, required this.date});

  final DateTime date;

  @override
  ConsumerState<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends ConsumerState<DiaryDetailPage> {
  DiaryEntry? _entry;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entry = await ref
        .read(diaryRepositoryProvider)
        .getByDate(widget.date);
    if (!mounted) return;
    setState(() {
      _entry = entry;
      _loading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final entry = _entry;
    if (entry == null) return;
    final saved = await ref
        .read(diaryRepositoryProvider)
        .save(
          entry.copyWith(
            isFavorite: !entry.isFavorite,
            updatedAt: DateTime.now(),
          ),
        );
    if (mounted) setState(() => _entry = saved);
  }

  Future<void> _edit() async {
    final changed = await context.push<bool>(
      '/editor?date=${dateKey(widget.date)}',
    );
    if (changed == true) _load();
  }

  Future<void> _delete() async {
    final entry = _entry;
    if (entry == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除这篇日记？'),
        content: const Text('删除后无法恢复，相关图片也会一起删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(diaryRepositoryProvider).deleteById(entry.id);
    await ref.read(appImageStorageProvider).deletePaths(entry.images);
    if (mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final entry = _entry;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 54,
              child: Stack(
                children: [
                  Positioned(
                    left: 4,
                    top: 3,
                    child: TopIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: '返回',
                      onTap: () => context.pop(),
                    ),
                  ),
                  if (entry != null) ...[
                    Positioned(
                      right: 4,
                      top: 3,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TopIconButton(
                            icon: entry.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: entry.isFavorite ? colors.primary : null,
                            tooltip: entry.isFavorite ? '取消收藏' : '收藏',
                            onTap: _toggleFavorite,
                          ),
                          TopIconButton(
                            icon: Icons.edit_outlined,
                            tooltip: '编辑',
                            onTap: _edit,
                          ),
                          TopIconButton(
                            icon: Icons.delete_outline,
                            tooltip: '删除',
                            onTap: _delete,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const SizedBox.shrink()
                  : entry == null
                  ? Center(
                      child: Text(
                        '这天没有日记',
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : _DetailBody(entry: entry),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final weather = entry.weather;
    final meta = <String>[
      _lunar(entry.date),
      if (entry.city?.trim().isNotEmpty == true) entry.city!.trim(),
      if (weather != null) weather.label,
      if (entry.temperature != null) '${entry.temperature}°',
      if (entry.mood != null) entry.mood!.label,
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(
              '${entry.date.year}年${entry.date.month}月${entry.date.day}日',
              style: TextStyle(
                color: colors.text,
                fontSize: 27,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              meta.join(' · '),
              style: TextStyle(color: colors.secondaryText, fontSize: 12.5),
            ),
            if (entry.title?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 24),
              Text(
                entry.title!.trim(),
                style: TextStyle(
                  color: colors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
            if (entry.content.trim().isNotEmpty) ...[
              const SizedBox(height: 18),
              SelectableText(
                entry.content,
                style: TextStyle(color: colors.text, fontSize: 16, height: 1.9),
              ),
            ],
            if (entry.images.isNotEmpty) ...[
              const SizedBox(height: 22),
              _Images(entry: entry),
            ],
          ],
        ),
      ),
    );
  }

  String _lunar(DateTime date) {
    try {
      final lunar = Lunar.fromDate(date);
      var month = lunar.getMonthInChinese();
      if (!month.endsWith('月')) month = '$month月';
      return '农历$month${lunar.getDayInChinese()}';
    } catch (_) {
      return '';
    }
  }
}

class _Images extends ConsumerWidget {
  const _Images({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entry.images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        return FutureBuilder<String>(
          future: ref
              .read(appImageStorageProvider)
              .absolutePath(entry.images[index]),
          builder: (context, snapshot) {
            final path = snapshot.data;
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: path == null
                  ? ColoredBox(color: colors.field)
                  : Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          ColoredBox(color: colors.field),
                    ),
            );
          },
        );
      },
    );
  }
}
