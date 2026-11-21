#!/usr/bin/env bash
# Android release launch check: the store build must start. Builds the release
# bundle the way the store lane does (`flutter build appbundle --release`, R8
# on), turns it into one universal APK with bundletool, installs that on the
# release-check emulator, opens it from its launcher entry, and fails unless
# the process is still alive, the app's first screen drew, and logcat holds no
# crash from the app.
#
#   scripts/release_launch_check.sh               build the bundle, then check it
#   scripts/release_launch_check.sh <file.aab>    check a bundle built already,
#                                                 such as the one a lane uploads
#
# Why (21 Nov 2026): Squish 1.12.0's first candidate passed every test and
# gate, yet its release build died at every launch: R8 full mode had removed a
# constructor Room creates by reflection once WorkManager came in. Debug
# builds and Dart tests never show that class of bug; only the shrunk store
# build does. Same check as Squish's app/scripts/release_launch_check.sh.
#
# The gate's own build carries none of the Doppler keys, so an emulator never
# reaches Sentry, Aptabase or RevenueCat; pass the lane's bundle to check the
# keyed build itself.
#
# Env: MM_RELEASE_AVD (default MM_Release_Check_API_34, created on first use
# from the android-34 google_apis arm64 image), MM_RELEASE_PORT (default: the
# first free even port from 5680 down), ANDROID_HOME. It only ever drives its
# own AVD, holds a lock every app's copy of this check shares, and shuts down
# any emulator it booted. Logs stay in a temp folder when it fails.
set -uo pipefail
# Never let a git hook's GIT_DIR leak into the Flutter tool.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

# ---- this app ------------------------------------------------------------------
APP_NAME="Wharf WOD"
PKG=app.mentalmetal.wharfwod
# Runtime permissions to grant up front, so the first screen is the app's own
# rather than a system permission sheet over it (none asked for at start-up).
GRANTS=""
# --------------------------------------------------------------------------------

ARG="${1:-}"
if [ -n "$ARG" ]; then
  [ -f "$ARG" ] || { echo "RELEASE LAUNCH FAILED: no bundle at $ARG"; exit 1; }
  ARG="$(cd "$(dirname "$ARG")" && pwd)/$(basename "$ARG")"
fi
cd "$(dirname "$0")/.." || exit 1
AVD="${MM_RELEASE_AVD:-MM_Release_Check_API_34}"
IMAGE="system-images;android-34;google_apis;arm64-v8a"
SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
ADB="$SDK/platform-tools/adb"
LOCK="$HOME/Library/Caches/mm-release-launch-check.lock"
LOGDIR="$(mktemp -d -t mm-release-launch)"
SERIAL=""; BOOTED=""; HAVE_LOCK=""; PASSED=""

cleanup() {
  # Nothing of the app's is left on the AVD: an install kept on its disk wakes
  # at the next cold boot (boot receivers) and can die under the next run.
  [ -n "$SERIAL" ] && "$ADB" -s "$SERIAL" uninstall "$PKG" >/dev/null 2>&1
  [ -n "$BOOTED" ] && "$ADB" -s "$BOOTED" emu kill >/dev/null 2>&1
  [ -n "$HAVE_LOCK" ] && rm -rf "$LOCK"
  [ -n "$PASSED" ] && rm -rf "$LOGDIR"
}
trap cleanup EXIT
trap 'exit 130' INT TERM
fail() { echo "RELEASE LAUNCH FAILED: $*"; echo "   logs: $LOGDIR"; exit 1; }

# ---- the bundle ------------------------------------------------------------------
if [ -n "$ARG" ]; then
  AAB="$ARG"
  echo "== checking $AAB"
else
  echo "== building the release bundle (R8 on, as the store lane builds it)"
  fvm flutter build appbundle --release >"$LOGDIR/build.log" 2>&1 \
    || { tail -25 "$LOGDIR/build.log"; fail "release build (see build.log)"; }
  BUILT=build/app/outputs/bundle/release/app-release.aab
  [ -f "$BUILT" ] || fail "no $BUILT"
  # Out of the lane's path: a keyless bundle must never be the one a lane uploads.
  mv "$BUILT" "$LOGDIR/app-release.aab"
  AAB="$LOGDIR/app-release.aab"
  # R8 writes a fresh mapping on every shrunk build; without one, this build
  # was not shrunk the way a store build is.
  [ -s build/app/outputs/mapping/release/mapping.txt ] \
    || echo "   note: R8 wrote no mapping, so this build was not shrunk like a store build"
fi

command -v bundletool >/dev/null 2>&1 || fail "bundletool not found (brew install bundletool)"
echo "== universal APK from the bundle (bundletool)"
bundletool build-apks --bundle="$AAB" --output="$LOGDIR/app.apks" --mode=universal --overwrite \
  >"$LOGDIR/bundletool.log" 2>&1 || fail "bundletool build-apks (see bundletool.log)"
unzip -p "$LOGDIR/app.apks" universal.apk >"$LOGDIR/universal.apk" 2>/dev/null
[ -s "$LOGDIR/universal.apk" ] || fail "no universal.apk in $LOGDIR/app.apks"

# ---- the emulator ----------------------------------------------------------------
# One lock for every app's check: they share the AVD.
waited=0
until mkdir "$LOCK" 2>/dev/null; do
  holder="$(cat "$LOCK/pid" 2>/dev/null)"
  if [ -n "$holder" ] && ! kill -0 "$holder" 2>/dev/null; then rm -rf "$LOCK"; continue; fi
  [ $waited -eq 0 ] && echo "== waiting for another release launch check ($LOCK)"
  [ $waited -ge 3600 ] && fail "gave up waiting for $LOCK"
  sleep 10; waited=$((waited + 10))
done
echo $$ >"$LOCK/pid"; HAVE_LOCK=1

if ! "$SDK/emulator/emulator" -list-avds 2>/dev/null | grep -qx "$AVD"; then
  echo "== creating the $AVD emulator (first use)"
  [ -d "$SDK/${IMAGE//;//}" ] || fail "no $IMAGE (sdkmanager \"$IMAGE\")"
  echo no | JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}" \
    "$SDK/cmdline-tools/latest/bin/avdmanager" create avd -n "$AVD" -k "$IMAGE" -d pixel_6 \
    >"$LOGDIR/avd.log" 2>&1 || fail "could not create $AVD (see avd.log)"
fi

find_ours() {
  for s in $("$ADB" devices | awk '/^emulator-.*device$/{print $1}'); do
    [ "$("$ADB" -s "$s" emu avd name 2>/dev/null | head -1 | tr -d '\r')" = "$AVD" ] && { echo "$s"; return; }
  done
}
port_free() { ! lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1 && ! lsof -nP -iTCP:"$(($1 + 1))" -sTCP:LISTEN >/dev/null 2>&1; }

SERIAL="$(find_ours)"
if [ -z "$SERIAL" ]; then
  PORT="${MM_RELEASE_PORT:-}"
  if [ -z "$PORT" ]; then
    for p in $(seq 5680 -2 5600); do port_free "$p" && { PORT=$p; break; }; done
  fi
  [ -n "$PORT" ] || fail "no free emulator port between 5600 and 5680"
  echo "== booting $AVD on port $PORT"
  "$SDK/emulator/emulator" -avd "$AVD" -port "$PORT" -no-window -no-audio -no-boot-anim \
    -no-snapshot-save >"$LOGDIR/emulator.log" 2>&1 &
  EMU_PID=$!
  BOOTED="emulator-$PORT"
  for _ in $(seq 1 120); do
    kill -0 "$EMU_PID" 2>/dev/null || fail "the emulator exited while booting (see emulator.log)"
    [ "$("$ADB" -s "$BOOTED" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] && { SERIAL="$BOOTED"; break; }
    sleep 2
  done
fi
[ -n "$SERIAL" ] || fail "the $AVD emulator did not boot"
adb() { "$ADB" -s "$SERIAL" "$@"; }
# Waits (up to 60 s) until the system has delivered its queued broadcasts:
# after a cold boot, BOOT_COMPLETED can still be reaching apps when the
# install starts, and an old install's process dying then is not this build.
settle() {
  adb shell am wait-for-broadcast-idle >/dev/null 2>&1 &
  local w=$!
  for _ in $(seq 1 60); do kill -0 "$w" 2>/dev/null || return 0; sleep 1; done
  kill "$w" 2>/dev/null
}
settle

echo "== installing on $SERIAL ($AVD)"
# A signing key other than the one installed refuses an update: start clean.
adb uninstall "$PKG" >/dev/null 2>&1
adb install "$LOGDIR/universal.apk" >"$LOGDIR/install.log" 2>&1 || fail "install (see install.log)"
for g in $GRANTS; do adb shell pm grant "$PKG" "$g" >/dev/null 2>&1; done
settle

# ---- the launch ------------------------------------------------------------------
COMPONENT="$(adb shell cmd package resolve-activity --brief \
  -a android.intent.action.MAIN -c android.intent.category.LAUNCHER "$PKG" 2>/dev/null | tr -d '\r' | tail -1)"
case "$COMPONENT" in "$PKG"/*) ;; *) fail "no launcher entry for $PKG";; esac
adb shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
adb shell wm dismiss-keyguard >/dev/null 2>&1
echo "== launching $COMPONENT"
adb logcat -b all -c
adb shell am start -W -a android.intent.action.MAIN -c android.intent.category.LAUNCHER \
  -n "$COMPONENT" >"$LOGDIR/start.log" 2>&1
drew=""
for _ in $(seq 1 30); do
  sleep 1
  pid="$(adb shell pidof "$PKG" 2>/dev/null | tr -d '\r')"
  [ -n "$pid" ] || break
  # Flutter's semantics reach uiautomator once the first frame is up: a node
  # of the app's with words on it means it drew a screen, not just a window.
  adb shell rm -f /sdcard/mm-launch.xml >/dev/null 2>&1
  adb shell uiautomator dump /sdcard/mm-launch.xml >>"$LOGDIR/uiautomator.log" 2>&1
  if adb shell cat /sdcard/mm-launch.xml 2>/dev/null | tee "$LOGDIR/screen.xml" \
      | grep -Eq "(text|content-desc)=\"[^\"]+\"[^>]*package=\"$PKG\"|package=\"$PKG\"[^>]*(text|content-desc)=\"[^\"]+\""; then
    drew=1; break
  fi
done
sleep 3  # a crash just after the first frame still counts
adb logcat -d >"$LOGDIR/logcat.txt" 2>&1
adb shell rm -f /sdcard/mm-launch.xml >/dev/null 2>&1

dart_errors() { grep -E " E flutter|E/flutter" "$LOGDIR/logcat.txt" | grep -iE "unhandled exception|error" | head -6; }
if grep -A2 "FATAL EXCEPTION" "$LOGDIR/logcat.txt" | grep -q "Process: $PKG"; then
  grep -A14 "FATAL EXCEPTION" "$LOGDIR/logcat.txt" | head -18
  fail "the release build crashed (FATAL EXCEPTION)"
fi
if grep -q ">>> $PKG <<<" "$LOGDIR/logcat.txt"; then
  grep -B2 -A6 ">>> $PKG <<<" "$LOGDIR/logcat.txt" | head -12
  fail "the release build crashed (native signal)"
fi
if [ -z "$(adb shell pidof "$PKG" 2>/dev/null | tr -d '\r')" ]; then
  dart_errors
  fail "the process is not running after launch"
fi
if [ -z "$drew" ]; then
  dart_errors
  fail "$APP_NAME's first screen never drew"
fi
if [ -n "$(dart_errors)" ]; then
  echo "   note: Dart errors at start-up (not failing the check):"
  dart_errors | sed 's/^/     /'
fi
# The words on the first screen, as the proof it drew.
LABELS="$(tr '>' '\n' <"$LOGDIR/screen.xml" | grep "package=\"$PKG\"" \
  | grep -oE "(text|content-desc)=\"[^\"]+\"" | sed -E 's/^[a-z-]+="//; s/"$//' \
  | tr '\n' ' ' | tr -s ' ' | cut -c1-100)"
echo "   first screen: $LABELS"
adb shell am force-stop "$PKG" >/dev/null 2>&1
PASSED=1
echo "release launch: $APP_NAME's store build starts, draws its first screen and stays up"
