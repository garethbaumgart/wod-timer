# Wharf WOD 1.3.1: build spec

Single source of truth for the 1.3.1 build. Every decision below was made
by Gareth on 3 Oct 2026 (history in `docs/PLAN_1.3.1_brand_and_home.md`; where
the two disagree, THIS file wins). Visual references: `docs/design/1.3.1/`.
Behaviour references (open in a browser, read the source): the two working
prototypes in `docs/design/1.3.1/prototypes/`:
`setup_screens.html` (setup) and `live_and_end_screens.html` (live, paused
and end). Preview code for the Home screens: branch `preview/stacked-wordmark`
(`lib/core/presentation/router/home_variants.dart`, watch
`ios/WODTimerWatch/Presentation/HomeView.swift`). Port cleanly; do not merge
that branch.

Already done on this branch: icon 58 (iOS, Android adaptive, watch).

## Hard rules
- App updates never remove stored data. New prefs keys are additive; unknown
  or mistyped values read as defaults and are left untouched. Golden-fixture
  test for every persistence change.
- Never run build_runner (codegen is dead on Flutter 3.47.6; generated files
  are copied in). Watch: no new Swift files (no file-system synchronized
  groups; a new file needs pbxproj surgery). Put new watch code in existing
  files.
- Keep large text (1.6x at 375pt) laying out without overflow, and keep the
  existing PopScope / Android-back behaviour.
- Analyze 0 errors / warnings; every test green; never disable a test to get
  green. Update tests whose expectations the spec changes.

## Colours (one meaning each)

| Token | Hex | Used for |
|---|---|---|
| For Time | #FF6B1A | mode bar, timeline, live clock, AGAIN / RESUME |
| EMOM | #FF0088 | mode bar, timeline blocks, live clock, AGAIN / RESUME |
| AMRAP | #00AAFF | mode bar, timeline, live clock, AGAIN / RESUME |
| Tabata | #00FF88 | mode bar, AGAIN / RESUME |
| Work | #00FF88 | Tabata work blocks and work phase (clock, glow, phase word) |
| Rest | #FF0088 | Tabata rest blocks and rest phase everywhere (was blue) |
| Get ready | #FFFFFF | prep countdown, every mode (was amber) |
| Brand | #FF6B1A | unchanged constant (same as For Time) |
| START | #00FF88 | setup START slab |

Phone: `AppColors` (`amrapAccent`, `forTimeAccent`, `emomAccent`,
`tabataAccent`, `work`, `rest`, `prepare`). Watch: `Palette` and
`Palette.mode(code)`. Paused: the clock dims in its own colour (as today).

## Order
**For Time, EMOM, AMRAP, Tabata** on every Home screen.

## Wordmark (phone, tablet)
Stacked: small tracked **WHARF** white over heavy **WOD** green #00FF88 with a
pink #FF0088 full stop. Outfit 800 / 900. WHARF = 0.278 x WOD size, tracking
0.12 x WOD size; WOD tracking -0.028 x size; line height 0.9; soft glow on
colours, faint on white. WOD 64pt on phone (scaled by TabletScale on tablet).
Semantics label "Wharf WOD", header. Watch: the image
`docs/design/1.3.1/watch_wordmark_25_pink.png` as the first row of the Home
list (about 50pt tall, clear background, not tappable), no toolbar title.

## Home
Titles (mode names) **white** everywhere.

**Timeline** (shared component): the workout drawn as blocks, flex by
seconds, 3pt gaps, radius 3 to 4: For Time one bar (the cap), AMRAP one bar,
EMOM one block per round (pink), Tabata work (green) / rest (pink) pairs.
Track colour for unfilled blocks #24253A.

**Phone (portrait):** reference `home_phone_final.png`. Full-width cards:
4pt mode-colour bar, white name 28 / w900, setup right-aligned 18, timeline
12pt under, "10:00 total" right-aligned 13 grey (#9A9AA2) under that.
Landscape (844 x 390) must fit without scrolling: drop the total line and
use an 8pt timeline there.

**Tablet** (logical shortest side >= 560 under TabletScale): reference
`home_tablet_final.png`. The **last mode started** is a big tile across the
top; the other three sit in a row below in the order above. Each tile: bar,
white name, setup, timeline, total. New additive pref `setup_last_mode`
('amrap' | 'fortime' | 'emom' | 'tabata'), written by all four `SetupMemory`
save calls; null or unknown means For Time. Landscape tablet: wordmark
column left, tiles right; must fit.

**Watch:** references `home_watch_final*.png`. Rows: colour bar, white name
19 heavy, summary 14, then a 6pt timeline under the row (no total). Voice row
unchanged.

## Setup screens
Header: back, title **white** 24, voice chip. Bottom: **edge-to-edge START
slab** (phone and tablet): full width, 132pt tall to the very bottom edge
(content clear of the home indicator), #00FF88, "START" 34 / w900 / tracking
0.08em black, subtitle 16 / w700 / 70% black:
EMOM and Tabata "10:00 total", For Time "Counts up · cap 20:00" (or "Counts
down · ..."), AMRAP none. Keep the 500ms START guard. Remove plus / minus
steppers everywhere.

**AMRAP and For Time: stopwatch bezel.** A ring the user drags around; one
full turn = 60 minutes; 1 minute per 6 degrees; clamp 1..60 with no
wrap-around jump (crossing 12 o'clock from 60 does not jump to 1). Drawing
(see `setup_screens.html` `.dial`): track ring #1E1F33, progress arc white
from 12 o'clock to the value, 60 ticks (every 5th longer) coloured in the
mode colour up to the value else #2E2E44, a pink #FF0088 knob with an ink
outline at the value. Inside: label (DURATION / TIME CAP) and the value as
"m:00" heavy. Selection haptic per minute. Accessibility: an adjustable
semantics node (increase / decrease by one minute, value spoken), so it works
without dragging. For Time: a two-option switch under the bezel,
"COUNT UP" | "COUNT DOWN" (selected = white fill, black text).

**EMOM and Tabata: wheels side by side.** Snapping wheels with 3 visible rows
(selected row larger, white, on a soft #16172A highlight; neighbours dim),
like the prototype. Steps / ranges: EMOM EVERY 15s steps 0:15..10:00, ROUNDS
1..30; Tabata WORK and REST 5s steps 5s..2:00, ROUNDS 1..20 (same as
`SetupRanges`). Label colours: EMOM **EVERY green, ROUNDS blue**; Tabata
**WORK green, REST pink, ROUNDS blue**. Selection haptic per step. Each wheel
has an adjustable semantics node. Under the wheels: the Home timeline,
redrawn live, placed by the **centring rule** below.

Values save to SetupMemory exactly as today (on START).

## Live screens (phone, tablet)
- **Clock** in the workout's colour (Tabata: work green, rest pink; prep
  white). **Font size set once per workout** from its longest possible value
  (For Time: the cap as m:ss; AMRAP: the duration; EMOM: the interval in its
  display form; Tabata: the longer of work / rest), in a fixed-height slot.
  It never refits per tick. Tabular figures.
- **Phase line** (fixed slot, only Tabata and prep, as today): GET READY
  white, WORK green, REST / LAST REST pink, NEXT · WORK green / NEXT · REST
  pink in the last five seconds, PAUSED · ... grey when paused.
- **Second slot** (fixed height): For Time count-up "CAP 20:00"; EMOM and
  Tabata the round "2/10"; AMRAP "TAP TO COUNT" until first count, then
  "3 ROUNDS". Same baseline whichever content shows.
- **Progress = the Home timeline**: finished parts filled in their colour,
  the current part filling, upcoming parts on the #24253A track. Placed by
  the centring rule.
- **Bottom slab** (edge-to-edge, ~132pt, same geometry as START):
  - running: PAUSE (#16172A, white text); For Time: FINISH (white fill,
    black) | PAUSE.
  - paused: HOLD TO STOP (#1A0E14, red #FF4444 text, fills red while held,
    0.8s) | RESUME (workout colour, black text).
  - get ready: HOLD TO STOP alone (not pausable, as today).
- Canvas taps unchanged: prep tap skips, AMRAP tap counts (700ms cooldown),
  paused tap resumes. Taps on the slab never count.
- Landscape: keep the wall-clock layout; the slab sits along the bottom;
  must fit 844 x 390 and tablet landscape.

## End screens (phone, tablet)
Status word (Finished / Stopped / Time cap) white 30, config line grey
(e.g. "TABATA · 8 × 20s / 10s"), hero in the workout's colour, label and
detail line, the timeline filled to where the workout ended (centring rule),
then the slab: **AGAIN** (workout colour, black text) | **DONE** (#16172A,
white). DONE goes to setup, AGAIN restarts, as today.
- For Time finished: hero the time, label TIME. Time cap: as today (word,
  no score) with the timeline full.
- EMOM: hero "2/10" (stopped) or "10/10" (finished), label ROUNDS, detail
  "2:05 total" (elapsed).
- AMRAP: hero is a **rounds wheel** (scroll to fix the count; selected
  number in AMRAP blue, neighbours dim; 0..999), label ROUNDS, hint "Scroll
  to fix the count". No plus / minus.
- Tabata: hero "8/8" (or r/8 when stopped), label ROUNDS, detail "4:00
  total".

## Watch
Same colours, order, titles and rules at watch scale; the Digital Crown stays
the input on setup and for fixing the AMRAP count.
- **Buttons: full-width inset capsules**, never edge slabs (the round screen
  clips them): ~9pt side margin, ~10pt bottom margin, 44 to 48pt tall,
  radius = half height, 6pt gap between two. START: green with the same
  subtitle as the phone. Live: PAUSE; For Time FINISH | PAUSE. Paused: HOLD
  TO STOP | RESUME (workout colour). Prep: HOLD TO STOP. End: AGAIN (workout
  colour) | DONE.
- Setup: titles **white** (change the watch AccentColor or set title colour
  explicitly), label colours as the phone, Crown unchanged.
- Live: mode-colour clock, white prep, fixed slots, the timeline progress
  bar filling as on the phone, placed by the centring rule.
- End: word, config, hero in the workout colour, one label line (Tabata and
  EMOM put the total on it: "ROUNDS · 4:00"), the filled timeline, capsules.
  Every end screen fits without scrolling on 40mm, 42mm, 44mm and 46mm.
  AMRAP count fixed with the Crown (focused by default on the end screen).
- Keep the simulator `--capture` hook and add scenes for every new state
  (setup per mode, live per mode, paused, prep, end per mode incl. EMOM).

## Layout rules (all devices)
1. **No jumping.** When a number changes or counts, nothing else moves.
   Every line on setup, live, paused and end screens has a fixed-height
   slot. Test: pump across a digit-count change (9:59 -> 10:00 count-up,
   10 -> 9 countdown, TAP TO COUNT -> 1 ROUNDS) and assert every widget's
   rect is unchanged.
2. **Centring rule.** Every timeline sits exactly midway between the visible
   bottom of the content above it (glyph bottoms: the wheels' lower visible
   row, the round number, the last label; not box edges) and the top of the
   bottom buttons. Build it as a layout rule (e.g. a widget that measures the
   above content's painted text bounds via TextPainter metrics), not per-
   screen padding. Test per screen and device class: the two gaps are equal
   within 1pt (phone 390 x 844, phone landscape, tablet 1024 x 1366 under
   TabletScale). Gareth checks this closely.
3. **Bottom actions in one place.** Every screen's main actions are in the
   bottom slab (phone / tablet) or bottom capsules (watch). Nothing else
   floats as a primary button.

## Store screenshot tours (needed for release)
Update `integration_test/ux_review_tour_test.dart` (MARK_ captures) for the
new controls so it drives every screen: Home, each setup, each live state
(incl. prep, Tabata work / rest / next, paused), each end (incl. AMRAP wheel),
Settings and voice picker, landscape. Setting values may go through
SetupMemory prefs before launch rather than dragging the bezel.

## Release notes (draft, owner: integrator)
Written by the integrator at ship time.
