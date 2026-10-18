# Wear OS SharedPreferences fixture v2.2.0-wear

- App version: 2.2.0-wear
- Commit SHA: `190a6e4ee87011f786b982e386bf1068127cc2a0`
- Prefs file name in production: `wharfwod`
- Produced by: `python3 tool/data_safety/generate_fixtures.py`
- Keys at that commit: wear_setup_<amrap|fortime|emom|tabata>, wear_voice_*, wear_health_track, wear_hint_amrap_counted, wear_perm_asked.

Encoded setup strings use that version's `SetupMemory.encode` (`amrap:720`, `fortime:900:0`, `emom:90:12`, `tabata:40:20:6`).

Do not edit this directory to make a test pass.
