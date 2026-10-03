import 'package:flutter/material.dart';

/// Layout rule 2 (1.3.1): a timeline sits exactly midway between the
/// visible bottom of the content above it (glyph bottoms, not box edges)
/// and the top of the bottom slab.
///
/// Place it as the flexible filler between that content and the slab, so
/// its box starts at the content's box bottom and ends at the slab's top:
///
/// ```dart
/// Column(children: [
///   content,                                  // ends in a line of text
///   Expanded(child: CentredTimeline(aboveInkInset: ..., child: timeline)),
///   BottomSlab(...),
/// ])
/// ```
///
/// [aboveInkInset] is how far above this widget's top edge the content's
/// glyphs end (its box bottom minus its glyph bottom, see GlyphInk). The
/// child is then placed so the gap from those glyphs to its top equals the
/// gap from its bottom to the slab.
class CentredTimeline extends StatelessWidget {
  const CentredTimeline({
    required this.aboveInkInset,
    required this.height,
    required this.child,
    super.key,
  });

  /// Distance from this widget's top edge up to the glyph bottom of the
  /// content above (0 when that content's glyphs touch its box bottom).
  final double aboveInkInset;

  /// The child's height.
  final double height;

  final Widget child;

  /// Where the child's top goes inside a zone [zoneHeight] tall.
  static double topFor({
    required double zoneHeight,
    required double aboveInkInset,
    required double height,
  }) {
    final midpoint = (zoneHeight - aboveInkInset) / 2;
    final top = midpoint - height / 2;
    return top.clamp(0.0, (zoneHeight - height).clamp(0.0, double.infinity));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final zone = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : height;
        final top = topFor(
          zoneHeight: zone,
          aboveInkInset: aboveInkInset,
          height: height,
        );
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: top),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
