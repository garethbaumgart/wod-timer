import 'package:flutter/material.dart';

/// Caps content width on large screens (tablets) while leaving phone
/// layouts untouched — the constraint only binds when the viewport is
/// wider than [maxWidth].
///
/// Reading/config surfaces (home, setup, settings, completion actions)
/// use this; the active timer stays full-bleed by design since giant
/// digits are the point.
class ContentWidthCap extends StatelessWidget {
  const ContentWidthCap({required this.child, super.key, this.maxWidth = 600});

  /// The content to cap.
  final Widget child;

  /// Maximum content width in logical pixels.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
