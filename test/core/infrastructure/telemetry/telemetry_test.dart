// Telemetry gating: events go nowhere unless main() initialised Aptabase
// in a release build, and a call can never throw into the workout.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';

void main() {
  tearDown(() => telemetryEnabled = false);

  test('telemetry is off until main() turns it on', () {
    expect(telemetryEnabled, isFalse);
    expect(
      () => trackEvent('workout_started', {'type': 'emom'}),
      returnsNormally,
    );
    expect(() => trackEvent('app_open'), returnsNormally);
  });

  test('a debug or test build never sends, even when enabled', () {
    // Aptabase is never initialised here: a send would throw, and the
    // release-mode gate must stop it before that.
    telemetryEnabled = true;
    expect(kReleaseMode, isFalse);
    expect(
      () => trackEvent('rate_tapped', {'source': 'settings'}),
      returnsNormally,
    );
  });
}
