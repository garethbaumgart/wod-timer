#!/usr/bin/env python3
# Wharf WOD promo: transparent text/graphic overlay PNGs via SVG + rsvg-convert.
# Clone of the Squish/HFD pipeline shape, re-skinned to the app's "Signal"
# design system: deep-ink dark, signal green, heavy condensed caps.
# 2026-07-13 rework: Wharfie (the site mascot) peeks over every caption pill
# with a per-scene expression, the GO moment gets a full-frame slam card, and
# the title/end cards lean on him too — same treatment that made the Squish
# promo land.
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


# ---------------- Wharfie (ported from the mentalmetal.app stage) ----------------
def wharfie(x, y, size, expr="smile", rotate=0, barbell=True, gid=""):
    """The stopwatch mascot, drawn into a `size`-wide box at (x, y).
    expr: smile | yell | starry. Unique gradient ids per instance via gid."""
    s = size / 200.0
    mouth = {
        "smile": '<path d="M86 126 Q101 138 116 124" fill="none" stroke="#14231b" '
                 'stroke-width="7" stroke-linecap="round"/>',
        # joyful war cry: mouth wide open mid-"GO!", eyes bright — never strained
        "yell": '<ellipse cx="101" cy="128" rx="14" ry="16" fill="#14231b"/>'
                '<path d="M92 136 Q101 143 110 136 L110 140 Q101 147 92 140 Z" fill="#e0523f"/>'
                '<path d="M140 70 L150 60 M146 82 L158 76" stroke="#00FF88" stroke-width="6" stroke-linecap="round"/>',
        # finished-the-WOD glow
        "starry": '<path d="M86 124 Q101 140 116 122" fill="none" stroke="#14231b" '
                  'stroke-width="7" stroke-linecap="round"/>'
                  '<path d="M60 74 L64 84 L74 88 L64 92 L60 102 L56 92 L46 88 L56 84 Z" fill="#00FF88"/>',
    }[expr]
    if expr == "yell":
        eyes = ('<circle cx="86" cy="107" r="9" fill="#14231b"/><circle cx="89" cy="104" r="3" fill="#fff"/>'
                '<circle cx="116" cy="107" r="9" fill="#14231b"/><circle cx="119" cy="104" r="3" fill="#fff"/>')
    elif expr == "starry":
        eyes = ('<path d="M86 100 L90 108 L98 112 L90 116 L86 124 L82 116 L74 112 L82 108 Z" fill="#14231b"/>'
                '<path d="M116 100 L120 108 L128 112 L120 116 L116 124 L112 116 L104 112 L112 108 Z" fill="#14231b"/>')
    else:
        eyes = ('<circle cx="86" cy="108" r="9" fill="#14231b"/><circle cx="89" cy="105" r="3" fill="#fff"/>'
                '<circle cx="116" cy="108" r="9" fill="#14231b"/><circle cx="119" cy="105" r="3" fill="#fff"/>')
    bar = ""
    if barbell:
        bar = (
            '<g><rect x="12" y="150" width="176" height="10" rx="5" fill="#cfd8d2" stroke="#0c1410" stroke-width="4"/>'
            f'<rect x="16" y="131" width="26" height="48" rx="8" fill="url(#wwRing{gid})" stroke="#0c1410" stroke-width="5"/>'
            f'<rect x="158" y="131" width="26" height="48" rx="8" fill="url(#wwRing{gid})" stroke="#0c1410" stroke-width="5"/></g>'
        )
    return (
        f'<g transform="translate({x},{y}) scale({s}) rotate({rotate} 100 110)">'
        f'<defs>'
        f'<linearGradient id="wwRing{gid}" x1="0" y1="0" x2="1" y2="1">'
        f'<stop offset="0" stop-color="#3dffa4"/><stop offset="1" stop-color="#00c86a"/></linearGradient>'
        f'<linearGradient id="wwBody{gid}" x1="0" y1="0" x2="0" y2="1">'
        f'<stop offset="0" stop-color="#263b31"/><stop offset="1" stop-color="#121d17"/></linearGradient>'
        f'</defs>'
        + bar +
        f'<rect x="88" y="28" width="24" height="16" rx="5" fill="#263b31" stroke="#0c1410" stroke-width="5"/>'
        f'<rect x="93" y="16" width="14" height="13" rx="4" fill="url(#wwRing{gid})" stroke="#0c1410" stroke-width="4"/>'
        f'<circle cx="100" cy="114" r="70" fill="url(#wwBody{gid})" stroke="#0c1410" stroke-width="7"/>'
        f'<circle cx="100" cy="114" r="56" fill="none" stroke="url(#wwRing{gid})" stroke-width="10" '
        f'stroke-linecap="round" stroke-dasharray="264 88" transform="rotate(-90 100 114)"/>'
        f'<circle cx="100" cy="114" r="42" fill="#f2f7ee"/>'
        + eyes + mouth +
        '</g>'
    )


# ---------------- icon squircle mask ----------------
render(
    "iconmask",
    f'<rect x="0" y="0" width="520" height="520" rx="118" fill="#ffffff"/>',
    w=520,
    h=520,
)

# ---------------- caption pills (Wharfie peeking over the corner) ----------------
def caption(name, text, expr="smile", cy=2280, fs=64):
    est = int(len(text) * fs * 0.58) + 150
    pw = min(max(est, 480), W - 70)
    ph = int(fs * 2.3)
    px = (W - pw) // 2
    py = cy - ph // 2
    baseline = cy + int(fs * 0.34)
    m_size = 190
    body = (
        # green signal tick on the pill's left edge, like the app's strips
        f'<rect x="{px}" y="{py}" width="{pw}" height="{ph}" rx="{ph // 2}" '
        f'fill="#05100a" fill-opacity="0.82" stroke="{GREEN}" stroke-opacity="0.35" stroke-width="3"/>'
        f'<rect x="{px + 34}" y="{cy - fs // 2 - 6}" width="10" height="{fs + 12}" rx="5" fill="{GREEN}"/>'
        + big(text, baseline, fs)
        # Wharfie peeks over the pill's top-left corner, Squish-style
        + wharfie(px - 30, py - m_size + 52, m_size, expr=expr, rotate=-12,
                  barbell=False, gid=name)
    )
    render(name, body)


caption("c_go", "IT YELLS IT LIKE IT MEANS IT.", expr="yell", fs=62)
caption("c_timers", "AMRAP · FOR TIME · EMOM · TABATA", expr="smile", fs=58)
caption("c_setup", "PICK YOUR POISON. START.", expr="smile")
caption("c_tabata", "WORK. REST. IT KEEPS COUNT.", expr="yell", fs=60)
caption("c_done", "GOOD JOB. (IT SAYS THAT TOO.)", expr="starry", fs=58)

# ---- v3: tap-to-count + device-family captions ----
caption("c_rounds", "TAP ANYWHERE. ROUND COUNTED.", expr="smile", fs=60)
caption("c_tablet", "PROP UP A TABLET. WHOLE-GYM CLOCK.", expr="smile", fs=56)
caption("c_watch", "ON YOUR WRIST. SAME COACH.", expr="yell", fs=60)

# Scene headers for the device shots (top of frame, above the footage)
def scene_header(name, text, y=430, fs=88):
    render(name, big(text, y, fs, fill=INK, spacing=3))

scene_header("h_tablet", "AND ON THE BIG SCREEN")
scene_header("h_watch", "AND ON YOUR WRIST")

# ---- v3: device footage masks (rounded corners via alphamerge) ----
# Tablet: 2560x1600 footage scaled to 1160x725 inside the portrait canvas.
render("tablet_mask",
       '<rect x="0" y="0" width="1230" height="769" rx="44" fill="#ffffff"/>',
       w=1230, h=769)
# Watch: 416x496 footage scaled x2.30 -> 957x1141; watch squircle corners.
render("watch_mask",
       '<rect x="0" y="0" width="957" height="1141" rx="240" fill="#ffffff"/>',
       w=957, h=1141)

# ---------------- GO slam ----------------
# Full-frame overlay for the WORK flip: mega GO. dropped over the live footage
# the exact frame the coach yells it.
render(
    "go_slam",
    f'<text x="{W // 2}" y="1990" text-anchor="middle" font-family="{SANS}" '
    f'font-size="560" font-weight="900" letter-spacing="-8" fill="{GREEN}" '
    f'stroke="#04140b" stroke-width="22" paint-order="stroke">GO.</text>',
)

# ---------------- title card ----------------
render(
    "title_overlay",
    wharfie(W // 2 - 170, 620, 340, expr="smile", barbell=True, gid="title")
    + big("THE WHARF", 1720, 170, weight=900, spacing=2)
    + big("WOD TIMER", 1930, 170, weight=900, spacing=2)
    + f'<rect x="{W // 2 - 260}" y="2120" width="520" height="108" rx="54" '
    f'fill="none" stroke="{GREEN}" stroke-width="5"/>'
    + big("SOUND ON.", 2190, 56, fill=GREEN, spacing=8),
)

# ---------------- end card ----------------
render(
    "end_overlay",
    wharfie(W // 2 - 210, 1060, 420, expr="starry", barbell=True, gid="end")
    + big("THE WHARF WOD TIMER", 1780, 96, fill=INK)
    + big("FREE. NO ADS. NO EXCUSES.", 1930, 72, fill=DIM)
    + big("mentalmetal.app", 2220, 64, fill=GREEN, spacing=4),
)
print("all overlays rendered")
