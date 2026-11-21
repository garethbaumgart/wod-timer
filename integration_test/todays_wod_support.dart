// Today's WOD on a device (2.6.0): the real app with its real engines on a
// clock that can run fast and be held still, so a whole session is driven
// in minutes and each screen is captured at the moment the mocks show.
// Prints MARK_<name> lines; tool/capture_todays_wod.sh screenshots the
// device at each one.
//
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/core/presentation/theme/app_fonts.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/infrastructure/services/i_timer_engine.dart';
import 'package:wod_timer/injection.dart';
import 'package:wod_timer/main.dart';

/// The one clock every capture engine reads: real time times [speed],
/// standing still while [frozen].
abstract class CaptureClock {
  static double speed = 1;
  static bool frozen = false;

  static final Stopwatch _real = Stopwatch()..start();
  static Duration _lastReal = Duration.zero;
  static Duration _virtual = Duration.zero;

  static Duration now() {
    final real = _real.elapsed;
    if (!frozen) _virtual += (real - _lastReal) * speed;
    _lastReal = real;
    return _virtual;
  }
}

/// [ITimerEngine] on [CaptureClock]: the production engine's contract,
/// ticking every 20ms of real time.
class CaptureEngine implements ITimerEngine {
  final _controller = StreamController<Duration>.broadcast();
  Timer? _timer;
  Duration _mark = Duration.zero;
  Duration _banked = Duration.zero;
  bool _running = false;
  bool _paused = false;

  @override
  Stream<Duration> get tickStream => _controller.stream;

  @override
  Duration get elapsed {
    if (!_running) return Duration.zero;
    if (_paused) return _banked;
    return _banked + (CaptureClock.now() - _mark);
  }

  @override
  bool get isRunning => _running && !_paused;

  @override
  bool get isPaused => _paused;

  @override
  void start() {
    _running = true;
    _paused = false;
    _banked = Duration.zero;
    _mark = CaptureClock.now();
    _tick();
  }

  @override
  void pause() {
    if (!_running || _paused) return;
    _banked = elapsed;
    _paused = true;
    _timer?.cancel();
  }

  @override
  void resume() {
    if (!_paused) return;
    _paused = false;
    _mark = CaptureClock.now();
    _tick();
  }

  @override
  void stop() {
    _running = false;
    _paused = false;
    _banked = Duration.zero;
    _timer?.cancel();
  }

  @override
  void reset() {
    _banked = Duration.zero;
    _mark = CaptureClock.now();
  }

  @override
  void dispose() {
    stop();
    unawaited(_controller.close());
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      if (!_controller.isClosed) _controller.add(elapsed);
    });
    _controller.add(elapsed);
  }
}

/// Launches the real app as main() does (fonts, DI, prefs, the app), with
/// both engines on [CaptureClock] and [prefs] written first.
Future<void> launchApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  configureBundledFonts();
  await configureDependencies();
  final stored = await SharedPreferences.getInstance();
  await stored.clear();
  for (final MapEntry(:key, :value) in prefs.entries) {
    switch (value) {
      case final int v:
        await stored.setInt(key, v);
      case final bool v:
        await stored.setBool(key, v);
      case final String v:
        await stored.setString(key, v);
    }
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(stored),
        timerEngineProvider.overrideWith((ref) {
          final engine = CaptureEngine();
          ref.onDispose(engine.dispose);
          return engine;
        }),
        sessionEngineProvider.overrideWith((ref) {
          final engine = CaptureEngine();
          ref.onDispose(engine.dispose);
          return engine;
        }),
      ],
      child: const WodTimerApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pump [seconds] of real time.
Future<void> pumpSeconds(WidgetTester tester, double seconds) async {
  final ticks = (seconds * 20).round();
  for (var i = 0; i < ticks; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Pump real time until [test] holds (or the timeout). Returns success.
Future<bool> pumpUntil(
  WidgetTester tester,
  bool Function() test, {
  Duration timeout = const Duration(seconds: 240),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 20));
    if (test()) return true;
  }
  return false;
}

bool shows(String text) => find.text(text).evaluate().isNotEmpty;

/// Holds the clock still, lets the UI settle, prints the mark (the PNG's
/// name), waits for the screenshot, then lets the clock run again.
Future<void> capture(WidgetTester tester, String name) async {
  CaptureClock.frozen = true;
  await pumpSeconds(tester, 0.8);
  print('MARK_$name');
  await pumpSeconds(tester, 3.5);
  CaptureClock.frozen = false;
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).first);
  await tester.pump();
  await pumpSeconds(tester, 0.8);
}

/// The tap cooldowns are real time: wait them out between taps.
Future<void> breath(WidgetTester tester) => pumpSeconds(tester, 0.8);

Future<void> setOrientation(
  WidgetTester tester, {
  required bool landscape,
}) async {
  await SystemChrome.setPreferredOrientations(
    landscape
        ? [DeviceOrientation.landscapeLeft]
        : [DeviceOrientation.portraitUp],
  );
  await pumpSeconds(tester, 2.5);
}

/// Hold-to-stop, held for its full duration.
Future<void> holdStop(WidgetTester tester, Finder cell) async {
  final gesture = await tester.startGesture(tester.getCenter(cell));
  await pumpSeconds(tester, 1.2);
  await gesture.up();
  await pumpSeconds(tester, 0.8);
}

/// A tap above the slab (skip, count, resume).
Future<void> tapCanvas(WidgetTester tester) async {
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  await tester.tapAt(Offset(size.width / 2, size.height * 0.4));
  await tester.pump();
}

final Finder anyScaffold = find.byType(Scaffold);

/// Ends a device run cleanly: the players' position updaters ask for
/// frames for as long as they live, which the test binding reports as an
/// animation left running once the tree is gone (seen on Android).
Future<void> releaseAudio(WidgetTester tester) async {
  await getIt<IAudioService>().dispose();
  await pumpSeconds(tester, 0.5);
}
