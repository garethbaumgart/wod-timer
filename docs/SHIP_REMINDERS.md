# Ship reminders

Printed by the ship script at the start of every Wharf WOD ship. Claude tells
Gareth what is still open here on every build, and removes an item once it
has shipped.

## Voice clips still to record (asked 4 Oct 2026)

Needed in all three voices (Major, Liam, Holly): 31 clips each, 93 in total.

| File | Says | Why |
|---|---|---|
| `round_2.mp3` to `round_30.mp3` | "Round 2" to "Round 30" | Every EMOM and Tabata round change except the last ("Last round" stays), as SmartWOD does. EMOM goes to 30 rounds, Tabata to 20; Round 2 to 20 is the minimum, and above that the app falls back to "Next round". |
| `well_done.mp3` | "Well done" | The end of a workout, added to the "Good job" / "That's it" mix. |
| `one_minute.mp3` | "One minute" | One minute left in an AMRAP or For Time longer than 2 minutes. |

Also: re-record Major's `rest.mp3` if it doesn't sound clearly like "Rest"
(the transcriber hears "West").

Recording: no silence before the first word (the line lands on the high
beep), under about 1.2 seconds, dry (no reverb or music), same voice and mic
setup as the pack's other clips. Volume doesn't matter: new clips go through
`tool/audio/level_voices.py`. Once they arrive, wire them into the cue logic
on phone and watch.

## Before the 2.2.0 App Store release (TestFlight does not need these)

The watch app now uses HealthKit (a workout session keeps it running when
the wrist drops, and the WOD is saved to Health). Before `release`:

- Privacy policy (mentalmetal-site, wharfwod/privacy): add that the Apple
  Watch app saves workouts to Apple Health on the device and reads no health
  data; nothing leaves the watch. Guideline 5.1.3.
- App Review notes: say HealthKit keeps the timer running off screen and
  saves the workout.
- Gareth's real-watch sign-off of the 2.2.0 TestFlight build (cues with the
  wrist down, wrist raise returns to the app, Health permission, the
  workout in Fitness).
