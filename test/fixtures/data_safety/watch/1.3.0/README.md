# Apple Watch UserDefaults fixture v1.3.0

- App version: 1.3.0
- Commit SHA: `15387695a5eba63e2e3d3da28cd88499ec9f5a87`
- Produced by: `python3 tool/data_safety/generate_fixtures.py`
- `recent_workouts.json` is JSONEncoder-shaped `[Workout]` (Date = `timeIntervalSinceReferenceDate` since 2001-01-01 UTC; UUID uppercase). HEAD's `JSONDecoder` + `RecentWorkoutsStore.load` must accept it.

Do not edit this directory to make a test pass.
