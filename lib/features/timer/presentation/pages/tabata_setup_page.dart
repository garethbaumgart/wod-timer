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

/// Setup page for Tabata timer.
///
/// Tabata is a high-intensity interval training (HIIT) protocol with
/// work/rest intervals, typically 20s work / 10s rest x 8 rounds.
class TabataSetupPage extends ConsumerStatefulWidget {
  const TabataSetupPage({super.key});

  @override
  ConsumerState<TabataSetupPage> createState() => _TabataSetupPageState();
}

class _TabataSetupPageState extends ConsumerState<TabataSetupPage> {
  // Classic Tabata defaults
  Duration _workDuration = const Duration(seconds: 20);
  Duration _restDuration = const Duration(seconds: 10);
  int _rounds = 8;
  bool _prepEnabled = true;
  int _prepSeconds = 10;

  Duration get _totalWorkoutDuration {
    final workSeconds = _workDuration.inSeconds * _rounds;
    final restSeconds = _restDuration.inSeconds * _rounds;
    return Duration(seconds: workSeconds + restSeconds);
  }

  Duration get _totalDuration => _prepEnabled
      ? _totalWorkoutDuration + Duration(seconds: _prepSeconds)
      : _totalWorkoutDuration;

  void _applyClassicTabata() {
    setState(() {
      _workDuration = const Duration(seconds: 20);
      _restDuration = const Duration(seconds: 10);
      _rounds = 8;
    });
  }

  Future<void> _onStart() async {
    final timerType = TabataTimer(
      workDuration: TimerDuration.fromSeconds(_workDuration.inSeconds),
      restDuration: TimerDuration.fromSeconds(_restDuration.inSeconds),
      rounds: RoundCount.fromInt(_rounds),
    );

    final createWorkout = ref.read(createWorkoutProvider);
    final workoutResult = createWorkout(
      name: 'Tabata Workout',
      timerType: timerType,
      prepCountdownSeconds: _prepEnabled ? _prepSeconds : 0,
    );

    await workoutResult.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${failure.toString()}')),
        );
      },
      (workout) async {
        await ref.read(timerNotifierProvider.notifier).start(workout);
        if (mounted) {
          context.go(AppRoutes.timerActivePath(TimerTypes.tabata));
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
        title: const Text('Tabata'),
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
                const SizedBox(height: AppSpacing.md),

                // Classic Tabata preset button
                _buildClassicTabataButton(),
                const SizedBox(height: AppSpacing.xl),

                // Work/Rest duration pickers side by side
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactDurationPicker(
                        label: 'Work',
                        duration: _workDuration,
                        color: AppColors.work,
                        onChanged: (d) => setState(() => _workDuration = d),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildCompactDurationPicker(
                        label: 'Rest',
                        duration: _restDuration,
                        color: AppColors.rest,
                        onChanged: (d) => setState(() => _restDuration = d),
                      ),
                    ),
                  ],
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
                  maxRounds: 20,
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
                  timerType: 'Tabata',
                  totalDuration: _totalDuration,
                  rounds: _rounds,
                  workDuration: _workDuration,
                  restDuration: _restDuration,
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
                const SizedBox(height: AppSpacing.sm),
                _buildClassicTabataButton(),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactDurationPicker(
                        label: 'Work',
                        duration: _workDuration,
                        color: AppColors.work,
                        onChanged: (d) => setState(() => _workDuration = d),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildCompactDurationPicker(
                        label: 'Rest',
                        duration: _restDuration,
                        color: AppColors.rest,
                        onChanged: (d) => setState(() => _restDuration = d),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                RoundPicker(
                  initialRounds: _rounds,
                  onChanged: (rounds) {
                    setState(() {
                      _rounds = rounds;
                    });
                  },
                  label: 'Rounds',
                  minRounds: 1,
                  maxRounds: 20,
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
                  timerType: 'Tabata',
                  totalDuration: _totalDuration,
                  rounds: _rounds,
                  workDuration: _workDuration,
                  restDuration: _restDuration,
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
      'High-intensity intervals alternating between work and rest periods.',
      style: theme.textTheme.bodyLarge?.copyWith(
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildClassicTabataButton() {
    return OutlinedButton.icon(
      onPressed: _applyClassicTabata,
      icon: const Icon(Icons.flash_on),
      label: const Text('Classic Tabata (20/10 x 8)'),
    );
  }

  Widget _buildCompactDurationPicker({
    required String label,
    required Duration duration,
    required Color color,
    required ValueChanged<Duration> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${duration.inSeconds}s',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSmallButton(
                icon: Icons.remove,
                onPressed: duration.inSeconds > 5
                    ? () => onChanged(duration - const Duration(seconds: 5))
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              _buildSmallButton(
                icon: Icons.add,
                onPressed: duration.inSeconds < 120
                    ? () => onChanged(duration + const Duration(seconds: 5))
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onPressed != null
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            color: onPressed != null
                ? AppColors.primary
                : (isDark
                    ? AppColors.textDisabledDark
                    : AppColors.textDisabledLight),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    final isValid = _workDuration.inSeconds > 0 && _rounds > 0;
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
    final isValid = _workDuration.inSeconds > 0 && _rounds > 0;
    return ElevatedButton.icon(
      onPressed: isValid ? _onStart : null,
      icon: const Icon(Icons.play_arrow),
      label: const Text('START'),
    );
  }
}
