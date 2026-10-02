import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
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

    testWidgets('WORK and REST carry their colour without a dot', (
      tester,
    ) async {
      await pumpSetup(tester, const TabataSetupPage());

      final work = tester.widget<Text>(find.text('WORK'));
      expect(work.style!.color, AppColors.work);
      final rest = tester.widget<Text>(find.text('REST'));
      expect(rest.style!.color, AppColors.rest);

      // With no dot beside it, the label centres over its value.
      final label = tester.getRect(find.text('WORK'));
      final value = tester.getRect(find.text('20s'));
      expect((label.center.dx - value.center.dx).abs(), lessThan(3));
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
      expect(find.text('RESET TO CLASSIC'), findsNothing);

      await tapLabel(tester, 'Increase rounds');
      expect(find.text('9'), findsOneWidget);
      expect(find.text('11'), findsNothing);
    });

    testWidgets('the classic chip is blank until a value drifts', (
      tester,
    ) async {
      await pumpSetup(tester, const TabataSetupPage());

      expect(find.text('CLASSIC TABATA'), findsNothing);
      expect(find.text('RESET TO CLASSIC'), findsNothing);
      expect(find.byIcon(Icons.check), findsNothing);
      final workBefore = tester.getRect(find.text('WORK'));
      final startBefore = tester.getRect(find.text('START'));

      await tapLabel(tester, 'Increase work');
      expect(find.text('RESET TO CLASSIC'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      final reset = tester.widget<Text>(find.text('RESET TO CLASSIC'));
      expect(reset.style!.fontSize, 15);
      expect(reset.style!.color, AppColors.textSecondaryDark);

      // The chip filled its reserved slot: nothing below it moved.
      expect(tester.getRect(find.text('WORK')), workBefore);
      expect(tester.getRect(find.text('START')), startBefore);
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

      expect(find.text('1:05'), findsOneWidget);
      expect(find.text('65s'), findsNothing);
      expect(find.text('10s'), findsOneWidget);
      expect(find.bySemanticsLabel('Work: 1 minute 5 seconds'), findsOneWidget);
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
    testWidgets('count direction is one caption line and is remembered', (
      tester,
    ) async {
      final prefs = await pumpSetup(tester, const ForTimeSetupPage());

      expect(find.text('20:00'), findsOneWidget);
      expect(find.text('COUNT UP'), findsNothing);
      expect(find.text('COUNT DOWN'), findsNothing);
      expect(find.text('COUNTS UP \u00B7 TAP TO CHANGE'), findsOneWidget);

      await tester.tap(find.text('COUNTS UP \u00B7 TAP TO CHANGE'));
      await tester.pump();
      expect(find.text('COUNTS DOWN \u00B7 TAP TO CHANGE'), findsOneWidget);
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

    testWidgets('the caption sits under the cap with a 44pt tap target', (
      tester,
    ) async {
      await pumpSetup(
        tester,
        const ForTimeSetupPage(),
        stored: {SetupMemory.forTimeCountUpKey: false},
      );

      final caption = find.text('COUNTS DOWN \u00B7 TAP TO CHANGE');
      final value = tester.getRect(find.text('20:00'));
      final text = tester.getRect(caption);
      expect(text.top, greaterThan(value.bottom));
      expect(text.top - value.bottom, lessThan(30));
      expect((text.center.dx - value.center.dx).abs(), lessThan(3));

      final target = tester.getRect(
        find
            .ancestor(of: caption, matching: find.byType(GestureDetector))
            .first,
      );
      expect(target.height, greaterThanOrEqualTo(44));
      expect(target.contains(text.center), isTrue);

      // White direction words, grey instruction, all 15pt.
      final span = tester.widget<Text>(caption).textSpan! as TextSpan;
      final parts = span.children!.cast<TextSpan>();
      expect(parts.first.text, 'COUNTS DOWN');
      expect(parts.first.style!.color, AppColors.textPrimaryDark);
      expect(parts.last.style!.color, AppColors.textSecondaryDark);
      expect(parts.every((p) => p.style!.fontSize == 15), isTrue);
    });
  });
}
