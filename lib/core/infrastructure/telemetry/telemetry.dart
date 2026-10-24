import 'dart:async';

import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Whether Aptabase was initialised this launch (release build + key present).
///
/// Set once from main(); [trackEvent] is a no-op until then.
bool telemetryEnabled = false;

/// Where an event goes once it carries the test-device props.
typedef TelemetrySend = void Function(String name, Map<String, dynamic> props);

/// Records events in tests in place of Aptabase. When set, the release-mode
/// gate does not apply (a test build is never a release build); when null,
/// events go to Aptabase from release builds only.
@visibleForTesting
TelemetrySend? debugTelemetrySend;

/// Why this run's events are flagged as test traffic. TestFlight and App
/// Review builds are release builds and do emit, so they must be told apart
/// from real users; so must a release build on a simulator or an emulator
/// (the ship gates and the capture runs), which carries no sandbox receipt
/// at all. See docs/TEST_DEVICES.md.
enum TestReason {
  none,
  sandboxReceipt,
  xcode,
  firebaseTestLab,
  simulator,
  emulator,
  debug,
  envFlag;

  /// The `test_reason` prop and Sentry tag.
  String get wireName => switch (this) {
    TestReason.none => 'none',
    TestReason.sandboxReceipt => 'sandbox_receipt',
    TestReason.xcode => 'xcode',
    TestReason.firebaseTestLab => 'firebase_test_lab',
    TestReason.simulator => 'simulator',
    TestReason.emulator => 'emulator',
    TestReason.debug => 'debug',
    TestReason.envFlag => 'env_flag',
  };

  /// The `is_test` prop and Sentry tag: anything but a real user.
  bool get isTest => this != TestReason.none;
}

// Null while main()'s test-device check is out: events wait for it.
// Never described (tests, the capture harness) means a real user.
TestReason? _testReason = TestReason.none;
final _held = <(String, Map<String, dynamic>?)>[];

/// Hands over the test-device check main() starts at launch. It can take a
/// StoreKit round-trip on a real iPhone, so events fired before it answers
/// (`app_open`) wait and go out in order once it does. A failed check is
/// not evidence of a test.
void describeTestDevice(Future<TestReason> reason) {
  _testReason = null;
  unawaited(
    reason.then(_release, onError: (Object _) => _release(TestReason.none)),
  );
}

void _release(TestReason reason) {
  _testReason = reason;
  final held = [..._held];
  _held.clear();
  for (final (name, props) in held) {
    _send(name, props, reason);
  }
}

/// Puts the test-device check back to "a real user" between tests.
@visibleForTesting
void resetTelemetryForTest() {
  _testReason = TestReason.none;
  _held.clear();
}

/// Fire an anonymous funnel event.
///
/// The one place the app calls Aptabase (a test keeps it that way), so every
/// event carries `is_test` (0/1) and `test_reason`; filter dashboards on
/// `is_test = 0`. Never throws and never blocks — analytics must not affect
/// the workout.
void trackEvent(String name, [Map<String, dynamic>? props]) {
  if (!telemetryEnabled) return;
  if (debugTelemetrySend == null && !kReleaseMode) return;
  final reason = _testReason;
  if (reason == null) {
    _held.add((name, props));
    return;
  }
  _send(name, props, reason);
}

void _send(String name, Map<String, dynamic>? props, TestReason reason) {
  // The flag goes last so an event's own props can never override it.
  final withFlag = <String, dynamic>{
    ...?props,
    'is_test': reason.isTest ? 1 : 0,
    'test_reason': reason.wireName,
  };
  try {
    final send = debugTelemetrySend;
    if (send != null) {
      send(name, withFlag);
    } else {
      unawaited(
        Aptabase.instance.trackEvent(name, withFlag).catchError((Object _) {}),
      );
    }
  } on Object {
    // Swallow: telemetry is strictly best-effort.
  }
}
