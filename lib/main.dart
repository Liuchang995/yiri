import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/poetry/poetry_cache_store.dart';
import 'data/poetry/poetry_library.dart';
import 'data/preferences/preferences.dart';
import 'data/startup_state.dart';
import 'models/poem.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  final preferencesFuture = SharedPreferences.getInstance();
  final poemsFuture = _loadLibrarySafely();
  final online = await _hasNetwork();

  final preferences = await preferencesFuture;
  final library = online
      ? await poemsFuture
      : const PoetryLibrary([kFallbackPoem]);
  final cached = online
      ? await PoetryCacheStore.read(now)
            .timeout(const Duration(milliseconds: 150), onTimeout: () => null)
      : null;
  final localPoem = PoetrySelector.pick(library.poems, now) ?? kFallbackPoem;

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        startupStateProvider.overrideWithValue(
          StartupState(
            online: online,
            library: library,
            initialPoem: cached ?? localPoem,
            initialFromCache: cached != null,
          ),
        ),
      ],
      child: const YiriApp(),
    ),
  );
}

/// 200ms 硬上限。超时或插件异常都按离线处理，直接进入日历。
Future<bool> _hasNetwork() async {
  try {
    final results = await Connectivity().checkConnectivity().timeout(
      const Duration(milliseconds: 200),
      onTimeout: () => const <ConnectivityResult>[],
    );
    return results.any((result) => result != ConnectivityResult.none);
  } catch (_) {
    return false;
  }
}

Future<PoetryLibrary> _loadLibrarySafely() async {
  try {
    return await PoetryAssetLibrary.load();
  } catch (_) {
    return const PoetryLibrary([kFallbackPoem]);
  }
}
