import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String themeModePreferenceKey = 'theme_mode';
const String permissionsOnboardedKey = 'permissions_onboarded_v1';
const String lastSplashDateKey = 'last_splash_date';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

ThemeMode themeModeFromPreference(SharedPreferences preferences) {
  return switch (preferences.getString(themeModePreferenceKey)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

String themeModeToPreference(ThemeMode mode) => switch (mode) {
  ThemeMode.light => 'light',
  ThemeMode.dark => 'dark',
  ThemeMode.system => 'system',
};
