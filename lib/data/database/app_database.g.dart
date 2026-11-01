// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DiaryRecordsTable extends DiaryRecords
    with TableInfo<$DiaryRecordsTable, DiaryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiaryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateKeyMeta = const VerificationMeta(
    'dateKey',
  );
  @override
  late final GeneratedColumn<String> dateKey = GeneratedColumn<String>(
    'date_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<int> mood = GeneratedColumn<int>(
    'mood',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weatherCodeMeta = const VerificationMeta(
    'weatherCode',
  );
  @override
  late final GeneratedColumn<String> weatherCode = GeneratedColumn<String>(
    'weather_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperatureMeta = const VerificationMeta(
    'temperature',
  );
  @override
  late final GeneratedColumn<int> temperature = GeneratedColumn<int>(
    'temperature',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagesMeta = const VerificationMeta('images');
  @override
  late final GeneratedColumn<String> images = GeneratedColumn<String>(
    'images',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dateKey,
    title,
    content,
    mood,
    weatherCode,
    temperature,
    images,
    city,
    isFavorite,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diary_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiaryRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date_key')) {
      context.handle(
        _dateKeyMeta,
        dateKey.isAcceptableOrUnknown(data['date_key']!, _dateKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dateKeyMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    }
    if (data.containsKey('weather_code')) {
      context.handle(
        _weatherCodeMeta,
        weatherCode.isAcceptableOrUnknown(
          data['weather_code']!,
          _weatherCodeMeta,
        ),
      );
    }
    if (data.containsKey('temperature')) {
      context.handle(
        _temperatureMeta,
        temperature.isAcceptableOrUnknown(
          data['temperature']!,
          _temperatureMeta,
        ),
      );
    }
    if (data.containsKey('images')) {
      context.handle(
        _imagesMeta,
        images.isAcceptableOrUnknown(data['images']!, _imagesMeta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiaryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiaryRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      dateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_key'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood'],
      ),
      weatherCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weather_code'],
      ),
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}temperature'],
      ),
      images: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}images'],
      )!,
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DiaryRecordsTable createAlias(String alias) {
    return $DiaryRecordsTable(attachedDatabase, alias);
  }
}

class DiaryRecord extends DataClass implements Insertable<DiaryRecord> {
  final String id;
  final String dateKey;
  final String? title;
  final String content;
  final int? mood;
  final String? weatherCode;
  final int? temperature;
  final String images;
  final String? city;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DiaryRecord({
    required this.id,
    required this.dateKey,
    this.title,
    required this.content,
    this.mood,
    this.weatherCode,
    this.temperature,
    required this.images,
    this.city,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date_key'] = Variable<String>(dateKey);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<int>(mood);
    }
    if (!nullToAbsent || weatherCode != null) {
      map['weather_code'] = Variable<String>(weatherCode);
    }
    if (!nullToAbsent || temperature != null) {
      map['temperature'] = Variable<int>(temperature);
    }
    map['images'] = Variable<String>(images);
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DiaryRecordsCompanion toCompanion(bool nullToAbsent) {
    return DiaryRecordsCompanion(
      id: Value(id),
      dateKey: Value(dateKey),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      content: Value(content),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      weatherCode: weatherCode == null && nullToAbsent
          ? const Value.absent()
          : Value(weatherCode),
      temperature: temperature == null && nullToAbsent
          ? const Value.absent()
          : Value(temperature),
      images: Value(images),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      isFavorite: Value(isFavorite),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DiaryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiaryRecord(
      id: serializer.fromJson<String>(json['id']),
      dateKey: serializer.fromJson<String>(json['dateKey']),
      title: serializer.fromJson<String?>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      mood: serializer.fromJson<int?>(json['mood']),
      weatherCode: serializer.fromJson<String?>(json['weatherCode']),
      temperature: serializer.fromJson<int?>(json['temperature']),
      images: serializer.fromJson<String>(json['images']),
      city: serializer.fromJson<String?>(json['city']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dateKey': serializer.toJson<String>(dateKey),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String>(content),
      'mood': serializer.toJson<int?>(mood),
      'weatherCode': serializer.toJson<String?>(weatherCode),
      'temperature': serializer.toJson<int?>(temperature),
      'images': serializer.toJson<String>(images),
      'city': serializer.toJson<String?>(city),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DiaryRecord copyWith({
    String? id,
    String? dateKey,
    Value<String?> title = const Value.absent(),
    String? content,
    Value<int?> mood = const Value.absent(),
    Value<String?> weatherCode = const Value.absent(),
    Value<int?> temperature = const Value.absent(),
    String? images,
    Value<String?> city = const Value.absent(),
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DiaryRecord(
    id: id ?? this.id,
    dateKey: dateKey ?? this.dateKey,
    title: title.present ? title.value : this.title,
    content: content ?? this.content,
    mood: mood.present ? mood.value : this.mood,
    weatherCode: weatherCode.present ? weatherCode.value : this.weatherCode,
    temperature: temperature.present ? temperature.value : this.temperature,
    images: images ?? this.images,
    city: city.present ? city.value : this.city,
    isFavorite: isFavorite ?? this.isFavorite,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DiaryRecord copyWithCompanion(DiaryRecordsCompanion data) {
    return DiaryRecord(
      id: data.id.present ? data.id.value : this.id,
      dateKey: data.dateKey.present ? data.dateKey.value : this.dateKey,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      mood: data.mood.present ? data.mood.value : this.mood,
      weatherCode: data.weatherCode.present
          ? data.weatherCode.value
          : this.weatherCode,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      images: data.images.present ? data.images.value : this.images,
      city: data.city.present ? data.city.value : this.city,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiaryRecord(')
          ..write('id: $id, ')
          ..write('dateKey: $dateKey, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('mood: $mood, ')
          ..write('weatherCode: $weatherCode, ')
          ..write('temperature: $temperature, ')
          ..write('images: $images, ')
          ..write('city: $city, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dateKey,
    title,
    content,
    mood,
    weatherCode,
    temperature,
    images,
    city,
    isFavorite,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiaryRecord &&
          other.id == this.id &&
          other.dateKey == this.dateKey &&
          other.title == this.title &&
          other.content == this.content &&
          other.mood == this.mood &&
          other.weatherCode == this.weatherCode &&
          other.temperature == this.temperature &&
          other.images == this.images &&
          other.city == this.city &&
          other.isFavorite == this.isFavorite &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DiaryRecordsCompanion extends UpdateCompanion<DiaryRecord> {
  final Value<String> id;
  final Value<String> dateKey;
  final Value<String?> title;
  final Value<String> content;
  final Value<int?> mood;
  final Value<String?> weatherCode;
  final Value<int?> temperature;
  final Value<String> images;
  final Value<String?> city;
  final Value<bool> isFavorite;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DiaryRecordsCompanion({
    this.id = const Value.absent(),
    this.dateKey = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.mood = const Value.absent(),
    this.weatherCode = const Value.absent(),
    this.temperature = const Value.absent(),
    this.images = const Value.absent(),
    this.city = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiaryRecordsCompanion.insert({
    required String id,
    required String dateKey,
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.mood = const Value.absent(),
    this.weatherCode = const Value.absent(),
    this.temperature = const Value.absent(),
    this.images = const Value.absent(),
    this.city = const Value.absent(),
    this.isFavorite = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dateKey = Value(dateKey),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DiaryRecord> custom({
    Expression<String>? id,
    Expression<String>? dateKey,
    Expression<String>? title,
    Expression<String>? content,
    Expression<int>? mood,
    Expression<String>? weatherCode,
    Expression<int>? temperature,
    Expression<String>? images,
    Expression<String>? city,
    Expression<bool>? isFavorite,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dateKey != null) 'date_key': dateKey,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (mood != null) 'mood': mood,
      if (weatherCode != null) 'weather_code': weatherCode,
      if (temperature != null) 'temperature': temperature,
      if (images != null) 'images': images,
      if (city != null) 'city': city,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiaryRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? dateKey,
    Value<String?>? title,
    Value<String>? content,
    Value<int?>? mood,
    Value<String?>? weatherCode,
    Value<int?>? temperature,
    Value<String>? images,
    Value<String?>? city,
    Value<bool>? isFavorite,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DiaryRecordsCompanion(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      weatherCode: weatherCode ?? this.weatherCode,
      temperature: temperature ?? this.temperature,
      images: images ?? this.images,
      city: city ?? this.city,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dateKey.present) {
      map['date_key'] = Variable<String>(dateKey.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (mood.present) {
      map['mood'] = Variable<int>(mood.value);
    }
    if (weatherCode.present) {
      map['weather_code'] = Variable<String>(weatherCode.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<int>(temperature.value);
    }
    if (images.present) {
      map['images'] = Variable<String>(images.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiaryRecordsCompanion(')
          ..write('id: $id, ')
          ..write('dateKey: $dateKey, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('mood: $mood, ')
          ..write('weatherCode: $weatherCode, ')
          ..write('temperature: $temperature, ')
          ..write('images: $images, ')
          ..write('city: $city, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DiaryRecordsTable diaryRecords = $DiaryRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [diaryRecords];
}

typedef $$DiaryRecordsTableCreateCompanionBuilder =
    DiaryRecordsCompanion Function({
      required String id,
      required String dateKey,
      Value<String?> title,
      Value<String> content,
      Value<int?> mood,
      Value<String?> weatherCode,
      Value<int?> temperature,
      Value<String> images,
      Value<String?> city,
      Value<bool> isFavorite,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DiaryRecordsTableUpdateCompanionBuilder =
    DiaryRecordsCompanion Function({
      Value<String> id,
      Value<String> dateKey,
      Value<String?> title,
      Value<String> content,
      Value<int?> mood,
      Value<String?> weatherCode,
      Value<int?> temperature,
      Value<String> images,
      Value<String?> city,
      Value<bool> isFavorite,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DiaryRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $DiaryRecordsTable> {
  $$DiaryRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weatherCode => $composableBuilder(
    column: $table.weatherCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DiaryRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $DiaryRecordsTable> {
  $$DiaryRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weatherCode => $composableBuilder(
    column: $table.weatherCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DiaryRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiaryRecordsTable> {
  $$DiaryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dateKey =>
      $composableBuilder(column: $table.dateKey, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get weatherCode => $composableBuilder(
    column: $table.weatherCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<String> get images =>
      $composableBuilder(column: $table.images, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DiaryRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiaryRecordsTable,
          DiaryRecord,
          $$DiaryRecordsTableFilterComposer,
          $$DiaryRecordsTableOrderingComposer,
          $$DiaryRecordsTableAnnotationComposer,
          $$DiaryRecordsTableCreateCompanionBuilder,
          $$DiaryRecordsTableUpdateCompanionBuilder,
          (
            DiaryRecord,
            BaseReferences<_$AppDatabase, $DiaryRecordsTable, DiaryRecord>,
          ),
          DiaryRecord,
          PrefetchHooks Function()
        > {
  $$DiaryRecordsTableTableManager(_$AppDatabase db, $DiaryRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiaryRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiaryRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiaryRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> dateKey = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int?> mood = const Value.absent(),
                Value<String?> weatherCode = const Value.absent(),
                Value<int?> temperature = const Value.absent(),
                Value<String> images = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiaryRecordsCompanion(
                id: id,
                dateKey: dateKey,
                title: title,
                content: content,
                mood: mood,
                weatherCode: weatherCode,
                temperature: temperature,
                images: images,
                city: city,
                isFavorite: isFavorite,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String dateKey,
                Value<String?> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int?> mood = const Value.absent(),
                Value<String?> weatherCode = const Value.absent(),
                Value<int?> temperature = const Value.absent(),
                Value<String> images = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DiaryRecordsCompanion.insert(
                id: id,
                dateKey: dateKey,
                title: title,
                content: content,
                mood: mood,
                weatherCode: weatherCode,
                temperature: temperature,
                images: images,
                city: city,
                isFavorite: isFavorite,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DiaryRecordsTable, DiaryRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DiaryRecordsTable,
                    DiaryRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DiaryRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiaryRecordsTable,
      DiaryRecord,
      $$DiaryRecordsTableFilterComposer,
      $$DiaryRecordsTableOrderingComposer,
      $$DiaryRecordsTableAnnotationComposer,
      $$DiaryRecordsTableCreateCompanionBuilder,
      $$DiaryRecordsTableUpdateCompanionBuilder,
      (
        DiaryRecord,
        BaseReferences<_$AppDatabase, $DiaryRecordsTable, DiaryRecord>,
      ),
      DiaryRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DiaryRecordsTableTableManager get diaryRecords =>
      $$DiaryRecordsTableTableManager(_db, _db.diaryRecords);
}
