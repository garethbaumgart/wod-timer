# Apple Watch UserDefaults fixture v2.0.0

- App version: 2.0.0
- Commit SHA: `eac3086474735f719c61049f89e60b035451a9ff`
- Produced by: `python3 tool/data_safety/generate_fixtures.py`
- `recent_workouts.json` is JSONEncoder-shaped `[Workout]` (Date = `timeIntervalSinceReferenceDate` since 2001-01-01 UTC; UUID uppercase). HEAD's `JSONDecoder` + `RecentWorkoutsStore.load` must accept it.
- `setup_*.json` is JSONEncoder-shaped `TimerType` for `watch_setup_<code>` (2.0.0+).
- `prefs.json` holds additive UserDefaults scalars (`watch_voice_*`, hint, health).

Do not edit this directory to make a test pass.
