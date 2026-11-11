// Touch hotspots for app-preview footage. Wrap the app under test in [TapDots] and every
// pointer the tour sends (tap, drag, long press) leaves a soft dot in the recording, so a
// viewer watching with the sound off can see what was touched. Test-only: lives under
// integration_test/, never imported by lib/.
import 'package:flutter/widgets.dart';

class TapDots extends StatefulWidget {
  const TapDots({super.key, required this.child});

  final Widget child;

  @override
  State<TapDots> createState() => _TapDotsState();
}

class _Dot {
  _Dot(this.position, this.controller);

  Offset position;
  final AnimationController controller;
  bool down = true;
}

class _TapDotsState extends State<TapDots> with TickerProviderStateMixin {
  final Map<int, _Dot> _dots = {};

  void _down(PointerDownEvent e) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    final dot = _Dot(e.position, controller);
    controller.addListener(() => setState(() {}));
    controller.addStatusListener((status) {
      // animateTo(0.3) also ends in `completed`: only a released dot that
      // has run its fade may go, or a held finger loses its dot at 110 ms.
      if (status == AnimationStatus.completed && !dot.down) {
        _dots.removeWhere((_, d) => d == dot);
        controller.dispose();
        if (mounted) setState(() {});
      }
    });
    // Grow in over the first 30% and hold there while the finger is down.
    controller.animateTo(0.3, duration: const Duration(milliseconds: 110));
    setState(() => _dots[e.pointer] = dot);
  }

  void _move(PointerMoveEvent e) {
    final dot = _dots[e.pointer];
    if (dot == null) return;
    setState(() => dot.position = e.position);
  }

  void _up(PointerEvent e) {
    final dot = _dots[e.pointer];
    if (dot == null || !dot.down) return;
    dot.down = false;
    // Finish the grow if the tap was instant, then fade out.
    dot.controller.forward(
      from: dot.controller.value < 0.3 ? 0.3 : dot.controller.value,
    );
  }

  @override
  void dispose() {
    for (final dot in _dots.values) {
      dot.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            IgnorePointer(
              child: CustomPaint(painter: _DotsPainter(_dots.values.toList())),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.dots);

  final List<_Dot> dots;

  @override
  void paint(Canvas canvas, Size size) {
    for (final dot in dots) {
      final t = dot.controller.value;
      // 0..0.3 grow in, 0.3..1 expand a little and fade.
      final grow = Curves.easeOutCubic.transform((t / 0.3).clamp(0.0, 1.0));
      final fade = t <= 0.3
          ? 1.0
          : 1.0 - Curves.easeIn.transform((t - 0.3) / 0.7);
      final radius =
          15.0 + 13.0 * grow + (t > 0.3 ? 8.0 * (t - 0.3) / 0.7 : 0.0);
      canvas.drawCircle(
        dot.position,
        radius + 1.5,
        Paint()
          ..color = Color.fromRGBO(0, 0, 0, 0.22 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawCircle(
        dot.position,
        radius,
        Paint()..color = Color.fromRGBO(255, 255, 255, 0.42 * fade),
      );
      canvas.drawCircle(
        dot.position,
        radius,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, 0.85 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) => true;
}
