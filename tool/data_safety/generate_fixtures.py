#!/usr/bin/env python3
"""Write committed data-safety fixtures from each shipped version's keys.

Keys were read from that version's source (`git show <sha>:<file>`), not from
HEAD, and `tool/data_safety/verify_fixtures.py` re-checks those literals at
every catalog SHA. Re-run:

    python3 tool/data_safety/generate_fixtures.py

Never edit an old fixture by hand to make a test pass — change HEAD's
readers or add a new version directory.
"""

from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "test" / "fixtures" / "data_safety"

# A key no build of ours wrote. Every surface must leave it alone.
FOREIGN = 'keep me — «Gareth» 💪\nעברית العربية "quotes"'

APPLE_EPOCH = datetime(2001, 1, 1, tzinfo=timezone.utc)


def apple_ref(iso: str) -> float:
    dt = datetime.fromisoformat(iso).replace(tzinfo=timezone.utc)
    return (dt - APPLE_EPOCH).total_seconds()


def typed(kind: str, value: object) -> dict:
    return {kind: value}


def dump(path: Path, obj: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(obj, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def write_readme(path: Path, body: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(body.strip() + "\n", encoding="utf-8")


# --- Phone SharedPreferences -------------------------------------------------

PHONE = [
    {
        "version": "1.1.0",
        "sha": "3876b5bf597cc99732c2be575af79a6b71495373",
        "keys_from": [
            "lib/core/application/providers/app_settings_provider.dart",
        ],
        "keys": {
            "app_orientation_lock": typed("int", 1),  # portrait
            "app_haptic_enabled": typed("bool", False),
            "app_sound_enabled": typed("bool", True),
            "app_keep_screen_on": typed("bool", False),
            "app_voice": typed("int", 1),  # liam
            "some_plugin_key": typed("string", FOREIGN),
        },
        "expect": {
            "orientationLock": "portrait",
            "hapticEnabled": False,
            "soundEnabled": True,
            "keepScreenOn": False,
            "voice": "liam",
            "voiceIndexAfterLoad": 1,
            "silentMigratedAfterLoad": True,
            "amrapDurationSeconds": 600,
            "forTimeCapSeconds": 1200,
            "forTimeCountUp": True,
            "emomIntervalSeconds": 60,
            "emomRounds": 10,
            "tabataWorkSeconds": 20,
            "tabataRestSeconds": 10,
            "tabataRounds": 8,
            "lastMode": "fortime",
            "hasCountedRound": False,
            "reviewMoments": 0,
            "reviewAsks": 0,
            "reviewLastAskedMs": 0,
        },
    },
    {
        "version": "1.1.2",
        "sha": "c0ffb0a5f772a0dd9efe6df93ff59f695e4ba1f7",
        "keys_from": [
            "lib/core/application/providers/app_settings_provider.dart",
        ],
        "keys": {
            "app_orientation_lock": typed("int", 2),  # landscape
            "app_haptic_enabled": typed("bool", True),
            "app_sound_enabled": typed("bool", False),  # 1.3.0 migrates once
            "app_keep_screen_on": typed("bool", True),
            "app_voice": typed("int", 2),  # holly, rewritten to silent
            "some_plugin_key": typed("string", FOREIGN),
        },
        "expect": {
            "orientationLock": "landscape",
            "hapticEnabled": True,
            "soundEnabled": False,
            "keepScreenOn": True,
            "voice": "silent",
            "voiceIndexAfterLoad": 5,
            "silentMigratedAfterLoad": True,
            "amrapDurationSeconds": 600,
            "forTimeCapSeconds": 1200,
            "forTimeCountUp": True,
            "emomIntervalSeconds": 60,
            "emomRounds": 10,
            "tabataWorkSeconds": 20,
            "tabataRestSeconds": 10,
            "tabataRounds": 8,
            "lastMode": "fortime",
            "hasCountedRound": False,
            "reviewMoments": 0,
            "reviewAsks": 0,
            "reviewLastAskedMs": 0,
        },
    },
    {
        "version": "1.1.3",
        "sha": "b5bba49280726fc83d24a95830f333f0936abfc5",
        "keys_from": [
            "lib/core/application/providers/app_settings_provider.dart",
            "lib/core/review/review_prompter.dart",
        ],
        "keys": {
            "app_orientation_lock": typed("int", 0),  # auto
            "app_haptic_enabled": typed("bool", False),
            "app_sound_enabled": typed("bool", True),
            "app_keep_screen_on": typed("bool", False),
            "app_voice": typed("int", 3),  # random
            "review_value_moments": typed("int", 7),
            "review_ask_count": typed("int", 1),
            "review_last_asked_ms": typed("int", 1790000000000),
            "some_plugin_key": typed("string", FOREIGN),
        },
        "expect": {
            "orientationLock": "auto",
            "hapticEnabled": False,
            "soundEnabled": True,
            "keepScreenOn": False,
            "voice": "random",
            "voiceIndexAfterLoad": 3,
            "silentMigratedAfterLoad": True,
            "amrapDurationSeconds": 600,
            "forTimeCapSeconds": 1200,
            "forTimeCountUp": True,
            "emomIntervalSeconds": 60,
            "emomRounds": 10,
            "tabataWorkSeconds": 20,
            "tabataRestSeconds": 10,
            "tabataRounds": 8,
            "lastMode": "fortime",
            "hasCountedRound": False,
            "reviewMoments": 7,
            "reviewAsks": 1,
            "reviewLastAskedMs": 1790000000000,
        },
    },
    {
        "version": "1.2.0",
        "sha": "9379e3a7c7d59f32696fdf5c18cf6c74b3238d15",
        "keys_from": [
            "lib/core/application/providers/app_settings_provider.dart",
            "lib/core/review/review_prompter.dart",
            "lib/features/timer/application/setup/setup_memory.dart",
        ],
        "keys": {
            "app_orientation_lock": typed("int", 1),
            "app_haptic_enabled": typed("bool", False),
            "app_sound_enabled": typed("bool", True),
            "app_keep_screen_on": typed("bool", False),
            "app_voice": typed("int", 4),  # off (last index at 1.2.x)
            "review_value_moments": typed("int", 3),
            "review_ask_count": typed("int", 2),
            "review_last_asked_ms": typed("int", 1726531200000),
            "setup_amrap_duration_s": typed("int", 60),  # min
            "setup_fortime_cap_s": typed("int", 3600),  # max
            "setup_fortime_count_up": typed("bool", False),
            "setup_emom_interval_s": typed("int", 15),  # min
            "setup_emom_rounds": typed("int", 30),  # max
            "setup_tabata_work_s": typed("int", 5),  # min
            "setup_tabata_rest_s": typed("int", 120),  # max
            "setup_tabata_rounds": typed("int", 1),  # min
            "some_plugin_key": typed("string", FOREIGN),
        },
        "expect": {
            "orientationLock": "portrait",
            "hapticEnabled": False,
            "soundEnabled": True,
            "keepScreenOn": False,
            "voice": "off",
            "voiceIndexAfterLoad": 4,
            "silentMigratedAfterLoad": True,
            "amrapDurationSeconds": 60,
            "forTimeCapSeconds": 3600,
            "forTimeCountUp": False,
            "emomIntervalSeconds": 15,
            "emomRounds": 30,
            "tabataWorkSeconds": 5,
            "tabataRestSeconds": 120,
            "tabataRounds": 1,
            "lastMode": "fortime",
            "hasCountedRound": False,
            "reviewMoments": 3,
            "reviewAsks": 2,
            "reviewLastAskedMs": 1726531200000,
        },
    },
    {
        "version": "1.3.0",
        "sha": "15387695a5eba63e2e3d3da28cd88499ec9f5a87",
        "keys_from": [
            "lib/core/application/providers/app_settings_provider.dart",
            "lib/core/review/review_prompter.dart",
            "lib/features/timer/application/setup/setup_memory.dart",
            "lib/features/timer/application/setup/live_hints.dart",
        ],
        "keys": {
            "app_orientation_lock": typed("int", 2),
            "app_haptic_enabled": typed("bool", False),
            "app_sound_enabled": typed("bool", False),
            "app_keep_screen_on": typed("bool", False),
            "app_voice": typed("int", 5),  # silent
            "app_sound_silent_migrated_v130": typed("bool", True),
            "review_value_moments": typed("int", 9),
            "review_ask_count": typed("int", 3),
            "review_last_asked_ms": typed("int", 1730000000000),
            "setup_amrap_duration_s": typed("int", 720),
            "setup_fortime_cap_s": typed("int", 900),
            "setup_fortime_count_up": typed("bool", False),
            "setup_emom_interval_s": typed("int", 90),
            "setup_emom_rounds": typed("int", 12),
            "setup_tabata_work_s": typed("int", 40),
            "setup_tabata_rest_s": typed("int", 20),
            "setup_tabata_rounds": typed("int", 6),
            "hint_amrap_counted_round": typed("bool", True),
            "some_plugin_key": typed("string", FOREIGN),
        },
        "expect": {
            "orientationLock": "landscape",
            "hapticEnabled": False,
            "soundEnabled": False,
            "keepScreenOn": False,
            "voice": "silent",
            "voiceIndexAfterLoad": 5,
            "silentMigratedAfterLoad": True,
            "amrapDurationSeconds": 720,
            "forTimeCapSeconds": 900,
            "forTimeCountUp": False,
            "emomIntervalSeconds": 90,
            "emomRounds": 12,
            "tabataWorkSeconds": 40,
            "tabataRestSeconds": 20,
            "tabataRounds": 6,
            "lastMode": "fortime",
            "hasCountedRound": True,
            "reviewMoments": 9,
            "reviewAsks": 3,
            "reviewLastAskedMs": 1730000000000,
        },
    },
    {
        "version": "2.0.0",
        "sha": "eac3086474735f719c61049f89e60b035451a9ff",
        "keys_from": [
            "lib/core/application/providers/app_settings_provider.dart",
            "lib/core/review/review_prompter.dart",
            "lib/features/timer/application/setup/setup_memory.dart",
            "lib/features/timer/application/setup/live_hints.dart",
        ],
        "keys": {
            "app_orientation_lock": typed("int", 0),
            "app_haptic_enabled": typed("bool", False),
            "app_sound_enabled": typed("bool", False),
            "app_keep_screen_on": typed("bool", False),
            "app_voice": typed("int", 0),  # major, must stick
            "app_sound_silent_migrated_v130": typed("bool", True),
            "review_value_moments": typed("int", 4),
            "review_ask_count": typed("int", 0),
            "review_last_asked_ms": typed("int", 0),
            "setup_amrap_duration_s": typed("int", 1800),
            "setup_fortime_cap_s": typed("int", 600),
            "setup_fortime_count_up": typed("bool", True),
            "setup_emom_interval_s": typed("int", 45),
            "setup_emom_rounds": typed("int", 20),
            "setup_tabata_work_s": typed("int", 30),
            "setup_tabata_rest_s": typed("int", 15),
            "setup_tabata_rounds": typed("int", 10),
            "setup_last_mode": typed("string", "amrap"),
            "hint_amrap_counted_round": typed("bool", False),
            "some_plugin_key": typed("string", FOREIGN),
        },
        "expect": {
            "orientationLock": "auto",
            "hapticEnabled": False,
            "soundEnabled": False,
            "keepScreenOn": False,
            "voice": "major",
            "voiceIndexAfterLoad": 0,
            "silentMigratedAfterLoad": True,
            "amrapDurationSeconds": 1800,
            "forTimeCapSeconds": 600,
            "forTimeCountUp": True,
            "emomIntervalSeconds": 45,
            "emomRounds": 20,
            "tabataWorkSeconds": 30,
            "tabataRestSeconds": 15,
            "tabataRounds": 10,
            "lastMode": "amrap",
            "hasCountedRound": False,
            "reviewMoments": 4,
            "reviewAsks": 0,
            "reviewLastAskedMs": 0,
        },
    },
    {
        "version": "2.1.0",
        "sha": "96c5a86b63841966184d45b38089418eaf72cd77",
        "keys_from": [
            "lib/core/application/providers/app_settings_provider.dart",
            "lib/core/review/review_prompter.dart",
            "lib/features/timer/application/setup/setup_memory.dart",
            "lib/features/timer/application/setup/live_hints.dart",
        ],
        "keys": {
            "app_orientation_lock": typed("int", 1),
            "app_haptic_enabled": typed("bool", True),
            "app_sound_enabled": typed("bool", True),
            "app_keep_screen_on": typed("bool", False),
            "app_voice": typed("int", 2),  # holly
            "app_sound_silent_migrated_v130": typed("bool", True),
            "review_value_moments": typed("int", 12),
            "review_ask_count": typed("int", 1),
            "review_last_asked_ms": typed("int", 1740000000000),
            "setup_amrap_duration_s": typed("int", 900),
            "setup_fortime_cap_s": typed("int", 1500),
            "setup_fortime_count_up": typed("bool", False),
            "setup_emom_interval_s": typed("int", 75),
            "setup_emom_rounds": typed("int", 8),
            "setup_tabata_work_s": typed("int", 25),
            "setup_tabata_rest_s": typed("int", 10),
            "setup_tabata_rounds": typed("int", 8),
            "setup_last_mode": typed("string", "fortime"),
            "hint_amrap_counted_round": typed("bool", True),
            "some_plugin_key": typed("string", FOREIGN),
        },
        "expect": {
            "orientationLock": "portrait",
            "hapticEnabled": True,
            "soundEnabled": True,
            "keepScreenOn": False,
            "voice": "holly",
            "voiceIndexAfterLoad": 2,
            "silentMigratedAfterLoad": True,
            "amrapDurationSeconds": 900,
            "forTimeCapSeconds": 1500,
            "forTimeCountUp": False,
            "emomIntervalSeconds": 75,
            "emomRounds": 8,
            "tabataWorkSeconds": 25,
            "tabataRestSeconds": 10,
            "tabataRounds": 8,
            "lastMode": "fortime",
            "hasCountedRound": True,
            "reviewMoments": 12,
            "reviewAsks": 1,
            "reviewLastAskedMs": 1740000000000,
        },
    },
    {
        "version": "2.2.0",
        "sha": "adfc25275bd8d8deb07c6950ff5c9ea72417231f",
        "keys_from": [
            "lib/core/application/providers/app_settings_provider.dart",
            "lib/core/review/review_prompter.dart",
            "lib/features/timer/application/setup/setup_memory.dart",
            "lib/features/timer/application/setup/live_hints.dart",
        ],
        "keys": {
            "app_orientation_lock": typed("int", 2),
            "app_haptic_enabled": typed("bool", False),
            "app_sound_enabled": typed("bool", True),
            "app_keep_screen_on": typed("bool", False),
            "app_voice": typed("int", 3),  # random
            "app_sound_silent_migrated_v130": typed("bool", True),
            "review_value_moments": typed("int", 5),
            "review_ask_count": typed("int", 2),
            "review_last_asked_ms": typed("int", 1750000000000),
            "setup_amrap_duration_s": typed("int", 1200),
            "setup_fortime_cap_s": typed("int", 480),
            "setup_fortime_count_up": typed("bool", True),
            "setup_emom_interval_s": typed("int", 120),
            "setup_emom_rounds": typed("int", 5),
            "setup_tabata_work_s": typed("int", 20),
            "setup_tabata_rest_s": typed("int", 10),
            "setup_tabata_rounds": typed("int", 16),
            "setup_last_mode": typed("string", "tabata"),
            "hint_amrap_counted_round": typed("bool", True),
            "some_plugin_key": typed("string", FOREIGN),
        },
        "expect": {
            "orientationLock": "landscape",
            "hapticEnabled": False,
            "soundEnabled": True,
            "keepScreenOn": False,
            "voice": "random",
            "voiceIndexAfterLoad": 3,
            "silentMigratedAfterLoad": True,
            "amrapDurationSeconds": 1200,
            "forTimeCapSeconds": 480,
            "forTimeCountUp": True,
            "emomIntervalSeconds": 120,
            "emomRounds": 5,
            "tabataWorkSeconds": 20,
            "tabataRestSeconds": 10,
            "tabataRounds": 16,
            "lastMode": "tabata",
            "hasCountedRound": True,
            "reviewMoments": 5,
            "reviewAsks": 2,
            "reviewLastAskedMs": 1750000000000,
        },
    },
    {
        "version": "2.2.1",
        "sha": "998f9e3b81597e228376ed31784a815e209a3591",
        "keys_from": [
            "lib/core/application/providers/app_settings_provider.dart",
            "lib/core/review/review_prompter.dart",
            "lib/features/timer/application/setup/setup_memory.dart",
            "lib/features/timer/application/setup/live_hints.dart",
        ],
        "keys": {
            "app_orientation_lock": typed("int", 0),
            "app_haptic_enabled": typed("bool", False),
            "app_sound_enabled": typed("bool", True),
            "app_keep_screen_on": typed("bool", False),
            "app_voice": typed("int", 4),  # off / beeps only
            "app_sound_silent_migrated_v130": typed("bool", True),
            "review_value_moments": typed("int", 8),
            "review_ask_count": typed("int", 1),
            "review_last_asked_ms": typed("int", 1760000000000),
            "setup_amrap_duration_s": typed("int", 2400),
            "setup_fortime_cap_s": typed("int", 720),
            "setup_fortime_count_up": typed("bool", False),
            "setup_emom_interval_s": typed("int", 150),
            "setup_emom_rounds": typed("int", 16),
            "setup_tabata_work_s": typed("int", 50),
            "setup_tabata_rest_s": typed("int", 25),
            "setup_tabata_rounds": typed("int", 4),
            "setup_last_mode": typed("string", "emom"),
            "hint_amrap_counted_round": typed("bool", False),
            "some_plugin_key": typed("string", FOREIGN),
        },
        "expect": {
            "orientationLock": "auto",
            "hapticEnabled": False,
            "soundEnabled": True,
            "keepScreenOn": False,
            "voice": "off",
            "voiceIndexAfterLoad": 4,
            "silentMigratedAfterLoad": True,
            "amrapDurationSeconds": 2400,
            "forTimeCapSeconds": 720,
            "forTimeCountUp": False,
            "emomIntervalSeconds": 150,
            "emomRounds": 16,
            "tabataWorkSeconds": 50,
            "tabataRestSeconds": 25,
            "tabataRounds": 4,
            "lastMode": "emom",
            "hasCountedRound": False,
            "reviewMoments": 8,
            "reviewAsks": 1,
            "reviewLastAskedMs": 1760000000000,
        },
    },
]


def amrap(seconds: int) -> dict:
    return {"amrap": {"duration": {"seconds": seconds}}}


def fortime(seconds: int, count_up: bool) -> dict:
    return {"forTime": {"timeCap": {"seconds": seconds}, "countUp": count_up}}


def emom(seconds: int, rounds: int) -> dict:
    return {
        "emom": {
            "intervalDuration": {"seconds": seconds},
            "rounds": {"value": rounds},
        }
    }


def tabata(work: int, rest: int, rounds: int) -> dict:
    return {
        "tabata": {
            "workDuration": {"seconds": work},
            "restDuration": {"seconds": rest},
            "rounds": {"value": rounds},
        }
    }


def workout(uid: str, name: str, timer_type: dict, prep: int, created: float) -> dict:
    return {
        "id": uid,
        "name": name,
        "timerType": timer_type,
        "prepCountdown": {"seconds": prep},
        "createdAt": created,
    }


# Swift JSONEncoder default Date = timeIntervalSinceReferenceDate.
CREATED_OLD = apple_ref("2026-07-14T06:00:00")
CREATED_MID = apple_ref("2026-10-01T12:00:00")
CREATED_NEW = apple_ref("2026-10-16T18:00:00")

UIDS = [
    "A1B2C3D4-E5F6-4789-A012-3456789ABCDE",
    "B2C3D4E5-F6A7-4890-B123-456789ABCDEF",
    "C3D4E5F6-A7B8-4901-C234-56789ABCDEF0",
]

# Unicode / RTL / quotes / newline in the only free-text field (workout name).
NAME_AMRAP = "AMRAP 💪 «Fran»\nsecond line"
NAME_FORTIME = "للوقت — For Time"
NAME_EMOM = "EMOM 90s × 12 — Gareth's “wod”"
NAME_TABATA = "Tabata «quotes» & rest"

WATCH = [
    {
        "version": "1.1.0",
        "sha": "3876b5bf597cc99732c2be575af79a6b71495373",
        "has_setup": False,
        "has_voice": False,
        "has_health": False,
        "recents": [
            workout(UIDS[0], NAME_AMRAP, amrap(720), 10, CREATED_OLD),
            workout(UIDS[1], NAME_FORTIME, fortime(900, False), 0, CREATED_MID),
            workout(UIDS[2], NAME_EMOM, emom(90, 12), 10, CREATED_NEW),
        ],
        "expect": {
            "workouts": [
                {"id": UIDS[0], "name": NAME_AMRAP, "code": "amrap", "seconds": 720, "prep": 10},
                {"id": UIDS[1], "name": NAME_FORTIME, "code": "fortime", "cap": 900, "countUp": False, "prep": 0},
                {"id": UIDS[2], "name": NAME_EMOM, "code": "emom", "interval": 90, "rounds": 12, "prep": 10},
            ]
        },
    },
    {
        "version": "1.1.2",
        "sha": "c0ffb0a5f772a0dd9efe6df93ff59f695e4ba1f7",
        "has_setup": False,
        "has_voice": False,
        "has_health": False,
        "recents": [
            workout(UIDS[0], NAME_TABATA, tabata(40, 20, 6), 10, CREATED_OLD),
            workout(UIDS[1], NAME_AMRAP, amrap(60), 10, CREATED_MID),
            workout(UIDS[2], NAME_FORTIME, fortime(3600, True), 10, CREATED_NEW),
        ],
        "expect": {
            "workouts": [
                {"id": UIDS[0], "name": NAME_TABATA, "code": "tabata", "work": 40, "rest": 20, "rounds": 6, "prep": 10},
                {"id": UIDS[1], "name": NAME_AMRAP, "code": "amrap", "seconds": 60, "prep": 10},
                {"id": UIDS[2], "name": NAME_FORTIME, "code": "fortime", "cap": 3600, "countUp": True, "prep": 10},
            ]
        },
    },
    {
        "version": "1.1.3",
        "sha": "b5bba49280726fc83d24a95830f333f0936abfc5",
        "has_setup": False,
        "has_voice": False,
        "has_health": False,
        "recents": [
            workout(UIDS[0], NAME_EMOM, emom(15, 30), 10, CREATED_OLD),
            workout(UIDS[1], NAME_AMRAP, amrap(1800), 10, CREATED_MID),
            workout(UIDS[2], NAME_TABATA, tabata(5, 120, 1), 10, CREATED_NEW),
        ],
        "expect": {
            "workouts": [
                {"id": UIDS[0], "name": NAME_EMOM, "code": "emom", "interval": 15, "rounds": 30, "prep": 10},
                {"id": UIDS[1], "name": NAME_AMRAP, "code": "amrap", "seconds": 1800, "prep": 10},
                {"id": UIDS[2], "name": NAME_TABATA, "code": "tabata", "work": 5, "rest": 120, "rounds": 1, "prep": 10},
            ]
        },
    },
    {
        "version": "1.2.0",
        "sha": "9379e3a7c7d59f32696fdf5c18cf6c74b3238d15",
        "has_setup": False,
        "has_voice": False,
        "has_health": False,
        "recents": [
            workout(UIDS[0], NAME_FORTIME, fortime(1200, False), 10, CREATED_OLD),
            workout(UIDS[1], NAME_EMOM, emom(45, 20), 10, CREATED_MID),
            workout(UIDS[2], NAME_AMRAP, amrap(300), 10, CREATED_NEW),
        ],
        "expect": {
            "workouts": [
                {"id": UIDS[0], "name": NAME_FORTIME, "code": "fortime", "cap": 1200, "countUp": False, "prep": 10},
                {"id": UIDS[1], "name": NAME_EMOM, "code": "emom", "interval": 45, "rounds": 20, "prep": 10},
                {"id": UIDS[2], "name": NAME_AMRAP, "code": "amrap", "seconds": 300, "prep": 10},
            ]
        },
    },
    {
        "version": "1.3.0",
        "sha": "15387695a5eba63e2e3d3da28cd88499ec9f5a87",
        "has_setup": False,
        "has_voice": False,
        "has_health": False,
        "recents": [
            workout(UIDS[0], NAME_AMRAP, amrap(900), 10, CREATED_OLD),
            workout(UIDS[1], NAME_TABATA, tabata(20, 10, 8), 10, CREATED_MID),
            workout(UIDS[2], NAME_FORTIME, fortime(600, True), 10, CREATED_NEW),
        ],
        "expect": {
            "workouts": [
                {"id": UIDS[0], "name": NAME_AMRAP, "code": "amrap", "seconds": 900, "prep": 10},
                {"id": UIDS[1], "name": NAME_TABATA, "code": "tabata", "work": 20, "rest": 10, "rounds": 8, "prep": 10},
                {"id": UIDS[2], "name": NAME_FORTIME, "code": "fortime", "cap": 600, "countUp": True, "prep": 10},
            ]
        },
    },
    {
        "version": "2.0.0",
        "sha": "eac3086474735f719c61049f89e60b035451a9ff",
        "has_setup": True,
        "has_voice": True,
        "has_health": False,
        "recents": [
            workout(UIDS[0], NAME_AMRAP, amrap(720), 10, CREATED_OLD),
            workout(UIDS[1], NAME_FORTIME, fortime(900, False), 10, CREATED_MID),
            workout(UIDS[2], NAME_EMOM, emom(90, 12), 10, CREATED_NEW),
        ],
        "setup": {
            "amrap": amrap(720),
            "fortime": fortime(900, False),
            "emom": emom(90, 12),
            "tabata": tabata(40, 20, 6),
        },
        "prefs": {
            "watch_voice_pack": "holly",
            "watch_voice_random": True,
            "watch_voice_muted": False,
            "watch_voice_beeps": True,
            "watch_hint_amrap_counted": True,
        },
        "expect": {
            "workouts": [
                {"id": UIDS[0], "name": NAME_AMRAP, "code": "amrap", "seconds": 720, "prep": 10},
                {"id": UIDS[1], "name": NAME_FORTIME, "code": "fortime", "cap": 900, "countUp": False, "prep": 10},
                {"id": UIDS[2], "name": NAME_EMOM, "code": "emom", "interval": 90, "rounds": 12, "prep": 10},
            ],
            "setup": {
                "amrapSeconds": 720,
                "forTimeCap": 900,
                "forTimeCountUp": False,
                "emomInterval": 90,
                "emomRounds": 12,
                "tabataWork": 40,
                "tabataRest": 20,
                "tabataRounds": 6,
            },
            "voicePack": "holly",
            "random": True,
            "muted": False,
            "beeps": True,
            "hintCounted": True,
        },
    },
    {
        "version": "2.1.0",
        "sha": "96c5a86b63841966184d45b38089418eaf72cd77",
        "has_setup": True,
        "has_voice": True,
        "has_health": False,
        "recents": [
            workout(UIDS[0], NAME_FORTIME, fortime(1500, True), 10, CREATED_OLD),
            workout(UIDS[1], NAME_TABATA, tabata(25, 10, 8), 10, CREATED_MID),
            workout(UIDS[2], NAME_AMRAP, amrap(900), 10, CREATED_NEW),
        ],
        "setup": {
            "amrap": amrap(900),
            "fortime": fortime(1500, True),
            "emom": emom(75, 8),
            "tabata": tabata(25, 10, 8),
        },
        "prefs": {
            "watch_voice_pack": "liam",
            "watch_voice_random": False,
            "watch_voice_muted": True,
            "watch_voice_beeps": False,
            "watch_hint_amrap_counted": False,
        },
        "expect": {
            "workouts": [
                {"id": UIDS[0], "name": NAME_FORTIME, "code": "fortime", "cap": 1500, "countUp": True, "prep": 10},
                {"id": UIDS[1], "name": NAME_TABATA, "code": "tabata", "work": 25, "rest": 10, "rounds": 8, "prep": 10},
                {"id": UIDS[2], "name": NAME_AMRAP, "code": "amrap", "seconds": 900, "prep": 10},
            ],
            "setup": {
                "amrapSeconds": 900,
                "forTimeCap": 1500,
                "forTimeCountUp": True,
                "emomInterval": 75,
                "emomRounds": 8,
                "tabataWork": 25,
                "tabataRest": 10,
                "tabataRounds": 8,
            },
            "voicePack": "liam",
            "random": False,
            "muted": True,
            "beeps": False,
            "hintCounted": False,
        },
    },
    {
        "version": "2.2.0",
        "sha": "adfc25275bd8d8deb07c6950ff5c9ea72417231f",
        "has_setup": True,
        "has_voice": True,
        "has_health": True,
        "recents": [
            workout(UIDS[0], NAME_TABATA, tabata(20, 10, 16), 10, CREATED_OLD),
            workout(UIDS[1], NAME_EMOM, emom(120, 5), 10, CREATED_MID),
            workout(UIDS[2], NAME_AMRAP, amrap(1200), 10, CREATED_NEW),
        ],
        "setup": {
            "amrap": amrap(1200),
            "fortime": fortime(480, True),
            "emom": emom(120, 5),
            "tabata": tabata(20, 10, 16),
        },
        "prefs": {
            "watch_voice_pack": "major",
            "watch_voice_random": True,
            "watch_voice_muted": False,
            "watch_voice_beeps": False,
            "watch_hint_amrap_counted": True,
            "watch_health_track": False,
        },
        "expect": {
            "workouts": [
                {"id": UIDS[0], "name": NAME_TABATA, "code": "tabata", "work": 20, "rest": 10, "rounds": 16, "prep": 10},
                {"id": UIDS[1], "name": NAME_EMOM, "code": "emom", "interval": 120, "rounds": 5, "prep": 10},
                {"id": UIDS[2], "name": NAME_AMRAP, "code": "amrap", "seconds": 1200, "prep": 10},
            ],
            "setup": {
                "amrapSeconds": 1200,
                "forTimeCap": 480,
                "forTimeCountUp": True,
                "emomInterval": 120,
                "emomRounds": 5,
                "tabataWork": 20,
                "tabataRest": 10,
                "tabataRounds": 16,
            },
            "voicePack": "major",
            "random": True,
            "muted": False,
            "beeps": False,
            "hintCounted": True,
            "healthTrack": False,
        },
    },
    {
        "version": "2.2.1",
        "sha": "998f9e3b81597e228376ed31784a815e209a3591",
        "has_setup": True,
        "has_voice": True,
        "has_health": True,
        "recents": [
            workout(UIDS[0], NAME_EMOM, emom(150, 16), 10, CREATED_OLD),
            workout(UIDS[1], NAME_FORTIME, fortime(720, False), 10, CREATED_MID),
            workout(UIDS[2], NAME_AMRAP, amrap(2400), 10, CREATED_NEW),
        ],
        "setup": {
            "amrap": amrap(2400),
            "fortime": fortime(720, False),
            "emom": emom(150, 16),
            "tabata": tabata(50, 25, 4),
        },
        "prefs": {
            "watch_voice_pack": "holly",
            "watch_voice_random": False,
            "watch_voice_muted": False,
            "watch_voice_beeps": True,
            "watch_hint_amrap_counted": False,
            "watch_health_track": True,
        },
        "expect": {
            "workouts": [
                {"id": UIDS[0], "name": NAME_EMOM, "code": "emom", "interval": 150, "rounds": 16, "prep": 10},
                {"id": UIDS[1], "name": NAME_FORTIME, "code": "fortime", "cap": 720, "countUp": False, "prep": 10},
                {"id": UIDS[2], "name": NAME_AMRAP, "code": "amrap", "seconds": 2400, "prep": 10},
            ],
            "setup": {
                "amrapSeconds": 2400,
                "forTimeCap": 720,
                "forTimeCountUp": False,
                "emomInterval": 150,
                "emomRounds": 16,
                "tabataWork": 50,
                "tabataRest": 25,
                "tabataRounds": 4,
            },
            "voicePack": "holly",
            "random": False,
            "muted": False,
            "beeps": True,
            "hintCounted": False,
            "healthTrack": True,
        },
    },
]

WEAR = [
    {
        "version": "2.2.0-wear",
        "sha": "190a6e4ee87011f786b982e386bf1068127cc2a0",
        "keys": {
            "wear_setup_amrap": typed("string", "amrap:720"),
            "wear_setup_fortime": typed("string", "fortime:900:0"),
            "wear_setup_emom": typed("string", "emom:90:12"),
            "wear_setup_tabata": typed("string", "tabata:40:20:6"),
            "wear_voice_pack": typed("string", "holly"),
            "wear_voice_random": typed("bool", True),
            "wear_voice_muted": typed("bool", False),
            "wear_voice_beeps": typed("bool", True),
            "wear_health_track": typed("bool", False),
            "wear_hint_amrap_counted": typed("bool", True),
            "wear_perm_asked": typed("bool", True),
            "some_plugin_key": typed("string", FOREIGN),
        },
        "expect": {
            "amrap": "amrap:720",
            "fortime": "fortime:900:0",
            "emom": "emom:90:12",
            "tabata": "tabata:40:20:6",
            "amrapSeconds": 720,
            "forTimeCap": 900,
            "forTimeCountUp": False,
            "emomInterval": 90,
            "emomRounds": 12,
            "tabataWork": 40,
            "tabataRest": 20,
            "tabataRounds": 6,
            "voicePack": "holly",
            "random": True,
            "muted": False,
            "beeps": True,
            "healthTrack": False,
            "hintCounted": True,
            "permAsked": True,
        },
    },
    {
        "version": "2.2.1",
        "sha": "998f9e3b81597e228376ed31784a815e209a3591",
        "keys": {
            "wear_setup_amrap": typed("string", "amrap:2400"),
            "wear_setup_fortime": typed("string", "fortime:720:1"),
            "wear_setup_emom": typed("string", "emom:150:16"),
            "wear_setup_tabata": typed("string", "tabata:50:25:4"),
            "wear_voice_pack": typed("string", "liam"),
            "wear_voice_random": typed("bool", False),
            "wear_voice_muted": typed("bool", True),
            "wear_voice_beeps": typed("bool", False),
            "wear_health_track": typed("bool", True),
            "wear_hint_amrap_counted": typed("bool", False),
            "wear_perm_asked": typed("bool", False),
            "some_plugin_key": typed("string", FOREIGN),
        },
        "expect": {
            "amrap": "amrap:2400",
            "fortime": "fortime:720:1",
            "emom": "emom:150:16",
            "tabata": "tabata:50:25:4",
            "amrapSeconds": 2400,
            "forTimeCap": 720,
            "forTimeCountUp": True,
            "emomInterval": 150,
            "emomRounds": 16,
            "tabataWork": 50,
            "tabataRest": 25,
            "tabataRounds": 4,
            "voicePack": "liam",
            "random": False,
            "muted": True,
            "beeps": False,
            "healthTrack": True,
            "hintCounted": False,
            "permAsked": False,
        },
    },
]


PHONE_README = """# Phone SharedPreferences fixture v{version}

- App version: {version}
- Commit SHA (keys taken from this tree): `{sha}`
- Produced by: `python3 tool/data_safety/generate_fixtures.py`
- Keys at that commit ({files}):
{key_list}

`some_plugin_key` is a foreign value no Wharf WOD build wrote; HEAD must leave it in place.

Do not edit this directory to make a test pass. If HEAD cannot read it, that is a data-loss bug.
"""

WATCH_README = """# Apple Watch UserDefaults fixture v{version}

- App version: {version}
- Commit SHA: `{sha}`
- Produced by: `python3 tool/data_safety/generate_fixtures.py`
- `recent_workouts.json` is JSONEncoder-shaped `[Workout]` (Date = `timeIntervalSinceReferenceDate` since 2001-01-01 UTC; UUID uppercase). HEAD's `JSONDecoder` + `RecentWorkoutsStore.load` must accept it.
{extra}
Do not edit this directory to make a test pass.
"""

WEAR_README = """# Wear OS SharedPreferences fixture v{version}

- App version: {version}
- Commit SHA: `{sha}`
- Prefs file name in production: `wharfwod`
- Produced by: `python3 tool/data_safety/generate_fixtures.py`
- Keys at that commit: wear_setup_<amrap|fortime|emom|tabata>, wear_voice_*, wear_health_track, wear_hint_amrap_counted, wear_perm_asked.

Encoded setup strings use that version's `SetupMemory.encode` (`amrap:720`, `fortime:900:0`, `emom:90:12`, `tabata:40:20:6`).

Do not edit this directory to make a test pass.
"""


def main() -> None:
    for spec in PHONE:
        folder = OUT / "phone" / spec["version"]
        dump(
            folder / "prefs.json",
            {
                "app_version": spec["version"],
                "commit": spec["sha"],
                "keys": spec["keys"],
                "expect": spec["expect"],
            },
        )
        write_readme(
            folder / "README.md",
            PHONE_README.format(
                version=spec["version"],
                sha=spec["sha"],
                files=", ".join(spec["keys_from"]),
                key_list="\n".join(f"- `{k}`" for k in spec["keys"]),
            ),
        )

    for spec in WATCH:
        folder = OUT / "watch" / spec["version"]
        dump(folder / "recent_workouts.json", spec["recents"])
        dump(folder / "expected.json", spec["expect"])
        extra_lines = []
        if spec["has_setup"]:
            for code, payload in spec["setup"].items():
                dump(folder / f"setup_{code}.json", payload)
            extra_lines.append(
                "- `setup_*.json` is JSONEncoder-shaped `TimerType` for `watch_setup_<code>` (2.0.0+)."
            )
        if spec.get("prefs"):
            dump(folder / "prefs.json", spec["prefs"])
            extra_lines.append(
                "- `prefs.json` holds additive UserDefaults scalars (`watch_voice_*`, hint, health)."
            )
        extra = "".join(f"{line}\n" for line in extra_lines)
        write_readme(
            folder / "README.md",
            WATCH_README.format(version=spec["version"], sha=spec["sha"], extra=extra),
        )

    for spec in WEAR:
        folder = OUT / "wear" / spec["version"]
        dump(
            folder / "prefs.json",
            {
                "app_version": spec["version"],
                "commit": spec["sha"],
                "keys": spec["keys"],
                "expect": spec["expect"],
            },
        )
        write_readme(
            folder / "README.md",
            WEAR_README.format(version=spec["version"], sha=spec["sha"]),
        )

    write_readme(
        OUT / "README.md",
        f"""# Data-safety fixtures

Generated by `python3 tool/data_safety/generate_fixtures.py`.
Checksums: `MANIFEST.sha256` (verified by `tool/data_safety/verify_fixtures.py`).

Each subdirectory is one shipped storage shape. Phone readers live in
`AppSettingsNotifier`, `SetupMemory`, `LiveHints`, `PrefsReviewStore`.
Watch JSON is the Codable layout `JSONEncoder` wrote from 1.1.0 through
2.2.1 (confirmed unchanged). Wear strings are `SetupMemory.encode`.

Foreign key on every surface: `some_plugin_key` = a unicode / RTL / quote / newline
string HEAD must not delete.

Apple reference dates used in watch JSON:
- oldest: 2026-07-14T06:00:00Z = {CREATED_OLD}
- middle: 2026-10-01T12:00:00Z = {CREATED_MID}
- newest: 2026-10-16T18:00:00Z = {CREATED_NEW}
""",
    )
    subprocess.check_call(
        [
            sys.executable,
            str(ROOT / "tool" / "data_safety" / "verify_fixtures.py"),
            "--write-manifest",
        ]
    )
    print(f"wrote fixtures under {OUT}")


if __name__ == "__main__":
    main()
