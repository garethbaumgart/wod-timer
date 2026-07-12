import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';
import 'package:wod_timer/core/presentation/router/app_router.dart';
import 'package:wod_timer/core/presentation/theme/app_theme.dart';
import 'package:wod_timer/injection.dart';

// Per-app compile-time secrets, injected from the `gazzawod` Doppler project
// via --dart-define-from-file at build time (see scripts/with-secrets.sh).
// Empty in dev builds → telemetry stays off.
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');
const _sentryEnv = String.fromEnvironment(
  'SENTRY_ENV',
  defaultValue: 'development',
);
const _aptabaseKey = String.fromEnvironment('APTABASE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

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
      appRunner: () => runApp(const ProviderScope(child: WodTimerApp())),
    );
  } else {
    runApp(const ProviderScope(child: WodTimerApp()));
  }
}

class WodTimerApp extends ConsumerWidget {
  const WodTimerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Gazza WOD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
