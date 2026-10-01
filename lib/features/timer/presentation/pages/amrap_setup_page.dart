import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/widgets/widgets.dart';

/// Setup page for AMRAP (As Many Rounds As Possible) timer.
///
/// One decision (how long), in whole minutes, then START.
class AmrapSetupPage extends ConsumerStatefulWidget {
  const AmrapSetupPage({super.key});

  @override
  ConsumerState<AmrapSetupPage> createState() => _AmrapSetupPageState();
}

class _AmrapSetupPageState extends ConsumerState<AmrapSetupPage> {
  late AmrapSetup _setup = ref.read(setupMemoryProvider).amrap;

  static const _duration = SetupRanges.amrapDuration;

  Future<void> _onStart() async {
    await ref.read(setupMemoryProvider).saveAmrap(_setup);
    if (!mounted) return;
    await startSetupWorkout(
      context: context,
      ref: ref,
      name: 'AMRAP Workout',
      timerType: AmrapTimer(
        duration: TimerDuration.fromSeconds(_setup.durationSeconds),
      ),
      route: TimerTypes.amrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = _setup.durationSeconds;
    return SetupScaffold(
      title: 'AMRAP',
      onStart: _onStart,
      controls: [
        SetupStepper(
          label: 'Duration',
          value: setupClock(duration),
          semanticValue: setupSpokenDuration(duration),
          decrementLabel: 'Decrease duration',
          incrementLabel: 'Increase duration',
          onDecrement: _duration.canDecrement(duration)
              ? () => setState(
                  () => _setup = _setup.copyWith(
                    durationSeconds: _duration.decrement(duration),
                  ),
                )
              : null,
          onIncrement: _duration.canIncrement(duration)
              ? () => setState(
                  () => _setup = _setup.copyWith(
                    durationSeconds: _duration.increment(duration),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
