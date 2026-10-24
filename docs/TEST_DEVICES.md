# Test devices: what counts as test traffic, and what it changes

Since this change every Aptabase event carries `is_test` (0/1) and `test_reason`, and a
simulator or emulator run counts as test traffic. Nothing is dropped server-side: filter
Aptabase dashboards on `is_test = 0`. Wharf WOD is free and has no RevenueCat, so the
RevenueCat column of the portfolio table does not apply here.

| `test_reason` | How it is known | Aptabase events |
|---|---|---|
| `none` | a real phone, production receipt | sent, `is_test = 0` |
| `sandbox_receipt` | real phone, StoreKit says sandbox: TestFlight, App Review, sandbox accounts | sent, `is_test = 1` |
| `xcode` | real phone run from Xcode with a StoreKit configuration file | sent, `is_test = 1` |
| `simulator` | iOS simulator (`#if targetEnvironment(simulator)`), any build mode | sent only from release builds, `is_test = 1` |
| `emulator` | Android emulator (generic `Build` fingerprint, model, product, hardware) | sent only from release builds, `is_test = 1` |
| `firebase_test_lab` | Play pre-launch reports (`Settings.System` `firebase.test.lab`) | sent, `is_test = 1` |
| `debug` | `kDebugMode` | never sent (Aptabase is release-only) |
| `env_flag` | `--dart-define=IS_TEST=true` | sent from release builds, `is_test = 1` |

Aptabase is also off when `APTABASE_KEY` is unset.

Where it lives: `lib/core/infrastructure/telemetry/test_device_detector.dart` (Dart side, two
calls: `detect()` is the full answer and `detectLocal()` the instant one), the
`app.mentalmetal.wharfwod/test_device` channel in `ios/Runner/AppDelegate.swift` and
`android/app/src/main/kotlin/app/mentalmetal/wharfwod/MainActivity.kt`, `TestReason` and the two
props in `trackEvent` in `lib/core/infrastructure/telemetry/telemetry.dart` (the only place
that calls Aptabase; `main.dart` only initialises it, and a test keeps it that way), and the
check at the top of `lib/main.dart`.

The watch apps send nothing: the watchOS companion (`ios/WODTimerWatch`) and the Wear OS app
(`android/wear`) have no Aptabase or Sentry SDK and no network code (the Wear manifest does not
even ask for `INTERNET`). Every Wharf WOD event comes from the phone app.

Order: `main` starts both checks and goes straight on to the first frame; neither is awaited.
`trackEvent` holds any event fired before the full answer is in (`app_open` fires in `main`) and
sends them in order once it is, so every event carries the right flag. Both checks are capped at
10 s (the full one then falls back to the local answer, else `none`). The cap is long on
purpose: the platform thread only answers once the activity is up, which took 1.4 to 1.7 s on
an emulator and more than 2 s on a slow cold start, so the 2 s cap the other apps use read some
emulator runs as `none`.

Sentry: the local answer is set as the `test_device` tag at start-up; once the full answer is
in, `is_test` and `test_reason` tags are set on the scope, so a crash or an app hang from App
Review's harness reads as such in the sweep.

How to check a build by hand: the app prints one line at start-up,
`[wharfwod] test device: <reason>`, visible in `adb logcat` (`I/flutter`) on an emulator and in
the simulator's log (`xcrun simctl spawn <udid> log show --last 2m --predicate
'process == "Runner"'`). A release build on an emulator must say `emulator`; a simulator build
must say `simulator`; a TestFlight install on a phone says `none` (the local check never says
sandbox; analytics learn that a moment later).
