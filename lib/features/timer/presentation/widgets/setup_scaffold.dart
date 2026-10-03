import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/core/presentation/widgets/centred_timeline.dart';
import 'package:wod_timer/core/presentation/widgets/voice_picker_sheet.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_wheel.dart';
import 'package:wod_timer/features/timer/presentation/widgets/stopwatch_bezel.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';

/// The frame every setup screen shares (1.3.1): header (back, mode in
/// white, voice chip), the mode's controls, then the edge-to-edge START
/// slab carrying the total (EMOM, Tabata) or the count direction (For
/// Time) as its subtitle. One value per control, nothing repeated.
class SetupScaffold extends StatefulWidget {
  const SetupScaffold({
    required this.title,
    required this.body,
    required this.onStart,
    super.key,
    this.startSubtitle,
  });

  /// Mode name in the header ("EMOM").
  final String title;

  /// The mode's controls between the header and START, built for the
  /// orientation.
  final Widget Function(BuildContext context, {required bool landscape}) body;

  final VoidCallback onStart;

  /// Under START: "10:00 total", "Counts up · cap 20:00", or nothing
  /// (AMRAP, whose one value already is the total).
  final String? startSubtitle;

  /// How long START ignores taps after the screen appears. DONE on the
  /// completion screen lands here, so the second tap of a double tap on
  /// DONE would otherwise start a fresh countdown.
  static const startGuard = Duration(milliseconds: 500);

  @override
  State<SetupScaffold> createState() => _SetupScaffoldState();
}

class _SetupScaffoldState extends State<SetupScaffold> {
  // Lives here, not in the slab, so rotating the phone (which rebuilds
  // the slab in a new place) doesn't re-arm it.
  late final Timer _guard;

  @override
  void initState() {
    super.initState();
    _guard = Timer(SetupScaffold.startGuard, () {});
  }

  @override
  void dispose() {
    _guard.cancel();
    super.dispose();
  }

  void _onStart() {
    if (_guard.isActive) return;
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) {
    // Setup is reached with context.go (from Home, and from DONE since 1.3.0),
    // so it is the only route on the stack: the Android back button would
    // close the app. Back goes Home instead, like the header chevron.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        // The slab runs to the very bottom edge; its content keeps clear of
        // the home indicator itself.
        body: SafeArea(
          bottom: false,
          child: OrientationBuilder(
            builder: (context, orientation) {
              final landscape = orientation == Orientation.landscape;
              final subtitle = widget.startSubtitle;
              return Column(
                children: [
                  _SetupHeader(
                    title: widget.title,
                    verticalPadding: landscape ? 4 : 12,
                  ),
                  Expanded(child: widget.body(context, landscape: landscape)),
                  BottomSlab(
                    cells: [
                      SlabCell(
                        label: 'START',
                        labelSize: 34,
                        subtitle: subtitle,
                        background: AppColors.start,
                        foreground: Colors.black,
                        onTap: _onStart,
                        semanticsLabel: subtitle == null
                            ? 'Start workout'
                            : 'Start workout. $subtitle',
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({required this.title, this.verticalPadding = 12});

  final String title;

  /// Tighter in landscape, where every point of height counts.
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Go back',
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.home),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 22,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Expanded (not Flexible + Spacer, which split the free space and
          // left the chip short of the edge) so the chip sits flush right.
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: AppTypography.sectionHeader.copyWith(
                color: AppColors.textPrimaryDark,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const _VoiceChip(),
        ],
      ),
    );
  }
}

/// The voice pack, choosable at setup: one chip instead of a card row.
///
/// Grey on purpose: START is the only green control on a setup screen, so
/// the eye goes to it first.
class _VoiceChip extends ConsumerWidget {
  const _VoiceChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.watch(appSettingsNotifierProvider).voice;
    final label = voiceShortLabel(voice);
    return Semantics(
      button: true,
      label: 'Voice: $label. Tap to change.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => showVoicePickerSheet(context, ref),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Container(
              height: 40,
              padding: const EdgeInsets.only(left: 12, right: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    switch (voice) {
                      VoiceOption.silent => Icons.volume_off_outlined,
                      VoiceOption.off => Icons.volume_down_outlined,
                      _ => Icons.volume_up_outlined,
                    },
                    size: 19,
                    color: AppColors.textSecondaryDark,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: AppTypography.summaryValue.copyWith(
                      color: AppColors.textSecondaryDark,
                      fontSize: 16,
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

/// AMRAP and For Time: the stopwatch bezel centred in the space with one
/// line under it (the direction switch, or a hint). The bezel is 270pt
/// where it fits and shrinks where it doesn't (a phone held sideways,
/// where the line moves beside it).
class BezelSetupBody extends StatelessWidget {
  const BezelSetupBody({
    required this.landscape,
    required this.bezel,
    required this.below,
    super.key,
  });

  final bool landscape;

  /// Builds the bezel at the size the space allows.
  final Widget Function(double size) bezel;

  final Widget below;

  static const double fullSize = 270;
  static const double gap = 14;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (landscape) {
          final size = math.min(
            fullSize,
            math.min(constraints.maxHeight - 16, constraints.maxWidth * 0.45),
          );
          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [bezel(size), const SizedBox(width: 32), below],
            ),
          );
        }
        // Leave room for the line under the bezel and a breath above and
        // below (large text makes that line taller).
        final size = math
            .min(
              fullSize,
              math.min(
                constraints.maxHeight - gap - 96,
                constraints.maxWidth - 32,
              ),
            )
            .clamp(140.0, fullSize);
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              bezel(size),
              const SizedBox(height: gap),
              below,
            ],
          ),
        );
      },
    );
  }
}

/// EMOM and Tabata: the wheels side by side, centred between the header
/// and the timeline zone, with the Home timeline under them placed by the
/// centring rule (layout rule 2) and redrawn live.
class WheelsSetupBody extends StatelessWidget {
  const WheelsSetupBody({
    required this.landscape,
    required this.wheels,
    required this.shape,
    super.key,
    this.accessory,
  });

  final bool landscape;

  /// Built with the row height for the orientation.
  final List<Widget> Function(double rowHeight) wheels;

  final WorkoutShape shape;

  /// An optional line just above the wheels (Tabata's reset chip).
  final Widget? accessory;

  static const double timelineHeight = 12;

  double get rowHeight => landscape ? 44 : 56;

  @override
  Widget build(BuildContext context) {
    final accessory = this.accessory;
    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: accessory == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: EdgeInsets.only(bottom: landscape ? 0 : 12),
                    child: accessory,
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              for (final wheel in wheels(rowHeight))
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: SetupWheel.width,
                    ),
                    child: wheel,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: CentredTimeline(
            aboveInkInset: SetupWheel.inkInset(context, rowHeight),
            height: timelineHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: WorkoutTimeline(shape: shape, height: timelineHeight),
            ),
          ),
        ),
      ],
    );
  }
}

/// For Time's count direction: a two-option switch under the bezel,
/// COUNT UP | COUNT DOWN, the selected one white with black text.
class CountDirectionSwitch extends StatelessWidget {
  const CountDirectionSwitch({
    required this.countUp,
    required this.onChanged,
    super.key,
  });

  final bool countUp;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(String label, {required bool selected, required bool up}) {
      return Semantics(
        button: true,
        selected: selected,
        label: up ? 'Count up' : 'Count down',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: selected ? null : () => onChanged(up),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: AppTypography.sectionHeader.copyWith(
                color: selected ? Colors.black : AppColors.textSecondaryDark,
                fontSize: 17,
                letterSpacing: 17 * 0.06,
                height: 1.2,
              ),
            ),
          ),
        ),
      );
    }

    // Scales down rather than overflowing a narrow phone at large text.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            option('COUNT UP', selected: countUp, up: true),
            option('COUNT DOWN', selected: !countUp, up: false),
          ],
        ),
      ),
    );
  }
}

/// The hint under AMRAP's bezel.
class BezelHint extends StatelessWidget {
  const BezelHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppTypography.labelLarge.copyWith(
        color: AppColors.textDisabledDark,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// A bezel wired to a setup page: the mode colour, the haptic per minute.
Widget setupBezel({
  required WidgetRef ref,
  required int minutes,
  required String label,
  required Color accent,
  required double size,
  required ValueChanged<int> onChanged,
}) => StopwatchBezel(
  minutes: minutes,
  label: label,
  accent: accent,
  size: size,
  onChanged: (next) {
    ref.read(hapticServiceProvider).selectionClick();
    onChanged(next);
  },
);

/// Creates the workout, starts the timer and opens the active screen.
/// Shared by all four setup screens.
Future<void> startSetupWorkout({
  required BuildContext context,
  required WidgetRef ref,
  required String name,
  required TimerType timerType,
  required String route,
}) async {
  final workoutResult = ref.read(createWorkoutProvider)(
    name: name,
    timerType: timerType,
    prepCountdownSeconds: 10,
  );

  await workoutResult.fold<Future<void>>(
    (failure) async {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${failure.toString()}')));
    },
    (workout) async {
      await ref.read(timerNotifierProvider.notifier).start(workout);
      if (!context.mounted) return;
      context.go(AppRoutes.timerActivePath(route));
    },
  );
}
