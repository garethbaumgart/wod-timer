import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';

/// Active timer display page - Signal design.
///
/// Shows the running timer with large display for gym visibility.
/// Supports pause/resume and stop controls.
class TimerActivePage extends ConsumerStatefulWidget {
  const TimerActivePage({
    required this.timerType,
    super.key,
  });

  /// The type of timer being displayed.
  final String timerType;

  @override
  ConsumerState<TimerActivePage> createState() => _TimerActivePageState();
}

class _TimerActivePageState extends ConsumerState<TimerActivePage> {
  @override
  void initState() {
    super.initState();
    // Keep screen on during workout
    WakelockPlus.enable();
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
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

  void _onStop() {
    ref.read(timerNotifierProvider.notifier).stop();
  }

  Future<void> _onReset() async {
    final state = ref.read(timerNotifierProvider);

    // Show confirmation dialog if timer is actively running
    if (state.canPause || state.canResume) {
      final shouldExit = await _showExitConfirmation();
      if (!shouldExit) return;
    }

    // Only reset if timer is not in initial state (was properly started)
    if (state is! TimerInitial) {
      ref.read(timerNotifierProvider.notifier).reset();
    }
    if (mounted) {
      context.go(AppRoutes.timerSetupPath(widget.timerType));
    }
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text(
              'Exit Workout?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Your workout is still in progress. Are you sure you want to exit? Your progress will be lost.',
              style: TextStyle(color: Color(0xFF888888)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'CONTINUE WORKOUT',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: const Text('EXIT'),
              ),
            ],
          ),
        ) ??
        false;
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

    // Show placeholder when timer is not configured yet
    if (timerState is TimerInitial) {
      return _buildNotConfiguredState();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Semantics(
          label: _buildTimerAccessibilityLabel(timerState),
          liveRegion: true,
          child: GestureDetector(
            // Tap anywhere to toggle pause (optional UX enhancement)
            onDoubleTap: timerState.canPause || timerState.canResume
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
              else if (details.primaryVelocity! > 300 &&
                  timerState.canResume) {
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

  String _buildTimerAccessibilityLabel(TimerNotifierState state) {
    final session = state.sessionOrNull;
    if (session == null) return 'Timer not started';

    final timeRemaining = session.timeRemaining.seconds;
    final minutes = timeRemaining ~/ 60;
    final secs = timeRemaining % 60;

    final phase = state.maybeMap(
      preparing: (_) => 'Get Ready',
      running: (_) => 'Work',
      resting: (_) => 'Rest',
      paused: (_) => 'Paused',
      completed: (_) => 'Complete',
      orElse: () => '',
    );

    final roundInfo = session.totalRounds != null
        ? ', Round ${session.currentRound} of ${session.totalRounds}'
        : '';

    // Only show control hints when pause/resume is available
    final controlsHint = (state.canPause || state.canResume)
        ? '. Double tap to pause or resume. Swipe up to pause, swipe down to resume.'
        : '';

    return '$phase, $minutes minutes $secs seconds remaining$roundInfo$controlsHint';
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
                  'Go back to the setup page to configure and start your workout.',
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

  // -- Phase color helper (used for pill badge & glow) --

  Color _getPhaseColor(TimerNotifierState state) {
    return state.maybeMap(
      preparing: (_) => AppColors.prepare,
      running: (_) => AppColors.work,
      resting: (_) => AppColors.rest,
      paused: (_) => AppColors.paused,
      completed: (_) => AppColors.complete,
      orElse: () => AppColors.primary,
    );
  }

  String _getPhaseLabel(TimerNotifierState state) {
    return state.maybeMap(
      preparing: (_) => 'GET READY',
      running: (_) => 'WORK',
      resting: (_) => 'REST',
      paused: (_) => 'PAUSED',
      completed: (_) => 'COMPLETE',
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

  // ===================================================================
  // Portrait Layout
  // ===================================================================

  Widget _buildPortraitLayout(TimerNotifierState state) {
    // Completed state has a special layout
    if (state is TimerCompleted) {
      return _buildCompletedLayout(state);
    }

    final session = state.sessionOrNull;
    final timeRemaining = session?.timeRemaining.seconds ?? 0;
    final phaseColor = _getPhaseColor(state);

    return Column(
      children: [
        const Spacer(flex: 2),

        // Pill badge: "FOR TIME . WORK"
        _buildPillBadge(state, phaseColor),

        const Spacer(),

        // Giant time with radial glow behind
        _buildTimerWithGlow(timeRemaining, state, phaseColor),

        const SizedBox(height: AppSpacing.sm),

        // Sub-label below time
        _buildSubLabel(state, session),

        const Spacer(flex: 2),

        // Progress bar
        _buildProgressBar(state),

        const SizedBox(height: AppSpacing.xl),

        // Control buttons
        _buildControls(state),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // ===================================================================
  // Landscape Layout
  // ===================================================================

  Widget _buildLandscapeLayout(TimerNotifierState state) {
    if (state is TimerCompleted) {
      return _buildCompletedLayoutLandscape(state);
    }

    final session = state.sessionOrNull;
    final timeRemaining = session?.timeRemaining.seconds ?? 0;
    final phaseColor = _getPhaseColor(state);

    return Row(
      children: [
        // Left side - Timer display
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPillBadge(state, phaseColor),
              const SizedBox(height: AppSpacing.md),
              _buildTimerWithGlow(timeRemaining, state, phaseColor),
              const SizedBox(height: AppSpacing.sm),
              _buildSubLabel(state, session),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: _buildProgressBar(state),
              ),
            ],
          ),
        ),

        // Right side - Controls
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlsCompact(state),
            ],
          ),
        ),
      ],
    );
  }

  // ===================================================================
  // Pill Badge
  // ===================================================================

  Widget _buildPillBadge(TimerNotifierState state, Color phaseColor) {
    final typeLabel = _getTimerTypeLabel();
    final phaseLabel = _getPhaseLabel(state);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: phaseColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        '$typeLabel  \u00B7  $phaseLabel',
        style: AppTypography.pillBadge.copyWith(
          color: phaseColor,
        ),
      ),
    );
  }

  // ===================================================================
  // Timer with radial glow
  // ===================================================================

  Widget _buildTimerWithGlow(
    int seconds,
    TimerNotifierState state,
    Color phaseColor,
  ) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    // Pulse animation for last 3 seconds of prep countdown
    final isPulsing = state is TimerPreparing && seconds <= 3 && seconds > 0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Radial glow behind the timer
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                phaseColor.withValues(alpha: 0.06),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7],
            ),
          ),
        ),
        // Giant time text
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: AppTypography.timerDisplay.copyWith(
            fontSize: isPulsing ? 104 : 96,
            color: Colors.white,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              timeString,
              semanticsLabel: '$minutes minutes $secs seconds remaining',
            ),
          ),
        ),
      ],
    );
  }

  // ===================================================================
  // Sub-label below time
  // ===================================================================

  Widget _buildSubLabel(TimerNotifierState state, TimerSession? session) {
    if (session == null) return const SizedBox.shrink();

    // Show round info if available
    if (session.totalRounds != null) {
      return Text(
        'Round ${session.currentRound}/${session.totalRounds}',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textDisabledDark,
        ),
      );
    }

    // Show "Elapsed" for For Time
    if (widget.timerType == TimerTypes.forTime) {
      return Text(
        'Elapsed',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textDisabledDark,
        ),
      );
    }

    // Phase preview for Tabata (last 5 seconds)
    if (widget.timerType == TimerTypes.tabata) {
      return _buildPhasePreview(state, session);
    }

    return const SizedBox.shrink();
  }

  Widget _buildPhasePreview(TimerNotifierState state, TimerSession session) {
    final timeRemaining = session.timeRemaining.seconds;

    // Show preview when less than 5 seconds remain in current phase
    if (timeRemaining > 5) return const SizedBox.shrink();

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
      return const SizedBox.shrink();
    }

    return AnimatedOpacity(
      opacity: timeRemaining <= 3 ? 1.0 : 0.6,
      duration: const Duration(milliseconds: 200),
      child: Text(
        '$nextPhase in ${timeRemaining}s',
        style: AppTypography.bodySmall.copyWith(
          color: nextColor,
          fontWeight: FontWeight.w600,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SizedBox(
        height: 3,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fillWidth = constraints.maxWidth * progress;
            return Stack(
              children: [
                // Track
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                // Fill with glow
                Container(
                  height: 3,
                  width: fillWidth,
                  decoration: BoxDecoration(
                    color: phaseColor,
                    borderRadius: BorderRadius.circular(1.5),
                    boxShadow: [
                      BoxShadow(
                        color: phaseColor.withValues(alpha: 0.3),
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

  // ===================================================================
  // Control Buttons (Portrait)
  // ===================================================================

  Widget _buildControls(TimerNotifierState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: _buildActiveControls(state),
    );
  }

  Widget _buildActiveControls(TimerNotifierState state) {
    final isPaused = state is TimerPaused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Stop button
        _buildCircleButton(
          icon: Icons.stop,
          label: 'Stop',
          borderColor: const Color(0xFF331111),
          iconColor: AppColors.error,
          onPressed: state.canStop ? _onStop : null,
          size: 42,
        ),

        // Pause/Resume button (large center)
        _buildCircleButton(
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          label: isPaused ? 'Resume' : 'Pause',
          borderColor: AppColors.primary,
          iconColor: AppColors.primary,
          onPressed:
              state.canPause || state.canResume ? _onPauseResume : null,
          size: 52,
        ),

        // Complete button (for For Time) or placeholder
        if (widget.timerType == TimerTypes.forTime)
          _buildCircleButton(
            icon: Icons.flag,
            label: 'Done',
            borderColor: const Color(0xFF222222),
            iconColor: const Color(0xFF888888),
            onPressed: () {
              ref.read(timerNotifierProvider.notifier).stop();
            },
            size: 42,
          )
        else
          const SizedBox(width: 42),
      ],
    );
  }

  // ===================================================================
  // Control Buttons (Landscape / Compact)
  // ===================================================================

  Widget _buildControlsCompact(TimerNotifierState state) {
    final isPaused = state is TimerPaused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleButton(
          icon: Icons.stop,
          label: 'Stop',
          borderColor: const Color(0xFF331111),
          iconColor: AppColors.error,
          onPressed: state.canStop ? _onStop : null,
          size: 42,
        ),
        const SizedBox(width: AppSpacing.lg),
        _buildCircleButton(
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          label: isPaused ? 'Resume' : 'Pause',
          borderColor: AppColors.primary,
          iconColor: AppColors.primary,
          onPressed:
              state.canPause || state.canResume ? _onPauseResume : null,
          size: 52,
        ),
        if (widget.timerType == TimerTypes.forTime) ...[
          const SizedBox(width: AppSpacing.lg),
          _buildCircleButton(
            icon: Icons.flag,
            label: 'Done',
            borderColor: const Color(0xFF222222),
            iconColor: const Color(0xFF888888),
            onPressed: () {
              ref.read(timerNotifierProvider.notifier).stop();
            },
            size: 42,
          ),
        ],
      ],
    );
  }

  // ===================================================================
  // Circle Button (border-only style)
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
      child: Material(
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
                color: isDisabled
                    ? const Color(0xFF222222)
                    : borderColor,
                width: 1.5,
              ),
            ),
            child: ExcludeSemantics(
              child: Icon(
                icon,
                color: isDisabled ? const Color(0xFF444444) : iconColor,
                size: size * 0.45,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // Completed State Layout
  // ===================================================================

  Widget _buildCompletedLayout(TimerNotifierState state) {
    final session = state.sessionOrNull;
    final elapsed = session?.elapsed.seconds ?? 0;
    final minutes = elapsed ~/ 60;
    final secs = elapsed % 60;
    final elapsedString =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),

        // Checkmark icon
        const Icon(
          Icons.check,
          size: 40,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.md),

        // "Finished!" title
        Text(
          'Finished!',
          style: AppTypography.workoutTitle.copyWith(
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Stat text
        Text(
          'Total: $elapsedString',
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 13,
            color: const Color(0xFF444444),
          ),
        ),

        if (session?.totalRounds != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Rounds: ${session!.currentRound}/${session.totalRounds}',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13,
              color: const Color(0xFF444444),
            ),
          ),
        ],

        const Spacer(flex: 2),

        // Progress bar (full)
        _buildProgressBar(state),
        const SizedBox(height: AppSpacing.xl),

        // Again / Done buttons
        _buildCompletedButtons(),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildCompletedLayoutLandscape(TimerNotifierState state) {
    final session = state.sessionOrNull;
    final elapsed = session?.elapsed.seconds ?? 0;
    final minutes = elapsed ~/ 60;
    final secs = elapsed % 60;
    final elapsedString =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check,
                size: 40,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Finished!',
                style: AppTypography.workoutTitle.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Total: $elapsedString',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF444444),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCompletedButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Row(
        children: [
          // Again button (bordered)
          Expanded(
            child: Semantics(
              button: true,
              label: 'Again button',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onReset,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Again',
                      style: AppTypography.buttonMedium.copyWith(
                        color: const Color(0xFF666666),
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
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Done',
                      style: AppTypography.buttonMedium.copyWith(
                        color: Colors.black,
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
