#!/usr/bin/env bash
#
# with-secrets.sh — invoke `flutter` with secrets sourced from Doppler.
#
# Bridges Doppler's per-config secrets into Flutter's compile-time
# `String.fromEnvironment(...)` constants (SENTRY_DSN, SENTRY_ENV,
# APTABASE_KEY). Without this wrapper Flutter only sees `--dart-define[-from-file]`
# flags at build time.
#
# Usage:
#   scripts/with-secrets.sh <dev|stg|prd> <flutter-args...>
#
# Examples:
#   scripts/with-secrets.sh prd test
#   scripts/with-secrets.sh prd run --release --device-id 00008140-...
#   scripts/with-secrets.sh prd build ipa --export-method app-store
#
# Prereqs:
#   - `doppler` CLI installed + logged in (one-time: `doppler login`)
#   - Doppler project `gazzawod` exists with a prd config

set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <dev|stg|prd> <flutter-args...>" >&2
  echo "       e.g. $(basename "$0") prd run --release --device-id <id>" >&2
  exit 2
}

CONFIG="${1:-}"
if [ -z "$CONFIG" ]; then usage; fi
shift

if [ "$#" -eq 0 ]; then
  echo "error: no flutter args supplied" >&2
  usage
fi

# cd to the Flutter project root (one level above scripts/)
cd "$(dirname "$0")/.."

# Honour the .fvmrc pin when fvm is available.
FLUTTER=flutter
if command -v fvm > /dev/null && [ -f .fvmrc ]; then
  FLUTTER="fvm flutter"
fi

# Materialise filtered Doppler secrets as a temp dart-define JSON file in a
# private dir; deleted on exit (incl. Ctrl+C).
TEMP_DIR=$(mktemp -d -t gazzawod-dart-defines)
chmod 700 "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT INT TERM
TEMP="$TEMP_DIR/dart-defines.json"

doppler secrets download \
  --project gazzawod --config "$CONFIG" \
  --no-file --format json \
  | python3 -c '
import json, sys
data = json.load(sys.stdin)
# Strip Doppler-injected metadata keys (DOPPLER_CONFIG, DOPPLER_PROJECT, etc.)
# Those are not app secrets and would leak Doppler config names into the bundle.
filtered = {k: v for k, v in data.items() if not k.startswith("DOPPLER_")}
json.dump(filtered, sys.stdout)
' > "$TEMP"

# Sanity check — refuse to proceed if no app keys came through.
if [ "$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))))' "$TEMP")" = "0" ]; then
  echo "error: Doppler returned no app secrets for config '$CONFIG' — check 'doppler whoami' + config name" >&2
  exit 1
fi

$FLUTTER "$@" --dart-define-from-file="$TEMP"
