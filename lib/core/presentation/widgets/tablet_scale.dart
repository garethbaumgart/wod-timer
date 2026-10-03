import 'package:flutter/widgets.dart';

/// Tablets render the whole app scaled up from a phone-sized layout, so
/// type, buttons and spacing all grow with the screen (1.3.1). Before this
/// an iPad showed phone-sized text in a 600pt column with empty space
/// around it.
///
/// Phones, and split-view slivers narrower than [baseShortestSide], get a
/// factor of 1 and are untouched. Layouts below see a logical screen whose
/// shortest side is about [baseShortestSide], so every existing phone and
/// landscape rule still applies; the paint is then scaled to fill.
class TabletScale extends StatelessWidget {
  const TabletScale({required this.child, super.key});

  final Widget child;

  /// The logical shortest side a tablet is laid out at.
  static const double baseShortestSide = 600;

  /// Largest scale (a 12.9in iPad lands just under it).
  static const double maxFactor = 1.75;

  /// The scale for a screen of [size] logical pixels.
  static double factorFor(Size size) =>
      (size.shortestSide / baseShortestSide).clamp(1.0, maxFactor);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final factor = factorFor(media.size);
    if (factor <= 1.0) return child;
    final logical = media.size / factor;
    return MediaQuery(
      data: media.copyWith(
        size: logical,
        devicePixelRatio: media.devicePixelRatio * factor,
        padding: media.padding / factor,
        viewPadding: media.viewPadding / factor,
        viewInsets: media.viewInsets / factor,
        systemGestureInsets: media.systemGestureInsets / factor,
      ),
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: logical.width,
          height: logical.height,
          child: child,
        ),
      ),
    );
  }
}
