# Apple Watch UserDefaults fixture v2.1.0

- App version: 2.1.0
- Commit SHA: `96c5a86b63841966184d45b38089418eaf72cd77`
- Produced by: `python3 tool/data_safety/generate_fixtures.py`
- `recent_workouts.json` is JSONEncoder-shaped `[Workout]` (Date = `timeIntervalSinceReferenceDate` since 2001-01-01 UTC; UUID uppercase). HEAD's `JSONDecoder` + `RecentWorkoutsStore.load` must accept it.
- `setup_*.json` is JSONEncoder-shaped `TimerType` for `watch_setup_<code>` (2.0.0+).
- `prefs.json` holds additive UserDefaults scalars (`watch_voice_*`, hint, health).

Do not edit this directory to make a test pass.
