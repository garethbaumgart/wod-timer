#!/usr/bin/env python3
"""Try to run each shipped tag's Dart prefs writers in a git worktree.

Committed phone fixtures are produced by generate_fixtures.py and
cross-checked by verify_fixtures.py (git show of key literals at each
SHA). This script records whether compiling those tags and invoking the
real writers is feasible on the current toolchain.

It is not feasible here, and the script prints the exact failure for
each SHA rather than pretending to regenerate fixtures:

- Generated *.g.dart / *.freezed.dart / injection.config.dart were not
  in git at those tags (they were gitignored).
- AppSettingsNotifier is a @Riverpod class and cannot be constructed
  without app_settings_provider.g.dart.
- `dart run build_runner` hangs on Flutter 3.47.7 / Dart 3.13.5 because
  analyzer 7.6.0 has no visitDotShorthandPropertyAccess (riverpod_generator
  2.6). HEAD even comments that riverpod_generator 2.6 cannot parse the
  3.47 SDK.
- Older tags need a matching Flutter; this VM has 3.47.7 and 3.44.9.

HEAD writers *are* exercised in test/data_safety/phone_prefs_test.dart
(the capture test uses AppSettingsNotifier, SetupMemory, LiveHints, and
PrefsReviewStore against SharedPreferences.setMockInitialValues).

Usage:

    python3 tool/data_safety/capture_phone_worktree.py
    python3 tool/data_safety/capture_phone_worktree.py --sha 998f9e3

Never writes into test/fixtures/data_safety/.
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

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

FLUTTER_347 = os.environ.get("FLUTTER_347", "/home/ubuntu/sdk/flutter")
FLUTTER_344 = os.environ.get("FLUTTER_344", "/home/ubuntu/sdk/flutter-3.44.9")
BUILD_RUNNER_TIMEOUT = int(os.environ.get("BUILD_RUNNER_TIMEOUT", "90"))


def flutter_for(sha: str) -> Path:
    """v2.2.1 is after the 3.47.7 bump (77b25a1); earlier tags use 3.44.9."""
    if sha.startswith("998f9e3"):
        return Path(FLUTTER_347)
    return Path(FLUTTER_344)


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


def snippet(text: str, limit: int = 600) -> str:
    text = text.strip()
    if len(text) <= limit:
        return text
    return text[:limit] + "\n…"


def try_sha(version: str, sha: str) -> str:
    flutter = flutter_for(sha)
    dart = flutter / "bin" / "dart"
    if not dart.is_file():
        return f"{version} {sha[:12]}: SKIP no dart at {dart}"

    work = Path(tempfile.mkdtemp(prefix=f"ds-phone-{version}-"))
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

        generated = work / "lib/core/application/providers/app_settings_provider.g.dart"
        if generated.is_file():
            return (
                f"{version} {sha[:12]}: UNEXPECTED generated file present; "
                "refusing to treat this as a historical tag capture"
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

        return (
            f"{version} {sha[:12]}: build_runner succeeded, but this script "
            "still does not overwrite committed fixtures (verify_fixtures.py "
            "is the historical check; HEAD writers run in phone_prefs_test.dart)"
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
        "capture_phone_worktree: will not write fixtures. "
        "Probing whether each SHA's Dart writers can compile.\n"
    )
    status = 0
    for version, sha in targets:
        line = try_sha(version, sha)
        print(line)
        print()
        if line.startswith(f"{version}") and "build_runner succeeded" not in line:
            status = 1
    return status


if __name__ == "__main__":
    raise SystemExit(main())
