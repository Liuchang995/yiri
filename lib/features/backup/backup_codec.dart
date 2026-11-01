import 'dart:convert';

import 'backup_models.dart';

class BackupCodec {
  static const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');

  static String buildManifestJsonString(BackupManifest manifest) {
    return _prettyEncoder.convert(manifest.toJson());
  }

  static BackupManifest parseManifest(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const BackupFormatException('manifest.json 不是有效的 JSON');
    }
    if (decoded is! Map) {
      throw const BackupFormatException('manifest.json 结构不正确');
    }
    final json = Map<String, dynamic>.from(decoded);
    if (json['format'] != backupFormat) {
      throw const BackupFormatException('这不是「一日」导出的备份文件');
    }
    if (json['version'] != backupVersion) {
      throw BackupFormatException(
        '备份版本不兼容（需要 $backupVersion，实际为 ${json['version']}）',
      );
    }
    final rawEntries = json['entries'];
    if (rawEntries is! List) {
      throw const BackupFormatException('备份清单缺少 entries');
    }
    final entries = <BackupEntry>[];
    for (final rawEntry in rawEntries) {
      if (rawEntry is! Map) {
        throw const BackupFormatException('备份中的日记条目损坏');
      }
      entries.add(
        BackupEntry.fromManifestJson(Map<String, dynamic>.from(rawEntry)),
      );
    }
    if (entries.isEmpty) {
      throw const BackupFormatException('备份中没有日记');
    }
    final exportedAt =
        DateTime.tryParse((json['exportedAt'] as String?) ?? '') ??
        DateTime.now();
    return BackupManifest(exportedAt: exportedAt, entries: entries);
  }

  /// 入口日期会出现在文件名中，所以仅使用 ASCII 与常见安全字符。
  static String safeId(String id) {
    final safe = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return safe.isEmpty ? 'entry' : safe;
  }

  static String imageFileName(String id, int index, String extension) {
    final normalized = extension.toLowerCase().replaceAll('.', '');
    final ext = normalized.isEmpty ? 'jpg' : normalized;
    return '${safeId(id)}_$index.$ext';
  }

  static String buildMarkdown(
    BackupEntry entry, {
    required List<String> imageNames,
  }) {
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('date: ${entry.date}')
      ..writeln('mood: ${entry.mood ?? 'null'}')
      ..writeln('weather: ${entry.weatherCode ?? 'null'}')
      ..writeln('temperature: ${entry.temperature ?? 'null'}')
      ..writeln('---')
      ..writeln();
    if (entry.title != null && entry.title!.trim().isNotEmpty) {
      buffer
        ..writeln('# ${entry.title!.trim()}')
        ..writeln();
    }
    if (entry.content.isNotEmpty) {
      buffer
        ..writeln(entry.content)
        ..writeln();
    }
    for (final image in imageNames) {
      buffer
        ..writeln('![](../images/$image)')
        ..writeln();
    }
    return buffer.toString();
  }
}
