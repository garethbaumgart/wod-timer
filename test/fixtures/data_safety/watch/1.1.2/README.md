# Apple Watch UserDefaults fixture v1.1.2

- App version: 1.1.2
- Commit SHA: `c0ffb0a5f772a0dd9efe6df93ff59f695e4ba1f7`
- Produced by: `python3 tool/data_safety/generate_fixtures.py`
- `recent_workouts.json` is JSONEncoder-shaped `[Workout]` (Date = `timeIntervalSinceReferenceDate` since 2001-01-01 UTC; UUID uppercase). HEAD's `JSONDecoder` + `RecentWorkoutsStore.load` must accept it.

Do not edit this directory to make a test pass.
