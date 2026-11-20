import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/pages/block_edit_page.dart';
import 'package:wod_timer/features/session/presentation/session_entry.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/widgets/widgets.dart';

/// Setup page for For Time workouts: the cap on the bezel, the count
/// direction as a two-option switch under it, both read back in START.
class ForTimeSetupPage extends ConsumerStatefulWidget {
  const ForTimeSetupPage({super.key, this.edit});

  /// Opened from Today's WOD's builder (2.6.0): that block's values, DONE
  /// in place of START, REMOVE BLOCK in place of "+ THEN".
  final BlockEdit? edit;

  @override
  ConsumerState<ForTimeSetupPage> createState() => _ForTimeSetupPageState();
}

class _ForTimeSetupPageState extends ConsumerState<ForTimeSetupPage> {
  late ForTimeSetup _setup = switch (widget.edit?.block) {
    ForTimeBlock(:final capSeconds, :final countUp) => ForTimeSetup(
      capSeconds: capSeconds,
      countUp: countUp,
    ),
    _ => ref.read(setupMemoryProvider).forTime,
  };

  /// The values on screen as a Today's WOD block.
  ForTimeBlock get _block =>
      ForTimeBlock(capSeconds: _setup.capSeconds, countUp: _setup.countUp);

  Future<void> _onStart() async {
    if (widget.edit case final edit?) {
      edit.onDone(_block);
      return;
    }
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
      startLabel: widget.edit == null ? 'START' : BlockEdit.doneLabel,
      onBack: widget.edit?.onCancel,
      capsule:
          widget.edit?.removeCapsule ??
          thenCapsule(context: context, ref: ref, first: () => _block),
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
