import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../data/preferences/preferences.dart';
import '../../data/poetry/poetry_service.dart';
import '../../data/startup_state.dart';
import '../../models/poem.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _exitController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late Poem _poem;
  late bool _loadedFromCache;

  double _dragOffset = 0;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    final startup = ref.read(startupStateProvider);
    _poem = startup.initialPoem;
    _loadedFromCache = startup.initialFromCache;
    if (!_loadedFromCache) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_fetchOnlinePoem());
      });
    }
  }

  Future<void> _fetchOnlinePoem() async {
    if (!mounted || _leaving) return;
    final poem = await ref.read(poetryServiceProvider).fetchOnline();
    if (!mounted || _leaving || poem == null || poem.lines.isEmpty) return;
    final changed =
        poem.title != _poem.title ||
        poem.author != _poem.author ||
        poem.lines.join() != _poem.lines.join();
    if (!changed) return;
    setState(() => _poem = poem);
    unawaited(ref.read(poetryServiceProvider).cacheToday(poem));
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_leaving) return;
    final next = (_dragOffset + details.delta.dy).clamp(-120.0, 0.0).toDouble();
    setState(() => _dragOffset = next);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_leaving) return;
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragOffset <= -splashDismissDistance ||
        velocity < -splashDismissVelocity) {
      unawaited(_leave());
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    try {
      await _exitController.forward().orCancel;
    } catch (_) {
      // 页面在退场时被系统回收，直接走路由兜底。
    }
    if (!mounted) return;
    var needsPermissions = false;
    try {
      needsPermissions =
          !(ref
                  .read(sharedPreferencesProvider)
                  .getBool(permissionsOnboardedKey) ??
              false);
    } catch (_) {
      needsPermissions = false;
    }
    context.go(needsPermissions ? '/permissions' : '/home');
  }

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _leaving ? null : _leave,
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          child: AnimatedBuilder(
            animation: _exitController,
            builder: (context, child) {
              final exitValue = Curves.easeOutCubic.transform(
                _exitController.value.clamp(0.0, 1.0),
              );
              return Opacity(
                opacity: 1 - exitValue,
                child: Transform.translate(
                  offset: Offset(0, -34 * exitValue + _dragOffset),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                const Spacer(flex: 2),
                Flexible(
                  flex: 9,
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: _PoemView(
                          key: ValueKey('${_poem.title}-${_poem.author}'),
                          poem: _poem,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 1),
                Padding(
                  padding: const EdgeInsets.only(bottom: 34),
                  child: Text(
                    '上滑进入',
                    style: TextStyle(
                      color: colors.secondaryText.withValues(alpha: 0.42),
                      fontSize: 11,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PoemView extends StatelessWidget {
  const _PoemView({super.key, required this.poem});

  final Poem poem;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalChars = poem.lines.fold<int>(
      0,
      (sum, line) => sum + line.length,
    );
    final fontSize = poem.lines.length <= 4 && totalChars <= 80
        ? 26.0
        : poem.lines.length <= 7 && totalChars <= 150
        ? 23.5
        : 22.0;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...poem.lines.map(
            (line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Text(
                line,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.text,
                  fontSize: fontSize,
                  height: 1.66,
                  letterSpacing: 1.1,
                  fontFamily: 'Songti SC',
                  fontFamilyFallback: const [
                    'Noto Serif SC',
                    'Noto Serif CJK SC',
                    'STSong',
                    'SimSun',
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            poem.footer,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 12.5,
              letterSpacing: 0.8,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// 手势物理参数单一来源。
const double splashDismissDistance = 60;
const double splashDismissVelocity = 350;
