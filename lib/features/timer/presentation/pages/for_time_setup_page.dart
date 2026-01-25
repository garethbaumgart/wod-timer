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

/// Setup page for For Time timer.
///
/// For Time workouts involve completing a set of exercises as fast as possible,
/// with an optional time cap.
class ForTimeSetupPage extends ConsumerStatefulWidget {
  const ForTimeSetupPage({super.key});

  @override
  ConsumerState<ForTimeSetupPage> createState() => _ForTimeSetupPageState();
}

class _ForTimeSetupPageState extends ConsumerState<ForTimeSetupPage> {
  // Default 20 minute time cap
  Duration _timeCap = const Duration(minutes: 20);
  // Count up (stopwatch style) vs count down - will be passed to timer in future sprint
  bool _countUp = true;
  bool _prepEnabled = true;
  int _prepSeconds = 10;

  Duration get _totalDuration => _prepEnabled
      ? _timeCap + Duration(seconds: _prepSeconds)
      : _timeCap;

  Future<void> _onStart() async {
    // Create the timer type
    final timerType = ForTimeTimer(
      timeCap: TimerDuration.fromSeconds(_timeCap.inSeconds),
    );

    // Create the workout
    final createWorkout = ref.read(createWorkoutProvider);
    final workoutResult = createWorkout(
      name: 'For Time Workout',
      timerType: timerType,
      prepCountdownSeconds: _prepEnabled ? _prepSeconds : 0,
    );

    // Start the timer
    await workoutResult.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${failure.toString()}')),
        );
      },
      (workout) async {
        await ref.read(timerNotifierProvider.notifier).start(workout);
        if (mounted) {
          context.go(AppRoutes.timerActivePath(TimerTypes.forTime));
        }
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
        title: const Text('For Time'),
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
                _buildDescription(),
                const SizedBox(height: AppSpacing.xl),

                // Time cap picker
                DurationPicker(
                  initialDuration: _timeCap,
                  onChanged: (duration) {
                    setState(() {
                      _timeCap = duration;
                    });
                  },
                  label: 'Time Cap',
                  maxMinutes: 60,
                  minuteInterval: 1,
                  secondInterval: 30,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Count direction toggle
                _buildCountDirectionToggle(),
                const SizedBox(height: AppSpacing.lg),

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
                  timerType: 'For Time',
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
        _buildStartButton(),
      ],
    );
  }

  Widget _buildLandscapeLayout(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDescription(),
                const SizedBox(height: AppSpacing.lg),
                DurationPicker(
                  initialDuration: _timeCap,
                  onChanged: (duration) {
                    setState(() {
                      _timeCap = duration;
                    });
                  },
                  label: 'Time Cap',
                  maxMinutes: 60,
                  minuteInterval: 1,
                  secondInterval: 30,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCountDirectionToggle(),
                const SizedBox(height: AppSpacing.lg),
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
                  timerType: 'For Time',
                  totalDuration: _totalDuration,
                  prepCountdown:
                      _prepEnabled ? Duration(seconds: _prepSeconds) : null,
                ),
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
      'Complete the workout as fast as possible. Press finish when done, or the timer stops at the time cap.',
      style: theme.textTheme.bodyLarge?.copyWith(
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCountDirectionToggle() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timer Display',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Count Up'),
                icon: Icon(Icons.arrow_upward),
              ),
              ButtonSegment(
                value: false,
                label: Text('Count Down'),
                icon: Icon(Icons.arrow_downward),
              ),
            ],
            selected: {_countUp},
            onSelectionChanged: (selection) {
              setState(() {
                _countUp = selection.first;
              });
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return Colors.transparent;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: ElevatedButton.icon(
        onPressed: _timeCap.inSeconds > 0 ? _onStart : null,
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
      onPressed: _timeCap.inSeconds > 0 ? _onStart : null,
      icon: const Icon(Icons.play_arrow),
      label: const Text('START'),
    );
  }
}
