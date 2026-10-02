import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/content_width_cap.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/application/setup/live_hints.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_state.dart'
    as domain;
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_stepper.dart';

/// Active timer display page - Signal design, 1.3.0 "big clock".
///
/// Built for the 3-metre gym glance: one phase-coloured clock filling the
/// width, one big second number (the round, the score or the cap), one
/// phase word when there is a phase to name, nothing under 15pt, and one
/// control while running. Stop lives on the paused screen and is
/// hold-to-confirm; ending early reports an honest "Stopped" state.
class TimerActivePage extends ConsumerStatefulWidget {
  const TimerActivePage({required this.timerType, super.key});

  /// The type of timer being displayed.
  final String timerType;

  @override
  ConsumerState<TimerActivePage> createState() => _TimerActivePageState();
}

class _TimerActivePageState extends ConsumerState<TimerActivePage>
    with SingleTickerProviderStateMixin {
  /// Pulses the digits while paused so a stopped clock can't be mistaken
  /// for a running one at distance.
  late final AnimationController _pausedPulse;

  /// Transient HOLD hint inside the Stop button (a short press, or a back
  /// gesture while paused).
  bool _showHoldHint = false;

  // Fixed slot heights (before the tablet text scale), so nothing on the
  // screen moves when a state comes and goes.
  static const double _phaseLineHeight = 40;
  static const double _controlRowHeight = 96;

  @override
  void initState() {
    super.initState();
    _pausedPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      lowerBound: 0.35,
      upperBound: 0.9,
    );
    // A timer that sleeps mid-WOD is the app failing: the wakelock is always
    // held while this page is open (the Keep Screen On switch went in 1.3.0).
    WakelockPlus.enable();
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pausedPulse.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ===================================================================
  // Actions
  // ===================================================================

  void _onPauseResume() {
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
    ref.read(timerNotifierProvider.notifier).finish();
  }

  /// Tap anywhere outside the control row: skip the get-ready countdown,
  /// count an AMRAP round, or resume a paused workout. These are the only
  /// canvas gestures (double tap and swipes went in 1.3.0: they meant pause
  /// in three modes and two rounds in AMRAP, and nothing showed them).
  void _onCanvasTap() {
    final notifier = ref.read(timerNotifierProvider.notifier);
    final state = ref.read(timerNotifierProvider);
    if (state is TimerPreparing) {
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
    switch (state) {
      case TimerPreparing():
        _onStopConfirmed();
      case TimerPaused():
        _flashHoldHint();
      case TimerCompleted():
        _onDone();
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
    await ref.read(timerNotifierProvider.notifier).restart();
  }

  /// DONE lands on this mode's setup with the workout just run loaded, so
  /// fixing one number and going again is DONE, stepper, START.
  void _onDone() => _goToSetup();

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

    // Show placeholder when timer is not configured yet
    if (timerState is TimerInitial) {
      return _buildNotConfiguredState();
    }

    final isAmrapRunning =
        timerState is TimerRunning && widget.timerType == TimerTypes.amrap;
    final canvasTaps =
        timerState is TimerPreparing || timerState is TimerPaused || isAmrapRunning;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPopAttempt();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: Semantics(
            label: _buildTimerAccessibilityLabel(timerState),
            liveRegion: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canvasTaps ? _onCanvasTap : null,
              child: OrientationBuilder(
                builder: (context, orientation) {
                  if (timerState is TimerCompleted) {
                    return orientation == Orientation.landscape
                        ? ContentWidthCap(
                            maxWidth: 900,
                            child: _buildCompletedLayout(
                              timerState,
                              landscape: true,
                            ),
                          )
                        : ContentWidthCap(
                            child: _buildCompletedLayout(
                              timerState,
                              landscape: false,
                            ),
                          );
                  }
                  if (orientation == Orientation.landscape) {
                    return _buildLandscapeLayout(timerState);
                  }
                  return _buildPortraitLayout(timerState);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tablets get proportionally bigger text slots so the round keeps its
  /// ratio to a width-filled clock; phones are 1.0.
  double _scale(BuildContext context) =>
      (MediaQuery.sizeOf(context).shortestSide / 390).clamp(1.0, 1.6);

  // ===================================================================
  // Session helpers
  // ===================================================================

  /// Whether this session's For Time timer counts up from zero.
  bool _isCountUpForTime(TimerSession? session) {
    final type = session?.workout.timerType;
    return type is ForTimeTimer && type.countUp;
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
  String _clock(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

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
  // Phase colour (owns the digits, the wash, the bar and the phase word)
  // ===================================================================

  Color _phaseColorOf(domain.TimerState? phase) => switch (phase) {
    domain.TimerState.preparing => AppColors.prepare,
    domain.TimerState.resting => AppColors.rest,
    _ => AppColors.work,
  };

  /// Digits keep the phase they are in (or paused in): a paused Tabata
  /// shows which phase will resume. Paused additionally dims and pulses.
  Color _digitColor(TimerNotifierState state) => state.maybeMap(
    preparing: (_) => AppColors.prepare,
    running: (_) => AppColors.work,
    resting: (_) => AppColors.rest,
    paused: (s) => _phaseColorOf(_effectivePhase(s.session)),
    orElse: () => Colors.white,
  );

  /// Wash and bar colour: grey while paused, the phase otherwise.
  Color _washColor(TimerNotifierState state) => state.maybeMap(
    preparing: (_) => AppColors.prepare,
    running: (_) => AppColors.work,
    resting: (_) => AppColors.rest,
    paused: (_) => AppColors.paused,
    orElse: () => AppColors.primary,
  );

  // ===================================================================
  // Portrait
  // ===================================================================

  Widget _buildPortraitLayout(TimerNotifierState state) {
    final session = state.sessionOrNull;
    final s = _scale(context);

    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: _buildClock(state)),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: _phaseLineHeight * s,
                child: _buildPhaseWord(state, session, fontSize: 34 * s),
              ),
              SizedBox(
                height: _scoreSlotHeight * s,
                child: _buildScoreSlot(state, session, s),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildBarSlot(state, horizontalPadding: AppSpacing.lg),
        const SizedBox(height: AppSpacing.lg),
        ContentWidthCap(
          maxWidth: 560,
          child: _absorbCanvasTaps(
            SizedBox(
              height: _controlRowHeight,
              child: _buildControlRow(state),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  /// The control row keeps its own taps: a near miss on Pause or Stop must
  /// never count a round or resume the workout.
  Widget _absorbCanvasTaps(Widget child) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {},
    child: child,
  );

  /// Fixed per mode, so prep and work share one layout and nothing moves
  /// at GO.
  double get _scoreSlotHeight => switch (widget.timerType) {
    TimerTypes.amrap => 108,
    TimerTypes.forTime => 44,
    _ => 84,
  };

  // ===================================================================
  // Landscape: the propped phone
  // ===================================================================

  Widget _buildLandscapeLayout(TimerNotifierState state) {
    final session = state.sessionOrNull;
    final s = _scale(context);
    final isPaused = state is TimerPaused;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Center(child: _buildClock(state)),
          ),
        ),
        _absorbCanvasTaps(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: SizedBox(
              height: _controlRowHeight,
              child: Row(
                children: [
                  if (isPaused || state is TimerPreparing) ...[
                    _buildStopButton(state),
                    const SizedBox(width: AppSpacing.lg),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Fixed by the 96pt row, whatever the tablet
                        // scale: the text fits itself to it.
                        SizedBox(
                          height: 64,
                          child: _buildLandscapeInfoLine(state, session, s),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _buildBarSlot(state, horizontalPadding: 0),
                      ],
                    ),
                  ),
                  if (state is! TimerPreparing) ...[
                    const SizedBox(width: AppSpacing.lg),
                    if (_showFinish(state)) ...[
                      SizedBox(width: 200, child: _buildFinishButton()),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    _buildPauseDisc(state),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// One line under the landscape clock: the phase word (when there is
  /// one) and the round, score or cap, left-aligned beside the bar.
  Widget _buildLandscapeInfoLine(
    TimerNotifierState state,
    TimerSession? session,
    double s,
  ) {
    if (session == null) return const SizedBox.shrink();
    final parts = <Widget>[];
    final phase = _phaseWord(state, session);
    if (phase != null) {
      parts
        ..add(
          Text(
            phase.$1,
            style: _phaseStyle(phase.$2, 34 * s),
          ),
        )
        ..add(SizedBox(width: AppSpacing.md * s));
    }

    if (state is TimerPreparing) {
      parts.add(Text('TAP TO SKIP', style: _captionStyle(15 * s)));
    } else if (session.totalRounds != null) {
      parts.add(
        Text(
          '${session.currentRound}/${session.totalRounds}',
          style: _roundStyle(56 * s),
        ),
      );
    } else if (widget.timerType == TimerTypes.amrap) {
      if (_showTapToCount(state, session)) {
        parts.add(Text('TAP TO COUNT', style: _hintStyle(34 * s)));
      } else {
        parts
          ..add(Text('${session.currentRound - 1}', style: _roundStyle(56 * s)))
          ..add(SizedBox(width: AppSpacing.sm * s))
          ..add(Text('ROUNDS', style: _captionStyle(15 * s)));
      }
    } else if (_showCap(state, session)) {
      parts.add(Text(_capText(session), style: _capStyle(26 * s)));
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: parts,
        ),
      ),
    );
  }

  // ===================================================================
  // The clock
  // ===================================================================

  /// The giant digits, width-filled (and height-capped by the enclosing
  /// Flexible / Expanded) with the phase wash behind them.
  Widget _buildClock(TimerNotifierState state) {
    final seconds = _displaySeconds(state);
    final timeString = _displayString(state, seconds);
    final isPaused = state is TimerPaused;

    // Pulse for last 3 seconds of prep countdown
    final isPulsing = state is TimerPreparing && seconds <= 3 && seconds > 0;

    Widget digits = Text(
      timeString,
      style: AppTypography.timerDisplay.copyWith(
        fontSize: timeString.contains(':') ? 96 : 150,
        color: _digitColor(state),
      ),
      semanticsLabel:
          '${seconds ~/ 60} minutes ${seconds % 60} seconds '
          '${_isCountUpForTime(state.sessionOrNull) ? 'elapsed' : 'remaining'}',
    );

    // FittedBox only scales UP under a forced size: pin the width so the
    // digits grow to it; the height follows the aspect ratio (and the
    // enclosing Flexible caps it on short screens).
    digits = SizedBox(
      width: double.infinity,
      child: FittedBox(child: digits),
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
        // Radial wash behind the timer carries the phase at a glance.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.9,
                colors: [
                  wash.withValues(alpha: isPaused ? 0.08 : 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: digits,
        ),
      ],
    );
  }

  // ===================================================================
  // Phase word, round slot
  // ===================================================================

  TextStyle _phaseStyle(Color color, double size) =>
      AppTypography.sectionHeader.copyWith(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 4,
        height: 1,
      );

  TextStyle _roundStyle(double size) => AppTypography.timerDisplay.copyWith(
    color: Colors.white,
    fontSize: size,
    letterSpacing: -2,
  );

  TextStyle _hintStyle(double size) => AppTypography.sectionHeader.copyWith(
    color: AppColors.textSecondaryDark,
    fontSize: size,
    fontWeight: FontWeight.w800,
    letterSpacing: 4,
    height: 1,
  );

  TextStyle _captionStyle(double size) => AppTypography.labelSmall.copyWith(
    color: AppColors.textSecondaryDark,
    fontSize: size,
    letterSpacing: 3,
  );

  TextStyle _capStyle(double size) => AppTypography.labelSmall.copyWith(
    color: AppColors.textSecondaryDark,
    fontSize: size,
    fontWeight: FontWeight.w700,
    letterSpacing: 3,
  );

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
        child: Text(phase.$1, style: _phaseStyle(phase.$2, fontSize)),
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

  /// The second big number: the round (EMOM, Tabata), the score (AMRAP) or
  /// the cap (count-up For Time). In prep it carries the skip hint.
  Widget _buildScoreSlot(
    TimerNotifierState state,
    TimerSession? session,
    double s,
  ) {
    if (session == null) return const SizedBox.shrink();

    Widget? child;
    if (state is TimerPreparing) {
      child = Text('TAP TO SKIP', style: _hintStyle(34 * s));
    } else if (session.totalRounds != null) {
      child = Text(
        '${session.currentRound}/${session.totalRounds}',
        style: _roundStyle(80 * s),
      );
    } else if (widget.timerType == TimerTypes.amrap) {
      if (_showTapToCount(state, session)) {
        child = Text('TAP TO COUNT', style: _hintStyle(34 * s));
      } else {
        child = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${session.currentRound - 1}', style: _roundStyle(80 * s)),
            SizedBox(height: AppSpacing.xs * s),
            Text('ROUNDS', style: _captionStyle(15 * s)),
          ],
        );
      }
    } else if (_showCap(state, session)) {
      child = Text(_capText(session), style: _capStyle(26 * s));
    }

    if (child == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topCenter,
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    );
  }

  // ===================================================================
  // Progress bar
  // ===================================================================

  /// The 8pt bar (with round ticks for EMOM and Tabata). Hidden but still
  /// sized during the get-ready countdown, where it would read 0%.
  Widget _buildBarSlot(
    TimerNotifierState state, {
    required double horizontalPadding,
  }) {
    final bar = _buildProgressBar(state, horizontalPadding: horizontalPadding);
    if (state is TimerPreparing) {
      return Visibility(
        visible: false,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: bar,
      );
    }
    return bar;
  }

  Widget _buildProgressBar(
    TimerNotifierState state, {
    required double horizontalPadding,
  }) {
    final session = state.sessionOrNull;
    final progress = session?.progress ?? 0.0;
    final color = _washColor(state);
    final totalRounds = session?.totalRounds;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: SizedBox(
        height: 8,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fillWidth = constraints.maxWidth * progress;
            return Stack(
              children: [
                // Track — visible, so "how far through" is answerable
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.progressTrack,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Fill with glow
                Container(
                  height: 8,
                  width: fillWidth,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                // Round ticks for interval modes
                if (totalRounds != null && totalRounds > 1)
                  for (var i = 1; i < totalRounds; i++)
                    Positioned(
                      left: constraints.maxWidth * i / totalRounds,
                      child: Container(
                        width: 2,
                        height: 8,
                        color: AppColors.backgroundDark,
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ===================================================================
  // Controls: one Pause while running; Stop beside Resume when paused
  // ===================================================================

  bool _showFinish(TimerNotifierState state) =>
      widget.timerType == TimerTypes.forTime &&
      (state is TimerRunning || state is TimerPaused);

  Widget _buildControlRow(TimerNotifierState state) {
    if (state is TimerPreparing) {
      return Center(child: _buildStopButton(state));
    }
    final isPaused = state is TimerPaused;
    if (_showFinish(state)) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            if (isPaused) ...[
              _buildStopButton(state),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(child: _buildFinishButton()),
            SizedBox(width: isPaused ? AppSpacing.md : AppSpacing.lg),
            _buildPauseDisc(state),
          ],
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isPaused) ...[
          _buildStopButton(state),
          const SizedBox(width: 44),
        ],
        _buildPauseDisc(state),
      ],
    );
  }

  Widget _buildStopButton(TimerNotifierState state) => _HoldToStopButton(
    enabled: state.canStop,
    showHint: _showHoldHint,
    onConfirmed: _onStopConfirmed,
    onShortPress: _flashHoldHint,
  );

  /// Pause (running) or Resume (paused): the one fast action, so the
  /// biggest target. 96pt, neutral so colour stays the phase's.
  Widget _buildPauseDisc(TimerNotifierState state) {
    final isPaused = state is TimerPaused;
    final enabled = state.canPause || state.canResume;
    const size = 96.0;

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: '${isPaused ? 'Resume' : 'Pause'} button'
          '${enabled ? '' : ', disabled'}',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: enabled ? _onPauseResume : null,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPaused
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: enabled
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppColors.border,
                width: 2.5,
              ),
            ),
            child: ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.only(left: isPaused ? 5 : 0),
                child: Icon(
                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: isPaused
                      ? AppColors.backgroundDark
                      : (enabled ? Colors.white : AppColors.textDisabledDark),
                  size: isPaused ? 52 : 44,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// For Time's success action: white, labelled, beside Pause so a slip
  /// has to travel sideways into a different shape and colour.
  Widget _buildFinishButton() {
    return Semantics(
      container: true,
      button: true,
      label: 'Finish workout and log your time',
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: _onFinish,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flag, color: Colors.black, size: 22),
                const SizedBox(width: 10),
                Text(
                  'FINISH',
                  style: AppTypography.buttonLarge.copyWith(
                    color: Colors.black,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // Completion: one word, one line, one number
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

  /// The athlete's score, or null when there is none to show (a natural
  /// EMOM / Tabata finish is "you did it"; a time cap is a DNF).
  _Score? _scoreOf(TimerCompleted state) {
    final session = state.session;
    if (state.endedAtTimeCap) return null;
    final elapsed = _clock(session.elapsed.seconds);
    switch (widget.timerType) {
      case TimerTypes.amrap:
        return _Score(
          value: '${session.currentRound - 1}',
          label: 'ROUNDS',
          secondary: state.endedEarly ? elapsed : null,
          adjustable: true,
        );
      case TimerTypes.forTime:
        return _Score(value: elapsed, label: 'TIME');
      default:
        if (!state.endedEarly) return null;
        final total = session.totalRounds;
        if (total == null) return _Score(value: elapsed, label: 'TIME');
        return _Score(value: '${session.currentRound}/$total', label: 'ROUNDS');
    }
  }

  Widget _buildCompletedLayout(
    TimerCompleted state, {
    required bool landscape,
  }) {
    final session = state.session;
    final score = _scoreOf(state);
    final config = Text(
      _configLine(session),
      textAlign: TextAlign.center,
      style: _captionStyle(15).copyWith(letterSpacing: 2.6),
    );

    final Widget middle;
    if (score == null) {
      // No number: the word is the hero.
      final word = state.endedAtTimeCap ? 'Time cap' : 'Finished';
      middle = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            word,
            style: AppTypography.heroTitle.copyWith(
              color: state.endedAtTimeCap
                  ? AppColors.textSecondaryDark
                  : Colors.white,
              fontSize: 56,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          config,
        ],
      );
    } else {
      middle = _buildHero(state, score, landscape: landscape);
    }

    return Column(
      children: [
        SizedBox(height: landscape ? AppSpacing.md : AppSpacing.xxxl),
        if (score != null) ...[
          Text(
            state.endedEarly ? 'Stopped' : 'Finished',
            style: AppTypography.workoutTitle.copyWith(
              color: state.endedEarly
                  ? AppColors.textSecondaryDark
                  : Colors.white,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          config,
        ],
        Expanded(child: Center(child: middle)),
        _buildCompletedButtons(),
        SizedBox(height: landscape ? AppSpacing.md : AppSpacing.xl),
      ],
    );
  }

  Widget _buildHero(
    TimerCompleted state,
    _Score score, {
    required bool landscape,
  }) {
    final color = state.endedEarly ? Colors.white : AppColors.primary;
    Widget hero = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: landscape ? 150 : 200),
      child: SizedBox(
        width: double.infinity,
        child: FittedBox(
          child: Text(
            score.value,
            style: AppTypography.timerDisplay.copyWith(color: color),
          ),
        ),
      ),
    );

    if (score.adjustable) {
      final rounds = state.session.currentRound - 1;
      hero = Row(
        children: [
          _GhostStepButton(
            icon: Icons.remove,
            semanticsLabel: 'One round fewer',
            onPressed: rounds > 0
                ? () => ref
                      .read(timerNotifierProvider.notifier)
                      .adjustRounds(-1)
                : null,
          ),
          Expanded(child: hero),
          _GhostStepButton(
            icon: Icons.add,
            semanticsLabel: 'One round more',
            onPressed: () =>
                ref.read(timerNotifierProvider.notifier).adjustRounds(1),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: hero),
          const SizedBox(height: AppSpacing.xs),
          Text(score.label, style: _captionStyle(15)),
          if (score.secondary != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              score.secondary!,
              style: AppTypography.workoutTitle.copyWith(
                color: Colors.white,
                fontSize: 26,
              ),
            ),
            Text('TIME', style: _captionStyle(15)),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedButtons() {
    Widget button(String label, String semantics, VoidCallback onTap) =>
        Expanded(
          child: Semantics(
            container: true,
            button: true,
            label: semantics,
            excludeSemantics: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Container(
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.borderLight, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: AppTypography.buttonLarge.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

    return ContentWidthCap(
      maxWidth: 520,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            button('AGAIN', 'Run the same workout again', _onAgain),
            const SizedBox(width: AppSpacing.sm),
            button('DONE', 'Done, back to setup', _onDone),
          ],
        ),
      ),
    );
  }
}

/// What the completion hero shows.
class _Score {
  const _Score({
    required this.value,
    required this.label,
    this.secondary,
    this.adjustable = false,
  });

  final String value;
  final String label;

  /// Elapsed time under a stopped AMRAP's rounds.
  final String? secondary;

  /// AMRAP rounds can be corrected with a ghosted minus / plus.
  final bool adjustable;
}

/// Ghosted 44pt minus / plus beside the AMRAP rounds hero, so a stray tap
/// (or a workout nobody tapped through) can be corrected after the fact.
class _GhostStepButton extends StatelessWidget {
  const _GhostStepButton({
    required this.icon,
    required this.semanticsLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticsLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = Colors.white.withValues(alpha: enabled ? 0.4 : 0.15);
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}

/// Stop control that must be held (0.8s) to fire.
///
/// The red ring starts filling the instant the finger lands (a raw pointer
/// listener, so there is no 500ms long-press dead zone first) and confirms
/// when it completes. Letting go early rewinds it and shows HOLD inside the
/// button for a moment: nothing else on the screen moves. This is the
/// error-prevention guard for the app's only destructive action.
class _HoldToStopButton extends StatefulWidget {
  const _HoldToStopButton({
    required this.enabled,
    required this.showHint,
    required this.onConfirmed,
    required this.onShortPress,
  });

  final bool enabled;
  final bool showHint;
  final VoidCallback onConfirmed;
  final VoidCallback onShortPress;

  @override
  State<_HoldToStopButton> createState() => _HoldToStopButtonState();
}

class _HoldToStopButtonState extends State<_HoldToStopButton>
    with SingleTickerProviderStateMixin {
  static const double _size = 64;

  late final AnimationController _fill;
  bool _confirmed = false;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _fill =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 800),
          )
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && !_confirmed) {
              _confirmed = true;
              widget.onConfirmed();
            }
          })
          ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  void _startHold() {
    if (!widget.enabled) return;
    _confirmed = false;
    _holding = true;
    HapticFeedback.mediumImpact();
    _fill.forward(from: 0);
  }

  void _release() {
    if (!_holding) return;
    _holding = false;
    if (_confirmed) return;
    _fill
      ..stop()
      ..animateBack(0, duration: const Duration(milliseconds: 150));
    widget.onShortPress();
  }

  void _cancel() {
    if (!_holding) return;
    _holding = false;
    if (_confirmed) return;
    _fill
      ..stop()
      ..animateBack(0, duration: const Duration(milliseconds: 150));
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final hint = widget.showHint && enabled;
    final ringColor = enabled
        ? AppColors.error.withValues(alpha: hint ? 1 : 0.7)
        : AppColors.border;
    final iconColor = enabled ? AppColors.error : AppColors.textDisabledDark;

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: 'End workout. Hold to confirm.',
      onLongPress: enabled ? widget.onConfirmed : null,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: enabled ? (_) => _startHold() : null,
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _cancel(),
        child: SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(
                    alpha: enabled ? 0.10 : 0.0,
                  ),
                  border: Border.all(color: ringColor, width: 1.5),
                ),
                child: hint
                    ? Center(
                        child: Text(
                          'HOLD',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.error,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      )
                    : Icon(Icons.stop, color: iconColor, size: 28),
              ),
              // Hold-progress ring fills as confirmation approaches
              if (_fill.value > 0)
                SizedBox(
                  width: _size,
                  height: _size,
                  child: CircularProgressIndicator(
                    value: _fill.value,
                    strokeWidth: 3.5,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.error,
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
