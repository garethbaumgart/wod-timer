import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/content_width_cap.dart';
import 'package:wod_timer/core/presentation/widgets/voice_picker_sheet.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_stepper.dart';

/// The frame every setup screen shares: header (back, mode, voice chip),
/// the mode's controls centred in the space, then an optional total line
/// and START. One value per control, nothing repeated.
class SetupScaffold extends StatefulWidget {
  const SetupScaffold({
    required this.title,
    required this.controls,
    required this.onStart,
    super.key,
    this.totalSeconds,
    this.spacing = 44,
  });

  /// Mode name in the header ("EMOM").
  final String title;

  /// The mode's steppers / switches, top to bottom.
  final List<Widget> controls;

  final VoidCallback onStart;

  /// Computed workout length, shown only where it is new information
  /// (EMOM, Tabata). AMRAP and For Time leave it null: their one value
  /// already is the total.
  final int? totalSeconds;

  /// Vertical gap between controls in portrait.
  final double spacing;

  /// How long START ignores taps after the screen appears. DONE on the
  /// completion screen lands here, so the second tap of a double tap on
  /// DONE would otherwise start a fresh countdown.
  static const startGuard = Duration(milliseconds: 500);

  @override
  State<SetupScaffold> createState() => _SetupScaffoldState();
}

class _SetupScaffoldState extends State<SetupScaffold> {
  // Lives here, not in the footer, so rotating the phone (which rebuilds
  // the footer in a new place) doesn't re-arm it.
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
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return ContentWidthCap(maxWidth: 900, child: _buildLandscape());
            }
            return ContentWidthCap(child: _buildPortrait());
          },
        ),
      ),
    );
  }

  Widget _buildPortrait() {
    return Column(
      children: [
        _SetupHeader(title: widget.title),
        Expanded(
          child: _SetupControls(
            controls: widget.controls,
            spacing: widget.spacing,
          ),
        ),
        _SetupFooter(totalSeconds: widget.totalSeconds, onStart: _onStart),
      ],
    );
  }

  Widget _buildLandscape() {
    return Column(
      children: [
        _SetupHeader(title: widget.title),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _SetupControls(controls: widget.controls, spacing: 20),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: SingleChildScrollView(
                    child: _SetupFooter(
                      totalSeconds: widget.totalSeconds,
                      onStart: _onStart,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

/// Controls centred in the available space; scrolls only if they can't fit
/// (large accessibility text, landscape Tabata).
class _SetupControls extends StatelessWidget {
  const _SetupControls({required this.controls, required this.spacing});

  final List<Widget> controls;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 20).clamp(0, double.infinity),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: spacing,
                children: controls,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SetupFooter extends StatelessWidget {
  const _SetupFooter({required this.totalSeconds, required this.onStart});

  final int? totalSeconds;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final total = totalSeconds;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (total != null) ...[
            Semantics(
              label: 'Total ${setupSpokenDuration(total)}',
              excludeSemantics: true,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: setupClock(total),
                      style: AppTypography.workoutTitle.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontSize: 22,
                      ),
                    ),
                    TextSpan(
                      text: '  total',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondaryDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Semantics(
            button: true,
            label: 'Start workout',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onStart,
              child: Container(
                width: double.infinity,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'START',
                    style: AppTypography.buttonLarge.copyWith(
                      color: Colors.black,
                      fontSize: 18,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
