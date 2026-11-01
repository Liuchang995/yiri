import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiri/data/preferences/preferences.dart';
import 'package:yiri/features/theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('主题模式从偏好读取，手动切换后写回', () async {
    SharedPreferences.setMockInitialValues({themeModePreferenceKey: 'dark'});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeControllerProvider), ThemeMode.dark);

    container
        .read(themeModeControllerProvider.notifier)
        .toggleFrom(Brightness.dark);
    expect(container.read(themeModeControllerProvider), ThemeMode.light);
    expect(preferences.getString(themeModePreferenceKey), 'light');
  });
}
