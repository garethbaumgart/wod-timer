#!/usr/bin/env python3
"""Verify data-safety fixtures against MANIFEST.sha256 and git history.

1. Every file under test/fixtures/data_safety/ (except MANIFEST.sha256)
   matches the committed checksum manifest. Editing or deleting an old
   fixture without updating the manifest fails.
2. At each ShippedStorageVersion commit, the persistence key literals in
   that tree match the fixture's key set (minus the foreign plugin key).

Historical phone *values* are not produced by compiling old tags — see
tool/data_safety/capture_phone_worktree.py. This script is the automated
cross-check that the key lists still match source at each listed SHA.

Requires a git checkout with those commits present (CI fetch-depth: 0).
"""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "test" / "fixtures" / "data_safety"
CATALOG = ROOT / "test" / "data_safety" / "storage_catalog.dart"
MANIFEST = OUT / "MANIFEST.sha256"
FOREIGN = "some_plugin_key"

PHONE_FILES = (
    "lib/core/application/providers/app_settings_provider.dart",
    "lib/core/review/review_prompter.dart",
    "lib/features/timer/application/setup/setup_memory.dart",
    "lib/features/timer/application/setup/live_hints.dart",
)
WATCH_FILES = (
    "ios/WODTimerWatch/Application/RecentWorkoutsStore.swift",
    "ios/WODTimerWatch/Application/TimerViewModel.swift",
    "ios/WODTimerWatch/Services/WatchAudioService.swift",
    "ios/WODTimerWatch/Services/WatchWorkoutTracker.swift",
)
WEAR_FILES = (
    "android/wear/src/main/java/app/mentalmetal/wharfwod/wear/application/SetupMemory.kt",
    "android/wear/src/main/java/app/mentalmetal/wharfwod/wear/application/TimerViewModel.kt",
    "android/wear/src/main/java/app/mentalmetal/wharfwod/wear/services/CueFiles.kt",
    "android/wear/src/main/java/app/mentalmetal/wharfwod/wear/services/ExerciseTracker.kt",
    "android/wear/src/main/java/app/mentalmetal/wharfwod/wear/MainActivity.kt",
)

KEY_RE = re.compile(
    r"""['"]((?:app_|setup_|review_|hint_|watch_|wear_|recent_workouts)[^'"]*)['"]"""
)
VERSION_RE = re.compile(
    r"ShippedStorageVersion\(\s*appVersion:\s*'([^']+)',\s*commitSha:\s*'([^']+)'"
    r"(?:.*?(?:fixtureFolder:\s*'([^']+)'))?",
    re.S,
)


def die(msg: str) -> None:
    print(msg, file=sys.stderr)
    raise SystemExit(1)


def parse_catalog_section(name: str) -> list[tuple[str, str, str]]:
    text = CATALOG.read_text(encoding="utf-8")
    match = re.search(
        rf"static const {name} = <ShippedStorageVersion>\[(.*?)\]\;",
        text,
        re.S,
    )
    if not match:
        die(f"could not parse StorageCatalog.{name}")
    out: list[tuple[str, str, str]] = []
    for item in VERSION_RE.finditer(match.group(1)):
        version, sha, folder = item.group(1), item.group(2), item.group(3)
        out.append((version, sha, folder or version))
    if not out:
        die(f"no ShippedStorageVersion entries in {name}")
    return out


def git_show(sha: str, path: str) -> str | None:
    result = subprocess.run(
        ["git", "show", f"{sha}:{path}"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    return result.stdout


def expand_key(raw: str) -> set[str]:
    # Skip part/import paths (`app_settings_provider.g.dart`).
    if "." in raw or "/" in raw or " " in raw:
        return set()
    templated = any(token in raw for token in ("$(", r"\(", "$code", "$"))
    if raw.startswith("watch_setup_") and (templated or raw.endswith("_")):
        return {f"watch_setup_{code}" for code in ("amrap", "fortime", "emom", "tabata")}
    if raw.startswith("wear_setup_") and (templated or raw.endswith("_") or "code" in raw):
        return {f"wear_setup_{code}" for code in ("amrap", "fortime", "emom", "tabata")}
    if raw.startswith(
        ("app_", "setup_", "review_", "hint_", "watch_", "wear_")
    ) or raw == "recent_workouts":
        return {raw}
    return set()


def keys_from_text(text: str) -> set[str]:
    found: set[str] = set()
    for match in KEY_RE.finditer(text):
        found |= expand_key(match.group(1))
    return found


def keys_at_commit(sha: str, files: tuple[str, ...]) -> set[str]:
    found: set[str] = set()
    for path in files:
        text = git_show(sha, path)
        if text is None:
            continue
        found |= keys_from_text(text)
    return found


def typed_fixture_keys(path: Path) -> set[str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    keys = set(data["keys"])
    keys.discard(FOREIGN)
    return keys


def watch_fixture_keys(folder: str) -> set[str]:
    directory = OUT / "watch" / folder
    keys = {"recent_workouts"}
    prefs = directory / "prefs.json"
    if prefs.is_file():
        keys |= set(json.loads(prefs.read_text(encoding="utf-8")))
    for code in ("amrap", "fortime", "emom", "tabata"):
        if (directory / f"setup_{code}.json").is_file():
            keys.add(f"watch_setup_{code}")
    return keys


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative_fixture_files() -> list[Path]:
    files = [
        p
        for p in OUT.rglob("*")
        if p.is_file() and p.name != "MANIFEST.sha256"
    ]
    return sorted(files, key=lambda p: p.relative_to(OUT).as_posix())


def write_manifest() -> None:
    lines = [
        "# SHA-256 of every data-safety fixture file.",
        "# Regenerated by python3 tool/data_safety/generate_fixtures.py",
        "# Do not edit an old fixture to make a test pass; add a new version.",
    ]
    for path in relative_fixture_files():
        rel = path.relative_to(OUT).as_posix()
        lines.append(f"{sha256(path)}  {rel}")
    MANIFEST.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_manifest() -> dict[str, str]:
    if not MANIFEST.is_file():
        die(f"missing {MANIFEST.relative_to(ROOT)}")
    mapping: dict[str, str] = {}
    for raw in MANIFEST.read_text(encoding="utf-8").splitlines():
        if not raw.strip() or raw.startswith("#"):
            continue
        digest, name = raw.split("  ", 1)
        mapping[name] = digest
    return mapping


def verify_manifest() -> None:
    expected = parse_manifest()
    actual = {
        path.relative_to(OUT).as_posix(): sha256(path)
        for path in relative_fixture_files()
    }
    extra = sorted(set(actual) - set(expected))
    missing = sorted(set(expected) - set(actual))
    changed = sorted(
        name for name, digest in actual.items() if expected.get(name) != digest
    )
    if extra or missing or changed:
        parts = []
        if missing:
            parts.append("deleted: " + ", ".join(missing))
        if extra:
            parts.append("untracked: " + ", ".join(extra))
        if changed:
            parts.append("edited: " + ", ".join(changed))
        die("MANIFEST.sha256 mismatch: " + "; ".join(parts))
    print(f"manifest: {len(actual)} fixture files match")


def ensure_git_history(sha: str) -> None:
    result = subprocess.run(
        ["git", "cat-file", "-e", f"{sha}^{{commit}}"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        die(
            f"git object {sha} is missing. Tests need full history "
            "(actions/checkout fetch-depth: 0)."
        )


def verify_phone() -> None:
    for version, sha, folder in parse_catalog_section("phoneVersions"):
        ensure_git_history(sha)
        fixture = typed_fixture_keys(OUT / "phone" / folder / "prefs.json")
        source = keys_at_commit(sha, PHONE_FILES)
        if fixture != source:
            die(
                f"phone {version} ({sha[:12]}): fixture keys {sorted(fixture)} "
                f"!= source {sorted(source)}"
            )
        print(f"phone {version}: {len(fixture)} keys match {sha[:12]}")


def verify_watch() -> None:
    for version, sha, folder in parse_catalog_section("watchVersions"):
        ensure_git_history(sha)
        fixture = watch_fixture_keys(folder)
        source = keys_at_commit(sha, WATCH_FILES)
        # recent_workouts is always present; setup/voice/health are additive.
        if fixture != source:
            die(
                f"watch {version} ({sha[:12]}): fixture keys {sorted(fixture)} "
                f"!= source {sorted(source)}"
            )
        print(f"watch {version}: {len(fixture)} keys match {sha[:12]}")


def verify_wear() -> None:
    for version, sha, folder in parse_catalog_section("wearVersions"):
        ensure_git_history(sha)
        fixture = typed_fixture_keys(OUT / "wear" / folder / "prefs.json")
        source = keys_at_commit(sha, WEAR_FILES)
        if fixture != source:
            die(
                f"wear {version} ({sha[:12]}): fixture keys {sorted(fixture)} "
                f"!= source {sorted(source)}"
            )
        print(f"wear {version}: {len(fixture)} keys match {sha[:12]}")


def main() -> None:
    if len(sys.argv) > 1 and sys.argv[1] == "--write-manifest":
        write_manifest()
        print(f"wrote {MANIFEST}")
        return
    verify_manifest()
    verify_phone()
    verify_watch()
    verify_wear()
    print("verify_fixtures: ok")


if __name__ == "__main__":
    main()
