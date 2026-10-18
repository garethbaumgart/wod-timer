# Data safety (no loss on upgrade)

Wharf WOD has no database. The only durable user data is key/value:

| Surface | Store | Production readers |
| --- | --- | --- |
| Phone / tablet | SharedPreferences | `AppSettingsNotifier`, `SetupMemory`, `LiveHints`, `PrefsReviewStore` |
| Apple Watch | UserDefaults (`recent_workouts` JSON, `watch_setup_*`, voice, hint, health) | `RecentWorkoutsStore`, `SetupMemory`, `WatchAudioService`, `TimerViewModel`, `HealthWorkoutTracker` |
| Wear OS | SharedPreferences file `"wharfwod"` | `SetupMemory.decode`, `VoiceSettings`, `TimerViewModel`, `ExerciseTracker` |

Every storage shape that has shipped to the stores has a committed fixture under `test/fixtures/data_safety/`. HEAD must load each one through those real readers without dropping a key or rewriting a value, except the documented 1.3.0 Sound-Effects → Silent migration, which runs **once**.

There is no Drift schema in this app. Skip `drift_dev`.

## Adding a version

1. Bump `version:` in `pubspec.yaml` and `StorageCatalog.currentAppVersion` in `lib/core/persistence/storage_catalog.dart`.
2. Append a `ShippedStorageVersion` on the phone list (and watch / wear if those stores gained keys).
3. Add a fixture directory `test/fixtures/data_safety/{phone,watch,wear}/<version>/` with **that version's** keys, non-default values, and a README naming the commit SHA. Prefer `python3 tool/data_safety/generate_fixtures.py` after extending the catalog in that script.
4. Assert the new fixture in `test/data_safety/` (and XCTest / Wear JUnit when watch or wear keys change).
5. Run `scripts/data_safety_gate.sh`. The guard test fails if the current pubspec version has no phone fixture — its message points here.

Never edit an old fixture to make a test pass. If HEAD cannot read it, that is a data-loss bug: fix the reader, don't rewrite history.

## Running

```
scripts/data_safety_gate.sh          # tagged suite + fail on zero tests
fvm flutter test --tags data-safety  # same tests, default reporter
fvm flutter test                     # full suite; data-safety is not skipped
```
