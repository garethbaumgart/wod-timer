import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';

/// One part of a workout as the timeline draws it: how long, and whether
/// it is a rest.
@immutable
class TimelinePart {
  const TimelinePart(this.seconds, {this.rest = false});

  final int seconds;
  final bool rest;

  @override
  bool operator ==(Object other) =>
      other is TimelinePart && other.seconds == seconds && other.rest == rest;

  @override
  int get hashCode => Object.hash(seconds, rest);
}

/// The shape of a workout: its parts in order, and the colour its work
/// parts wear. For Time and AMRAP are one bar, EMOM one block per round,
/// Tabata a work / rest pair per round. Rest parts are always rest pink.
@immutable
class WorkoutShape {
  const WorkoutShape({required this.parts, required this.accent});

  factory WorkoutShape.forTime(int capSeconds) => WorkoutShape(
    parts: [TimelinePart(capSeconds)],
    accent: AppColors.forTimeAccent,
  );

  factory WorkoutShape.amrap(int durationSeconds) => WorkoutShape(
    parts: [TimelinePart(durationSeconds)],
    accent: AppColors.amrapAccent,
  );

  factory WorkoutShape.emom({
    required int intervalSeconds,
    required int rounds,
  }) => WorkoutShape(
    parts: [for (var i = 0; i < rounds; i++) TimelinePart(intervalSeconds)],
    accent: AppColors.emomAccent,
  );

  factory WorkoutShape.tabata({
    required int workSeconds,
    required int restSeconds,
    required int rounds,
  }) => WorkoutShape(
    parts: [
      for (var i = 0; i < rounds; i++) ...[
        TimelinePart(workSeconds),
        TimelinePart(restSeconds, rest: true),
      ],
    ],
    accent: AppColors.tabataAccent,
  );

  factory WorkoutShape.ofSetup(Object setup) => switch (setup) {
    ForTimeSetup(:final capSeconds) => WorkoutShape.forTime(capSeconds),
    AmrapSetup(:final durationSeconds) => WorkoutShape.amrap(durationSeconds),
    EmomSetup(:final intervalSeconds, :final rounds) => WorkoutShape.emom(
      intervalSeconds: intervalSeconds,
      rounds: rounds,
    ),
    TabataSetup(:final workSeconds, :final restSeconds, :final rounds) =>
      WorkoutShape.tabata(
        workSeconds: workSeconds,
        restSeconds: restSeconds,
        rounds: rounds,
      ),
    _ => throw ArgumentError.value(setup, 'setup', 'not a setup'),
  };

  /// The shape of a configured timer, for the live and end screens.
  factory WorkoutShape.ofTimerType(TimerType type) => type.when(
    amrap: (t) => WorkoutShape.amrap(t.duration.seconds),
    forTime: (t) => WorkoutShape.forTime(t.timeCap.seconds),
    emom: (t) => WorkoutShape.emom(
      intervalSeconds: t.intervalDuration.seconds,
      rounds: t.rounds.value,
    ),
    tabata: (t) => WorkoutShape.tabata(
      workSeconds: t.workDuration.seconds,
      restSeconds: t.restDuration.seconds,
      rounds: t.rounds.value,
    ),
  );

  final List<TimelinePart> parts;
  final Color accent;

  int get totalSeconds => parts.fold(0, (sum, p) => sum + p.seconds);

  Color colorOf(TimelinePart part) => part.rest ? AppColors.rest : accent;

  @override
  bool operator ==(Object other) =>
      other is WorkoutShape &&
      other.accent == accent &&
      other.parts.length == parts.length &&
      [
        for (var i = 0; i < parts.length; i++) other.parts[i] == parts[i],
      ].every((same) => same);

  @override
  int get hashCode => Object.hash(accent, Object.hashAll(parts));
}

/// The workout drawn as blocks, flex by seconds, with 3pt gaps: the one
/// timeline Home, setup, live and end share (1.3.1).
///
/// With [elapsedSeconds] null every part is filled (Home, setup). Given,
/// finished parts are filled, the current part fills from its left edge
/// and parts still to come sit on the track colour (live, end).
class WorkoutTimeline extends StatelessWidget {
  const WorkoutTimeline({
    required this.shape,
    super.key,
    this.height = 12,
    this.elapsedSeconds,
    this.gap = 3,
  });

  final WorkoutShape shape;
  final double height;
  final double? elapsedSeconds;
  final double gap;

  /// Corner radius: 3 on a Home card, 4 on the live screen's 14pt bar.
  static double radiusFor(double height) => height >= 14 ? 4 : 3;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: TimelinePainter(
            shape: shape,
            elapsedSeconds: elapsedSeconds,
            gap: gap,
            radius: radiusFor(height),
          ),
        ),
      ),
    );
  }
}

/// Paints a [WorkoutShape] across the width.
class TimelinePainter extends CustomPainter {
  const TimelinePainter({
    required this.shape,
    required this.gap,
    required this.radius,
    this.elapsedSeconds,
  });

  final WorkoutShape shape;
  final double gap;
  final double radius;
  final double? elapsedSeconds;

  @override
  void paint(Canvas canvas, Size size) {
    final parts = shape.parts;
    final total = shape.totalSeconds;
    if (parts.isEmpty || total <= 0) return;
    final usable = size.width - gap * (parts.length - 1);
    if (usable <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;
    var x = 0.0;
    var start = 0;
    for (final part in parts) {
      final width = usable * part.seconds / total;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, width, size.height),
        Radius.circular(radius),
      );
      final elapsed = elapsedSeconds;
      if (elapsed == null) {
        canvas.drawRRect(rect, paint..color = shape.colorOf(part));
      } else {
        canvas.drawRRect(rect, paint..color = AppColors.track);
        final fraction = part.seconds == 0
            ? 1.0
            : ((elapsed - start) / part.seconds).clamp(0.0, 1.0);
        if (fraction > 0) {
          canvas
            ..save()
            ..clipRRect(rect)
            ..drawRect(
              Rect.fromLTWH(x, 0, width * fraction, size.height),
              paint..color = shape.colorOf(part),
            )
            ..restore();
        }
      }
      x += width + gap;
      start += part.seconds;
    }
  }

  @override
  bool shouldRepaint(TimelinePainter old) =>
      old.shape != shape ||
      old.elapsedSeconds != elapsedSeconds ||
      old.gap != gap ||
      old.radius != radius;
}
