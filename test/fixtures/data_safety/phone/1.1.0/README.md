# Phone SharedPreferences fixture v1.1.0

- App version: 1.1.0
- Commit SHA (keys taken from this tree): `3876b5bf597cc99732c2be575af79a6b71495373`
- Produced by: `python3 tool/data_safety/generate_fixtures.py`
- Keys at that commit (lib/core/application/providers/app_settings_provider.dart):
- `app_orientation_lock`
- `app_haptic_enabled`
- `app_sound_enabled`
- `app_keep_screen_on`
- `app_voice`
- `some_plugin_key`

`some_plugin_key` is a foreign value no Wharf WOD build wrote; HEAD must leave it in place.

Do not edit this directory to make a test pass. If HEAD cannot read it, that is a data-loss bug.
