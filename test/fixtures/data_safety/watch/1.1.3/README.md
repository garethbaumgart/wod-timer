# Apple Watch UserDefaults fixture v1.1.3

- App version: 1.1.3
- Commit SHA: `b5bba49280726fc83d24a95830f333f0936abfc5`
- Produced by: `python3 tool/data_safety/generate_fixtures.py`
- `recent_workouts.json` is JSONEncoder-shaped `[Workout]` (Date = `timeIntervalSinceReferenceDate` since 2001-01-01 UTC; UUID uppercase). HEAD's `JSONDecoder` + `RecentWorkoutsStore.load` must accept it.

Do not edit this directory to make a test pass.
