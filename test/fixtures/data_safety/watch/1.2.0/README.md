# Apple Watch UserDefaults fixture v1.2.0

- App version: 1.2.0
- Commit SHA: `9379e3a7c7d59f32696fdf5c18cf6c74b3238d15`
- Produced by: `python3 tool/data_safety/generate_fixtures.py`
- `recent_workouts.json` is JSONEncoder-shaped `[Workout]` (Date = `timeIntervalSinceReferenceDate` since 2001-01-01 UTC; UUID uppercase). HEAD's `JSONDecoder` + `RecentWorkoutsStore.load` must accept it.

Do not edit this directory to make a test pass.
