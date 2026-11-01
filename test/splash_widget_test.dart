import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiri/core/app_theme.dart';
import 'package:yiri/data/poetry/poetry_library.dart';
import 'package:yiri/data/startup_state.dart';
import 'package:yiri/features/splash/splash_page.dart';
import 'package:yiri/models/poem.dart';

void main() {
  testWidgets('开屏本地诗立即渲染且无 loading', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          startupStateProvider.overrideWithValue(
            const StartupState(
              online: true,
              library: PoetryLibrary([kFallbackPoem]),
              initialPoem: kFallbackPoem,
              initialFromCache: true,
            ),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const SplashPage()),
      ),
    );
    await tester.pump();

    expect(find.text('床前明月光，疑是地上霜。'), findsOneWidget);
    expect(find.text('唐 · 李白 · 静夜思'), findsOneWidget);
    expect(find.text('上滑进入'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
