import 'package:flutter_test/flutter_test.dart';
import 'package:yiri/features/backup/backup_codec.dart';
import 'package:yiri/features/backup/backup_models.dart';

BackupEntry _entry() {
  return BackupEntry(
    id: 'entry-1',
    date: '2025-06-12',
    title: '湖边',
    content: '今天的风很轻。',
    mood: 4,
    weatherCode: 'sunny',
    temperature: 26,
    imageNames: ['entry-1_1.jpg'],
    createdAt: '2025-06-12T08:00:00.000',
    updatedAt: '2025-06-12T09:00:00.000',
  );
}

void main() {
  test('manifest 往返保留完整字段', () {
    final manifest = BackupManifest(
      exportedAt: DateTime(2025, 6, 12, 10),
      entries: [_entry()],
    );
    final parsed = BackupCodec.parseManifest(
      BackupCodec.buildManifestJsonString(manifest),
    );
    expect(parsed.entries.length, 1);
    final entry = parsed.entries.single;
    expect(entry.id, 'entry-1');
    expect(entry.date, '2025-06-12');
    expect(entry.title, '湖边');
    expect(entry.content, '今天的风很轻。');
    expect(entry.mood, 4);
    expect(entry.weatherCode, 'sunny');
    expect(entry.temperature, 26);
    expect(entry.imageNames, ['entry-1_1.jpg']);
  });

  test('Markdown 带 front-matter 与相对图片', () {
    final markdown = BackupCodec.buildMarkdown(
      _entry(),
      imageNames: ['entry-1_1.jpg'],
    );
    expect(markdown, contains('date: 2025-06-12'));
    expect(markdown, contains('mood: 4'));
    expect(markdown, contains('weather: sunny'));
    expect(markdown, contains('temperature: 26'));
    expect(markdown, contains('![](../images/entry-1_1.jpg)'));
  });

  test('拒绝缺失 manifest 版本或错误版本', () {
    expect(
      () => BackupCodec.parseManifest('{}'),
      throwsA(isA<BackupFormatException>()),
    );
    final valid = BackupCodec.buildManifestJsonString(
      BackupManifest(exportedAt: DateTime.now(), entries: [_entry()]),
    );
    final wrongVersion = valid.replaceFirst('"version": 1', '"version": 99');
    expect(
      () => BackupCodec.parseManifest(wrongVersion),
      throwsA(isA<BackupFormatException>()),
    );
    final wrongFormat = valid.replaceFirst(
      '"format": "yiri-diary-backup"',
      '"format": "other"',
    );
    expect(
      () => BackupCodec.parseManifest(wrongFormat),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('拒绝不安全图片路径', () {
    final manifest = BackupManifest(
      exportedAt: DateTime.now(),
      entries: [
        BackupEntry(
          id: 'bad',
          date: '2025-06-12',
          content: '',
          imageNames: ['../evil.jpg'],
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      ],
    );
    expect(
      () => BackupCodec.parseManifest(
        BackupCodec.buildManifestJsonString(manifest),
      ),
      throwsA(isA<BackupFormatException>()),
    );
  });
}
