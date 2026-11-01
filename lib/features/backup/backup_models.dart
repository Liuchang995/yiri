import '../../core/date_utils.dart';
import '../../models/diary_entry.dart';
import '../../models/mood.dart';
import '../../models/weather_code.dart';

const String backupFormat = 'yiri-diary-backup';
const int backupVersion = 1;

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum ExportKind { all, month, single }

class ExportScope {
  const ExportScope._(this.kind, {this.month, this.entryId});

  const ExportScope.all() : this._(ExportKind.all);

  ExportScope.month(DateTime month)
    : this._(ExportKind.month, month: DateTime(month.year, month.month));

  ExportScope.single(String entryId)
    : this._(ExportKind.single, entryId: entryId);

  final ExportKind kind;
  final DateTime? month;
  final String? entryId;
}

class BackupEntry {
  const BackupEntry({
    required this.id,
    required this.date,
    this.title,
    required this.content,
    this.mood,
    this.weatherCode,
    this.temperature,
    required this.imageNames,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String date;
  final String? title;
  final String content;
  final int? mood;
  final String? weatherCode;
  final int? temperature;

  /// zip 内 `images/` 下的文件名，不含目录。
  final List<String> imageNames;
  final String createdAt;
  final String updatedAt;

  Map<String, dynamic> toManifestJson() => {
    'id': id,
    'date': date,
    'title': title,
    'content': content,
    'mood': mood,
    'weatherCode': weatherCode,
    'temperature': temperature,
    'images': imageNames,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory BackupEntry.fromManifestJson(Map<String, dynamic> json) {
    final dateValue = (json['date'] as String?)?.trim() ?? '';
    final parsedDate = tryParseDateKey(dateValue);
    if (parsedDate == null) {
      throw BackupFormatException('日期格式不正确：$dateValue');
    }
    final rawMood = json['mood'];
    final mood = rawMood == null
        ? null
        : (rawMood is num ? rawMood.toInt() : null);
    if (rawMood != null && Mood.fromValue(mood) == null) {
      throw const BackupFormatException('心情枚举值超出范围');
    }
    final weatherCode = (json['weatherCode'] as String?)?.trim();
    if (weatherCode != null &&
        weatherCode.isNotEmpty &&
        WeatherCode.fromCode(weatherCode) == null) {
      throw BackupFormatException('未知天气代码：$weatherCode');
    }
    final rawImages = json['images'];
    final images = <String>[];
    if (rawImages is List) {
      for (final item in rawImages) {
        if (item is! String || item.trim().isEmpty) {
          throw const BackupFormatException('图片列表格式不正确');
        }
        final name = item.trim();
        if (name.contains('/') || name.contains('\\') || name.contains('..')) {
          throw const BackupFormatException('图片文件名不安全');
        }
        if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(name)) {
          throw const BackupFormatException('图片文件名包含非法字符');
        }
        images.add(name);
      }
    } else if (rawImages != null) {
      throw const BackupFormatException('图片列表格式不正确');
    }

    final createdAt = DateTime.tryParse((json['createdAt'] as String?) ?? '');
    final updatedAt = DateTime.tryParse((json['updatedAt'] as String?) ?? '');
    final now = DateTime.now();
    return BackupEntry(
      id: (json['id'] as String?)?.trim() ?? '',
      date: dateKey(parsedDate),
      title: (json['title'] as String?)?.trim().isEmpty == true
          ? null
          : (json['title'] as String?),
      content: (json['content'] as String?) ?? '',
      mood: mood,
      weatherCode: weatherCode == null || weatherCode.isEmpty
          ? null
          : weatherCode,
      temperature: json['temperature'] is num
          ? (json['temperature'] as num).round()
          : null,
      imageNames: images,
      createdAt: (createdAt ?? now).toIso8601String(),
      updatedAt: (updatedAt ?? now).toIso8601String(),
    );
  }

  DiaryEntry toDiaryEntry({required List<String> localImages}) {
    final parsedDate = tryParseDateKey(date) ?? dateOnly(DateTime.now());
    return DiaryEntry(
      id: id,
      date: parsedDate,
      title: title,
      content: content,
      mood: Mood.fromValue(mood),
      weatherCode: weatherCode,
      temperature: temperature,
      images: localImages,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
    );
  }
}

class BackupManifest {
  const BackupManifest({required this.exportedAt, required this.entries});

  final DateTime exportedAt;
  final List<BackupEntry> entries;

  Map<String, dynamic> toJson() => {
    'app': '一日',
    'format': backupFormat,
    'version': backupVersion,
    'exportedAt': exportedAt.toIso8601String(),
    'entries': entries.map((entry) => entry.toManifestJson()).toList(),
  };
}

class BackupExportResult {
  const BackupExportResult({
    required this.path,
    required this.fileName,
    required this.entryCount,
    required this.imageCount,
    required this.missingImageCount,
    required this.bytes,
  });

  final String path;
  final String fileName;
  final int entryCount;
  final int imageCount;
  final int missingImageCount;
  final int bytes;
}

class BackupExtractionResult {
  const BackupExtractionResult({
    required this.entries,
    required this.imageCount,
    required this.missingImageCount,
  });

  final List<BackupEntry> entries;
  final int imageCount;
  final int missingImageCount;
}
