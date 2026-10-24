# Test devices out of the numbers: Wharf WOD (24 Oct 2026)

Branch `feat/test-devices`, cut from `origin/main` at `8ad8e43`. Plan:
`mentalmetal-portfolio/docs/test-devices-rollout-2026-10-24.md`. Reference: Hot Flash Diary
`4ffb4ba`; siblings Loglet `9c6cf62` and Churnie `37fbdea`. Not merged, tagged or shipped;
`pubspec.yaml` stays at 2.3.0+1.

## Commits

- No Flutter commit: `.fvmrc` on main already pins 3.47.8.
- `9aa2f8b` 2.3.0: a simulator or emulator run is test traffic.

## What changed

- A native `app.mentalmetal.wharfwod/test_device` channel, with `detect` and `detectLocal`:
  - iOS (`ios/Runner/AppDelegate.swift`) answers `simulator` at compile time. On a phone,
    `detectLocal` says `none` and `detect` reads StoreKit 2 `AppTransaction` (`sandbox_receipt`,
    `xcode`), with the iOS 15 sandbox-receipt fallback (the app targets iOS 15).
  - Android (`MainActivity.kt`) checks the Firebase Test Lab flag first, then the emulator
    heuristics, for both methods.
- `TestReason` (portfolio wire names, `isTest`) lives in
  `lib/core/infrastructure/telemetry/telemetry.dart`; `TestDeviceDetector` in
  `test_device_detector.dart` beside it applies the precedence: native answer, then `IS_TEST`,
  then debug.
- The one helper: the app already had a single `trackEvent` helper in `telemetry.dart`, and all
  seven event call sites (`main.dart` app_open, `settings_page.dart` rate_tapped and
  feedback_tapped, `timer_notifier.dart` workout_started and three workout_completed) go through
  it. It is the only code that sends to Aptabase, so it now adds `is_test` (0/1) and
  `test_reason` to every event, last, so no event prop can override them. Events fired before
  the full answer is in are held and sent in order. Call sites and event names are unchanged.
- `main.dart` starts both checks and does not wait for either before the first frame. Each is
  capped at 10 s; on timeout the full answer falls back to the local one, else `none`.
- Sentry: the `test_device` tag comes from the local answer; `is_test` and `test_reason` tags
  follow once the full answer is in.
- Start-up line: `[wharfwod] test device: <reason>`.
- `docs/TEST_DEVICES.md`: the HFD table without the RevenueCat column, plus the watch finding.

## Watch and Wear

Neither sends Aptabase events. `ios/WODTimerWatch` has no Aptabase or Sentry import and no
`URLSession` code. The Podfile only gives pods to `Runner` and `RunnerTests`. `android/wear`
has no analytics or network dependency in `build.gradle.kts`, no `java.net` or OkHttp code, and
no `INTERNET` permission in its manifest. Every event comes from the phone app.

## Tests

- Before: 678 passed. After: 691 passed, 0 skipped (13 new).
  - `test/core/infrastructure/telemetry/test_device_detector_test.dart` covers the channel
    mapping (six strings plus an unknown one), no channel or an error, precedence,
    `detectLocal`, `isTest` and the wire names.
  - `test/core/infrastructure/telemetry/telemetry_test.dart` keeps its two gating tests and
    adds: a simulator run flagged on every event the app sends, held events released in order,
    `is_test 0` on a real phone, a failed check counts as `none`, a prop cannot override the
    flag, nothing sent when telemetry is off. A guard test checks that only `telemetry.dart` and
    `main.dart` import Aptabase, only `telemetry.dart` uses `Aptabase.instance`, and `main.dart`
    only calls `Aptabase.init`.
- `fvm flutter analyze`: 0 errors and 0 warnings. It still reports the 126 infos already on
  main (very_good_analysis style infos on older files), none from this change. The repo's own
  bar (CLAUDE.md, the gate's `--no-fatal-infos --fatal-warnings`) is 0 errors and 0 warnings.
- The existing layout and overflow tests (large text, dark theme) are in the 691 and pass.
- `scripts/test_gate.sh` (full, both): green. It ran analyze, the Flutter tests, the watch
  XCTests on the Apple Watch Series 11 simulator and the Wear OS JVM tests. After the
  start-up timing fix below, `--quick` ran green again; that fix touched only `main.dart` and
  the doc.

## Builds and start-up lines

There is no `dart_defines.json` in the shared checkout (secrets come from Doppler via
`scripts/with-secrets.sh`), so both builds ran without defines. Aptabase and Sentry are off in
these builds, but the start-up line prints either way.

- `fvm flutter build apk --release`: `app-release.apk` (57.3MB).
- `fvm flutter build ios --simulator --debug -d 1799E12E-...`: `Runner.app`, watch companion
  included.
- iPhone 16 Plus simulator (1799E12E-8E68-4F24-A59E-51E8D3DCA778):
  `2026-10-24 21:41:13.046 Df Runner[98554:1d5baa6] (Flutter) flutter: [wharfwod] test device: simulator`
- Android `Pixel_Tablet_API_34` on emulator-5592 (`-read-only`), release APK, `am start -W`:
  `10-24 21:38:34.806  6181  6181 I flutter : [wharfwod] test device: emulator`
  (three cold launches, all `emulator`).

## The 2 s cap was too short (deviation from the siblings)

My first emulator run, built the way HFD, Loglet and Churnie do it (await `detectLocal()` with
a 2 s cap before the first frame, then `detect()` with a 5 s cap that falls back to the local
answer), printed `test device: none` on two cold launches (cold start 4.3 s). A probe build
showed why. The channel reply arrives only once the platform thread is free: after 1.4 to
1.7 s on a normal cold start, and past 2 s on a slow one. When the 2 s cap fires, the local
answer becomes `none`. If the full check also misses its 5 s cap, it falls back to that `none`,
and an emulator run's events go out as `is_test = 0`.

The fix here: no wait before the first frame, a 10 s cap on both checks, and the line and
Sentry tag written when the local answer arrives. On Android `detect` is the same instant read,
so analytics get `emulator` even when the first frame is slow. As a side effect, cold start on
the emulator dropped to about 1.5 to 2.7 s.

For the coordinator: Loglet, Churnie and HFD keep the 2 s / 5 s caps. They are worth checking
on a slow cold start. HFD's case is worse, because its 2 s local answer also gates RevenueCat.

## Not done

- No RevenueCat item: Wharf WOD is free.
- Not checked: a real-phone `none` or a TestFlight `sandbox_receipt` answer, because that needs a
  device.
- The emulator snapshot held a newer Wharf WOD (versionCode 12), so the APK went in with
  `install -r -d`. The emulator ran `-read-only`, so nothing persisted.
- `docs/SHIP_REMINDERS.md` is unchanged.
- The merge, the ship and the store records are left to the coordinating session.
