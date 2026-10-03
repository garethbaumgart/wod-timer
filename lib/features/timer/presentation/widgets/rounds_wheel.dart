import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';

/// The AMRAP end screen's hero (1.3.1): the round count as a wheel the
/// athlete scrolls to fix (a stray tap counted one too many, or nobody
/// tapped). The selected number is AMRAP blue, the neighbours dim, and the
/// ends fade out. 0..999. Also an adjustable semantics node.
class RoundsWheel extends StatefulWidget {
  const RoundsWheel({
    required this.rounds,
    required this.fontSize,
    required this.onChanged,
    super.key,
  });

  final int rounds;

  /// The selected number's size; the wheel's geometry follows it.
  final double fontSize;

  /// Called with the new count whenever the wheel settles on another row.
  final ValueChanged<int> onChanged;

  static const int max = 999;

  static double itemHeightFor(double fontSize) => fontSize * 1.05;
  static double heightFor(double fontSize) => itemHeightFor(fontSize) * 1.9;
  static double widthFor(double fontSize) => fontSize * 1.6;

  static TextStyle style(double fontSize, {required bool selected}) =>
      AppTypography.timerDisplay.copyWith(
        color: selected ? AppColors.amrapAccent : AppColors.wheelDim,
        fontSize: fontSize,
        letterSpacing: -fontSize * 0.02,
      );

  @override
  State<RoundsWheel> createState() => _RoundsWheelState();
}

class _RoundsWheelState extends State<RoundsWheel> {
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.rounds);
  }

  @override
  void didUpdateWidget(RoundsWheel old) {
    super.didUpdateWidget(old);
    if (widget.rounds != old.rounds &&
        _controller.hasClients &&
        _controller.selectedItem != widget.rounds) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpToItem(widget.rounds);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.fontSize;
    final itemHeight = RoundsWheel.itemHeightFor(size);
    final rounds = widget.rounds;
    return Semantics(
      container: true,
      label: 'Rounds',
      value: '$rounds',
      increasedValue: rounds < RoundsWheel.max ? '${rounds + 1}' : null,
      decreasedValue: rounds > 0 ? '${rounds - 1}' : null,
      onIncrease: rounds < RoundsWheel.max
          ? () => _controller.animateToItem(
              rounds + 1,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
            )
          : null,
      onDecrease: rounds > 0
          ? () => _controller.animateToItem(
              rounds - 1,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
            )
          : null,
      excludeSemantics: true,
      child: SizedBox(
        width: RoundsWheel.widthFor(size),
        height: RoundsWheel.heightFor(size),
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0, 0.28, 0.72, 1],
          ).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: itemHeight,
            diameterRatio: 100,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) {
              if (i != widget.rounds) widget.onChanged(i);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: RoundsWheel.max + 1,
              builder: (context, i) => Center(
                child: Text(
                  '$i',
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: RoundsWheel.style(size, selected: i == rounds),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
