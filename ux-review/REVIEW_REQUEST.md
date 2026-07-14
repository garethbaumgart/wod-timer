# The Wharf WOD Timer — UX review request

**This file is the complete review prompt.** If you are an AI agent opened in the
`ux-review/` folder, read this file and perform the review — no other instructions
are required.

## How to run this review

### In Cursor / Claude Code / any AI opened in this folder (recommended)

Tell the agent:

> The prompt is in `REVIEW_REQUEST.md`. Do the review.

The agent should:

1. **Read this file** (`REVIEW_REQUEST.md`) — it contains the full brief, context,
   screen list, evaluation lenses, and output format.
2. **Start at `index.html`** — a visual index of all 21 screens with filenames and
   short captions. Open it in a browser or read it to see how screens map to files.
3. **Review every screenshot in `screens/`** — 21 PNGs, numbered `01` through
   `21` (see the table below for filenames and what each shows).
4. **Save the evaluation** as `UX_HEURISTIC_EVALUATION_<MODEL>.md` in this folder
   (naming note at the end).

Do **not** read or use any other UX review in this folder or elsewhere. Each
evaluation must be **independent and cold**.

### In a fresh external chat (manual)

Open a new chat in each model. Attach all 21 PNGs from `screens/` (`01_…png`
through `21_…png`). Paste everything below the `---` divider in this file. One
paste, one model. Save its reply as `UX_HEURISTIC_EVALUATION_<MODEL>.md`.

### Folder layout

| Path | Purpose |
|------|---------|
| `REVIEW_REQUEST.md` | **This file** — the full review prompt |
| `index.html` | **Starting point** — visual gallery linking to all screens |
| `screens/` | **21 PNG screenshots** to evaluate (`01_…png` … `21_…png`) |
| `UX_HEURISTIC_EVALUATION_*.md` | Where completed reviews are saved |

---

## Your task

You are a **senior product designer** doing a heuristic UX evaluation of a mobile
app, paired with the instincts of a **skeptical first-time user** who has plenty of
free alternatives to choose from (the gym's wall clock, SmartWOD-style interval
timer apps, a YouTube Tabata video, the stopwatch on their watch). Read the context
below, then review **all 21 screenshots** in `screens/` (use `index.html` as your
map).

Use **only** the context in this file and the screens in `screens/`. Do **not** use
outside knowledge, assumptions about implementation, generic app-store knowledge,
or any other UX review (yours or another model's). This is an **independent, cold**
evaluation — do not reference, agree with, or react to any other review. If
something is unclear, say it's unclear rather than guessing.

Be critical, specific, and concrete. Do **not** praise the app generally or hedge.
Assume it is **not yet good enough to ship** and your job is to find what's wrong
and what would move the needle. Reference screens by number.

**Judge everything through the target user's eyes, not a generic user's or a
designer's.** The user is a CrossFit / functional-fitness athlete — anywhere from a
23-year-old box regular to a 50-year-old garage-gym owner. The moment of use: they
walk up to the bar with 30 seconds to spare, thumb in the workout (sweaty hands,
maybe still wearing grips), prop the phone on a bench or plyo box **2–3 metres
away**, and then never want to touch it again until the workout ends. Mid-workout
they only *glance* at it between reps — often with heart rate at 170+, from an
angle, sometimes in a dim garage. Occasionally they must pause fast (dropped
barbell, dog walks in, phone rings). After the final rep they stagger over and want
exactly one thing: their time/rounds. A pattern that's slick in an armchair but
wrong at 170 bpm from 3 metres is a **finding, not a win**. For every issue and
fix, ask "does this work for *them*, in *that* moment?" and weight severities
accordingly.

## Context: what you're reviewing

**The Wharf WOD Timer** ("Wharf WOD") — a no-fuss workout timer for functional
fitness: AMRAP, For Time, EMOM and Tabata, with recorded voice cues loud enough to
hear across a garage gym. iPhone app (iPhone-only v1; a watchOS companion exists
but is not part of this review). New app, first release currently in App Store
review.

**Who it's for:** CrossFit-style athletes and garage-gym owners who want a timer
that just works with zero account, zero setup, zero upsell. The bar: set up any
standard WOD format in under 15 seconds, readable from across the gym.

**The wedge (what makes it different):**
1. **Voice cues with personality** — 3 recorded human voice packs (Major: CrossFit
   coach; Liam: old British man; Holly) plus a Random mode; countdowns, "GO!",
   halfway, last round, final 5-4-3-2-1, encouragement. Plays through the iPhone
   silent switch. (Screenshots can't convey audio — evaluate how *visible,
   discoverable and self-explanatory* the voice feature is in the UI.)
2. **Suspension-proof timing** — backgrounding the app mid-workout can never
   desync EMOM/Tabata rounds.
3. **Gym-visible UI** — giant timer text, explicit landscape layouts, screen
   kept awake during workouts.

**Business model:** completely **free**. No paywall, no ads, no account, no IAP in
v1. (So there is no conversion lens — replace it with: would this user *keep* it
installed and reach for it next session?)

**Look & feel:** the "Signal" design system — deep-ink dark background (#050510),
neon green accent (#00FF88), per-mode accent colours (AMRAP green, For Time blue,
EMOM magenta, Tabata orange), Outfit typeface throughout (w900 for the giant
timer). **Dark-only and English-only by design in v1** — critique the execution,
not the existence of a light theme or locales.

## The screens

Files live in `screens/`. `index.html` shows them in order with thumbnails.
All shots are iPhone 16 Pro Max. Screens 18–21 are landscape (the app supports
rotation; an Orientation Lock setting exists).

| # | File | Screen | What it is / what to evaluate |
|---|------|--------|-------------------------------|
| 01 | `01_home.png` | Home | First-run screen: "WOD." hero, 4 timer-type strips, settings gear. 5-second test: is it obvious what this app is and where to start? |
| 02 | `02_amrap_setup.png` | AMRAP setup | Duration picker (default 10:00) + summary card + START. The 15-second-setup bar. |
| 03 | `03_fortime_setup.png` | For Time setup | Time cap picker + COUNT UP / COUNT DOWN segmented control (COUNT UP selected). |
| 04 | `04_fortime_setup_countdown.png` | For Time setup (variant) | Same screen with COUNT DOWN selected — segmented-control state clarity. |
| 05 | `05_emom_setup.png` | EMOM setup | Interval duration + number of rounds + summary. |
| 06 | `06_tabata_setup.png` | Tabata setup | CLASSIC TABATA preset chip, Work/Rest compact pickers, rounds, summary. Densest setup screen. |
| 07 | `07_settings.png` | Settings | Display (Orientation Lock, Keep Screen On), Audio (Sound Effects, Voice, Haptic Feedback), About. All defaults. |
| 08 | `08_settings_voice_picker.png` | Voice picker sheet | Bottom sheet: Major / Liam / Holly / Random. The wedge feature's main surface. |
| 09 | `09_settings_orientation_picker.png` | Orientation picker sheet | Bottom sheet: Auto / Portrait only / Landscape only. |
| 10 | `10_active_prep_countdown.png` | Get-ready countdown | 10-second prep phase (orange GET READY pill), caught at 00:03 with the pulse-enlarged digits. |
| 11 | `11_active_amrap_work.png` | AMRAP running | The core in-workout screen: pill badge, giant countdown, progress bar, Stop/Pause controls. Judge 3-metre glanceability. |
| 12 | `12_active_amrap_paused.png` | Paused | Grey PAUSED state, play button to resume. How obvious is the fastest way to pause/resume mid-WOD? |
| 13 | `13_active_amrap_complete.png` | Workout complete (AMRAP) | "Finished!" + TOTAL TIME stat card + Again/Done. NOTE: reached by pressing Stop mid-workout — Stop always ends at this screen. |
| 14 | `14_active_fortime_countup.png` | For Time running (count-up) | Elapsed stopwatch display + third "Done" flag button. Is the flag's meaning (log my finish) clear vs Stop? |
| 15 | `15_active_emom_round2.png` | EMOM running | Round 2/10 of 1:00 intervals; giant time = remaining in current interval. Is "which number am I looking at" instantly clear? |
| 16 | `16_active_tabata_rest.png` | Tabata rest phase | Blue REST phase. Work↔rest phase distinction at a glance / at distance. |
| 17 | `17_active_tabata_complete.png` | Workout complete (Tabata) | Completion with ROUNDS card (2/2). (Capture note: rounds were set to 2 so the tour could finish — classic is 8.) |
| 18 | `18_home_landscape.png` | Home (landscape) | Same home in landscape — layout parity check. |
| 19 | `19_amrap_setup_landscape.png` | AMRAP setup (landscape) | Two-column landscape setup layout + compact START. |
| 20 | `20_active_work_landscape.png` | AMRAP running (landscape) | The propped-phone gym view. Judge hard for 3-metre readability. |
| 21 | `21_complete_landscape.png` | Complete (landscape) | Completion two-column layout. |

## Known constraints (so feedback is actionable)

- **Dark-only, English-only, iPhone-only** are v1 decisions — don't file them as
  findings; do file execution problems within them.
- **Free with no monetisation** is deliberate for v1.
- **No workout presets, no history/log, custom prep countdown fixed at 10s** —
  deliberately cut from v1. If their absence badly hurts the core loop you may say
  so as a *strategic* observation, but the priority is what's on the screens.
- **Voice cues are audio** — you can only judge their UI surface (discoverability,
  labelling, preview affordance), not the sound itself.
- Capture artifacts: screen 17 shows 2 rounds because the capture run shortened
  the workout (not a bug); screens were taken on a simulator, so status-bar
  content is stock; screen 15 was stopped mid-round-2 by the capture run.
- Screens come from a **debug build**: the yellow/black striped bar on screen 18
  is Flutter's debug overflow indicator. The overflow itself is real (that content
  genuinely does not fit and is cut off in release) — treat the missing/clipped
  content as the finding, not the stripes' appearance.
- The status bar is hidden during active workouts by design (immersive mode).

## Evaluate against

Nielsen's 10 usability heuristics **and** these product lenses:

- **5-second test:** on screen 01, is it obvious what the app does, and does it
  look better than the free alternatives?
- **15-second setup:** from screen 01, can a sweaty athlete configure today's WOD
  (say 7 rounds of 40s work / 20s rest) with gloves on, without reading anything
  twice?
- **3-metre glanceability:** on screens 10–16 and 20, what reads from across a
  garage gym and what doesn't (type size, contrast, colour coding, information
  placement)?
- **Panic actions:** mid-WOD, how fast can they pause, resume, or bail out
  entirely? Is any destructive action too easy or too hidden?
- **Comprehension:** do AMRAP/EMOM/Tabata semantics on screen match what an
  athlete expects (what counts up, what counts down, what a "round" is)?
- **Honesty & trust:** does what the UI says match what it does (e.g. "Finished!"
  after pressing Stop, summary numbers, toggle states)?
- **First-run orientation:** with no onboarding, does screen 01 alone teach the
  app? Is the voice-cue wedge discoverable at all before the first workout?
- **Accessibility:** contrast (especially the grey-on-ink secondary text),
  touch-target sizes, one-handed reach, text scaling risk.
- **Landscape parity:** are screens 18–21 first-class or an afterthought?
- **Consistency & craft:** spacing, alignment, casing, iconography, colour
  semantics across all 21 screens.

## Output format (use exactly this)

**1. Top 5 problems, ranked** — most impactful first:

| # | Severity | Screen(s) | Issue | Why it matters | Suggested fix |
|---|----------|-----------|-------|----------------|---------------|

Severity = Critical (blocks the task / loses the user) · High · Medium · Low.

**2. Full findings** — every other issue, same columns, grouped by screen.

**3. Three pointed questions:**
- What, if anything, would make you **not keep using** this app?
- What would make you **stop trusting** it mid-workout?
- If you could ship only **one** change before the next release, what is it and why?

**4. One genuine strength** (one sentence — so it isn't weakened in iteration).

Prefer specific, testable fixes ("move X above the fold", "rename Y to …") over
vague advice ("improve hierarchy").

---

### Naming your reply
Save as `UX_HEURISTIC_EVALUATION_<MODEL>.md`, `<MODEL>` = your model name + version
in caps — e.g. `UX_HEURISTIC_EVALUATION_GPT-5.md`, `..._SONNET-4.6.md`.
