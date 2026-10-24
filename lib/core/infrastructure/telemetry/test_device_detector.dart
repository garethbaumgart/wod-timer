import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';

/// Tells test traffic from real users. The native side reads StoreKit 2's
/// `AppTransaction.environment` (sandbox covers TestFlight and App Review;
/// xcode is a local run) with a receipt-name fallback on iOS 15, the
/// simulator target on iOS, the Firebase Test Lab system setting on Android
/// (Play pre-launch reports) and the emulator's generic build properties.
/// `--dart-define=IS_TEST=true` and debug builds also count.
class TestDeviceDetector {
  const TestDeviceDetector({
    this.channel = const MethodChannel(channelName),
    this.debugBuild = kDebugMode,
    this.envFlag = const bool.fromEnvironment('IS_TEST'),
  });

  static const channelName = 'app.mentalmetal.wharfwod/test_device';

  final MethodChannel channel;
  final bool debugBuild;
  final bool envFlag;

  /// The full answer, including the StoreKit round-trip on a real iPhone.
  /// Analytics wait for this one.
  Future<TestReason> detect() => _detect('detect');

  /// The instant, local part of [detect]: a simulator or emulator, a Play
  /// pre-launch device, the env flag or a debug build. No store round-trip,
  /// so `main` can tag Sentry and print the start-up line before the first
  /// frame. Never says sandbox.
  Future<TestReason> detectLocal() => _detect('detectLocal');

  Future<TestReason> _detect(String method) async {
    final native = await _native(method);
    if (native != TestReason.none) return native;
    if (envFlag) return TestReason.envFlag;
    if (debugBuild) return TestReason.debug;
    return TestReason.none;
  }

  Future<TestReason> _native(String method) async {
    try {
      final reason = await channel.invokeMethod<String>(method);
      return switch (reason) {
        'sandbox_receipt' => TestReason.sandboxReceipt,
        'xcode' => TestReason.xcode,
        'firebase_test_lab' => TestReason.firebaseTestLab,
        'simulator' => TestReason.simulator,
        'emulator' => TestReason.emulator,
        _ => TestReason.none,
      };
    } on Object {
      // No channel (tests, an older native shell): not evidence of a test.
      return TestReason.none;
    }
  }
}
