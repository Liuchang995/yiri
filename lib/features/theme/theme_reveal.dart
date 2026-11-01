import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/app_keys.dart';

class ThemeRevealScope extends InheritedWidget {
  const ThemeRevealScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final ThemeRevealController controller;

  static ThemeRevealController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeRevealScope>()
        ?.controller;
  }

  static ThemeRevealController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'ThemeRevealScope not found');
    return controller!;
  }

  @override
  bool updateShouldNotify(ThemeRevealScope oldWidget) =>
      controller != oldWidget.controller;
}

/// 页面树外层：带 GlobalKey 的 RepaintBoundary + 动画宿主。
class ThemeRevealHost extends StatefulWidget {
  const ThemeRevealHost({super.key, required this.child});

  final Widget child;

  @override
  State<ThemeRevealHost> createState() => _ThemeRevealHostState();
}

class _ThemeRevealHostState extends State<ThemeRevealHost>
    with TickerProviderStateMixin {
  late final ThemeRevealController _controller = ThemeRevealController(
    vsync: this,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeRevealScope(
      controller: _controller,
      child: RepaintBoundary(key: rootBoundaryKey, child: widget.child),
    );
  }
}

/// 截图 + 圆扩散。整个控制器同时只允许一套动画。
class ThemeRevealController {
  ThemeRevealController({required TickerProvider vsync}) : _vsync = vsync;

  final TickerProvider _vsync;
  bool _busy = false;

  OverlayEntry? _entry;
  AnimationController? _animation;
  ui.Image? _image;

  Future<void> reveal({
    required BuildContext originContext,
    required VoidCallback applyNewTheme,
  }) async {
    if (_busy) return;
    _busy = true;

    final overlay = rootNavigatorKey.currentState?.overlay;
    final boundary = rootBoundaryKey.currentContext?.findRenderObject();
    final box = originContext.findRenderObject();
    if (overlay == null ||
        boundary is! RenderRepaintBoundary ||
        box is! RenderBox ||
        !box.hasSize) {
      applyNewTheme();
      _busy = false;
      return;
    }

    final center = box.localToGlobal(box.size.center(Offset.zero));
    final screenSize = MediaQuery.sizeOf(originContext);
    final pixelRatio = MediaQuery.devicePixelRatioOf(originContext);
    final oldBackground = Theme.of(originContext).scaffoldBackgroundColor;
    final maxRadius =
        <Offset>[
          Offset.zero,
          Offset(screenSize.width, 0),
          Offset(0, screenSize.height),
          Offset(screenSize.width, screenSize.height),
        ].map((corner) => (corner - center).distance).reduce(math.max) +
        20;

    ui.Image? screenshot;
    try {
      await WidgetsBinding.instance.endOfFrame;
      screenshot = await boundary.toImage(pixelRatio: pixelRatio);
    } catch (_) {
      screenshot = null;
    }

    if (screenshot == null) {
      await _fallbackFade(
        overlay: overlay,
        oldBackground: oldBackground,
        applyNewTheme: applyNewTheme,
      );
      _busy = false;
      return;
    }

    _image = screenshot;
    final controller = AnimationController(
      vsync: _vsync,
      duration: const Duration(milliseconds: 450),
    );
    _animation = controller;
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    final entry = OverlayEntry(
      builder: (context) {
        return IgnorePointer(
          ignoring: true,
          child: AnimatedBuilder(
            animation: curved,
            builder: (context, child) {
              final radius = maxRadius * curved.value;
              return ClipPath(
                clipper: _RevealClipper(center: center, radius: radius),
                child: child,
              );
            },
            child: SizedBox.expand(
              child: RawImage(
                image: screenshot,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.low,
              ),
            ),
          ),
        );
      },
    );
    _entry = entry;
    overlay.insert(entry);

    try {
      applyNewTheme();
      await WidgetsBinding.instance.endOfFrame;
      await controller.forward().orCancel;
    } catch (_) {
      // 动画被系统打断时，直接完成主题切换。
    } finally {
      entry.remove();
      if (identical(_entry, entry)) _entry = null;
      controller.dispose();
      if (identical(_animation, controller)) _animation = null;
      screenshot.dispose();
      if (identical(_image, screenshot)) _image = null;
      _busy = false;
    }
  }

  Future<void> _fallbackFade({
    required OverlayState overlay,
    required Color oldBackground,
    required VoidCallback applyNewTheme,
  }) async {
    final controller = AnimationController(
      vsync: _vsync,
      duration: const Duration(milliseconds: 200),
    );
    _animation = controller;
    final entry = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0).animate(controller),
          child: ColoredBox(
            color: oldBackground,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    try {
      applyNewTheme();
      await controller.forward().orCancel;
    } catch (_) {
      // ignore
    } finally {
      entry.remove();
      if (identical(_entry, entry)) _entry = null;
      controller.dispose();
      if (identical(_animation, controller)) _animation = null;
    }
  }

  void dispose() {
    _entry?.remove();
    _entry = null;
    _animation?.dispose();
    _animation = null;
    _image?.dispose();
    _image = null;
    _busy = false;
  }
}

class _RevealClipper extends CustomClipper<Path> {
  const _RevealClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) {
    final full = Path()..addRect(Offset.zero & size);
    if (radius <= 0) return full;
    final hole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    return Path.combine(PathOperation.difference, full, hole);
  }

  @override
  bool shouldReclip(covariant _RevealClipper oldClipper) {
    return oldClipper.center != center || oldClipper.radius != radius;
  }
}
