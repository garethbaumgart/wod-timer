// START on every setup screen: what it remembers and exactly which
// workout it launches, the haptic per control, and the one failure path.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
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

  Future<SharedPreferences> pumpSetup(
    WidgetTester tester,
    Widget page, {
    Map<String, Object> stored = const {},
  }) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
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
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          timerNotifierProvider.overrideWith(() => timer),
          hapticServiceProvider.overrideWithValue(haptic),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(SetupScaffold.startGuard);
    return prefs;
  }

  Finder wheelOf(String label) => find.byWidgetPredicate(
    (w) => w is SetupWheel && w.label.toUpperCase() == label,
  );

  Future<void> spin(WidgetTester tester, String label, int steps) async {
    final wheel = tester.widget<SetupWheel>(wheelOf(label));
    await tester.drag(wheelOf(label), Offset(0, -wheel.rowHeight * steps));
    await tester.pumpAndSettle();
  }

  group('START launches exactly the setup shown', () {
    testWidgets('For Time: the cap and the direction', (tester) async {
      final prefs = await pumpSetup(
        tester,
        const ForTimeSetupPage(),
        stored: {SetupMemory.forTimeCapKey: 900},
      );
      await tester.tap(find.text('COUNT DOWN'));
      await tester.pump();
      verify(haptic.selectionClick).called(1);
      expect(find.text('Counts down · cap 15:00'), findsOneWidget);

      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();

      expect(prefs.getInt(SetupMemory.forTimeCapKey), 900);
      expect(prefs.getBool(SetupMemory.forTimeCountUpKey), isFalse);
      expect(prefs.getString(SetupMemory.lastModeKey), 'fortime');
      final type = timer.started!.timerType as ForTimeTimer;
      expect(type.timeCap.seconds, 900);
      expect(type.countUp, isFalse);
      expect(timer.started!.prepCountdown.seconds, 10);
      expect(timer.started!.name.value, 'For Time Workout');
      expect(find.text('ACTIVE fortime'), findsOneWidget);
    });

    testWidgets('Tabata: work, rest and rounds off the wheels', (tester) async {
      final prefs = await pumpSetup(tester, const TabataSetupPage());
      await spin(tester, 'WORK', 2); // 30s
      await spin(tester, 'REST', 1); // 15s
      await spin(tester, 'ROUNDS', -2); // 6
      verify(haptic.selectionClick).called(3);
      expect(find.text('4:30 total'), findsOneWidget);

      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();

      expect(prefs.getInt(SetupMemory.tabataWorkKey), 30);
      expect(prefs.getInt(SetupMemory.tabataRestKey), 15);
      expect(prefs.getInt(SetupMemory.tabataRoundsKey), 6);
      expect(prefs.getString(SetupMemory.lastModeKey), 'tabata');
      final type = timer.started!.timerType as TabataTimer;
      expect(type.workDuration.seconds, 30);
      expect(type.restDuration.seconds, 15);
      expect(type.rounds.value, 6);
      expect(find.text('ACTIVE tabata'), findsOneWidget);
    });

    testWidgets('AMRAP: the minutes off the bezel, with a tick per minute', (
      tester,
    ) async {
      final prefs = await pumpSetup(tester, const AmrapSetupPage());
      final bezel = tester.getRect(find.byType(StopwatchBezel));
      // 3 o'clock is 15 minutes.
      await tester.tapAt(Offset(bezel.right - 20, bezel.center.dy));
      await tester.pump();
      expect(find.text('15:00'), findsOneWidget);
      verify(haptic.selectionClick).called(1);

      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();

      expect(prefs.getInt(SetupMemory.amrapDurationKey), 900);
      expect(prefs.getString(SetupMemory.lastModeKey), 'amrap');
      final type = timer.started!.timerType as AmrapTimer;
      expect(type.duration.seconds, 900);
      expect(timer.started!.name.value, 'AMRAP Workout');
      expect(find.text('ACTIVE amrap'), findsOneWidget);
    });

    testWidgets('EMOM: a remembered setup launches unchanged', (tester) async {
      final prefs = await pumpSetup(
        tester,
        const EmomSetupPage(),
        stored: {
          SetupMemory.emomIntervalKey: 45,
          SetupMemory.emomRoundsKey: 20,
          SetupMemory.lastModeKey: 'tabata',
        },
      );
      expect(find.text('15:00 total'), findsOneWidget);
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      expect(prefs.getString(SetupMemory.lastModeKey), 'emom');
      final type = timer.started!.timerType as EmomTimer;
      expect(type.intervalDuration.seconds, 45);
      expect(type.rounds.value, 20);
      expect(timer.started!.name.value, 'EMOM Workout');
    });
  });

  group('startSetupWorkout', () {
    testWidgets('an invalid workout shows the error and launches nothing', (
      tester,
    ) async {
      timer = _RecordingTimerNotifier();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => startSetupWorkout(
                    context: context,
                    ref: ref,
                    name: 'Broken',
                    timerType: const AmrapTimer(duration: TimerDuration.zero),
                    route: TimerTypes.amrap,
                  ),
                  child: const Text('GO'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/timer/:timerType/active',
            builder: (_, _) => const Text('ACTIVE'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [timerNotifierProvider.overrideWith(() => timer)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.text('GO'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('AMRAP duration must be greater than 0'),
        findsOneWidget,
      );
      expect(timer.started, isNull);
      expect(find.text('ACTIVE'), findsNothing);
    });
  });
}
