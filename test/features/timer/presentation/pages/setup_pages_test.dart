import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/pages/pages.dart';

/// Records the workout START launches instead of running a real timer.
class _RecordingTimerNotifier extends TimerNotifier {
  Workout? started;

  @override
  TimerNotifierState build() => const TimerNotifierState.initial();

  @override
  Future<void> start(Workout workout) async => started = workout;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingTimerNotifier timer;

  /// Pumps [page] on an iPhone-16e-sized portrait screen with [stored] as
  /// the device's SharedPreferences.
  Future<SharedPreferences> pumpSetup(
    WidgetTester tester,
    Widget page, {
    Map<String, Object> stored = const {},
  }) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(Map.of(stored));
    final prefs = await SharedPreferences.getInstance();
    timer = _RecordingTimerNotifier();

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
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return prefs;
  }

  Future<void> tapLabel(WidgetTester tester, String semanticsLabel) async {
    await tester.tap(find.bySemanticsLabel(semanticsLabel));
    await tester.pump();
  }

  group('EMOM setup', () {
    testWidgets('shows each number once, with nothing repeated', (
      tester,
    ) async {
      await pumpSetup(tester, const EmomSetupPage());

      expect(find.text('EVERY'), findsOneWidget);
      expect(find.text('1:00'), findsOneWidget);
      expect(find.text('ROUNDS'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.textContaining('10:00'), findsOneWidget); // the total
      expect(find.text('Major'), findsOneWidget); // voice chip

      // The old furniture is gone.
      expect(find.text('SUMMARY'), findsNothing);
      expect(find.text('NUMBER OF ROUNDS'), findsNothing);
      expect(find.text('hold to repeat'), findsNothing);
      expect(find.textContaining('get-ready'), findsNothing);
      expect(find.text('1m'), findsNothing);
    });

    testWidgets('voice chip sits flush right in the header', (tester) async {
      await pumpSetup(tester, const EmomSetupPage());

      final chip = tester.getRect(find.text('Major'));
      // 16pt screen padding + 15pt chip padding + 1.5pt border.
      expect(chip.right, greaterThan(390 - 16 - 15 - 4));
    });

    testWidgets('one stepper moves the interval in 15s and updates the total', (
      tester,
    ) async {
      await pumpSetup(tester, const EmomSetupPage());

      await tapLabel(tester, 'Increase interval');
      await tapLabel(tester, 'Increase interval');

      expect(find.text('1:30'), findsOneWidget);
      expect(find.textContaining('15:00'), findsOneWidget);
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

      expect(find.text('1:30'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.textContaining('18:00'), findsOneWidget);
    });

    testWidgets('START remembers the setup and launches exactly it', (
      tester,
    ) async {
      final prefs = await pumpSetup(tester, const EmomSetupPage());

      await tapLabel(tester, 'Increase interval');
      await tapLabel(tester, 'Decrease rounds');
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();

      expect(prefs.getInt(SetupMemory.emomIntervalKey), 75);
      expect(prefs.getInt(SetupMemory.emomRoundsKey), 9);

      final type = timer.started!.timerType as EmomTimer;
      expect(type.intervalDuration.seconds, 75);
      expect(type.rounds.value, 9);
      expect(find.text('ACTIVE emom'), findsOneWidget);
    });

    testWidgets('a stepper at its limit is disabled', (tester) async {
      await pumpSetup(
        tester,
        const EmomSetupPage(),
        stored: {SetupMemory.emomRoundsKey: 1},
      );

      await tapLabel(tester, 'Decrease rounds');

      expect(find.text('1'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Decrease rounds')),
        containsSemantics(isEnabled: false),
      );
    });
  });

  group('Tabata setup', () {
    // Regression: RoundPicker copied its value once in initState, so
    // "Reset to classic" set rounds to 8 everywhere except the stepper,
    // which kept showing the old count and sent old+1 on the next tap.
    testWidgets('Reset to classic resets the rounds stepper too', (
      tester,
    ) async {
      await pumpSetup(tester, const TabataSetupPage());

      await tapLabel(tester, 'Increase rounds');
      await tapLabel(tester, 'Increase rounds');
      expect(find.text('10'), findsOneWidget);
      expect(find.text('RESET TO CLASSIC'), findsOneWidget);

      await tester.tap(find.text('RESET TO CLASSIC'));
      await tester.pump();
      expect(find.text('8'), findsOneWidget);
      expect(find.text('CLASSIC TABATA'), findsOneWidget);

      await tapLabel(tester, 'Increase rounds');
      expect(find.text('9'), findsOneWidget);
      expect(find.text('11'), findsNothing);
    });

    testWidgets('each value appears once and the total is shown', (
      tester,
    ) async {
      await pumpSetup(tester, const TabataSetupPage());

      expect(find.text('20s'), findsOneWidget);
      expect(find.text('10s'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.textContaining('4:00'), findsOneWidget);
      expect(find.textContaining('20s work'), findsNothing);
    });

    testWidgets('fits an iPhone 16e without scrolling', (tester) async {
      await pumpSetup(tester, const TabataSetupPage());

      final start = tester.getRect(find.text('START'));
      final rounds = tester.getRect(find.text('8'));
      expect(rounds.bottom, lessThan(start.top));
      expect(tester.takeException(), isNull);
    });
  });

  group('AMRAP setup', () {
    testWidgets('moves in whole minutes and shows no summary', (tester) async {
      await pumpSetup(tester, const AmrapSetupPage());

      expect(find.text('10:00'), findsOneWidget);
      await tapLabel(tester, 'Increase duration');
      expect(find.text('11:00'), findsOneWidget);
      expect(find.text('WORKOUT TIME'), findsNothing);
    });
  });

  group('For Time setup', () {
    testWidgets('count direction is one switch and is remembered', (
      tester,
    ) async {
      final prefs = await pumpSetup(tester, const ForTimeSetupPage());

      expect(find.text('20:00'), findsOneWidget);
      await tester.tap(find.text('COUNT DOWN'));
      await tester.pump();
      await tapLabel(tester, 'Decrease time cap');
      expect(find.text('19:00'), findsOneWidget);

      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();

      expect(prefs.getBool(SetupMemory.forTimeCountUpKey), isFalse);
      expect(prefs.getInt(SetupMemory.forTimeCapKey), 1140);
      final type = timer.started!.timerType as ForTimeTimer;
      expect(type.countUp, isFalse);
      expect(type.timeCap.seconds, 1140);
    });
  });
}
