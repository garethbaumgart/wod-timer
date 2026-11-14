import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';

void main() {
  _timelinePartsAndShapes();
  group('WorkoutShape', () {
    test('For Time and AMRAP are one bar in their colour', () {
      final forTime = WorkoutShape.ofSetup(const ForTimeSetup());
      expect(forTime.parts, [const TimelinePart(1200)]);
      expect(forTime.accent, AppColors.forTimeAccent);

      final amrap = WorkoutShape.ofSetup(const AmrapSetup());
      expect(amrap.parts, [const TimelinePart(600)]);
      expect(amrap.accent, AppColors.amrapAccent);
      expect(amrap.totalSeconds, 600);
    });

    test('EMOM is one pink block per round', () {
      final shape = WorkoutShape.ofSetup(const EmomSetup());
      expect(shape.parts, hasLength(10));
      expect(shape.parts.every((p) => p == const TimelinePart(60)), isTrue);
      expect(shape.colorOf(shape.parts.first), AppColors.emomAccent);
      expect(shape.totalSeconds, 600);
    });

    test('Tabata alternates green work and pink rest', () {
      final shape = WorkoutShape.ofSetup(TabataSetup.classic);
      expect(shape.parts, hasLength(16));
      expect(shape.parts[0], const TimelinePart(20));
      expect(shape.parts[1], const TimelinePart(10, rest: true));
      expect(shape.colorOf(shape.parts[0]), AppColors.work);
      expect(shape.colorOf(shape.parts[1]), AppColors.rest);
      expect(shape.totalSeconds, 240);
    });

    test('a configured timer gives the same shape as its setup', () {
      final fromType = WorkoutShape.ofTimerType(
        TabataTimer(
          workDuration: TimerDuration.fromSeconds(20),
          restDuration: TimerDuration.fromSeconds(10),
          rounds: RoundCount.fromInt(8),
        ),
      );
      expect(fromType, WorkoutShape.ofSetup(TabataSetup.classic));
      expect(
        WorkoutShape.ofTimerType(
          EmomTimer(
            intervalDuration: TimerDuration.fromSeconds(90),
            rounds: RoundCount.fromInt(3),
          ),
        ),
        WorkoutShape.emom(intervalSeconds: 90, rounds: 3),
      );
    });
  });

  group('WorkoutTimeline', () {
    testWidgets('fills the width at its height, radius 3 under 14pt', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: WorkoutTimeline(
                shape: WorkoutShape.ofSetup(const EmomSetup()),
              ),
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byType(WorkoutTimeline));
      expect(size, const Size(300, 12));
      final painter =
          tester.widget<CustomPaint>(find.byType(CustomPaint).last).painter!
              as TimelinePainter;
      expect(painter.radius, 3);
      expect(painter.gap, 3);
      expect(painter.elapsedSeconds, isNull);
      expect(WorkoutTimeline.radiusFor(14), 4);
      expect(WorkoutTimeline.radiusFor(8), 3);
    });

    test('a running timeline repaints only when progress or shape change', () {
      final shape = WorkoutShape.ofSetup(const EmomSetup());
      final a = TimelinePainter(
        shape: shape,
        gap: 3,
        radius: 4,
        elapsedSeconds: 10,
      );
      final same = TimelinePainter(
        shape: WorkoutShape.ofSetup(const EmomSetup()),
        gap: 3,
        radius: 4,
        elapsedSeconds: 10,
      );
      final later = TimelinePainter(
        shape: shape,
        gap: 3,
        radius: 4,
        elapsedSeconds: 11,
      );
      expect(a.shouldRepaint(same), isFalse);
      expect(a.shouldRepaint(later), isTrue);
    });

    testWidgets('paints without error at every progress', (tester) async {
      for (final elapsed in [null, 0.0, 65.5, 600.0, 9999.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WorkoutTimeline(
                shape: WorkoutShape.ofSetup(TabataSetup.classic),
                height: 14,
                elapsedSeconds: elapsed,
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: '$elapsed');
      }
    });
  });
}

void _timelinePartsAndShapes() {
  group('mid-round ticks (2.5.0)', () {
    Future<RenderObject> pumpTimeline(
      WidgetTester tester,
      WorkoutShape shape, {
      required bool midTicks,
    }) async {
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 300,
            child: WorkoutTimeline(shape: shape, midTicks: midTicks),
          ),
        ),
      );
      return tester.renderObject(
        find.descendant(
          of: find.byType(WorkoutTimeline),
          matching: find.byType(CustomPaint),
        ),
      );
    }

    /// The white tick rects a paint drew, by centre x.
    Rect tickAt(double x, double barHeight) => Rect.fromCenter(
      center: Offset(x, barHeight / 2),
      width: TimelinePainter.midTickWidth,
      height: barHeight + TimelinePainter.midTickOverhang * 2,
    );

    testWidgets('an EMOM gets a white tick in the middle of every round', (
      tester,
    ) async {
      final shape = WorkoutShape.ofSetup(const EmomSetup(rounds: 2));
      final box = await pumpTimeline(tester, shape, midTicks: true);
      // Two 148.5pt blocks with a 3pt gap: middles at 74.25 and 225.75.
      expect(
        box,
        paints
          ..rrect(color: AppColors.emomAccent)
          ..rrect(
            rrect: RRect.fromRectAndRadius(
              tickAt(74.25, 12),
              const Radius.circular(1.5),
            ),
            color: AppColors.textPrimaryDark,
          )
          ..rrect(color: AppColors.emomAccent)
          ..rrect(
            rrect: RRect.fromRectAndRadius(
              tickAt(225.75, 12),
              const Radius.circular(1.5),
            ),
            color: AppColors.textPrimaryDark,
          ),
      );
    });

    testWidgets('Tabata ticks its work blocks, never its rests', (
      tester,
    ) async {
      final shape = WorkoutShape.ofSetup(const TabataSetup(rounds: 1));
      final box = await pumpTimeline(tester, shape, midTicks: true);
      expect(
        box,
        paints
          ..rrect(color: AppColors.work)
          ..rrect(color: AppColors.textPrimaryDark)
          ..rrect(color: AppColors.rest),
      );
      expect(
        box,
        isNot(
          paints
            ..rrect(color: AppColors.rest)
            ..rrect(color: AppColors.textPrimaryDark),
        ),
      );
    });

    testWidgets('parts under 10s and timelines without midTicks get none', (
      tester,
    ) async {
      final short = WorkoutShape.ofSetup(
        const TabataSetup(workSeconds: 5, restSeconds: 5, rounds: 1),
      );
      expect(
        await pumpTimeline(tester, short, midTicks: true),
        isNot(paints..rrect(color: AppColors.textPrimaryDark)),
      );
      final emom = WorkoutShape.ofSetup(const EmomSetup());
      expect(
        await pumpTimeline(tester, emom, midTicks: false),
        isNot(paints..rrect(color: AppColors.textPrimaryDark)),
      );
    });
  });

  group('TimelinePart and WorkoutShape value semantics', () {
    test('parts compare by seconds and rest', () {
      expect(const TimelinePart(20), const TimelinePart(20));
      expect(const TimelinePart(20).hashCode, const TimelinePart(20).hashCode);
      expect(const TimelinePart(20), isNot(const TimelinePart(20, rest: true)));
      expect(const TimelinePart(20), isNot(const TimelinePart(25)));
    });

    test('shapes compare part by part, with their accent', () {
      final a = WorkoutShape.emom(intervalSeconds: 60, rounds: 3);
      final b = WorkoutShape.emom(intervalSeconds: 60, rounds: 3);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(WorkoutShape.emom(intervalSeconds: 60, rounds: 4)));
      expect(a, isNot(WorkoutShape.emom(intervalSeconds: 90, rounds: 3)));
      expect(
        WorkoutShape.forTime(600),
        isNot(WorkoutShape.amrap(600)),
        reason: 'same bar, different colour',
      );
    });

    test('ofSetup refuses anything that is not a setup', () {
      expect(() => WorkoutShape.ofSetup('emom'), throwsArgumentError);
    });

    test('the corner radius is 3 on a Home card and 4 on the live bar', () {
      expect(WorkoutTimeline.radiusFor(12), 3);
      expect(WorkoutTimeline.radiusFor(8), 3);
      expect(WorkoutTimeline.radiusFor(14), 4);
    });
  });
}
