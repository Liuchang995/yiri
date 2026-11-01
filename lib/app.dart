import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_theme.dart';
import 'features/theme/theme_controller.dart';
import 'features/theme/theme_reveal.dart';
import 'routing/app_router.dart';

class YiriApp extends ConsumerWidget {
  const YiriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: '一日',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.systemUiStyle(brightness),
          child: ThemeRevealHost(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
