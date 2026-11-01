import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:yiri/data/database/app_database.dart';
import 'package:yiri/data/database/diary_repository.dart';
import 'package:yiri/models/diary_entry.dart';
import 'package:yiri/models/mood.dart';

bool _sqliteAvailable() {
  try {
    final database = sqlite.sqlite3.openInMemory();
    database.close();
    return true;
  } catch (_) {
    return false;
  }
}

final bool _hasSqlite = _sqliteAvailable();

void main() {
  if (!_hasSqlite) {
    // Windows 开发机若没有可用的 sqlite3.dll，跳过原生数据库测试；
    // Android/iOS 构建会通过 sqlite3 的 native assets 打包自带库。
    test('原生数据库测试', () {}, skip: 'sqlite3 native library unavailable');
    return;
  }

  late AppDatabase database;
  late DiaryRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DiaryRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('一天一篇：按日期更新而不是插入第二条', () async {
    final now = DateTime(2025, 6, 12, 8);
    final first = await repository.save(
      DiaryEntry(
        id: 'first-id',
        date: DateTime(2025, 6, 12),
        title: '第一版',
        content: '一',
        mood: Mood.calm,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final second = await repository.save(
      DiaryEntry(
        id: 'second-id',
        date: DateTime(2025, 6, 12, 23, 59),
        title: '第二版',
        content: '二',
        mood: Mood.good,
        createdAt: now.add(const Duration(hours: 1)),
        updatedAt: now.add(const Duration(hours: 1)),
      ),
    );
    expect(second.id, first.id);
    expect(await repository.count(), 1);
    final loaded = await repository.getByDate(DateTime(2025, 6, 12));
    expect(loaded?.title, '第二版');
    expect(loaded?.content, '二');
    expect(loaded?.mood, Mood.good);
  });

  test('导入支持跳过与覆盖且不产生重复日期', () async {
    final now = DateTime(2025, 6, 12, 8);
    await repository.save(
      DiaryEntry(
        id: 'local',
        date: DateTime(2025, 6, 12),
        content: '本地',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final imported = DiaryEntry(
      id: 'imported',
      date: DateTime(2025, 6, 12),
      content: '备份',
      createdAt: now,
      updatedAt: now,
    );
    final skipped = await repository.importEntries([
      imported,
    ], overwrite: false);
    expect(skipped.skipped, 1);
    expect((await repository.getByDate(DateTime(2025, 6, 12)))?.content, '本地');

    final overwritten = await repository.importEntries([
      imported,
    ], overwrite: true);
    expect(overwritten.imported, 1);
    expect(await repository.count(), 1);
    final loaded = await repository.getByDate(DateTime(2025, 6, 12));
    expect(loaded?.content, '备份');
    expect(loaded?.id, 'imported');
  });
}
