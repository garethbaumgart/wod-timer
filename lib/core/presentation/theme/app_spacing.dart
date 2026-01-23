/// Spacing constants for consistent layout.
abstract class AppSpacing {
  // Base spacing unit (4dp)
  static const double unit = 4;

  // Spacing scale
  static const double xxs = 4; // 1 unit
  static const double xs = 8; // 2 units
  static const double sm = 12; // 3 units
  static const double md = 16; // 4 units
  static const double lg = 24; // 6 units
  static const double xl = 32; // 8 units
  static const double xxl = 48; // 12 units
  static const double xxxl = 64; // 16 units

  // Padding presets
  static const double screenPadding = 16;
  static const double cardPadding = 16;
  static const double listItemPadding = 12;

  // Touch target sizes (min 48dp for accessibility)
  static const double minTouchTarget = 48;
  static const double buttonHeight = 56;
  static const double iconButtonSize = 48;
  static const double largeButtonHeight = 64;

  // Border radius
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;
}
