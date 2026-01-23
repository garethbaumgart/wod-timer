/// Route path constants for the app.
abstract class AppRoutes {
  /// Home screen - timer type selection.
  static const String home = '/';

  /// Timer setup screen.
  /// Path parameter: `timerType` - the type of timer (amrap, fortime, emom, tabata)
  static const String timerSetup = '/timer/:timerType';

  /// Active timer screen.
  /// Path parameter: `timerType` - the type of timer
  static const String timerActive = '/timer/:timerType/active';

  /// Saved presets screen.
  static const String presets = '/presets';

  /// Settings screen.
  static const String settings = '/settings';

  /// Helper to generate timer setup path.
  static String timerSetupPath(String timerType) => '/timer/$timerType';

  /// Helper to generate active timer path.
  static String timerActivePath(String timerType) => '/timer/$timerType/active';
}

/// Timer type identifiers for routing.
abstract class TimerTypes {
  /// AMRAP - As Many Rounds As Possible.
  static const String amrap = 'amrap';

  /// For Time - Complete work as fast as possible.
  static const String forTime = 'fortime';

  /// EMOM - Every Minute On the Minute.
  static const String emom = 'emom';

  /// Tabata - 20s work / 10s rest intervals.
  static const String tabata = 'tabata';

  /// All valid timer types.
  static const List<String> all = [amrap, forTime, emom, tabata];

  /// Check if a timer type is valid.
  static bool isValid(String type) => all.contains(type);
}
