#!/usr/bin/env bash
# Fail the release if data-safety tests fail or if none of them ran.
# mentalmetal-ship calls this (via test_gate.sh) and refuses to ship
# without it. Do not pipe the test process into tail — gate on the
# flutter exit code and a counted testDone total.
set -euo pipefail

cd "$(dirname "$0")/.."

if command -v fvm >/dev/null 2>&1; then
  flutter_cmd=(fvm flutter)
else
  flutter_cmd=(flutter)
fi

report="$(mktemp)"
cleanup() { rm -f "$report"; }
trap cleanup EXIT

set +e
"${flutter_cmd[@]}" test --tags data-safety --file-reporter "json:$report"
status=$?
set -e

if [[ ! -s "$report" ]]; then
  echo "data-safety gate: json reporter wrote no output" >&2
  exit 1
fi

count="$(python3 - "$report" <<'PY'
import json, sys
path = sys.argv[1]
n = 0
with open(path, encoding="utf-8") as fh:
    for raw in fh:
        raw = raw.strip()
        if not raw:
            continue
        try:
            event = json.loads(raw)
        except json.JSONDecodeError:
            continue
        if event.get("type") != "testDone":
            continue
        if event.get("hidden") is True:
            continue
        n += 1
print(n)
PY
)"

echo "data-safety gate: $count visible test(s), flutter exit $status"

if [[ "$status" -ne 0 ]]; then
  exit "$status"
fi
if [[ "$count" -eq 0 ]]; then
  echo "data-safety gate: zero tests ran" >&2
  exit 1
fi
