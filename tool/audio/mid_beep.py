#!/usr/bin/env python3
"""Write the halfway sound, beeps/mid.wav: the "Mid tone" Gareth chose on 27 Nov 2026.

Two pips on a pitch of their own, a fifth under the change beep and well clear
of the 3, 2, 1 beep, at the change beep's level:

    687.3 Hz (1031 x 2/3), 2 pips of 120 ms, 110 ms of silence between them

The harmonic recipe is the one measured in the low beeps (odd harmonics), so the
pips sound like the same family and keep some bite on a small speaker. The 2.5.0
pips this replaces were two 0.1 s clips of the high beep at x0.75: the change
beep's exact pitch and about a tenth of its energy.

Writes the phone asset and the Apple Watch and Wear OS copies, which must stay
byte-identical (test/tool/beep_files_test.dart checks that, and the pitch and
level).

    python3 tool/audio/mid_beep.py
"""
import pathlib
import wave

import numpy as np

SR = 44100
ROOT = pathlib.Path(__file__).resolve().parents[2]
OUTPUTS = (
    ROOT / "assets/audio/beeps/mid.wav",
    ROOT / "ios/WODTimerWatch/Resources/audio/beeps/mid.wav",
    ROOT / "android/wear/src/main/assets/audio/beeps/mid.wav",
)

F_CHANGE = 1031.0                 # high.wav
F_MID = F_CHANGE * 2 / 3          # a fifth under it
PIP_MS = 120
GAP_MS = 110
TAIL_MS = 40
PEAK_DB = -9.0                    # the change beep's sustained peak
# (harmonic, level in dB): the recipe measured in low_N.wav
PARTIALS = [(1, 0.0), (3, -20.9), (5, -31.8), (7, -39.0)]


def amp(d):
    return 10 ** (d / 20)


def pip(freq, ms, peak_db, partials, attack_ms=6, release_ms=25):
    """One pip: a fundamental plus odd harmonics, raised-cosine edges."""
    n = int(SR * ms / 1000)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for mult, level_db in partials:
        x += amp(level_db) * np.sin(2 * np.pi * freq * mult * t)
    x /= np.abs(x).max()
    a, r = int(SR * attack_ms / 1000), int(SR * release_ms / 1000)
    env = np.ones(n)
    env[:a] = 0.5 - 0.5 * np.cos(np.pi * np.arange(a) / a)
    env[-r:] = 0.5 + 0.5 * np.cos(np.pi * np.arange(r) / r)
    return x * env * amp(peak_db)


def mid_beep():
    one = pip(F_MID, PIP_MS, PEAK_DB, PARTIALS)
    gap = np.zeros(int(SR * GAP_MS / 1000))
    return np.concatenate([one, gap, one, np.zeros(int(SR * TAIL_MS / 1000))])


def save(path, x):
    x = np.clip(x, -1, 1)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())


if __name__ == "__main__":
    sound = mid_beep()
    for out in OUTPUTS:
        save(out, sound)
        print(f"wrote {out.relative_to(ROOT)} ({len(sound) / SR * 1000:.0f} ms)")
