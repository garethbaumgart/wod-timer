// Test traffic: TestFlight, App Review, Xcode runs, the simulator and
// emulators, Play pre-launch reports, debug builds and an explicit flag.
//
// Every detector here spells out both flags, even where one matches the
// default, so no case depends on the test runner's own build mode.
// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';
import 'package:wod_timer/core/infrastructure/telemetry/test_device_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(TestDeviceDetector.channelName);

  void reply(Object? Function(MethodCall) answer) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => answer(call));
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  const release = TestDeviceDetector(debugBuild: false, envFlag: false);

  test('the native answer maps to the reason', () async {
    for (final (native, reason) in [
      ('sandbox_receipt', TestReason.sandboxReceipt),
      ('xcode', TestReason.xcode),
      ('firebase_test_lab', TestReason.firebaseTestLab),
      ('simulator', TestReason.simulator),
      ('emulator', TestReason.emulator),
      ('none', TestReason.none),
      ('something_new', TestReason.none),
    ]) {
      reply((call) {
        expect(call.method, 'detect');
        return native;
      });
      expect(await release.detect(), reason, reason: native);
    }
  });

  test('no native side (or an error) is not evidence of a test', () async {
    expect(await release.detect(), TestReason.none);
    reply((_) => throw PlatformException(code: 'boom'));
    expect(await release.detect(), TestReason.none);
    expect(await release.detectLocal(), TestReason.none);
  });

  test('native evidence wins; then the env flag; then a debug build', () async {
    reply((_) => 'xcode');
    expect(
      await const TestDeviceDetector(debugBuild: true, envFlag: true).detect(),
      TestReason.xcode,
    );
    reply((_) => 'none');
    expect(
      await const TestDeviceDetector(debugBuild: true, envFlag: true).detect(),
      TestReason.envFlag,
    );
    expect(
      await const TestDeviceDetector(debugBuild: true, envFlag: false).detect(),
      TestReason.debug,
    );
    expect(await release.detect(), TestReason.none);
  });

  test(
    'the local check asks the native side for the instant answer only',
    () async {
      reply((call) {
        expect(call.method, 'detectLocal');
        return 'emulator';
      });
      expect(await release.detectLocal(), TestReason.emulator);
      reply((call) {
        expect(call.method, 'detectLocal');
        return 'simulator';
      });
      expect(
        await const TestDeviceDetector(
          debugBuild: true,
          envFlag: true,
        ).detectLocal(),
        TestReason.simulator,
      );
      reply((call) {
        expect(call.method, 'detectLocal');
        return 'none';
      });
      expect(await release.detectLocal(), TestReason.none);
      expect(
        await const TestDeviceDetector(
          debugBuild: false,
          envFlag: true,
        ).detectLocal(),
        TestReason.envFlag,
      );
      expect(
        await const TestDeviceDetector(
          debugBuild: true,
          envFlag: false,
        ).detectLocal(),
        TestReason.debug,
      );
    },
  );

  test('only a real user is not a test', () {
    expect(TestReason.none.isTest, isFalse);
    for (final reason in TestReason.values.skip(1)) {
      expect(reason.isTest, isTrue, reason: reason.wireName);
    }
  });

  test('wire names match the spec', () {
    expect(TestReason.values.map((r) => r.wireName), [
      'none',
      'sandbox_receipt',
      'xcode',
      'firebase_test_lab',
      'simulator',
      'emulator',
      'debug',
      'env_flag',
    ]);
  });
}
