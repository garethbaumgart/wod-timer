"""Does the gap between the two pips survive an echoing room? Median over many rooms."""
import sys, importlib.util
import numpy as np
spec = importlib.util.spec_from_file_location("make", sys.argv[1])
sys.argv = [sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]]
make = importlib.util.module_from_spec(spec); spec.loader.exec_module(make)
SR = make.SR
def dip(x, onset2_ms, pip_ms, rt60, seed):
    y = make.room(np.concatenate([x, np.zeros(SR)]), rt60=rt60, seed=seed)
    fr = int(SR * 0.02)
    def lvl(ms):
        i = int(SR * ms / 1000); return np.sqrt((y[i:i + fr] ** 2).mean())
    # level in the last 20 ms of the gap, against the level 30 ms into pip 2
    return make.db(lvl(onset2_ms - 20) / lvl(onset2_ms + 30))
shapes = {
    "now: 80 ms pips, 60 ms gap, 1031 Hz": (make.CANDIDATES["a_now"][1], 160),
    "same pips, 110 ms gap, 1031 Hz": (make.pair(make.pip(1031, 100, -12, make.HIGH, release_ms=35), make.pip(1031, 100, -12, make.HIGH, release_ms=35), 110), 210),
    "fuller: 120 ms pips, 110 ms gap, 1031 Hz": (make.CANDIDATES["b_fuller"][1], 230),
    "mid tone: 120 ms pips, 110 ms gap, 687 Hz": (make.CANDIDATES["c_mid_tone"][1], 230),
    "watch chime: 70 ms pips, 90 ms gap, 2062 Hz": (make.CANDIDATES["e_watch_chime"][1], 160),
}
for rt60 in (0.8, 1.4, 2.2):
    print(f"RT60 {rt60} s, median dip before the second pip over 200 rooms (0 dB = no gap left):")
    for name, (x, onset2) in shapes.items():
        d = [dip(x, onset2, 0, rt60, s) for s in range(200)]
        print(f"   {name}: {np.median(d):.1f} dB (quartiles {np.percentile(d,25):.1f} to {np.percentile(d,75):.1f})")
