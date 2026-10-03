import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/widgets/widgets.dart';

/// Setup page for Tabata timer.
///
/// Tabata is a high-intensity interval training (HIIT) protocol with
/// work/rest intervals, typically 20s work / 10s rest x 8 rounds: three
/// wheels side by side, work blocks green and rest blocks pink under them.
class TabataSetupPage extends ConsumerStatefulWidget {
  const TabataSetupPage({super.key});

  @override
  ConsumerState<TabataSetupPage> createState() => _TabataSetupPageState();
}

class _TabataSetupPageState extends ConsumerState<TabataSetupPage> {
  late TabataSetup _setup = ref.read(setupMemoryProvider).tabata;

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

  void _update(TabataSetup next) {
    ref.read(hapticServiceProvider).selectionClick();
    setState(() => _setup = next);
  }

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      title: 'TABATA',
      onStart: _onStart,
      startSubtitle: '${setupClock(_setup.totalSeconds)} total',
      body: (context, {required landscape}) => WheelsSetupBody(
        landscape: landscape,
        shape: WorkoutShape.ofSetup(_setup),
        accessory: _buildClassicChip(),
        wheels: (rowHeight) => [
          SetupWheel(
            label: 'Work',
            labelColor: AppColors.work,
            range: SetupRanges.tabataWork,
            value: _setup.workSeconds,
            format: setupPhase,
            spoken: setupSpokenDuration,
            rowHeight: rowHeight,
            onChanged: (v) => _update(_setup.copyWith(workSeconds: v)),
          ),
          SetupWheel(
            label: 'Rest',
            labelColor: AppColors.rest,
            range: SetupRanges.tabataRest,
            value: _setup.restSeconds,
            format: setupPhase,
            spoken: setupSpokenDuration,
            rowHeight: rowHeight,
            onChanged: (v) => _update(_setup.copyWith(restSeconds: v)),
          ),
          SetupWheel(
            label: 'Rounds',
            labelColor: AppColors.secondary,
            range: SetupRanges.tabataRounds,
            value: _setup.rounds,
            format: (v) => '$v',
            spoken: (v) => '$v',
            rowHeight: rowHeight,
            onChanged: (v) => _update(_setup.copyWith(rounds: v)),
          ),
        ],
      ),
    );
  }

  /// Nothing while the values are classic 20/10 x 8 (the wheels already
  /// say so), and an offer to reset the moment they drift. The 48pt slot is
  /// kept either way so the wheels never jump.
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
