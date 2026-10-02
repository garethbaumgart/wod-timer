import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';
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
  late TabataSetup _setup = ref.read(setupMemoryProvider).tabata;

  static const _work = SetupRanges.tabataWork;
  static const _rest = SetupRanges.tabataRest;
  static const _rounds = SetupRanges.tabataRounds;

  Future<void> _onStart() async {
    await ref.read(setupMemoryProvider).saveTabata(_setup);
    if (!mounted) return;
    await startSetupWorkout(
      context: context,
      ref: ref,
      name: 'Tabata Workout',
      timerType: TabataTimer(
        workDuration: TimerDuration.fromSeconds(_setup.workSeconds),
        restDuration: TimerDuration.fromSeconds(_setup.restSeconds),
        rounds: RoundCount.fromInt(_setup.rounds),
      ),
      route: TimerTypes.tabata,
    );
  }

  void _update(TabataSetup next) => setState(() => _setup = next);

  @override
  Widget build(BuildContext context) {
    final work = _setup.workSeconds;
    final rest = _setup.restSeconds;
    final rounds = _setup.rounds;
    return SetupScaffold(
      title: 'TABATA',
      totalSeconds: _setup.totalSeconds,
      spacing: 30,
      onStart: _onStart,
      accessory: _buildClassicChip(),
      controls: [
        SetupStepper(
          label: 'Work',
          labelColor: AppColors.work,
          value: setupPhase(work),
          semanticValue: setupSpokenDuration(work),
          decrementLabel: 'Decrease work',
          incrementLabel: 'Increase work',
          onDecrement: _work.canDecrement(work)
              ? () =>
                    _update(_setup.copyWith(workSeconds: _work.decrement(work)))
              : null,
          onIncrement: _work.canIncrement(work)
              ? () =>
                    _update(_setup.copyWith(workSeconds: _work.increment(work)))
              : null,
        ),
        SetupStepper(
          label: 'Rest',
          labelColor: AppColors.rest,
          value: setupPhase(rest),
          semanticValue: setupSpokenDuration(rest),
          decrementLabel: 'Decrease rest',
          incrementLabel: 'Increase rest',
          onDecrement: _rest.canDecrement(rest)
              ? () =>
                    _update(_setup.copyWith(restSeconds: _rest.decrement(rest)))
              : null,
          onIncrement: _rest.canIncrement(rest)
              ? () =>
                    _update(_setup.copyWith(restSeconds: _rest.increment(rest)))
              : null,
        ),
        SetupStepper(
          label: 'Rounds',
          value: '$rounds',
          semanticValue: '$rounds',
          decrementLabel: 'Decrease rounds',
          incrementLabel: 'Increase rounds',
          onDecrement: _rounds.canDecrement(rounds)
              ? () =>
                    _update(_setup.copyWith(rounds: _rounds.decrement(rounds)))
              : null,
          onIncrement: _rounds.canIncrement(rounds)
              ? () =>
                    _update(_setup.copyWith(rounds: _rounds.increment(rounds)))
              : null,
        ),
      ],
    );
  }

  /// Nothing while the values are classic 20/10 x 8 (the steppers already
  /// say so), and an offer to reset the moment they drift. The 48pt slot is
  /// kept either way so the steppers never jump.
  Widget _buildClassicChip() {
    if (_setup.isClassic) return const SizedBox(height: 48);
    return Semantics(
      button: true,
      label:
          'Reset to classic Tabata: 20 seconds work, 10 seconds rest, '
          '8 rounds',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _update(TabataSetup.classic),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Container(
              height: 38,
              padding: const EdgeInsets.only(left: 12, right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: AppColors.borderLight, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh,
                    size: 18,
                    color: AppColors.textSecondaryDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RESET TO CLASSIC',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 15,
                      letterSpacing: 1,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
