import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/widgets/widgets.dart';

/// Setup page for EMOM (Every Minute On the Minute) timer.
///
/// Reads the way athletes say it: every 1:00, 10 rounds.
class EmomSetupPage extends ConsumerStatefulWidget {
  const EmomSetupPage({super.key});

  @override
  ConsumerState<EmomSetupPage> createState() => _EmomSetupPageState();
}

class _EmomSetupPageState extends ConsumerState<EmomSetupPage> {
  late EmomSetup _setup = ref.read(setupMemoryProvider).emom;

  static const _interval = SetupRanges.emomInterval;
  static const _rounds = SetupRanges.emomRounds;

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

  @override
  Widget build(BuildContext context) {
    final interval = _setup.intervalSeconds;
    final rounds = _setup.rounds;
    return SetupScaffold(
      title: 'EMOM',
      totalSeconds: _setup.totalSeconds,
      onStart: _onStart,
      controls: [
        SetupStepper(
          label: 'Every',
          value: setupClock(interval),
          semanticValue: setupSpokenDuration(interval),
          decrementLabel: 'Decrease interval',
          incrementLabel: 'Increase interval',
          onDecrement: _interval.canDecrement(interval)
              ? () => setState(
                  () => _setup = _setup.copyWith(
                    intervalSeconds: _interval.decrement(interval),
                  ),
                )
              : null,
          onIncrement: _interval.canIncrement(interval)
              ? () => setState(
                  () => _setup = _setup.copyWith(
                    intervalSeconds: _interval.increment(interval),
                  ),
                )
              : null,
        ),
        SetupStepper(
          label: 'Rounds',
          value: '$rounds',
          semanticValue: '$rounds',
          decrementLabel: 'Decrease rounds',
          incrementLabel: 'Increase rounds',
          onDecrement: _rounds.canDecrement(rounds)
              ? () => setState(
                  () => _setup = _setup.copyWith(
                    rounds: _rounds.decrement(rounds),
                  ),
                )
              : null,
          onIncrement: _rounds.canIncrement(rounds)
              ? () => setState(
                  () => _setup = _setup.copyWith(
                    rounds: _rounds.increment(rounds),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
