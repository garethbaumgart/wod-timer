#!/usr/bin/env python3
# Wharf WOD promo: transparent text/graphic overlay PNGs via SVG + rsvg-convert.
# Clone of the Squish/HFD pipeline shape, re-skinned to the app's "Signal"
# design system: deep-ink dark, signal green, heavy condensed caps.
import html
import os
import subprocess

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "work", "txt")
os.makedirs(OUT, exist_ok=True)

W, H = 1290, 2796
INK = "#F2F7EE"
GREEN = "#00FF88"
DIM = "#9aa79f"
SANS = "'Helvetica Neue', Helvetica, Arial, sans-serif"


def render(name, body, w=W, h=H):
    svg = (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
        f'viewBox="0 0 {w} {h}">{body}</svg>'
    )
    p = os.path.join(OUT, name + ".svg")
    with open(p, "w") as f:
        f.write(svg)
    subprocess.run(
        ["rsvg-convert", p, "-o", os.path.join(OUT, name + ".png")], check=True
    )
    print("wrote", name + ".png")


def esc(t):
    return html.escape(t)


def big(text, y, fs, fill=INK, weight=900, spacing=2, anchor="middle", x=W // 2):
    return (
        f'<text x="{x}" y="{y}" text-anchor="{anchor}" font-family="{SANS}" '
        f'font-size="{fs}" font-weight="{weight}" letter-spacing="{spacing}" '
        f'fill="{fill}">{esc(text)}</text>'
    )


# ---------------- icon squircle mask ----------------
render(
    "iconmask",
    f'<rect x="0" y="0" width="520" height="520" rx="118" fill="#ffffff"/>',
    w=520,
    h=520,
)

# ---------------- caption pills ----------------
def caption(name, text, cy=2280, fs=64):
    est = int(len(text) * fs * 0.58) + 150
    pw = min(max(est, 480), W - 70)
    ph = int(fs * 2.3)
    px = (W - pw) // 2
    py = cy - ph // 2
    baseline = cy + int(fs * 0.34)
    body = (
        # green signal tick on the pill's left edge, like the app's strips
        f'<rect x="{px}" y="{py}" width="{pw}" height="{ph}" rx="{ph // 2}" '
        f'fill="#05100a" fill-opacity="0.78" stroke="{GREEN}" stroke-opacity="0.35" stroke-width="3"/>'
        f'<rect x="{px + 34}" y="{cy - fs // 2 - 6}" width="10" height="{fs + 12}" rx="5" fill="{GREEN}"/>'
        + big(text, baseline, fs)
    )
    render(name, body)


caption("c_home", "FOUR TIMERS. ZERO FAFF.")
caption("c_setup", "PICK YOUR POISON")
caption("c_count", "THREE. TWO. ONE…", fs=72)
caption("c_go", "GO. (IT YELLS THIS.)", fs=72)
caption("c_tabata", "WORK. REST. REPEAT.")
caption("c_done", "NEVER LOSES COUNT.")

# ---------------- title card ----------------
render(
    "title_overlay",
    big("WOD", 1750, 340, weight=900, spacing=8)
    + f'<circle cx="{W // 2 + 385}" cy="1750" r="34" fill="{GREEN}"/>'
    + big("THE WHARF WOD TIMER", 1900, 74, fill=DIM, spacing=10)
    + big("THREE. TWO. ONE.", 2130, 96, fill=INK)
    + big("GO.", 2320, 150, fill=GREEN),
)

# ---------------- end card ----------------
render(
    "end_overlay",
    big("FREE.", 1560, 120)
    + big("NO ADS. NO EXCUSES.", 1700, 84, fill=DIM)
    + big("THE WHARF WOD TIMER", 2040, 90, fill=INK)
    + big("App Store — soon", 2150, 62, fill=GREEN)
    + big("mentalmetal.app", 2420, 54, fill=DIM),
)
print("all overlays rendered")
