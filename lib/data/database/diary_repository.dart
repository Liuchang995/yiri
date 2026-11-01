import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/date_utils.dart';
import '../../models/diary_entry.dart' as model;
import '../../models/mood.dart';
import 'app_database.dart';

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepository(ref.watch(appDatabaseProvider));
});

final diaryEntriesProvider = StreamProvider.autoDispose<List<model.DiaryEntry>>(
  (ref) {
    return ref.watch(diaryRepositoryProvider).watchAll();
  },
);

class ImportCommitResult {
  const ImportCommitResult({required this.imported, required this.skipped});

  final int imported;
  final int skipped;
}

class DiaryRepository {
  DiaryRepository(this.database);

  final AppDatabase database;
  static const Uuid _uuid = Uuid();

  model.DiaryEntry _toModel(DiaryRecord row) {
    final decodedImages = <String>[];
    try {
      final value = jsonDecode(row.images);
      if (value is List) {
        for (final item in value) {
          if (item is String && item.trim().isNotEmpty) {
            decodedImages.add(item);
          }
        }
      }
    } catch (_) {
      // 单行数据损坏不应拖垮整个日历。
    }
    return model.DiaryEntry(
      id: row.id,
      date: tryParseDateKey(row.dateKey) ?? dateOnly(row.createdAt),
      title: row.title,
      content: row.content,
      mood: Mood.fromValue(row.mood),
      weatherCode: row.weatherCode,
      temperature: row.temperature,
      city: row.city,
      isFavorite: row.isFavorite,
      images: decodedImages,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  DiaryRecordsCompanion _toCompanion(model.DiaryEntry entry) {
    return DiaryRecordsCompanion(
      id: Value(entry.id),
      dateKey: Value(entry.dateKeyValue),
      title: Value(entry.title),
      content: Value(entry.content),
      mood: Value(entry.mood?.value),
      weatherCode: Value(entry.weatherCode),
      temperature: Value(entry.temperature),
      city: Value(entry.city),
      isFavorite: Value(entry.isFavorite),
      images: Value(jsonEncode(entry.images)),
      createdAt: Value(entry.createdAt),
      updatedAt: Value(entry.updatedAt),
    );
  }

  Stream<List<model.DiaryEntry>> watchAll() {
    final query = database.select(database.diaryRecords)
      ..orderBy([(table) => OrderingTerm.desc(table.dateKey)]);
    return query.watch().map((rows) => List.unmodifiable(rows.map(_toModel)));
  }

  Future<List<model.DiaryEntry>> getAll() async {
    final query = database.select(database.diaryRecords)
      ..orderBy([(table) => OrderingTerm.desc(table.dateKey)]);
    final rows = await query.get();
    return rows.map(_toModel).toList(growable: false);
  }

  Future<List<model.DiaryEntry>> getMonth(DateTime month) async {
    final prefix = yearMonthStamp(month);
    final query = database.select(database.diaryRecords)
      ..where((table) => table.dateKey.like('$prefix%'))
      ..orderBy([(table) => OrderingTerm.asc(table.dateKey)]);
    final rows = await query.get();
    return rows.map(_toModel).toList(growable: false);
  }

  Future<model.DiaryEntry?> getByDate(DateTime date) async {
    final query = database.select(database.diaryRecords)
      ..where((table) => table.dateKey.equals(dateKey(date)));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<model.DiaryEntry?> getById(String id) async {
    final query = database.select(database.diaryRecords)
      ..where((table) => table.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<Set<String>> allDateKeys() async {
    final rows = await database.select(database.diaryRecords).get();
    return rows.map((row) => row.dateKey).toSet();
  }

  Future<int> count() async {
    final expression = database.diaryRecords.id.count();
    final query = database.selectOnly(database.diaryRecords)
      ..addColumns([expression]);
    final row = await query.getSingle();
    return row.read(expression) ?? 0;
  }

  /// 一天一篇：dateKey 唯一。无论传入什么 id，最终都按日期更新同一行。
  Future<model.DiaryEntry> save(model.DiaryEntry entry) async {
    return database.transaction(() async {
      final now = DateTime.now();
      final existing = await getByDate(entry.date);
      if (existing != null) {
        final saved = entry.copyWith(
          id: existing.id,
          createdAt: existing.createdAt,
          updatedAt: now,
        );
        await (database.update(database.diaryRecords)
              ..where((table) => table.id.equals(existing.id)))
            .write(_toCompanion(saved));
        return saved;
      }

      var id = entry.id.trim().isEmpty ? _uuid.v4() : entry.id;
      if (await getById(id) != null) id = _uuid.v4();
      final saved = entry.copyWith(id: id, updatedAt: now);
      await database.into(database.diaryRecords).insert(_toCompanion(saved));
      return saved;
    });
  }

  Future<void> deleteById(String id) async {
    await (database.delete(
      database.diaryRecords,
    )..where((table) => table.id.equals(id))).go();
  }

  /// 导入以 manifest 为准。已存在日期可以跳过或覆盖，绝不产生重复。
  Future<ImportCommitResult> importEntries(
    List<model.DiaryEntry> entries, {
    required bool overwrite,
    void Function(int done, int total)? onProgress,
  }) async {
    var imported = 0;
    var skipped = 0;
    final total = entries.length;
    await database.transaction(() async {
      for (final entry in entries) {
        final existing = await getByDate(entry.date);
        if (existing != null && !overwrite) {
          skipped++;
          onProgress?.call(imported + skipped, total);
          continue;
        }
        if (existing != null) {
          await (database.delete(
            database.diaryRecords,
          )..where((table) => table.dateKey.equals(entry.dateKeyValue))).go();
        }
        var id = entry.id.trim().isEmpty ? _uuid.v4() : entry.id;
        if (await getById(id) != null) id = _uuid.v4();
        final toInsert = entry.copyWith(
          id: id,
          updatedAt: entry.updatedAt,
          createdAt: entry.createdAt,
        );
        await database
            .into(database.diaryRecords)
            .insert(_toCompanion(toInsert), mode: InsertMode.insertOrReplace);
        imported++;
        onProgress?.call(imported + skipped, total);
        // 让调用方在 UI 上能短暂让出主线程。
        if (imported % 20 == 0) await Future<void>.delayed(Duration.zero);
      }
    });
    return ImportCommitResult(imported: imported, skipped: skipped);
  }

  Future<void> clearAllForTests() async {
    await database.delete(database.diaryRecords).go();
  }
}
