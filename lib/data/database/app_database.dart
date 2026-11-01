import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class DiaryRecords extends Table {
  @override
  String get tableName => 'diary_entries';

  TextColumn get id => text()();
  TextColumn get dateKey => text().unique()();
  TextColumn get title => text().nullable()();
  TextColumn get content => text().withDefault(const Constant(''))();
  IntColumn get mood => integer().nullable()();
  TextColumn get weatherCode => text().nullable()();
  IntColumn get temperature => integer().nullable()();
  TextColumn get images => text().withDefault(const Constant('[]'))();
  TextColumn get city => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [DiaryRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS diary_entries_date_key '
        'ON diary_entries (date_key)',
      );
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 2) {
        await migrator.addColumn(diaryRecords, diaryRecords.city);
        await migrator.addColumn(diaryRecords, diaryRecords.isFavorite);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dataDir = Directory(p.join(appDir.path, 'yiri_data'));
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    final file = File(p.join(dataDir.path, 'diary.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.defaults();
  ref.onDispose(database.close);
  return database;
});
