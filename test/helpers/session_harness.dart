// Today's WOD on a fake clock: the session controller over the real timer
// notifier, both engines hand-driven, the cues and haptics recorded by the
// notifier harness.
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';

import 'notifier_harness.dart';

class SessionHarness {
  SessionHarness({
    AppSettings settings = const AppSettings(voice: VoiceOption.major),
  }) {
    h = NotifierHarness(
      settings: settings,
      overrides: [sessionEngineProvider.overrideWithValue(sessionEngine)],
    );
    TodaysWodController.clock = () => h.now;
    telemetryEnabled = true;
    debugTelemetrySend = (name, props) => events.add((name, props));
    h.container.listen<WodRun?>(todaysWodProvider, (_, run) {
      if (run == null) return;
      final step = stepOf(run);
      if (steps.isEmpty || steps.last != step) steps.add(step);
    });
  }

  late final NotifierHarness h;

  /// The session's own engine.
  final sessionEngine = FakeTimerEngine();

  /// Every analytics event, in order.
  final events = <(String, Map<String, dynamic>)>[];

  /// The run's path: "0 getReady", "0 setWork 1", "1 rest", "2 timer" ...
  final steps = <String>[];

  static String stepOf(WodRun run) => switch (run.phase) {
    WodPhase.setWork ||
    WodPhase.setRest => '${run.index} ${run.phase.name} ${run.set}',
    _ => '${run.index} ${run.phase.name}',
  };

  TodaysWodController get controller =>
      h.container.read(todaysWodProvider.notifier);
  WodRun get run => h.container.read(todaysWodProvider)!;
  WodRun? get runOrNull => h.container.read(todaysWodProvider);
  TimerNotifierState get timer => h.state;

  Future<void> start(List<SessionBlock> blocks) async {
    await controller.start(WodSession(blocks));
    await flush();
  }

  /// Lets the timer notifier's start and the hand-overs settle.
  Future<void> flush() async {
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Runs both clocks forward by [seconds], one tick per [stepMs].
  Future<void> advance(num seconds, {int stepMs = 1000}) async {
    var left = (seconds * 1000).round();
    while (left > 0) {
      final step = left < stepMs ? left : stepMs;
      left -= step;
      _emit(sessionEngine, step);
      _emit(h.engine, step);
      await flush();
    }
  }

  /// One tick of [ms] on both clocks at once (the app was suspended).
  Future<void> jump(int ms) async {
    _emit(sessionEngine, ms);
    _emit(h.engine, ms);
    await flush();
  }

  static void _emit(FakeTimerEngine engine, int ms) {
    if (!engine.isRunning || engine.isPaused) return;
    engine.emit(engine.elapsed + Duration(milliseconds: ms));
  }

  /// Taps that follow one another wait out the controllers' cooldowns.
  void later() => h.later();

  List<(String, Map<String, dynamic>)> eventsNamed(String name) =>
      events.where((e) => e.$1 == name).toList();

  void dispose() {
    h.dispose();
    TodaysWodController.clock = DateTime.now;
    telemetryEnabled = false;
    debugTelemetrySend = null;
  }
}
