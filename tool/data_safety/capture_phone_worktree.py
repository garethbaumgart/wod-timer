#!/usr/bin/env python3
"""Run each shipped tag's Dart prefs writers in a git worktree.

Codegen uses Flutter 3.44.9. `dart run build_runner` hangs on the FVM pin
(Flutter 3.47.7 / analyzer 7.6.0 missing visitDotShorthandPropertyAccess),
so this never invokes 3.47.7's dart for generation.

When codegen succeeds, a generated harness calls that tag's real
AppSettingsNotifier / SetupMemory / LiveHints / PrefsReviewStore writers
and prints the key→type map. That map is compared to the committed
fixture (minus `some_plugin_key`). Fixtures are never overwritten.

HEAD (2.2.1) writers are also covered by test/data_safety/phone_prefs_test.dart.

Usage:

    python3 tool/data_safety/capture_phone_worktree.py
    python3 tool/data_safety/capture_phone_worktree.py --sha 96c5a86
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "test" / "fixtures" / "data_safety"
FOREIGN = "some_plugin_key"

PHONE = [
    ("1.1.0", "3876b5bf597cc99732c2be575af79a6b71495373"),
    ("1.1.2", "c0ffb0a5f772a0dd9efe6df93ff59f695e4ba1f7"),
    ("1.1.3", "b5bba49280726fc83d24a95830f333f0936abfc5"),
    ("1.2.0", "9379e3a7c7d59f32696fdf5c18cf6c74b3238d15"),
    ("1.3.0", "15387695a5eba63e2e3d3da28cd88499ec9f5a87"),
    ("2.0.0", "eac3086474735f719c61049f89e60b035451a9ff"),
    ("2.1.0", "96c5a86b63841966184d45b38089418eaf72cd77"),
    ("2.2.0", "adfc25275bd8d8deb07c6950ff5c9ea72417231f"),
    ("2.2.1", "998f9e3b81597e228376ed31784a815e209a3591"),
]

FLUTTER_344 = Path(os.environ.get("FLUTTER_344", "/home/ubuntu/sdk/flutter-3.44.9"))
BUILD_RUNNER_TIMEOUT = int(os.environ.get("BUILD_RUNNER_TIMEOUT", "180"))


def run(
    args: list[str],
    cwd: Path,
    timeout: int | None = None,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    merged = os.environ.copy()
    if env:
        merged.update(env)
    try:
        return subprocess.run(
            args,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout,
            env=merged,
        )
    except subprocess.TimeoutExpired as exc:
        stdout = exc.stdout.decode() if isinstance(exc.stdout, bytes) else (exc.stdout or "")
        stderr = exc.stderr.decode() if isinstance(exc.stderr, bytes) else (exc.stderr or "")
        return subprocess.CompletedProcess(
            args=args,
            returncode=124,
            stdout=stdout,
            stderr=stderr + f"\nTIMEOUT after {timeout}s",
        )


def snippet(text: str, limit: int = 800) -> str:
    text = text.strip()
    if len(text) <= limit:
        return text
    return text[:limit] + "\n…"


def write_harness(work: Path, capture_path: Path) -> None:
    has_setup = (work / "lib/features/timer/application/setup/setup_memory.dart").is_file()
    has_hints = (work / "lib/features/timer/application/setup/live_hints.dart").is_file()
    has_review = (work / "lib/core/review/review_prompter.dart").is_file()
    setup_src = (
        (work / "lib/features/timer/application/setup/setup_memory.dart").read_text(encoding="utf-8")
        if has_setup
        else ""
    )
    has_last_mode = "lastModeKey" in setup_src
    settings_src = (
        work / "lib/core/application/providers/app_settings_provider.dart"
    ).read_text(encoding="utf-8")
    has_set_sound = "setSoundEnabled" in settings_src

    imports = [
        "import 'dart:convert';",
        "import 'dart:io';",
        "",
        "import 'package:flutter_riverpod/flutter_riverpod.dart';",
        "import 'package:flutter_test/flutter_test.dart';",
        "import 'package:shared_preferences/shared_preferences.dart';",
        "import 'package:wod_timer/core/application/providers/app_settings_provider.dart';",
    ]
    if has_review:
        imports.append(
            "import 'package:wod_timer/core/review/review_prompter.dart';"
        )
    if has_hints:
        imports.append(
            "import 'package:wod_timer/features/timer/application/setup/live_hints.dart';"
        )
    if has_setup:
        imports.append(
            "import 'package:wod_timer/features/timer/application/setup/setup_configs.dart';"
        )
        imports.append(
            "import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';"
        )

    body: list[str] = [
        "    TestWidgetsFlutterBinding.ensureInitialized();",
        "    SharedPreferences.setMockInitialValues(<String, Object>{});",
        "    final prefs = await SharedPreferences.getInstance();",
        "    final container = ProviderContainer();",
        "    addTearDown(container.dispose);",
        "    container.read(appSettingsNotifierProvider);",
        "    for (var i = 0; i < 10; i++) {",
        "      await Future<void>.delayed(Duration.zero);",
        "    }",
        "    final notifier = container.read(appSettingsNotifierProvider.notifier);",
        "    await notifier.setOrientationLock(OrientationLockMode.portrait);",
        "    await notifier.setHapticEnabled(enabled: false);",
        "    await notifier.setVoice(VoiceOption.values[1]);",
    ]
    if has_set_sound:
        body += [
            "    await notifier.setSoundEnabled(enabled: true);",
            "    await notifier.setKeepScreenOn(enabled: false);",
        ]
    if has_setup:
        body += [
            "    final memory = SetupMemory(prefs);",
            "    await memory.saveAmrap(const AmrapSetup(durationSeconds: 720));",
            "    await memory.saveForTime(const ForTimeSetup(capSeconds: 900, countUp: false));",
            "    await memory.saveEmom(const EmomSetup(intervalSeconds: 90, rounds: 12));",
            "    await memory.saveTabata(const TabataSetup(workSeconds: 40, restSeconds: 20, rounds: 6));",
        ]
        if not has_last_mode:
            pass
    if has_hints:
        body.append("    await LiveHints(prefs).markCountedRound();")
    if has_review:
        body += [
            "    const store = PrefsReviewStore();",
            "    await store.writeInt(ReviewPrompter.momentsKey, 1);",
            "    await store.writeInt(ReviewPrompter.asksKey, 1);",
            "    await store.writeInt(ReviewPrompter.lastAskedKey, 1);",
        ]
    body += [
        "    await prefs.reload();",
        "    final written = <String, String>{};",
        "    for (final key in prefs.getKeys()) {",
        "      final value = prefs.get(key);",
        "      if (value is int) {",
        "        written[key] = 'int';",
        "      } else if (value is bool) {",
        "        written[key] = 'bool';",
        "      } else if (value is String) {",
        "        written[key] = 'string';",
        "      }",
        "    }",
        f"    File({json.dumps(str(capture_path))}).writeAsStringSync(jsonEncode(written));",
        "    expect(written, isNotEmpty);",
    ]

    dart = "\n".join(
        [
            *imports,
            "",
            "void main() {",
            "  test('capture phone writers', () async {",
            *body,
            "  });",
            "}",
            "",
        ]
    )
    dest = work / "test" / "data_safety_capture_test.dart"
    dest.write_text(dart, encoding="utf-8")


def fixture_types(version: str) -> dict[str, str]:
    data = json.loads((OUT / "phone" / version / "prefs.json").read_text(encoding="utf-8"))
    types: dict[str, str] = {}
    for key, spec in data["keys"].items():
        if key == FOREIGN:
            continue
        if "int" in spec:
            types[key] = "int"
        elif "bool" in spec:
            types[key] = "bool"
        elif "string" in spec:
            types[key] = "string"
    return types


def try_sha(version: str, sha: str) -> str:
    flutter = FLUTTER_344
    dart = flutter / "bin" / "dart"
    if not dart.is_file():
        return f"{version} {sha[:12]}: SKIP no dart at {dart}"

    work = Path(tempfile.mkdtemp(prefix=f"ds-phone-{version}-"))
    capture_path = work / "captured_shape.json"
    try:
        add = run(
            ["git", "worktree", "add", "--detach", str(work), sha],
            cwd=ROOT,
            timeout=60,
        )
        if add.returncode != 0:
            return f"{version} {sha[:12]}: FAIL git worktree add\n{snippet(add.stderr)}"

        pub = run(
            [str(flutter / "bin" / "flutter"), "pub", "get"],
            cwd=work,
            timeout=180,
        )
        if pub.returncode != 0:
            return (
                f"{version} {sha[:12]}: FAIL flutter pub get "
                f"({flutter})\n{snippet(pub.stderr or pub.stdout)}"
            )

        codegen = run(
            [
                str(dart),
                "run",
                "build_runner",
                "build",
                "--delete-conflicting-outputs",
            ],
            cwd=work,
            timeout=BUILD_RUNNER_TIMEOUT,
        )
        if codegen.returncode != 0:
            why = "TIMEOUT" if codegen.returncode == 124 else "FAIL"
            return (
                f"{version} {sha[:12]}: {why} build_runner "
                f"({flutter}, {BUILD_RUNNER_TIMEOUT}s cap)\n"
                f"{snippet(codegen.stderr or codegen.stdout)}"
            )

        write_harness(work, capture_path)
        test = run(
            [
                str(flutter / "bin" / "flutter"),
                "test",
                "test/data_safety_capture_test.dart",
            ],
            cwd=work,
            timeout=180,
        )
        if test.returncode != 0:
            return (
                f"{version} {sha[:12]}: FAIL writer harness\n"
                f"{snippet(test.stderr or test.stdout)}"
            )
        if not capture_path.is_file():
            return f"{version} {sha[:12]}: FAIL harness wrote no capture file"

        captured = json.loads(capture_path.read_text(encoding="utf-8"))
        expected = fixture_types(version)
        if captured != expected:
            return (
                f"{version} {sha[:12]}: FAIL writer keys {json.dumps(captured, sort_keys=True)} "
                f"!= fixture {json.dumps(expected, sort_keys=True)}"
            )
        return (
            f"{version} {sha[:12]}: OK writers via Flutter 3.44.9 "
            f"({len(captured)} keys+types match fixture)"
        )
    finally:
        subprocess.run(
            ["git", "worktree", "remove", "--force", str(work)],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        shutil.rmtree(work, ignore_errors=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sha", help="only this commit (prefix ok)")
    args = parser.parse_args()
    targets = PHONE
    if args.sha:
        targets = [item for item in PHONE if item[1].startswith(args.sha)]
        if not targets:
            print(f"no catalog SHA starts with {args.sha}", file=sys.stderr)
            return 2

    print(
        "capture_phone_worktree: codegen on Flutter 3.44.9, then run that "
        "tag's Dart writers. Does not write fixtures.\n"
    )
    status = 0
    for version, sha in targets:
        line = try_sha(version, sha)
        print(line)
        print()
        if ": OK " not in line:
            status = 1
    return status


if __name__ == "__main__":
    raise SystemExit(main())
