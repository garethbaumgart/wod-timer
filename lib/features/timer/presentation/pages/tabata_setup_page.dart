import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/presentation/widgets/voice_picker_sheet.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/repeating_icon_button.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${failure.toString()}')));
      },
      (workout) async {
        await ref.read(timerNotifierProvider.notifier).start(workout);
        if (!mounted) return;
        context.go(AppRoutes.timerActivePath(TimerTypes.tabata));
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
            'Tabata',
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
                  workoutDuration: _totalWorkoutDuration,
                  rounds: _rounds,
                  workDuration: _workDuration,
                  restDuration: _restDuration,
                  voiceLabel: voiceShortLabel(
                    ref.watch(appSettingsNotifierProvider).voice,
                  ),
                  onVoiceTap: () => showVoicePickerSheet(context, ref),
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
                  workoutDuration: _totalWorkoutDuration,
                  rounds: _rounds,
                  workDuration: _workDuration,
                  restDuration: _restDuration,
                  voiceLabel: voiceShortLabel(
                    ref.watch(appSettingsNotifierProvider).voice,
                  ),
                  onVoiceTap: () => showVoicePickerSheet(context, ref),
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

  /// Whether the current values match the classic 20/10 x 8 protocol.
  bool get _isClassic =>
      _workDuration == const Duration(seconds: 20) &&
      _restDuration == const Duration(seconds: 10) &&
      _rounds == 8;

  /// A real toggle chip: lit while the values match classic Tabata,
  /// visibly deselected the moment they diverge; tapping re-applies.
  Widget _buildClassicTabataButton() {
    final isActive = _isClassic;
    final accent = isActive ? AppColors.primary : AppColors.textHintDark;
    return Center(
      child: Semantics(
        button: true,
        selected: isActive,
        label: isActive
            ? 'Classic Tabata applied: 20 seconds work, 10 seconds rest, '
                  '8 rounds'
            : 'Apply classic Tabata: 20 seconds work, 10 seconds rest, '
                  '8 rounds',
        child: GestureDetector(
          onTap: _applyClassicTabata,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border,
              ),
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? Icons.flash_on : Icons.flash_off,
                  size: 16,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'CLASSIC TABATA' : 'RESET TO CLASSIC',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '20s work / 10s rest \u00D7 8 rounds',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHintDark,
                      ),
                    ),
                  ],
                ),
                if (isActive) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.check, size: 16, color: AppColors.primary),
                ],
              ],
            ),
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
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: color,
                letterSpacing: 1.5,
                fontSize: 12,
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
            RepeatingIconButton(
              icon: Icons.remove,
              onPressed: duration.inSeconds > 5
                  ? () => onChanged(duration - const Duration(seconds: 5))
                  : null,
              semanticsLabel: 'Decrease by 5 seconds',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '5s',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: AppColors.textHintDark,
                ),
              ),
            ),
            RepeatingIconButton(
              icon: Icons.add,
              onPressed: duration.inSeconds < 120
                  ? () => onChanged(duration + const Duration(seconds: 5))
                  : null,
              semanticsLabel: 'Increase by 5 seconds',
            ),
          ],
        ),
      ],
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
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isValid
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isValid
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
