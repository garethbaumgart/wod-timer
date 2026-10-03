import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';

/// The slab cell that ends a workout: HOLD TO STOP, red on near-black,
/// filling red from the left while held and confirming after 0.8s.
///
/// The fill starts the instant the finger lands (a raw pointer listener,
/// so there is no long-press dead zone first). Letting go early rewinds
/// it and brightens the cell for a moment as the hint: nothing else on the
/// screen moves. This is the error-prevention guard for the app's only
/// destructive action.
class HoldToStopCell extends StatefulWidget {
  const HoldToStopCell({
    required this.enabled,
    required this.showHint,
    required this.onConfirmed,
    required this.onShortPress,
    super.key,
  });

  final bool enabled;

  /// Brightened for a moment after a short press or a back gesture.
  final bool showHint;
  final VoidCallback onConfirmed;
  final VoidCallback onShortPress;

  static const holdDuration = Duration(milliseconds: 800);

  @override
  State<HoldToStopCell> createState() => _HoldToStopCellState();
}

class _HoldToStopCellState extends State<HoldToStopCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill;
  bool _confirmed = false;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _fill =
        AnimationController(vsync: this, duration: HoldToStopCell.holdDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && !_confirmed) {
              _confirmed = true;
              widget.onConfirmed();
            }
          })
          ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  void _startHold() {
    if (!widget.enabled) return;
    _confirmed = false;
    _holding = true;
    HapticFeedback.mediumImpact();
    _fill.forward(from: 0);
  }

  void _release() {
    if (!_holding) return;
    _holding = false;
    if (_confirmed) return;
    _fill
      ..stop()
      ..animateBack(0, duration: const Duration(milliseconds: 150));
    widget.onShortPress();
  }

  void _cancel() {
    if (!_holding) return;
    _holding = false;
    if (_confirmed) return;
    _fill
      ..stop()
      ..animateBack(0, duration: const Duration(milliseconds: 150));
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final hint = widget.showHint && enabled;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: 'End workout. Hold to confirm.',
      onLongPress: enabled ? widget.onConfirmed : null,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: enabled ? (_) => _startHold() : null,
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _cancel(),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: hint
              ? Color.alphaBlend(
                  AppColors.stopRed.withValues(alpha: 0.25),
                  AppColors.stopSlab,
                )
              : AppColors.stopSlab,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The red fill creeping in from the left while held.
              if (_fill.value > 0)
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _fill.value,
                  child: ColoredBox(
                    color: AppColors.stopRed.withValues(alpha: 0.35),
                  ),
                ),
              SlabContent(
                label: 'HOLD TO STOP',
                foreground: enabled
                    ? AppColors.stopRed
                    : AppColors.textDisabledDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
