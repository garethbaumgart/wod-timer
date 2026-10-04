// Shared harness for layout tests that need the real app chrome: the
// bundled Outfit font, a device of a given size (phones, and tablets under
// TabletScale), the live timer with a fake engine, and a pixel reading of
// what was painted.
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/core/domain/failures/audio_failure.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/domain/value_objects/unique_id.dart';
import 'package:wod_timer/core/domain/value_objects/workout_name.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_fonts.dart';
import 'package:wod_timer/core/presentation/theme/app_theme.dart';
import 'package:wod_timer/core/presentation/widgets/tablet_scale.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/infrastructure/services/i_timer_engine.dart';
import 'package:wod_timer/features/timer/presentation/pages/timer_active_page.dart';

/// Loads the bundled Outfit weights so text lays out and paints with the
/// real glyph metrics the app ships with.
Future<void> loadOutfit() async {
  configureBundledFonts();
  for (final weight in [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ]) {
    GoogleFonts.outfit(fontWeight: weight);
  }
  await GoogleFonts.pendingFonts();
}

/// A screen the layout rules are tested on.
class Device {
  const Device(this.name, this.size, {this.dpr = 3, this.tablet = false});

  final String name;

  /// Logical points of the physical screen (before TabletScale).
  final Size size;
  final double dpr;

  /// Whether the app's TabletScale wraps the page, as in main.dart.
  final bool tablet;

  static const phone = Device('phone 390x844', Size(390, 844));
  static const phoneLandscape = Device('phone 844x390', Size(844, 390));
  static const tablet13 = Device(
    'tablet 1024x1366',
    Size(1024, 1366),
    dpr: 2,
    tablet: true,
  );
  static const all = [phone, phoneLandscape, tablet13];

  void apply(WidgetTester tester) {
    tester.view
      ..physicalSize = size * dpr
      ..devicePixelRatio = dpr;
    addTearDown(tester.view.reset);
  }
}

/// The key of the RepaintBoundary around every pumped screen.
final screenKey = GlobalKey(debugLabel: 'screen');

/// Wraps [child] the way main.dart does (theme, TabletScale) inside a
/// repaint boundary so the painted pixels can be read back.
Widget appShell(Widget child, {required Device device}) {
  Widget shell = child;
  if (device.tablet) shell = TabletScale(child: shell);
  return RepaintBoundary(key: screenKey, child: shell);
}

/// Reads the painted screen. Returns RGBA bytes and the image size.
Future<({Uint8List rgba, int width, int height})> paintedScreen(
  WidgetTester tester,
) async {
  final boundary =
      screenKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late ui.Image image;
  late ByteData bytes;
  await tester.runAsync(() async {
    image = await boundary.toImage(pixelRatio: tester.view.devicePixelRatio);
    bytes = (await image.toByteData())!;
  });
  return (
    rgba: bytes.buffer.asUint8List(),
    width: image.width,
    height: image.height,
  );
}

/// The lowest painted edge (logical px) inside [region] that is not the
/// background, or null when the region is empty. "Painted" means any
/// channel at least [threshold] away from the ink background. The last
/// row's coverage (how far it is from full ink) gives a sub-pixel edge, so
/// an anti-aliased glyph bottom reads to a fraction of a pixel.
double? lowestInkIn(
  ({Uint8List rgba, int width, int height}) shot,
  Rect region,
  double dpr, {
  int threshold = 48,
}) {
  final bg = AppColors.backgroundDark;
  final br = (bg.r * 255).round();
  final bgG = (bg.g * 255).round();
  final bb = (bg.b * 255).round();
  final x0 = (region.left * dpr).floor().clamp(0, shot.width);
  final x1 = (region.right * dpr).ceil().clamp(0, shot.width);
  final y0 = (region.top * dpr).floor().clamp(0, shot.height);
  final y1 = (region.bottom * dpr).ceil().clamp(0, shot.height);
  int diffAt(int x, int y) {
    final i = (y * shot.width + x) * 4;
    final dr = (shot.rgba[i] - br).abs();
    final dg = (shot.rgba[i + 1] - bgG).abs();
    final db = (shot.rgba[i + 2] - bb).abs();
    return math.max(dr, math.max(dg, db));
  }

  for (var y = y1 - 1; y >= y0; y--) {
    var rowMax = 0;
    for (var x = x0; x < x1; x++) {
      rowMax = math.max(rowMax, diffAt(x, y));
    }
    if (rowMax >= threshold) {
      // Full ink is the strongest pixel in the rows just above.
      var full = rowMax;
      for (var yy = y - 1; yy >= math.max(y0, y - 6); yy--) {
        for (var x = x0; x < x1; x++) {
          full = math.max(full, diffAt(x, yy));
        }
      }
      final coverage = (rowMax / full).clamp(0.0, 1.0);
      return (y + coverage) / dpr;
    }
  }
  return null;
}

class MockAudioService extends Mock implements IAudioService {}

class MockHapticService extends Mock implements IHapticService {}

class FakeTimerEngine implements ITimerEngine {
  final _controller = StreamController<Duration>.broadcast(sync: true);
  Duration _elapsed = Duration.zero;

  @override
  Stream<Duration> get tickStream => _controller.stream;

  void emit(Duration elapsed) {
    _elapsed = elapsed;
    _controller.add(elapsed);
  }

  @override
  Duration get elapsed => _elapsed;
  @override
  bool get isRunning => true;
  @override
  bool get isPaused => false;
  @override
  void start() {}
  @override
  void pause() {}
  @override
  void resume() {}
  @override
  void stop() {}
  @override
  void reset() => _elapsed = Duration.zero;
  @override
  void dispose() => _controller.close();
}

Workout amrapWorkout({int seconds = 600, int prep = 0}) => Workout(
  id: UniqueId(),
  name: WorkoutName.defaultAmrap,
  timerType: AmrapTimer(duration: TimerDuration.fromSeconds(seconds)),
  prepCountdown: TimerDuration.fromSeconds(prep),
  createdAt: DateTime.now(),
);

Workout forTimeWorkout({required bool countUp, int cap = 1200}) => Workout(
  id: UniqueId(),
  name: WorkoutName.defaultForTime,
  timerType: ForTimeTimer(
    timeCap: TimerDuration.fromSeconds(cap),
    countUp: countUp,
  ),
  prepCountdown: TimerDuration.zero,
  createdAt: DateTime.now(),
);

Workout emomWorkout({int interval = 60, int rounds = 10, int prep = 0}) =>
    Workout(
      id: UniqueId(),
      name: WorkoutName.defaultEmom,
      timerType: EmomTimer(
        intervalDuration: TimerDuration.fromSeconds(interval),
        rounds: RoundCount.fromInt(rounds),
      ),
      prepCountdown: TimerDuration.fromSeconds(prep),
      createdAt: DateTime.now(),
    );

Workout tabataWorkout({int rounds = 8, int rest = 10, int prep = 0}) => Workout(
  id: UniqueId(),
  name: WorkoutName.defaultTabata,
  timerType: TabataTimer(
    workDuration: TimerDuration.fromSeconds(20),
    restDuration: TimerDuration.fromSeconds(rest),
    rounds: RoundCount.fromInt(rounds),
  ),
  prepCountdown: TimerDuration.fromSeconds(prep),
  createdAt: DateTime.now(),
);

/// The live timer page with a fake engine and silent services.
class LiveHarness {
  LiveHarness() {
    when(() => audio.setVoicePack(any())).thenReturn(null);
    when(
      () => audio.setRandomizePerCue(enabled: any(named: 'enabled')),
    ).thenReturn(null);
    when(
      () => audio.setVoiceMuted(muted: any(named: 'muted')),
    ).thenReturn(null);
    for (final cue in <Future<Either<AudioFailure, Unit>> Function()>[
      () => audio.playGo(),
      () => audio.playLetsGo(),
      () => audio.playGoodJob(),
      () => audio.playThatsIt(),
      () => audio.playComplete(),
      () => audio.playGetReady(),
      () => audio.playRest(),
      () => audio.playNextRound(),
      () => audio.playLastRound(),
      () => audio.playHalfway(),
      () => audio.playKeepGoing(),
      () => audio.playComeOn(),
      () => audio.playAlmostThere(),
      () => audio.playTenSeconds(),
      () => audio.playFinalCountdown(),
    ]) {
      when(cue).thenAnswer((_) async => right(unit));
    }
    when(() => audio.playCountdown(any())).thenAnswer((_) async => right(unit));
    when(() => audio.playLowBeep(any())).thenAnswer((_) async => right(unit));
    when(audio.playHighBeep).thenAnswer((_) async => right(unit));
    when(() => haptic.heavyImpact()).thenAnswer((_) async => right(unit));
    when(() => haptic.mediumImpact()).thenAnswer((_) async => right(unit));
    when(() => haptic.success()).thenAnswer((_) async => right(unit));
    when(() => haptic.warning()).thenAnswer((_) async => right(unit));
    when(() => haptic.selectionClick()).thenAnswer((_) async => right(unit));
  }

  final audio = MockAudioService();
  final haptic = MockHapticService();
  final engine = FakeTimerEngine();
  late ProviderContainer container;

  /// The notifier's clock, so round counts clear their cooldown.
  DateTime now = DateTime(2026, 10, 3, 6);

  /// Advances the clock past the round-count cooldown.
  void later() => now = now.add(const Duration(seconds: 1));

  /// The live page talks to the wakelock over a pigeon channel; answer it
  /// so a real event loop (toImage) never sees a channel error.
  static void mockPlatformChannels() {
    const codec = StandardMessageCodec();
    const prefix =
        'dev.flutter.pigeon.wakelock_plus_platform_interface.'
        'WakelockPlusApi.';
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger
      ..setMockMessageHandler(
        '${prefix}toggle',
        (_) async => codec.encodeMessage(<Object?>[null]),
      )
      ..setMockMessageHandler(
        '${prefix}isEnabled',
        (_) async => codec.encodeMessage(<Object?>[false]),
      );
  }

  TimerNotifier get notifier => container.read(timerNotifierProvider.notifier);

  /// Pumps the live page for [workout] on [device], [elapsed] in.
  Future<void> pump(
    WidgetTester tester, {
    required Workout workout,
    required String type,
    required Device device,
    Duration elapsed = Duration.zero,
    Map<String, Object> prefs = const {},
    double textScale = 1,
  }) async {
    device.apply(tester);
    mockPlatformChannels();
    TimerNotifier.clock = () => now;
    addTearDown(() => TimerNotifier.clock = DateTime.now);
    SharedPreferences.setMockInitialValues(prefs);
    final sharedPrefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        audioServiceProvider.overrideWithValue(audio),
        hapticServiceProvider.overrideWithValue(haptic),
        timerEngineProvider.overrideWithValue(engine),
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
    );
    addTearDown(container.dispose);
    await notifier.start(workout);

    final router = GoRouter(
      initialLocation: AppRoutes.timerActivePath(type),
      routes: [
        GoRoute(
          path: AppRoutes.timerSetup,
          builder: (context, state) =>
              Text('SETUP ${state.pathParameters['timerType']}'),
          routes: [
            GoRoute(
              path: 'active',
              builder: (context, state) => TimerActivePage(timerType: type),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

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
    if (elapsed > Duration.zero) engine.emit(elapsed);
    await tester.pump();
  }
}
