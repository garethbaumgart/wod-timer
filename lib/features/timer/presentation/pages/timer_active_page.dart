import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';

/// Active timer display page - Signal design.
///
/// The screen is built for the 3-metre gym glance: the phase (get ready /
/// work / rest / paused) owns the colour of the giant digits and the
/// background wash, and the round counter is a first-class figure.
/// Stop is hold-to-confirm; ending early reports an honest "Stopped"
/// state instead of a celebration.
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

  /// Transient "hold to end" hint shown when Stop is tapped instead of held.
  bool _showHoldHint = false;

  @override
  void initState() {
    super.initState();
    _pausedPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      lowerBound: 0.35,
      upperBound: 0.9,
    );
    // Keep screen on during workout (honours the settings toggle)
    if (ref.read(appSettingsNotifierProvider).keepScreenOn) {
      WakelockPlus.enable();
    }
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pausedPulse.dispose();
    // Restore screen behavior
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

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
  /// go straight back to setup; mid-workout, land on the honest
  /// "Stopped" completion state.
  void _onStopConfirmed() {
    final state = ref.read(timerNotifierProvider);
    if (state is TimerPreparing) {
      ref.read(timerNotifierProvider.notifier).reset();
      context.go(AppRoutes.timerSetupPath(widget.timerType));
      return;
    }
    ref.read(timerNotifierProvider.notifier).stop();
  }

  void _onStopTapped() {
    setState(() => _showHoldHint = true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showHoldHint = false);
    });
  }

  void _onFinish() {
    ref.read(timerNotifierProvider.notifier).finish();
  }

  void _onCanvasTap() {
    final state = ref.read(timerNotifierProvider);
    if (state is TimerPreparing) {
      ref.read(hapticServiceProvider).mediumImpact();
      ref.read(timerNotifierProvider.notifier).skipPrep();
      return;
    }
    if (state is TimerRunning && widget.timerType == TimerTypes.amrap) {
      ref.read(timerNotifierProvider.notifier).countRound();
    }
  }

  Future<void> _onReset() async {
    final state = ref.read(timerNotifierProvider);
    // Only reset if timer is not in initial state (was properly started)
    if (state is! TimerInitial) {
      ref.read(timerNotifierProvider.notifier).reset();
    }
    if (mounted) {
      context.go(AppRoutes.timerSetupPath(widget.timerType));
    }
  }

  Future<void> _onRestart() async {
    await ref.read(timerNotifierProvider.notifier).restart();
  }

  void _onComplete() {
    final state = ref.read(timerNotifierProvider);
    // Only reset if timer is not in initial state (was properly started)
    if (state is! TimerInitial) {
      ref.read(timerNotifierProvider.notifier).reset();
    }
    context.go(AppRoutes.home);
  }

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

    // React to the Keep Screen On setting changing mid-workout
    ref.listen(appSettingsNotifierProvider.select((s) => s.keepScreenOn), (
      previous,
      keepScreenOn,
    ) {
      if (keepScreenOn) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    });

    // Show placeholder when timer is not configured yet
    if (timerState is TimerInitial) {
      return _buildNotConfiguredState();
    }

    // AMRAP counts rounds on tap, so double-tap-to-pause is disabled there
    // (the two gestures can't coexist); swipe up/down still pauses/resumes.
    final isAmrapRunning =
        timerState is TimerRunning && widget.timerType == TimerTypes.amrap;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Semantics(
          label: _buildTimerAccessibilityLabel(timerState),
          liveRegion: true,
          child: GestureDetector(
            onTap: timerState is TimerPreparing || isAmrapRunning
                ? _onCanvasTap
                : null,
            onDoubleTap:
                !isAmrapRunning && (timerState.canPause || timerState.canResume)
                ? _onPauseResume
                : null,
            // Swipe up to pause
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity == null) return;

              // Swipe up (negative velocity) to pause
              if (details.primaryVelocity! < -300 && timerState.canPause) {
                ref.read(hapticServiceProvider).mediumImpact();
                _onPauseResume();
              }
              // Swipe down (positive velocity) to resume when paused
              else if (details.primaryVelocity! > 300 && timerState.canResume) {
                ref.read(hapticServiceProvider).mediumImpact();
                _onPauseResume();
              }
            },
            child: OrientationBuilder(
              builder: (context, orientation) {
                if (orientation == Orientation.landscape) {
                  return _buildLandscapeLayout(timerState);
                }
                return _buildPortraitLayout(timerState);
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Whether this session's For Time timer counts up from zero.
  bool _isCountUpForTime(TimerSession? session) {
    final type = session?.workout.timerType;
    return type is ForTimeTimer && type.countUp;
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

    // Only show control hints when pause/resume is available
    final amrapHint =
        state is TimerRunning && widget.timerType == TimerTypes.amrap
        ? ' Tap to count a round.'
        : '';
    final controlsHint = (state.canPause || state.canResume)
        ? '. Swipe up to pause, swipe down to resume. '
              'Hold the stop button to end.$amrapHint'
        : '';

    final direction = _isCountUpForTime(session) ? 'elapsed' : 'remaining';
    return '$phase, $minutes minutes $secs seconds $direction'
        '$roundInfo$controlsHint';
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
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  onPressed: _onReset,
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

  // -- Phase color helper (owns digits, wash, pill and progress) --

  Color _getPhaseColor(TimerNotifierState state) {
    return state.maybeMap(
      preparing: (_) => AppColors.prepare,
      running: (_) => AppColors.work,
      resting: (_) => AppColors.rest,
      paused: (_) => AppColors.paused,
      completed: (s) => s.endedEarly ? AppColors.paused : AppColors.complete,
      orElse: () => AppColors.primary,
    );
  }

  String _getPhaseLabel(TimerNotifierState state) {
    return state.maybeMap(
      preparing: (_) => 'GET READY',
      running: (_) => 'WORK',
      resting: (_) => 'REST',
      paused: (_) => 'PAUSED',
      completed: (s) => s.endedEarly ? 'STOPPED' : 'COMPLETE',
      orElse: () => '',
    );
  }

  String _getTimerTypeLabel() {
    switch (widget.timerType) {
      case TimerTypes.amrap:
        return 'AMRAP';
      case TimerTypes.forTime:
        return 'FOR TIME';
      case TimerTypes.emom:
        return 'EMOM';
      case TimerTypes.tabata:
        return 'TABATA';
      default:
        return widget.timerType.toUpperCase();
    }
  }

  /// Pill text: the phase word is shown only when it carries information
  /// (get-ready/paused/rest always; WORK only for Tabata, the one running
  /// mode with a contrasting phase).
  String _pillText(TimerNotifierState state) {
    final type = _getTimerTypeLabel();
    final showPhase =
        state is TimerPreparing ||
        state is TimerPaused ||
        state is TimerResting ||
        (state is TimerRunning && widget.timerType == TimerTypes.tabata);
    if (!showPhase) return type;
    return '$type  ·  ${_getPhaseLabel(state)}';
  }

  // ===================================================================
  // Portrait Layout
  // ===================================================================

  Widget _buildPortraitLayout(TimerNotifierState state) {
    // Completed state has a special layout
    if (state is TimerCompleted) {
      return _buildCompletedLayout(state);
    }

    final session = state.sessionOrNull;
    final phaseColor = _getPhaseColor(state);

    return Column(
      children: [
        const Spacer(flex: 2),

        // Pill badge: "TABATA . REST"
        _buildPillBadge(state, phaseColor),

        const Spacer(),

        // Giant time with radial glow behind
        _buildTimerWithGlow(state, phaseColor),

        const SizedBox(height: AppSpacing.sm),

        // Direction label + round counter + phase preview
        _buildSubInfo(state, session, phaseColor),

        const Spacer(flex: 2),

        // Progress bar
        _buildProgressBar(state),

        const SizedBox(height: AppSpacing.lg),

        // For Time: the success action is a real, labelled button
        if (_showFinishButton(state)) ...[
          _buildFinishButton(),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Control buttons
        _buildControls(state),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  bool _showFinishButton(TimerNotifierState state) {
    return widget.timerType == TimerTypes.forTime &&
        (state is TimerRunning || state is TimerPaused);
  }

  // ===================================================================
  // Landscape Layout
  // ===================================================================

  Widget _buildLandscapeLayout(TimerNotifierState state) {
    if (state is TimerCompleted) {
      return _buildCompletedLayoutLandscape(state);
    }

    final session = state.sessionOrNull;
    final phaseColor = _getPhaseColor(state);

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Left side - Timer display
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPillBadge(state, phaseColor),
                    const SizedBox(height: AppSpacing.md),
                    _buildTimerWithGlow(state, phaseColor, expand: true),
                    const SizedBox(height: AppSpacing.sm),
                    _buildSubInfo(state, session, phaseColor),
                  ],
                ),
              ),

              // Right side - Controls
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_showFinishButton(state)) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: _buildFinishButton(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    _buildControlsCompact(state),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Full-width progress bar in landscape too
        _buildProgressBar(state),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  // ===================================================================
  // Pill Badge
  // ===================================================================

  Widget _buildPillBadge(TimerNotifierState state, Color phaseColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: phaseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        _pillText(state),
        style: AppTypography.pillBadge.copyWith(color: phaseColor),
      ),
    );
  }

  // ===================================================================
  // Timer with radial glow
  // ===================================================================

  /// Display string for the giant digits.
  ///
  /// Sub-minute countdowns (prep countdown, Tabata/EMOM intervals, the
  /// final minute) drop the dead "00:" prefix so the meaningful digits
  /// render roughly twice as tall. Count-up displays keep MM:SS.
  String _displayString(TimerNotifierState state, int seconds) {
    final isCountUp =
        state is! TimerPreparing && _isCountUpForTime(state.sessionOrNull);
    if (!isCountUp && seconds < 60) {
      return '$seconds';
    }
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildTimerWithGlow(
    TimerNotifierState state,
    Color phaseColor, {
    bool expand = false,
  }) {
    final seconds = _displaySeconds(state);
    final timeString = _displayString(state, seconds);
    final isBareSeconds = !timeString.contains(':');
    final isPaused = state is TimerPaused;

    // Pulse animation for last 3 seconds of prep countdown
    final isPulsing = state is TimerPreparing && seconds <= 3 && seconds > 0;

    final baseSize = isBareSeconds ? 150.0 : 96.0;
    final fontSize = isPulsing ? baseSize + 14 : baseSize;

    // The phase owns the digit colour — the one channel that survives
    // 3 metres. Paused additionally dims and pulses.
    final digitColor = state.maybeMap(
      preparing: (_) => AppColors.prepare,
      running: (_) => AppColors.work,
      resting: (_) => AppColors.rest,
      paused: (_) => Colors.white,
      orElse: () => Colors.white,
    );

    Widget digits = AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: AppTypography.timerDisplay.copyWith(
        fontSize: fontSize,
        color: digitColor,
      ),
      // In landscape the digits scale UP to fill the wide column — the
      // whole point of the propped-phone posture is a bigger clock.
      child: FittedBox(
        fit: expand ? BoxFit.contain : BoxFit.scaleDown,
        child: Text(
          timeString,
          semanticsLabel:
              '${seconds ~/ 60} minutes ${seconds % 60} seconds '
              '${_isCountUpForTime(state.sessionOrNull) ? 'elapsed' : 'remaining'}',
        ),
      ),
    );

    if (isPaused) {
      digits = FadeTransition(opacity: _pausedPulse, child: digits);
    }
    if (expand) {
      digits = SizedBox(
        width: double.infinity,
        height: 180,
        child: digits,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Radial wash behind the timer carries the phase at a glance.
        // Positioned.fill so the decoration never dictates layout height
        // (a fixed 300px circle overflowed the landscape column).
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.9,
                colors: [
                  phaseColor.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: digits,
        ),
      ],
    );
  }

  // ===================================================================
  // Sub info: direction label, round counter, phase preview, cap
  // ===================================================================

  Widget _buildSubInfo(
    TimerNotifierState state,
    TimerSession? session,
    Color phaseColor,
  ) {
    if (session == null) return const SizedBox.shrink();

    final children = <Widget>[];

    // Small direction label — every mode, not just For Time.
    final directionLabel = state is TimerPreparing
        ? 'STARTS IN'
        : (_isCountUpForTime(session) ? 'ELAPSED' : 'REMAINING');
    children.add(
      Text(
        directionLabel,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondaryDark,
          letterSpacing: 2,
          fontSize: 13,
        ),
      ),
    );

    // Round counter is co-primary information for round-based modes.
    if (session.totalRounds != null && state is! TimerPreparing) {
      children
        ..add(const SizedBox(height: 6))
        ..add(
          Text(
            'ROUND ${session.currentRound}/${session.totalRounds}',
            style: AppTypography.timerDisplaySmall.copyWith(
              color: Colors.white,
              fontSize: 40,
            ),
          ),
        );
    }

    // AMRAP: the manual tap-to-count tally.
    if (widget.timerType == TimerTypes.amrap && state is! TimerPreparing) {
      final counted = session.currentRound - 1;
      children
        ..add(const SizedBox(height: 6))
        ..add(
          Text(
            'ROUNDS $counted',
            style: AppTypography.timerDisplaySmall.copyWith(
              color: Colors.white,
              fontSize: 40,
            ),
          ),
        );
      if (counted == 0 && state is TimerRunning) {
        children
          ..add(const SizedBox(height: 4))
          ..add(
            Text(
              'TAP ANYWHERE TO COUNT A ROUND',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textHintDark,
                letterSpacing: 1.5,
                fontSize: 11,
              ),
            ),
          );
      }
    }

    // For Time: keep the cap in sight while pacing against it.
    if (widget.timerType == TimerTypes.forTime) {
      final type = session.workout.timerType;
      if (type is ForTimeTimer) {
        children
          ..add(const SizedBox(height: 6))
          ..add(
            Text(
              'CAP ${_clock(type.timeCap.seconds)}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
      }
    }

    // Tabata: phase preview in the last seconds of a phase.
    if (widget.timerType == TimerTypes.tabata) {
      final preview = _buildPhasePreview(state, session);
      if (preview != null) {
        children
          ..add(const SizedBox(height: 6))
          ..add(preview);
      }
    }

    // Prep: skip affordance.
    if (state is TimerPreparing) {
      children
        ..add(const SizedBox(height: 6))
        ..add(
          Text(
            'TAP TO START NOW',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textHintDark,
              letterSpacing: 1.5,
              fontSize: 11,
            ),
          ),
        );
    }

    return Column(children: children);
  }

  /// "WORK in 3s" — anticipation for the next Tabata phase flip.
  Widget? _buildPhasePreview(TimerNotifierState state, TimerSession session) {
    final timeRemaining = session.timeRemaining.seconds;

    // Show preview when 5 or fewer seconds remain in the current phase
    if (timeRemaining > 5) return null;

    String nextPhase;
    Color nextColor;

    if (state is TimerRunning) {
      nextPhase = 'REST';
      nextColor = AppColors.rest;
    } else if (state is TimerResting) {
      if (session.currentRound >= (session.totalRounds ?? 0)) {
        nextPhase = 'COMPLETE';
        nextColor = AppColors.complete;
      } else {
        nextPhase = 'WORK';
        nextColor = AppColors.work;
      }
    } else {
      return null;
    }

    return AnimatedOpacity(
      opacity: timeRemaining <= 3 ? 1.0 : 0.7,
      duration: const Duration(milliseconds: 200),
      child: Text(
        '$nextPhase in ${timeRemaining}s',
        style: AppTypography.bodyMedium.copyWith(
          color: nextColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ===================================================================
  // Progress Bar
  // ===================================================================

  Widget _buildProgressBar(TimerNotifierState state) {
    final session = state.sessionOrNull;
    final progress = session?.progress ?? 0.0;
    final phaseColor = _getPhaseColor(state);
    final totalRounds = session?.totalRounds;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                    color: phaseColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: phaseColor.withValues(alpha: 0.3),
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
  // FINISH — For Time's success action, labelled and unmissable
  // ===================================================================

  Widget _buildFinishButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Semantics(
        button: true,
        label: 'Finish workout and log your time',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _onFinish,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
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
      ),
    );
  }

  // ===================================================================
  // Control Buttons
  // ===================================================================

  Widget _buildControls(TimerNotifierState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          if (_showHoldHint)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'HOLD TO END WORKOUT',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.error,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
            ),
          _buildActiveControls(state),
        ],
      ),
    );
  }

  Widget _buildActiveControls(TimerNotifierState state) {
    final isPaused = state is TimerPaused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Stop button (hold to confirm)
        _HoldToStopButton(
          enabled: state.canStop,
          onConfirmed: _onStopConfirmed,
          onTapped: _onStopTapped,
        ),

        // Pause/Resume button (large centre; neutral so colour = phase)
        _buildCircleButton(
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          label: isPaused ? 'RESUME' : 'PAUSE',
          borderColor: Colors.white70,
          iconColor: Colors.white,
          onPressed: state.canPause || state.canResume ? _onPauseResume : null,
          size: 72,
        ),

        // Symmetry placeholder (FINISH moved to its own labelled button)
        const SizedBox(width: 64),
      ],
    );
  }

  Widget _buildControlsCompact(TimerNotifierState state) {
    final isPaused = state is TimerPaused;

    return Column(
      children: [
        if (_showHoldHint)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'HOLD TO END WORKOUT',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.error,
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _HoldToStopButton(
              enabled: state.canStop,
              onConfirmed: _onStopConfirmed,
              onTapped: _onStopTapped,
            ),
            const SizedBox(width: AppSpacing.lg),
            _buildCircleButton(
              icon: isPaused ? Icons.play_arrow : Icons.pause,
              label: isPaused ? 'RESUME' : 'PAUSE',
              borderColor: Colors.white70,
              iconColor: Colors.white,
              onPressed: state.canPause || state.canResume
                  ? _onPauseResume
                  : null,
              size: 72,
            ),
          ],
        ),
      ],
    );
  }

  // ===================================================================
  // Circle Button (border-only style, with a caption)
  // ===================================================================

  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required Color borderColor,
    required Color iconColor,
    required VoidCallback? onPressed,
    required double size,
  }) {
    final isDisabled = onPressed == null;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: '$label button${isDisabled ? ', disabled' : ''}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(size / 2),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDisabled ? AppColors.border : borderColor,
                    width: 1.5,
                  ),
                ),
                child: ExcludeSemantics(
                  child: Icon(
                    icon,
                    color: isDisabled ? AppColors.textDisabledDark : iconColor,
                    size: size * 0.45,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          ExcludeSemantics(
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondaryDark,
                letterSpacing: 1.5,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // Completed State Layout
  // ===================================================================

  /// Clock format for stats: "0:19", "10:00".
  String _clock(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  /// One-line record of what the workout was ("AMRAP · 10:00").
  String _configLine(TimerSession session) {
    return session.workout.timerType.when(
      amrap: (t) => 'AMRAP  ·  ${_clock(t.duration.seconds)}',
      forTime: (t) => 'FOR TIME  ·  CAP ${_clock(t.timeCap.seconds)}',
      emom: (t) =>
          'EMOM  ·  ${t.rounds.value} × '
          '${_clock(t.intervalDuration.seconds)}',
      tabata: (t) =>
          'TABATA  ·  ${t.workDuration.seconds}s/'
          '${t.restDuration.seconds}s × ${t.rounds.value}',
    );
  }

  /// The true completed fraction — a stopped workout must not render a
  /// 100% bar.
  double _completedFraction(TimerCompleted state) {
    if (!state.endedEarly) return 1;
    final session = state.session;
    final total = session.workout.timerType.estimatedDuration.seconds;
    if (total == 0) return 1;
    return (session.elapsed.seconds / total).clamp(0.02, 1.0);
  }

  Widget _buildCompletedHeader(TimerCompleted state) {
    final session = state.session;
    final endedEarly = state.endedEarly;
    final total = session.workout.timerType.estimatedDuration.seconds;

    return Column(
      children: [
      if (endedEarly) ...[
        const Icon(
          Icons.stop_circle_outlined,
          size: 52,
          color: AppColors.paused,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Stopped',
          style: AppTypography.workoutTitle.copyWith(
            color: Colors.white,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_clock(session.elapsed.seconds)} of ${_clock(total)}',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryDark,
          ),
        ),
      ] else ...[
        const Icon(Icons.check, size: 56, color: AppColors.primary),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Finished!',
          style: AppTypography.workoutTitle.copyWith(
            color: Colors.white,
            fontSize: 28,
          ),
        ),
      ],
      const SizedBox(height: 6),
      Text(
        _configLine(session),
        style: AppTypography.summaryLabel.copyWith(
          color: AppColors.textHintDark,
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
      ],
    );
  }

  /// The hero stat is the athlete's score: rounds for round-based modes,
  /// time for the others.
  Widget _buildCompletedStats(TimerCompleted state) {
    final session = state.session;
    final elapsedString = _clock(session.elapsed.seconds);

    String heroValue;
    String heroLabel;
    String? secondaryValue;
    String? secondaryLabel;

    if (session.totalRounds != null) {
      heroValue = '${session.currentRound}/${session.totalRounds}';
      heroLabel = 'ROUNDS';
      secondaryValue = elapsedString;
      secondaryLabel = 'TOTAL TIME';
    } else if (widget.timerType == TimerTypes.amrap) {
      final counted = session.currentRound - 1;
      if (counted > 0) {
        heroValue = '$counted';
        heroLabel = 'ROUNDS';
        secondaryValue = elapsedString;
        secondaryLabel = 'TOTAL TIME';
      } else {
        heroValue = elapsedString;
        heroLabel = 'TOTAL TIME';
      }
    } else {
      heroValue = elapsedString;
      heroLabel = state.endedEarly ? 'TIME' : 'YOUR TIME';
    }

    return Column(
      children: [
        Text(
          heroValue,
          style: AppTypography.timerDisplay.copyWith(
            color: state.endedEarly ? Colors.white : AppColors.primary,
            fontSize: 68,
          ),
        ),
        Text(
          heroLabel,
          style: AppTypography.summaryLabel.copyWith(
            color: AppColors.textSecondaryDark,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
        if (secondaryValue != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            secondaryValue,
            style: AppTypography.workoutTitle.copyWith(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          Text(
            secondaryLabel!,
            style: AppTypography.summaryLabel.copyWith(
              color: AppColors.textHintDark,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletedBar(TimerCompleted state) {
    final fraction = _completedFraction(state);
    final color = state.endedEarly ? AppColors.paused : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SizedBox(
        height: 8,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.progressTrack,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 8,
                  width: constraints.maxWidth * fraction,
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
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompletedLayout(TimerCompleted state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        _buildCompletedHeader(state),
        const SizedBox(height: AppSpacing.xl),
        _buildCompletedStats(state),
        const Spacer(flex: 2),
        _buildCompletedBar(state),
        const SizedBox(height: AppSpacing.xl),
        _buildCompletedButtons(),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildCompletedLayoutLandscape(TimerCompleted state) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCompletedHeader(state),
                    const SizedBox(height: AppSpacing.lg),
                    _buildCompletedStats(state),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [_buildCompletedButtons()],
                ),
              ),
            ],
          ),
        ),
        _buildCompletedBar(state),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildCompletedButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Row(
        children: [
          // Again button (bordered, readable)
          Expanded(
            child: Semantics(
              button: true,
              label: 'Run the same workout again',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onRestart,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'AGAIN',
                      style: AppTypography.buttonMedium.copyWith(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Done button (filled green)
          Expanded(
            child: Semantics(
              button: true,
              label: 'Done button',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onComplete,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'DONE',
                      style: AppTypography.buttonMedium.copyWith(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stop control that must be held (~0.8s) to fire.
///
/// A plain tap calls [onTapped] so the page can flash a "hold to end"
/// hint; holding fills a red ring around the button and confirms when the
/// fill completes. This is the error-prevention guard for the app's only
/// destructive action.
class _HoldToStopButton extends StatefulWidget {
  const _HoldToStopButton({
    required this.enabled,
    required this.onConfirmed,
    required this.onTapped,
  });

  final bool enabled;
  final VoidCallback onConfirmed;
  final VoidCallback onTapped;

  @override
  State<_HoldToStopButton> createState() => _HoldToStopButtonState();
}

class _HoldToStopButtonState extends State<_HoldToStopButton>
    with SingleTickerProviderStateMixin {
  static const double _size = 64;

  late final AnimationController _fill;
  bool _confirmed = false;

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
    HapticFeedback.mediumImpact();
    _fill.forward(from: 0);
  }

  void _cancelHold() {
    if (_confirmed) return;
    _fill
      ..stop()
      ..animateBack(0, duration: const Duration(milliseconds: 150));
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final ringColor = enabled
        ? AppColors.error.withValues(alpha: 0.7)
        : AppColors.border;
    final iconColor = enabled ? AppColors.error : AppColors.textDisabledDark;

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'End workout. Hold to confirm.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: enabled ? widget.onTapped : null,
            onLongPressStart: enabled ? (_) => _startHold() : null,
            onLongPressEnd: (_) => _cancelHold(),
            onLongPressCancel: _cancelHold,
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
                    child: ExcludeSemantics(
                      child: Icon(Icons.stop, color: iconColor, size: 28),
                    ),
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
          const SizedBox(height: 6),
          ExcludeSemantics(
            child: Text(
              'HOLD TO END',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondaryDark,
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
