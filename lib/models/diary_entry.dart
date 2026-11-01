import '../core/date_utils.dart';
import 'mood.dart';
import 'weather_code.dart';

const Object _unset = Object();

class DiaryEntry {
  DiaryEntry({
    required this.id,
    required DateTime date,
    this.title,
    required this.content,
    this.mood,
    this.weatherCode,
    this.temperature,
    this.city,
    this.isFavorite = false,
    List<String> images = const [],
    required this.createdAt,
    required this.updatedAt,
  }) : date = dateOnly(date),
       images = List.unmodifiable(images);

  final String id;
  final DateTime date;
  final String? title;
  final String content;
  final Mood? mood;

  /// sunny / cloudy / overcast / rain / snow / fog / wind
  final String? weatherCode;
  final int? temperature;
  final String? city;
  final bool isFavorite;

  /// 应用私有目录下的相对路径。
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get dateKeyValue => dateKey(date);

  String get displayTitle {
    final trimmed = title?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return '${date.month} 月 ${date.day} 日';
  }

  bool get hasContent =>
      content.trim().isNotEmpty ||
      (title?.trim().isNotEmpty ?? false) ||
      images.isNotEmpty;

  WeatherCode? get weather => WeatherCode.fromCode(weatherCode);

  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    Object? title = _unset,
    String? content,
    Object? mood = _unset,
    Object? weatherCode = _unset,
    Object? temperature = _unset,
    Object? city = _unset,
    bool? isFavorite,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: identical(title, _unset) ? this.title : title as String?,
      content: content ?? this.content,
      mood: identical(mood, _unset) ? this.mood : mood as Mood?,
      weatherCode: identical(weatherCode, _unset)
          ? this.weatherCode
          : weatherCode as String?,
      temperature: identical(temperature, _unset)
          ? this.temperature
          : temperature as int?,
      city: identical(city, _unset) ? this.city : city as String?,
      isFavorite: isFavorite ?? this.isFavorite,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': dateKeyValue,
    'title': title,
    'content': content,
    'mood': mood?.value,
    'weatherCode': weatherCode,
    'temperature': temperature,
    'city': city,
    'isFavorite': isFavorite,
    'images': images,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final parsedDate =
        tryParseDateKey(json['date'] as String?) ??
        DateTime.tryParse((json['date'] as String?) ?? '') ??
        dateOnly(now);
    final rawImages = json['images'];
    final images = <String>[
      if (rawImages is List)
        for (final item in rawImages)
          if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
    final rawMood = json['mood'];
    return DiaryEntry(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? (json['id'] as String).trim()
          : '',
      date: parsedDate,
      title: (json['title'] as String?)?.trim().isEmpty == true
          ? null
          : (json['title'] as String?),
      content: (json['content'] as String?) ?? '',
      mood: rawMood is int ? Mood.fromValue(rawMood) : null,
      weatherCode: (json['weatherCode'] as String?)?.trim(),
      temperature: json['temperature'] is num
          ? (json['temperature'] as num).round()
          : null,
      city: (json['city'] as String?)?.trim().isEmpty == true
          ? null
          : (json['city'] as String?)?.trim(),
      isFavorite: json['isFavorite'] == true,
      images: images,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? now,
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? now,
    );
  }
}
