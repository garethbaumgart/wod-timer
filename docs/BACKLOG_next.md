# Next release backlog

Notes from Gareth to pick up in the next set of changes. Add new items here as they come in; move each into the release's plan or spec when the build starts.

## 2.7.1 (27 Nov 2026): the halfway Mid tone, and Workouts switched off by 2.7.0's Health sheet

Built and merged, not shipped when this was written.

- **Halfway pips: the Mid tone.** Gareth asked whether the mid / halfway sound
  was the right one. Measured, the 2.5.0 pips sat on the change beep's exact
  pitch (1031 Hz), 2.5 dB under it with about a tenth of its energy: the
  quietest cue in the app, told from "round over" by rhythm alone. He heard
  five options inside a real Tabata round
  (https://claude.ai/artifact/F5n8SQX6Xb5P9msWt5macR) and chose C: two 120 ms
  pips 110 ms apart at 687 Hz, a fifth under the change beep and clear of the
  3, 2, 1 beep, at the change beep's level. `mid.wav` replaced on phone, Apple
  Watch and Wear OS; `tool/audio/mid_beep.py` writes it;
  `test/tool/beep_files_test.dart` holds the pitch, the level and the three
  identical copies. The two-pip shape stays: over 200 simulated echoing rooms
  its gap holds. Options and generator: branch `mock/halfway-sound-2026-11-27`.
- **Apple Watch: 2.7.0's Health sheet could switch Workouts off.** Gareth, on
  2.7.0 from TestFlight: no heart rate "even when enabled on the watch", and no
  countdown or start beep at the start of a workout. His timer showed the bell
  and his Health page "Workouts: not allowed". 2.7.0 asked every athlete for
  both permissions (save workouts, read the heart rate). For one who had
  already allowed workouts, watchOS shows the whole sheet again: Write Access
  with its switch already ON, then Read Access with it off. A tap on each
  switch "to enable it" turns Workouts off. No Workouts permission, no Health
  session: no heart rate, and the app sleeps when the wrist drops, so the get
  ready's 3, 2, 1 and the start beep are lost. Reproduced on a new simulator
  (asked as 2.6.2 did, then relaunched as 2.7.0: "Write Access:1", "Read
  Access:0").
  - The app asks only for what is still unanswered
    (`HealthWorkoutTracker.shareTypesToAsk`): an athlete who has answered the
    workouts question is shown Read Access alone.
  - Health never shows its sheet twice, so an athlete already there has to turn
    Workouts on in the watch's Settings. Home now says so once ("Workouts is
    off": what it costs and where to turn it on), keeps a red row under the
    timers while it lasts, and the Health page's line names the heart rate and
    the beeps. Back from Settings, Home reads the permissions again.
  - `tool/watch/health_permission_check.sh` runs the three Health UI tests, each
    on a brand-new simulator (Health keeps its answers through an uninstall):
    a new athlete, an updating athlete who taps every switch, and Workouts not
    allowed. Not in the gate; run it when the permissions or the session change.
  - 2.7.0 (build 39) was still waiting for App Review when this was found: it
    carries the fault for every athlete updating.

## 2.7.0 (26 Nov 2026): the watch release

From a review of both watch apps (Gareth, 26 Nov: "address major experience
flaws or bugs", then "build them all and ship them all together").

- **Apple Watch: heart rate.** On the timer, in the session glyph's slot,
  while the clock runs; the workout's average and peak on the end screen in
  the config line's place (a time cap shows both). Read from the Health
  session's own builder, so the numbers are the ones Health shows. The app
  asks to read the heart rate on Home, never over a countdown, reads nothing
  else and keeps no copy. A reading older than 15 s, a pause and the end show
  no number. New purpose strings; the privacy page and the App Review notes
  say the same. Wear OS has no heart rate yet: it needs the body sensor
  permission and Play's Health declaration.
- **Apple Watch: Home is a 2x2.** The wordmark on one line in the top bar and
  the four timers as tiles that fill the safe area, as on Wear OS: every
  watch shows all four at once (a 40mm showed one and a half, a 49mm two).
  The For Time tile leaves its direction to the setup screen.
- **Apple Watch: EMOM and Tabata setup fit the screen.** Since RUN IN
  WORKOUT joined START (2.3.0) the stacked values overflowed: labels over the
  title and back button, values at about 12pt on a 40mm and 20pt on a 49mm.
  They sit in one row sized from the room the row really has
  (`SetupValueRow`): EMOM 26pt on a 40mm to 43pt on a 49mm, Tabata 18pt to
  26pt. The setup capture scenes are now pushed, as the app shows them.
- **Wear OS: the timer keeps ticking with the screen off.** The foreground
  service kept the process, but nothing kept the processor: `dumpsys power`
  listed no wake lock of ours, so a real watch may suspend and the beeps and
  taps stop until the wrist comes back (an emulator never suspends). A
  partial wake lock (`AwakeHold`) is held from START to the end, let go
  while paused, always time-limited. Wants a real-watch check: wrist down
  for a whole EMOM, every round felt.
- **Wear OS: the Back button no longer loses the timer.** Back on the live
  screen popped to setup while the workout ran on behind it. Back now does
  nothing while a workout is under way or paused, and is DONE on the end
  screen.
- **Tests.** 211 watch unit tests, 77 Wear tests, `tool/wear/shape_check.sh`
  with a third flow (wake lock and Back), and a UI test target that drives
  the watch app with real touches (`WODTimerWatchUITests`): every tile opens
  its setup, a workout runs from a tile to the end screen, and a real Health
  session answers the permission sheet and shows a measured heart rate.
- **Store screens.** The Apple Watch set (eight captures of 2.7.0, in
  `fastlane/screenshots-watch/en-US/`), the wrist frame on both stores, the
  13-inch iPad set and Play's two tablet sets were re-captured: see
  `design/store-captions-2026-10/README.md`.
- **Google Play, the same evening.** The Wear build went up as vc20007:
  internal first, then `tool/wear/release_smoke.sh` on both round emulators
  (the exact uploaded bundle, driven by real taps on its labels: the four
  tiles, an EMOM through pause, Back, screen off and HOLD TO STOP, a For
  Time through FINISH, the wake lock at every step), then production. The
  phone set and both tablet sets went up in one commit. Run that smoke
  between the internal upload and the promote on every Wear release.

Left for a decision, not built:

- A right swipe on the Wear live screen closes the app to the watch face (the
  workout runs on and the chip brings it back): the window's own
  swipe-to-dismiss, which `userSwipeEnabled = false` does not stop.
- Heart rate on Wear OS (BODY_SENSORS and the Play Health declaration).

## Shipped as 2.5.1 (15 Nov 2026): end screens lifted, with fact tiles

- **Option 1 of the end-screen mocks** (https://claude.ai/artifact/BrKtJQCp2aKoXZ91xPAEzP,
  asked 15 Nov 2026): upright, the result sits under the header (header 28pt
  down, 36pt to the hero) and three fact tiles sit under it, all from the
  session: AMRAP time, per round (time / rounds; STARTED when no round was
  counted), finished; For Time cap, time under the cap (only a FINISH; a stop
  or the cap shows STARTED), finished; EMOM time, interval, finished; Tabata
  time, work done, finished. The last tile says STOPPED or ENDED (time cap)
  when that is what happened, and follows the phone's 12 or 24-hour clock.
  The AMRAP wheel is capped at 100pt so the tiles fit; the EMOM and Tabata
  "total" line moved into the TIME tile. Landscape unchanged. First Wharf
  release on Flutter 3.50.0.

## Shipped as 2.5.0 (14 Nov 2026): mid-round pips, bigger setup dials

- **Mid-round pips, no setting** (asked 14 Nov 2026, option 1 of the round 1
  mocks with the pill removed): `assets/audio/beeps/mid.wav`, two 0.1 s clips
  of the high beep 160 ms apart at x0.75 (peak 2.5 dB under the high beep),
  halfway through every EMOM interval and Tabata work block, and halfway
  through an AMRAP or For Time clock. Phases under 10 s get none; once per
  phase; a tick more than a second past the midpoint stays quiet (no late pip
  after a suspension). Plays with Beeps only and every voice; Silent mutes it.
  Phone, Apple Watch and Wear OS (the Wear build waits for Google's first Wear
  review). Not added to the watch's wrist alerts (iOS caps pending
  notifications at 64). Mocks: https://claude.ai/artifact/Knm6pYiiBNaap8wYvziKQE
- **Bigger, higher setup dials** (option C of
  https://claude.ai/artifact/2faSDCrAcHSFfXDUoLzfYC): wheels 96pt rows (72pt
  digits, was 42) in 184pt columns with 8pt edges, the bezel full width inside
  8pt edges (ring 241 to 337pt on a 393pt phone), both lifted so the space
  above is half the space below. White ticks on the setup timeline mark where
  the pips land. Landscape unchanged.

## Built on feat/gym-beeps (4 Oct 2026), waiting on Gareth's listen

- **Gym-timer beeps in every workout.** Three low beeps (about 435.5 Hz) with 3, 2, 1 seconds left in every phase, then the high beep (about 1031 Hz) on the change with the voice line on it, matched to the SmartWOD recording Gareth chose. Spoken 3-2-1 and 5-4-3-2-1 replaced by the beeps; optional lines never talk over the count-in or another line; Beeps only = beeps without voice. Phone and watch. Assets: `assets/audio/beeps/`, voices levelled by `tool/audio/level_voices.py` (see `tool/audio/README.md`). Major mocks of all four workouts, rendered from the app's own cue log (`test/tool/cue_timeline_test.dart`): https://claude.ai/artifact/AoN3cUXdV73Q4ozoVAFRFC
- **Rate block (option 14 of https://claude.ai/artifact/AYaE7K23rdhJda7HHfQauH).** "How is Wharf WOD working for you?" with Love it (store page) and Could be better (feedback mail), both always shown (no review gating). Replaces the Rate and Send feedback rows.
- **Major is a Drill Sergeant.** Phone "Major (Drill Sergeant)", watch "Drill sergeant", same order.

## Shipped as 2.2.0 (5 Oct 2026): iOS build 22 submitted, Play vc14 production

- **The watch stays awake**: HKWorkoutSession per workout, haptic patterns
  (GO a double knock, rounds, rest, 3-2-1 taps), audio session fallback,
  Sound check row, Health row, whole-millisecond ticks. Plan:
  `docs/PLAN_2.2.0_watch_background.md`.

## Shipped as 2.4.0 (8 Nov 2026): wrist alerts, honest session state, cue cleanup

- Local notifications stand in for the cues when no Health session keeps
  the watch app alive (Track workouts off, permission unanswered, Apple's
  Workout app recording); the live screen says which; no restart after a
  takeover; Stay on screen row (Return to App). Plan:
  `docs/PLAN_2.4.0_watch_wrist_alerts.md`.
- **Cue cleanup asked for on 24 Oct 2026.** The encouragement lines are
  gone on all three ports (Keep going / Come on at a third, Almost there at
  85%), and so are the coin flips: GO always says "Go", the end always
  "Good job" (a capped For Time keeps the neutral end tone). Get ready,
  Rest, Next round / Last round, Halfway, Ten seconds and the gym beeps
  stay. Beeps is the voice for an athlete who never chose one: a missing
  phone `app_voice` reads as Beeps only (a stored index keeps its meaning,
  so a saved Major stays Major), a missing watch `watch_voice_beeps` or
  Wear `wear_voice_beeps` reads as on unless another voice key shows an
  earlier choice. Nothing stored is rewritten. The retired clips stay in
  the bundles (the watch and Wear sound checks still play "Let's go").
  Rides the 2.4.0 release with the wrist alerts.

## Still open

- Record "Round 2", "Round 3" and so on, plus "Well done", if wanted (EMOM says "Next round" today).

## Already merged, waiting to ship

