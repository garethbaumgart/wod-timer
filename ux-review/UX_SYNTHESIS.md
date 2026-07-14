# The Wharf WOD Timer — UX review synthesis

Aggregated from 5 independent cold reviews, 14 Jul 2026. This round ran five
Fable 5 agents (in-repo), each given the identical `REVIEW_REQUEST.md` packet +
21 screens but a distinct primary lens: FIRSTRUN, GYMGLANCE, CRAFT, A11Y,
FLOWTRUST. `n/5` = how many raised the theme independently. Ranked by
**consensus × severity**. The packet is self-contained, so external-model passes
(GPT/Gemini/Composer, per the HFD round) can be added to this folder later and
folded in. Capture artifacts and code-verified facts the reviewers couldn't see
are pulled out separately so we don't chase ghosts.

---

## The headline: the "ship only one change" vote split 3–2 — so both ship

1. **Guard and honest-ify the Stop flow.** One unconfirmed tap on Stop — 5 cm
   from Pause, at 170 bpm — irreversibly kills the workout, then the app
   **celebrates**: green check, "Finished!", 100% green progress bar at 0:19 of
   a 10:00 AMRAP. **5/5 Critical; 3/5 picked it as the one change.** (Code
   check: stopping during the GET READY countdown also lands on "Finished!
   00:00".)
2. **Make workout state readable at 3 metres.** The giant digits stay white in
   every phase; work/rest/get-ready/paused live only in a ~14pt pill word, and
   the EMOM/Tabata round counter is ~15pt grey at ~2.7:1. Paused is
   indistinguishable from running at distance. **5/5 Critical; 2/5 picked it as
   the one change.** Fix direction all five converged on: tint the digits (or
   flood a background wash) per phase — orange get-ready, green work, blue
   rest, dimmed-grey paused — and promote "ROUND X/Y" to ≥40pt white under the
   timer.

And one bug outranks everything but those two: **landscape home is broken**
(5/5): the list overflows by 175px, TABATA is unreachable, the gear collides
with EMOM — while the app itself offers "Landscape only" orientation lock, so a
user can lock themselves out of a quarter of the product. Code-verified: home
has no landscape layout at all (single portrait column,
`placeholder_pages.dart`).

## The strength to protect (all five agree, verbatim theme)

The giant white Outfit w900 digits on deep ink, with nothing competing —
genuinely readable from across a gym and a distinctive identity. **Add state
via colour, not via more furniture.** Any fix that shrinks or crowds the clock
is worse than the problem it solves. (The setup flow's big-target steppers +
sane defaults + Classic Tabata preset also clear the 15-second bar —
GYMGLANCE's strength pick.)

---

## Tier 1 — consensus must-fixes (all 5/5)

| # | n/5 | Severity | Screens | Issue | Agreed fix |
|---|-----|----------|---------|-------|------------|
| 1 | 5/5 | Critical | 10–16, 20 → 13 | **Stop is a one-tap kill switch with a lying end screen.** No confirm, no undo, no resume; early stop shows "Finished!" + full green bar; stop during prep shows "Finished! 00:00". | **Hold-to-stop** (~0.8s ring-fill; plain tap flashes "Hold to end") and **split the end state**: natural completion → "Finished!"; early stop → "Stopped — 0:19 of 10:00", bar at true fraction, neutral mark, no celebration. Note: an "Exit Workout?" confirm dialog already exists in code but is wired to an unreachable path (see code-verified findings) — the guard was built, never connected. |
| 2 | 5/5 | Critical | 10–12, 15, 16, 20 | **Phase and round are illegible at distance.** White digits in every phase; 14pt pill; paused ≈ running; round counter tiny grey; progress bar a ~2–4px hairline with a 1.05:1 track. | **Phase-coloured active screens**: tint digits or flood a low-luminance wash (orange prep / green work / blue rest / grey paused, paused digits dimmed to ~40% + slow pulse). **"ROUND 2/10" at ≥40pt white** directly under the digits. Progress bar ≥8pt, phase-coloured, visible track, full-width in landscape, EMOM/Tabata round ticks. |
| 3 | 5/5 | Critical | 18 (+09) | **Landscape home broken**: 175px overflow, TABATA unreachable, gear collides; "Landscape only" lock makes it a trap. | Purpose-built landscape home (2×2 mode grid, gear pinned to a corner); scroll view as the stopgap. Also fix the orientation sheet's own 19px landscape overflow (code-verified). |
| 4 | 5/5 | Critical/High | 14 → 13 | **For Time's finish action is the dimmest control on screen**: an unlabeled grey flag (ring ~1.0:1) that reads as disabled/lap, beside Pause; Stop and flag land on identical "Finished!" outcomes. | Replace the flag with a **large labelled FINISH control** (filled, high-contrast, distinct from Stop), demote Pause; finish → "Finished!" with frozen time, Stop → "Stopped" state (per fix #1). |
| 5 | 5/5 | High | 01–08 | **The voice wedge is invisible until it starts talking.** Nothing on home or any setup screen mentions voices; picker has no preview, no Off, Holly has no descriptor, icon families clash. | **Voice chip on every setup screen** next to START ("🔊 Major ▸" → opens picker); **play-preview button per voice** ("3-2-1 GO!" sample); add **Off**; give Holly a descriptor; one icon family. |
| 6 | 5/5 | High | 02–06 vs 13/17 | **The app's arithmetic disagrees with the athlete.** Setup silently adds the 10s prep ("Classic Tabata = 4m 10s"); completion excludes prep; TOTAL TIME means three different things; a full AMRAP's "result" is the number the user typed. | One definition everywhere: summary shows configured work time (**"4:00" + muted "+ 0:10 get-ready"**), completion uses the same basis, formats unified to one clock style (see Tier 3 sweep). |
| 7 | 5/5 | High | 11, 13 | **AMRAP can't hold its own score** — no round counting mid-WOD, completion echoes the configured duration. All five: this is what sends the athlete back to the wall clock + chalk. | Strategic feature (Gareth call, below): tap-anywhere round counter feeding a ROUNDS hero card on completion. Interim honesty fix: relabel the stat ("DURATION 10:00") or add a +/- rounds stepper on the summary card. |
| 8 | 5/5 | High | 01–07, 13–15, 21 | **Systemic sub-AA contrast on every functional grey** (A11Y measured: values #666 = 3.5:1, labels #555 = 2.7:1, gear/chevrons #333 = 1.6:1, stepper borders #1A1A1A = 1.17:1, progress track 1.05:1, Stop/flag rings ~1.0–1.5:1). Steppers — the app's only input — read as *disabled*. | Contrast pass over the palette: functional text ≥4.5:1 (≈#9A9AA2+ on #050510), borders/icons/tracks ≥3:1; keep purely decorative labels dim if desired. One palette edit in `app_colors.dart` covers most of it. |
| 9 | 5/5 | Med–High | 01 vs 03/05/06, 10, 14, 16 | **Colour system collides**: home teaches mode hues (green/blue/magenta/orange) that runtime reuses as phase hues (work/rest/prep) plus brand-green-everything; magenta orphaned after home. | Give each hue one owner: **phase colours own active screens** (pairs with fix #2); mode colours stay on home/setup accents only (or go monochrome); neutral in-workout controls so coloured buttons can't lie about phase. |

## Tier 2 — strong consensus, medium severity

| # | n/5 | Screens | Issue | Fix |
|---|-----|---------|-------|-----|
| 10 | 5/5 | 02–06 | Stepper grammar inconsistent (−/+ around labels vs around values), step sizes unlabeled except Tabata's "5s". *Code fact: hold-to-repeat already exists (400ms delay) — it's undiscoverable, not missing.* | Unify on the Tabata pattern (value-flanked, step labelled "±1m"/"±5s"); add a first-use "hold to repeat" hint; consider tap-on-digits direct entry. |
| 11 | 4/5 | 10 | Prep renders "00:03" in full MM:SS — five glyphs to say "3", white despite the orange pill. | Single giant phase-coloured digit for the last 5s of prep (matches the voice count); consider tap-to-skip (2/5 asked). |
| 12 | 3/5 | 15, 16 | Sub-minute phases waste half the display on a dead "00:" prefix (Tabata intervals are always <60s). | Render seconds-only ("57", "10") when the phase is under a minute — roughly doubles glyph height for free. |
| 13 | 5/5 | 06 | CLASSIC TABATA chip ambiguous: button or state? *Code fact: it's a plain re-apply button; it never highlights/deselects.* | Make it a real toggle chip: lit only while values = 20/10×8, tap re-applies. |
| 14 | 5/5 | 13, 17, 21 | Completion hierarchy inverted ("Finished!" outweighs the stat); landscape completion drops the card and bar entirely; "Again" is a ghost (3.5:1). | Stat becomes the hero (≥64pt, per-mode: time / rounds); same card components in both orientations; "Again" legible; add config line ("AMRAP · 10:00"). |
| 15 | 4/5 | 11, 15 | Count-direction unlabeled outside For Time ("is 09:46 elapsed or remaining?"); EMOM pill wastes its slot on a permanent "WORK". | Same small label under digits in all modes ("REMAINING"/"ELAPSED", ≥20pt); EMOM pill → "EMOM · ROUND 2/10". |
| 16 | 5/5 | 01 | Home: ~40–55% dead space, no value-prop line, gear + chevrons near-invisible (1.6:1), rows have no card/pressed affordance. | One sub-line under the hero ("Voice-coached gym timer"); gear ≥28pt at ≥3:1 (consider top-right); visible row bounds. |
| 17 | 2/5 | 14 | For Time never shows the cap mid-workout — pacing against it is blind math. | Small "CAP 20:00" under the elapsed label. |
| 18 | 4/5 | all | Dynamic Type robustness unproven; fixed columns + screen 18 already overflowing at default size is bad evidence. | QA pass at AX text sizes; scrollable setup columns; cap scaling on the hero digits only. |

## Tier 3 — one polish sweep, low severity (mostly 3–5/5)

- **Casing/label sweep**: "FOR TIME" vs "For Time" vs pills; "START WORKOUT" vs "START"; pick one scheme (5/5).
- **Duration-format sweep**: "10:00" / "10m 10s" / "1m" / "00:19" → one clock format + one compact-parameter format (5/5).
- **Voice/orientation sheets**: one icon family, explicit Done/close affordance (2/5), rename "Orientation Lock" → "Orientation" (2/5).
- **About**: add Send-feedback (mailto) + privacy row (3/5).
- **Silent-switch disclosure**: one caption under AUDIO — "voice cues play even on silent" (1/5, but it's the app's own README promise; cheap trust win).
- **AMRAP pill**: "AMRAP · WORK" phase is filler — show target or nothing (2/5).
- **Landscape active composition**: digits no bigger than portrait while 60% of the screen idles; pill/progress alignment wobble (GYMGLANCE #3; 3/5 noted the 55–60% progress bar).

## Code-verified findings the reviewers couldn't see

1. **The Tabata "phase preview" ("WORK in 3s") is dead UI.** `_buildSubLabel`
   returns the rounds label whenever `totalRounds != null` — always true for
   Tabata — so the preview branch is unreachable. The README advertises it;
   the voice cues cover the transition audibly, the visual never fires. Either
   wire it (stack it with the round label) or delete the code. All five
   reviewers flagged the missing capture; the truth is stronger.
2. **The "Exit Workout?" confirmation dialog is orphaned.** It exists in
   `timer_active_page.dart` but is only reachable from the not-configured
   placeholder's reset path — never from Stop. The guard Tier-1 #1 demands was
   written and never wired.
3. **Orientation picker sheet overflows 19px in landscape**
   (`settings_page.dart:373`, RenderFlex exception during capture).
4. **Stop during GET READY → "Finished! 00:00"** (state machine allows
   `complete()` from preparing).
5. **Invisible gestures**: double-tap-to-pause and swipe-up/down pause/resume
   already exist on the active screen; no reviewer could see them and no UI
   hints at them. They also collide with the proposed tap-to-count-rounds —
   the interaction design for Tier-1 #7 must resolve that conflict.
6. **Telemetry is honest even where the UI isn't**: `workout_completed` fires
   with `ended_by: user|timer`, so fixing the UI needs no analytics change.
7. Touch targets are fine in code (48pt steppers, 64–72pt circle controls) —
   the a11y complaints are about *perceived* size (1.0–1.5:1 rings), which the
   contrast pass fixes.

## Capture artifacts (verified, don't chase)

- Screen 17 shows "2/2 ROUNDS" — capture shortened the workout to 2 rounds.
- Screen 15's EMOM was stopped mid-round-2 by the tour.
- Yellow/black stripes on 18 are Flutter's debug overflow indicator; release
  silently clips instead (the overflow itself is Tier-1 #3).
- The packet briefly listed a phase-preview screenshot that can't exist (see
  code-verified #1); reviewers correctly noted the numbering wobble — fixed in
  the packet, harmless to findings.
- Landscape coverage was AMRAP-only (FLOWTRUST caught it): EMOM/Tabata/paused
  landscape states should be captured in the next round — same tour, cheap.

## Strategic calls for Gareth (not bugs — decisions)

1. **AMRAP round counting** (Tier-1 #7): all five demand it; it's the
   retention argument vs the wall clock. But it's a real feature (tap zones vs
   the existing double-tap-pause gesture, score persistence expectations), not
   a patch. Decide: ship v1.1 with tap-to-count, or interim-relabel the stat.
2. **Voice preview / voice Off** (Tier-1 #5): feature work on the wedge's
   surface; small but real (audio assets already exist per voice).
3. **Home value-prop line**: one line of copy decides how the app pitches
   itself ("Voice-coached gym timer"); also the "WOD." hero vs the "Wharf WOD"
   name — branding call.
4. **Landscape redesign scope**: stopgap scroll (hours) vs designed 2×2 home +
   completion parity (a day-ish).
5. **Prep skip / configurable prep**: fixed 10s was a v1 cut; 2/5 reviewers
   want at least tap-to-skip.

## Suggested batching

- **1.0.1 "trust patch"** (small, high-yield, no new features): hold-to-stop +
  wire the orphaned confirm where appropriate, honest "Stopped" end state (incl.
  prep-stop), landscape-home stopgap scroll + orientation-sheet overflow,
  contrast palette pass, labelled FINISH for For Time, prep-math line in
  summaries, casing/format sweep.
- **1.1 "gym-glance" release** (design work): phase-coloured active screens +
  giant round counter + progress bar rework, seconds-only sub-minute display,
  designed landscape home/completion, voice chip + preview + Off, single-digit
  prep, AMRAP round counting (if greenlit).

*Files: 5 × `UX_HEURISTIC_EVALUATION_FABLE5-*.md` (this folder), packet
`REVIEW_REQUEST.md`, gallery `index.html`, screens in `screens/` (gitignored,
regenerable via `integration_test/ux_review_tour_test.dart`).*
