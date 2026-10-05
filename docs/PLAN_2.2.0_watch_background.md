# 2.2.0: the watch stays awake (Gareth's wrist notes, 5 Oct 2026)

Gareth timed an EMOM on his Apple Watch with 2.1.0 (Major voice) and found:

1. the GO vibration felt soft;
2. none of the EMOM round-change vibrations arrived;
3. checking the watch mid workout showed the watch face, not the app, though
   the clock was right once the app was reopened;
4. no audio cues at all.

## Root cause

A watchOS app is suspended the moment the wrist drops. Nothing in 2.1.0 kept
the app alive, so after GO every beep, line and tap was skipped until the
next wrist raise (the clock caught up from the wall clock, which is why it
looked right). Apple's documentation is explicit: `WKInterfaceDevice.play`
does nothing while the app is in the background, "the only exception are
apps with an active workout session", and short audio clips in the
background likewise need an active workout session plus the `audio`
background mode.

The one firm GO Gareth felt was `.start`; the round changes that could
have fired were `.click`, which is barely perceptible mid workout.

## Changes

- **HKWorkoutSession for every workout** (`Services/WatchWorkoutTracker.swift`).
  START opens the session (so the app survives GET READY), GO begins the
  Health workout, pause / resume are mirrored, the end finishes the record.
  A cancelled get ready or a stop inside the first minute discards it. Tabata
  is saved as High Intensity Interval Training, the rest as Functional
  Strength Training, indoor. The watch shows the workout icon on the face
  and comes back to the app on wrist raise.
- **Health settings row** on Home: Track workouts on/off (one additive key,
  `watch_health_track`, missing = on), the permission state, and what Off
  costs (cues stop when the wrist drops). The single permission (save
  workouts) is asked when Home appears, the way workout apps do.
- **Entitlement, background modes, purpose strings**: `WODTimerWatch.entitlements`
  (`com.apple.developer.healthkit`), `WKBackgroundModes` = workout-processing +
  audio, `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` on the
  watch (and the iOS Info.plist, belt and braces). HEALTHKIT was added to the
  watch App ID `app.mentalmetal.wharfwod.watchkitapp` via the App Store
  Connect API on 5 Oct 2026; the ship lane re-mints the App Store profile.
- **Haptic patterns** (`Services/WatchHapticService.swift`): watchOS has no
  intensity control, so strength is the pattern. `.notification` (the
  firmest single haptic) leads every change; GO is two of them, the last
  round three, a rest adds a falling pulse, a round a rising one. The 3, 2, 1
  before every change (not only get ready) is a firm `.start` tap. One cue
  per tick: when a Tabata round starts as its rest ends, only the round cue
  plays. Patterns space their taps by at least 0.4s (the engine needs 100ms).
- **Audio session**: `.playback` with duck + spoken-audio interruption, falling
  back to plainer options rather than staying on a category that never
  reaches the speaker. A **Sound check** row under Voice plays the high beep
  with "Let's go" and reports the output route and the media volume, the two
  things that explain a silent watch (a watch whose media volume sits at 0%
  plays nothing; the Crown in Now Playing raises it).
- **Clock accuracy**: the tick handler truncated each delta to whole
  milliseconds, losing up to 1ms a tick, about three seconds over a 10:00
  AMRAP. It now differences whole milliseconds of the engine clock
  (regression test: 6000 ticks of 100.7ms read 604s, not 600s).
- Crash recovery: `handleActiveWorkoutRecovery` closes a session handed back
  after a crash so it never blocks the next start.

## Tests

`ios/WODTimerWatchTests/Application/WatchCueTests.swift`: patterns, pattern
cancellation, GO / round / last round / rest on the wrist, one cue per tick,
pause / resume / stop / finish / cancel reaching the session, the
millisecond regression, the Health switch, activity types, the bundle's
background modes and purpose strings, the audio session category and the
sound check. 116 -> 131 watch tests.

## Before the App Store release (not needed for TestFlight)

- Privacy policy page (mentalmetal.app/wharfwod): say the watch app saves
  workouts to Apple Health on the device and reads nothing; health data
  never leaves the watch. App Review Guideline 5.1.3 asks for it.
- App Review notes: mention HealthKit is used to keep the timer running and
  save the workout.
- A real-watch check of: wrist-down cues, wrist-raise return, the Health
  permission sheet, a saved workout in the Fitness app.

## Known trade-off

Apple Watch runs one workout session at a time. Starting a Wharf WOD
workout ends a workout running in Apple's Workout app (and vice versa). The
Health switch turns the session off for athletes who track the whole class
in Workout, at the cost of cues while the wrist is down.
