# 2.4.0: wrist alerts when no session keeps the watch app alive (8 Nov 2026)

Gareth, Apple Watch Ultra, 2.3.3 (the watch code unchanged since 2.3.0):
after the screen has been off "for a while" the app is gone from the
foreground and he scrolls to find it; the clock is right when he reopens
it; the beeps and vibrations between rounds did not happen while it was
off screen. The same report as 15 Oct on 2.2.0.

## Root cause

Apple's frontmost rule (watchkit "Taking advantage of frontmost app
state", healthkit "Running workout sessions", verified 8 Nov 2026): after
the wrist drops ANY app stays frontmost for the Return to Clock period
(Settings > General > Return to Clock, default After 2 minutes) and can
still play haptics there; then it goes to the background and is suspended,
unless a workout session runs. A session app runs for the whole session,
"can alert the user using audio or haptic feedback while running in the
background", and the face shows a glyph that returns to it.

So cues that work for about two minutes and then stop mean the Health
workout session was NOT running. The engine counts from wall-clock dates
and catches up the instant the app wakes, which is what "it ran in the
background" looks like from outside. The 15 Oct CPU theory (2.2.1) was
unlikely for the same reason.

Why no session, each with its check on the watch:

1. Apple's Workout app was recording the class. One session at a time and
   the Workout app's keeps priority (24 Oct verdict). Check: no Wharf WOD
   workout in Fitness afterwards.
2. Track workouts off. Check: Home > Health says Off.
3. The Health permission sheet was never answered. Home said On regardless
   (2.2.0 only reported an explicit denial). Check: the Health page.
4. The session failed to start. Check: the Health page.

The glyph at the top of the watch face mid-WOD means the session is alive
and only the Return to Clock setting is at play.

Also found: `HealthWorkoutTracker.clear()` restarted our session whenever
`pendingWorkout` was set, including after
`didFailWithError(errorAnotherWorkoutSessionStarted)`: no backoff, so it
either ended the athlete's Apple workout or looped against it.

## Changes (watch only)

- **Wrist alerts** (`Application/WristAlertPlan.swift`,
  `Services/WristAlerts.swift`): when no session of ours keeps the app
  alive, the view model schedules a local notification for every change
  still to come, from the session's own clock (get ready included): EMOM
  and Tabata rounds ("Round 3 of 10", "Last round"), Tabata rests ("Rest",
  "Last rest"), an AMRAP's "Halfway" (2:00 and up) and the end ("Finished",
  "Time cap"). The body is the config line ("EMOM · 10 × 1:00"). The system
  taps and chimes; a tap on the alert brings the timer back. Replanned on
  resume and skip; cancelled on pause, stop, finish, the end, cancel and
  DONE; capped at 60 of the system's 64 with the end always kept. The app
  delegate suppresses alerts while the app is on screen or frontmost
  (`willPresent` returns nothing), because the app plays its own cue
  there; a fresh launch clears alerts a killed run left behind. Default
  sound, no custom haptic (watchOS offers none for notifications).
- **Session state through the protocol**: `WorkoutTracking.status` and
  `onStatusChange`; `Status.takenOver` for another app's session ending
  ours; `keepsAppAlive` (running or paused). The view model switches to
  alerts the moment the session is lost mid-workout and remembers when
  (`sessionLostAt`) for the Health page's note.
- **No restart on a takeover**: `clear(_:restart:)` restarts a pending
  workout only when we closed the session ourselves (AGAIN after a
  finish). A session that dies under the workout is left alone.
- **Honest state on screen**: a glyph in the back button's slot of the
  live and paused screens (figure = Health session on, bell = alerts
  standing in, crossed bell in red = neither, nothing while starting);
  Home's Health row says Off, Not allowed, Not answered or On; the Health
  page gains an Off screen section (what the alerts do, the alerts
  permission with an Allow alerts button, the last workout's takeover note,
  the Return to App setting).
- **Stay on screen** (`Presentation/StayOnScreenView.swift`): a Home row,
  shown until read once (`watch_hint_return_to_app_seen`), with the four
  steps to Settings > General > Return to Clock > Wharf WOD > Custom >
  Return to App, and why the switch is only listed after a session has run.
- **Permissions**: the notifications permission is asked when Home
  appears, as the Health one is. No new entitlement or plist key.
- **Site FAQ** (mentalmetal-site branch `wharf-wod-faq-wrist-alerts`):
  "The watch went back to the clock face mid-WOD, and the taps stopped",
  plus pointers from the Health and RUN IN WORKOUT answers. Merges when
  2.4.0 is live.

## Tests

`ios/WODTimerWatchTests/Application/WristAlertTests.swift`: the plan per
mode, the schedule from the session's clock (get ready, mid-round), a
paused or finished session plans nothing, the 100-round cap keeps the end;
the view model with no session, a running session, pause/resume, stop,
finish, the end, cancel, a takeover mid-workout (alerts from the current
round, the note), the session coming up after a pending permission, the
glyph states; Home's Health label, the takeover error mapping,
`keepsAppAlive`, the notification status mapping, the Health page lines.
`WatchCueTests` keep passing with the spy tracker reporting a running
session.

## What only Gareth's watch can show

The simulator has no frontmost timeout, no Return to Clock and a Noop
tracker, so the proof is a WOD on the Ultra with the wrist down for more
than two minutes:

1. Home > Health: what the row says now (Off / Not allowed / Not answered /
   On) tells which of the four causes it was.
2. Start an EMOM, drop the wrist for three minutes. Expected with no
   session: an alert (tap + chime) at each minute while the face shows,
   tapping one opens the timer. Expected with a session: the taps as
   before, the face with the glyph at the top after two minutes (or the
   app itself once Return to App is on).
3. The glyph at the top left of the live screen before dropping the wrist:
   figure, bell or crossed bell.
4. Start a Functional Strength workout in Apple's Workout app first, then
   a Wharf WOD EMOM: the glyph should turn to the bell within a few
   seconds and the alerts should carry the rounds; the Apple workout keeps
   running; the Health page shows the takeover note afterwards.

## Not in 2.4.0

The cue cleanup and Beeps default asked for on 24 Oct (three ports), the
AMRAP / For Time hand-off, the whole-WOD session. Pending voice clips:
`docs/SHIP_REMINDERS.md`.
