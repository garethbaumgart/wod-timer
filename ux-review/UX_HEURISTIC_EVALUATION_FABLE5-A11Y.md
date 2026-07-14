# UX Heuristic Evaluation — The Wharf WOD Timer
**Reviewer:** FABLE5-A11Y (cold, independent review; evidence = the 21 PNGs in `screens/` + `REVIEW_REQUEST.md` only)
**Primary lens:** accessibility and physical ergonomics (contrast, touch targets, distance legibility, sweaty/gloved hands, ageing eyes)

**Method note on contrast figures:** colours below were sampled from the actual PNG pixels (brightest anti-aliased pixel of each text/control vs its local background) and converted to WCAG contrast ratios. Anti-aliasing means the true ratio can only be *at or below* the figure quoted. Background measures `#050510`. Point sizes are estimated from pixel heights at iPhone 16 Pro Max scale (3x, 440pt width); physical sizes assume the 6.9" panel (~0.175 mm/pt).

**Capture-set note:** the brief's table lists `17_active_tabata_phase_preview.png`, but `screens/` contains only `17_active_tabata_complete.png`. The "WORK in Ns" phase preview could not be evaluated. If it renders in the same style as "Round 2/10" (#555, ~15pt), it will be invisible exactly when it matters — verify before ship.

---

## 1. Top 5 problems, ranked

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| 1 | Critical | 10–16, 20, 13 | **One unguarded tap on Stop irreversibly ends the workout — and For Time hides the one correct "finish" action.** Stop is a single tap with no confirmation and no undo; it jumps straight to "Finished!" (13). On For Time (14) the athlete at collapse must choose between three unlabeled circles: Stop (red square, its ring measures 1.0:1 — invisible), Pause, and a grey flag (ring also 1.0:1) that is the *only* way to log their time. Sweaty finger, 170 bpm, reading glasses off: a mis-tap destroys the WOD or logs nothing. | The moment of highest fatigue meets the app's most destructive and most ambiguous controls. Losing a 20-minute For Time result once is enough to send the user back to the wall clock. | Make Stop **hold-to-stop** (≈0.8 s with a filling ring; a quick tap shows "Hold to end"). On For Time, replace the flag with a **full-width green button labelled "FINISH"** above the Stop/Pause pair (min 60pt tall); keep Stop as the small tertiary control. Test: gloved single mis-tap anywhere can no longer end a workout. |
| 2 | Critical | 11, 12, 15, 16, 20 (+10) | **Workout state is illegible beyond arm's length.** The only phase signal (WORK vs REST vs PAUSED) is a ~14pt word in a small pill (≈2.4 mm tall — subtends ~2.8 arcmin at 3 m, below legibility). The giant digits stay identical white in every phase, and the round counter — the EMOM/Tabata score-keeping datum — is ~15pt grey `#555` at **2.7:1** (15). Paused (12) looks identical to running from distance. | The app's stated bar is "readable from across the gym." Today only the digits pass; *which* number and *what phase* do not. An athlete glancing mid-rep cannot tell work from rest from paused, or round 2 from round 7. | Colour the state, not a pill: tint the digits (or a full-bleed background wash) per phase — green work / blue rest / orange get-ready / dimmed grey paused — and render the round counter **≥40pt white** directly under the timer ("ROUND 3/10"). Test: phase and round identifiable in a photo taken from 3 m in a dim room. |
| 3 | Critical | 18 (+09) | **Landscape home clips TABATA and Settings off-screen** ("BOTTOM OVERFLOWED BY 175 PIXELS"; the gear floats mid-list over EMOM). The brief confirms the clipped content is really cut off in release. A user who sets Orientation Lock = "Landscape only" (09) can never start a Tabata or re-open Settings from home. | A quarter of the product's modes is unreachable in a supported orientation, and the setting that causes the trap is offered in-app. This is a functional loss, not polish. | Give landscape home its own layout: 2×2 grid of the four mode rows with the gear in a corner, or wrap the list in a scroll view as a floor. Test: rotate home on a 16 Pro Max — all four modes + gear visible and tappable with no debug overflow. |
| 4 | High | 01–07, 13–15, 21 | **Systemic sub-AA contrast on every functional grey.** Measured: home subtitles & settings values `#666` = **3.5:1** (AA needs 4.5); "WORKOUT DURATION"/MIN/SEC/"Elapsed"/"Round 2/10"/section headers `#555` = **2.7:1**; chevrons & settings gear `#333` = **1.6:1**; stepper borders `#1a1a1a` = **1.17:1**; progress-bar track = **1.05:1**. The steppers — the app's primary input — read as *disabled*; the progress bar reads as a floating sliver with no track to judge it against. | A 50-year-old in a dim garage (or anyone in glare) loses: what the pickers do, where Settings lives, how far through the WOD they are, and the "Again" action (3.5:1). This quietly fails the exact target user. | Raise functional greys to ≥`#9A9AA2` (~7:1) for text and ≥`#6A6A72` (3:1) for borders/track/icons; keep decorative-only labels dim if desired. Test: no interactive element or informational text below 4.5:1 (text) / 3:1 (non-text) with a contrast probe. |
| 5 | High | 02–06 vs 13, 17 | **The summary lies about duration, in both directions.** Setup silently adds the 10 s prep: configure 10:00 AMRAP → "10m 10s TOTAL DURATION" (02); 20:00 cap → "20m 10s" (03/04); Tabata 8×(20+10) → "4m 10s" (06). The completion screen then *excludes* prep: 2 Tabata rounds = "01:00 TOTAL TIME" (17). And after stopping at 19 s of a 10:00 AMRAP, 13 shows "Finished!" over a **100% full green progress bar**. | First-run trust: the very first number the app reflects back doesn't match what the athlete typed ("did I fat-finger 10 s?"). Then the end screen mislabels a quit as a finish with a full bar. A timer's only product is honest numbers. | Show configured work time only ("10m" for 10:00) with a separate muted "+10s get ready" line; use one format everywhere; on early stop, title "Stopped — 0:19 of 10:00", bar at actual %, and keep "Finished!" for real completions. Test: setup summary, live screen and completion agree for the same WOD. |

---

## 2. Full findings

### Screen 01 — Home (portrait)

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| 1.1 | High | 01 | Settings gear is a ~19pt icon at **1.6:1** (`#333`), alone at the bottom; row chevrons also 1.6:1. | Settings holds the entire wedge (voice packs) and orientation lock; most users will never find it. Fails 3:1 non-text contrast. | Gear ≥28pt at ≥`#8A8A93`, top-right where iOS users look; chevrons ≥3:1. Test: 5 first-timers asked "change the voice" all find it <10 s. |
| 1.2 | High | 01, 07, 08 | The voice-cue wedge is invisible on first run: nothing on home hints that recorded coaches exist; it lives 2 levels deep behind the 1.6:1 gear. | The differentiator vs the wall clock/SmartWOD is undiscoverable before the first workout; the free-app "keep it installed" case never gets made. | Add a one-line voice row on home ("Voice: Major 〉" with a speaker glyph) or fire a voice cue + toast on first START. Test: new user can name the feature after 30 s on home. |
| 1.3 | Medium | 01 | Mode rows have no container/pressed affordance — thin colour tick, headline, faint chevron; tap target boundaries are invisible (is the whole row live?). | Gloved/sweaty taps need obvious, forgiving targets; hesitation on the very first screen erodes the 15-second-setup bar. | Full-width card surfaces (~72pt tall) with visible bounds and pressed state. Test: whole-row tap works and visibly responds. |
| 1.4 | Low | 01 | Top ~55% of the screen is the logo and dead space; the four rows sit low. | Fine one-handed, but the first impression is emptier than the free alternatives it must beat; subtitles at 3.5:1 (see 4 above) carry all meaning. | Pull rows up, use freed space for the voice row (1.2). |

### Screens 02–06 — Setup

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| 2.1 | High | 02–06 | Steppers look disabled: border **1.17:1**, glyph **3.5:1**, and the value they edit sits far above them. | The app's only input mechanism reads as inert grey ghosts — first-timers poke the big digits instead (which do nothing visible). | Border ≥3:1, glyph ≥4.5:1, pressed flash + haptic; consider tap-on-digits opening the same steppers inline. Test: eye-tracking-free hallway test — user changes 10:00→12:30 in <8 s unprompted. |
| 2.2 | Medium | 02, 03, 05 | Stepper-only entry with unlabeled step size: 10:00→17:00 is 7 taps; EMOM SEC step is unknown (Tabata shows "5s", MIN/SEC show nothing — inconsistent). | The 15-second-setup bar with gloves is missed for any non-default WOD; uncertainty about step size forces trial taps. | Label steps ("±1m", "±5s") and add press-and-hold auto-repeat (state it with a first-use hint). Test: 7×(40s/20s) Tabata and a 17:00 AMRAP each configurable ≤15 s. |
| 2.3 | Medium | 03, 04 | COUNT UP / COUNT DOWN chips are ~30pt tall (under the 44pt floor), and nothing says what they change (display direction vs workout behaviour). | Glove-hostile target; a first-timer can't predict the effect, and the answer only reveals itself mid-workout. | ≥44pt chips; caption "Timer display: counts up to cap / down from cap". Test: chip hit-rate with winter gloves ≥95%. |
| 2.4 | Medium | 06 | CLASSIC TABATA chip is ambiguous: button or state? No selected indicator, and unclear whether editing Work to 30s silently exits "classic". | Preset chips that don't reflect state teach users to distrust the summary. | Make it a toggle-style chip with selected state that clears when values diverge. Test: edit work→30s, chip visibly deselects. |
| 2.5 | Low | 02–04 | Summary card is mostly redundant (TYPE repeats the title; duration repeats the picker) and its label greys measure 1.55–2.7:1. | Burns the space that could show the one non-obvious number (total incl. prep — see Top-5 #5) legibly. | Collapse to a single honest line: "10m work + 10s get ready". |
| 2.6 | Low | 05 | Summary formats collide: picker "01:00", summary "1m", completion "01:00" (17). | Small trust papercuts accumulate. | One duration format app-wide ("1:00" style). |

### Screens 07–09 — Settings & pickers

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| 3.1 | High | 08 | No preview/play button per voice — auditioning Major vs Liam vs Holly requires backing out and running a workout. | The wedge feature can't be tried at its own surface; Random ("mix it up each cue") is a blind bet. | Speaker icon per row playing a 1-s "3-2-1 GO!" sample on tap. Test: hear all three voices in <15 s without starting a workout. |
| 3.2 | Medium | 07, 08 | No way to turn voice **off**: the picker has no "Off" row, and it's undefined whether "Sound Effects" covers voice. | Early-morning garage next to a sleeping house is a core context; users will mute the phone and then miss the suspension-proof cues entirely. | Add "Off" to the voice sheet (or a Voice toggle) and rename "Sound Effects" → "Beeps". Test: beeps-only and voice-only configurations both achievable. |
| 3.3 | Low | 08 | Row inconsistencies: Major and Liam get descriptors, Holly gets none; Holly's icon is a face while the others are person-with-waves. | The undescribed option reads unfinished; icons imply a taxonomy that doesn't exist. | Give Holly a descriptor and matching icon. |
| 3.4 | Low | 07 | Value text (`Auto >`, `Major >`, version) at **3.5:1**, section headers 2.7:1; row labels scrape by at 4.53:1. | Current-state answers ("which voice am I on?") are the dimmest text on the screen. | Values ≥4.5:1 (fold into Top-5 #4). |
| 3.5 | Medium | 09 + 18 | "Landscape only" is offered while landscape home is broken (Top-5 #3) — the setting is a trap door. | A user can configure themselves out of reaching Tabata/Settings. | Fix 18 first; until then hide/disable "Landscape only". |

### Screens 10–16 — Active workout (portrait)

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| 4.1 | High | 11, 13 | AMRAP has **no round counter** — no live tally, no tap-to-count, and completion (13) shows only TOTAL TIME (which for a completed AMRAP is just the number you configured). | An AMRAP's score *is* rounds+reps. The athlete staggers over wanting one thing and the app can't give it; the wall clock ties on features. | Big tap-anywhere round counter during AMRAP ("ROUNDS 7", increments on tap, giant) and show it on completion. Test: complete an AMRAP, read your round count from 3 m. |
| 4.2 | Medium | 10, 11, 14 | Stop's visible affordance is a ~16pt red square (5.9:1) inside an invisible ring (1.0:1); the flag's ring likewise 1.0:1. Perceived targets are a fraction of actual ones. | Sweaty aim goes to visible pixels; tiny perceived targets cause hesitation or misses next to Pause (panic-action latency). | Visible button fills/rings ≥3:1 (ties to Top-5 #1 relabelling). |
| 4.3 | Medium | 11, 14, 15, 16, 20 | Progress track measures **1.05:1** — only the filled sliver shows, floating on black with no endpoint. | "How far through am I" is unanswerable at a glance; early in a WOD the bar is indistinguishable from nothing. | Track ≥`#3A3A44`, bar ≥6pt tall; for EMOM/Tabata add interval tick marks. Test: fraction-complete estimable from 3 m in a photo. |
| 4.4 | Medium | 11 | AMRAP's giant number counts **down** with no direction label (For Time got "Elapsed"; AMRAP got nothing). | First glance mid-workout ("09:46 — elapsed or remaining?") costs seconds of doubt at 170 bpm. | 20pt "REMAINING" caption ≥4.5:1 under the digits (pairs with the ≥40pt round counter from Top-5 #2). |
| 4.5 | Medium | 12 | Paused state: digits stay full-brightness white; only the 14pt pill word and the swapped icon change. | From 3 m a paused clock looks like a running clock — the athlete keeps working to a stopped timer (the exact desync the app promises to prevent). | Dim digits to 40% + slow-blink while paused; phase tint per Top-5 #2. Test: running vs paused distinguishable at 3 m in 1 s. |
| 4.6 | Low | 16 | Rest countdown renders "00:10" — the dead "00:" halves the usable digit size for a 10-second phase. | Tabata rests are always sub-minute; the most time-critical read gets the smallest digits. | Drop the minutes field when phase <60 s ("10"), roughly doubling glyph height. |
| 4.7 | Low | 14 | No time-cap reference on the For Time screen (cap was 20:00; screen shows only elapsed + a context-free bar). | "Am I near the cap?" is a real mid-WOD question; the invisible track (4.3) can't answer it. | Small "CAP 20:00" ≥4.5:1 under Elapsed. |
| 4.8 | Low | 10–16 | All active controls are icon-only (no text labels anywhere in-workout). | With reading glasses off, dim garage, unfamiliar app: square-vs-pause-vs-flag is iconography roulette (compounds Top-5 #1). | 11pt labels under each control ("END", "PAUSE", "FINISH"). |

### Screens 13, 17 — Completion (portrait)

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| 5.1 | Medium | 13, 17, 21 | "Again" text `#666` at **3.5:1** (~14pt) on a 1.2:1-border ghost button. | The repeat-the-WOD action — the retention loop — is the least visible element on the screen. | Text ≥4.5:1, border ≥3:1. |
| 5.2 | Low | 13, 17 | Completion stat "00:19"/"01:00" vs setup "10m 10s" format mismatch; 13's card shows a metric (total time) that is meaningless for AMRAP while 17 gets a proper ROUNDS card. | Inconsistent stat vocabulary across the two completion variants of the same app. | Per-mode stat cards: AMRAP→rounds (see 4.1), For Time→time vs cap, EMOM/Tabata→rounds + time; one format. |
| 5.3 | Low | 13, 17 | No record of what the workout *was* (config) on completion. | "Wait, was that the 12-minute or the 10-minute version?" — matters when re-running ("Again") or reporting a score. | One muted line: "AMRAP · 10:00". |

### Screens 18–21 — Landscape

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| 6.1 | Medium | 18 | Beyond the clipped Tabata (Top-5 #3): layout is stretched portrait — labels hug the left, chevrons sit ~2000px away at the far right edge, gear overlaps the list. | Landscape reads as an afterthought on the very first screen, undermining the "explicit landscape layouts" claim. | Purpose-built grid (see Top-5 #3 fix). |
| 6.2 | Medium | 21 | Landscape completion drops the portrait's stat card and green bar: bare "00:12 / TOTAL TIME" text floats in a mostly empty screen; Again at 3.5:1. | The propped-phone user finishes in landscape and gets the weakest version of the payoff screen. | Reuse the portrait stat-card component; balance columns. Test: portrait/landscape completions show identical information hierarchy. |
| 6.3 | Low | 19, 20 | Craft drift: button label "START" vs portrait's "START WORKOUT"; on 20 the progress bar spans only ~55% width, aligned to nothing, with dead space bottom-right. | Small inconsistencies across orientations read as two different apps. | Share one label; span the bar full-width under both columns. |
| 6.4 | Low | 20 | Timer block sits left-of-centre with controls stacked right; digits are ~72–80pt — good — but the pill and bar remain arm's-length elements (see Top-5 #2). | The dedicated "propped phone" view still relies on the 14pt pill for phase. | Phase tint (Top-5 #2) makes this view genuinely 3-metre-first. |

### Cross-cutting

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|
| 7.1 | High | all setup + 18 | **Large-text robustness is unproven and the evidence is bad:** layouts are fixed, non-scrolling columns, and screen 18 already overflows at *default* text size. At AX text sizes the Tabata setup (06, densest) will clip START or collide pickers. | Accessibility-needs users (and everyone over ~45 bumping system text) hit broken screens; the app's whole demographic skews this way. | Wrap setup screens in scroll views, pin START as a floating footer, test at AX5 and lock a CI screenshot test. |
| 7.2 | Medium | 01 vs 10–16 | Colour semantics are incoherent: home says blue=For Time, magenta=EMOM, orange=Tabata; in-workout, everything is green except blue=REST and orange=GET READY; magenta never appears again; blue means two unrelated things. | Colour is the app's main glance-code, and it can't be learned if the mapping changes between screens; also several states differ by hue alone at distance. | Pick one system: mode colour for setup accents only; phase colours (work/rest/prep/paused) own the active screens exclusively — and always pair colour with a large word or digit treatment. |
| 7.3 | Low | 02–06, 13, 17 | Duration format zoo: "10:00", "10m 10s", "1m", "20s", "00:19" across adjacent screens. | Each re-parse is friction; consistency is free trust. | One clock format ("10:00", "0:19") everywhere except step labels. |

---

## 3. Three pointed questions

**What, if anything, would make you not keep using this app?**
The first time it costs me a score: I finish a 20-minute For Time, tap the red square instead of the invisible grey flag (14), and my time is gone — or I finish an AMRAP and discover the app never counted my rounds (11→13), so I was counting in my head anyway. At that point the gym wall clock does everything this app did for me, and it's already on the wall. The greys compound it: in my dim garage the steppers, gear and "Again" button are all sub-3.5:1 (01–06, 13) — the app feels like it's in a disabled state I can't wake up.

**What would make you stop trusting it mid-workout?**
Numbers that don't match what I set: I type 10:00 and the summary says "10m 10s" (02); I quit at 0:19 and it declares "Finished!" over a 100%-full green bar (13); completion then defines "total time" differently from setup (17 vs 06). If the app rounds the truth on screens I can check, I won't believe the EMOM round boundaries I *can't* check — which is the entire suspension-proof promise.

**If you could ship only one change before the next release, what is it and why?**
Make in-workout state readable at 3 metres: tint the giant digits (or full-screen background) by phase — green work, blue rest, orange get-ready, dimmed paused — and put a ≥40pt white "ROUND X/Y" under the timer (11, 12, 15, 16, 20). It's one rendering change, it fixes the core "readable from across the gym" promise for all four modes at once, and every glance of every workout benefits — the highest-frequency moment in the product. (If a second change squeezes in: hold-to-stop + labelled FINISH on For Time, because that's the one that loses user data.)

## 4. One genuine strength

The in-workout core hierarchy is exactly right and must survive iteration: one enormous w900 white readout on true black with a single bright-green primary control (11, 20) — nothing competes with the number, which is precisely what a propped-phone gym timer should be.
