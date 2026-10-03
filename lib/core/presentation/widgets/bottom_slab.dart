import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wod_timer/core/presentation/theme/app_typography.dart';

/// Layout rule 3 (1.3.1): every screen's main actions live in one
/// edge-to-edge slab along the bottom. Full width, [tall] (132pt) to the
/// very bottom edge with the content kept clear of the home indicator, or
/// [short] on a phone held sideways. One or two cells side by side.
class BottomSlab extends StatelessWidget {
  const BottomSlab({required this.cells, super.key});

  /// Left to right; each takes an equal share of the width.
  final List<Widget> cells;

  static const double tall = 132;
  static const double short = 96;

  /// Logical heights under this get the short slab (a phone in landscape;
  /// a tablet lays out at 600pt or more either way).
  static const double shortBelowHeight = 480;

  static double heightOf(BuildContext context) =>
      MediaQuery.sizeOf(context).height < shortBelowHeight ? short : tall;

  /// Space under the labels: the home indicator, or 10pt where there is
  /// none, so the content sits slightly above centre as in the prototype.
  static double bottomPaddingOf(BuildContext context) =>
      math.max(MediaQuery.viewPaddingOf(context).bottom, 10);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: heightOf(context),
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final cell in cells) Expanded(child: cell)],
      ),
    );
  }
}

/// One slab cell: a heavy tracked label, an optional subtitle, one tap.
class SlabCell extends StatelessWidget {
  const SlabCell({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    required this.semanticsLabel,
    super.key,
    this.subtitle,
    this.labelSize = 26,
    this.enabled = true,
  });

  final String label;
  final String? subtitle;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final String semanticsLabel;

  /// 34 for START, 26 for the live and end cells.
  final double labelSize;
  final bool enabled;

  /// The label style, shared so other cells (hold to stop) match.
  static TextStyle labelStyle(Color color, double size) =>
      AppTypography.buttonLarge.copyWith(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: size * 0.08,
        height: 1,
      );

  static TextStyle subtitleStyle(Color color) =>
      AppTypography.bodyMedium.copyWith(
        color: color.withValues(alpha: 0.7),
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.15,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: background,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: SlabContent(
            label: label,
            subtitle: subtitle,
            foreground: foreground,
            labelSize: labelSize,
          ),
        ),
      ),
    );
  }
}

/// A cell's text, centred above the home indicator.
class SlabContent extends StatelessWidget {
  const SlabContent({
    required this.label,
    required this.foreground,
    super.key,
    this.subtitle,
    this.labelSize = 26,
  });

  final String label;
  final String? subtitle;
  final Color foreground;
  final double labelSize;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: BottomSlab.bottomPaddingOf(context),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                style: SlabCell.labelStyle(foreground, labelSize),
              ),
              if (sub != null) ...[
                const SizedBox(height: 5),
                Text(
                  sub,
                  maxLines: 1,
                  style: SlabCell.subtitleStyle(foreground),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
