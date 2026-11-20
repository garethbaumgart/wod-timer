import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:wod_timer/core/application/providers/review_prompter_provider.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/infrastructure/services/i_timer_engine.dart';
import 'package:wod_timer/features/timer/infrastructure/services/timer_engine.dart';

/// Where a session is: in a block's get-ready (Sets only: a timer block's
/// get-ready is the timer's own), in a timer block, in a Rest block, on a
/// set or in the rest after it, or done.
enum WodPhase { getReady, timer, rest, setWork, setRest, finished }

/// What one block came to, for the end screen.
@immutable
class BlockOutcome {
  const BlockOutcome({
    required this.block,
    this.count,
    this.seconds,
    this.capped = false,
  });

  final SessionBlock block;

  /// Sets done, EMOM and Tabata rounds run, AMRAP rounds counted.
  final int? count;

  /// A For Time's time.
  final int? seconds;

  /// A For Time that ran into its cap.
  final bool capped;
}

/// One run of Today's WOD.
@immutable
class WodRun {
  const WodRun({
    required this.session,
    required this.index,
    required this.phase,
    required this.getReadySeconds,
    this.paused = false,
    this.phaseElapsedMs = 0,
    this.set = 1,
    this.totalMs = 0,
    this.outcomes = const [],
    this.stopped = false,
  });

  final WodSession session;

  /// The block running (the last one, once finished).
  final int index;
  final WodPhase phase;
  final int getReadySeconds;
  final bool paused;

  /// Time into a get-ready, a Rest block or a set's rest.
  final int phaseElapsedMs;

  /// The set a Sets block is on, from 1.
  final int set;

  /// Session time so far, pauses excluded.
  final int totalMs;

  /// The blocks run to their end, in order.
  final List<BlockOutcome> outcomes;

  /// Ended by HOLD TO STOP.
  final bool stopped;

  SessionBlock get block => session.blocks[index];

  int get blockCount => session.blocks.length;

  /// The block after this one, or null on the last.
  SessionBlock? get next =>
      index + 1 < blockCount ? session.blocks[index + 1] : null;

  bool get isFinished => phase == WodPhase.finished;

  /// The length of the counted phase, in seconds (0 when nothing counts).
  int get phaseSeconds => switch (phase) {
    WodPhase.getReady => getReadySeconds,
    WodPhase.rest => (block as RestBlock).seconds,
    WodPhase.setRest => (block as SetsBlock).restSeconds,
    _ => 0,
  };

  /// What the countdown shows: whole seconds left, as the timer counts.
  int get remainingSeconds {
    final left = phaseSeconds - phaseElapsedMs ~/ 1000;
    return left.clamp(0, phaseSeconds);
  }

  WodRun copyWith({
    int? index,
    WodPhase? phase,
    bool? paused,
    int? phaseElapsedMs,
    int? set,
    int? totalMs,
    List<BlockOutcome>? outcomes,
    bool? stopped,
  }) => WodRun(
    session: session,
    getReadySeconds: getReadySeconds,
    index: index ?? this.index,
    phase: phase ?? this.phase,
    paused: paused ?? this.paused,
    phaseElapsedMs: phaseElapsedMs ?? this.phaseElapsedMs,
    set: set ?? this.set,
    totalMs: totalMs ?? this.totalMs,
    outcomes: outcomes ?? this.outcomes,
    stopped: stopped ?? this.stopped,
  );
}

/// The clock under the whole session: session time, and the get-readies
/// and rests the session counts itself. Separate from the timer's engine,
/// which runs each timer block exactly as it runs a timer on its own.
final sessionEngineProvider = Provider<ITimerEngine>((ref) {
  final engine = TimerEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

/// Runs Today's WOD (2.6.0): the blocks in order, hands-free, on top of
/// the timer engine without changing it.
///
/// A timer block is started on the timer notifier as a session block, so
/// its get-ready, clock, cues, tap-to-count and FINISH are exactly the
/// timer's own; when it ends the session moves on. The session counts
/// what the timer has no notion of: a Rest block, and a Sets block's
/// get-ready, sets and rests. Hand-over cues are the app's existing beeps
/// and lines: a block's end is the high beep (with "Rest" when a rest
/// follows), a Rest block ends silently into the get-ready's 3-2-1, and
/// the last block's end is the timer's own end ("Good job").
class TodaysWodController extends Notifier<WodRun?> {
  /// The get-ready in front of every block but a Rest, as on the setup
  /// screens.
  static const int getReadySeconds = 10;

  /// Taps on SET DONE, TAP TO SKIP and PAUSE are ignored this long after
  /// one of them changed the screen, so a double tap never does two
  /// things (SET DONE's second tap would land on PAUSE).
  static const actionCooldown = Duration(milliseconds: 700);

  /// Clock for the cooldown; tests replace it.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  late ITimerEngine _engine;
  late IAudioService _audio;
  late IHapticService _haptic;
  StreamSubscription<Duration>? _ticks;
  int _lastTickMs = 0;

  /// Bumped on every start and end, so a timer block that finishes
  /// starting after the session moved on is ignored.
  int _generation = 0;

  /// The run is stopping a timer block itself: its end is not a hand-over.
  bool _stopping = false;

  /// One voice line and one change beep per pass, however many phases a
  /// catch-up tick (the app was suspended) runs through.
  bool _voiced = false;
  bool _beeped = false;
  String? _lastLowBeep;
  DateTime? _blockedUntil;

  @override
  WodRun? build() {
    _engine = ref.watch(sessionEngineProvider);
    _audio = ref.watch(audioServiceProvider);
    _haptic = ref.watch(hapticServiceProvider);
    ref
      ..listen(timerNotifierProvider, _onTimerState)
      ..onDispose(_stopEngine);
    return null;
  }

  TimerNotifier get _timer => ref.read(timerNotifierProvider.notifier);

  // ===================================================================
  // Start, stop, again
  // ===================================================================

  /// Starts [session] from its first block.
  Future<void> start(WodSession session) async {
    if (!session.isRunnable) return;
    _stopEngine();
    _generation++;
    _stopping = false;
    _lastLowBeep = null;
    _blockedUntil = null;
    if (ref.read(timerNotifierProvider) is! TimerInitial) _timer.reset();
    // The first block's own phase from the start, so nothing shows a
    // get-ready a Rest or a timer block does not have.
    state = WodRun(
      session: session,
      index: 0,
      phase: switch (session.blocks.first.kind) {
        BlockKind.rest => WodPhase.rest,
        BlockKind.sets => WodPhase.getReady,
        _ => WodPhase.timer,
      },
      getReadySeconds: getReadySeconds,
    );
    trackEvent('session_started', {
      'blocks': session.blocks.length,
      'kinds': session.kindCodes,
    });
    _lastTickMs = 0;
    _pendingTimerStart = null;
    _ticks = _engine.tickStream.listen(_onTick);
    _engine
      ..reset()
      ..start();
    _pass(() => _enterBlock(0, carryMs: 0));
    await _pendingTimerStart;
  }

  /// Runs the same session again from the end screen.
  Future<void> again() async {
    final run = state;
    if (run == null || !run.isFinished) return;
    await start(run.session);
  }

  /// HOLD TO STOP: ends the whole session on the end screen in its stopped
  /// form, showing what was completed.
  void stop() {
    final run = state;
    if (run == null || run.isFinished) return;
    if (run.phase == WodPhase.timer) {
      _stopping = true;
      _timer.stop();
    }
    _finish(stopped: true);
  }

  /// Whether HOLD TO STOP should leave without an end screen: nothing has
  /// happened yet (the first block's get-ready), as a timer on its own
  /// goes back to setup from its get-ready.
  bool get nothingDoneYet {
    final run = state;
    if (run == null || run.index != 0 || run.outcomes.isNotEmpty) return false;
    if (run.phase == WodPhase.getReady) return true;
    return run.phase == WodPhase.timer &&
        ref.read(timerNotifierProvider) is TimerPreparing;
  }

  /// Leaves the session with nothing kept (stop in the first get-ready,
  /// DONE on the end screen).
  void exit() {
    _generation++;
    _stopEngine();
    if (state?.phase == WodPhase.timer) {
      _stopping = true;
      _timer.reset();
      _stopping = false;
    }
    state = null;
  }

  // ===================================================================
  // Taps
  // ===================================================================

  bool _blocked() {
    final until = _blockedUntil;
    return until != null && clock().isBefore(until);
  }

  void _block() => _blockedUntil = clock().add(actionCooldown);

  /// SET DONE: rest before the next set, or the block is over after the
  /// last one.
  void setDone() {
    final run = state;
    if (run == null || run.phase != WodPhase.setWork || run.paused) return;
    if (_blocked()) return;
    _block();
    final block = run.block as SetsBlock;
    _pass(() {
      if (run.set >= block.sets) {
        _blockEnded(BlockOutcome(block: block, count: block.sets));
      } else {
        state = run.copyWith(phase: WodPhase.setRest, phaseElapsedMs: 0);
        _changeBeep();
        _say(_audio.playRest);
        _haptic.warning();
      }
    });
  }

  /// TAP TO SKIP: ends a Sets get-ready, a Rest block or a set's rest now.
  void skip() {
    final run = state;
    if (run == null || run.paused) return;
    if (run.phase != WodPhase.getReady &&
        run.phase != WodPhase.rest &&
        run.phase != WodPhase.setRest) {
      return;
    }
    if (_blocked()) return;
    _block();
    _haptic.mediumImpact();
    _pass(() => _phaseDone(0));
  }

  /// PAUSE, in a timer block (through the timer), a Rest block, a set or
  /// its rest. Not in a get-ready: skip or stop are the only actions there,
  /// as on a timer on its own.
  void pause() {
    final run = state;
    if (run == null || run.paused || _blocked()) return;
    switch (run.phase) {
      case WodPhase.timer:
        _timer.pause();
      case WodPhase.rest || WodPhase.setWork || WodPhase.setRest:
        _engine.pause();
        state = run.copyWith(paused: true);
        _haptic.mediumImpact();
      case WodPhase.getReady || WodPhase.finished:
        break;
    }
  }

  void resume() {
    final run = state;
    if (run == null || !run.paused) return;
    if (run.phase == WodPhase.timer) {
      _timer.resume();
      return;
    }
    _engine.resume();
    state = run.copyWith(paused: false);
    _haptic.mediumImpact();
    _block();
  }

  // ===================================================================
  // The clock
  // ===================================================================

  void _onTick(Duration elapsed) {
    final run = state;
    if (run == null || run.isFinished) return;
    // An in-flight tick can land after a pause: drop it, and the next
    // delta covers the span (as the timer does).
    if (run.paused) return;
    final ms = elapsed.inMilliseconds;
    final delta = ms - _lastTickMs;
    _lastTickMs = ms;
    if (delta <= 0) return;
    final counting =
        run.phase == WodPhase.getReady ||
        run.phase == WodPhase.rest ||
        run.phase == WodPhase.setRest;
    _pass(() {
      state = run.copyWith(totalMs: ms);
      if (counting) _advance(delta);
    });
  }

  /// Moves the counted phase on by [deltaMs], through its end and into the
  /// next phase with the overshoot when a catch-up tick crosses it.
  void _advance(int deltaMs) {
    final run = state!;
    final length = run.phaseSeconds * 1000;
    final elapsed = run.phaseElapsedMs + deltaMs;
    if (elapsed < length) {
      state = run.copyWith(phaseElapsedMs: elapsed);
      _countdownBeep(state!);
      return;
    }
    _phaseDone(elapsed - length);
  }

  /// Three low beeps in the last three seconds of a get-ready and of a
  /// set's rest. A Rest block has none: the get-ready after it does.
  void _countdownBeep(WodRun run) {
    if (run.phase == WodPhase.rest) return;
    final left = run.remainingSeconds;
    if (left < 1 || left > 3 || left >= run.phaseSeconds) return;
    final key = '${run.index}:${run.phase.name}:${run.set}:$left';
    if (key == _lastLowBeep) return;
    _lastLowBeep = key;
    _audio.playLowBeep(left);
    if (run.phase == WodPhase.getReady) _haptic.mediumImpact();
  }

  /// The counted phase is over; [carryMs] ran past its end.
  void _phaseDone(int carryMs) {
    final run = state!;
    switch (run.phase) {
      case WodPhase.getReady:
        // Into the first set. A set has no clock: the overshoot ends here.
        state = run.copyWith(phase: WodPhase.setWork, phaseElapsedMs: 0);
        _go();
      case WodPhase.setRest:
        state = run.copyWith(
          phase: WodPhase.setWork,
          phaseElapsedMs: 0,
          set: run.set + 1,
        );
        _go();
      case WodPhase.rest:
        // Silent: the get-ready that follows has the 3-2-1.
        _blockEnded(BlockOutcome(block: run.block), carryMs: carryMs);
      case WodPhase.timer || WodPhase.setWork || WodPhase.finished:
        break;
    }
  }

  // ===================================================================
  // Blocks
  // ===================================================================

  Future<void>? _pendingTimerStart;

  /// Starts block [index], carrying [carryMs] into a counted phase.
  void _enterBlock(int index, {required int carryMs}) {
    final run = state!;
    if (index >= run.blockCount) {
      _finish(stopped: false);
      return;
    }
    final block = run.session.blocks[index];
    _lastLowBeep = null;
    switch (block) {
      case RestBlock():
        state = run.copyWith(
          index: index,
          phase: WodPhase.rest,
          phaseElapsedMs: 0,
          set: 1,
        );
        _say(_audio.playRest);
        _haptic.warning();
        if (carryMs > 0) _advance(carryMs);
      case SetsBlock():
        state = run.copyWith(
          index: index,
          phase: WodPhase.getReady,
          phaseElapsedMs: 0,
          set: 1,
        );
        _say(_audio.playGetReady);
        if (carryMs > 0) _advance(carryMs);
      case ForTimeBlock() || EmomBlock() || AmrapBlock() || TabataBlock():
        // The timer's own get-ready, clock and cues. A catch-up tick's
        // overshoot stops here: the timer starts from its get-ready.
        state = run.copyWith(
          index: index,
          phase: WodPhase.timer,
          phaseElapsedMs: 0,
          set: 1,
        );
        _pendingTimerStart = _startTimerBlock(block, _generation);
    }
  }

  Future<void> _startTimerBlock(SessionBlock block, int generation) async {
    final workout = ref
        .read(createWorkoutProvider)(
          name: "Today's WOD",
          // The default get-ready, [getReadySeconds], as on setup.
          timerType: timerTypeOf(block),
        )
        .toNullable();
    if (workout == null) return;
    await _timer.start(workout, inSession: true);
    // Stopped or restarted while the timer was starting.
    if (generation != _generation) _timer.reset();
  }

  /// The timer a timer block runs.
  static TimerType timerTypeOf(SessionBlock block) => switch (block) {
    ForTimeBlock(:final capSeconds, :final countUp) => ForTimeTimer(
      timeCap: TimerDuration.fromSeconds(capSeconds),
      countUp: countUp,
    ),
    EmomBlock(:final intervalSeconds, :final rounds) => EmomTimer(
      intervalDuration: TimerDuration.fromSeconds(intervalSeconds),
      rounds: RoundCount.fromInt(rounds),
    ),
    AmrapBlock(:final durationSeconds) => AmrapTimer(
      duration: TimerDuration.fromSeconds(durationSeconds),
    ),
    TabataBlock(:final workSeconds, :final restSeconds, :final rounds) =>
      TabataTimer(
        workDuration: TimerDuration.fromSeconds(workSeconds),
        restDuration: TimerDuration.fromSeconds(restSeconds),
        rounds: RoundCount.fromInt(rounds),
      ),
    RestBlock() || SetsBlock() => throw ArgumentError.value(
      block,
      'block',
      'not a timer block',
    ),
  };

  /// The timer notifier changed: a timer block paused, resumed or ended.
  void _onTimerState(TimerNotifierState? previous, TimerNotifierState next) {
    final run = state;
    if (run == null || run.phase != WodPhase.timer) return;
    switch (next) {
      case TimerPaused():
        if (!run.paused) {
          _engine.pause();
          state = run.copyWith(paused: true);
        }
      case TimerPreparing() || TimerRunning() || TimerResting():
        if (run.paused) {
          _engine.resume();
          state = run.copyWith(paused: false);
        }
      case TimerCompleted(:final session, :final endedEarly):
        if (_stopping || endedEarly) return;
        final capped = next.endedAtTimeCap;
        final generation = _generation;
        final block = run.block;
        final outcome = switch (block) {
          ForTimeBlock() => BlockOutcome(
            block: block,
            seconds: session.elapsed.seconds,
            capped: capped,
          ),
          AmrapBlock() => BlockOutcome(
            block: block,
            count: session.currentRound - 1,
          ),
          _ => BlockOutcome(block: block, count: session.currentRound),
        };
        // After the timer has finished its own tick.
        scheduleMicrotask(() {
          if (generation != _generation || state?.phase != WodPhase.timer) {
            return;
          }
          _pass(() => _blockEnded(outcome));
        });
      default:
        break;
    }
  }

  /// A block ran to its end: the change, then the next block.
  void _blockEnded(BlockOutcome outcome, {int carryMs = 0}) {
    final run = state!;
    state = run.copyWith(outcomes: [...run.outcomes, outcome]);
    final last = run.index + 1 >= run.blockCount;
    if (last) {
      _finish(stopped: false, capped: outcome.capped);
      return;
    }
    if (outcome.block is! RestBlock) {
      _changeBeep();
      _haptic.heavyImpact();
    }
    _enterBlock(run.index + 1, carryMs: carryMs);
  }

  void _finish({required bool stopped, bool capped = false}) {
    final run = state;
    if (run == null || run.isFinished) return;
    _generation++;
    final total = _engine.elapsed.inMilliseconds;
    _stopEngine();
    state = run.copyWith(
      phase: WodPhase.finished,
      paused: false,
      stopped: stopped,
      totalMs: total > run.totalMs ? total : run.totalMs,
    );
    _timer.reset();
    _stopping = false;
    trackEvent('session_completed', {
      'blocks': run.blockCount,
      'ended_by': stopped ? 'stopped' : 'finished',
    });
    if (stopped) {
      _haptic.mediumImpact();
      return;
    }
    // The end, as a timer's own end: the high beep with the line on it,
    // never "Good job" on a cap. The review payoff once, for the session.
    _changeBeep();
    if (capped) {
      _say(_audio.playComplete);
      _haptic.heavyImpact();
    } else {
      _say(_audio.playGoodJob);
      _haptic.success();
      unawaited(ref.read(reviewPrompterProvider).recordValueMoment());
    }
  }

  // ===================================================================
  // Cues
  // ===================================================================

  /// Runs [body] as one pass: at most one voice line and one change beep.
  void _pass(void Function() body) {
    _voiced = false;
    _beeped = false;
    body();
  }

  void _say(Future<Object?> Function() cue) {
    if (_voiced) return;
    _voiced = true;
    cue();
  }

  void _changeBeep() {
    if (_beeped) return;
    _beeped = true;
    _audio.playHighBeep();
  }

  /// Into a set: the high beep with "Go" on it.
  void _go() {
    _changeBeep();
    _say(_audio.playGo);
    _haptic.heavyImpact();
  }

  void _stopEngine() {
    _ticks?.cancel();
    _ticks = null;
    _engine.stop();
  }
}

/// Written by hand: riverpod_generator 2.6 can't parse the Flutter 3.47 SDK.
final todaysWodProvider = NotifierProvider<TodaysWodController, WodRun?>(
  TodaysWodController.new,
);
