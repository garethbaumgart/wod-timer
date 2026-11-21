import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/core/presentation/widgets/centred_timeline.dart';
import 'package:wod_timer/core/presentation/widgets/glyph_ink.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/application/setup/live_hints.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_state.dart'
    as domain;
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/widgets/end_fact_tiles.dart';
import 'package:wod_timer/features/timer/presentation/widgets/hold_to_stop_cell.dart';
import 'package:wod_timer/features/timer/presentation/widgets/live_frame.dart';
import 'package:wod_timer/features/timer/presentation/widgets/rounds_wheel.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_format.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';

/// Active timer display page: 1.3.0 "big clock" in the 1.3.1 colours.
///
/// Built for the 3-metre gym glance: one clock in the workout's colour,
/// sized once per workout from its longest value so it never refits, one
/// second line (the round, the score or the cap) on a fixed baseline, one
/// phase word when there is a phase to name, the Home timeline filling as
/// the workout runs, and the actions in one slab along the bottom. Every
/// line has a fixed slot (layout rule 1): nothing moves while numbers
/// count. Stop lives on the paused screen and is hold-to-confirm.
class TimerActivePage extends ConsumerStatefulWidget {
  const TimerActivePage({required this.timerType, super.key, this.session});

  /// The type of timer being displayed.
  final String timerType;

  /// Set when the timer is a block of Today's WOD (2.6.0); null for every
  /// timer started on its own, which this page shows exactly as before.
  final LiveSessionFrame? session;

  @override
  ConsumerState<TimerActivePage> createState() => _TimerActivePageState();
}

class _TimerActivePageState extends ConsumerState<TimerActivePage>
    with SingleTickerProviderStateMixin {
  /// Pulses the digits while paused so a stopped clock can't be mistaken
  /// for a running one at distance.
  late final AnimationController _pausedPulse;

  /// Transient hint on HOLD TO STOP (a short press, or a back gesture
  /// while paused).
  bool _showHoldHint = false;

  /// AGAIN and DONE ignore taps this long after the end screen appears
  /// (2.6.0), so the second tap of a double tap on FINISH never restarts
  /// the workout or leaves before the result is seen.
  static const endGuard = Duration(milliseconds: 700);

  /// Running while the end screen is new; null when it is not shown.
  Timer? _endGuard;

  bool get _endSettling => _endGuard?.isActive ?? false;

  // Fixed slots (layout rule 1), in logical points before TabletScale.
  static const double _timelineHeight = LiveFrame.timelineHeight;

  @override
  void initState() {
    super.initState();
    _pausedPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      lowerBound: 0.35,
      upperBound: 0.9,
    );
    // In a session the session page holds both, across every block.
    if (widget.session != null) return;
    // A timer that sleeps mid-WOD is the app failing: the wakelock is always
    // held while this page is open (the Keep Screen On switch went in 1.3.0).
    WakelockPlus.enable();
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _endGuard?.cancel();
    _pausedPulse.dispose();
    if (widget.session == null) {
      WakelockPlus.disable();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  // ===================================================================
  // Actions
  // ===================================================================

  void _onPauseResume() {
    // In a session the slab waits out a phase change (a timer on its own
    // pauses at once, as always).
    if (widget.session?.canTap == false) return;
    final timerNotifier = ref.read(timerNotifierProvider.notifier);
    final state = ref.read(timerNotifierProvider);

    if (state.canPause) {
      timerNotifier.pause();
    } else if (state.canResume) {
      timerNotifier.resume();
    }
  }

  /// Stop confirmed via hold: during prep nothing has happened yet, so
  /// go straight back to setup; otherwise land on the honest "Stopped"
  /// completion state.
  void _onStopConfirmed() {
    // In a session HOLD TO STOP ends the whole session.
    if (widget.session case final session?) {
      session.stop();
      return;
    }
    final state = ref.read(timerNotifierProvider);
    if (state is TimerPreparing) {
      ref.read(timerNotifierProvider.notifier).reset();
      context.go(AppRoutes.timerSetupPath(widget.timerType));
      return;
    }
    ref.read(timerNotifierProvider.notifier).stop();
  }

  void _flashHoldHint() {
    setState(() => _showHoldHint = true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showHoldHint = false);
    });
  }

  void _onFinish() {
    if (widget.session?.canTap == false) return;
    ref.read(timerNotifierProvider.notifier).finish();
  }

  /// Tap anywhere above the slab: skip the get-ready countdown, count an
  /// AMRAP round, or resume a paused workout. These are the only canvas
  /// gestures (double tap and swipes went in 1.3.0: they meant pause in
  /// three modes and two rounds in AMRAP, and nothing showed them).
  void _onCanvasTap() {
    final notifier = ref.read(timerNotifierProvider.notifier);
    final state = ref.read(timerNotifierProvider);
    if (state is TimerPreparing) {
      if (widget.session?.canTap == false) return;
      ref.read(hapticServiceProvider).mediumImpact();
      notifier.skipPrep();
      return;
    }
    if (state is TimerPaused) {
      notifier.resume();
      return;
    }
    if (state is TimerRunning && widget.timerType == TimerTypes.amrap) {
      final before = state.session.currentRound;
      notifier.countRound();
      final after = ref.read(timerNotifierProvider).sessionOrNull?.currentRound;
      if (after != null && after > before) {
        ref.read(liveHintsProvider).markCountedRound();
      }
    }
  }

  /// The back gesture / Android back never leaves a live workout silently.
  void _onPopAttempt() {
    final state = ref.read(timerNotifierProvider);
    // In a session the back gesture never ends it: on a get-ready the
    // session decides, paused it hints at HOLD TO STOP, otherwise nothing.
    if (widget.session case final session?) {
      switch (state) {
        case TimerPreparing():
          session.back();
        case TimerPaused():
          _flashHoldHint();
        default:
          break;
      }
      return;
    }
    switch (state) {
      case TimerPreparing():
        _onStopConfirmed();
      case TimerPaused():
        _flashHoldHint();
      case TimerCompleted():
        // In a session the block's end is a hand-over, not an end screen.
        if (widget.session == null) _onDone();
      case TimerRunning() || TimerResting():
        // Mid-rep: pause first, then hold Stop. A stray edge swipe does
        // nothing.
        break;
      default:
        _goToSetup();
    }
  }

  void _goToSetup() {
    final state = ref.read(timerNotifierProvider);
    if (state is! TimerInitial) {
      ref.read(timerNotifierProvider.notifier).reset();
    }
    if (mounted) context.go(AppRoutes.timerSetupPath(widget.timerType));
  }

  Future<void> _onAgain() async {
    if (_endSettling) return;
    await ref.read(timerNotifierProvider.notifier).restart();
  }

  /// DONE lands on this mode's setup with the workout just run loaded, so
  /// fixing one number and going again is DONE, wheel, START.
  void _onDone() => _goToSetup();

  /// The DONE cell (the back gesture goes straight to [_onDone]).
  void _onDoneTap() {
    if (_endSettling) return;
    _onDone();
  }

  // ===================================================================
  // Build
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerNotifierProvider);

    // Drive the paused pulse from the state
    if (timerState is TimerPaused) {
      if (!_pausedPulse.isAnimating) {
        _pausedPulse.repeat(reverse: true);
      }
    } else {
      if (_pausedPulse.isAnimating) {
        _pausedPulse
          ..stop()
          ..value = _pausedPulse.upperBound;
      }
    }

    // The end screen's tap guard starts when it appears.
    if (timerState is TimerCompleted && widget.session == null) {
      _endGuard ??= Timer(endGuard, () {});
    } else if (_endGuard != null) {
      _endGuard!.cancel();
      _endGuard = null;
    }

    // Show placeholder when timer is not configured yet
    if (timerState is TimerInitial) {
      return _buildNotConfiguredState();
    }

    final isAmrapRunning =
        timerState is TimerRunning && widget.timerType == TimerTypes.amrap;
    final canvasTaps =
        timerState is TimerPreparing ||
        timerState is TimerPaused ||
        isAmrapRunning;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPopAttempt();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        // The slab runs to the very bottom edge.
        body: SafeArea(
          bottom: false,
          child: Semantics(
            label: _buildTimerAccessibilityLabel(timerState),
            liveRegion: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canvasTaps ? _onCanvasTap : null,
              child: OrientationBuilder(
                builder: (context, orientation) {
                  final landscape = orientation == Orientation.landscape;
                  // A session block's end is the moment before the session
                  // hands over: the live screen holds until it does.
                  if (timerState is TimerCompleted && widget.session == null) {
                    return _buildEnd(timerState, landscape: landscape);
                  }
                  return _buildLive(timerState, landscape: landscape);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // Session helpers
  // ===================================================================

  /// Whether this session's For Time timer counts up from zero.
  bool _isCountUpForTime(TimerSession? session) {
    final type = session?.workout.timerType;
    return type is ForTimeTimer && type.countUp;
  }

  /// Whether this session's For Time timer counts down from the cap.
  bool _countsDownForTime(TimerSession session) {
    final type = session.workout.timerType;
    return type is ForTimeTimer && !type.countUp;
  }

  /// The phase the session is in, or paused in.
  domain.TimerState? _effectivePhase(TimerSession? session) {
    if (session == null) return null;
    return session.state == domain.TimerState.paused
        ? (session.stateBeforePause ?? session.state)
        : session.state;
  }

  /// The seconds shown on the giant display: the get-ready countdown while
  /// preparing (every mode), elapsed for a count-up For Time, otherwise the
  /// remaining time in the current phase.
  int _displaySeconds(TimerNotifierState state) {
    final session = state.sessionOrNull;
    if (session == null) return 0;
    if (state is TimerPreparing) return session.timeRemaining.seconds;
    if (_isCountUpForTime(session)) return session.elapsed.seconds;
    return session.timeRemaining.seconds;
  }

  /// Length of the phase the clock is counting through.
  int _phaseSeconds(TimerNotifierState state, TimerSession session) {
    if (state is TimerPreparing) return session.workout.prepCountdown.seconds;
    final phase = _effectivePhase(session);
    return session.workout.timerType.when(
      amrap: (t) => t.duration.seconds,
      forTime: (t) => t.timeCap.seconds,
      emom: (t) => t.intervalDuration.seconds,
      tabata: (t) => phase == domain.TimerState.resting
          ? t.restDuration.seconds
          : t.workDuration.seconds,
    );
  }

  /// Clock format: "9:45", "0:11", "12:30". Never zero-padded minutes.
  String _clock(int totalSeconds) => setupClock(totalSeconds);

  /// Display string for the giant digits.
  ///
  /// Countdowns go to bare seconds under a minute, and a phase of a minute
  /// or less never shows "1:00" (an EMOM minute counts 60, 59 ...). Count-up
  /// For Time always reads M:SS.
  String _displayString(TimerNotifierState state, int seconds) {
    final session = state.sessionOrNull;
    final isCountUp = state is! TimerPreparing && _isCountUpForTime(session);
    if (!isCountUp &&
        (seconds < 60 ||
            (session != null && _phaseSeconds(state, session) <= 60))) {
      return '$seconds';
    }
    return _clock(seconds);
  }

  /// A phase length the way the clock would show it at its start.
  String _phaseDisplay(int seconds) =>
      seconds <= 60 ? '$seconds' : _clock(seconds);

  /// The longest value this workout's clock can show: the clock's font
  /// size is set once from it, so counting never refits (layout rule 1).
  String _clockReference(TimerSession session) =>
      session.workout.timerType.when(
        amrap: (t) => _clock(t.duration.seconds),
        forTime: (t) => _clock(t.timeCap.seconds),
        emom: (t) => _phaseDisplay(t.intervalDuration.seconds),
        tabata: (t) => _phaseDisplay(
          math.max(t.workDuration.seconds, t.restDuration.seconds),
        ),
      );

  /// Seconds run so far, with the sub-second part, for the timeline.
  double _elapsedSeconds(TimerSession session) =>
      session.elapsed.seconds + session.elapsedMillis / 1000;

  String _buildTimerAccessibilityLabel(TimerNotifierState state) {
    final session = state.sessionOrNull;
    if (session == null) return 'Timer not started';

    final displaySeconds = _displaySeconds(state);
    final minutes = displaySeconds ~/ 60;
    final secs = displaySeconds % 60;

    final phase = state.maybeMap(
      preparing: (_) => 'Get Ready',
      running: (_) => 'Work',
      resting: (_) => 'Rest',
      paused: (_) => 'Paused',
      completed: (s) => s.endedEarly ? 'Stopped' : 'Complete',
      orElse: () => '',
    );

    final roundInfo = session.totalRounds != null
        ? ', Round ${session.currentRound} of ${session.totalRounds}'
        : (widget.timerType == TimerTypes.amrap
              ? ', ${session.currentRound - 1} rounds counted'
              : '');

    final String hint;
    if (state is TimerPreparing) {
      hint = '. Tap to start now. Hold the stop button to go back.';
    } else if (state is TimerPaused) {
      hint = '. Tap anywhere to resume. Hold the stop button to end.';
    } else if (state is TimerRunning && widget.timerType == TimerTypes.amrap) {
      hint = '. Tap to count a round. Pause to stop.';
    } else if (state.canPause) {
      hint = '. Pause to stop.';
    } else {
      hint = '';
    }

    final direction = _isCountUpForTime(session) ? 'elapsed' : 'remaining';
    return '$phase, $minutes minutes $secs seconds $direction$roundInfo$hint';
  }

  Widget _buildNotConfiguredState() {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_off_outlined,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Timer Not Started',
                  style: AppTypography.workoutTitle.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Go back to the setup page to configure and start '
                  'your workout.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  onPressed: _goToSetup,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go to Setup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // Colour: the workout's, one meaning each
  // ===================================================================

  /// The mode colour: For Time orange, EMOM pink, AMRAP blue, Tabata green.
  Color get _modeColor => switch (widget.timerType) {
    TimerTypes.forTime => AppColors.forTimeAccent,
    TimerTypes.emom => AppColors.emomAccent,
    TimerTypes.amrap => AppColors.amrapAccent,
    _ => AppColors.tabataAccent,
  };

  Color _phaseColorOf(domain.TimerState? phase) => switch (phase) {
    domain.TimerState.preparing => AppColors.prepare,
    domain.TimerState.resting => AppColors.rest,
    _ => widget.timerType == TimerTypes.tabata ? AppColors.work : _modeColor,
  };

  /// Digits keep the phase they are in (or paused in): a paused Tabata
  /// shows which phase will resume. Paused additionally dims and pulses.
  Color _digitColor(TimerNotifierState state) => state.maybeMap(
    preparing: (_) => AppColors.prepare,
    running: (_) => _phaseColorOf(domain.TimerState.running),
    resting: (_) => AppColors.rest,
    paused: (s) => _phaseColorOf(_effectivePhase(s.session)),
    orElse: () => _modeColor,
  );

  /// Wash colour: grey while paused, the digits' colour otherwise.
  Color _washColor(TimerNotifierState state) =>
      state is TimerPaused ? AppColors.paused : _digitColor(state);

  // ===================================================================
  // Live: fixed slots top to bottom, the slab along the bottom
  // ===================================================================

  Widget _buildLive(TimerNotifierState state, {required bool landscape}) {
    final session = state.sessionOrNull;
    return LiveFrame(
      landscape: landscape,
      header: widget.session?.header(state),
      clockReference: session == null ? null : _clockReference(session),
      // A count-down For Time has no second line while it runs, so the
      // clock is the content above the timeline and the zone under the
      // empty slot must still hold a centred bar.
      secondLineWhileRunning: session == null || !_countsDownForTime(session),
      phaseWord: (fontSize) =>
          _buildPhaseWord(state, session, fontSize: fontSize),
      clock: (clock) => _buildClock(state, clock),
      secondLine: (context, big) => session == null
          ? null
          : _secondLine(context, state, session, big, landscape: landscape),
      timeline: session == null
          ? const SizedBox.shrink()
          : _buildTimeline(session),
      slab: _absorbCanvasTaps(_buildLiveSlab(state)),
    );
  }

  /// The slab keeps its own taps: a near miss on PAUSE or HOLD TO STOP
  /// must never count a round or resume the workout.
  Widget _absorbCanvasTaps(Widget child) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {},
    child: child,
  );

  /// The timeline as progress: finished parts filled, the current one
  /// filling, the rest on the track.
  Widget _buildTimeline(TimerSession session) => WorkoutTimeline(
    shape: WorkoutShape.ofTimerType(session.workout.timerType),
    height: _timelineHeight,
    elapsedSeconds: _elapsedSeconds(session),
  );

  // ===================================================================
  // The clock
  // ===================================================================

  /// The digits in the phase colour at the size fixed for this workout,
  /// with the wash behind them.
  Widget _buildClock(TimerNotifierState state, ClockSpec clock) {
    final seconds = _displaySeconds(state);
    final timeString = _displayString(state, seconds);
    final isPaused = state is TimerPaused;

    // Pulse for last 3 seconds of prep countdown
    final isPulsing = state is TimerPreparing && seconds <= 3 && seconds > 0;

    Widget digits = Text(
      timeString,
      maxLines: 1,
      textScaler: TextScaler.noScaling,
      style: clock.style.copyWith(color: _digitColor(state)),
      semanticsLabel:
          '${seconds ~/ 60} minutes ${seconds % 60} seconds '
          '${_isCountUpForTime(state.sessionOrNull) ? 'elapsed' : 'remaining'}',
    );
    digits = AnimatedScale(
      scale: isPulsing ? 1.08 : 1,
      duration: const Duration(milliseconds: 200),
      child: digits,
    );
    if (isPaused) {
      digits = FadeTransition(opacity: _pausedPulse, child: digits);
    }

    final wash = _washColor(state);
    return Stack(
      alignment: Alignment.center,
      children: [
        // Radial wash behind the timer carries the phase at a glance. It
        // fades out by the slot's nearest edge (0.5 of the shortest side,
        // the prototype's closest-side gradient) so the slot has no edges.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.5,
                colors: [
                  wash.withValues(alpha: isPaused ? 0.08 : 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Center(child: digits),
      ],
    );
  }

  // ===================================================================
  // Phase word, second line
  // ===================================================================

  TextStyle _phaseStyle(Color color, double size) =>
      LiveStyles.phase(color, size);

  /// The grey words on the second line ("TAP TO COUNT", "CAP 20:00").
  TextStyle _hintStyle(double size) => LiveStyles.hint(size);

  /// The small unit beside a number ("ROUNDS", "TIME").
  TextStyle _unitStyle(double size) => LiveStyles.unit(size);

  /// The phase word and its colour, or null when there is no phase to name
  /// (AMRAP, EMOM and For Time work).
  (String, Color)? _phaseWord(TimerNotifierState state, TimerSession session) {
    final isTabata = widget.timerType == TimerTypes.tabata;
    if (state is TimerPreparing) return ('GET READY', AppColors.prepare);
    if (state is TimerPaused) {
      if (!isTabata) return ('PAUSED', AppColors.paused);
      final resting = _effectivePhase(session) == domain.TimerState.resting;
      return (resting ? 'PAUSED · REST' : 'PAUSED · WORK', AppColors.paused);
    }
    if (!isTabata) return null;

    // Tabata: name the phase, and for its last five seconds name the next
    // one in the next phase's colour (the digits stay in the current one).
    final remaining = session.timeRemaining.seconds;
    final lastRound = session.currentRound >= (session.totalRounds ?? 0);
    if (state is TimerResting) {
      if (lastRound) return ('LAST REST', AppColors.rest);
      if (remaining <= 5) return ('NEXT · WORK', AppColors.work);
      return ('REST', AppColors.rest);
    }
    if (state is TimerRunning) {
      if (remaining <= 5) return ('NEXT · REST', AppColors.rest);
      return ('WORK', AppColors.work);
    }
    return null;
  }

  Widget _buildPhaseWord(
    TimerNotifierState state,
    TimerSession? session, {
    required double fontSize,
  }) {
    if (session == null) return const SizedBox.shrink();
    final phase = _phaseWord(state, session);
    if (phase == null) return const SizedBox.shrink();
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          phase.$1,
          maxLines: 1,
          style: _phaseStyle(phase.$2, fontSize),
        ),
      ),
    );
  }

  bool _showTapToCount(TimerNotifierState state, TimerSession session) =>
      state is TimerRunning &&
      session.currentRound == 1 &&
      !ref.read(liveHintsProvider).hasCountedRound;

  /// The cap is the pacing number under a count-up clock, once work starts.
  /// A count-down clock already is the cap.
  bool _showCap(TimerNotifierState state, TimerSession session) =>
      state is! TimerPreparing && _isCountUpForTime(session);

  String _capText(TimerSession session) {
    final type = session.workout.timerType;
    return type is ForTimeTimer ? 'CAP ${_clock(type.timeCap.seconds)}' : '';
  }

  /// The second line: the round (EMOM, Tabata), the score (AMRAP) or the
  /// cap (count-up For Time); the skip hint in prep. Null for a count-down
  /// For Time. The record's text and style are its lowest glyphs, for the
  /// centring rule.
  ({Widget widget, String text, TextStyle style})? _secondLine(
    BuildContext context,
    TimerNotifierState state,
    TimerSession session,
    TextStyle big, {
    required bool landscape,
  }) {
    // Styles resolve against the context the texts render in (inside the
    // Scaffold's Material), so measurement and paint share one baseline.
    final hint = GlyphInk.resolve(context, _hintStyle(landscape ? 20 : 26));
    ({Widget widget, String text, TextStyle style}) line(
      String text,
      TextStyle style,
    ) => (
      widget: Text(text, maxLines: 1, style: style),
      text: text,
      style: style,
    );

    if (state is TimerPreparing) {
      // In a session the get-ready names the block in its colour; TAP TO
      // SKIP moves to the session's line.
      if (widget.session case final session?) {
        final (text, color) = session.gettingReadyFor;
        return line(
          text,
          fitPhaseStyle(
            context,
            text,
            color,
            landscape ? 20 : 26,
            MediaQuery.sizeOf(context).width - 2 * LiveFrame.sidePad,
          ),
        );
      }
      return line('TAP TO SKIP', hint);
    }
    if (session.totalRounds != null) {
      return line('${session.currentRound}/${session.totalRounds}', big);
    }
    if (widget.timerType == TimerTypes.amrap) {
      if (_showTapToCount(state, session)) return line('TAP TO COUNT', hint);
      final count = '${session.currentRound - 1}';
      return (
        widget: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(count, maxLines: 1, style: big),
            const SizedBox(width: 8),
            Text('ROUNDS', maxLines: 1, style: _unitStyle(16)),
          ],
        ),
        text: count,
        style: big,
      );
    }
    if (_showCap(state, session)) return line(_capText(session), hint);
    return null;
  }

  // ===================================================================
  // The live slab: PAUSE; FINISH | PAUSE; HOLD TO STOP | RESUME; HOLD TO
  // STOP alone in prep
  // ===================================================================

  Widget _buildLiveSlab(TimerNotifierState state) {
    final stop = HoldToStopCell(
      enabled: state.canStop,
      showHint: _showHoldHint,
      onConfirmed: _onStopConfirmed,
      onShortPress: _flashHoldHint,
    );
    if (state is TimerPreparing) return BottomSlab(cells: [stop]);
    if (state is TimerPaused) {
      return BottomSlab(
        cells: [
          stop,
          SlabCell(
            label: 'RESUME',
            background: _modeColor,
            foreground: Colors.black,
            onTap: _onPauseResume,
            semanticsLabel: 'Resume button',
          ),
        ],
      );
    }
    return BottomSlab(
      cells: [
        if (widget.timerType == TimerTypes.forTime)
          SlabCell(
            label: 'FINISH',
            background: Colors.white,
            foreground: Colors.black,
            onTap: _onFinish,
            semanticsLabel: 'Finish workout and log your time',
          ),
        SlabCell(
          label: 'PAUSE',
          background: AppColors.soft,
          foreground: Colors.white,
          enabled: state.canPause,
          onTap: _onPauseResume,
          semanticsLabel: 'Pause button${state.canPause ? '' : ', disabled'}',
        ),
      ],
    );
  }

  // ===================================================================
  // End: word, config, hero in the workout colour, the filled timeline,
  // AGAIN | DONE
  // ===================================================================

  /// The config line, count first: "AMRAP · 10:00", "FOR TIME · CAP 20:00",
  /// "EMOM · 10 × 1:00", "TABATA · 8 × 20s / 10s".
  String _configLine(TimerSession session) {
    return session.workout.timerType.when(
      amrap: (t) => 'AMRAP  ·  ${_clock(t.duration.seconds)}',
      forTime: (t) => 'FOR TIME  ·  CAP ${_clock(t.timeCap.seconds)}',
      emom: (t) =>
          'EMOM  ·  ${t.rounds.value} × ${_clock(t.intervalDuration.seconds)}',
      tabata: (t) =>
          'TABATA  ·  ${t.rounds.value} × '
          '${setupPhase(t.workDuration.seconds)} / '
          '${setupPhase(t.restDuration.seconds)}',
    );
  }

  TextStyle _heroStyle(double size) => AppTypography.timerDisplay.copyWith(
    color: _modeColor,
    fontSize: size,
    letterSpacing: -size * 0.02,
    height: ClockSpec.lineHeight,
    leadingDistribution: TextLeadingDistribution.even,
  );

  Widget _buildEnd(TimerCompleted state, {required bool landscape}) {
    final session = state.session;
    final textScaler = MediaQuery.textScalerOf(context);
    final word = state.endedAtTimeCap
        ? 'Time cap'
        : state.endedEarly
        ? 'Stopped'
        : 'Finished';
    final configText = _configLine(session);

    return LayoutBuilder(
      builder: (context, constraints) {
        final configStyle = GlyphInk.resolve(context, _unitStyle(14));
        final wordStyle = GlyphInk.resolve(
          context,
          AppTypography.heroTitle.copyWith(
            color: Colors.white,
            fontSize: 30,
            letterSpacing: -0.3,
          ),
        );
        if (!landscape) {
          return _buildEndPortrait(
            context,
            state,
            constraints: constraints,
            word: word,
            wordStyle: wordStyle,
            configText: configText,
            configStyle: configStyle,
          );
        }
        const topPad = 16.0;
        // What the hero block may take without squeezing the timeline zone
        // (the bar plus a breath either side; the spacer above the block
        // takes an equal share of what is left) or the slab.
        final blockHeight =
            constraints.maxHeight -
            topPad -
            GlyphInk.boxHeight(word, wordStyle, textScaler: textScaler) -
            4 -
            GlyphInk.boxHeight(
              configText,
              configStyle,
              textScaler: textScaler,
            ) -
            BottomSlab.heightOf(context) -
            2 * (_timelineHeight + 24);
        final hero = state.endedAtTimeCap
            ? null
            : _endHero(
                context,
                state,
                maxWidth: (constraints.maxWidth - 32) * 0.86,
                maxHeight: constraints.maxHeight * 0.22,
                maxBlockHeight: blockHeight,
              );
        final last = hero == null
            ? (text: configText, style: configStyle)
            : (text: hero.lastText, style: hero.lastStyle);
        return Column(
          children: [
            SizedBox(height: topPad),
            Text(word, style: wordStyle),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                configText,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: configStyle,
              ),
            ),
            if (hero != null) ...[const Spacer(), hero.widget],
            Expanded(
              child: CentredTimeline(
                aboveInkInset: GlyphInk.bottomInset(
                  last.text,
                  last.style,
                  textScaler: textScaler,
                ),
                height: _timelineHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: WorkoutTimeline(
                    shape: WorkoutShape.ofTimerType(session.workout.timerType),
                    height: _timelineHeight,
                    elapsedSeconds: _elapsedSeconds(session),
                  ),
                ),
              ),
            ),
            _absorbCanvasTaps(
              BottomSlab(
                cells: [
                  SlabCell(
                    label: 'AGAIN',
                    background: _modeColor,
                    foreground: Colors.black,
                    onTap: _onAgain,
                    semanticsLabel: 'Run the same workout again',
                  ),
                  SlabCell(
                    label: 'DONE',
                    background: AppColors.soft,
                    foreground: Colors.white,
                    onTap: _onDoneTap,
                    semanticsLabel: 'Done, back to setup',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Upright end screen (2.5.1, option 1 of the 15 Nov 2026 mocks): the
  /// result lifted under the header, three fact tiles under it (the time,
  /// one fact for the mode, when it finished), the timeline centred in
  /// what is left above the slab.
  ///
  /// [context] is the layout's, under the Scaffold: styles resolved from
  /// the page's own context pick up the no-Material warning underline.
  Widget _buildEndPortrait(
    BuildContext context,
    TimerCompleted state, {
    required BoxConstraints constraints,
    required String word,
    required TextStyle wordStyle,
    required String configText,
    required TextStyle configStyle,
  }) {
    final textScaler = MediaQuery.textScalerOf(context);
    const topPad = 28.0;
    const heroGap = 36.0;
    const tilesGap = 28.0;
    final facts = _endFacts(context, state);
    final tilesHeight = EndFactTiles.heightOf(context);
    // What the hero may take: everything but the header, the gaps, the
    // tiles, the timeline zone (the bar and a breath either side) and the
    // slab.
    final blockHeight =
        constraints.maxHeight -
        topPad -
        GlyphInk.boxHeight(word, wordStyle, textScaler: textScaler) -
        4 -
        GlyphInk.boxHeight(configText, configStyle, textScaler: textScaler) -
        heroGap -
        tilesGap -
        tilesHeight -
        BottomSlab.heightOf(context) -
        2 * (_timelineHeight + 24);
    final hero = state.endedAtTimeCap
        ? null
        : _endHero(
            context,
            state,
            maxWidth: (constraints.maxWidth - 32) * 0.86,
            maxHeight: math.min(
              constraints.maxHeight * 0.22,
              math.max(48, blockHeight - 40),
            ),
            maxBlockHeight: blockHeight,
            showTotal: false,
            wheelCap: EndFactTiles.amrapWheelCap,
          );
    final session = state.session;
    return Column(
      children: [
        const SizedBox(height: topPad),
        Text(word, style: wordStyle),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            configText,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: configStyle,
          ),
        ),
        const SizedBox(height: heroGap),
        if (hero != null) ...[hero.widget, const SizedBox(height: tilesGap)],
        EndFactTiles(facts: facts),
        Expanded(
          child: CentredTimeline(
            // The tiles' filled boxes are their lowest ink.
            aboveInkInset: 0,
            height: _timelineHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: WorkoutTimeline(
                shape: WorkoutShape.ofTimerType(session.workout.timerType),
                height: _timelineHeight,
                elapsedSeconds: _elapsedSeconds(session),
              ),
            ),
          ),
        ),
        _endSlab(),
      ],
    );
  }

  /// AGAIN | DONE.
  Widget _endSlab() => _absorbCanvasTaps(
    BottomSlab(
      cells: [
        SlabCell(
          label: 'AGAIN',
          background: _modeColor,
          foreground: Colors.black,
          onTap: _onAgain,
          semanticsLabel: 'Run the same workout again',
        ),
        SlabCell(
          label: 'DONE',
          background: AppColors.soft,
          foreground: Colors.white,
          onTap: _onDoneTap,
          semanticsLabel: 'Done, back to setup',
        ),
      ],
    ),
  );

  /// The three fact tiles for an end screen: the time, one fact for the
  /// mode, and when it ended. Everything comes from the session.
  List<EndFact> _endFacts(BuildContext context, TimerCompleted state) {
    final session = state.session;
    final elapsed = session.elapsed.seconds;
    final time = _clock(elapsed);
    final ended =
        session.completedAt ??
        session.startedAt?.add(Duration(seconds: elapsed)) ??
        DateTime.now();
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    final endedAt = EndFact.clockTime(ended, use24h: use24h);
    final startedAt = EndFact.clockTime(
      session.startedAt ?? ended.subtract(Duration(seconds: elapsed)),
      use24h: use24h,
    );
    final endLabel = state.endedAtTimeCap
        ? 'ENDED'
        : state.endedEarly
        ? 'STOPPED'
        : 'FINISHED';
    final end = EndFact(endLabel, endedAt);
    return session.workout.timerType.when(
      amrap: (_) {
        final rounds = session.currentRound - 1;
        return [
          EndFact('TIME', time),
          if (rounds > 0)
            EndFact('PER ROUND', _clock((elapsed / rounds).round()))
          else
            EndFact('STARTED', startedAt),
          end,
        ];
      },
      forTime: (t) => [
        EndFact('CAP', _clock(t.timeCap.seconds)),
        // Only a FINISH beats the cap; a stop or the cap itself does not.
        if (!state.endedEarly && !state.endedAtTimeCap)
          EndFact('UNDER CAP', _clock(math.max(0, t.timeCap.seconds - elapsed)))
        else
          EndFact('STARTED', startedAt),
        end,
      ],
      emom: (t) => [
        EndFact('TIME', time),
        EndFact('EVERY', _clock(t.intervalDuration.seconds)),
        end,
      ],
      tabata: (t) => [
        EndFact('TIME', time),
        EndFact(
          'WORK',
          _clock(
            EndFact.tabataWorkSeconds(
              elapsed,
              work: t.workDuration.seconds,
              rest: t.restDuration.seconds,
            ),
          ),
        ),
        end,
      ],
    );
  }

  /// The hero block: the number (or AMRAP's wheel) in the workout colour,
  /// its label, and the total where there is one. The record's last text
  /// and style are the block's lowest glyphs, for the centring rule.
  ({Widget widget, String lastText, TextStyle lastStyle}) _endHero(
    BuildContext context,
    TimerCompleted state, {
    required double maxWidth,
    required double maxHeight,
    required double maxBlockHeight,
    bool showTotal = true,
    double wheelCap = double.infinity,
  }) {
    final session = state.session;
    final textScaler = MediaQuery.textScalerOf(context);
    final elapsed = _clock(session.elapsed.seconds);
    final unit = GlyphInk.resolve(context, _unitStyle(16));
    final detailStyle = GlyphInk.resolve(
      context,
      AppTypography.sectionHeader.copyWith(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 1.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    if (widget.timerType == TimerTypes.amrap) {
      final hintStyle = GlyphInk.resolve(
        context,
        AppTypography.labelLarge.copyWith(
          color: AppColors.textDisabledDark,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      );
      const hintText = 'Scroll to fix the count';
      // The selected count is sized by the hero rule, like "2/10" on an
      // EMOM end screen (a four-glyph round fraction is the reference so a
      // one to three digit count reads just as big), then capped only by
      // what the wheel's three rows can take above the timeline zone.
      final heroSize = ClockSpec.fontSizeFor(
        reference: '0/00',
        style: GlyphInk.resolve(context, _heroStyle(100)),
        maxWidth: maxWidth,
        slotHeight: maxHeight,
      );
      final labels =
          GlyphInk.boxHeight('ROUNDS', unit, textScaler: textScaler) +
          GlyphInk.boxHeight(hintText, hintStyle, textScaler: textScaler) +
          12;
      final fits = (maxBlockHeight - labels) / RoundsWheel.heightFor(1);
      final size = math.max(24.0, math.min(wheelCap, math.min(heroSize, fits)));
      final rounds = session.currentRound - 1;
      return (
        widget: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            RoundsWheel(
              rounds: rounds,
              fontSize: size,
              onChanged: (next) => ref
                  .read(timerNotifierProvider.notifier)
                  .adjustRounds(next - rounds),
            ),
            Text('ROUNDS', style: unit),
            Text(hintText, style: hintStyle),
          ],
        ),
        lastText: hintText,
        lastStyle: hintStyle,
      );
    }

    final String value;
    final String label;
    String? detail;
    if (widget.timerType == TimerTypes.forTime) {
      value = elapsed;
      label = 'TIME';
    } else {
      value = '${session.currentRound}/${session.totalRounds}';
      label = 'ROUNDS';
      // Upright the time is a fact tile under the hero (2.5.1).
      if (showTotal) detail = '$elapsed total';
    }
    final style = GlyphInk.resolve(
      context,
      _heroStyle(
        ClockSpec.fontSizeFor(
          reference: value,
          style: GlyphInk.resolve(context, _heroStyle(100)),
          maxWidth: maxWidth,
          slotHeight: maxHeight,
        ),
      ),
    );
    final lastText = detail ?? label;
    final lastStyle = detail == null ? unit : detailStyle;
    // The hero's line box is trimmed to its cap height, so a slash or a
    // round digit paints past its bottom: keep the label clear of it.
    final overshoot = math.max(
      0.0,
      GlyphInk.glyphBottom(value, style) - GlyphInk.boxHeight(value, style),
    );
    return (
      widget: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: overshoot),
            child: Text(
              value,
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: style,
            ),
          ),
          Text(label, style: unit),
          if (detail != null) Text(detail, style: detailStyle),
        ],
      ),
      lastText: lastText,
      lastStyle: lastStyle,
    );
  }
}
