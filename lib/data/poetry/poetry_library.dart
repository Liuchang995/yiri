import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/poem.dart';

const String _assetPath = 'assets/poetry.json';

const Poem kFallbackPoem = Poem(
  title: '静夜思',
  dynasty: '唐',
  author: '李白',
  lines: ['床前明月光，疑是地上霜。', '举头望明月，低头思故乡。'],
);

class PoetryAssetLibrary {
  static Future<PoetryLibrary> load() async {
    final raw = await rootBundle.loadString(_assetPath);
    return PoetryAssetLibrary.parse(raw);
  }

  static PoetryLibrary parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('诗词资源格式不正确');
    }
    final poems = <Poem>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final poem = Poem.fromJson(Map<String, dynamic>.from(item));
      if (poem.lines.isNotEmpty) poems.add(poem);
    }
    if (poems.isEmpty) {
      return const PoetryLibrary([kFallbackPoem]);
    }
    return PoetryLibrary(List.unmodifiable(poems));
  }
}
