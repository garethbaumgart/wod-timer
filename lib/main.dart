import 'dart:async';

import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';
import 'package:wod_timer/core/infrastructure/telemetry/test_device_detector.dart';
import 'package:wod_timer/core/presentation/router/app_router.dart';
import 'package:wod_timer/core/presentation/theme/app_fonts.dart';
import 'package:wod_timer/core/presentation/theme/app_theme.dart';
import 'package:wod_timer/core/presentation/widgets/tablet_scale.dart';
import 'package:wod_timer/injection.dart';

// Per-app compile-time secrets, injected from the `wharfwod` Doppler project
// via --dart-define-from-file at build time (see scripts/with-secrets.sh).
// Empty in dev builds → telemetry stays off.
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');
const _sentryEnv = String.fromEnvironment(
  'SENTRY_ENV',
  defaultValue: 'development',
);
const _aptabaseKey = String.fromEnvironment('APTABASE_KEY');

/// How long the test-device check may take before a run counts as a real
/// user. Events wait at most this long; nothing else waits at all.
const _testDeviceCap = Duration(seconds: 10);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fonts ship in the bundle and must never be fetched at runtime — an
  // offline cold start used to crash the whole session when the Google Fonts
  // CDN was unreachable (Sentry WHARFWOD-1).
  configureBundledFonts();

  await configureDependencies();

  // Loaded before the first frame so setup screens open on the last
  // workout run in each mode, with no flash of defaults.
  final prefs = await SharedPreferences.getInstance();
  final rootScope = ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const WodTimerApp(),
  );

  // Test traffic: a simulator, an emulator, a Play pre-launch device, a debug
  // build or an IS_TEST run. The local answer feeds the Sentry tag and the
  // start-up line; the full one (TestFlight and App Review need a StoreKit
  // round-trip) feeds analytics, which hold their events until it is in.
  // Neither holds up the first frame: the platform thread answers only once
  // the activity is up, which took 1.4 to 1.7 s on an emulator and over 2 s
  // on a slow cold start, long enough that a short cap read every emulator
  // run as a real user.
  const testDevice = TestDeviceDetector();
  TestReason? localAnswer;
  final localReason = testDevice
      .detectLocal()
      .timeout(_testDeviceCap, onTimeout: () => TestReason.none)
      .then((reason) => localAnswer = reason);
  final testReason = testDevice.detect().timeout(
    _testDeviceCap,
    onTimeout: () => localAnswer ?? TestReason.none,
  );
  describeTestDevice(testReason);
  // One line to check a build by hand (logcat, the simulator's log).
  unawaited(
    localReason.then(
      (reason) => debugPrint('[wharfwod] test device: ${reason.wireName}'),
    ),
  );

  // Aptabase: anonymous funnel only, release builds only, key required.
  if (kReleaseMode && _aptabaseKey.isNotEmpty) {
    try {
      await Aptabase.init(_aptabaseKey);
      telemetryEnabled = true;
    } on Object {
      // Analytics must never block launch.
    }
  }
  trackEvent('app_open');

  // Sentry: crash + error reporting. No PII — scrub user/request context
  // defensively so nothing identifying leaves the phone.
  if (_sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options
          ..dsn = _sentryDsn
          ..environment = _sentryEnv
          ..sendDefaultPii = false
          ..beforeSend = (event, hint) {
            return event
              ..user = null
              ..request = null;
          };
      },
      appRunner: () {
        unawaited(
          localReason.then(
            (reason) => _tagSentry({'test_device': reason.wireName}),
          ),
        );
        // The full answer, once in, so a crash from a simulator, TestFlight
        // or App Review run is told apart from a real user's.
        unawaited(
          testReason.then(
            (reason) => _tagSentry({
              'is_test': reason.isTest ? '1' : '0',
              'test_reason': reason.wireName,
            }),
            onError: (Object _) {},
          ),
        );
        runApp(rootScope);
      },
    );
  } else {
    runApp(rootScope);
  }
}

/// Test-device tags on the Sentry scope. Never throws: a tag must not keep
/// the app from starting.
Future<void> _tagSentry(Map<String, String> tags) async {
  try {
    await Sentry.configureScope((scope) async {
      for (final MapEntry(:key, :value) in tags.entries) {
        await scope.setTag(key, value);
      }
    });
  } on Object {
    // Crash reporting must never break the app.
  }
}

class WodTimerApp extends ConsumerWidget {
  const WodTimerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Wharf WOD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      // iPad and Android tablets: the phone layout, scaled to the screen.
      builder: (context, child) =>
          TabletScale(child: child ?? const SizedBox.shrink()),
    );
  }
}
