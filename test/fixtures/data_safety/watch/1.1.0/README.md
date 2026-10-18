# Apple Watch UserDefaults fixture v1.1.0

- App version: 1.1.0
- Commit SHA: `3876b5bf597cc99732c2be575af79a6b71495373`
- Produced by: `python3 tool/data_safety/generate_fixtures.py`
- `recent_workouts.json` is JSONEncoder-shaped `[Workout]` (Date = `timeIntervalSinceReferenceDate` since 2001-01-01 UTC; UUID uppercase). HEAD's `JSONDecoder` + `RecentWorkoutsStore.load` must accept it.

Do not edit this directory to make a test pass.
