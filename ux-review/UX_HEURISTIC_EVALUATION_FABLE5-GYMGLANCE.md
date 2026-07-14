# UX Heuristic Evaluation — The Wharf WOD Timer

**Reviewer:** FABLE5-GYMGLANCE (independent cold review)
**Date:** 2026-07-14
**Evidence:** the 21 PNGs in `screens/` plus `REVIEW_REQUEST.md` only. No source code, no other reviews.
**Primary lens:** the 3-metre gym glance: in-workout screens (10-17, 20), phase/colour coding at distance, panic actions, landscape parity.
**Measurement basis:** iPhone 16 Pro Max captures (1320x2868 portrait, 3x). Point sizes below are measured from the pixels and are approximate. At 3 metres, a ~72pt digit on this device is roughly 12mm tall, about 13-14 arcminutes of visual angle: squint-readable for 20/20 vision, not glance-readable at 170 bpm from an angle in a dim garage.

---

## 1. Top 5 problems, ranked

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| 1 | Critical | 10, 11, 12, 14, 15, 16, 20 | Phase state (get-ready / work / rest / paused) is encoded only in a ~12pt pill label and a ~2pt progress-bar tint. The giant digits are white in every phase: white 00:57 during EMOM work (15), white 00:10 during Tabata rest (16), white 00:03 during get-ready (10), white 09:41 while paused (12). | The single question an interval athlete asks at 3m at 170 bpm is "work or rest?" (and "is it even running?"). Colour is the only channel fast enough, and this app's colour lives in elements that are invisible at distance. The core promise, "gym-visible UI," fails at the exact moment of use; the wall clock and SmartWOD win. | Tint the digits AND flood a low-luminance background wash per phase: orange = get ready, green = work, blue = rest, dimmed grey = paused (also drop digit opacity to ~40% when paused). Acceptance test: a viewer at 3m names the phase in under 1 second without reading any word, 10/10 trials, in a dim room. |
| 2 | Critical | 18 | Landscape home overflows by 175px: the TABATA row is completely unreachable, the settings gear renders on top of the EMOM row, and the list does not scroll. | Landscape is a promoted, first-class posture (dedicated layouts, an Orientation Lock setting with "Landscape only"). A user who props the phone landscape, or locks landscape, cannot start a Tabata at all. This is a broken screen one rotation away from first run. | Make the home list scrollable in landscape, or switch to a 2x2 mode grid beside the logo. Test: on 16 Pro Max landscape, all four mode rows plus the gear are visible and tappable; no overflow in debug builds. |
| 3 | High | 20 (vs 11) | The landscape timer is physically no bigger than portrait (~68pt vs ~73pt digit height) while roughly 60% of the screen is empty: the digits sit left-of-centre, two small controls occupy the entire right half, and the bottom band is dead space. | Landscape on a bench 3m away is the primary gym posture, and its one job is a bigger clock. ~11mm digits at 3m (~13 arcmin) is not glanceable. Rotating the phone currently buys the athlete nothing. | Scale the time to at least 70% of landscape width (roughly 650pt wide for MM:SS, about 3x current), pill and round info top-centre above it, controls shrunk into the bottom corners. Test: digits at least 30mm tall on device; readable in one glance from 3m at a 30-degree angle. |
| 4 | High | 11, 12, 13, 17, 21 | Stop is a single unconfirmed tap, irreversible, and lands on a celebration: "Finished!" with a green checkmark and a 100%-full green progress bar even when stopped at 0:19 of a 10:00 AMRAP (13). | One mis-tap (sweaty grab to move the phone, a dog, a pocket) destroys a 20-minute effort with no undo, and the app then misreports what happened. A timer that lies about the outcome once is never trusted mid-workout again. | Make Stop hold-to-confirm (600ms ring-fill, release cancels). Split the end state: "Finished!"/"Time!" only on natural completion; otherwise "Stopped: 0:19 of 10:00" with a partial (not full) bar, plus a 10-second "Resume" affordance after an early stop. Test: a single accidental tap can no longer end a workout. |
| 5 | High | 15, 16 | Round context ("Round 2/10", "Round 1/2") is ~14pt grey text floating mid-screen, and EMOM's giant number carries no label saying it is time-left-in-interval. | "Which minute am I in" is the entire job of an EMOM (every minute on the minute) timer; at 3m the athlete sees only a bare white countdown, no round, and must deduce what the big number means. | Promote the round to a second giant figure: "RND 2/10" at 40pt+ directly under the timer (or a split layout), segment the progress bar with one tick per round, and give the big number the same small label treatment For Time already has ("Elapsed" on 14), e.g. "LEFT". Test: round number readable at 3m. |

---

## 2. Full findings

### Home (01, 18)

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| H1 | High | 01, 02-06, 07, 08 | The voice-cue wedge is invisible before the first workout: home shows nothing about voice, setup shows nothing, and the only path is a small grey gear > Settings > Audio > Voice. | The differentiator vs every free alternative cannot be discovered by the exact skeptical first-timer it exists to convert; their first "GO!" is a surprise voice they never chose. | Add a "Voice: Major >" row to each setup summary card (there is a dead slot beside TYPE) that opens the voice sheet; optionally a one-line hint under the home hero ("Recorded coach voice built in"). Test: a first-time user finds and changes the voice without visiting Settings. |
| H2 | Low | 01 | Settings gear is a ~21pt dim-grey glyph at bottom centre with no label. | The only route to Voice, Orientation, Keep Screen On has the weakest affordance on the screen. | Raise to 28pt+, brighten to at least 3:1, or move to the standard top-right slot. |
| H3 | Low | 01 | Top ~30% of the screen is empty between the "WOD." hero and the first mode strip. | Wasted teach space on the only screen a first-run user is guaranteed to see (see H1); hierarchy is otherwise fine. | Use one line of it for the voice hint or pull the list up; no other change needed. |

### Setup (02, 03, 04, 05, 06, 19)

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| S1 | High | 02, 03, 05, 06 vs 17 | Summary "TOTAL DURATION" silently adds 10 seconds to what the user set: 10:00 shows "10m 10s" (02), 20:00 shows "20m 10s" (03), 10x1:00 shows "10m 10s" (05), 8x(20s+10s) shows "4m 10s" (06). The completion screen then uses the opposite basis: 2x(20+10) reports TOTAL TIME 01:00 (17), excluding prep. | The first arithmetic the app shows the athlete does not match what they typed, with no explanation (it is the hidden 10s get-ready), and the post-workout number uses a different rule. Unexplained numbers kill trust before the first start. | In the summary, show two lines: "10:00" + "+0:10 get-ready", or exclude prep from the total and add a separate "10s countdown" row. Make completion TOTAL TIME use the same stated basis. Test: summary total equals user input plus an explicitly labeled prep line. |
| S2 | Medium | 02, 03, 05 vs 06 | Stepper increments are unlabeled on AMRAP/For Time/EMOM (the mid-slot text is the unit, MIN/SEC), while on Tabata the same mid-slot shows the step size ("5s"). One slot, two meanings, and three screens where the tap step is unknowable. | A gloved athlete cannot predict how many taps 40 seconds takes; inconsistent labeling makes the same control behave "differently" across modes. | Label every stepper with its step in the same position ("±1 MIN", "±5 SEC"); keep unit implicit in the value. Test: no setup screen has an unlabeled increment. |
| S3 | Medium | 03, 04, 05 (vs 01) | Per-mode accent colours die after home: For Time's summary TYPE, selected segment and START are green (home promised blue, 01); EMOM's are green (home promised magenta). Magenta never appears again anywhere in the app. | Home teaches a colour code the rest of the app immediately breaks, so colour stops carrying information (see also finding A6 on phase colours). | Either carry the mode colour into TYPE value, selected segment and START per mode, or drop per-mode colours from home and let colour mean phase only. Pick one; apply everywhere. |
| S4 | Low | 06 | CLASSIC TABATA chip state is ambiguous: it looks tappable and looks selected, but nothing indicates whether it re-applies the preset or de-highlights when values are edited away from 20/10x8. | Preset-vs-state confusion is cheap to hit (change work to 30s: is the chip now wrong?). | Make it a selectable chip: highlighted only while values match 20/10x8, tap re-applies. Test: edit work to 30s, chip visibly deselects. |
| S5 | Low | 03, 04 | No visible way to run For Time without a time cap; whether the MIN stepper can reach a "no cap" state is unclear from the screens. | Plenty of For Time efforts are uncapped; a mandatory cap surprises athletes mid-Fran when the timer ends the workout. | Allow a "No cap" state below 1:00 on the picker (display "--:--", hide COUNT DOWN when capless). Flagged as unclear rather than confirmed: verify actual stepper floor. |
| S6 | Low | 19 | Landscape setup: the duration block floats high with dead space under the steppers; right column is fine. (START vs START WORKOUT label divergence is harmless.) | Slightly unfinished feel in a posture the app promotes. | Vertically centre the left column within the safe area. |

### Settings (07, 08, 09)

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| G1 | High | 07, 08 | No preview/play affordance anywhere for voices: the picker is four silent text rows (and 07's row is just "Voice: Major >"). | The user chooses between "Major", "Liam", "Holly" blind; the only way to hear the app's headline feature is to start a workout. | Add a speaker button per row in 08 that plays that pack's "3-2-1 GO!" sample on tap. Test: all four options can be auditioned from the sheet without starting a workout. |
| G2 | Medium | 07, 10-16, 20 | Nothing discloses that voice plays through the silent switch, and active screens show no sound/mute state. | Gym phones live on silent: some athletes will expect silence and get a voice; others will assume the muted phone will stay quiet and wait for cues that (they fear) never come. Either way, a mid-WOD surprise. | Caption under AUDIO in 07: "Voice cues play even when the silent switch is on." Add a small speaker glyph inside the active-screen pill reflecting Sound/Voice state. |
| G3 | Low | 08 | Holly has no descriptor while Major (CrossFit Coach) and Liam (Old British Man) do. | Inconsistent, and gives zero information for the blind choice G1 already forces. | Add her persona in the same parenthetical format. |
| G4 | Low | 07, 09 | "Orientation Lock: Auto" is self-contradicting (Auto means not locked). | Minor comprehension speed bump in an otherwise clean sheet (09 itself is fine). | Rename the row "Orientation"; keep the three options as-is. |
| G5 | Low | 07 | ABOUT contains only Version; no support/contact/privacy row. | A stuck user (or App Store reviewer) has no way to reach the developer from inside the app. | Add a "Support" row (mailto or URL). |

### Active: get-ready, AMRAP, paused (10, 11, 12)

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| A1 | Medium | 10 | Prep renders as MM:SS "00:03": four glyphs plus a colon for a one-digit countdown, and the digits stay white despite the orange GET READY pill. | The leading "00:0" is noise occupying most of the display width during the seconds when the athlete is walking away from the phone and needs the biggest, most colour-coded countdown of all. | Render a single giant orange digit ("3") during prep, matching the voice count. Test: prep digit at least 2x the height of the current MM:SS rendering. |
| A2 | Medium | 10 | No way to skip the fixed 10s get-ready. | The athlete who is already gripping the bar must stand through 10 dead seconds every single workout (prep length is a v1 constant, which makes skipping matter more). | "Tap anywhere to start now" during prep (single tap on the timer area starts the work phase immediately). |
| A3 | Medium | 12 (vs 11) | Paused is indistinguishable from running at distance: same white digits, same green ring; only the pill word and the glyph inside the button change. | A bumped phone or accidental pause silently stops the WOD; the athlete keeps working to a dead clock. This is the trust-killer scenario. | Covered by fix #1: grey wash + digits dimmed to ~40% opacity while paused, and pulse the digits at 1 Hz. Test: paused vs running distinguishable at 3m within 1 second. |
| A4 | Medium | 11, 14, 15, 16, 20 | The progress bar is a ~2pt hairline with a dot, and for countdown modes it fills left-to-right (up) while the digits count down. | Invisible at any distance, and the fill direction fights the countdown mental model; as-is it contributes nothing mid-WOD. | Raise to at least 8pt, phase-coloured (per fix #1); for AMRAP/EMOM/Tabata drain right-to-left so bar and digits agree. Segment per round for EMOM/Tabata (finding #5). |
| A5 | Low | 10, 11, 12, 14, 15, 16 | The Stop ring is nearly invisible: a dark-red outline at roughly 1.5:1 against the ink background. | The bail-out control disappears in a dim garage even up close; users hunting for it mid-panic get friction (the red square alone floats unanchored). | Fill the stop button face (solid dark red, white square) or raise ring contrast to 3:1 minimum. |
| A6 | Low | 10, 11, 12, 15, 16, 20 | Controls borrow the phase palette: the pause/resume button is a bright green ring in every phase, including rest (16), where green should mean "work"; get-ready's orange pill doubles as Tabata's identity colour; rest blue doubles as For Time's. | Once colour becomes the phase channel (fix #1), coloured controls will actively lie at distance. | Make in-workout controls neutral (white/grey rings and glyphs); reserve saturated colour exclusively for phase state. |

### Active: For Time (14)

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| F1 | High | 14 | The finish action is the dimmest, most ambiguous control on the screen: a small grey outlined flag, unlabeled, sitting immediately right of pause. | Logging your time is THE For Time action, performed while gasping at the exact moment precision is worst. A grey flag reads as disabled or as a lap marker, and a fumbling athlete can hit pause instead, losing their true time. | Replace with a large filled button labeled "FINISH" (mode colour), at least 1.5x the pause target, far right or full-width above the control row; keep Stop far left. Test: three first-time viewers correctly name all three controls without help. |
| F2 | Medium | 14 | Stop vs flag: two ways to end, zero on-screen distinction of outcome (does Stop discard my time? does flag stop the clock?). | Ambiguity between the destructive exit and the goal action, discovered only by trying one mid-WOD. | With F1's "FINISH" label plus hold-to-stop (fix #4), the semantics become self-evident; also change the end screens per fix #4 ("Time!" vs "Stopped"). |
| F3 | Low | 14 vs 11, 15, 16 | "Elapsed" label exists only in For Time; the other three modes' giant numbers are unlabeled. | Inconsistent labeling of the single most important number in the app. | Same label slot on all modes ("LEFT" for countdowns, "REST"/"WORK" during Tabata phases), at 20pt+ so it survives a metre or two. |

### Active: EMOM, Tabata (15, 16) — beyond Top-5 items #1 and #5

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| E1 | High | 15, 16 | Sub-minute phases render as "00:xx": the "00:" prefix is half the display carrying zero information (Tabata intervals are always under a minute; EMOM's default is exactly 1:00 so 59 of every 60 seconds show "00:"). | The digits could be roughly twice as tall for free; at 3m that is the difference between reading and squinting. | When the current phase is under 60s, render seconds only ("10", or ":10"), scaled to the freed width. Test: 20/10 Tabata rest readable at 3m; format flips back to M:SS at 60s+. |

### Complete (13, 17, 21)

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| C1 | Medium | 13, 17, 21 | Result hierarchy is inverted: "Finished!" (~29-34pt) outweighs the number the athlete staggered over to read (TOTAL TIME at ~22-26pt); in landscape (21) the stat also loses its card and sits bare. | After the final rep they want exactly one thing, their time/rounds, and it is the third-largest element on the screen. | Make the stat the hero: 64pt+, top of the stack; demote the headline to a small line above it. Test: the number is the largest text on all three completion screens. |
| C2 | Medium | 13 | AMRAP completion reports only TOTAL TIME, a meaningless stat for a fixed-duration format (the score is rounds+reps), and no round counter exists mid-WOD to feed a real one. | The app ends an AMRAP without the AMRAP result. Presets/history are v1 cuts, but this is the wrong stat, not a missing feature. | Immediate: label honestly per fix #4 ("Stopped at 0:19 of 10:00"). Next release (strategic): tap-anywhere-to-count-rounds during AMRAP (the mid-screen dead space is an ideal 200pt+ tap zone) feeding a ROUNDS card like 17's. |
| C3 | Medium | 21 | Landscape completion: Again/Done float mid-right with the bottom half of the screen empty; no card, no progress bar; layout reads unfinished compared to 13/17. | Last screen of every landscape workout leaves an afterthought impression, undermining the "explicit landscape layouts" claim. | Centre the stat column left, pin Again/Done bottom-right corner, reuse the portrait stat card. |
| C4 | Low | 13, 17, 21 | "Again" ghost button text is dim grey (~4:1) on ink. | The likely repeat action for interval athletes is the hardest to read post-workout. | White text at the same weight as Done's label. |

### Pack integrity

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| P1 | Low | (17 preview) | The brief lists `17_active_tabata_phase_preview.png` ("WORK in Ns" preview) but the file is absent from `screens/` (two rows numbered 17, only the completion shot exists). The phase-preview feature is therefore unverified in this review. | A claimed glanceability feature of the densest mode went unevaluated; numbering collision also risks reviewers citing the wrong screen 17. | Re-capture the preview state and renumber (17a/17b or 17/18 shift) for the next review round. |

### Cross-cutting

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| X1 | Medium | 02-07, 13, 17 | Micro-label caps ("SUMMARY", "TOTAL DURATION", "MIN"/"SEC", settings section headers) sit at roughly 3:1 on the ink background at ~12-13pt, below the 4.5:1 threshold for small text; giant fixed-scale numerals suggest Dynamic Type is unhandled (not testable from stills, flag for QA). | Dim-garage legibility is the app's stated arena; secondary text currently opts out of it, and a text-scaling break would hit exactly the 50-year-old garage-gym owner persona. | Lift all micro-labels to at least 4.5:1 (roughly #9A9AA5 on #050510); QA every screen at AX3 text size and cap scaling on the timer digits only. |
| X2 | Low | 01 vs 02-06 | Casing drifts between home strips (ALL CAPS: "FOR TIME", "TABATA") and nav titles ("For Time", "Tabata" title case, while AMRAP/EMOM stay caps). | Small craft wobble on the two screens every user sees back-to-back within 5 seconds. | Pick one convention for mode names (suggest caps everywhere, matching the pills) and apply to nav titles. |

---

## 3. Three pointed questions

**What, if anything, would make you not keep using this app?**
Failing the glance: if mid-Tabata I cannot tell work from rest (or running from paused) from 3 metres because everything is white-on-ink (findings #1, A3, E1), the app is worse than the gym wall clock it wants to replace, and Tabata being unreachable on the landscape home (finding #2) means the first time I prop the phone sideways I conclude v1 simply is not finished. Both send me back to SmartWOD within a session.

**What would make you stop trusting it mid-workout?**
The first accidental one-tap Stop that vaporises 12 minutes of effort and then shows "Finished!" with a checkmark and a 100% green bar (finding #4): a timer that misreports what happened once is done as a timer. The pre-workout arithmetic that turns my typed 10:00 into "10m 10s" with no explanation (finding S1) plants the same doubt before I even start.

**If you could ship only one change before the next release, what is it and why?**
Phase-coloured active screens (fix #1): tint the giant digits and flood a background wash per state (orange get-ready, green work, blue rest, dimmed paused) across screens 10-16 and 20. It is one change that makes every mode glanceable at distance, makes paused unmistakable, converts the design system's colours from decoration into information, and is the whole "gym-visible UI" wedge delivered; no other single change moves keep-it-installed retention as much.

---

## 4. One genuine strength

The setup flow genuinely clears the 15-second bar: sane defaults, big-target steppers, the Classic Tabata preset, and an always-visible full-width START mean a gloved, sweaty athlete configures 7 rounds of 40/20 in about 7 taps without reading anything twice.
