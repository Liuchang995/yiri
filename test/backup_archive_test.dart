import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:yiri/features/backup/backup_codec.dart';
import 'package:yiri/features/backup/backup_worker.dart';

Future<Map<String, dynamic>> _runWorker(
  Future<void> Function(Map<String, dynamic>) worker,
  Map<String, dynamic> args,
) async {
  final port = ReceivePort();
  final completer = Completer<Map<String, dynamic>>();
  final subscription = port.listen((message) {
    if (message is Map && message['type'] == 'result') {
      if (!completer.isCompleted) {
        completer.complete(Map<String, dynamic>.from(message));
      }
    } else if (message is Map && message['type'] == 'error') {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError((message['message'] ?? 'worker error').toString()),
        );
      }
    } else if (message is List) {
      if (!completer.isCompleted) {
        completer.completeError(StateError(message.join(' ')));
      }
    }
  });
  final isolate = await Isolate.spawn<Map<String, dynamic>>(worker, {
    ...args,
    'sendPort': port.sendPort,
  }, onError: port.sendPort);
  try {
    return await completer.future.timeout(const Duration(minutes: 1));
  } finally {
    await subscription.cancel();
    port.close();
    isolate.kill(priority: Isolate.immediate);
  }
}

void main() {
  late Directory temp;
  late Directory root;
  late String zipPath;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('yiri_backup_test_');
    root = Directory(p.join(temp.path, 'root'));
    await Directory(p.join(root.path, 'images')).create(recursive: true);
    await File(p.join(root.path, 'images', 'a.jpg'))
        .writeAsBytes(List<int>.generate(32, (index) => index));
    await File(p.join(root.path, 'images', 'b.png'))
        .writeAsBytes(List<int>.generate(24, (index) => 200 - index));
    zipPath = p.join(temp.path, 'backup.zip');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('导出 zip 结构、manifest 与 Markdown 符合约定', () async {
    final entries = [
      {
        'id': 'entry-one',
        'date': '2025-06-12',
        'title': '湖边',
        'content': '今天的风很轻。',
        'mood': 4,
        'weatherCode': 'sunny',
        'temperature': 26,
        'images': ['images/a.jpg', 'images/b.png'],
        'createdAt': '2025-06-12T08:00:00.000',
        'updatedAt': '2025-06-12T09:00:00.000',
      },
      {
        'id': 'entry-two',
        'date': '2025-06-13',
        'title': null,
        'content': '只写了一句。',
        'mood': 3,
        'weatherCode': 'cloudy',
        'temperature': null,
        'images': [],
        'createdAt': '2025-06-13T08:00:00.000',
        'updatedAt': '2025-06-13T09:00:00.000',
      },
    ];
    final result = await _runWorker(backupExportWorker, {
      'outputPath': zipPath,
      'rootPath': root.path,
      'entries': entries,
    });
    expect(result['entries'], 2);
    expect(result['images'], 2);
    expect(result['missing'], 0);

    final input = InputFileStream(zipPath);
    final archive = ZipDecoder().decodeStream(input);
    final names = archive.files.map((file) => file.name).toSet();
    expect(names, contains('manifest.json'));
    expect(names, contains('entries/2025-06-12.md'));
    expect(names, contains('entries/2025-06-13.md'));
    expect(names, contains('images/entry-one_1.jpg'));
    expect(names, contains('images/entry-one_2.png'));

    final manifestFile = archive.find('manifest.json')!;
    final manifest = BackupCodec.parseManifest(
      utf8.decode(manifestFile.readBytes()!),
    );
    expect(manifest.entries.length, 2);
    expect(manifest.entries.first.imageNames, [
      'entry-one_1.jpg',
      'entry-one_2.png',
    ]);

    final markdown = utf8.decode(
      archive.find('entries/2025-06-12.md')!.readBytes()!,
    );
    expect(markdown, contains('mood: 4'));
    expect(markdown, contains('weather: sunny'));
    expect(markdown, contains('temperature: 26'));
    expect(markdown, contains('![](../images/entry-one_1.jpg)'));
    input.close();
  });

  test('解包把图片原样写回，不重新压缩', () async {
    final entries = [
      {
        'id': 'entry-one',
        'date': '2025-06-12',
        'title': '湖边',
        'content': '今天的风很轻。',
        'mood': 4,
        'weatherCode': 'sunny',
        'temperature': 26,
        'images': ['images/a.jpg', 'images/b.png'],
        'createdAt': '2025-06-12T08:00:00.000',
        'updatedAt': '2025-06-12T09:00:00.000',
      },
    ];
    await _runWorker(backupExportWorker, {
      'outputPath': zipPath,
      'rootPath': root.path,
      'entries': entries,
    });

    final input = InputFileStream(zipPath);
    final archive = ZipDecoder().decodeStream(input);
    final manifest = BackupCodec.parseManifest(
      utf8.decode(archive.find('manifest.json')!.readBytes()!),
    );
    input.close();

    final targetRoot = Directory(p.join(temp.path, 'imported'));
    await targetRoot.create(recursive: true);
    final extracted = await _runWorker(backupExtractWorker, {
      'zipPath': zipPath,
      'rootPath': targetRoot.path,
      'entries': manifest.entries
          .map((entry) => entry.toManifestJson())
          .toList(growable: false),
    });
    expect(extracted['entries'], hasLength(1));
    expect(extracted['missing'], 0);
    final written = File(p.join(targetRoot.path, 'images', 'entry-one_1.jpg'));
    expect(await written.exists(), isTrue);
    expect(await written.length(), 32);
    final raw = await File(p.join(root.path, 'images', 'a.jpg')).readAsBytes();
    expect(await written.readAsBytes(), raw);
  });
}
