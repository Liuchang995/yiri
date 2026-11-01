import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/date_utils.dart';
import '../../models/diary_entry.dart';

final draftStoreProvider = Provider<DraftStore>((ref) => DraftStore());

/// 草稿写在应用私有目录的 JSON 文件里。shared_preferences 只保存主题。
class DraftStore {
  Directory? _cachedDirectory;

  Future<Directory> _directory() async {
    if (_cachedDirectory != null) return _cachedDirectory!;
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'yiri', 'drafts'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    _cachedDirectory = directory;
    return directory;
  }

  Future<File> _file(DateTime date) async {
    final directory = await _directory();
    return File(p.join(directory.path, '${dateKey(date)}.json'));
  }

  Future<void> save(DiaryEntry entry) async {
    try {
      final file = await _file(entry.date);
      await file.writeAsString(jsonEncode(entry.toJson()), flush: true);
    } catch (_) {
      // 草稿失败不应阻塞写作。
    }
  }

  Future<DiaryEntry?> read(DateTime date) async {
    try {
      final file = await _file(date);
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      final entry = DiaryEntry.fromJson(Map<String, dynamic>.from(decoded));
      if (!isSameDay(entry.date, date)) return null;
      return entry;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear(DateTime date) async {
    try {
      final file = await _file(date);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // ignore
    }
  }
}
