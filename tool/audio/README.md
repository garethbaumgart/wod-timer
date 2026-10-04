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

Mix: the beeps sit about 5.5 dB above the voice. The voice clips are levelled
to match by `tool/audio/level_voices.py`. The watch has identical copies in
`ios/WODTimerWatch/Resources/audio/beeps/`.
