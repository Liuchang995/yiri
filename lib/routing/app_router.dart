import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_keys.dart';
import '../core/app_colors.dart';
import '../core/date_utils.dart';
import '../features/calendar/calendar_page.dart';
import '../features/editor/editor_page.dart';
import '../features/home/diary_detail_page.dart';
import '../features/home/home_shell.dart';
import '../features/permissions/permission_setup_page.dart';
import '../features/splash/splash_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashPage()),
      ),
      GoRoute(
        path: '/permissions',
        name: 'permissions',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: PermissionSetupPage()),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: HomeShell()),
      ),
      GoRoute(
        path: '/detail',
        name: 'detail',
        pageBuilder: (context, state) {
          final date =
              tryParseDateKey(state.uri.queryParameters['date']) ??
              dateOnly(DateTime.now());
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: const Duration(milliseconds: 220),
            child: DiaryDetailPage(date: date),
            transitionsBuilder: (context, animation, secondary, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        pageBuilder: (context, state) {
          final fadeOnMount = state.uri.queryParameters['fade'] == '1';
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
            child: CalendarPage(fadeOnMount: fadeOnMount),
            transitionsBuilder: (context, animation, secondary, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/editor',
        name: 'editor',
        pageBuilder: (context, state) {
          final date =
              tryParseDateKey(state.uri.queryParameters['date']) ??
              dateOnly(DateTime.now());
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: const Duration(milliseconds: 230),
            reverseTransitionDuration: const Duration(milliseconds: 200),
            child: EditorPage(date: date),
            transitionsBuilder: (context, animation, secondary, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.015),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
          );
        },
      ),
    ],
    errorBuilder: (context, state) {
      final colors = context.colors;
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '页面走丢了',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '回到日历继续写今天的日记。',
                  style: TextStyle(color: colors.secondaryText, fontSize: 13),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/calendar'),
                  child: const Text('返回日历'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  ref.onDispose(router.dispose);
  return router;
});
