import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yiri/data/poetry/poetry_library.dart';
import 'package:yiri/data/poetry/poetry_remote_source.dart';
import 'package:yiri/models/poem.dart';

void main() {
  late PoetryLibrary library;

  setUpAll(() {
    final raw = File('assets/poetry.json').readAsStringSync();
    library = PoetryAssetLibrary.parse(raw);
  });

  test('内置诗词不少于 60 首且字段完整', () {
    expect(library.poems.length, greaterThanOrEqualTo(60));
    for (final poem in library.poems) {
      expect(poem.title, isNotEmpty);
      expect(poem.author, isNotEmpty);
      expect(poem.dynasty, isNotEmpty);
      expect(poem.lines, isNotEmpty);
    }
  });

  test('同一天永远选中同一首', () {
    final date = DateTime(2025, 6, 12);
    final first = PoetrySelector.pick(library.poems, date);
    final second = PoetrySelector.pick(library.poems, date);
    expect(first, isNotNull);
    expect(first!.title, second!.title);
    expect(first.author, second.author);
  });

  test(' Poem JSON 往返保留所有字段', () {
    const poem = Poem(
      title: '静夜思',
      dynasty: '唐',
      author: '李白',
      lines: ['床前明月光，疑是地上霜。'],
    );
    final decoded = Poem.fromJson(poem.toJson());
    expect(decoded.title, poem.title);
    expect(decoded.dynasty, poem.dynasty);
    expect(decoded.author, poem.author);
    expect(decoded.lines, poem.lines);
    expect(decoded.footer, '唐 · 李白 · 静夜思');
  });

  test('在线诗词按标点拆行', () {
    final lines = splitPoemLines('床前明月光，疑是地上霜。举头望明月，低头思故乡。');
    expect(lines, ['床前明月光，疑是地上霜。', '举头望明月，低头思故乡。']);
  });
}
