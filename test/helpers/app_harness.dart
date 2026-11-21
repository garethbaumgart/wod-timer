// The whole app's router with silent services and hand-driven engines, for
// Today's WOD's screens (2.6.0): Home's card, "+ THEN", the builder, a
// session running and its end screen, on a device of a given size.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/core/domain/failures/audio_failure.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';
import 'package:wod_timer/core/presentation/router/app_router.dart';
import 'package:wod_timer/core/presentation/theme/app_theme.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';

import 'screen_harness.dart';

class AppHarness {
  AppHarness() {
    when(() => audio.setVoicePack(any())).thenReturn(null);
    when(
      () => audio.setRandomizePerCue(enabled: any(named: 'enabled')),
    ).thenReturn(null);
    when(
      () => audio.setVoiceMuted(muted: any(named: 'muted')),
    ).thenReturn(null);
    when(
      () => audio.setMuted(muted: any(named: 'muted')),
    ).thenAnswer((_) async {});
    when(audio.preloadSounds).thenAnswer((_) async {});
    for (final cue in <Future<Either<AudioFailure, Unit>> Function()>[
      audio.playGo,
      audio.playGoodJob,
      audio.playComplete,
      audio.playGetReady,
      audio.playRest,
      audio.playNextRound,
      audio.playLastRound,
      audio.playHalfway,
      audio.playTenSeconds,
    ]) {
      when(cue).thenAnswer((_) async => right(unit));
    }
    when(() => audio.playLowBeep(any())).thenAnswer((_) async => right(unit));
    when(audio.playHighBeep).thenAnswer((_) async => right(unit));
    when(audio.playMidBeep).thenAnswer((_) async => right(unit));
    for (final haptic in [
      this.haptic.lightImpact,
      this.haptic.mediumImpact,
      this.haptic.heavyImpact,
      this.haptic.selectionClick,
      this.haptic.success,
      this.haptic.warning,
    ]) {
      when(haptic).thenAnswer((_) async => right(unit));
    }
  }

  final audio = MockAudioService();
  final haptic = MockHapticService();
  final timerEngine = FakeTimerEngine();
  final sessionEngine = FakeTimerEngine();
  late ProviderContainer container;
  late SharedPreferences prefs;

  /// Analytics events, in order.
  final events = <(String, Map<String, dynamic>)>[];

  DateTime now = DateTime(2026, 11, 20, 6);

  /// Advances the controllers' tap cooldown clock.
  void later() => now = now.add(const Duration(seconds: 1));

  /// The app's router, held for the test (its provider auto-disposes).
  late GoRouter router;

  /// Pumps the app at [location] on [device].
  Future<void> pump(
    WidgetTester tester, {
    required Device device,
    String location = '/',
    Map<String, Object> stored = const {},
    double textScale = 1,
  }) async {
    device.apply(tester);
    LiveHarness.mockPlatformChannels();
    TimerNotifier.clock = () => now;
    TodaysWodController.clock = () => now;
    telemetryEnabled = true;
    debugTelemetrySend = (name, props) => events.add((name, props));
    addTearDown(() {
      TimerNotifier.clock = DateTime.now;
      TodaysWodController.clock = DateTime.now;
      telemetryEnabled = false;
      debugTelemetrySend = null;
    });
    SharedPreferences.setMockInitialValues(Map.of(stored));
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        audioServiceProvider.overrideWithValue(audio),
        hapticServiceProvider.overrideWithValue(haptic),
        timerEngineProvider.overrideWithValue(timerEngine),
        sessionEngineProvider.overrideWithValue(sessionEngine),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    router = container.listen(appRouterProvider, (_, _) {}).read();
    router.go(location);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          builder: (context, child) => appShell(
            MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            device: device,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Runs both engines on by [seconds], a frame per second.
  Future<void> advance(WidgetTester tester, int seconds) async {
    for (var i = 0; i < seconds; i++) {
      // The tap cooldowns' clock keeps time with the engines.
      now = now.add(const Duration(seconds: 1));
      for (final engine in [sessionEngine, timerEngine]) {
        engine.emit(engine.elapsed + const Duration(seconds: 1));
      }
      await tester.pump();
      await tester.pump();
    }
  }

  List<Map<String, dynamic>> eventsNamed(String name) => [
    for (final (n, props) in events)
      if (n == name) props,
  ];
}
