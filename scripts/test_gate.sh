#!/usr/bin/env bash
# Wharf WOD test gate: everything that must be green before a build goes
# to a store. The release pipeline (mentalmetal-ship) runs
# `scripts/test_gate.sh --full <platform>` automatically before uploading
# when this file exists; run it by hand with
#
#   scripts/test_gate.sh                 # --full: analyze, Flutter tests, watch XCTests
#   scripts/test_gate.sh --quick         # analyze and Flutter tests only (no Xcode, about 1 min)
#   scripts/test_gate.sh --full android  # the watch ships with iOS, so Android skips it;
#                                        # Android (and both) also run the Wear OS module's JVM tests
#
# Exits non-zero on the first failure. Fast by design: unit and widget
# tests only. The integration_test/ tours (store screenshots, promo and
# UX-review captures) are NOT part of the gate; run one by hand with
#
#   fvm flutter test integration_test/ux_review_tour_test.dart -d <device>
#
# Toolchain: Flutter via fvm (the .fvmrc pin). Never run build_runner: the
# generated *.g.dart / *.freezed.dart files are copied in and gitignored.
set -euo pipefail

cd "$(dirname "$0")/.."

WATCH_SIM_ID="${WATCH_SIM_ID:-8F48DAA5-961D-4AF7-AE66-11A90BC7A525}"
WATCH_DERIVED_DATA="${WATCH_DERIVED_DATA:-/private/tmp/wharfwod-test-gate-dd}"
MODE=full
PLATFORM=both
for arg in "$@"; do
  case "$arg" in
    --full) MODE=full ;;
    --quick|--no-watch) MODE=quick ;;
    ios|android|both) PLATFORM="$arg" ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg (use --full | --quick, ios | android | both)" >&2; exit 2 ;;
  esac
done
RUN_WATCH=1
[[ "$MODE" == "quick" ]] && RUN_WATCH=0
[[ "$PLATFORM" == "android" ]] && RUN_WATCH=0

step() { printf '\n==> %s\n' "$*"; }

step "fvm flutter analyze (errors and warnings fail; infos are reported)"
# very_good_analysis reports style infos on older files; the bar for the
# gate is zero errors and zero warnings.
fvm flutter analyze --no-fatal-infos --fatal-warnings

step "fvm flutter test"
fvm flutter test

if [[ "$RUN_WATCH" == "1" ]]; then
  if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "xcodebuild not found; the watch XCTests need Xcode (pass --no-watch to skip)" >&2
    exit 1
  fi
  step "watch XCTests (WODTimerWatchTests on simulator $WATCH_SIM_ID)"
  # The simulator is booted by xcodebuild as needed and shut down after
  # so a gate run never leaves one running on the build machine.
  (
    cd ios
    xcodebuild test \
      -workspace Runner.xcworkspace \
      -scheme WODTimerWatch \
      -destination "platform=watchOS Simulator,id=$WATCH_SIM_ID" \
      -derivedDataPath "$WATCH_DERIVED_DATA" \
      -quiet
  )
  xcrun simctl shutdown "$WATCH_SIM_ID" >/dev/null 2>&1 || true
else
  step "watch XCTests skipped ($MODE, $PLATFORM)"
fi

# The Wear OS module (android/wear) has its own JVM tests; they ship with the
# Android side, so the ios-only gate skips them.
if [[ "$PLATFORM" != "ios" && -f android/wear/build.gradle.kts ]]; then
  step "Wear OS JVM tests (:wear:testDebugUnitTest)"
  JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"
  export JAVA_HOME
  if [[ ! -x android/gradlew ]]; then
    FLUTTER_ROOT="$(fvm flutter --version --machine | python3 -c 'import json,sys; print(json.load(sys.stdin)["flutterRoot"])')"
    cp "$FLUTTER_ROOT/bin/cache/artifacts/gradle_wrapper/gradlew" android/
    mkdir -p android/gradle/wrapper
    cp "$FLUTTER_ROOT/bin/cache/artifacts/gradle_wrapper/gradle/wrapper/gradle-wrapper.jar" android/gradle/wrapper/
    chmod +x android/gradlew
  fi
  (cd android && ./gradlew :wear:testDebugUnitTest -q)
fi

step "test gate green"
