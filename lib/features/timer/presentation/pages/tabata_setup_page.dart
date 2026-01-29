import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
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
  Duration get _totalWorkoutDuration {
    final workSeconds = _workDuration.inSeconds * _rounds;
    final restSeconds = _restDuration.inSeconds * _rounds;
    return Duration(seconds: workSeconds + restSeconds);
  }

  Duration get _totalDuration =>
      _totalWorkoutDuration + const Duration(seconds: 10);

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
      prepCountdownSeconds: 10,
    );

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
        context.go(AppRoutes.timerActivePath(TimerTypes.tabata));
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
            'Tabata',
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
                const SizedBox(height: 12),

                // Classic Tabata preset button
                _buildClassicTabataButton(),
                const SizedBox(height: 28),

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
                    const SizedBox(width: 12),
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
                const SizedBox(height: 28),

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
                const SizedBox(height: 28),

                const SizedBox(height: 4),

                // Summary card
                WorkoutSummaryCard(
                  timerType: 'Tabata',
                  totalDuration: _totalDuration,
                  rounds: _rounds,
                  workDuration: _workDuration,
                  restDuration: _restDuration,
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
                      const SizedBox(height: 8),
                      _buildClassicTabataButton(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactDurationPicker(
                              label: 'Work',
                              duration: _workDuration,
                              color: AppColors.work,
                              onChanged: (d) =>
                                  setState(() => _workDuration = d),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCompactDurationPicker(
                              label: 'Rest',
                              duration: _restDuration,
                              color: AppColors.rest,
                              onChanged: (d) =>
                                  setState(() => _restDuration = d),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                  timerType: 'Tabata',
                  totalDuration: _totalDuration,
                  rounds: _rounds,
                  workDuration: _workDuration,
                  restDuration: _restDuration,
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

  Widget _buildClassicTabataButton() {
    return Center(
      child: GestureDetector(
        onTap: _applyClassicTabata,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.flash_on,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'CLASSIC TABATA (20/10 x 8)',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDurationPicker({
    required String label,
    required Duration duration,
    required Color color,
    required ValueChanged<Duration> onChanged,
  }) {
    return Column(
      children: [
        // Label with color dot
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: color,
                letterSpacing: 1.5,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Big seconds display
        Text(
          '${duration.inSeconds}s',
          style: AppTypography.timerDisplaySmall.copyWith(
            color: AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 12),
        // +/- buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSmallButton(
              icon: Icons.remove,
              onPressed: duration.inSeconds > 5
                  ? () => onChanged(duration - const Duration(seconds: 5))
                  : null,
              semanticLabel: 'Decrease by 5 seconds',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '5s',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: const Color(0xFF444444),
                ),
              ),
            ),
            _buildSmallButton(
              icon: Icons.add,
              onPressed: duration.inSeconds < 120
                  ? () => onChanged(duration + const Duration(seconds: 5))
                  : null,
              semanticLabel: 'Increase by 5 seconds',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required VoidCallback? onPressed,
    String? semanticLabel,
  }) {
    final isEnabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: isEnabled
                ? const Color(0xFF666666)
                : AppColors.textDisabledDark,
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildStartButton() {
    final isValid = _workDuration.inSeconds > 0 && _rounds > 0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Semantics(
        button: true,
        enabled: isValid,
        label: 'Start workout',
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
      ),
    );
  }

  Widget _buildStartButtonCompact() {
    final isValid = _workDuration.inSeconds > 0 && _rounds > 0;
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
