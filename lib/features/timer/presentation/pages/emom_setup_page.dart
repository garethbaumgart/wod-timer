import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
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
  Duration get _totalWorkoutDuration =>
      Duration(seconds: _intervalDuration.inSeconds * _rounds);

  Duration get _totalDuration =>
      _totalWorkoutDuration + const Duration(seconds: 10);

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
      prepCountdownSeconds: 10,
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
        context.go(AppRoutes.timerActivePath(TimerTypes.emom));
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
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return _buildLandscapeLayout();
            }
            return _buildPortraitLayout();
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go(AppRoutes.home),
            child: const Text(
              '\u2039',
              style: TextStyle(
                fontSize: 32,
                color: AppColors.textPrimaryDark,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'EMOM',
            style: AppTypography.sectionHeader.copyWith(
              color: AppColors.textPrimaryDark,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _onSavePreset,
            child: const Icon(
              Icons.bookmark_border,
              color: AppColors.textSecondaryDark,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

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
                const SizedBox(height: 32),

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
                const SizedBox(height: 28),

                // Summary card
                WorkoutSummaryCard(
                  timerType: 'EMOM',
                  totalDuration: _totalDuration,
                  rounds: _rounds,
                  intervalDuration: _intervalDuration,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _buildStartButton(),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
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
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WorkoutSummaryCard(
                  timerType: 'EMOM',
                  totalDuration: _totalDuration,
                  rounds: _rounds,
                  intervalDuration: _intervalDuration,
                ),
                const SizedBox(height: 16),
                _buildStartButtonCompact(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    final isValid = _intervalDuration.inSeconds > 0 && _rounds > 0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: isValid ? _onStart : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isValid
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              'START WORKOUT',
              style: AppTypography.buttonLarge.copyWith(
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartButtonCompact() {
    final isValid = _intervalDuration.inSeconds > 0 && _rounds > 0;
    return GestureDetector(
      onTap: isValid ? _onStart : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isValid
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            'START',
            style: AppTypography.buttonLarge.copyWith(
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
