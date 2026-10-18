# Phone SharedPreferences fixture v1.1.3

- App version: 1.1.3
- Commit SHA (keys taken from this tree): `b5bba49280726fc83d24a95830f333f0936abfc5`
- Produced by: `python3 tool/data_safety/generate_fixtures.py`
- Keys at that commit (lib/core/application/providers/app_settings_provider.dart, lib/core/review/review_prompter.dart):
- `app_orientation_lock`
- `app_haptic_enabled`
- `app_sound_enabled`
- `app_keep_screen_on`
- `app_voice`
- `review_value_moments`
- `review_ask_count`
- `review_last_asked_ms`
- `some_plugin_key`

`some_plugin_key` is a foreign value no Wharf WOD build wrote; HEAD must leave it in place.

Do not edit this directory to make a test pass. If HEAD cannot read it, that is a data-loss bug.
