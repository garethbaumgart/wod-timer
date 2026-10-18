# Data safety (no loss on upgrade)

Wharf WOD has no database. The only durable user data is key/value:

| Surface | Store | Production readers |
| --- | --- | --- |
| Phone / tablet | SharedPreferences | `AppSettingsNotifier`, `SetupMemory`, `LiveHints`, `PrefsReviewStore` |
| Apple Watch | UserDefaults (`recent_workouts` JSON, `watch_setup_*`, voice, hint, health) | `RecentWorkoutsStore`, `SetupMemory`, `WatchAudioService`, `TimerViewModel`, `HealthWorkoutTracker` |
| Wear OS | SharedPreferences file `"wharfwod"` | `SetupMemory.decode`, `VoiceSettings`, `TimerViewModel`, `ExerciseTracker` |

Every storage shape that has shipped to the stores has a committed fixture under `test/fixtures/data_safety/`. HEAD must load each one through those real readers without dropping a key or rewriting a value, except the documented 1.3.0 Sound-Effects → Silent migration, which runs **once**.

The release guard is a **storage-shape** check, not a pubspec version check. `scripts/ship.sh` bumps `version:` *after* the test gate, so requiring `pubspec.yaml` to equal a catalog version would fail the next ship and every subsequent `flutter test` on main with no storage change. HEAD's SharedPreferences keys and types (and watch / Wear payload shapes) must equal the **newest** committed fixture. A new or changed key without a new fixture directory fails.

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

Phone fixtures are synthesized from the key literals at each shipped SHA (`git show <sha>:<file>`), with non-default values. `tool/data_safety/verify_fixtures.py` re-extracts those literals at every catalog commit and requires them to equal the fixture key set (minus the foreign `some_plugin_key`).

Running the real shipped Dart writers *at each old tag* in a worktree is not feasible on this toolchain (see `tool/data_safety/capture_phone_worktree.py`): generated `*.g.dart` files were not in git, `AppSettingsNotifier` needs `riverpod_generator`, and `build_runner` hangs on Flutter 3.47.7 (`analyzer` 7.6.0 missing `visitDotShorthandPropertyAccess`). HEAD's writers **are** run in `phone_prefs_test.dart` against `SharedPreferences.setMockInitialValues`.

Watch JSON follows Swift `JSONEncoder` (`Date` = `timeIntervalSinceReferenceDate` since 2001-01-01 UTC; UUID uppercase). Wear strings are that version's `SetupMemory.encode`.

## Code generation

`dart run build_runner` hangs on the FVM pin (Flutter 3.47.7 / Dart 3.13.5) because `riverpod_generator` 2.6 pulls `analyzer` 7.6.0, which cannot visit Dart 3.13 dot shorthands. Generated `*.g.dart`, `*.freezed.dart`, and `lib/injection.config.dart` are committed so `flutter analyze`, `flutter test`, and `scripts/data_safety_gate.sh` run from a clean checkout without codegen. Do not add a CI `build_runner` step on 3.47.7.

## Running

```
scripts/data_safety_gate.sh          # tagged suite + fail on zero tests
fvm flutter test --tags data-safety  # same tests, default reporter
fvm flutter test                     # full suite; data-safety is not skipped
python3 tool/data_safety/verify_fixtures.py
```
