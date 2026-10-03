import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/widgets/widgets.dart';

/// Setup page for EMOM (Every Minute On the Minute) timer.
///
/// Reads the way athletes say it: every 1:00, 10 rounds, on two wheels
/// side by side with the timeline under them.
class EmomSetupPage extends ConsumerStatefulWidget {
  const EmomSetupPage({super.key});

  @override
  ConsumerState<EmomSetupPage> createState() => _EmomSetupPageState();
}

class _EmomSetupPageState extends ConsumerState<EmomSetupPage> {
  late EmomSetup _setup = ref.read(setupMemoryProvider).emom;

  Future<void> _onStart() async {
    await ref.read(setupMemoryProvider).saveEmom(_setup);
    if (!mounted) return;
    await startSetupWorkout(
      context: context,
      ref: ref,
      name: 'EMOM Workout',
      timerType: EmomTimer(
        intervalDuration: TimerDuration.fromSeconds(_setup.intervalSeconds),
        rounds: RoundCount.fromInt(_setup.rounds),
      ),
      route: TimerTypes.emom,
    );
  }

  void _update(EmomSetup next) {
    ref.read(hapticServiceProvider).selectionClick();
    setState(() => _setup = next);
  }

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      title: 'EMOM',
      onStart: _onStart,
      startSubtitle: '${setupClock(_setup.totalSeconds)} total',
      body: (context, {required landscape}) => WheelsSetupBody(
        landscape: landscape,
        shape: WorkoutShape.ofSetup(_setup),
        wheels: (rowHeight) => [
          SetupWheel(
            label: 'Every',
            labelColor: AppColors.work,
            range: SetupRanges.emomInterval,
            value: _setup.intervalSeconds,
            format: setupClock,
            spoken: setupSpokenDuration,
            rowHeight: rowHeight,
            onChanged: (v) => _update(_setup.copyWith(intervalSeconds: v)),
          ),
          SetupWheel(
            label: 'Rounds',
            labelColor: AppColors.secondary,
            range: SetupRanges.emomRounds,
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
}
