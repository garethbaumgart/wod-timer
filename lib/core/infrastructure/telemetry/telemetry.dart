import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Whether Aptabase was initialised this launch (release build + key present).
///
/// Set once from main(); [trackEvent] is a no-op until then.
bool telemetryEnabled = false;

/// Fire an anonymous funnel event.
///
/// Never throws and never blocks — analytics must not affect the workout.
void trackEvent(String name, [Map<String, dynamic>? props]) {
  if (!telemetryEnabled || !kReleaseMode) return;
  try {
    Aptabase.instance.trackEvent(name, props);
  } on Object {
    // Swallow: telemetry is strictly best-effort.
  }
}
