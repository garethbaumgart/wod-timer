# Wharf WOD 2.6.0 build plan: Today's WOD, a chained session (P0 to P11)

Source of truth for the build agent. Written 20 Nov 2026 on top of origin/main
144f83b (2.5.2, Flutter 3.50.0; 2.5.2 is waiting for review on both stores).
Where this plan and the mocks disagree, this plan wins. Where this plan is
wrong about the code, do the closest thing that keeps its intent and report
the deviation.

## Why

Each timer runs alone, so a class with strength, an EMOM and an AMRAP means
setting the clock three times with chalky hands, and the app covers only the
timed part of the hour. This release chains blocks into one hands-free
session: the four timers, a Rest, and a Sets block for strength. It is option
A (playlist) of the 25 Oct 2026 whole-WOD ideation, and it keeps Gareth's
steer that Wharf WOD complements Apple's Workout app and is not a second
recorder: no history, no tracker, no library.

**Approval (20 Nov 2026):** Gareth saw the real-app mocks and said "love all of
those. go ahead and ship them!". That covers the design as mocked and a ship to
TestFlight and Play internal. The coordinator ships; you do not.

## Design reference

- Page: https://claude.ai/artifact/4323RGij4eSdaiq98das4z
- Captures (1206x2622 PNG, the approved look):
  `/Users/garethbaumgart/Source/mentalmetal-portfolio/.claude/worktrees/feature-recommendations-squish-wharf-93b4ac/previews/wharf/`
  `01-home-repeat`, `02-setup-then`, `03-builder`, `04-add-block`,
  `05-live-strip`, `06-get-ready-next`, `07-sets-work`, `08-sets-rest`,
  `09-end`.
- Prototype code: branch `preview/todays-wod` (commit e606353), flag gated,
  fixed states. Port its widgets and layout (`git show
  preview/todays-wod:<path>`), not its fakes or its flag. The real build has no
  preview flag.

## Decisions (made, do not reopen)

1. A session is a plain ordered list of 1 to 12 blocks. Block kinds: For Time,
   EMOM, AMRAP, Tabata (each with exactly the settings its setup screen has
   today), Rest (a duration), Sets (a set count and a rest duration).
2. Sets has no work clock: the screen shows which set she is on, SET DONE
   starts the rest, the rest counts down and the next set begins. After the
   last set's SET DONE the block is over; there is no rest after it.
3. Hand-over is automatic. Every block that is not a Rest starts with the
   app's standard GET READY (white, tap to skip) and that get-ready names the
   block in its colour. A Rest block counts its full duration in rest pink,
   names what is next, can be skipped with a tap, and ends without its own
   3-2-1 beeps because the get-ready that follows has them.
4. Built on the phone (and tablet). The Apple Watch and Wear OS apps are not
   touched in this release and must behave exactly as they do now.
5. Results live on the end screen only. Nothing is kept except the last
   session itself, so it can be repeated.
6. Colours: the four mode colours as today; Sets amber `#FFB800`; Rest uses
   the dim bar `#7A1F4D` with its name in the lighter `#C7528D` in lists and
   strips, and full rest pink on the clock, as mocked. The session's own hero
   and AGAIN are brand green.

## Hard rules

1. **Never remove or alter stored data.** The last session is one new
   SharedPreferences key holding versioned JSON. Golden-fixture test: seed
   every pre-existing prefs key with real-shaped values, save and load a
   session, assert every pre-existing key is unchanged. A corrupt or unknown
   session value is ignored (the Home card shows its empty state), never a
   crash, and is not overwritten until she starts a new session.
2. Work only in this worktree
   (`/Users/garethbaumgart/Source/mentalmetal-portfolio/.claude/worktrees/feature-recommendations-squish-wharf-93b4ac/wod-timer`),
   branch `feat/2.6.0-todays-wod` (already created from origin/main). Never
   edit the shared checkout at `/Users/garethbaumgart/Source/mentalmetal-portfolio/wod-timer`.
   One commit per item, message `2.6.0: P<n> <what>`. Before each commit:
   `fvm flutter analyze` with no new issues and `fvm flutter test` all green.
   Never disable or delete a test to get green.
3. **A single timer started the way it is today must be unchanged**: same
   screens, same cues, same end screen, same analytics. With no session ever
   built, the only visible differences are the Home card's empty state and the
   THEN capsule on the four setup screens.
4. The live clock inside a session is the same size as the single-timer clock
   (the mock measured identical, 14pt lower). Counting numbers sit in
   fixed-height slots sized once from the longest value so nothing jumps.
   Gaps are measured in code from visible glyphs, not eyeballed, and pinned by
   layout tests (equal gaps within 1pt; clock rect unchanged across a tick).
5. Every screen works in portrait and landscape, on a small phone (iPhone SE),
   on iPad and an Android tablet, and at large text. Home may scroll on small
   phones; nothing may overflow or clip.
6. Copy is terse capitals in the app's voice. **No em dashes (U+2014) anywhere
   new.** No new voice clips: use the existing beeps and lines only. Do not
   edit `docs/SHIP_REMINDERS.md`.
7. Do not touch `ios/WODTimerWatch`, `android/wear`, the version, tags, main,
   or any store or TestFlight lane.
8. Other agents are building other apps on this Mac right now. Use only your
   own devices: iOS simulator iPhone 16 Pro (iOS 18.4) UDID
   `8AB9BDB8-113C-48BE-82E7-553111C6F72B` (create your own extra simulators
   for iPhone SE and iPad if you need them, and delete them after), Android
   AVD `F350_WharfWOD` started headless on port 5564 (`emulator-5564`). Never
   reset, shut down or `adb kill-server` anything else. Shut your own devices
   down when finished. Scratch files go under
   `/private/tmp/claude-501/-Users-garethbaumgart-Source-mentalmetal-portfolio--claude-worktrees-feature-recommendations-squish-wharf-93b4ac/5ce6afb5-447b-4849-8e09-3b4035106a5f/scratchpad/wharf-build/`.
9. From tool shells `pod install` needs `LANG=en_US.UTF-8`. If
   `fvm flutter --version` prints `0.0.0-unknown` or hangs, stop and report.
   The prototype agent found `build_runner` hangs in this repo: if generated
   files are needed, find out why first and report it rather than hand-copying.

## P0  Flutter 3.50.1  (do first)

3.50.1 stable was released on 20 Nov 2026 and is already installed in FVM.
Follow the per-app steps of `~/.claude/skills/mentalmetal-flutter-upgrade/SKILL.md`
for this one app (`fvm use 3.50.1`, pub get, analyze, tests, an appbundle and
an iOS simulator build; the Flutter project is at the repo root). It is a
patch release; if anything beyond a lockfile changes, say so in the report. Do
not update the portfolio ledger (the coordinator does). Commit
`2.6.0: P0 Flutter 3.50.1`.

## P1  Session model and persistence  (High)

Immutable block and session value objects in the domain layer's idiom, JSON
with a version field, the estimate of total time ("about N min": timer
durations, For Time at its cap, rests, the get-readies, and Sets counted as
one minute of work per set plus its rests), and the last-session store from
hard rule 1. Each block kind remembers its own last values for the add sheet,
reusing `setup_memory.dart` where it fits.

## P2  The session engine  (High, heavily tested)

A controller that runs the blocks in order on top of the existing timer
engine, without changing how a single timer behaves.

- Timer blocks run with today's engine, cues, tap-to-count (AMRAP) and FINISH
  (For Time). When one ends, by time, cap or FINISH, the session moves on.
- Rest and Sets follow decisions 2 and 3. A Sets rest gives the usual 3-2-1
  low beeps and the high beep into the next set.
- PAUSE works in every state. HOLD TO STOP ends the whole session and goes to
  the end screen in its stopped form, showing what was completed.
- The screen stays awake for the whole session, get-readies and rests
  included. Backgrounding and resume behave as a single timer does today.
- Tests with a fake clock: a session with every block kind runs start to
  finish in the right order with the right phases; skipping a rest and a
  get-ready; pause and resume in each state; stop in each state; a one-block
  session; two timer blocks back to back; Sets with 1 set; a 12-block session.

## P3  Entry points  (High)

- **Home card** (match `01-home-repeat.png`): "TODAY'S WOD" above the four
  tiles. With a last session: its blocks named in their colours, the strip,
  "about 42 min", and "+ NEW". Tapping the card opens the builder with that
  session loaded. Empty state: one slim line inviting her to chain timers,
  with "+ NEW". The four tiles keep their colour bars and order.
- **THEN capsule** (match `02-setup-then.png`): "+ THEN" above START on all
  four setup screens. It starts a new session whose first block is the values
  on screen and opens the builder with the add sheet open.

## P4  The builder  (High)

Match `03-builder.png` and `04-add-block.png`.

- Rows with colour bar, name in colour, detail and drag handle. Drag to
  reorder. Tap a row to edit that block with the same wheels its setup screen
  uses (Rest: one duration wheel; Sets: a count wheel and a rest wheel),
  confirmed with DONE instead of START. Remove a block from its edit screen
  and by swiping the row, with an undo.
- "+ ADD BLOCK" opens the sheet of six kinds, each showing its last values.
- The strip shows the session's shape, and START carries "About N min".
  START is disabled with no blocks.
- Starting saves the session as the last session.

## P5  Live screens  (High)

Match `05-live-strip.png`, `06-get-ready-next.png`, `07-sets-work.png`,
`08-sets-rest.png`.

- The strip of segments (done dimmed, current bright, to come outlined) and
  the line "BLOCK 3 OF 5 · NEXT REST 2:00" sit above today's live layout. The
  last block's line names no next block.
- GET READY names the block ("NEXT · AMRAP 12:00") in its colour.
- Sets: "SET" over "3/5" in amber, "THEN REST 2:00", SET DONE beside PAUSE.
  Sets rest: the pink countdown, "REST · SET 4 NEXT", TAP TO SKIP.
- Rest block: the pink countdown, "NEXT · EMOM 10 × 1:00", TAP TO SKIP.
- Landscape and tablet layouts get the same strip and line without shrinking
  the clock more than the single-timer landscape layout already does.

## P6  The end screen  (High)

Match `09-end.png`, in the style of the 2.5.1 end screens: "Finished",
"TODAY'S WOD · 5 BLOCKS", the total time as the hero, then one fact tile per
scored block (SETS 5, EMOM ROUNDS 10, AMRAP ROUNDS 7, FOR TIME 6:42, TABATA
ROUNDS 8; Rest has none), three to a row and wrapping, the strip, AGAIN and
DONE. AGAIN restarts the same session. The stopped form says so and shows
only what was completed.

## P7  Telemetry  (Process)

Through the existing analytics: `session_started {blocks, kinds}` (kinds as a
sorted, comma-joined list of block kinds), `session_completed {blocks,
ended_by: finished | stopped}`, `session_builder_opened {source: home | then |
repeat}`. The existing `workout_started` and `workout_completed` still fire
for each timer block, with `in_session: true`. Single timers send exactly what
they send today.

## P8  Layout and accessibility tests  (Process)

The tests from hard rules 4 and 5: clock size equal to the single-timer clock;
equal gaps; no rect movement across a tick; no overflow on iPhone SE, iPad
portrait and landscape, a phone in landscape, and text scale 1.6; the Home
card in both states; the builder with 1 and 12 blocks.

## P9  Real-app proof  (Process)

From the finished build, with a real session actually running (drive it with
an integration test or launch arguments and a fast clock, building on
`integration_test/screenshot_tour_test.dart` and the prototype's
`tool/preview/capture_todays_wod.sh`): capture the nine screens above on the
iPhone 16 Pro simulator, the builder and a live screen in landscape, the same
set on the Android emulator, and Home, builder and live on an iPad simulator.
Save to
`/Users/garethbaumgart/Source/mentalmetal-portfolio/.claude/worktrees/feature-recommendations-squish-wharf-93b4ac/previews/wharf-real/`
as `ios-01-…png`, `ios-landscape-…`, `ipad-…`, `android-…`. Open every PNG and
fix what is wrong before you finish. Also run one whole short session on a
simulator with sound on and confirm from the app's cue log that every
transition played the cues this plan describes.

## P10  Regression  (Process)

`scripts/test_gate.sh` in its quick form passes. Run each of the four single
timers once on the simulator and confirm hard rule 3 by comparing against
captures of origin/main (pixel-identical apart from the THEN capsule on setup
and the card on Home).

## P11  Finish

- Analyze with no new issues, all tests green, `fvm flutter build appbundle
  --release` and an iOS simulator build both succeed.
- `git push -u origin feat/2.6.0-todays-wod` (the owner's standing rule: every
  work branch is pushed; this overrides your default of not pushing).
- Do not write other documents.

## Handoff report (under 400 words)

Commits by item; test count before and after; how the session engine sits on
the existing timer engine; every deviation from this plan and why; anything you
are unsure about in behaviour or look; the `build_runner` finding; where the
captures are and how to re-run them; draft release notes (two or three terse
sentences in the app's voice, no em dashes); whether the push succeeded.
