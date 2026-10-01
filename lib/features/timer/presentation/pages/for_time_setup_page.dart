import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/widgets/widgets.dart';

/// Setup page for For Time workouts.
///
/// For Time workouts involve completing a set of exercises as fast as possible,
/// with an optional time cap.
class ForTimeSetupPage extends ConsumerStatefulWidget {
  const ForTimeSetupPage({super.key});

  @override
  ConsumerState<ForTimeSetupPage> createState() => _ForTimeSetupPageState();
}

class _ForTimeSetupPageState extends ConsumerState<ForTimeSetupPage> {
  late ForTimeSetup _setup = ref.read(setupMemoryProvider).forTime;

  static const _cap = SetupRanges.forTimeCap;

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

  @override
  Widget build(BuildContext context) {
    final cap = _setup.capSeconds;
    return SetupScaffold(
      title: 'FOR TIME',
      onStart: _onStart,
      controls: [
        SetupStepper(
          label: 'Time cap',
          value: setupClock(cap),
          semanticValue: setupSpokenDuration(cap),
          decrementLabel: 'Decrease time cap',
          incrementLabel: 'Increase time cap',
          onDecrement: _cap.canDecrement(cap)
              ? () => setState(
                  () =>
                      _setup = _setup.copyWith(capSeconds: _cap.decrement(cap)),
                )
              : null,
          onIncrement: _cap.canIncrement(cap)
              ? () => setState(
                  () =>
                      _setup = _setup.copyWith(capSeconds: _cap.increment(cap)),
                )
              : null,
        ),
        _buildCountDirectionSwitch(),
      ],
    );
  }

  /// One two-way switch, so count direction reads as a single choice.
  Widget _buildCountDirectionSwitch() {
    return Container(
      width: 310,
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          _buildSegment(label: 'COUNT UP', countUp: true),
          _buildSegment(label: 'COUNT DOWN', countUp: false),
        ],
      ),
    );
  }

  Widget _buildSegment({required String label, required bool countUp}) {
    final isSelected = _setup.countUp == countUp;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () =>
              setState(() => _setup = _setup.copyWith(countUp: countUp)),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.13)
                  : Colors.transparent,
            ),
            child: Center(
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 15,
                  letterSpacing: 1.2,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondaryDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
