# Apple Watch UserDefaults fixture v2.2.1

- App version: 2.2.1
- Commit SHA: `998f9e3b81597e228376ed31784a815e209a3591`
- Produced by: `python3 tool/data_safety/generate_fixtures.py`
- `recent_workouts.json` is JSONEncoder-shaped `[Workout]` (Date = `timeIntervalSinceReferenceDate` since 2001-01-01 UTC; UUID uppercase). HEAD's `JSONDecoder` + `RecentWorkoutsStore.load` must accept it.
- `setup_*.json` is JSONEncoder-shaped `TimerType` for `watch_setup_<code>` (2.0.0+).
- `prefs.json` holds additive UserDefaults scalars (`watch_voice_*`, hint, health).

Do not edit this directory to make a test pass.
