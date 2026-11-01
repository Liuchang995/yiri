import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/date_utils.dart';
import '../../models/poem.dart';

/// 每日在线诗词缓存。写在应用支持目录，不占用 shared_preferences
/// （偏好里只允许保存主题模式）。
class PoetryCacheStore {
  static const String _fileName = 'poetry_cache.json';

  static Future<File> _file() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'yiri'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File(p.join(directory.path, _fileName));
  }

  static Future<Poem?> read(DateTime date) async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      if (decoded['date'] != dateKey(date)) return null;
      final poemJson = decoded['poem'];
      if (poemJson is! Map) return null;
      final poem = Poem.fromJson(Map<String, dynamic>.from(poemJson));
      return poem.lines.isEmpty ? null : poem;
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(Poem poem, {DateTime? now}) async {
    try {
      final file = await _file();
      await file.writeAsString(
        jsonEncode({
          'date': dateKey(now ?? DateTime.now()),
          'poem': poem.toJson(),
        }),
        flush: true,
      );
    } catch (_) {
      // 缓存失败不影响开屏。
    }
  }
}
