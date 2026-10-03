# 1.3.1 brand, Home and workout screens: the build list

Status: **decisions logged, nothing built yet.** Gareth asked to lock the
workout screens first, then build everything in one pass (3 Oct 2026).

Where things stand on the stores: iOS 1.3.0 build 16 is WAITING_FOR_REVIEW
(auto-release). 1.3.1 build 17 / Play internal vc11 (from main 40e4f53) is on
TestFlight and Play internal only. The build below supersedes build 17's Home,
wordmark and icon.

Reference images: `docs/design/1.3.1/`. Throwaway preview code for every option
shown: branch `preview/stacked-wordmark` (`lib/core/presentation/router/home_variants.dart`,
watch `HomeView.swift`). Port the chosen pieces cleanly; do not merge that branch.

## Locked

### 1. Wordmark: combo 25 with a pink full stop
- Stacked: small tracked **WHARF in white** over a heavy **WOD in neon green
  #00FF88**, with a **pink #FF0088 full stop** (the EMOM magenta). Outfit 800 /
  900, soft glow on the coloured parts, faint glow on white.
- Proportions (from the preview): WHARF = 0.278 x WOD size, tracking 0.12 x
  WOD size; WOD tracking -0.028 x size; line height 0.9.
- Phone and tablet: replaces the one-line mark at the top of Home
  (`lib/core/presentation/widgets/wordmark.dart`).
- Watch: as an image (`docs/design/1.3.1/watch_wordmark_25_pink.png`) at the
  top of the Home list, about 50pt tall, scrolling away with the list. Not in
  the toolbar title slot (too small for a stacked mark).

### 2. App icon 58
- `docs/design/1.3.1/app_icon_58.svg`: white ring, pink timer arc, neon
  green plates (#00FF88 / #00B862 collars), white bar, pink top and side
  buttons, on the app's ink #050510 with a #0E0E1E dial.
- To regenerate: iOS 1024 (no alpha, full-bleed square, iOS rounds the
  corners), Android adaptive (foreground in the safe zone, background #050510;
  update `adaptive_icon_background` in pubspec), Apple Watch marketing 1024 and
  40@2x (watch masks to a circle; every element sits inside it), App Store icon.
  Then `flutter_launcher_icons`.

### 3. Home order everywhere
**For Time, EMOM, AMRAP, Tabata** on phone, tablet and watch.

### 4. Phone Home: option 13
Reference: `home_phone_13.png`.
- Full-width cards: mode colour bar, **white** name (28), setup at the right
  (18), then the workout drawn as a block timeline (12pt tall, flex by
  seconds: EMOM one block per round, Tabata work in the mode colour and rest
  in blue #00AAFF, AMRAP and For Time one bar), then "10:00 total" right
  aligned (13, grey).
- Phone landscape must still fit 844 x 390 without scrolling (existing test):
  likely drop the total line and thin the timeline there. To confirm in build.

### 5. Tablet Home: last workout as the hero
Reference: `home_tablet_hero.png` (preview option TG).
- The last mode started gets a big tile across the top; the other three sit
  in a row below, in the For Time, EMOM, AMRAP, Tabata order.
- Each tile is option 13 as a tile: bar, white name, setup, timeline, total.
- Needs a new additive key: `setup_last_mode` written on every START (all
  four `save*` calls in `SetupMemory`). Before the first start, the hero is
  For Time (first in the order).
- Tablet = logical shortest side >= 560 under TabletScale. Tablet landscape
  (logical ~800 x 600): wordmark column left, hero tiles right. To check.

### 6. Watch Home: option A
References: `home_watch_A.png`, `home_watch_A_scrolled.png`.
- Rows keep the colour bar, **white** name and setup, plus a thin (6pt) block
  timeline under each row. No total line.
- `SetupMemory.shape(code)` for the parts; `TimelineBar` view.

### 7. Titles
Home mode names are **white** on all three devices (they were brand orange
in build 17). Setup screen headings: decided in the workout-screen review.

## Still to decide: the workout screens
Next step, per Gareth: go through each workout type's screens across phone,
tablet and watch and lock the fine-tuning before building. Current-state
sheets (setup / live / end on iPhone 17 Pro Max, iPad 13, watch 46mm) were
sent 3 Oct. Proposals put to him, awaiting picks:

1. Setup heading colour: white like Home, or keep brand orange.
2. Setup screens show the Home timeline and total above START (fills the
   empty middle on phone and iPad); the total then leaves START.
3. Live progress bar becomes the same block timeline, filling as you go
   (EMOM blocks, Tabata work and rest blocks).
4. Live screen spacing on phone and iPad: close the gap between the round or
   score and the bar, or grow the round slot into it.
5. End screens show the timeline filled to where you stopped (Stopped EMOM
   2/10 shows 2 of 10 blocks); a natural Tabata finish shows rounds and
   total time instead of an empty screen.
6. AMRAP: counted rounds as dots under the count on the live screen.
7. For Time setup: the COUNTS UP / TAP TO CHANGE line is small; make it a
   proper two-option switch.
8. Watch: same as 1 to 3 and 5 at watch scale; add an EMOM end capture.

9. Setup input (Gareth, 3 Oct): no plus and minus buttons beside the values.
   Eight working options in the Setup Lab (https://claude.ai/artifact/B714VFqbupZmi78EFLThn6):
   1 scroll wheel, 2 tape ruler, 3 drag the number, 4 usual-time chips then a
   wheel, 5 stopwatch bezel, 6 keypad, 7 two rulers (EMOM), 8 wheels side by
   side (Tabata). Suggested: 4 for AMRAP / For Time, 8 for EMOM / Tabata.
   Watch keeps the Digital Crown.
10. Bigger START (Gareth: "needs to be bigger"): A 88pt tall bar with the
   total under START (suggested), B 168pt round button, C 132pt edge-to-edge
   slab. Today's is 62pt.

**Picked 3 Oct:** stopwatch bezel for AMRAP and For Time (1 to 60 min,
1 minute per 6 degrees), wheels side by side for EMOM (every 15s steps
0:15 to 10:00, rounds 1 to 30) and Tabata (work and rest 5s steps 5s to 2:00,
rounds 1 to 20), edge-to-edge START slab (132pt, total or direction under
START). Watch keeps the Crown with the slab at the bottom.
Review page: https://claude.ai/artifact/PXFnX8SMBKEqNbz8eo4hMh. It also
proposes, pending his OK: For Time Up / Down switch under the bezel, the Home
timeline under the EMOM and Tabata wheels, white setup headings.

**Setup label colours (3 Oct):** EMOM EVERY green, ROUNDS blue. Tabata WORK
green, REST pink, ROUNDS blue. Same on the watch. iPad: space between the
Tabata timeline and START (about 30pt before scaling).

**Rest is pink everywhere (3 Oct, Gareth):** work green #00FF88, rest pink
#FF0088 on the Tabata timeline (Home, setup, live progress), the live REST
phase (digits, glow, phase word, paused states) on phone, tablet and watch.
Replaces rest blue #00AAFF (AppColors.rest, watch Palette.rest). This also
overrides section 4's "rest in blue" for the Home timeline.

**Four mode colours (3 Oct, Gareth):** For Time orange #FF6B1A (was blue),
EMOM pink #FF0088, AMRAP green #00FF88, Tabata blue #00AAFF (was amber, too
close to orange). Home bars and single-block timelines use the mode colour;
Tabata's timeline is work green / rest pink. Preview captures sent
(preview branch commit "four mode colours"). Open: EMOM blocks pink (mode
colour, current) or green (work).

**Setup timeline position:** on EMOM and Tabata setup, the timeline sits
halfway between the wheels and START (prototype updated).

**Mode colours revised (3 Oct, Gareth):** AMRAP blue #00AAFF, Tabata green
#00FF88 (bar), For Time orange, EMOM pink. Supersedes the four-colour note
above. Tabata timeline stays work green / rest pink. Captures sent.

**Decided (3 Oct):** EMOM timeline blocks stay pink. All three setup additions
kept: For Time Up / Down switch under the bezel, Home timeline under the EMOM
and Tabata wheels (halfway to START), white setup headings.

Next: live and end screens per workout, themed by mode colour. Running
prototype: https://claude.ai/artifact/Cnz7pnXLE9pmPrntaWoSTi (iPhone live and
end, watch live and end, iPad Tabata live and For Time end). Proposed,
awaiting picks: clock in the workout's colour (Tabata: work green, rest
pink); GET READY white instead of amber; AGAIN / DONE as an edge-to-edge
slab with AGAIN in the workout's colour; progress bar and end screens use the
Home timeline (done blocks filled, current filling, rest dim); EMOM end shows
rounds and time, Tabata finish shows 8/8 and 4:00 total.

**Button rule (proposed 3 Oct, after Gareth flagged inconsistency):** every
screen's main actions sit at the bottom in one place. Phone and iPad:
edge-to-edge slab (START; PAUSE, with FINISH on For Time; HOLD TO STOP and
RESUME when paused; AGAIN and DONE). Watch: the same buttons as full-width
inset capsules with a small margin, because the rounded screen clips an edge
slab (Gareth: edge buttons "look squashed on watch"). AGAIN and RESUME in the
workout's colour.

**No jumping (Gareth, 3 Oct):** when numbers change or count, nothing else
may move. Every line on the live, paused and end screens has a fixed-height
slot; the clock's font size is set once per workout from its longest value
(For Time cap, AMRAP duration, EMOM interval, Tabata work), not refitted
every tick (today's BigClock / width-fill refits per string, so 9:59 to 10:00
or 10 to 9 can change the size). Tabular figures throughout. Add a widget
test: pump a tick across a digit-count change and assert every element's
rect is unchanged.

**AMRAP end:** no plus and minus beside the count (Gareth: odd). The count is
a wheel you scroll to fix, like the setup wheels, with "Scroll to fix the
count" under ROUNDS. Watch: the Crown fixes it.

Record the picks here before building.

## Build checklist (when everything above is locked)
- Phone/tablet Home, wordmark, icon, order, last-mode key; watch Home,
  wordmark image, icon, order.
- Tests: Home order, bars, white names, timeline and total, tablet hero picks
  the last mode (and For Time by default), landscape fit on phone and tablet;
  SetupMemory last-mode golden test (additive key, unknown values ignored).
  Watch: shape() per mode, order.
- Captures: iPhone 6.9, iPad 13, watch 46mm; exact-AAB smoke on the Pixel
  Tablet emulator.
- Ship 1.3.1 (next build) to TestFlight + Play internal; production only on
  Gareth's go (cancel 1.3.0 build 16's review then).
- Store shots (iPhone, iPad, watch, Play), site card and FAQ (new wordmark,
  icon, Beeps), NOW.md, state file.
