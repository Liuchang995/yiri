import 'package:dio/dio.dart';

import '../../models/poem.dart';

/// 替换在线诗词源时，只需要：
/// 1. 实现本接口（一个 URL + 一个 JSON 解析器）；
/// 2. 在 [PoetryService.sources] 中替换默认实现。
abstract interface class PoetryRemoteSource {
  String get url;

  Future<Poem?> fetch(Dio dio);
}

/// 默认源一：今日诗词公开接口，无需 Key。
class JinrishiciSource implements PoetryRemoteSource {
  const JinrishiciSource();

  static const String endpoint = 'https://v1.jinrishici.com/all.json';

  @override
  String get url => endpoint;

  @override
  Future<Poem?> fetch(Dio dio) async {
    final response = await dio.get<dynamic>(
      url,
      options: Options(responseType: ResponseType.json),
    );
    final data = response.data;
    if (data is! Map) return null;
    final content = (data['content'] as String?)?.trim();
    if (content == null || content.isEmpty) return null;
    final category = (data['category'] as String?)?.trim() ?? '';
    return Poem(
      title: _firstNonEmpty([data['origin'], '无题']),
      dynasty: _dynastyFrom(category),
      author: _firstNonEmpty([data['author'], '佚名']),
      lines: splitPoemLines(content),
    );
  }

  String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  String _dynastyFrom(String category) {
    final match = RegExp(r'(唐|宋|元|明|清|汉|魏|晋|南北朝|五代)').firstMatch(category);
    return match?.group(1) ?? '诗词';
  }
}

/// 默认源二：一言的「诗词」分类，作为源一失效时的兜底。
class HitokotoPoetrySource implements PoetryRemoteSource {
  const HitokotoPoetrySource();

  static const String endpoint =
      'https://v1.hitokoto.cn/?c=i&encode=json&charset=utf-8';

  @override
  String get url => endpoint;

  @override
  Future<Poem?> fetch(Dio dio) async {
    final response = await dio.get<dynamic>(
      url,
      options: Options(responseType: ResponseType.json),
    );
    final data = response.data;
    if (data is! Map) return null;
    final content = (data['hitokoto'] as String?)?.trim();
    if (content == null || content.isEmpty) return null;
    return Poem(
      title: (data['from'] as String?)?.trim().isNotEmpty == true
          ? (data['from'] as String).trim()
          : '无题',
      dynasty: '诗词',
      author: (data['from_who'] as String?)?.trim().isNotEmpty == true
          ? (data['from_who'] as String).trim()
          : '佚名',
      lines: splitPoemLines(content),
    );
  }
}

List<String> splitPoemLines(String content) {
  final normalized = content.replaceAll('\r\n', '\n').trim();
  final rawLines = normalized
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .expand<String>((line) {
        final sentenceEnds = RegExp(r'[。！？；]').allMatches(line).length;
        if (line.length <= 16 || sentenceEnds <= 1) return [line];
        final matches = RegExp(r'[^。！？；]+[。！？；]?').allMatches(line);
        final pieces = matches
            .map((match) => match.group(0)?.trim() ?? '')
            .where((piece) => piece.isNotEmpty)
            .toList();
        return pieces.isEmpty ? [line] : pieces;
      })
      .toList();
  return rawLines.isEmpty ? [normalized] : rawLines;
}
