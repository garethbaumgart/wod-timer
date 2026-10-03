import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/widgets/widgets.dart';

/// Setup page for AMRAP (As Many Rounds As Possible) timer.
///
/// One decision (how long), in whole minutes on the bezel, then START.
class AmrapSetupPage extends ConsumerStatefulWidget {
  const AmrapSetupPage({super.key});

  @override
  ConsumerState<AmrapSetupPage> createState() => _AmrapSetupPageState();
}

class _AmrapSetupPageState extends ConsumerState<AmrapSetupPage> {
  late AmrapSetup _setup = ref.read(setupMemoryProvider).amrap;

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
    return SetupScaffold(
      title: 'AMRAP',
      onStart: _onStart,
      body: (context, {required landscape}) => BezelSetupBody(
        landscape: landscape,
        bezel: (size) => setupBezel(
          ref: ref,
          minutes: _setup.durationSeconds ~/ 60,
          label: 'Duration',
          accent: AppColors.amrapAccent,
          size: size,
          onChanged: (minutes) => setState(
            () => _setup = _setup.copyWith(durationSeconds: minutes * 60),
          ),
        ),
        below: const BezelHint('Turn the bezel · one turn is 60 minutes'),
      ),
    );
  }
}
