# Halfway sound options (27 Nov 2026)

Gareth asked whether the mid / halfway sound (`assets/audio/beeps/mid.wav`) is the
right one. Review and five sounds to hear: https://claude.ai/artifact/F5n8SQX6Xb5P9msWt5macR

Nothing here is in the app. Waiting on his pick.

| | Sound | Pitch | Pips | Level against the change beep |
|---|---|---|---|---|
| A | Now (shipped `mid.wav`) | 1031 Hz | 2 x 100 ms, 60 ms gap | 2.5 dB under |
| B | Fuller | 1031 Hz | 2 x 120 ms, 110 ms gap | level |
| C | Mid tone (recommended) | 687 Hz | 2 x 120 ms, 110 ms gap | level |
| D | Rising pair | 687 then 872 Hz | 2 x 130 ms, 90 ms gap | level |
| E | Watch chime | 2062 Hz | 2 x 70 ms, 90 ms gap | 3 dB under |

What was measured: the shipped pips sit on the change beep's exact pitch and carry
about a tenth of its energy. The two-pip shape is fine: over 200 simulated echoing
rooms the 60 ms gap survives about as well as a 110 ms one (`gap_check.py`).

- `candidates/*.wav`: the five sounds, ready to copy over `mid.wav` in the three
  places (`assets/audio/beeps`, `ios/WODTimerWatch/Resources/audio/beeps`,
  `android/wear/src/main/assets/audio/beeps`).
- `make.py <repo> <cue-log dir> <out dir>`: synthesises the sounds and renders each
  into the app's own cue log (`cues_beeps.json`, `cues_major.json`, written by
  `test/tool/cue_timeline_test.dart` with `CUE_TIMELINE_OUT`; the Beeps only log came
  from a copy of that test with `VoiceOption.off`).
- `build_page.py` + `page_template.html`: the listening page, clips embedded.
