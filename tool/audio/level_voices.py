#!/usr/bin/env python3
"""Level every voice cue to the same loudness, for the gym-timer mix.

The beeps sit about 5.5 dB above the voice (measured from the SmartWOD
recording Gareth chose, 4 Oct 2026). That balance only holds if every clip
in every pack is equally loud, so each clip's speech (its 20 ms frames above
a tenth of its loudest) is set to TARGET_DB, with a -4 dBFS limiter for the
peaks. TARGET_DB leaves headroom: the high beep and a line start together, and
their peaks must sum under full scale or the phone clips. Reads the ORIGINAL recordings from git (SOURCE_REV), so re-running is
idempotent, and writes the phone assets and the watch copies. Clips added
after SOURCE_REV (new voice lines) are not in git there yet: level a new
recording by pointing SOURCE_REV at the commit that adds it.

    python3 tool/audio/level_voices.py
"""
import pathlib
import subprocess

import numpy as np

SOURCE_REV = "02442bb"  # last commit with the unlevelled recordings
TARGET_DB = -17.0
PACKS = ("major", "liam", "holly")
SR = 44100
ROOT = pathlib.Path(__file__).resolve().parents[2]
OUTPUTS = (ROOT / "assets/audio", ROOT / "ios/WODTimerWatch/Resources/audio")


def decode(data: bytes) -> np.ndarray:
    raw = subprocess.run(
        ["ffmpeg", "-loglevel", "error", "-i", "pipe:0", "-f", "s16le",
         "-ac", "1", "-ar", str(SR), "-"],
        input=data, capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.int16).astype(float) / 32768


def speech_db(y: np.ndarray) -> float:
    f = int(0.02 * SR)
    r = np.array([np.sqrt(np.mean(y[i:i + f] ** 2)) for i in range(0, len(y) - f, f)])
    top = r[r > r.max() * 0.1]
    return 20 * np.log10(np.sqrt(np.mean(top ** 2)))


def main() -> None:
    for pack in PACKS:
        names = subprocess.run(
            ["git", "ls-tree", "--name-only", f"{SOURCE_REV}:assets/audio/{pack}"],
            cwd=ROOT, capture_output=True, text=True, check=True).stdout.split()
        # Only the clips the app still ships: a clip deleted from the pack
        # (2.1.0 dropped the spoken countdowns, "Next interval" and "No rep")
        # is never brought back. New clips are leveled once they are added.
        live = {p.name for p in (OUTPUTS[0] / pack).glob("*.mp3")}
        for name in (n for n in names if n.endswith(".mp3") and n in live):
            src = subprocess.run(
                ["git", "show", f"{SOURCE_REV}:assets/audio/{pack}/{name}"],
                cwd=ROOT, capture_output=True, check=True).stdout
            gain = TARGET_DB - speech_db(decode(src))
            out = subprocess.run(
                ["ffmpeg", "-loglevel", "error", "-i", "pipe:0", "-af",
                 f"volume={gain:.2f}dB,alimiter=limit=0.631:level=false:attack=2:release=40",
                 "-ar", str(SR), "-ac", "1", "-c:a", "libmp3lame", "-b:a", "128k",
                 "-map_metadata", "-1", "-f", "mp3", "-"],
                input=src, capture_output=True, check=True).stdout
            for base in OUTPUTS:
                (base / pack / name).write_bytes(out)
            print(f"{pack}/{name}: {gain:+.1f} dB")


if __name__ == "__main__":
    main()
