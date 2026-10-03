// The real HapticService against a recorded platform channel: which
// vibration each call asks the OS for, the success / warning / error
// patterns, the Haptics-off setting, and that a platform failure never
// surfaces.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:wod_timer/core/infrastructure/haptic/haptic_service.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> vibrations;
  late HapticService haptics;
  var platformFails = false;

  setUp(() {
    vibrations = [];
    platformFails = false;
    haptics = HapticService();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            if (platformFails) {
              throw PlatformException(code: 'no_haptics');
            }
            vibrations.add(call.arguments as String);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  const light = 'HapticFeedbackType.lightImpact';
  const medium = 'HapticFeedbackType.mediumImpact';
  const heavy = 'HapticFeedbackType.heavyImpact';
  const selection = 'HapticFeedbackType.selectionClick';

  test('is on until told otherwise', () {
    expect(haptics.isEnabled, isTrue);
  });

  test('each impact asks the OS for exactly that vibration', () async {
    expect(await haptics.lightImpact(), right<HapticFailure, Unit>(unit));
    expect(await haptics.mediumImpact(), right<HapticFailure, Unit>(unit));
    expect(await haptics.heavyImpact(), right<HapticFailure, Unit>(unit));
    expect(await haptics.selectionClick(), right<HapticFailure, Unit>(unit));
    expect(vibrations, [light, medium, heavy, selection]);
  });

  test('success rises light, medium, heavy', () async {
    expect(await haptics.success(), right<HapticFailure, Unit>(unit));
    expect(vibrations, [light, medium, heavy]);
  });

  test('warning is two medium taps', () async {
    expect(await haptics.warning(), right<HapticFailure, Unit>(unit));
    expect(vibrations, [medium, medium]);
  });

  test('error is three heavy thumps', () async {
    expect(await haptics.error(), right<HapticFailure, Unit>(unit));
    expect(vibrations, [heavy, heavy, heavy]);
  });

  test(
    'Haptics off: every call reports disabled and nothing vibrates',
    () async {
      await haptics.setEnabled(enabled: false);
      expect(haptics.isEnabled, isFalse);
      for (final call in [
        haptics.lightImpact,
        haptics.mediumImpact,
        haptics.heavyImpact,
        haptics.selectionClick,
        haptics.success,
        haptics.warning,
        haptics.error,
      ]) {
        expect(
          await call(),
          left<HapticFailure, Unit>(const HapticFailure.disabled()),
        );
      }
      expect(vibrations, isEmpty);

      await haptics.setEnabled(enabled: true);
      await haptics.mediumImpact();
      expect(vibrations, [medium]);
    },
  );

  test('a platform without haptics fails silently', () async {
    platformFails = true;
    expect(await haptics.heavyImpact(), right<HapticFailure, Unit>(unit));
    expect(await haptics.success(), right<HapticFailure, Unit>(unit));
    expect(vibrations, isEmpty);
  });
}
