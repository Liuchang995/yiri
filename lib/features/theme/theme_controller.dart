import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/preferences/preferences.dart';

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return themeModeFromPreference(ref.watch(sharedPreferencesProvider));
  }

  /// 以「当前实际亮度」决定目标，而不是以 ThemeMode 本身。
  /// manual 之后永远写 light/dark，系统变化不再影响 App。
  void toggleFrom(Brightness currentBrightness) {
    final next = currentBrightness == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    state = next;
    final preferences = ref.read(sharedPreferencesProvider);
    unawaited(
      preferences.setString(
        themeModePreferenceKey,
        themeModeToPreference(next),
      ),
    );
  }
}
