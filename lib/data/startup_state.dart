import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/poem.dart';

class StartupState {
  const StartupState({
    required this.online,
    required this.library,
    required this.initialPoem,
    required this.initialFromCache,
  });

  final bool online;
  final PoetryLibrary library;
  final Poem initialPoem;
  final bool initialFromCache;
}

final startupStateProvider = Provider<StartupState>((ref) {
  throw UnimplementedError('startupStateProvider must be overridden');
});
