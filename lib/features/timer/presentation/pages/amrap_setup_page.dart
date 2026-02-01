import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
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
  Duration get _totalDuration => _duration + const Duration(seconds: 10);

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
      prepCountdownSeconds: 10,
    );

    // Start the timer
    await workoutResult.fold<Future<void>>(
      (failure) async {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${failure.toString()}')));
      },
      (workout) async {
        await ref.read(timerNotifierProvider.notifier).start(workout);
        if (!mounted) return;
        context.go(AppRoutes.timerActivePath(TimerTypes.amrap));
      },
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
          Semantics(
            button: true,
            label: 'Go back',
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.home),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 22,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'AMRAP',
            style: AppTypography.sectionHeader.copyWith(
              color: AppColors.textPrimaryDark,
              fontSize: 24,
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
                const SizedBox(height: 32),

                // Summary card
                WorkoutSummaryCard(
                  timerType: 'AMRAP',
                  totalDuration: _totalDuration,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // Start button
        _buildStartButton(),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Left side - Configuration
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
            ],
          ),
        ),
        // Right side - Settings and summary
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WorkoutSummaryCard(
                  timerType: 'AMRAP',
                  totalDuration: _totalDuration,
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
    final isEnabled = _duration.inSeconds > 0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Semantics(
        button: true,
        enabled: isEnabled,
        label: 'Start workout',
        child: GestureDetector(
          onTap: isEnabled ? _onStart : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: _duration.inSeconds > 0
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'START WORKOUT',
                style: AppTypography.buttonLarge.copyWith(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartButtonCompact() {
    return GestureDetector(
      onTap: _duration.inSeconds > 0 ? _onStart : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _duration.inSeconds > 0
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'START',
            style: AppTypography.buttonLarge.copyWith(
              color: Colors.black,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
