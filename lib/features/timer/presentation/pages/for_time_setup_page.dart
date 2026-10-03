import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/widgets/widgets.dart';

/// Setup page for For Time workouts: the cap on the bezel, the count
/// direction as a two-option switch under it, both read back in START.
class ForTimeSetupPage extends ConsumerStatefulWidget {
  const ForTimeSetupPage({super.key});

  @override
  ConsumerState<ForTimeSetupPage> createState() => _ForTimeSetupPageState();
}

class _ForTimeSetupPageState extends ConsumerState<ForTimeSetupPage> {
  late ForTimeSetup _setup = ref.read(setupMemoryProvider).forTime;

  Future<void> _onStart() async {
    await ref.read(setupMemoryProvider).saveForTime(_setup);
    if (!mounted) return;
    await startSetupWorkout(
      context: context,
      ref: ref,
      name: 'For Time Workout',
      timerType: ForTimeTimer(
        timeCap: TimerDuration.fromSeconds(_setup.capSeconds),
        countUp: _setup.countUp,
      ),
      route: TimerTypes.forTime,
    );
  }

  /// "Counts up · cap 20:00", read under START.
  static String subtitleFor(ForTimeSetup setup) =>
      '${setup.countUp ? 'Counts up' : 'Counts down'} · '
      'cap ${setupClock(setup.capSeconds)}';

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      title: 'FOR TIME',
      onStart: _onStart,
      startSubtitle: subtitleFor(_setup),
      body: (context, {required landscape}) => BezelSetupBody(
        landscape: landscape,
        bezel: (size) => setupBezel(
          ref: ref,
          minutes: _setup.capSeconds ~/ 60,
          label: 'Time cap',
          accent: AppColors.forTimeAccent,
          size: size,
          onChanged: (minutes) => setState(
            () => _setup = _setup.copyWith(capSeconds: minutes * 60),
          ),
        ),
        below: CountDirectionSwitch(
          countUp: _setup.countUp,
          onChanged: (up) {
            ref.read(hapticServiceProvider).selectionClick();
            setState(() => _setup = _setup.copyWith(countUp: up));
          },
        ),
      ),
    );
  }
}
