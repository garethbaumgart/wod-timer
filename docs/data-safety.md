# Data safety (no loss on upgrade)

Wharf WOD has no database. The only durable user data is key/value:

| Surface | Store | Production readers |
| --- | --- | --- |
| Phone / tablet | SharedPreferences | `AppSettingsNotifier`, `SetupMemory`, `LiveHints`, `PrefsReviewStore` |
| Apple Watch | UserDefaults (`recent_workouts` JSON, `watch_setup_*`, voice, hint, health) | `RecentWorkoutsStore`, `SetupMemory`, `WatchAudioService`, `TimerViewModel`, `HealthWorkoutTracker` |
| Wear OS | SharedPreferences file `"wharfwod"` | `SetupMemory.decode`, `VoiceSettings`, `TimerViewModel`, `ExerciseTracker` |

Every storage shape that has shipped to the stores has a committed fixture under `test/fixtures/data_safety/`. HEAD must load each one through those real readers without dropping a key or rewriting a value, except the documented 1.3.0 Sound-Effects → Silent migration, which runs **once**.

The release guard is a **storage-shape** check, not a pubspec version check. `scripts/ship.sh` bumps `version:` *after* the test gate, so requiring `pubspec.yaml` to equal a catalog version would fail the next ship and every subsequent `flutter test` on main with no storage change. HEAD's SharedPreferences keys and types are discovered by scanning every non-generated `lib/**/*.dart` file for prefs get/set calls and the const strings those calls use — not a hand-kept list and not a single writer file. Watch / Wear payload shapes are scanned from the companion sources. HEAD must equal the **newest** committed fixture. A new or changed key in any `lib/` file (including a brand-new file) without a new fixture directory fails.

`test/fixtures/data_safety/MANIFEST.sha256` checksums every fixture file. Editing or deleting an old fixture without updating the manifest fails. Never edit an old fixture to make a test pass.

There is no Drift schema in this app. Skip `drift_dev`.

`StorageCatalog` lives in `test/data_safety/storage_catalog.dart` (test-only).

## Adding a version

1. Bump `version:` in `pubspec.yaml` when you actually ship. Do **not** add a fixture just because the marketing version changed.
2. If HEAD gained or changed a persisted key, type, or watch/Wear payload shape, append a `ShippedStorageVersion` on the affected list in `test/data_safety/storage_catalog.dart` and add a **new** fixture directory `test/fixtures/data_safety/{phone,watch,wear}/<version>/`. Prefer `python3 tool/data_safety/generate_fixtures.py` after extending the key lists in that script (it rewrites `MANIFEST.sha256`).
3. Assert the new fixture in `test/data_safety/` (and XCTest / Wear JUnit when watch or wear keys change).
4. Run `scripts/data_safety_gate.sh`. The guard fails if HEAD's shape is not exactly the newest fixture, if a catalog SHA's source keys drifted, or if an old fixture's checksum changed.

Never edit an old fixture to make a test pass. If HEAD cannot read it, that is a data-loss bug: fix the reader, don't rewrite history.

## Fixture provenance

Phone fixture *values* are synthesized (non-default, unicode/RTL on the foreign plugin key). The *key set and types* are proven two ways:

1. `tool/data_safety/verify_fixtures.py` `git show`s persistence sources at each catalog SHA and requires those key literals to equal the fixture (minus `some_plugin_key`).
2. `tool/data_safety/capture_phone_worktree.py` checks out each SHA in a worktree, runs `build_runner` on **Flutter 3.44.9**, then invokes that tag's real `AppSettingsNotifier` / `SetupMemory` / `LiveHints` / `PrefsReviewStore` writers. The resulting key→type map must match the fixture. This does not work on the FVM pin (3.47.7): `build_runner` hangs (`analyzer` 7.6.0 missing `visitDotShorthandPropertyAccess`).

HEAD writers are also run in `phone_prefs_test.dart` against `SharedPreferences.setMockInitialValues`.

Watch JSON follows Swift `JSONEncoder` (`Date` = `timeIntervalSinceReferenceDate` since 2001-01-01 UTC; UUID uppercase). Wear strings are that version's `SetupMemory.encode`. The committed fixtures are not rewritten by the worktree capture.

## Code generation

`dart run build_runner` hangs on the FVM pin (Flutter 3.47.7 / Dart 3.13.5) because `riverpod_generator` 2.6 pulls `analyzer` 7.6.0, which cannot visit Dart 3.13 dot shorthands. Generated `*.g.dart`, `*.freezed.dart`, and `lib/injection.config.dart` are committed so `flutter analyze`, `flutter test`, and `scripts/data_safety_gate.sh` run from a clean checkout without codegen.

Do **not** run `build_runner` on 3.47.7 (including CI `pr-check.yml` Analyze & Test and `deploy-testflight.yml`). Codegen runs on **Flutter 3.44.9 / Dart 3.12.2**. Re-run and commit whenever `@Riverpod` / `@freezed` / `@injectable` sources change:

```
/path/to/flutter-3.44.9/bin/dart run build_runner build --delete-conflicting-outputs
# restore pubspec.lock if 3.44.9 rewrote it, then fvm flutter pub get
python3 tool/data_safety/compare_generated.py
```

CI job **Generated files up to date** in `.github/workflows/pr-check.yml` installs Flutter 3.44.9, regenerates, and fails on a real diff. Registration-order-only changes in `lib/injection.config.dart` (`gh.factory` / `gh.lazySingleton` shuffled) are ignored; alias renumbering (`as _i174` vs `as _i200`) and added/removed registrations fail.

## Running

```
scripts/data_safety_gate.sh          # tagged suite + fail on zero tests
fvm flutter test --tags data-safety  # same tests, default reporter
fvm flutter test                     # full suite; data-safety is not skipped
python3 tool/data_safety/verify_fixtures.py
```
