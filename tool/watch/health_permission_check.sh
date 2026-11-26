#!/bin/bash
# The Apple Watch app's Health permissions and session, on real watchOS sheets.
#
#   tool/watch/health_permission_check.sh [test name ...]
#
# Runs each WatchHealthSessionUITests test on a simulator that has never run
# the app. Health keeps its answers through an uninstall, so a used
# simulator shows no sheet: every test gets a new one, deleted afterwards.
# With no names it runs the three that check the app:
#
#   testARealHealthSessionShowsAMeasuredHeartRate
#       a new athlete: Write Access, then Read Access, then a measured heart rate
#   testAnUpdatingAthleteIsAskedForTheHeartRateAloneAndKeepsTheSession
#       allowed workouts before 2.7.0, taps every switch shown: only Read Access
#       is shown, the session still runs (27 Nov 2026: 2.7.0 showed the Workouts
#       switch again, already on, and a tap turned it off)
#   testWorkoutsNotAllowedIsSaidOnHomeOnce
#       Workouts not allowed: Home's notice, its row, the bell on the timer
#
# About two minutes a test. Not in scripts/test_gate.sh: run it when the
# Health permissions or the workout session change. Screenshots land in
# OUT (default /tmp/wharfwod-health-check).
set -u
cd "$(dirname "$0")/../.."

OUT="${OUT:-/tmp/wharfwod-health-check}"
DERIVED="${WATCH_DERIVED_DATA:-/private/tmp/wharfwod-test-gate-dd}"
DEVICE_TYPE="${WATCH_DEVICE_TYPE:-Apple Watch Ultra 3 (49mm)}"
TESTS=("$@")
if [ ${#TESTS[@]} -eq 0 ]; then
  TESTS=(
    testARealHealthSessionShowsAMeasuredHeartRate
    testAnUpdatingAthleteIsAskedForTheHeartRateAloneAndKeepsTheSession
    testWorkoutsNotAllowedIsSaidOnHomeOnce
  )
fi

RUNTIME=$(xcrun simctl list runtimes | grep -i watchOS | tail -1 | grep -oE "com\.apple\.CoreSimulator\.SimRuntime\.[A-Za-z0-9.-]+")
TYPE=$(xcrun simctl list devicetypes | grep -F "$DEVICE_TYPE" | grep -oE "com\.apple\.CoreSimulator\.SimDeviceType\.[A-Za-z0-9.-]+" | head -1)
if [ -z "$RUNTIME" ] || [ -z "$TYPE" ]; then
  echo "no watchOS runtime or no '$DEVICE_TYPE' device type" >&2
  exit 2
fi
mkdir -p "$OUT"
fail=0
for name in "${TESTS[@]}"; do
  sim=$(xcrun simctl create "WharfHealthCheck" "$TYPE" "$RUNTIME")
  xcrun simctl boot "$sim"
  xcrun simctl bootstatus "$sim" -b >/dev/null 2>&1
  rm -rf "$OUT/$name.xcresult" "$OUT/$name"
  xcodebuild test -project ios/Runner.xcodeproj -scheme WODTimerWatchUITests \
    -destination "platform=watchOS Simulator,id=$sim" -derivedDataPath "$DERIVED" \
    -resultBundlePath "$OUT/$name.xcresult" \
    -only-testing:"WODTimerWatchUITests/WatchHealthSessionUITests/$name" > "$OUT/$name.log" 2>&1
  code=$?
  grep -E "HEART-" "$OUT/$name.log" | cut -c1-400
  xcrun xcresulttool export attachments --path "$OUT/$name.xcresult" --output-path "$OUT/$name" >/dev/null 2>&1
  if [ $code -eq 0 ]; then
    echo "PASS $name"
  else
    echo "FAIL $name (log: $OUT/$name.log)"
    grep -E "error:|XCTAssert|failed -" "$OUT/$name.log" | cut -c1-300 | head -8
    fail=1
  fi
  if [ "${KEEP_SIM:-0}" = "1" ]; then
    echo "kept simulator $sim"
  else
    xcrun simctl shutdown "$sim" >/dev/null 2>&1
    xcrun simctl delete "$sim"
  fi
done
exit $fail
