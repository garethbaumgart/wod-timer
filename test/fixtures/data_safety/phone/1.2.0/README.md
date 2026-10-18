# Phone SharedPreferences fixture v1.2.0

- App version: 1.2.0
- Commit SHA (keys taken from this tree): `9379e3a7c7d59f32696fdf5c18cf6c74b3238d15`
- Produced by: `python3 tool/data_safety/generate_fixtures.py`
- Keys at that commit (lib/core/application/providers/app_settings_provider.dart, lib/core/review/review_prompter.dart, lib/features/timer/application/setup/setup_memory.dart):
- `app_orientation_lock`
- `app_haptic_enabled`
- `app_sound_enabled`
- `app_keep_screen_on`
- `app_voice`
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
- `some_plugin_key`

`some_plugin_key` is a foreign value no Wharf WOD build wrote; HEAD must leave it in place.

Do not edit this directory to make a test pass. If HEAD cannot read it, that is a data-loss bug.
