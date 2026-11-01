import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/poem.dart';
import 'poetry_cache_store.dart';
import 'poetry_remote_source.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 1400),
      receiveTimeout: const Duration(milliseconds: 1400),
      sendTimeout: const Duration(milliseconds: 1400),
      headers: const {'User-Agent': 'Yiri-Diary/1.0 (local-only)'},
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

final poetryServiceProvider = Provider<PoetryService>((ref) {
  return PoetryService(ref.watch(dioProvider));
});

class PoetryService {
  PoetryService(this.dio);

  final Dio dio;

  /// 总超时严格控制在 1.5 秒。失败返回 null，调用方保持本地诗。
  static const Duration remoteTimeout = Duration(milliseconds: 1500);

  List<PoetryRemoteSource> get sources => const [
    JinrishiciSource(),
    HitokotoPoetrySource(),
  ];

  Future<Poem?> fetchOnline() async {
    try {
      return await _fetchFromSources().timeout(remoteTimeout);
    } catch (_) {
      return null;
    }
  }

  Future<Poem?> _fetchFromSources() async {
    for (final source in sources) {
      try {
        final poem = await source.fetch(dio);
        if (poem != null && poem.lines.isNotEmpty) return poem;
      } catch (_) {
        // 单个源挂掉时换下一个，不打断开屏。
      }
    }
    return null;
  }

  Future<void> cacheToday(Poem poem, {DateTime? now}) {
    return PoetryCacheStore.write(poem, now: now);
  }
}
