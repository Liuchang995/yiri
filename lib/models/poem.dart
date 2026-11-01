import '../core/date_utils.dart';

class Poem {
  const Poem({
    required this.title,
    required this.dynasty,
    required this.author,
    required this.lines,
  });

  final String title;
  final String dynasty;
  final String author;
  final List<String> lines;

  String get footer => '$dynasty · $author · $title';

  String get plainText => lines.join('\n');

  Map<String, dynamic> toJson() => {
    'title': title,
    'dynasty': dynasty,
    'author': author,
    'lines': lines,
  };

  factory Poem.fromJson(Map<String, dynamic> json) {
    final lines = <String>[
      if (json['lines'] is List)
        for (final line in json['lines'] as List)
          if (line is String && line.trim().isNotEmpty) line.trim(),
    ];
    return Poem(
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : '无题',
      dynasty: (json['dynasty'] as String?)?.trim().isNotEmpty == true
          ? (json['dynasty'] as String).trim()
          : '诗词',
      author: (json['author'] as String?)?.trim().isNotEmpty == true
          ? (json['author'] as String).trim()
          : '佚名',
      lines: lines,
    );
  }
}

class PoetryLibrary {
  const PoetryLibrary(this.poems);

  final List<Poem> poems;

  bool get isEmpty => poems.isEmpty;

  Poem? get fallback => poems.isEmpty ? null : poems.first;
}

/// 同一天永远返回同一首。FNV-1a 比 String.hashCode 更稳定。
class PoetrySelector {
  static Poem? pick(List<Poem> poems, DateTime date) {
    if (poems.isEmpty) return null;
    var hash = 0x811c9dc5;
    for (final unit in dateKey(date).codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return poems[hash % poems.length];
  }
}
