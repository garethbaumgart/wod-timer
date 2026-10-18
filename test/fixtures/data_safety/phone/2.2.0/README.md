# Phone SharedPreferences fixture v2.2.0

- App version: 2.2.0
- Commit SHA (keys taken from this tree): `adfc25275bd8d8deb07c6950ff5c9ea72417231f`
- Produced by: `python3 tool/data_safety/generate_fixtures.py`
- Keys at that commit (lib/core/application/providers/app_settings_provider.dart, lib/core/review/review_prompter.dart, lib/features/timer/application/setup/setup_memory.dart, lib/features/timer/application/setup/live_hints.dart):
- `app_orientation_lock`
- `app_haptic_enabled`
- `app_sound_enabled`
- `app_keep_screen_on`
- `app_voice`
- `app_sound_silent_migrated_v130`
- `review_value_moments`
- `review_ask_count`
- `review_last_asked_ms`
- `setup_amrap_duration_s`
- `setup_fortime_cap_s`
- `setup_fortime_count_up`
- `setup_emom_interval_s`
- `setup_emom_rounds`
- `setup_tabata_work_s`
- `setup_tabata_rest_s`
- `setup_tabata_rounds`
- `setup_last_mode`
- `hint_amrap_counted_round`
- `some_plugin_key`

`some_plugin_key` is a foreign value no Wharf WOD build wrote; HEAD must leave it in place.

Do not edit this directory to make a test pass. If HEAD cannot read it, that is a data-loss bug.
