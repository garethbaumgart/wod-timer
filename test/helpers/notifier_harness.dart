// A TimerNotifier wired to recording fakes: a hand-driven engine, a mocked
// audio service and haptic service, an in-memory review prompter and an
// app-settings override, so cue timing, haptics and the review payoff can
// be asserted second by second without a widget tree.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/application/providers/review_prompter_provider.dart';
import 'package:wod_timer/core/domain/failures/audio_failure.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/domain/value_objects/unique_id.dart';
import 'package:wod_timer/core/domain/value_objects/workout_name.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/core/review/review_prompter.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/infrastructure/services/i_timer_engine.dart';

class MockAudioService extends Mock implements IAudioService {}

class MockHapticService extends Mock implements IHapticService {}

/// A timer engine the test drives by hand via [emit]; records its calls.
class FakeTimerEngine implements ITimerEngine {
  final _controller = StreamController<Duration>.broadcast(sync: true);
  final List<String> calls = [];
  Duration _elapsed = Duration.zero;
  bool _running = false;
  bool _paused = false;

  @override
  Stream<Duration> get tickStream => _controller.stream;

  void emit(Duration elapsed) {
    _elapsed = elapsed;
    _controller.add(elapsed);
  }

  @override
  Duration get elapsed => _elapsed;
  @override
  bool get isRunning => _running;
  @override
  bool get isPaused => _paused;

  @override
  void start() {
    calls.add('start');
    _running = true;
    _paused = false;
  }

  @override
  void pause() {
    calls.add('pause');
    _paused = true;
  }

  @override
  void resume() {
    calls.add('resume');
    _paused = false;
  }

  @override
  void stop() {
    calls.add('stop');
    _running = false;
    _paused = false;
  }

  @override
  void reset() {
    calls.add('reset');
    _elapsed = Duration.zero;
  }

  @override
  void dispose() => _controller.close();
}

/// In-memory review store so the policy is observable without prefs.
class MapReviewStore implements ReviewStore {
  final Map<String, int> values = {};

  @override
  Future<int> readInt(String key) async => values[key] ?? 0;

  @override
  Future<void> writeInt(String key, int value) async => values[key] = value;
}

class FakeReviewRequester implements ReviewRequester {
  int requests = 0;
  int listings = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> request() async => requests++;

  @override
  Future<void> openStoreListing() async => listings++;
}

/// App settings pinned to a value, with no SharedPreferences load.
class FixedSettings extends AppSettingsNotifier {
  FixedSettings(this.settings);

  final AppSettings settings;

  @override
  AppSettings build() => settings;
}

Workout amrapWorkout({int seconds = 600, int prep = 0}) => Workout(
  id: UniqueId(),
  name: WorkoutName.defaultAmrap,
  timerType: AmrapTimer(duration: TimerDuration.fromSeconds(seconds)),
  prepCountdown: TimerDuration.fromSeconds(prep),
  createdAt: DateTime.now(),
);

Workout forTimeWorkout({int cap = 1200, bool countUp = true, int prep = 0}) =>
    Workout(
      id: UniqueId(),
      name: WorkoutName.defaultForTime,
      timerType: ForTimeTimer(
        timeCap: TimerDuration.fromSeconds(cap),
        countUp: countUp,
      ),
      prepCountdown: TimerDuration.fromSeconds(prep),
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

Workout tabataWorkout({
  int work = 20,
  int rest = 10,
  int rounds = 8,
  int prep = 0,
}) => Workout(
  id: UniqueId(),
  name: WorkoutName.defaultTabata,
  timerType: TabataTimer(
    workDuration: TimerDuration.fromSeconds(work),
    restDuration: TimerDuration.fromSeconds(rest),
    rounds: RoundCount.fromInt(rounds),
  ),
  prepCountdown: TimerDuration.fromSeconds(prep),
  createdAt: DateTime.now(),
);

/// Every cue the notifier can ask for, keyed by name, so a test can say
/// "only these cues played, in this order".
class NotifierHarness {
  NotifierHarness({AppSettings settings = const AppSettings()}) {
    when(() => audio.setVoicePack(any())).thenReturn(null);
    when(
      () => audio.setRandomizePerCue(enabled: any(named: 'enabled')),
    ).thenReturn(null);
    when(
      () => audio.setVoiceMuted(muted: any(named: 'muted')),
    ).thenReturn(null);
    for (final entry in cues.entries) {
      when(entry.value).thenAnswer((_) async {
        played.add(entry.key);
        return right(unit);
      });
    }
    when(() => audio.playCountdown(any())).thenAnswer((invocation) async {
      played.add('countdown ${invocation.positionalArguments.first}');
      return right(unit);
    });
    for (final entry in haptics.entries) {
      when(entry.value).thenAnswer((_) async {
        felt.add(entry.key);
        return right(unit);
      });
    }
    TimerNotifier.clock = () => now;
    container = ProviderContainer(
      overrides: [
        audioServiceProvider.overrideWithValue(audio),
        hapticServiceProvider.overrideWithValue(haptic),
        timerEngineProvider.overrideWithValue(engine),
        appSettingsNotifierProvider.overrideWith(() => FixedSettings(settings)),
        reviewPrompterProvider.overrideWithValue(
          ReviewPrompter(
            requester: requester,
            store: store,
            now: () => now,
            minValueMoments: 1,
          ),
        ),
      ],
    );
  }

  final audio = MockAudioService();
  final haptic = MockHapticService();
  final engine = FakeTimerEngine();
  final store = MapReviewStore();
  final requester = FakeReviewRequester();
  late final ProviderContainer container;

  /// The voice cues, in the order they were asked for.
  final List<String> played = [];

  /// The haptics, in the order they were asked for.
  final List<String> felt = [];

  DateTime now = DateTime(2026, 10, 4, 6);

  late final Map<String, Future<Either<AudioFailure, Unit>> Function()> cues = {
    'go': audio.playGo,
    'lets go': audio.playLetsGo,
    'get ready': audio.playGetReady,
    'rest': audio.playRest,
    'next round': audio.playNextRound,
    'last round': audio.playLastRound,
    'halfway': audio.playHalfway,
    'keep going': audio.playKeepGoing,
    'come on': audio.playComeOn,
    'almost there': audio.playAlmostThere,
    'ten seconds': audio.playTenSeconds,
    'final countdown': audio.playFinalCountdown,
    'good job': audio.playGoodJob,
    'thats it': audio.playThatsIt,
    'complete': audio.playComplete,
  };

  late final Map<String, Future<Either<HapticFailure, Unit>> Function()>
  haptics = {
    'light': haptic.lightImpact,
    'medium': haptic.mediumImpact,
    'heavy': haptic.heavyImpact,
    'selection': haptic.selectionClick,
    'success': haptic.success,
    'warning': haptic.warning,
  };

  TimerNotifier get notifier => container.read(timerNotifierProvider.notifier);
  TimerNotifierState get state => container.read(timerNotifierProvider);

  /// Advances the fake clock past the round-count cooldown.
  void later() => now = now.add(const Duration(seconds: 1));

  /// Emits one tick at [seconds] of engine time.
  void tick(int seconds, [int millis = 0]) =>
      engine.emit(Duration(seconds: seconds, milliseconds: millis));

  /// Emits a tick every second from [from] to [to] inclusive.
  void run(int from, int to) {
    for (var s = from; s <= to; s++) {
      tick(s);
    }
  }

  /// The review moments recorded so far.
  int get valueMoments => store.values[ReviewPrompter.momentsKey] ?? 0;

  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    container.dispose();
    TimerNotifier.clock = DateTime.now;
  }
}
