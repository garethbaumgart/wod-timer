# Gym-timer beeps (assets/audio/beeps)

Matched to the SmartWOD screen recording Gareth chose on 4 Oct 2026. Each
beep is resynthesised, harmonic by harmonic, from what was measured in that
recording; no audio from SmartWOD is in these files.

- `low_3.wav`, `low_2.wav`, `low_1.wav`: the countdown in the last three
  seconds of every phase. About 435.5 Hz with odd harmonics: a sharp click,
  a dip, then a swell to full level over about 0.2 s, about 0.55 s long. The
  three differ slightly, as they do in the recording.
- `high.wav`: on every change (start, round, rest, work, end). About 1031 Hz,
  about 0.78 s. The voice line starts at the same moment.
- `mid.wav`: the halfway pips (2.5.0), halfway through every EMOM interval and
  Tabata work block and halfway through an AMRAP or For Time clock. Two pips
  of 120 ms, 110 ms apart, at 687 Hz: a fifth under the high beep and well
  clear of the low ones, at the high beep's level. Not from the recording:
  written by `tool/audio/mid_beep.py` with the low beeps' harmonic recipe.
  Gareth chose it by ear on 27 Nov 2026 from five options (the first pips
  were the high beep's own pitch, turned down, and the easiest cue to miss).

Mix: the beeps sit about 5.5 dB above the voice. The voice clips are levelled
to match by `tool/audio/level_voices.py`. Apple Watch and Wear OS have identical copies in
`ios/WODTimerWatch/Resources/audio/beeps/` and
`android/wear/src/main/assets/audio/beeps/`; `test/tool/beep_files_test.dart`
fails when one drifts, or when the halfway pips lose their pitch or level.
