import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/widgets/widgets.dart';

/// Setup page for AMRAP (As Many Rounds As Possible) timer.
class AmrapSetupPage extends ConsumerStatefulWidget {
  const AmrapSetupPage({super.key});

  @override
  ConsumerState<AmrapSetupPage> createState() => _AmrapSetupPageState();
}

class _AmrapSetupPageState extends ConsumerState<AmrapSetupPage> {
  // Default 10 minutes
  Duration _duration = const Duration(minutes: 10);
  bool _prepEnabled = true;
  int _prepSeconds = 10;

  Duration get _totalDuration => _prepEnabled
      ? _duration + Duration(seconds: _prepSeconds)
      : _duration;

  Future<void> _onStart() async {
    // Create the timer type
    final timerType = AmrapTimer(
      duration: TimerDuration.fromSeconds(_duration.inSeconds),
    );

    // Create the workout
    final createWorkout = ref.read(createWorkoutProvider);
    final workoutResult = createWorkout(
      name: 'AMRAP Workout',
      timerType: timerType,
      prepCountdownSeconds: _prepEnabled ? _prepSeconds : 0,
    );

    // Start the timer
    await workoutResult.fold<Future<void>>(
      (failure) async {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${failure.toString()}')),
        );
      },
      (workout) async {
        await ref.read(timerNotifierProvider.notifier).start(workout);
        if (!mounted) return;
        context.go(AppRoutes.timerActivePath(TimerTypes.amrap));
      },
    );
  }

  void _onSavePreset() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Save preset coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AMRAP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: _onSavePreset,
            tooltip: 'Save as Preset',
          ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return _buildLandscapeLayout(isDark);
            }
            return _buildPortraitLayout(isDark);
          },
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Description
                _buildDescription(),
                const SizedBox(height: AppSpacing.xl),

                // Duration picker
                DurationPicker(
                  initialDuration: _duration,
                  onChanged: (duration) {
                    setState(() {
                      _duration = duration;
                    });
                  },
                  label: 'Workout Duration',
                ),
                const SizedBox(height: AppSpacing.xl),

                // Prep countdown toggle
                PrepCountdownToggle(
                  enabled: _prepEnabled,
                  duration: _prepSeconds,
                  onEnabledChanged: (enabled) {
                    setState(() {
                      _prepEnabled = enabled;
                    });
                  },
                  onDurationChanged: (seconds) {
                    setState(() {
                      _prepSeconds = seconds;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Summary card
                WorkoutSummaryCard(
                  timerType: 'AMRAP',
                  totalDuration: _totalDuration,
                  prepCountdown:
                      _prepEnabled ? Duration(seconds: _prepSeconds) : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Audio test button
                const Center(child: AudioTestButton()),
              ],
            ),
          ),
        ),
        // Start button
        _buildStartButton(),
      ],
    );
  }

  Widget _buildLandscapeLayout(bool isDark) {
    return Row(
      children: [
        // Left side - Configuration
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDescription(),
                const SizedBox(height: AppSpacing.lg),
                DurationPicker(
                  initialDuration: _duration,
                  onChanged: (duration) {
                    setState(() {
                      _duration = duration;
                    });
                  },
                  label: 'Workout Duration',
                ),
              ],
            ),
          ),
        ),
        // Right side - Settings and summary
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrepCountdownToggle(
                  enabled: _prepEnabled,
                  duration: _prepSeconds,
                  onEnabledChanged: (enabled) {
                    setState(() {
                      _prepEnabled = enabled;
                    });
                  },
                  onDurationChanged: (seconds) {
                    setState(() {
                      _prepSeconds = seconds;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                WorkoutSummaryCard(
                  timerType: 'AMRAP',
                  totalDuration: _totalDuration,
                  prepCountdown:
                      _prepEnabled ? Duration(seconds: _prepSeconds) : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Center(child: AudioTestButton()),
                const SizedBox(height: AppSpacing.lg),
                _buildStartButtonCompact(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Text(
      'Complete as many rounds as possible within the time limit.',
      style: theme.textTheme.bodyLarge?.copyWith(
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: ElevatedButton.icon(
        onPressed: _duration.inSeconds > 0 ? _onStart : null,
        icon: const Icon(Icons.play_arrow),
        label: const Text('START WORKOUT'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, AppSpacing.largeButtonHeight),
        ),
      ),
    );
  }

  Widget _buildStartButtonCompact() {
    return ElevatedButton.icon(
      onPressed: _duration.inSeconds > 0 ? _onStart : null,
      icon: const Icon(Icons.play_arrow),
      label: const Text('START'),
    );
  }
}
