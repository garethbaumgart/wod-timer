# Wharf WOD 1.3.0: big clock

Source: the 2 Oct 2026 UX review (https://claude.ai/artifact/Vij6NmkfU4xhrc9n9gVTab), nine
reviewer lenses, 28 of 30 themes verified. Gareth: "love it. Build it and deploy to app stores."
All of "Your calls" go with the recommended vote. Brief: less is more, big numbers during a
workout, high value low friction.

## Rules for every change

- No em dashes in app copy or code comments. Nothing under 15pt anywhere.
- Never run `build_runner` (dead on Flutter 3.47; generated files are copied in, gitignored).
  New providers are hand-written `Provider<T>` like `setupMemoryProvider`.
- Settings / prefs changes are additive: new keys only, never delete or rewrite an old key.
- Any layout move gets a geometry assertion (`tester.getRect`), not just a finder.
- `fvm flutter analyze` (0 errors, 0 warnings; the 76 pre-existing infos are fine) and
  `fvm flutter test` green after every commit. Commit per item: `1.3.0: <id> <summary>`.

## The format, type and colour rule (both tracks)

- **Clock format:** minutes never zero-padded (`9:45`, `0:11`, `12:30`), seconds always two
  digits. Countdown clocks go bare seconds under a minute; a phase of 60s or less shows `60`
  rather than `1:00`. Count-up clocks and completion heroes always M:SS.
- **Phase lengths** (Tabata values, config lines, Home): `setupPhase()` in setup_stepper.dart,
  `20s` under a minute, `2:00` from a minute up. Clock durations use `setupClock()`.
- **Type scale:** 15pt captions (letter-spaced, #9A9AA2), 17pt rows, 26pt secondary, 34pt phase
  word, 56pt hero word / landscape round, 72pt setup values, 80pt live round, width-fill clock.
- **Colour:** orange get ready, green work, blue rest, grey paused, on the digits, the bar and
  the phase word only. START is the only green control on a setup screen. Everything else is
  white, grey or (the hold-to-stop ring) red.

## F0 (done, c858271)

Silent voice replaces the Sound Effects switch (one-time migration of 1.2.x users with Sound
Effects off, golden-fixture test); Keep Screen On and Sound Effects rows removed from Settings;
`setupPhase()` formatter; voice labels `Beeps only` / `Silent`, chip short labels `Beeps` /
`Silent` with distinct icons.

## Track A: live and completion screens (owner: main session, branch feat/1.3.0-big-clock)

Files: timer_active_page.dart, timer_notifier.dart (NOT `_configureVoice`), timer_session.dart
(`timeRemaining` getter only), application timer_state.dart, a new live-hints prefs file,
integration_test/*, their tests.

- A1 Clock: un-padded MM:SS through one formatter, 8pt side gutters, 60s-or-less phases bare.
- A2 Sub-clock: delete REMAINING / ELAPSED / STARTS IN, the 13pt pill and its top 40pt slot.
  One fixed 40pt phase line under the clock (34pt w800 letter-spaced, phase colour, blank when
  there is no phase): GET READY, REST, WORK (Tabata only), PAUSED (`PAUSED · WORK` /
  `PAUSED · REST` in Tabata), and for the last 5s of a Tabata phase `NEXT · WORK` /
  `NEXT · REST` in the next phase's colour, `LAST REST` through the final rest. Replaces the
  14pt "WORK in 4s" line.
- A3 Round slot, fixed height: EMOM / Tabata `2/10` at 80pt w900 white; AMRAP the count at 80pt
  with a 15pt ROUNDS caption, or `TAP TO COUNT` at 34pt grey in the same slot while 0 and never
  counted before (one additive prefs flag, set on the first counted round); For Time count-up
  `CAP 20:00` at 26pt w700 grey once work starts; count-down nothing. Prep: `TAP TO SKIP` 34pt
  grey in the round slot.
- A4 Controls: running shows one 96pt Pause disc (2.5pt white80 ring, 12% white fill, 40pt
  glyph). Paused shows the 64pt hold-to-stop circle beside a 96pt filled white Resume disc.
  For Time running: white FINISH (62pt, black 18pt text, flag glyph) on the left of the row,
  Pause on the right; paused For Time: FINISH above, Stop + Resume below. Prep: hold-to-stop
  circle only (same hold, returns to setup). Hold ring starts on pointer down (800ms, no 500ms
  dead zone); a short press shows HOLD inside the button for 1.6s, no layout shift.
- A5 Gestures: delete double-tap and both swipes. Paused: tap anywhere outside the control row
  resumes. Prep: tap skips, instantly. AMRAP running: tap counts, with a 700ms cooldown, also
  armed at GO. VoiceOver label updated to match.
- A6 Prep not pausable (notifier-level canPause excludes preparing; pause() no-ops). Bar hidden
  in prep, slot reserved.
- A7 Paused keeps the phase colour on the digits (dimmed pulse) instead of white.
- A8 Landscape live: clock alone across the full width (16pt gutters), then one bottom row:
  score / round (56pt, with the phase word on the same line when there is one) and the bar on
  the left, the controls on the right (paused: Stop left corner, score, Resume right corner).
  For Time puts FINISH in the row before Pause.
- A9 Completion: status word (26pt; `Finished` white, `Stopped` grey, `Time cap` grey) + 15pt
  config line (count first: `EMOM · 10 × 1:00`, `TABATA · 8 × 20s / 10s`,
  `FOR TIME · CAP 20:00`, `AMRAP · 10:00`); one width-filled hero where there is a score
  (AMRAP rounds counted, For Time finished under the cap, any Stopped run: rounds reached for
  EMOM/Tabata, rounds counted or time for AMRAP, time for For Time) with a 15pt label (ROUNDS,
  TIME); a natural EMOM / Tabata / zero-round AMRAP finish shows `Finished` as a 56pt hero word
  and no number; no icon; no bar; no TOTAL TIME secondary on a natural finish; Stopped AMRAP
  with rounds shows time as a 26pt secondary. AGAIN and DONE both bordered, 62pt, 18pt text.
  AMRAP end screens: ghosted 44pt minus / plus either side of the rounds hero (minus disabled
  at 0) so a stray tap can be corrected. Landscape completion: one centred column.
- A10 Time cap = DNF: For Time completed by the clock at the cap shows `Time cap`, no hero
  number, a neutral `playComplete()` instead of the encouragement cue, no success haptic.
- A11 DONE routes to the mode's setup (remembered values loaded). Back gesture / Android back on
  the live screen: PopScope(canPop false); a pop while running shows the HOLD hint, in prep it
  does what the Stop hold does, on completion it does what DONE does.
- A12 Bugs: Tabata paused mid-WORK shows the right time (`timeRemaining` keys on
  `stateBeforePause`); `stop()` / `finish()` return early on an already completed session;
  wakelock always on while the timer page is open (Keep Screen On is gone).

## Track B: Home, setup, Settings (owner: builder agent, branch feat/1.3.0-ends)

Files: placeholder_pages.dart, setup_scaffold.dart, setup_stepper.dart, *_setup_page.dart,
settings_page.dart, voice_picker_sheet.dart, and their tests (setup_pages_test.dart,
settings_page_test.dart, a new home page test). Do NOT touch any Track A file,
app_settings_provider.dart, pubspec.yaml, fastlane/ or integration_test/.

- B1 Home: delete the "Voice-coached gym timer" tagline, the four chevrons and the four colour
  bars. Each strip is one row: the mode name at the left (28pt w900; landscape 24 to 28pt) and
  the remembered setup for that mode at the right (17pt w600 white, tabular figures), read from
  `setupMemoryProvider` on every build: AMRAP `10:00`; For Time `CAP 20:00 · UP` /
  `CAP 20:00 · DOWN`; EMOM `10 × 1:00` (rounds first, `setupClock` interval); Tabata
  `8 × 20s / 10s` (rounds first, `setupPhase` work / rest). Strip vertical padding 18 to 14pt
  portrait, 12pt landscape, so all four strips fit an 844 × 390pt landscape screen with no
  scroll (keep the SingleChildScrollView as a silent fallback). Semantics label reads the
  config instead of the deleted description. Geometry test: the fourth strip's bottom is inside
  the landscape viewport.
- B2 Setup chrome: the voice chip keeps its size, label and tap target but goes grey (text and
  icon #9A9AA2, 1.5pt AppColors.border border, no fill), so START is the only green. Delete the
  coloured dots beside WORK / REST (the label colours stay).
- B3 Tabata classic chip: render nothing while the values are 20 / 10 / 8 (keep its 48pt slot
  so nothing jumps); show `RESET TO CLASSIC` (grey 1.5pt outline, 15pt, refresh icon) in the
  same slot only once a value drifts. Tabata values display with `setupPhase()` (65s reads
  `1:05`).
- B4 For Time count direction: replace the 310 × 54pt two-way switch with one 15pt caption line
  under the stepper, `COUNTS UP · TAP TO CHANGE` (direction words white, the rest grey,
  letter-spaced), 44pt tall tap target that toggles and is remembered as today.
- B5 START guard: START ignores taps for 500ms after a setup screen appears, so a double tap on
  DONE (which now lands on setup) cannot start a new countdown. Test it.
- B6 Landscape setup: the portrait layout centred (no left/right split): header, then
  multi-stepper modes side by side in one row using a compact stepper variant (52pt buttons,
  8pt gaps, 104pt value box; Tabata three across, EMOM two across), single-stepper modes
  centred, then the total line and a full-width START at the bottom. Tabata fits 844 × 390pt
  without scrolling (geometry test).
- B7 Settings: one flat list, no section headers, rows at 17pt with white labels and #9A9AA2
  values (delete the private #777777): Orientation, Voice, Haptics (renamed from Haptic
  Feedback), Rate Wharf WOD, Send feedback, Privacy policy. Replace the Version row with a
  centred 15pt grey footer `Wharf WOD 1.3.0 (n)`. Remove the silent-switch caption from
  Settings.
- B8 Voice picker: drop all leading icons; the leading slot becomes the 48pt preview play
  button (empty 48pt box for Beeps only and Silent), the row tap selects and closes, the check
  stays trailing, so preview and select sit at opposite ends of the row. Put
  "Voice cues play through the silent switch." as a 15pt grey line at the bottom of the sheet.

## After both tracks (main session)

Merge B into A, update the tours (ux_review_tour_test, screenshot_tour_test,
timer_integration_test), capture every screen on the iPhone 16e sim and the Pixel emulator and
look at each one, re-shoot the store screenshot sets the release changed, bump to 1.3.0, ship
TestFlight + Play internal, smoke the exact AAB on the emulator, then release to production on
both stores and refresh the mentalmetal.app card.
