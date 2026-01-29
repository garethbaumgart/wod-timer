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
  Duration get _totalDuration => _timeCap + const Duration(seconds: 10);

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
        context.go(AppRoutes.timerActivePath(TimerTypes.forTime));
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
                  child: Text(
                    '\u2039',
                    style: TextStyle(
                      fontSize: 32,
                      color: AppColors.textPrimaryDark,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'For Time',
            style: AppTypography.sectionHeader.copyWith(
              color: AppColors.textPrimaryDark,
            ),
          ),
          const Spacer(),
          Semantics(
            button: true,
            label: 'Save preset',
            child: GestureDetector(
              onTap: _onSavePreset,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Icon(
                    Icons.bookmark_border,
                    color: AppColors.textSecondaryDark,
                    size: 22,
                  ),
                ),
              ),
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
                const SizedBox(height: 28),

                // Count direction segmented control
                _buildCountDirectionToggle(),
                const SizedBox(height: 24),

                // Summary card
                WorkoutSummaryCard(
                  timerType: 'For Time',
                  totalDuration: _totalDuration,
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
                      const SizedBox(height: 16),
                      _buildCountDirectionToggle(),
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
                  timerType: 'For Time',
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

  Widget _buildCountDirectionToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSegmentButton(
          label: 'COUNT UP',
          isSelected: _countUp,
          onTap: () => setState(() => _countUp = true),
        ),
        const SizedBox(width: 8),
        _buildSegmentButton(
          label: 'COUNT DOWN',
          isSelected: !_countUp,
          onTap: () => setState(() => _countUp = false),
        ),
      ],
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : const Color(0xFF666666),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildStartButton() {
    final isEnabled = _timeCap.inSeconds > 0;
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _timeCap.inSeconds > 0
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
      ),
    );
  }

  Widget _buildStartButtonCompact() {
    return GestureDetector(
      onTap: _timeCap.inSeconds > 0 ? _onStart : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _timeCap.inSeconds > 0
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
