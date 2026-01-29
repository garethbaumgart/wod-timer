import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';

/// Active timer display page.
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
    final timerNotifier = ref.read(timerNotifierProvider.notifier);
    timerNotifier.stop();
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
            title: const Text('Exit Workout?'),
            content: const Text(
              'Your workout is still in progress. Are you sure you want to exit? Your progress will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CONTINUE WORKOUT'),
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
      backgroundColor: _getBackgroundColor(timerState),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
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
                  color: textColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Timer Not Started',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Go back to the setup page to configure and start your workout.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textColor.withValues(alpha: 0.7),
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

  Color _getBackgroundColor(TimerNotifierState state) {
    return state.maybeMap(
      preparing: (_) => AppColors.prepare.withValues(alpha: 0.2),
      running: (_) => AppColors.work.withValues(alpha: 0.15),
      resting: (_) => AppColors.rest.withValues(alpha: 0.2),
      paused: (_) => AppColors.paused.withValues(alpha: 0.2),
      completed: (_) => AppColors.complete.withValues(alpha: 0.2),
      orElse: () => Theme.of(context).scaffoldBackgroundColor,
    );
  }

  Widget _buildPortraitLayout(TimerNotifierState state) {
    return Column(
      children: [
        // Top bar with timer type and back button
        _buildTopBar(state),

        // Main timer display
        Expanded(
          flex: 3,
          child: _buildTimerDisplay(state),
        ),

        // Progress indicator
        _buildProgressBar(state),

        // Round/Phase indicator
        Expanded(
          flex: 1,
          child: _buildStatusIndicator(state),
        ),

        // Control buttons
        _buildControls(state),
      ],
    );
  }

  Widget _buildLandscapeLayout(TimerNotifierState state) {
    return Row(
      children: [
        // Left side - Timer display
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildTopBar(state),
              Expanded(child: _buildTimerDisplay(state)),
              _buildProgressBar(state),
            ],
          ),
        ),

        // Right side - Status and controls
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: _buildStatusIndicator(state)),
              _buildControlsCompact(state),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(TimerNotifierState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: textColor),
            onPressed: _onReset,
            tooltip: 'Exit',
          ),
          const Spacer(),
          Text(
            _getTimerTypeLabel(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the close button
        ],
      ),
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

  Widget _buildTimerDisplay(TimerNotifierState state) {
    final session = state.sessionOrNull;
    final timeRemaining = session?.timeRemaining.seconds ?? 0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Phase label (Get Ready, Work, Rest, etc.)
          _buildPhaseLabel(state),
          const SizedBox(height: AppSpacing.sm),

          // Large time display
          _buildTimeText(timeRemaining, state),
        ],
      ),
    );
  }

  Widget _buildPhaseLabel(TimerNotifierState state) {
    final label = state.maybeMap(
      preparing: (_) => 'GET READY',
      running: (_) => 'WORK',
      resting: (_) => 'REST',
      paused: (_) => 'PAUSED',
      completed: (_) => 'COMPLETE!',
      orElse: () => '',
    );

    final color = _getPhaseColor(state);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
      ),
    );
  }

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

  Widget _buildTimeText(int seconds, TimerNotifierState state) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.timerTextDark : AppColors.timerTextLight;

    // Pulse animation for last 3 seconds of prep countdown
    final isPulsing = state is TimerPreparing && seconds <= 3 && seconds > 0;

    // Larger font sizes for gym visibility (readable from 3-4 meters)
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: TextStyle(
        fontSize: isPulsing ? 160 : 140,
        fontWeight: FontWeight.w200,
        fontFamily: 'monospace',
        color: textColor,
        letterSpacing: 4,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          timeString,
          semanticsLabel: '$minutes minutes $secs seconds remaining',
        ),
      ),
    );
  }

  Widget _buildProgressBar(TimerNotifierState state) {
    final session = state.sessionOrNull;
    final progress = session?.progress ?? 0.0;
    final color = _getPhaseColor(state);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(TimerNotifierState state) {
    final session = state.sessionOrNull;
    if (session == null) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Round indicator (if applicable)
        if (session.totalRounds != null)
          _buildRoundIndicator(session),

        // Elapsed time for For Time
        if (widget.timerType == TimerTypes.forTime)
          _buildElapsedTime(session),

        // Phase change preview for Tabata
        if (widget.timerType == TimerTypes.tabata)
          _buildPhasePreview(state, session),
      ],
    );
  }

  Widget _buildPhasePreview(TimerNotifierState state, TimerSession session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

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

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: AnimatedOpacity(
        opacity: timeRemaining <= 3 ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 200),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_forward,
              size: 16,
              color: textColor.withValues(alpha: 0.6),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$nextPhase in ${timeRemaining}s',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: nextColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundIndicator(TimerSession session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Column(
      children: [
        Text(
          'ROUND',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: textColor.withValues(alpha: 0.6),
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
            children: [
              TextSpan(text: '${session.currentRound}'),
              TextSpan(
                text: ' / ${session.totalRounds}',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.5),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildElapsedTime(TimerSession session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    final elapsed = session.elapsed.seconds;
    final minutes = elapsed ~/ 60;
    final secs = elapsed % 60;
    final elapsedString =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Text(
          'ELAPSED',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: textColor.withValues(alpha: 0.6),
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          elapsedString,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildControls(TimerNotifierState state) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: state.maybeMap(
        completed: (_) => _buildCompletedControls(),
        orElse: () => _buildActiveControls(state),
      ),
    );
  }

  Widget _buildActiveControls(TimerNotifierState state) {
    final isPaused = state is TimerPaused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Stop button
        _buildControlButton(
          icon: Icons.stop,
          label: 'Stop',
          color: AppColors.error,
          onPressed: state.canStop ? _onStop : null,
          size: 64,
        ),

        // Pause/Resume button
        _buildControlButton(
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          label: isPaused ? 'Resume' : 'Pause',
          color: isPaused ? AppColors.success : AppColors.warning,
          onPressed:
              state.canPause || state.canResume ? _onPauseResume : null,
          size: 80,
          isPrimary: true,
        ),

        // Complete button (for For Time)
        if (widget.timerType == TimerTypes.forTime)
          _buildControlButton(
            icon: Icons.flag,
            label: 'Done',
            color: AppColors.complete,
            onPressed: () {
              ref.read(timerNotifierProvider.notifier).stop();
            },
            size: 64,
          )
        else
          const SizedBox(width: 64),
      ],
    );
  }

  Widget _buildCompletedControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.replay,
          label: 'Repeat',
          color: AppColors.secondary,
          onPressed: _onReset,
          size: 64,
        ),
        _buildControlButton(
          icon: Icons.check,
          label: 'Done',
          color: AppColors.success,
          onPressed: _onComplete,
          size: 80,
          isPrimary: true,
        ),
        const SizedBox(width: 64),
      ],
    );
  }

  Widget _buildControlsCompact(TimerNotifierState state) {
    return state.maybeMap(
      completed: (_) => _buildCompletedControlsCompact(),
      orElse: () => _buildActiveControlsCompact(state),
    );
  }

  Widget _buildActiveControlsCompact(TimerNotifierState state) {
    final isPaused = state is TimerPaused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Icons.stop,
          label: 'Stop',
          color: AppColors.error,
          onPressed: state.canStop ? _onStop : null,
          size: 48,
        ),
        const SizedBox(width: AppSpacing.lg),
        _buildControlButton(
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          label: isPaused ? 'Resume' : 'Pause',
          color: isPaused ? AppColors.success : AppColors.warning,
          onPressed:
              state.canPause || state.canResume ? _onPauseResume : null,
          size: 56,
          isPrimary: true,
        ),
        if (widget.timerType == TimerTypes.forTime) ...[
          const SizedBox(width: AppSpacing.lg),
          _buildControlButton(
            icon: Icons.flag,
            label: 'Done',
            color: AppColors.complete,
            onPressed: () {
              ref.read(timerNotifierProvider.notifier).stop();
            },
            size: 48,
          ),
        ],
      ],
    );
  }

  Widget _buildCompletedControlsCompact() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Icons.replay,
          label: 'Repeat',
          color: AppColors.secondary,
          onPressed: _onReset,
          size: 48,
        ),
        const SizedBox(width: AppSpacing.lg),
        _buildControlButton(
          icon: Icons.check,
          label: 'Done',
          color: AppColors.success,
          onPressed: _onComplete,
          size: 56,
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    required double size,
    bool isPrimary = false,
  }) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: '$label button${onPressed == null ? ', disabled' : ''}',
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
                  color: onPressed != null
                      ? (isPrimary ? color : color.withValues(alpha: 0.2))
                      : Colors.grey.withValues(alpha: 0.2),
                  border: isPrimary
                      ? null
                      : Border.all(
                          color: onPressed != null ? color : Colors.grey,
                          width: 2,
                        ),
                ),
                child: ExcludeSemantics(
                  child: Icon(
                    icon,
                    color: onPressed != null
                        ? (isPrimary ? Colors.white : color)
                        : Colors.grey,
                    size: size * 0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ExcludeSemantics(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: onPressed != null ? color : Colors.grey,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
