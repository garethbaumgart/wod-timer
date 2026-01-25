import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_spacing.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/widgets/widgets.dart';

/// Setup page for EMOM (Every Minute On the Minute) timer.
class EmomSetupPage extends ConsumerStatefulWidget {
  const EmomSetupPage({super.key});

  @override
  ConsumerState<EmomSetupPage> createState() => _EmomSetupPageState();
}

class _EmomSetupPageState extends ConsumerState<EmomSetupPage> {
  // Default 1 minute intervals for 10 rounds
  Duration _intervalDuration = const Duration(minutes: 1);
  int _rounds = 10;
  bool _prepEnabled = true;
  int _prepSeconds = 10;

  Duration get _totalWorkoutDuration =>
      Duration(seconds: _intervalDuration.inSeconds * _rounds);

  Duration get _totalDuration => _prepEnabled
      ? _totalWorkoutDuration + Duration(seconds: _prepSeconds)
      : _totalWorkoutDuration;

  Future<void> _onStart() async {
    // Create the timer type
    final timerType = EmomTimer(
      intervalDuration: TimerDuration.fromSeconds(_intervalDuration.inSeconds),
      rounds: RoundCount.fromInt(_rounds),
    );

    // Create the workout
    final createWorkout = ref.read(createWorkoutProvider);
    final workoutResult = createWorkout(
      name: 'EMOM Workout',
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
          context.go(AppRoutes.timerActivePath(TimerTypes.emom));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('EMOM'),
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
            final isDark = Theme.of(context).brightness == Brightness.dark;
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

                // Interval duration picker
                DurationPicker(
                  initialDuration: _intervalDuration,
                  onChanged: (duration) {
                    setState(() {
                      _intervalDuration = duration;
                    });
                  },
                  label: 'Interval Duration',
                  maxMinutes: 10,
                  minuteInterval: 1,
                  secondInterval: 15,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Rounds picker
                RoundPicker(
                  initialRounds: _rounds,
                  onChanged: (rounds) {
                    setState(() {
                      _rounds = rounds;
                    });
                  },
                  label: 'Number of Rounds',
                  minRounds: 1,
                  maxRounds: 30,
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
                  timerType: 'EMOM',
                  totalDuration: _totalDuration,
                  rounds: _rounds,
                  intervalDuration: _intervalDuration,
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
                  initialDuration: _intervalDuration,
                  onChanged: (duration) {
                    setState(() {
                      _intervalDuration = duration;
                    });
                  },
                  label: 'Interval Duration',
                  maxMinutes: 10,
                  minuteInterval: 1,
                  secondInterval: 15,
                ),
                const SizedBox(height: AppSpacing.lg),
                RoundPicker(
                  initialRounds: _rounds,
                  onChanged: (rounds) {
                    setState(() {
                      _rounds = rounds;
                    });
                  },
                  label: 'Number of Rounds',
                  minRounds: 1,
                  maxRounds: 30,
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
                  timerType: 'EMOM',
                  totalDuration: _totalDuration,
                  rounds: _rounds,
                  intervalDuration: _intervalDuration,
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
      'Start each round on the minute. Any time remaining in the interval is rest.',
      style: theme.textTheme.bodyLarge?.copyWith(
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStartButton() {
    final isValid = _intervalDuration.inSeconds > 0 && _rounds > 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: ElevatedButton.icon(
        onPressed: isValid ? _onStart : null,
        icon: const Icon(Icons.play_arrow),
        label: const Text('START WORKOUT'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, AppSpacing.largeButtonHeight),
        ),
      ),
    );
  }

  Widget _buildStartButtonCompact() {
    final isValid = _intervalDuration.inSeconds > 0 && _rounds > 0;
    return ElevatedButton.icon(
      onPressed: isValid ? _onStart : null,
      icon: const Icon(Icons.play_arrow),
      label: const Text('START'),
    );
  }
}
