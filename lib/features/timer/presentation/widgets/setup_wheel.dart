import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';
import 'package:wod_timer/core/presentation/widgets/glyph_ink.dart';
import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';

/// A setup value as a snapping wheel (1.3.1): a label over three visible
/// rows, the selected row larger and white on a soft highlight, the
/// neighbours dim. EMOM and Tabata put two or three side by side.
///
/// Controlled: the page owns the value and passes it back in, so anything
/// that changes it elsewhere (Tabata's "Reset to classic") moves the wheel.
/// Accessibility: one adjustable node per wheel (increase / decrease by a
/// step, value spoken).
class SetupWheel extends StatefulWidget {
  const SetupWheel({
    required this.label,
    required this.labelColor,
    required this.range,
    required this.value,
    required this.format,
    required this.spoken,
    required this.onChanged,
    super.key,
    this.rowHeight = 56,
  });

  /// Short label above the wheel ("EVERY", "ROUNDS").
  final String label;

  /// EMOM: EVERY green, ROUNDS blue. Tabata: WORK green, REST pink,
  /// ROUNDS blue.
  final Color labelColor;

  /// The legal values and step.
  final SetupRange range;

  final int value;

  /// Display string for a value ("1:00", "10", "20s").
  final String Function(int value) format;

  /// What a screen reader says for a value ("1 minute").
  final String Function(int value) spoken;

  final ValueChanged<int> onChanged;

  /// One row; the wheel shows three. 56 on a phone, 44 held sideways.
  final double rowHeight;

  /// Width of one wheel column.
  static const double width = 130;

  static const double labelGap = 8;

  static TextStyle labelStyle(Color color) => AppTypography.labelSmall.copyWith(
    color: color,
    fontSize: 13,
    letterSpacing: 13 * 0.14,
  );

  static TextStyle selectedStyle(double rowHeight) =>
      AppTypography.timerDisplayMedium.copyWith(
        color: AppColors.textPrimaryDark,
        fontSize: 42 * rowHeight / 56,
        letterSpacing: 0,
        fontWeight: FontWeight.w900,
      );

  static TextStyle neighbourStyle(double rowHeight) =>
      AppTypography.timerDisplayMedium.copyWith(
        color: AppColors.textDisabledDark,
        fontSize: 28 * rowHeight / 56,
        letterSpacing: 0,
        fontWeight: FontWeight.w800,
      );

  /// Height of the whole column: label, gap, three rows.
  static double heightFor(
    double rowHeight, {
    TextScaler textScaler = TextScaler.noScaling,
  }) =>
      GlyphInk.boxHeight(
        'A',
        labelStyle(Colors.white),
        textScaler: textScaler,
      ) +
      labelGap +
      3 * rowHeight;

  /// Layout rule 2: the visible bottom of a wheel is the glyph bottom of
  /// its lower row, whose text is centred in that row. Returned as the
  /// distance up from the column's bottom edge.
  static double inkInset(
    double rowHeight, {
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final style = neighbourStyle(rowHeight);
    final box = GlyphInk.boxHeight('0', style, textScaler: textScaler);
    final glyph = GlyphInk.glyphBottom('0', style, textScaler: textScaler);
    // The lower row's centre is half a row above the bottom; its text box
    // is centred on that, so the glyph bottom is box/2 - glyph above it.
    return rowHeight / 2 - (glyph - box / 2);
  }

  List<int> get values => [
    for (var v = range.min; v <= range.max; v += range.step) v,
  ];

  @override
  State<SetupWheel> createState() => _SetupWheelState();
}

class _SetupWheelState extends State<SetupWheel> {
  late final List<int> _values = widget.values;
  late final FixedExtentScrollController _controller;
  late int _selected = _indexOf(widget.value);

  int _indexOf(int value) {
    final i = _values.indexOf(widget.range.normalize(value));
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: _selected);
  }

  @override
  void didUpdateWidget(SetupWheel old) {
    super.didUpdateWidget(old);
    final target = _indexOf(widget.value);
    if (target != _selected) {
      _selected = target;
      // A value set elsewhere (Reset to classic): jump, no scroll fuss.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToItem(target);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSelected(int index) {
    if (index == _selected) return;
    setState(() => _selected = index);
    final value = _values[index];
    if (value != widget.value) widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.rowHeight;
    final value = _values[_selected];
    final canIncrease = _selected < _values.length - 1;
    final canDecrease = _selected > 0;
    return Semantics(
      container: true,
      label: widget.label,
      value: widget.spoken(value),
      increasedValue: canIncrease
          ? widget.spoken(_values[_selected + 1])
          : null,
      decreasedValue: canDecrease
          ? widget.spoken(_values[_selected - 1])
          : null,
      onIncrease: canIncrease
          ? () => _controller.animateToItem(
              _selected + 1,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
            )
          : null,
      onDecrease: canDecrease
          ? () => _controller.animateToItem(
              _selected - 1,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
            )
          : null,
      excludeSemantics: true,
      child: SizedBox(
        width: SetupWheel.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label.toUpperCase(),
              style: SetupWheel.labelStyle(widget.labelColor),
            ),
            const SizedBox(height: SetupWheel.labelGap),
            SizedBox(
              height: 3 * row,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The soft band behind the selected row.
                  Align(
                    child: Container(
                      height: row,
                      decoration: BoxDecoration(
                        color: AppColors.soft,
                        borderRadius: BorderRadius.circular(14 * row / 56),
                      ),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    controller: _controller,
                    itemExtent: row,
                    // Near flat: the rows read as a list that snaps.
                    diameterRatio: 100,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: _onSelected,
                    childDelegate: ListWheelChildListDelegate(
                      children: [
                        for (final (i, v) in _values.indexed)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.format(v),
                                  maxLines: 1,
                                  style: i == _selected
                                      ? SetupWheel.selectedStyle(row)
                                      : SetupWheel.neighbourStyle(row),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
