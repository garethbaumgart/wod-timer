"""Halfway-cue candidates for Wharf WOD, rendered into the app's own cue timeline.

  python3 -I make.py <wod-timer repo> <cue-log dir> <out dir>

Reads the cue logs written by test/tool/cue_timeline_test.dart (CUE_TIMELINE_OUT),
so every clip plays exactly what the app plays, when it plays it. Only
audio/beeps/mid.wav is swapped for each candidate.
"""
import json
import subprocess
import sys
import wave

import numpy as np

SR = 44100
REPO, LOGS, OUT = sys.argv[1], sys.argv[2], sys.argv[3]


def db(v):
    return 20 * np.log10(max(float(v), 1e-9))


def amp(d):
    return 10 ** (d / 20)


def load_wav(path):
    w = wave.open(path, "rb")
    assert w.getframerate() == SR and w.getsampwidth() == 2, path
    x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64) / 32768
    if w.getnchannels() > 1:
        x = x.reshape(-1, w.getnchannels()).mean(axis=1)
    return x


def load_any(path):
    if path.endswith(".wav"):
        return load_wav(path)
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", path, "-f", "s16le", "-ac", "1", "-ar", str(SR), "-"],
        check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.int16).astype(np.float64) / 32768


def save(path, x):
    x = np.clip(x, -1, 1)
    w = wave.open(path, "wb")
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((x * 32767).astype(np.int16).tobytes())
    w.close()


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


def pair(first, second, gap_ms, tail_ms=40):
    gap = np.zeros(int(SR * gap_ms / 1000))
    return np.concatenate([first, gap, second, np.zeros(int(SR * tail_ms / 1000))])


# The harmonic recipes measured in the shipped beeps.
HIGH = [(1, 0.0), (3, -28.6)]                       # high.wav: 1031 Hz
LOW = [(1, 0.0), (3, -20.9), (5, -31.8), (7, -39.0)]  # low_N.wav: 436 Hz

F_HIGH = 1031.0          # the change beep
F_LOW = 436.0            # the 3, 2, 1 beeps
F_MID = F_HIGH * 2 / 3   # 687 Hz: a fifth under the change beep
F_MID_UP = F_LOW * 2     # 872 Hz: an octave over the countdown beep

CANDIDATES = {
    # key: (label, samples)
    "a_now": ("Now", load_wav(f"{REPO}/assets/audio/beeps/mid.wav")),
    "b_fuller": ("Fuller", pair(pip(F_HIGH, 120, -9, HIGH), pip(F_HIGH, 120, -9, HIGH), 110)),
    "c_mid_tone": ("Mid tone", pair(pip(F_MID, 120, -9, LOW), pip(F_MID, 120, -9, LOW), 110)),
    "d_rising_pair": ("Rising pair", pair(pip(F_MID, 130, -9, LOW), pip(F_MID_UP, 130, -9, LOW), 90)),
    "e_watch_chime": ("Watch chime", pair(pip(F_HIGH * 2, 70, -12, [(1, 0.0), (3, -30.0)]),
                                          pip(F_HIGH * 2, 70, -12, [(1, 0.0), (3, -30.0)]), 90)),
}

_assets = {}


def asset(name):
    if name not in _assets:
        _assets[name] = load_any(f"{REPO}/assets/{name}")
    return _assets[name]


def render(events, start_s, end_s, mid):
    """Mix the logged cues that start inside [start_s, end_s)."""
    out = np.zeros(int(SR * (end_s - start_s)))
    for e in events:
        t = e["ms"] / 1000
        if not (start_s <= t < end_s):
            continue
        x = mid if e["asset"].endswith("beeps/mid.wav") else asset(e["asset"])
        i = int(SR * (t - start_s))
        x = x[: len(out) - i]
        out[i:i + len(x)] += x
    return out


def pink(n, rng):
    spec = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1 / SR)
    f[0] = f[1]
    spec /= np.sqrt(f)
    spec[f < 40] = 0
    x = np.fft.irfft(spec, n)
    return x / np.sqrt((x ** 2).mean())


def room(x, rt60=1.4, direct_to_reverb_db=0.0, seed=7):
    """A hard-walled box: the dry sound plus an exponentially decaying tail."""
    rng = np.random.default_rng(seed)
    n = int(SR * rt60 * 1.2)
    t = np.arange(n) / SR
    ir = rng.standard_normal(n) * np.exp(-6.91 * t / rt60)
    ir[: int(SR * 0.012)] = 0  # the first reflections arrive after 12 ms
    ir /= np.sqrt((ir ** 2).sum())
    size = 1 << int(np.ceil(np.log2(len(x) + n)))
    wet = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x)]
    return x + wet * amp(-direct_to_reverb_db)


def gap_dip_db(x):
    """How far the level falls between the two pips (20 ms frames, 5 ms hop)."""
    fr, hop = int(SR * 0.02), int(SR * 0.005)
    env = np.array([np.sqrt((x[i:i + fr] ** 2).mean()) for i in range(0, len(x) - fr, hop)])
    top = env.max()
    first = int(np.argmax(env > top * 0.7))
    # the second pip's peak: the last frame near the top level
    strong = np.nonzero(env > top * 0.7)[0]
    last = int(strong[-1])
    if last - first < 4:
        return 0.0
    return db(env[first:last + 1].min() / top)


if __name__ == "__main__":
    beeps = json.load(open(f"{LOGS}/cues_beeps.json"))
    major = json.load(open(f"{LOGS}/cues_major.json"))
    high = asset("audio/beeps/high.wav")
    high_rms = np.sqrt((high[: int(SR * 0.77)] ** 2).mean())
    high_energy = (high ** 2).sum()

    rng = np.random.default_rng(11)
    report = {}
    for key, (label, x) in CANDIDATES.items():
        save(f"{OUT}/{key}_alone.wav", np.concatenate([np.zeros(int(SR * 0.15)), x, np.zeros(int(SR * 0.25))]))

        # 1. One Tabata work block, Beeps only: pips at 10 s of 20, then 3, 2, 1 and the change.
        tabata = render(beeps["tabata"], 18.5, 31.2, x)
        save(f"{OUT}/{key}_tabata.wav", tabata)

        # 2. The same block under steady pink noise, a rough stand-in for music and a full
        #    room: set so the change beep sits 6 dB over the noise in its own third-octave
        #    band (pink noise: a third-octave band holds 1/30 of the power over 10 octaves).
        bed = pink(len(tabata), np.random.default_rng(11)) * high_rms / np.sqrt(1 / 30) * amp(-6)
        fade = int(SR * 0.25)
        bed[:fade] *= np.linspace(0, 1, fade); bed[-fade:] *= np.linspace(1, 0, fade)
        gain = amp(-1) / (np.abs(bed).max() + 0.45)   # one gain for every candidate
        save(f"{OUT}/{key}_noise.wav", (tabata + bed) * gain)

        # 3. An AMRAP's halfway with the Major voice: the pips and "Halfway" start together.
        voiced = render(major["amrap"], 39.5, 42.0, x)
        save(f"{OUT}/{key}_voice.wav", voiced)

        sounding = x[np.abs(x) > np.abs(x).max() * 0.1]
        worst = 0.0
        for pack in ("major", "liam", "holly"):
            v = asset(f"audio/{pack}/halfway.mp3")
            n = max(len(v), len(x))
            mix = np.zeros(n); mix[: len(x)] += x; mix[: len(v)] += v
            worst = max(worst, np.abs(mix).max())
        report[key] = {
            "label": label,
            "length_ms": round(1000 * (np.nonzero(np.abs(x) > 1e-3)[0][-1] + 1) / SR),
            "peak_dbfs": round(db(np.abs(x).max()), 1),
            "rms_sounding_db": round(db(np.sqrt((sounding ** 2).mean())), 1),
            "level_vs_change_beep_db": round(db(np.sqrt((sounding ** 2).mean()) / high_rms), 1),
            "energy_vs_change_beep_db": round(10 * np.log10((x ** 2).sum() / high_energy), 1),
            "worst_peak_with_halfway_voice_dbfs": round(db(worst), 1),
            "tabata_clip_peak_dbfs": round(db(np.abs(tabata).max()), 1),
            "noise_clip_gain_db": round(db(gain), 1),
        }
    json.dump(report, open(f"{OUT}/report.json", "w"), indent=2)
    for key, r in report.items():
        print(key, r)
