import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/pages/pages.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_scaffold.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_wheel.dart';
import 'package:wod_timer/features/timer/presentation/widgets/stopwatch_bezel.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';

/// Records the workout START launches instead of running a real timer.
class _RecordingTimerNotifier extends TimerNotifier {
  Workout? started;

  @override
  TimerNotifierState build() => const TimerNotifierState.initial();

  @override
  Future<void> start(Workout workout) async => started = workout;
}

class _MockHapticService extends Mock implements IHapticService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingTimerNotifier timer;
  late _MockHapticService haptic;

  /// Pumps [page] on a [size] screen (iPhone 16e portrait by default) with
  /// [stored] as the device's SharedPreferences, the system text size at
  /// [textScale] and [padding] as the safe area, then waits out the START
  /// guard unless [waitOutGuard] is false.
  Future<SharedPreferences> pumpSetup(
    WidgetTester tester,
    Widget page, {
    Map<String, Object> stored = const {},
    bool waitOutGuard = true,
    Size size = const Size(390, 844),
    double textScale = 1,
    FakeViewPadding padding = FakeViewPadding.zero,
  }) async {
    tester.view
      ..physicalSize = size * 3
      ..devicePixelRatio = 3
      ..padding = padding
      ..viewPadding = padding;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(Map.of(stored));
    final prefs = await SharedPreferences.getInstance();
    timer = _RecordingTimerNotifier();
    haptic = _MockHapticService();
    when(haptic.selectionClick).thenAnswer((_) async => right(unit));

    final router = GoRouter(
      initialLocation: '/setup',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('HOME')),
        GoRoute(path: '/setup', builder: (_, _) => page),
        GoRoute(
          path: '/timer/:timerType/active',
          builder: (_, state) =>
              Text('ACTIVE ${state.pathParameters['timerType']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          timerNotifierProvider.overrideWith(() => timer),
          hapticServiceProvider.overrideWithValue(haptic),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (waitOutGuard) await tester.pump(SetupScaffold.startGuard);
    return prefs;
  }

  /// The adjustable semantics node of a bezel or wheel.
  Future<void> adjust(
    WidgetTester tester,
    String label,
    SemanticsAction action,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pump();
    final node = tester.getSemantics(find.bySemanticsLabel(label));
    tester.binding.pipelineOwner.semanticsOwner!.performAction(node.id, action);
    await tester.pumpAndSettle();
    handle.dispose();
  }

  Finder wheelOf(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(SetupWheel));

  /// Drags a wheel by [steps] rows (positive = towards higher values).
  Future<void> spin(WidgetTester tester, String label, int steps) async {
    final rowHeight = tester.widget<SetupWheel>(wheelOf(label)).rowHeight;
    await tester.drag(wheelOf(label), Offset(0, -steps * rowHeight));
    await tester.pumpAndSettle();
  }

  Rect slabRect(WidgetTester tester) => tester.getRect(find.byType(BottomSlab));

  group('system back on setup (1.3.0)', () {
    testWidgets('goes Home instead of closing the app', (tester) async {
      await pumpSetup(tester, const AmrapSetupPage());
      expect(find.text('HOME'), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);
    });
  });

  group('START slab (1.3.1)', () {
    testWidgets('is edge to edge, 132pt, to the very bottom', (tester) async {
      await pumpSetup(
        tester,
        const EmomSetupPage(),
        padding: const FakeViewPadding(bottom: 34 * 3),
      );

      final slab = slabRect(tester);
      expect(slab.width, 390);
      expect(slab.height, BottomSlab.tall);
      expect(slab.bottom, 844);
      final label = tester.getRect(find.text('START'));
      // Content clear of the home indicator.
      expect(label.bottom, lessThan(844 - 34));
      expect(tester.widget<Text>(find.text('START')).style!.fontSize, 34);
      expect(find.text('START'), findsOneWidget);
    });

    testWidgets('EMOM carries its total inside START', (tester) async {
      await pumpSetup(tester, const EmomSetupPage());

      final total = tester.getRect(find.text('10:00 total'));
      expect(slabRect(tester).contains(total.center), isTrue);
      expect(
        total.top,
        greaterThan(tester.getRect(find.text('START')).bottom - 1),
      );
      expect(
        find.bySemanticsLabel('Start workout. 10:00 total'),
        findsOneWidget,
      );
    });

    testWidgets('Tabata carries its total inside START', (tester) async {
      await pumpSetup(tester, const TabataSetupPage());

      expect(
        slabRect(
          tester,
        ).contains(tester.getRect(find.text('4:00 total')).center),
        isTrue,
      );
    });

    testWidgets('AMRAP has no subtitle: its one value is the total', (
      tester,
    ) async {
      await pumpSetup(tester, const AmrapSetupPage());

      expect(find.textContaining('total'), findsNothing);
      expect(slabRect(tester).height, BottomSlab.tall);
      expect(find.bySemanticsLabel('Start workout'), findsOneWidget);
    });

    testWidgets('For Time says the direction and the cap under START', (
      tester,
    ) async {
      await pumpSetup(tester, const ForTimeSetupPage());

      expect(find.text('Counts up · cap 20:00'), findsOneWidget);
      await tester.tap(find.text('COUNT DOWN'));
      await tester.pump();
      expect(find.text('Counts down · cap 20:00'), findsOneWidget);
    });

    testWidgets('the mode heading is white (1.3.1)', (tester) async {
      await pumpSetup(tester, const EmomSetupPage());

      expect(
        tester.widget<Text>(find.text('EMOM')).style?.color,
        AppColors.textPrimaryDark,
      );
    });

    testWidgets('no plus or minus anywhere', (tester) async {
      for (final page in const <Widget>[
        AmrapSetupPage(),
        ForTimeSetupPage(),
        EmomSetupPage(),
        TabataSetupPage(),
      ]) {
        await pumpSetup(tester, page);
        expect(find.byIcon(Icons.add), findsNothing);
        expect(find.byIcon(Icons.remove), findsNothing);
        expect(find.textContaining('TAP TO CHANGE'), findsNothing);
      }
    });
  });

  group('EMOM setup', () {
    testWidgets('two wheels, each number once, labels in their colours', (
      tester,
    ) async {
      await pumpSetup(tester, const EmomSetupPage());

      expect(find.text('EVERY'), findsOneWidget);
      expect(find.text('ROUNDS'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('EVERY')).style!.color,
        AppColors.work,
      );
      expect(
        tester.widget<Text>(find.text('ROUNDS')).style!.color,
        AppColors.secondary,
      );
      expect(find.byType(SetupWheel), findsNWidgets(2));
      expect(find.text('Major'), findsOneWidget); // voice chip

      // The selected rows are the big white ones.
      final every = tester.widget<Text>(find.text('1:00'));
      expect(every.style!.color, AppColors.textPrimaryDark);
      expect(every.style!.fontSize, 42);
      final neighbour = tester.widget<Text>(find.text('0:45'));
      expect(neighbour.style!.color, AppColors.textDisabledDark);
      expect(neighbour.style!.fontSize, 28);
      expect(find.text('10'), findsOneWidget);

      // Wheels side by side, under the header, over the timeline.
      final everyRect = tester.getRect(wheelOf('EVERY'));
      final roundsRect = tester.getRect(wheelOf('ROUNDS'));
      expect(roundsRect.left, greaterThan(everyRect.right));
      expect(roundsRect.top, everyRect.top);
      final timeline = tester.getRect(find.byType(WorkoutTimeline));
      expect(timeline.top, greaterThan(everyRect.bottom));
      expect(timeline.bottom, lessThan(slabRect(tester).top));

      // The old furniture is gone.
      expect(find.text('SUMMARY'), findsNothing);
      expect(find.text('hold to repeat'), findsNothing);
    });

    testWidgets('voice chip sits flush right in the header', (tester) async {
      await pumpSetup(tester, const EmomSetupPage());

      final chip = tester.getRect(find.text('Major'));
      // 16pt screen padding + 15pt chip padding + 1.5pt border.
      expect(chip.right, greaterThan(390 - 16 - 15 - 4));
    });

    testWidgets('spinning a wheel moves the interval in 15s and the total', (
      tester,
    ) async {
      await pumpSetup(tester, const EmomSetupPage());

      await spin(tester, 'EVERY', 2);

      expect(find.text('1:30'), findsOneWidget);
      expect(find.text('15:00 total'), findsOneWidget);
      verify(haptic.selectionClick).called(greaterThanOrEqualTo(1));
      final timeline = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(WorkoutTimeline),
          matching: find.byType(CustomPaint),
        ),
      );
      expect((timeline.painter! as TimelinePainter).shape.totalSeconds, 900);
    });

    testWidgets('each wheel is adjustable without dragging', (tester) async {
      await pumpSetup(tester, const EmomSetupPage());

      await adjust(tester, 'Rounds', SemanticsAction.decrease);
      await adjust(tester, 'Rounds', SemanticsAction.decrease);
      expect(find.text('8:00 total'), findsOneWidget);
      await adjust(tester, 'Every', SemanticsAction.increase);
      expect(find.text('10:00 total'), findsOneWidget);

      final handle = tester.ensureSemantics();
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Every')),
        containsSemantics(
          value: '1 minute 15 seconds',
          increasedValue: '1 minute 30 seconds',
          decreasedValue: '1 minute',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('opens on the last EMOM started', (tester) async {
      await pumpSetup(
        tester,
        const EmomSetupPage(),
        stored: {
          SetupMemory.emomIntervalKey: 90,
          SetupMemory.emomRoundsKey: 12,
        },
      );

      final every = tester.widget<Text>(find.text('1:30'));
      expect(every.style!.fontSize, 42);
      final rounds = tester.widget<Text>(find.text('12'));
      expect(rounds.style!.fontSize, 42);
      expect(find.text('18:00 total'), findsOneWidget);
    });

    testWidgets('START remembers the setup and launches exactly it', (
      tester,
    ) async {
      final prefs = await pumpSetup(tester, const EmomSetupPage());

      await spin(tester, 'EVERY', 1);
      await spin(tester, 'ROUNDS', -1);
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();

      expect(prefs.getInt(SetupMemory.emomIntervalKey), 75);
      expect(prefs.getInt(SetupMemory.emomRoundsKey), 9);
      expect(prefs.getString(SetupMemory.lastModeKey), 'emom');

      final type = timer.started!.timerType as EmomTimer;
      expect(type.intervalDuration.seconds, 75);
      expect(type.rounds.value, 9);
      expect(find.text('ACTIVE emom'), findsOneWidget);
    });

    testWidgets('a wheel at its limit cannot go further', (tester) async {
      await pumpSetup(
        tester,
        const EmomSetupPage(),
        stored: {SetupMemory.emomRoundsKey: 1},
      );

      await spin(tester, 'ROUNDS', -3);
      expect(find.text('1:00 total'), findsOneWidget);
      final handle = tester.ensureSemantics();
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Rounds')),
        containsSemantics(hasDecreaseAction: false, hasIncreaseAction: true),
      );
      handle.dispose();
    });
  });

  group('Setup chrome', () {
    testWidgets('the voice chip is grey so START is the only green', (
      tester,
    ) async {
      await pumpSetup(tester, const EmomSetupPage());

      final label = tester.widget<Text>(find.text('Major'));
      expect(label.style!.color, AppColors.textSecondaryDark);
      final icon = tester.widget<Icon>(find.byIcon(Icons.volume_up_outlined));
      expect(icon.color, AppColors.textSecondaryDark);

      final chip = tester.widget<Container>(
        find
            .ancestor(of: find.text('Major'), matching: find.byType(Container))
            .first,
      );
      final decoration = chip.decoration! as BoxDecoration;
      expect(decoration.color, isNull);
      expect(decoration.border!.top.color, AppColors.border);
      expect(decoration.border!.top.width, 1.5);

      // Same size and tap target as before.
      final chipRect = tester.getRect(
        find
            .ancestor(of: find.text('Major'), matching: find.byType(SizedBox))
            .first,
      );
      expect(chipRect.height, 48);
    });

    testWidgets('WORK green, REST pink, ROUNDS blue over their wheels', (
      tester,
    ) async {
      await pumpSetup(tester, const TabataSetupPage());

      expect(
        tester.widget<Text>(find.text('WORK')).style!.color,
        AppColors.work,
      );
      expect(
        tester.widget<Text>(find.text('REST')).style!.color,
        AppColors.rest,
      );
      expect(
        tester.widget<Text>(find.text('ROUNDS')).style!.color,
        AppColors.secondary,
      );
      final label = tester.getRect(find.text('WORK'));
      final value = tester.getRect(find.text('20s'));
      expect((label.center.dx - value.center.dx).abs(), lessThan(3));
      expect(label.bottom, lessThan(value.top));
    });
  });

  group('START guard', () {
    // DONE on the completion screen lands on setup, so the second tap of a
    // double tap on DONE used to hit START and begin a new countdown.
    testWidgets('START ignores taps for 500ms after the screen appears', (
      tester,
    ) async {
      await pumpSetup(tester, const AmrapSetupPage(), waitOutGuard: false);

      // The second tap of a double tap on DONE, landing straight away.
      await tester.tap(find.text('START'));
      await tester.pump();
      expect(timer.started, isNull);
      expect(find.text('ACTIVE amrap'), findsNothing);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.text('START'));
      await tester.pump();
      expect(timer.started, isNull, reason: 'still inside the 500ms');

      await tester.pump(SetupScaffold.startGuard);
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      expect(timer.started, isNotNull);
      expect(find.text('ACTIVE amrap'), findsOneWidget);
    });

    testWidgets('the bezel works straight away; only START waits', (
      tester,
    ) async {
      await pumpSetup(tester, const AmrapSetupPage(), waitOutGuard: false);

      await adjust(tester, 'Duration', SemanticsAction.increase);
      expect(find.text('11:00'), findsOneWidget);
    });
  });

  group('Tabata setup', () {
    // Regression: RoundPicker copied its value once in initState, so
    // "Reset to classic" set rounds to 8 everywhere except the stepper,
    // which kept showing the old count and sent old+1 on the next tap.
    testWidgets('Reset to classic resets the rounds wheel too', (tester) async {
      await pumpSetup(tester, const TabataSetupPage());

      await spin(tester, 'ROUNDS', 2);
      expect(find.text('5:00 total'), findsOneWidget);
      expect(find.text('RESET TO CLASSIC'), findsOneWidget);

      await tester.tap(find.text('RESET TO CLASSIC'));
      await tester.pumpAndSettle();
      expect(find.text('4:00 total'), findsOneWidget);
      expect(tester.widget<Text>(find.text('8')).style!.fontSize, 42);
      expect(find.text('RESET TO CLASSIC'), findsNothing);

      await spin(tester, 'ROUNDS', 1);
      expect(find.text('4:30 total'), findsOneWidget);
      expect(tester.widget<Text>(find.text('9')).style!.fontSize, 42);
    });

    testWidgets('the classic chip is blank until a value drifts', (
      tester,
    ) async {
      await pumpSetup(tester, const TabataSetupPage());

      expect(find.text('RESET TO CLASSIC'), findsNothing);
      final workBefore = tester.getRect(find.text('WORK'));
      final startBefore = tester.getRect(find.text('START'));
      final timelineBefore = tester.getRect(find.byType(WorkoutTimeline));

      await spin(tester, 'WORK', 1);
      expect(find.text('RESET TO CLASSIC'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // The chip filled its reserved slot: nothing else moved.
      expect(tester.getRect(find.text('WORK')), workBefore);
      expect(tester.getRect(find.text('START')), startBefore);
      expect(tester.getRect(find.byType(WorkoutTimeline)), timelineBefore);
      expect(
        tester.getRect(find.text('RESET TO CLASSIC')).bottom,
        lessThan(workBefore.top),
      );
    });

    testWidgets('phase values read 20s under a minute, 1:05 above', (
      tester,
    ) async {
      await pumpSetup(
        tester,
        const TabataSetupPage(),
        stored: {SetupMemory.tabataWorkKey: 65},
      );

      expect(tester.widget<Text>(find.text('1:05')).style!.fontSize, 42);
      expect(find.text('65s'), findsNothing);
      expect(tester.widget<Text>(find.text('10s')).style!.fontSize, 42);
      final handle = tester.ensureSemantics();
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Work')),
        containsSemantics(value: '1 minute 5 seconds'),
      );
      handle.dispose();
    });

    testWidgets('three wheels and the total, nothing scrolls', (tester) async {
      await pumpSetup(tester, const TabataSetupPage());

      expect(find.byType(SetupWheel), findsNWidgets(3));
      expect(find.text('4:00 total'), findsOneWidget);
      expect(find.textContaining('20s work'), findsNothing);
      // Only the wheels scroll; the page itself never has to.
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.takeException(), isNull);
      final rounds = tester.getRect(wheelOf('ROUNDS'));
      expect(rounds.bottom, lessThan(slabRect(tester).top));
      expect(rounds.right, lessThanOrEqualTo(390 - 16 + 0.5));
    });

    testWidgets('the timeline redraws as the wheels move', (tester) async {
      await pumpSetup(tester, const TabataSetupPage());
      TimelinePainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(WorkoutTimeline),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as TimelinePainter;
      expect(painter().shape.parts, hasLength(16));

      await spin(tester, 'ROUNDS', -2);
      expect(painter().shape.parts, hasLength(12));
      expect(painter().shape.colorOf(painter().shape.parts[1]), AppColors.rest);
    });
  });

  group('AMRAP setup', () {
    testWidgets('the bezel shows the duration as m:00 with its label', (
      tester,
    ) async {
      await pumpSetup(tester, const AmrapSetupPage());

      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('DURATION'), findsOneWidget);
      expect(find.byType(StopwatchBezel), findsOneWidget);
      expect(tester.getSize(find.byType(StopwatchBezel)), const Size(270, 270));
      expect(
        tester.widget<StopwatchBezel>(find.byType(StopwatchBezel)).accent,
        AppColors.amrapAccent,
      );
      expect(
        find.text('Turn the bezel · one turn is 60 minutes'),
        findsOneWidget,
      );
      expect(find.text('WORKOUT TIME'), findsNothing);
    });

    testWidgets('a touch on the ring sets the minutes at that angle', (
      tester,
    ) async {
      await pumpSetup(tester, const AmrapSetupPage());
      final bezel = tester.getRect(find.byType(StopwatchBezel));

      // 6 o'clock is 30 minutes.
      await tester.tapAt(Offset(bezel.center.dx, bezel.bottom - 20));
      await tester.pump();
      expect(find.text('30:00'), findsOneWidget);
      verify(haptic.selectionClick).called(1);

      // 3 o'clock is 15.
      await tester.tapAt(Offset(bezel.right - 20, bezel.center.dy));
      await tester.pump();
      expect(find.text('15:00'), findsOneWidget);
    });

    testWidgets("dragging past 12 o'clock holds at 60, never wraps to 1", (
      tester,
    ) async {
      await pumpSetup(
        tester,
        const AmrapSetupPage(),
        stored: {SetupMemory.amrapDurationKey: 55 * 60},
      );
      final bezel = tester.getRect(find.byType(StopwatchBezel));
      // Start at about 11 o'clock and sweep clockwise through 12 to 1.
      final gesture = await tester.startGesture(
        Offset(bezel.center.dx - 60, bezel.top + 30),
      );
      await tester.pump();
      await gesture.moveTo(Offset(bezel.center.dx - 10, bezel.top + 22));
      await tester.pump();
      await gesture.moveTo(Offset(bezel.center.dx + 40, bezel.top + 26));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(find.text('60:00'), findsOneWidget);
      expect(find.text('1:00'), findsNothing);
    });

    testWidgets('the bezel is adjustable without dragging', (tester) async {
      final prefs = await pumpSetup(tester, const AmrapSetupPage());

      await adjust(tester, 'Duration', SemanticsAction.increase);
      expect(find.text('11:00'), findsOneWidget);
      await adjust(tester, 'Duration', SemanticsAction.decrease);
      await adjust(tester, 'Duration', SemanticsAction.decrease);
      expect(find.text('9:00'), findsOneWidget);

      final handle = tester.ensureSemantics();
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Duration')),
        containsSemantics(
          value: '9 minutes',
          increasedValue: '10 minutes',
          decreasedValue: '8 minutes',
        ),
      );
      handle.dispose();

      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      expect(prefs.getInt(SetupMemory.amrapDurationKey), 540);
      expect(prefs.getString(SetupMemory.lastModeKey), 'amrap');
    });
  });

  group('For Time setup', () {
    testWidgets('count direction is a switch under the bezel, remembered', (
      tester,
    ) async {
      final prefs = await pumpSetup(tester, const ForTimeSetupPage());

      expect(find.text('20:00'), findsOneWidget);
      expect(find.text('TIME CAP'), findsOneWidget);
      expect(find.text('COUNT UP'), findsOneWidget);
      expect(find.text('COUNT DOWN'), findsOneWidget);
      final bezel = tester.getRect(find.byType(StopwatchBezel));
      final up = tester.getRect(find.text('COUNT UP'));
      final down = tester.getRect(find.text('COUNT DOWN'));
      expect(up.top, greaterThan(bezel.bottom));
      expect(down.left, greaterThan(up.right));
      expect(
        tester.widget<Text>(find.text('COUNT UP')).style!.color,
        Colors.black,
      );
      expect(
        tester.widget<Text>(find.text('COUNT DOWN')).style!.color,
        AppColors.textSecondaryDark,
      );

      await tester.tap(find.text('COUNT DOWN'));
      await tester.pump();
      expect(
        tester.widget<Text>(find.text('COUNT DOWN')).style!.color,
        Colors.black,
      );
      await adjust(tester, 'Time cap', SemanticsAction.decrease);
      expect(find.text('19:00'), findsOneWidget);

      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();

      expect(prefs.getBool(SetupMemory.forTimeCountUpKey), isFalse);
      expect(prefs.getInt(SetupMemory.forTimeCapKey), 1140);
      expect(prefs.getString(SetupMemory.lastModeKey), 'fortime');
      final type = timer.started!.timerType as ForTimeTimer;
      expect(type.countUp, isFalse);
      expect(type.timeCap.seconds, 1140);
    });

    testWidgets('the bezel ticks are For Time orange', (tester) async {
      await pumpSetup(tester, const ForTimeSetupPage());
      expect(
        tester.widget<StopwatchBezel>(find.byType(StopwatchBezel)).accent,
        AppColors.forTimeAccent,
      );
    });
  });

  group('Landscape setup', () {
    const landscape = Size(844, 390);
    // iPhone 16e held sideways: the notch side and the home indicator.
    const notchedLandscape = FakeViewPadding(left: 141, right: 141, bottom: 63);

    testWidgets('Tabata puts its three wheels in a row over the timeline', (
      tester,
    ) async {
      await pumpSetup(tester, const TabataSetupPage(), size: landscape);

      expect(tester.takeException(), isNull);
      final work = tester.getRect(find.text('WORK'));
      final rest = tester.getRect(find.text('REST'));
      final rounds = tester.getRect(find.text('ROUNDS'));
      expect(rest.top, work.top);
      expect(rounds.top, work.top);
      expect(rest.left, greaterThan(work.right));
      expect(rounds.left, greaterThan(rest.right));
      expect((work.center.dx + rounds.center.dx) / 2, closeTo(844 / 2, 2));
      expect(tester.widget<SetupWheel>(wheelOf('WORK')).rowHeight, 44);

      // The short slab along the bottom, full width, carrying the total.
      final slab = slabRect(tester);
      expect(slab.width, 844);
      expect(slab.height, BottomSlab.short);
      expect(slab.bottom, 390);
      expect(
        slab.contains(tester.getRect(find.text('4:00 total')).center),
        isTrue,
      );
      final timeline = tester.getRect(find.byType(WorkoutTimeline));
      expect(
        timeline.top,
        greaterThan(tester.getRect(wheelOf('ROUNDS')).bottom),
      );
      expect(timeline.bottom, lessThan(slab.top));
    });

    testWidgets('Tabata fits a notched phone held sideways, chip showing', (
      tester,
    ) async {
      await pumpSetup(
        tester,
        const TabataSetupPage(),
        size: landscape,
        padding: notchedLandscape,
        stored: {SetupMemory.tabataWorkKey: 65},
      );

      expect(tester.takeException(), isNull);
      expect(find.text('RESET TO CLASSIC'), findsOneWidget);
      final chip = tester.getRect(find.text('RESET TO CLASSIC'));
      final work = tester.getRect(find.text('WORK'));
      expect(chip.bottom, lessThan(work.top));
      expect(tester.getRect(wheelOf('WORK')).left, greaterThanOrEqualTo(47));
      expect(
        tester.getRect(wheelOf('ROUNDS')).right,
        lessThanOrEqualTo(844 - 47),
      );
      expect(tester.getRect(find.text('START')).bottom, lessThan(390 - 21));
    });

    testWidgets('EMOM puts its two wheels side by side', (tester) async {
      await pumpSetup(tester, const EmomSetupPage(), size: landscape);

      expect(tester.takeException(), isNull);
      final every = tester.getRect(find.text('EVERY'));
      final rounds = tester.getRect(find.text('ROUNDS'));
      expect(rounds.top, every.top);
      expect(rounds.left, greaterThan(every.right));
      expect((every.center.dx + rounds.center.dx) / 2, closeTo(844 / 2, 2));
    });

    testWidgets('AMRAP shrinks the bezel and puts the hint beside it', (
      tester,
    ) async {
      await pumpSetup(tester, const AmrapSetupPage(), size: landscape);

      expect(tester.takeException(), isNull);
      final bezel = tester.getRect(find.byType(StopwatchBezel));
      expect(bezel.height, lessThan(270));
      expect(bezel.height, greaterThan(150));
      expect(bezel.bottom, lessThan(slabRect(tester).top));
      final hint = tester.getRect(find.textContaining('Turn the bezel'));
      expect(hint.left, greaterThan(bezel.right));
    });

    testWidgets('For Time keeps its switch beside the bezel', (tester) async {
      await pumpSetup(tester, const ForTimeSetupPage(), size: landscape);

      expect(tester.takeException(), isNull);
      final bezel = tester.getRect(find.byType(StopwatchBezel));
      final up = tester.getRect(find.text('COUNT UP'));
      expect(up.left, greaterThan(bezel.right));
      expect(find.text('Counts up · cap 20:00'), findsOneWidget);
    });
  });

  // Older users run a large system text size; every setup screen must
  // still lay out on a 375pt-wide phone, and in landscape.
  group('Large text (1.6x)', () {
    const pages = <String, Widget>{
      'AMRAP': AmrapSetupPage(),
      'For Time': ForTimeSetupPage(),
      'EMOM': EmomSetupPage(),
      'Tabata': TabataSetupPage(),
    };
    for (final entry in pages.entries) {
      testWidgets('${entry.key} lays out at 375pt without overflow', (
        tester,
      ) async {
        await pumpSetup(
          tester,
          entry.value,
          size: const Size(375, 812),
          textScale: 1.6,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('START'), findsOneWidget);
      });

      testWidgets('${entry.key} lays out in landscape without overflow', (
        tester,
      ) async {
        await pumpSetup(
          tester,
          entry.value,
          size: const Size(844, 390),
          textScale: 1.6,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
