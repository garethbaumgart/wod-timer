# Next release backlog

Notes from Gareth to pick up in the next set of changes. Add new items here as they come in; move each into the release's plan or spec when the build starts.

## Built on feat/gym-beeps (4 Oct 2026), waiting on Gareth's listen

- **Gym-timer beeps in every workout.** Three low beeps (about 435.5 Hz) with 3, 2, 1 seconds left in every phase, then the high beep (about 1031 Hz) on the change with the voice line on it, matched to the SmartWOD recording Gareth chose. Spoken 3-2-1 and 5-4-3-2-1 replaced by the beeps; optional lines never talk over the count-in or another line; Beeps only = beeps without voice. Phone and watch. Assets: `assets/audio/beeps/`, voices levelled by `tool/audio/level_voices.py` (see `tool/audio/README.md`). Major mocks of all four workouts, rendered from the app's own cue log (`test/tool/cue_timeline_test.dart`): https://claude.ai/artifact/AoN3cUXdV73Q4ozoVAFRFC
- **Rate block (option 14 of https://claude.ai/artifact/AYaE7K23rdhJda7HHfQauH).** "How is Wharf WOD working for you?" with Love it (store page) and Could be better (feedback mail), both always shown (no review gating). Replaces the Rate and Send feedback rows.
- **Major is a Drill Sergeant.** Phone "Major (Drill Sergeant)", watch "Drill sergeant", same order.

## Shipped as 2.2.0 (5 Oct 2026): iOS build 22 submitted, Play vc14 production

- **The watch stays awake**: HKWorkoutSession per workout, haptic patterns
  (GO a double knock, rounds, rest, 3-2-1 taps), audio session fallback,
  Sound check row, Health row, whole-millisecond ticks. Plan:
  `docs/PLAN_2.2.0_watch_background.md`.

## Still open

- Heart rate on the watch live screen (the session already collects it; a
  read permission and one line of UI).

- Record "Round 2", "Round 3" and so on, plus "Well done", if wanted (EMOM says "Next round" today).

## Already merged, waiting to ship

