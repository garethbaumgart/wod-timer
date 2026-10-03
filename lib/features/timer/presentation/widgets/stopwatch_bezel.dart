import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_format.dart';

/// The stopwatch bezel (1.3.1): a ring the athlete drags around to set
/// whole minutes, one full turn being 60. AMRAP's duration and For Time's
/// cap use it.
///
/// Drawn to the prototype: a dark track ring, a white arc from 12 o'clock
/// to the value, 60 ticks (every fifth longer) in the mode colour up to the
/// value, and a pink knob with an ink outline at the value. The label and
/// "m:00" sit inside. The value clamps to 1..60 with no wrap-around jump:
/// dragging past 12 o'clock from 60 stays on 60.
///
/// Accessibility: one adjustable node (increase / decrease by a minute),
/// so it works without dragging.
class StopwatchBezel extends StatelessWidget {
  const StopwatchBezel({
    required this.minutes,
    required this.label,
    required this.accent,
    required this.onChanged,
    super.key,
    this.size = 270,
  });

  /// 1..60.
  final int minutes;

  /// Inside the ring, above the value ("DURATION", "TIME CAP").
  final String label;

  /// The mode colour, for the ticks.
  final Color accent;

  /// Called with the new minutes whenever a drag moves the value.
  final ValueChanged<int> onChanged;

  /// Width and height; the prototype is 270pt on a phone.
  final double size;

  static const int maxMinutes = 60;

  /// The minutes at [local] inside a [size] box, or null off-centre.
  static int minutesAt(Offset local, double size) {
    final centre = size / 2;
    final dx = local.dx - centre;
    final dy = local.dy - centre;
    var degrees = math.atan2(dx, -dy) * 180 / math.pi;
    if (degrees < 0) degrees += 360;
    final n = (degrees / 6).round();
    return n == 0 ? maxMinutes : n;
  }

  /// The next value for a drag at [local]: snapped to the nearest minute,
  /// held at 1 or 60 instead of jumping across 12 o'clock.
  static int dragTo(Offset local, double size, int current) {
    var next = minutesAt(local, size);
    if ((next - current).abs() > 30) next = current > 30 ? maxMinutes : 1;
    return next.clamp(1, maxMinutes);
  }

  void _drag(Offset local) {
    final next = dragTo(local, size, minutes);
    if (next != minutes) onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final s = size / 270;
    final spoken = setupSpokenDuration(minutes * 60);
    return Semantics(
      container: true,
      label: label,
      value: spoken,
      increasedValue: minutes < maxMinutes
          ? setupSpokenDuration((minutes + 1) * 60)
          : null,
      decreasedValue: minutes > 1
          ? setupSpokenDuration((minutes - 1) * 60)
          : null,
      onIncrease: minutes < maxMinutes ? () => onChanged(minutes + 1) : null,
      onDecrease: minutes > 1 ? () => onChanged(minutes - 1) : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (d) => _drag(d.localPosition),
        onPanUpdate: (d) => _drag(d.localPosition),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: BezelPainter(minutes: minutes, accent: accent),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondaryDark,
                        fontSize: 13 * s,
                        letterSpacing: 13 * s * 0.14,
                      ),
                    ),
                    Text(
                      '$minutes:00',
                      style: AppTypography.timerDisplay.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontSize: 66 * s,
                        letterSpacing: -66 * s * 0.02,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints the ring, arc, ticks and knob of a [StopwatchBezel].
class BezelPainter extends CustomPainter {
  const BezelPainter({required this.minutes, required this.accent});

  final int minutes;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 270;
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = 112 * s;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18 * s
      ..color = AppColors.bezelRing;
    canvas.drawCircle(centre, radius, ring);

    // Progress arc from 12 o'clock, clockwise to the value.
    final sweep = math.min(minutes / 60 * 2 * math.pi, 2 * math.pi - 0.002);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18 * s
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );

    // 60 ticks, every fifth longer, lit in the mode colour up to the value.
    final tick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 60; k++) {
      final angle = k * math.pi / 30;
      final major = k % 5 == 0;
      final r1 = radius - 16 * s;
      final r2 = r1 - (major ? 14 : 7) * s;
      tick
        ..strokeWidth = (major ? 3 : 2) * s
        ..color = k < minutes ? accent : AppColors.bezelTickOff;
      canvas.drawLine(
        centre + Offset(r1 * math.sin(angle), -r1 * math.cos(angle)),
        centre + Offset(r2 * math.sin(angle), -r2 * math.cos(angle)),
        tick,
      );
    }

    // The knob at the value.
    final angle = sweep;
    final knob =
        centre + Offset(radius * math.sin(angle), -radius * math.cos(angle));
    canvas
      ..drawCircle(knob, 17 * s, Paint()..color = AppColors.bezelKnob)
      ..drawCircle(
        knob,
        17 * s,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * s
          ..color = AppColors.backgroundDark,
      );
  }

  @override
  bool shouldRepaint(BezelPainter old) =>
      old.minutes != minutes || old.accent != accent;
}
