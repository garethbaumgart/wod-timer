# Wharf WOD 1.2.1: a Rate row and Flutter 3.47.6

Approved by Gareth 2 Oct 2026. Branch `feat/1.2.1-rate-row`, worktree `~/Source/mentalmetal-worktrees/wharf-121`; the Flutter project is the repo ROOT (no `app/` dir). CRITICAL: codegen is dead on Flutter 3.47 for this repo (riverpod_generator 2.6 crashes) and generated files (`*.g.dart`, `*.freezed.dart`, `injection.config.dart`) are gitignored; they were copied into this worktree from the main checkout. NEVER run build_runner here (its delete step destroys them). If you need a provider, write a plain hand-written `Provider<T>`, not an `@riverpod` annotation.

## Hard rules

- Work only inside this worktree. Never touch the shared checkout under
  `/Users/garethbaumgart/Source/mentalmetal-portfolio/`.
- Use `fvm flutter ...` for every Flutter command.
- No device runs, no simulators, no emulators, no builds, no ships, no `git push`. The
  main session does device checks, builds and releases. Widget and unit tests only.
- Never remove stored data or rename existing prefs keys. Never disable or weaken a
  test to get green.
- Never use the em dash character anywhere: UI copy, comments, commit messages.
- Do not edit `fastlane/` (the main session owns store metadata).
- After each finding: `fvm flutter analyze` must report 0 issues and `fvm flutter test`
  must be all green, then commit.
- Commit format: `1.2.1: F<n> <what changed, in plain words>`, body explains why, last
  line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## F0. Flutter 3.47.6 (Dart 3.13.5)

3.47.6 is installed in the fvm cache. In the Flutter project dir: `fvm use 3.47.6`
(rewrites `.fvmrc`; use `--force` if it prompts), `fvm flutter pub get`, analyze, test.
Leave the `environment: sdk:` constraint alone unless pub refuses. Do not bump packages
beyond what pub forces. Commit `.fvmrc` + lockfile as `1.2.1: F0 Flutter 3.47.6`.

## F1. A "Rate Wharf WOD" row that opens the store's review page

Why: on 6 Sep 2026 the whole portfolio had zero ratings; the automatic `ReviewPrompter`
(in `lib/.../review/review_prompter.dart`) shipped then, but Apple throttles its sheet
and may show nothing, and neither store allows a review button to call the in-app
review API. A user who wants to rate needs a row they can tap.

Behaviour:
- Extend the existing `ReviewRequester` port with `Future<void> openStoreListing()`.
  `StoreReviewRequester` implements it with
  `InAppReview.instance.openStoreListing(appStoreId: '6790209231')` (on iOS this opens
  `apps.apple.com/app/id6790209231?action=write-review`; on Android the Play listing).
  Keep the App Store id in one named constant next to the requester.
- Add `Future<void> openStorePage()` to `ReviewPrompter`: user-initiated, never throws
  (swallow and ignore errors like the rest of the class), does NOT count as one of the
  automatic asks, but writes `lastAskedKey = now` so the automatic sheet does not pop up
  in the days right after the user just visited the store. Update every fake
  `ReviewRequester` in `test/` so the suite compiles.
- Fire a telemetry event `rate_tapped` with `{source: 'settings'}` (or the app's typed
  equivalent, e.g. a `rateTapped()` method) following the app's telemetry idiom.
- Placement: `lib/core/presentation/pages/settings_page.dart`, in the ABOUT section, as the first row above `Send Feedback`, built with the same `_buildTapRow` helper as its neighbours.
- Row copy: `Rate Wharf WOD`. Leading icon `Icons.star_outline_rounded` if the neighbouring
  rows use leading icons; otherwise match the neighbours exactly (no icon). No subtitle
  unless the neighbours have one. Large text (1.6x at 375 pt wide) and dark mode must
  not overflow; run the existing overflow tests.

Tests: the row renders where specified; tapping it calls the fake requester's
`openStoreListing` exactly once and records the telemetry event if the app's telemetry
is fakeable; it never calls `request()` (the automatic sheet); `openStorePage` swallows
a throwing requester.

## F2. Version

`pubspec.yaml` version `1.2.1+1`. Commit as `1.2.1: F2 version 1.2.1`.

## Handoff report (final message)

One line per finding (commit hash, what changed, test count before and after), any
deviation from the plan with the reason, and what the main session should look at on a
device.
