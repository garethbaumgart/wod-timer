#!/usr/bin/env python3
# The Wharf WOD Timer — landscape kinetic explainer (Churnie format, no VO).
# 1920x1080, ~36s. Frame-by-frame SVG -> rsvg-convert PNG. Big animated type,
# Wharfie riding, ticker strips, hard cuts on the beat, and REAL app screenshots
# in premium device mockups (Watch Ultra, iPhone, iPad). Sound = phonk-gym bed
# + the app's own GO / 3-2-1 / complete cues (see build_explainer.sh).
import base64
import html
import math
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SMALL = os.path.join(HERE, "work_gym", "small")
FRAMES = os.path.join(HERE, "frames_ex")
os.makedirs(FRAMES, exist_ok=True)

W, H, FPS = 1920, 1080, 30
INK = "#F2F7EE"
GREEN = "#00FF88"
GDIM = "#00c86a"
BLUE = "#3aa0ff"
DIM = "#7f8a82"
ORANGE = "#f0662a"
FONT = "Helvetica,Arial,sans-serif"

SCENES = [("hook", 4.6), ("nah", 1.8), ("yell", 3.4), ("modes", 9.6),
          ("glance", 4.4), ("trio", 6.3), ("cta", 6.0)]
TOTAL = sum(d for _, d in SCENES)

_IMG = {}
def img(key):
    if key not in _IMG:
        with open(os.path.join(SMALL, key + ".png"), "rb") as f:
            _IMG[key] = "data:image/png;base64," + base64.b64encode(f.read()).decode()
    return _IMG[key]


def esc(s):
    return html.escape(str(s))


def clamp01(x):
    return 0.0 if x < 0 else (1.0 if x > 1 else x)


def eo(t):            # ease-out cubic
    return 1 - (1 - clamp01(t)) ** 3


def eob(t, s=1.9):    # ease-out back (overshoot pop)
    t = clamp01(t) - 1
    return 1 + (s + 1) * t ** 3 + s * t ** 2


def appear(t, t0, dur=0.5):
    return eo((t - t0) / dur)


def T(x, y, size, s, fill=INK, w=900, ls=1, anchor="middle", op=1.0, font=FONT):
    return (f'<text x="{x:.1f}" y="{y:.1f}" text-anchor="{anchor}" font-family="{font}" '
            f'font-size="{size:.1f}" font-weight="{w}" letter-spacing="{ls}" fill="{fill}" '
            f'fill-opacity="{op:.3f}">{esc(s)}</text>')


def line_in(x, y, size, s, t, t0, fill=INK, anchor="middle", dy=46, ls=1, w=900):
    p = appear(t, t0, 0.5)
    return T(x, y + dy * (1 - p), size, s, fill=fill, w=w, ls=ls, anchor=anchor, op=p)


def pop(body_fn, t, t0, cx, cy, dur=0.5):
    p = clamp01((t - t0) / dur)
    if p <= 0:
        return ""
    sc = eob(p)
    op = eo(min(1.0, p * 1.6))
    return (f'<g transform="translate({cx:.1f} {cy:.1f}) scale({sc:.3f}) translate({-cx:.1f} {-cy:.1f})" '
            f'opacity="{op:.3f}">{body_fn}</g>')


def ticker(text, y, t, color=GREEN, speed=150, size=26, op=0.42):
    unit = (text + "  ")
    per = len(unit) * size * 0.60
    off = -((t * speed) % per)
    reps = int(W / per) + 3
    run = unit * reps
    return (f'<g opacity="{op}"><rect x="0" y="{y-size*0.9:.0f}" width="{W}" height="{size*1.5:.0f}" fill="#0b1710"/>'
            f'<text x="{off:.1f}" y="{y:.1f}" font-family="{FONT}" font-size="{size}" font-weight="900" '
            f'letter-spacing="2" fill="{color}">{esc(run)}</text></g>')


# ---------------- Wharfie ----------------
def wharfie(cx, cy, size, t, expr="smile", body_dark=False, bob=6.0):
    s = size / 200.0
    y = cy + bob * math.sin(t * 3.1)
    ink = "#04140b" if body_dark else "#0c1410"
    face = "#f2f7ee"
    if expr == "yell":
        eyes = ('<circle cx="86" cy="107" r="9" fill="#14231b"/><circle cx="89" cy="104" r="3" fill="#fff"/>'
                '<circle cx="116" cy="107" r="9" fill="#14231b"/><circle cx="119" cy="104" r="3" fill="#fff"/>')
        mouth = '<ellipse cx="101" cy="128" rx="14" ry="16" fill="#14231b"/><path d="M92 136 Q101 143 110 136 L110 140 Q101 147 92 140 Z" fill="#e0523f"/>'
    elif expr == "starry":
        eyes = ('<path d="M86 100 L90 108 L98 112 L90 116 L86 124 L82 116 L74 112 L82 108 Z" fill="#14231b"/>'
                '<path d="M116 100 L120 108 L128 112 L120 116 L116 124 L112 116 L104 112 L112 108 Z" fill="#14231b"/>')
        mouth = '<path d="M86 124 Q101 140 116 122" fill="none" stroke="#14231b" stroke-width="7" stroke-linecap="round"/>'
    else:
        eyes = ('<circle cx="86" cy="108" r="9" fill="#14231b"/><circle cx="89" cy="105" r="3" fill="#fff"/>'
                '<circle cx="116" cy="108" r="9" fill="#14231b"/><circle cx="119" cy="105" r="3" fill="#fff"/>')
        mouth = '<path d="M86 126 Q101 138 116 124" fill="none" stroke="#14231b" stroke-width="7" stroke-linecap="round"/>'
    gid = f"{int(cx)}_{int(cy)}"
    return (f'<g transform="translate({cx - size/2:.1f},{y - size/2:.1f}) scale({s:.3f})">'
            f'<defs><linearGradient id="wr{gid}" x1="0" y1="0" x2="1" y2="1">'
            f'<stop offset="0" stop-color="#3dffa4"/><stop offset="1" stop-color="#00c86a"/></linearGradient>'
            f'<linearGradient id="wb{gid}" x1="0" y1="0" x2="0" y2="1">'
            f'<stop offset="0" stop-color="#263b31"/><stop offset="1" stop-color="#121d17"/></linearGradient></defs>'
            f'<rect x="88" y="28" width="24" height="16" rx="5" fill="#263b31" stroke="{ink}" stroke-width="5"/>'
            f'<rect x="93" y="16" width="14" height="13" rx="4" fill="url(#wr{gid})" stroke="{ink}" stroke-width="4"/>'
            f'<circle cx="100" cy="114" r="70" fill="url(#wb{gid})" stroke="{ink}" stroke-width="7"/>'
            f'<circle cx="100" cy="114" r="56" fill="none" stroke="url(#wr{gid})" stroke-width="10" '
            f'stroke-linecap="round" stroke-dasharray="264 88" transform="rotate(-90 100 114)"/>'
            f'<circle cx="100" cy="114" r="42" fill="{face}"/>' + eyes + mouth + '</g>')


# ---------------- device mockups (small imgs) ----------------
def _shadow(cx, cy, rx, ry):
    return f'<ellipse cx="{cx:.0f}" cy="{cy:.0f}" rx="{rx:.0f}" ry="{ry:.0f}" fill="#000" opacity="0.5"/>'


def phone(cx, cy, sw, imgkey, gid):
    ar = 1320 / 2868
    sh = sw / ar
    bez = sw * 0.055
    ow, oh = sw + bez * 2, sh + bez * 2
    ox, oy = cx - ow / 2, cy - oh / 2
    r = ow * 0.23
    sid = "ph" + gid
    glow = f'<ellipse cx="{cx:.0f}" cy="{cy:.0f}" rx="{ow*0.72:.0f}" ry="{oh*0.55:.0f}" fill="{GREEN}" opacity="0.10"/>'
    body = (f'<rect x="{ox:.1f}" y="{oy:.1f}" width="{ow:.1f}" height="{oh:.1f}" rx="{r:.1f}" fill="#1b1e25" stroke="#000" stroke-width="2"/>'
            f'<rect x="{ox+2:.1f}" y="{oy+2:.1f}" width="{ow-4:.1f}" height="{oh-4:.1f}" rx="{r-2:.1f}" fill="none" stroke="#42474f" stroke-width="1.6"/>')
    clip = f'<clipPath id="{sid}"><rect x="{ox+bez:.1f}" y="{oy+bez:.1f}" width="{sw:.1f}" height="{sh:.1f}" rx="{r-bez:.1f}"/></clipPath>'
    im = f'<image href="{img(imgkey)}" x="{ox+bez:.1f}" y="{oy+bez:.1f}" width="{sw:.1f}" height="{sh:.1f}" preserveAspectRatio="xMidYMid slice" clip-path="url(#{sid})"/>'
    island = f'<rect x="{cx-sw*0.13:.1f}" y="{oy+bez+sw*0.04:.1f}" width="{sw*0.26:.1f}" height="{sw*0.075:.1f}" rx="{sw*0.037:.1f}" fill="#05050a"/>'
    return f'{glow}<defs>{clip}</defs>{body}{im}{island}'


def watch_ultra(cx, cy, sw, imgkey, gid):
    ar = 416 / 496
    sh = sw / ar
    bez = sw * 0.10
    ow, oh = sw + bez * 2, sh + bez * 2
    ox, oy = cx - ow / 2, cy - oh / 2
    cr = ow * 0.235
    sid = "wu" + gid
    bw = ow * 0.72
    band = (f'<rect x="{cx-bw/2:.1f}" y="{oy-oh*0.55:.1f}" width="{bw:.1f}" height="{oh*0.62:.1f}" rx="24" fill="#182720"/>'
            f'<rect x="{cx-bw/2:.1f}" y="{oy+oh-oh*0.06:.1f}" width="{bw:.1f}" height="{oh*0.62:.1f}" rx="24" fill="#182720"/>')
    action = f'<rect x="{ox-ow*0.055:.1f}" y="{oy+oh*0.42:.1f}" width="{ow*0.06:.1f}" height="{oh*0.20:.1f}" rx="5" fill="{ORANGE}" stroke="#a8481d" stroke-width="1.4"/>'
    guard = f'<rect x="{ox+ow-6:.1f}" y="{oy+oh*0.30:.1f}" width="{ow*0.075:.1f}" height="{oh*0.40:.1f}" rx="9" fill="#b7bbbd" stroke="#7d8183" stroke-width="1.4"/>'
    crown = (f'<rect x="{ox+ow+ow*0.02:.1f}" y="{oy+oh*0.37:.1f}" width="{ow*0.05:.1f}" height="{oh*0.14:.1f}" rx="5" fill="#b7bbbd" stroke="#6d7173" stroke-width="1.4"/>'
             f'<rect x="{ox+ow+ow*0.02:.1f}" y="{oy+oh*0.37:.1f}" width="{ow*0.05:.1f}" height="{oh*0.14:.1f}" rx="5" fill="none" stroke="{ORANGE}" stroke-width="1.6"/>')
    case = (f'<rect x="{ox:.1f}" y="{oy:.1f}" width="{ow:.1f}" height="{oh:.1f}" rx="{cr:.1f}" fill="#cfd2d3" stroke="#7d8183" stroke-width="2"/>'
            f'<rect x="{ox+3:.1f}" y="{oy+3:.1f}" width="{ow-6:.1f}" height="{oh-6:.1f}" rx="{cr-3:.1f}" fill="none" stroke="#ffffff" stroke-opacity="0.55" stroke-width="1.4"/>')
    dz = bez * 0.55
    screenbez = f'<rect x="{ox+dz:.1f}" y="{oy+dz:.1f}" width="{ow-dz*2:.1f}" height="{oh-dz*2:.1f}" rx="{cr-dz:.1f}" fill="#000"/>'
    inx, iny = ox + dz + sw * 0.04, oy + dz + sw * 0.04
    inw, inh = ow - dz * 2 - sw * 0.08, oh - dz * 2 - sw * 0.08
    clip = f'<clipPath id="{sid}"><rect x="{inx:.1f}" y="{iny:.1f}" width="{inw:.1f}" height="{inh:.1f}" rx="{cr-dz-6:.1f}"/></clipPath>'
    im = f'<image href="{img(imgkey)}" x="{inx:.1f}" y="{iny:.1f}" width="{inw:.1f}" height="{inh:.1f}" preserveAspectRatio="xMidYMid slice" clip-path="url(#{sid})"/>'
    glow = f'<ellipse cx="{cx:.0f}" cy="{cy:.0f}" rx="{ow*0.95:.0f}" ry="{oh*0.75:.0f}" fill="{GREEN}" opacity="0.15"/>'
    return f'{glow}{band}{action}{guard}{crown}{case}{screenbez}<defs>{clip}</defs>{im}'


def ipad(cx, cy, sw, imgkey, gid):
    ar = 2560 / 1600
    sh = sw / ar
    bez = sw * 0.028
    ow, oh = sw + bez * 2, sh + bez * 2
    ox, oy = cx - ow / 2, cy - oh / 2
    r = ow * 0.045
    sid = "ip" + gid
    glow = f'<ellipse cx="{cx:.0f}" cy="{cy:.0f}" rx="{ow*0.6:.0f}" ry="{oh*0.6:.0f}" fill="{GREEN}" opacity="0.09"/>'
    body = (f'<rect x="{ox:.1f}" y="{oy:.1f}" width="{ow:.1f}" height="{oh:.1f}" rx="{r:.1f}" fill="#1b1e24" stroke="#000" stroke-width="2"/>'
            f'<rect x="{ox+2:.1f}" y="{oy+2:.1f}" width="{ow-4:.1f}" height="{oh-4:.1f}" rx="{r-2:.1f}" fill="none" stroke="#3a3f47" stroke-width="1.6"/>')
    clip = f'<clipPath id="{sid}"><rect x="{ox+bez:.1f}" y="{oy+bez:.1f}" width="{sw:.1f}" height="{sh:.1f}" rx="{r*0.5:.1f}"/></clipPath>'
    im = f'<image href="{img(imgkey)}" x="{ox+bez:.1f}" y="{oy+bez:.1f}" width="{sw:.1f}" height="{sh:.1f}" preserveAspectRatio="xMidYMid slice" clip-path="url(#{sid})"/>'
    return f'{glow}<defs>{clip}</defs>{body}{im}'


def anim(body, t, t0, cx, cy, dur=0.55, dy=54):
    p = clamp01((t - t0) / dur)
    if p <= 0:
        return ""
    sc = eob(p)
    op = eo(min(1.0, p * 1.7))
    yo = dy * (1 - eo(p))
    return (f'<g opacity="{op:.3f}" transform="translate({cx:.1f} {cy+yo:.1f}) scale({sc:.3f}) '
            f'translate({-cx:.1f} {-cy:.1f})">{body}</g>')


BG = f'<rect width="{W}" height="{H}" fill="#080b12"/>'
VIG = f'<rect width="{W}" height="{H}" fill="url(#vg)"/>'
DEFS = (f'<defs><radialGradient id="vg" cx="0.5" cy="0.46" r="0.75">'
        f'<stop offset="0.6" stop-color="#000" stop-opacity="0"/>'
        f'<stop offset="1" stop-color="#000" stop-opacity="0.5"/></radialGradient></defs>')


# ---------------- scenes ----------------
def sc_hook(t, d):
    b = [BG, DEFS, ticker("TICK · TICK · TICK · TICK ·", 44, t),
         ticker("3 · 2 · 1 ·  3 · 2 · 1 ·", H - 30, t, speed=120)]
    b.append(line_in(150, 430, 118, "MID-WOD.", t, 0.15, anchor="start"))
    b.append(line_in(150, 560, 118, "GASPING.", t, 0.45, anchor="start"))
    b.append(line_in(150, 700, 66, "AND YOU'RE DOING MATHS?", t, 0.85, fill=GREEN, anchor="start"))
    b.append(wharfie(1560, 720, 300, t, expr="smile"))
    b.append(VIG)
    return "".join(b)


def sc_nah(t, d):
    b = [f'<rect width="{W}" height="{H}" fill="{GREEN}"/>']
    b.append(pop(T(W/2, H/2 + 90, 300, "NAH.", fill="#04140b", ls=-2), t, 0.05, W/2, H/2))
    b.append(wharfie(1640, 250, 200, t, expr="smile", body_dark=True))
    return "".join(b)


def sc_yell(t, d):
    b = [BG, DEFS, ticker("GO · GO · GO · GO · GO ·", H - 30, t, speed=200)]
    b.append(line_in(150, 400, 100, "IT YELLS IT", t, 0.1, anchor="start"))
    b.append(line_in(150, 520, 100, "LIKE IT MEANS IT.", t, 0.4, anchor="start"))
    go = f'<g transform="rotate(-8 1480 640)"><rect x="1330" y="560" width="300" height="170" rx="14" fill="{GREEN}"/><text x="1480" y="690" text-anchor="middle" font-family="{FONT}" font-size="130" font-weight="900" fill="#04140b">GO!</text></g>'
    b.append(pop(go, t, 1.15, 1480, 640, dur=0.4))
    b.append(wharfie(300, 830, 210, t, expr="yell"))
    b.append(VIG)
    return "".join(b)


def sc_modes(t, d):
    b = [BG, DEFS, ticker("AMRAP · FOR TIME · EMOM · TABATA ·", H - 28, t, speed=130, op=0.34)]
    b.append(line_in(W/2, 118, 60, "PICK YOUR POISON.", t, 0.1))
    modes = [("01", "AMRAP", "mode_amrap"), ("02", "FOR TIME", "mode_fortime"),
             ("03", "EMOM", "mode_emom"), ("04", "TABATA", "mode_tabata")]
    centers = [366, 758, 1150, 1542]
    for i, ((num, name, key), cx) in enumerate(zip(modes, centers)):
        t0 = 0.9 + i * 0.75
        b.append(anim(phone(cx, 500, 250, key, f"m{i}"), t, t0, cx, 500))
        p = appear(t, t0 + 0.2, 0.4)
        if p > 0:
            b.append(f'<text x="{cx}" y="905" text-anchor="middle" font-family="{FONT}" font-size="36" '
                     f'font-weight="900" letter-spacing="1" fill-opacity="{p:.2f}">'
                     f'<tspan fill="{GREEN}">{num} </tspan><tspan fill="{INK}">{name}</tspan></text>')
    return "".join(b)


def sc_glance(t, d):
    b = [BG, DEFS]
    pw = appear(t, 0.15, 0.5)
    pr = appear(t, 0.45, 0.5)
    b.append(f'<g opacity="{pw:.2f}"><rect x="150" y="330" width="360" height="150" rx="12" fill="{GREEN}" fill-opacity="0.16"/>'
             f'<text x="185" y="435" font-family="{FONT}" font-size="86" font-weight="900" fill="{GREEN}">WORK</text></g>')
    b.append(f'<g opacity="{pr:.2f}"><rect x="150" y="510" width="360" height="150" rx="12" fill="{BLUE}" fill-opacity="0.16"/>'
             f'<text x="185" y="615" font-family="{FONT}" font-size="86" font-weight="900" fill="{BLUE}">REST</text></g>')
    b.append(line_in(600, 430, 56, "THE SCREEN SHOUTS", t, 0.8, anchor="start"))
    b.append(line_in(600, 500, 56, "THE COLOUR.", t, 1.0, anchor="start"))
    b.append(line_in(600, 600, 40, "SO YOU NEVER LOOK DOWN.", t, 1.3, fill=GREEN, anchor="start"))
    b.append(anim(phone(1560, 520, 250, "mode_tabata", "g0"), t, 1.4, 1560, 520))
    b.append(VIG)
    return "".join(b)


def sc_trio(t, d):
    b = [BG, DEFS, f'<ellipse cx="960" cy="470" rx="820" ry="420" fill="{GREEN}" opacity="0.07"/>']
    b.append(anim(ipad(540, 470, 640, "tablet_hero", "t0"), t, 0.2, 540, 470, dur=0.6, dy=0))
    b.append(anim(phone(1070, 540, 300, "phone_hero", "t1"), t, 0.55, 1070, 540, dur=0.6))
    b.append(anim(watch_ultra(1500, 520, 250, "watch_hero", "t2"), t, 0.9, 1500, 520, dur=0.6))
    b.append(line_in(W/2, 940, 52, "ONE APP.  EVERY SCREEN.", t, 1.5))
    return "".join(b)


def sc_cta(t, d):
    b = [BG, DEFS, ticker("TIME'S TICKING · CHIN UP · TIME'S TICKING ·", H - 28, t, speed=140)]
    b.append(pop(wharfie(W/2, 360, 300, t, expr="starry"), t, 0.1, W/2, 360, dur=0.5))
    b.append(line_in(W/2, 640, 74, "FREE. NO ADS. NO EXCUSES.", t, 0.55))
    b.append(line_in(W/2, 760, 38, "THE WHARF WOD TIMER", t, 0.8, fill=DIM))
    fade = appear(t, 1.1, 0.5)
    b.append(f'<g opacity="{fade:.2f}"><rect x="{W/2-260:.0f}" y="820" width="520" height="86" rx="43" fill="none" stroke="{GREEN}" stroke-width="4"/>'
             f'<text x="{W/2}" y="878" text-anchor="middle" font-family="{FONT}" font-size="46" font-weight="900" letter-spacing="4" fill="{GREEN}">mentalmetal.app</text></g>')
    return "".join(b)


RENDER = {"hook": sc_hook, "nah": sc_nah, "yell": sc_yell, "modes": sc_modes,
          "glance": sc_glance, "trio": sc_trio, "cta": sc_cta}


def scene_at(gt):
    acc = 0.0
    for name, dur in SCENES:
        if gt < acc + dur or name == SCENES[-1][0]:
            return name, dur, gt - acc
        acc += dur
    return SCENES[-1][0], SCENES[-1][1], gt - (TOTAL - SCENES[-1][1])


def render_frame(fi, gt):
    name, dur, lt = scene_at(gt)
    body = RENDER[name](lt, dur)
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{body}</svg>'
    sp = os.path.join(FRAMES, f"{fi:05d}.svg")
    with open(sp, "w") as f:
        f.write(svg)
    subprocess.run(["rsvg-convert", sp, "-o", os.path.join(FRAMES, f"{fi:05d}.png")], check=True)
    os.remove(sp)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "probe":
        # render one representative frame per scene for review
        acc = 0.0
        for name, dur in SCENES:
            gt = acc + dur * 0.6
            fi = int(gt * FPS)
            render_frame(fi, gt)
            print(f"probe {name} -> {fi:05d}.png")
            acc += dur
        sys.exit(0)
    nframes = int(TOTAL * FPS)
    print(f"rendering {nframes} frames ({TOTAL:.1f}s)")
    for fi in range(nframes):
        render_frame(fi, fi / FPS)
        if fi % 60 == 0:
            print(f"  {fi}/{nframes}")
    print("frames done")
