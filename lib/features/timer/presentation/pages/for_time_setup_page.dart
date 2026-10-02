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
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SetupStepper(
              label: 'Time cap',
              value: setupClock(cap),
              semanticValue: setupSpokenDuration(cap),
              decrementLabel: 'Decrease time cap',
              incrementLabel: 'Increase time cap',
              onDecrement: _cap.canDecrement(cap)
                  ? () => setState(
                      () => _setup = _setup.copyWith(
                        capSeconds: _cap.decrement(cap),
                      ),
                    )
                  : null,
              onIncrement: _cap.canIncrement(cap)
                  ? () => setState(
                      () => _setup = _setup.copyWith(
                        capSeconds: _cap.increment(cap),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            _buildCountDirection(),
          ],
        ),
      ],
    );
  }

  /// Count direction as one caption under the cap: the setting reads as a
  /// fact about the clock, not a second control competing with START. The
  /// whole line is a 44pt tap target that flips it; START remembers it.
  Widget _buildCountDirection() {
    final countUp = _setup.countUp;
    final direction = countUp ? 'COUNTS UP' : 'COUNTS DOWN';
    final style = AppTypography.labelSmall.copyWith(
      fontSize: 15,
      letterSpacing: 1.2,
      color: AppColors.textSecondaryDark,
    );
    return Semantics(
      button: true,
      label: countUp
          ? 'Clock counts up. Tap to count down.'
          : 'Clock counts down. Tap to count up.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () =>
            setState(() => _setup = _setup.copyWith(countUp: !countUp)),
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          // At least 44pt; large text may wrap it onto a second line.
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              widthFactor: 1,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: direction,
                      style: style.copyWith(color: AppColors.textPrimaryDark),
                    ),
                    TextSpan(text: ' \u00B7 TAP TO CHANGE', style: style),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
