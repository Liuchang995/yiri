import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../data/images/app_image_storage.dart';
import '../../models/diary_entry.dart';

class DiaryPreviewCard extends ConsumerWidget {
  const DiaryPreviewCard({super.key, required this.entry, required this.onTap});

  final DiaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(entry: entry),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.date.month}月${entry.date.day}日',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.text, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _subtitle(entry),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (entry.isFavorite)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 2),
                child: Icon(
                  Icons.star_rounded,
                  size: 17,
                  color: colors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _subtitle(DiaryEntry entry) {
    final parts = <String>[
      if (entry.city?.trim().isNotEmpty == true) entry.city!.trim(),
      if (entry.weather?.label.trim().isNotEmpty == true) entry.weather!.label,
      if (entry.content.trim().isNotEmpty)
        entry.content.trim().replaceAll('\n', ' '),
    ];
    return parts.isEmpty ? '没有正文' : parts.join(' · ');
  }
}

class _Thumbnail extends ConsumerWidget {
  const _Thumbnail({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final first = entry.images.isEmpty ? null : entry.images.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 68,
        height: 68,
        child: first == null
            ? DecoratedBox(
                decoration: BoxDecoration(color: colors.field),
                child: Center(
                  child: Text(
                    '${entry.date.day}',
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            : FutureBuilder<String>(
                future: ref.read(appImageStorageProvider).absolutePath(first),
                builder: (context, snapshot) {
                  final path = snapshot.data;
                  if (path == null) {
                    return ColoredBox(color: colors.field);
                  }
                  return Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        ColoredBox(color: colors.field),
                  );
                },
              ),
      ),
    );
  }
}
