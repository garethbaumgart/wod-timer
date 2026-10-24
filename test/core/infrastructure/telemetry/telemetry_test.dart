// Telemetry gating: events go nowhere unless main() initialised Aptabase
// in a release build, and a call can never throw into the workout. Every
// event carries `is_test` and `test_reason`, so test runs can be filtered
// out of the funnel (docs/TEST_DEVICES.md).
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';

void main() {
  tearDown(() {
    telemetryEnabled = false;
    debugTelemetrySend = null;
    resetTelemetryForTest();
  });

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

  group('test devices', () {
    final sent = <(String, Map<String, dynamic>)>[];

    setUp(() {
      sent.clear();
      telemetryEnabled = true;
      debugTelemetrySend = (name, props) => sent.add((name, props));
    });

    test('a release build on a simulator is flagged on every event', () async {
      describeTestDevice(Future.value(TestReason.simulator));
      await pumpEventQueue();
      // Every event the app sends, with the props its call site passes.
      trackEvent('app_open');
      trackEvent('workout_started', {'type': 'emom'});
      trackEvent('workout_completed', {
        'type': 'amrap',
        'rounds': 7,
        'duration_s': 600,
      });
      trackEvent('rate_tapped', {'source': 'settings'});
      trackEvent('feedback_tapped', {'source': 'settings'});

      expect(sent.map((e) => e.$1), [
        'app_open',
        'workout_started',
        'workout_completed',
        'rate_tapped',
        'feedback_tapped',
      ]);
      for (final (name, props) in sent) {
        expect(props['is_test'], 1, reason: name);
        expect(props['test_reason'], 'simulator', reason: name);
      }
      // The event's own props are kept alongside.
      expect(sent[1].$2, {
        'type': 'emom',
        'is_test': 1,
        'test_reason': 'simulator',
      });
    });

    test(
      'events wait for the test-device check, then go out in order',
      () async {
        final check = Completer<TestReason>();
        describeTestDevice(check.future);
        // Tracked before the check answers (app_open fires in main()).
        trackEvent('app_open');
        trackEvent('workout_started', {'type': 'tabata'});
        await pumpEventQueue();
        expect(sent, isEmpty);

        check.complete(TestReason.sandboxReceipt);
        await pumpEventQueue();
        trackEvent('rate_tapped', {'source': 'settings'});

        expect(sent.map((e) => e.$1), [
          'app_open',
          'workout_started',
          'rate_tapped',
        ]);
        expect(sent.map((e) => e.$2['test_reason']).toSet(), {
          'sandbox_receipt',
        });
        expect(sent.map((e) => e.$2['is_test']).toSet(), {1});
      },
    );

    test('a real phone sends is_test 0', () async {
      describeTestDevice(Future.value(TestReason.none));
      await pumpEventQueue();
      trackEvent('app_open');
      expect(sent.single.$2, {'is_test': 0, 'test_reason': 'none'});
    });

    test('a failed check is not evidence of a test', () async {
      describeTestDevice(Future.error(StateError('no channel')));
      trackEvent('app_open');
      await pumpEventQueue();
      expect(sent.single.$2, {'is_test': 0, 'test_reason': 'none'});
    });

    test('an event prop can never override the flag', () async {
      describeTestDevice(Future.value(TestReason.emulator));
      await pumpEventQueue();
      trackEvent('app_open', {'is_test': 0, 'test_reason': 'none'});
      expect(sent.single.$2, {'is_test': 1, 'test_reason': 'emulator'});
    });

    test(
      'disabled telemetry sends nothing, even once the check answers',
      () async {
        telemetryEnabled = false;
        describeTestDevice(Future.value(TestReason.emulator));
        trackEvent('app_open');
        await pumpEventQueue();
        expect(sent, isEmpty);
      },
    );
  });

  test('Aptabase is only ever called from the telemetry helper', () {
    // The one helper is what makes "every event" true: a direct call
    // anywhere else would skip the two props. main() may initialise
    // Aptabase, nothing more.
    final dartFiles = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File && file.path.endsWith('.dart')) file,
    ];
    String path(File f) => f.path.replaceAll(r'\', '/');
    const helper = 'lib/core/infrastructure/telemetry/telemetry.dart';

    final importers = [
      for (final file in dartFiles)
        if (file.readAsStringSync().contains('package:aptabase_flutter/'))
          path(file),
    ]..sort();
    expect(importers, [
      'lib/core/infrastructure/telemetry/telemetry.dart',
      'lib/main.dart',
    ]);

    final senders = [
      for (final file in dartFiles)
        if (file.readAsStringSync().contains('Aptabase.instance')) path(file),
    ];
    expect(senders, [helper]);

    final main = File('lib/main.dart').readAsStringSync();
    expect(RegExp(r'Aptabase\.\w+').allMatches(main).map((m) => m[0]).toSet(), {
      'Aptabase.init',
    });
  });
}
