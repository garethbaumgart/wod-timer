#!/usr/bin/env python3
"""Fail if committed generated Dart is stale.

Run after `dart run build_runner build --delete-conflicting-outputs` on
Flutter 3.44.9 (codegen hangs on the FVM pin 3.47.7). Compares working-tree
generated files to git HEAD.

`lib/injection.config.dart` may differ only in the order of `gh.factory` /
`gh.lazySingleton` registrations; that is ignored. Alias renumbering
(`as _i174` vs `as _i200`) and added/removed registrations fail.
"""

from __future__ import annotations

import difflib
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INJECTION = "lib/injection.config.dart"
GH_START = re.compile(r"gh\.(?:factory|lazySingleton|singleton)<")


def die(msg: str) -> None:
    print(msg, file=sys.stderr)
    raise SystemExit(1)


def is_generated(rel: str) -> bool:
    return (
        rel == INJECTION
        or rel.endswith(".g.dart")
        or rel.endswith(".freezed.dart")
    )


def git_ls_generated() -> set[str]:
    out = subprocess.check_output(
        ["git", "ls-files", "lib"],
        cwd=ROOT,
        text=True,
    )
    return {line for line in out.splitlines() if is_generated(line)}


def worktree_generated() -> set[str]:
    lib = ROOT / "lib"
    found: set[str] = set()
    for path in lib.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(ROOT).as_posix()
        if is_generated(rel):
            found.add(rel)
    return found


def git_show(rel: str) -> str | None:
    result = subprocess.run(
        ["git", "show", f"HEAD:{rel}"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    return result.stdout.replace("\r\n", "\n")


def read_worktree(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8").replace("\r\n", "\n")


def _skip_balanced(text: str, i: int, open_ch: str, close_ch: str) -> int:
    if i >= len(text) or text[i] != open_ch:
        raise ValueError(f"expected {open_ch!r} at {i}")
    depth = 0
    while i < len(text):
        ch = text[i]
        if ch == open_ch:
            depth += 1
        elif ch == close_ch:
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    raise ValueError(f"unbalanced {open_ch}{close_ch}")


def _extract_gh_call(text: str, start: int) -> tuple[str, int]:
    if text.startswith("gh.lazySingleton", start):
        i = start + len("gh.lazySingleton")
    elif text.startswith("gh.factory", start):
        i = start + len("gh.factory")
    elif text.startswith("gh.singleton", start):
        i = start + len("gh.singleton")
    else:
        raise ValueError(f"not a gh registration at {start}")
    while i < len(text) and text[i].isspace():
        i += 1
    if i >= len(text) or text[i] != "<":
        raise ValueError("expected <T> on gh registration")
    i = _skip_balanced(text, i, "<", ">")
    while i < len(text) and text[i].isspace():
        i += 1
    if i >= len(text) or text[i] != "(":
        raise ValueError("expected ( on gh registration")
    i = _skip_balanced(text, i, "(", ")")
    while i < len(text) and text[i].isspace():
        i += 1
    if i < len(text) and text[i] == ";":
        i += 1
    return text[start:i], i


def gh_registrations(text: str) -> list[str]:
    calls: list[str] = []
    i = 0
    while True:
        match = GH_START.search(text, i)
        if not match:
            break
        call, end = _extract_gh_call(text, match.start())
        calls.append(re.sub(r"\s+", " ", call.strip()))
        i = end
    return calls


def normalize_injection(text: str) -> str:
    """Drop registration order; keep aliases, imports, and the rest intact."""
    marker = "final gh ="
    start = text.find(marker)
    if start < 0:
        die(f"{INJECTION}: no GetItHelper assignment")
    semi = text.find(";", start)
    if semi < 0:
        die(f"{INJECTION}: unterminated GetItHelper assignment")
    prefix = text[: semi + 1]
    rest = text[semi + 1 :]
    return_at = rest.find("return this;")
    if return_at < 0:
        die(f"{INJECTION}: no `return this;`")
    body = rest[:return_at]
    suffix = rest[return_at:]
    calls = gh_registrations(body)
    if not calls:
        die(f"{INJECTION}: no gh.factory / gh.lazySingleton registrations")
    leftover = body
    for raw in re.finditer(r"gh\.(?:factory|lazySingleton|singleton)<", body):
        call, _ = _extract_gh_call(body, raw.start())
        leftover = leftover.replace(call, "", 1)
    if leftover.strip():
        die(
            f"{INJECTION}: leftover init body after stripping registrations:\n"
            f"{leftover.strip()[:500]}"
        )
    return prefix + "\nREGS:\n" + "\n".join(sorted(calls)) + "\n" + suffix


def unified(rel: str, left: str, right: str) -> str:
    diff = difflib.unified_diff(
        left.splitlines(keepends=True),
        right.splitlines(keepends=True),
        fromfile=f"HEAD:{rel}",
        tofile=rel,
    )
    return "".join(diff)


def main() -> None:
    committed = git_ls_generated()
    working = worktree_generated()
    failures: list[str] = []

    missing = committed - working
    extra = working - committed
    if missing:
        failures.append(
            "generated files committed but missing on disk:\n  "
            + "\n  ".join(sorted(missing))
        )
    if extra:
        failures.append(
            "generated files on disk but not committed:\n  "
            + "\n  ".join(sorted(extra))
        )

    for rel in sorted(committed & working):
        head = git_show(rel)
        if head is None:
            failures.append(f"{rel}: not in HEAD")
            continue
        now = read_worktree(rel)
        if rel == INJECTION:
            left = normalize_injection(head)
            right = normalize_injection(now)
            if left != right:
                failures.append(
                    f"{rel}: generated content changed (not just "
                    f"gh.factory / gh.lazySingleton order)\n{unified(rel, left, right)}"
                )
            continue
        if head != now:
            failures.append(f"{rel}: differs from HEAD\n{unified(rel, head, now)}")

    if failures:
        die(
            "committed generated files are stale. Re-run codegen on Flutter "
            "3.44.9 and commit the result. See docs/data-safety.md.\n\n"
            + "\n\n".join(failures)
        )

    print(
        f"generated files match HEAD ({len(committed)} files; "
        f"{INJECTION} registration order ignored)"
    )


if __name__ == "__main__":
    main()
