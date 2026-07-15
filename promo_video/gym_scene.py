#!/usr/bin/env python3
# The Wharf WOD Timer promo — "in the gym" stylized scenes.
# Pure product (no people), on-brand "Signal" look: deep-ink dark, signal green
# rim light, CrossFit gear as clean geometry. Real app footage composited into
# framed hardware staged on gym equipment. Vertical 1290x2796 (App Store/social).
# SVG -> rsvg-convert PNG. Footage frames embedded as base64 data URIs.
import base64
import html
import os
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
GYM = os.path.join(HERE, "work_gym")
os.makedirs(GYM, exist_ok=True)

W, H = 1290, 2796
INK = "#F2F7EE"
GREEN = "#00FF88"
GREEN_DIM = "#00c86a"
DIM = "#8b968d"
SANS = "'Helvetica Neue', Helvetica, Arial, sans-serif"


def data_uri(path):
    with open(path, "rb") as f:
        b = base64.b64encode(f.read()).decode()
    ext = "jpeg" if path.lower().endswith((".jpg", ".jpeg")) else "png"
    return f"data:image/{ext};base64,{b}"


def esc(t):
    return html.escape(t)


# ---------------- Wharfie mascot (ported from mktext.py) ----------------
def wharfie(x, y, size, expr="smile", rotate=0, barbell=False, gid=""):
    s = size / 200.0
    mouth = {
        "smile": '<path d="M86 126 Q101 138 116 124" fill="none" stroke="#14231b" '
                 'stroke-width="7" stroke-linecap="round"/>',
        "yell": '<ellipse cx="101" cy="128" rx="14" ry="16" fill="#14231b"/>'
                '<path d="M92 136 Q101 143 110 136 L110 140 Q101 147 92 140 Z" fill="#e0523f"/>',
        "starry": '<path d="M86 124 Q101 140 116 122" fill="none" stroke="#14231b" '
                  'stroke-width="7" stroke-linecap="round"/>',
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
    return (
        f'<g transform="translate({x},{y}) scale({s}) rotate({rotate} 100 110)">'
        f'<defs><linearGradient id="wwR{gid}" x1="0" y1="0" x2="1" y2="1">'
        f'<stop offset="0" stop-color="#3dffa4"/><stop offset="1" stop-color="#00c86a"/></linearGradient>'
        f'<linearGradient id="wwB{gid}" x1="0" y1="0" x2="0" y2="1">'
        f'<stop offset="0" stop-color="#263b31"/><stop offset="1" stop-color="#121d17"/></linearGradient></defs>'
        f'<rect x="88" y="28" width="24" height="16" rx="5" fill="#263b31" stroke="#0c1410" stroke-width="5"/>'
        f'<rect x="93" y="16" width="14" height="13" rx="4" fill="url(#wwR{gid})" stroke="#0c1410" stroke-width="4"/>'
        f'<circle cx="100" cy="114" r="70" fill="url(#wwB{gid})" stroke="#0c1410" stroke-width="7"/>'
        f'<circle cx="100" cy="114" r="56" fill="none" stroke="url(#wwR{gid})" stroke-width="10" '
        f'stroke-linecap="round" stroke-dasharray="264 88" transform="rotate(-90 100 114)"/>'
        f'<circle cx="100" cy="114" r="42" fill="#f2f7ee"/>' + eyes + mouth + '</g>'
    )


def big(text, x, y, fs, fill=INK, weight=900, spacing=2, anchor="middle"):
    return (f'<text x="{x}" y="{y}" text-anchor="{anchor}" font-family="{SANS}" '
            f'font-size="{fs}" font-weight="{weight}" letter-spacing="{spacing}" '
            f'fill="{fill}">{esc(text)}</text>')


# ---------------- shared gym environment ----------------
def defs():
    return f'''<defs>
      <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#080b12"/><stop offset="0.55" stop-color="#0a0e17"/>
        <stop offset="1" stop-color="#05070c"/></linearGradient>
      <radialGradient id="pool" cx="0.5" cy="0.5" r="0.5">
        <stop offset="0" stop-color="{GREEN}" stop-opacity="0.30"/>
        <stop offset="0.55" stop-color="{GREEN}" stop-opacity="0.08"/>
        <stop offset="1" stop-color="{GREEN}" stop-opacity="0"/></radialGradient>
      <radialGradient id="vig" cx="0.5" cy="0.46" r="0.8">
        <stop offset="0.58" stop-color="#000000" stop-opacity="0"/>
        <stop offset="1" stop-color="#000000" stop-opacity="0.46"/></radialGradient>
      <linearGradient id="metal" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#2b313d"/><stop offset="1" stop-color="#141821"/></linearGradient>
      <linearGradient id="boxtop" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#20252f"/><stop offset="1" stop-color="#171b23"/></linearGradient>
      <linearGradient id="boxfront" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#12151c"/><stop offset="1" stop-color="#0b0d13"/></linearGradient>
      <filter id="soft" x="-40%" y="-40%" width="180%" height="180%">
        <feGaussianBlur stdDeviation="18"/></filter>
      <filter id="soft2" x="-60%" y="-60%" width="220%" height="220%">
        <feGaussianBlur stdDeviation="42"/></filter>
    </defs>'''


def rings(bar_y, ring_y):
    # gymnastic rings hanging on straps from the rig bar (fills upper frame)
    out = ""
    for x in (452, 838):
        out += (f'<rect x="{x-7}" y="{bar_y}" width="14" height="{ring_y-bar_y-40}" fill="#181c24" '
                f'stroke="{GREEN_DIM}" stroke-opacity="0.16" stroke-width="1.5"/>'
                f'<circle cx="{x}" cy="{ring_y}" r="52" fill="none" stroke="#2a2015" stroke-width="17"/>'
                f'<circle cx="{x}" cy="{ring_y}" r="52" fill="none" stroke="{GREEN}" stroke-opacity="0.20" stroke-width="3"/>'
                f'<path d="M{x-52} {ring_y} A52 52 0 0 1 {x} {ring_y-52}" fill="none" stroke="#4a3722" stroke-width="6"/>')
    return f'<g opacity="0.9">{out}</g>'


def back_wall():
    # pull-up rig + hanging rings + faint WHARF sign
    horizon = 1150
    rig_c = "#10141c"
    rim = f'stroke="{GREEN_DIM}" stroke-opacity="0.20" stroke-width="3"'
    bar_y = 470
    posts = ""
    for px in (150, 470, 820, 1140):
        posts += f'<rect x="{px}" y="300" width="26" height="{horizon-300}" fill="{rig_c}" {rim}/>'
    bars = f'<rect x="150" y="{bar_y}" width="1016" height="20" fill="{rig_c}" {rim}/>'
    bars += f'<rect x="150" y="{bar_y+180}" width="1016" height="16" fill="{rig_c}" {rim}/>'
    sign = big("WHARF", W // 2, 240, 118, fill=GREEN, weight=900, spacing=18)
    sign = f'<g opacity="0.13">{sign}</g>'
    return (f'<g>{sign}{posts}{bars}{rings(bar_y+20, 900)}'
            f'<line x1="0" y1="{horizon}" x2="{W}" y2="{horizon}" stroke="#0d111a" stroke-width="4"/></g>')


def floor_pool(cx, cy):
    # green light pool grounding the hero, plus a soft floor tone
    return (f'<rect x="0" y="1360" width="{W}" height="{H-1360}" fill="#070a11"/>'
            f'<ellipse cx="{cx}" cy="{cy}" rx="720" ry="360" fill="url(#pool)"/>')


def barbell(y, cx=W // 2):
    # olympic bar with bumper plates lying flat on the floor (foreground)
    bar = f'<rect x="{cx-560}" y="{y-9}" width="1120" height="18" rx="9" fill="url(#metal)" stroke="#000" stroke-width="2"/>'
    bar += f'<rect x="{cx-560}" y="{y-11}" width="1120" height="4" rx="2" fill="{GREEN}" opacity="0.16"/>'
    plates = ""
    for side in (-1, 1):
        for i, (rx, ry, col) in enumerate([(44, 172, "#171b22"), (36, 146, "#12161c")]):
            ox = cx + side * (392 + i * 62)
            plates += (f'<ellipse cx="{ox}" cy="{y}" rx="{rx}" ry="{ry}" fill="{col}" '
                       f'stroke="#000" stroke-width="3"/>'
                       f'<path d="M{ox-rx*0.5} {y-ry*0.86} A{rx} {ry} 0 0 1 {ox+rx} {y-ry*0.2}" '
                       f'fill="none" stroke="{GREEN}" stroke-opacity="0.45" stroke-width="4"/>')
    return f'<g>{bar}{plates}</g>'


def kettlebell(cx, cy, s=1.0):
    r = 78 * s
    body = f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#metal)" stroke="#000" stroke-width="3"/>'
    body += f'<path d="M{cx-r*0.6} {cy-r*0.7} q0 -{r*0.9} {r*0.6} -{r*0.9} q{r*0.6} 0 {r*0.6} {r*0.9}" fill="none" stroke="#20262f" stroke-width="{22*s}"/>'
    rim = (f'<path d="M{cx-r*0.72} {cy-r*0.55} A{r} {r} 0 0 1 {cx+r*0.2} {cy-r}" '
           f'fill="none" stroke="{GREEN}" stroke-opacity="0.4" stroke-width="3"/>')
    return f'<g opacity="0.95">{body}{rim}</g>'


def plyo_box(cx, top_y, tw, depth=118, faceh=300):
    # simple 3D box: top parallelogram + front + right side, dark, green rim on top edge
    half = tw // 2
    tl, tr = cx - half, cx + half
    # top face (parallelogram receding up-right)
    top = (f'<polygon points="{tl},{top_y} {tr},{top_y} {tr+depth},{top_y-depth*0.5} {tl+depth},{top_y-depth*0.5}" '
           f'fill="url(#boxtop)" stroke="#000" stroke-width="2"/>')
    front = f'<rect x="{tl}" y="{top_y}" width="{tw}" height="{faceh}" fill="url(#boxfront)" stroke="#000" stroke-width="2"/>'
    side = (f'<polygon points="{tr},{top_y} {tr+depth},{top_y-depth*0.5} {tr+depth},{top_y-depth*0.5+faceh} {tr},{top_y+faceh}" '
            f'fill="#0a0c12" stroke="#000" stroke-width="2"/>')
    # green rim light on the top front edge
    rim = f'<line x1="{tl}" y1="{top_y}" x2="{tr}" y2="{top_y}" stroke="{GREEN}" stroke-opacity="0.5" stroke-width="3"/>'
    # cutout handle hint on the front
    handle = f'<rect x="{cx-70}" y="{top_y+faceh*0.42}" width="140" height="30" rx="15" fill="#05070b"/>'
    return f'<g>{top}{side}{front}{rim}{handle}</g>'


def framed_ipad(cx, base_y, screen_w, footage, tilt=-3):
    # landscape iPad standing on a surface, leaning back slightly. Screen shows footage.
    ar = 2560 / 1600  # landscape footage aspect
    sw = screen_w
    sh = int(sw / ar)
    bez = 26
    ow, oh = sw + bez * 2, sh + bez * 2
    ox, oy = cx - ow // 2, base_y - oh
    sid = "ipadscr"
    uri = data_uri(footage)
    glow = (f'<ellipse cx="{cx}" cy="{oy+oh//2}" rx="{ow*0.62}" ry="{oh*0.62}" '
            f'fill="{GREEN}" opacity="0.16" filter="url(#soft2)"/>')
    body = (f'<rect x="{ox}" y="{oy}" width="{ow}" height="{oh}" rx="34" fill="#23272f" stroke="#000" stroke-width="3"/>'
            f'<rect x="{ox+2}" y="{oy+2}" width="{ow-4}" height="{oh//2}" rx="32" fill="#ffffff" opacity="0.04"/>')
    clip = f'<clipPath id="{sid}"><rect x="{ox+bez}" y="{oy+bez}" width="{sw}" height="{sh}" rx="8"/></clipPath>'
    img = (f'<image href="{uri}" x="{ox+bez}" y="{oy+bez}" width="{sw}" height="{sh}" '
           f'preserveAspectRatio="xMidYMid slice" clip-path="url(#{sid})"/>')
    screenrim = f'<rect x="{ox+bez}" y="{oy+bez}" width="{sw}" height="{sh}" rx="8" fill="none" stroke="{GREEN}" stroke-opacity="0.28" stroke-width="2"/>'
    # camera dot
    cam = f'<circle cx="{cx}" cy="{oy+13}" r="4" fill="#12151b"/>'
    # floor reflection of the green glow
    refl = f'<ellipse cx="{cx}" cy="{base_y+70}" rx="{sw*0.42}" ry="46" fill="{GREEN}" opacity="0.12" filter="url(#soft)"/>'
    inner = f'<defs>{clip}</defs>{glow}{body}{cam}{img}{screenrim}'
    return (f'{refl}<g transform="rotate({tilt} {cx} {base_y})">{inner}</g>')


def plate_stack(cx, top_y, n=3, rx=320, ry=72, gap=46):
    # stacked flat bumper plates = pedestal (top plate brightest, lit from device)
    out = ""
    for i in range(n - 1, -1, -1):  # draw back(top) to front(bottom)? bottom-up for overlap
        cy = top_y + i * gap
        edge = 0.5 if i == 0 else 0.22
        face = "#1a1f28" if i == 0 else "#12161d"
        out += (f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{face}" stroke="#000" stroke-width="3"/>'
                f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="none" stroke="{GREEN}" stroke-opacity="{edge}" stroke-width="2.5"/>'
                f'<ellipse cx="{cx}" cy="{cy}" rx="{rx*0.28}" ry="{ry*0.28}" fill="#080b10"/>')
    return f'<g>{out}</g>'


def framed_watch(cx, base_y, screen_w, footage, tilt=-6):
    ar = 416 / 496  # portrait watch footage
    sw = screen_w
    sh = int(sw / ar)
    bez = 42
    ow, oh = sw + bez * 2, sh + bez * 2
    ox, oy = cx - ow // 2, base_y - oh
    rx = int(ow * 0.34)
    sid = "watchscr"
    uri = data_uri(footage)
    glow = f'<ellipse cx="{cx}" cy="{oy+oh//2}" rx="{ow*0.85}" ry="{oh*0.7}" fill="{GREEN}" opacity="0.17" filter="url(#soft2)"/>'
    lug_t = f'<rect x="{cx-sw*0.34}" y="{oy-46}" width="{sw*0.68}" height="70" rx="20" fill="#181c24"/>'
    lug_b = f'<rect x="{cx-sw*0.34}" y="{oy+oh-24}" width="{sw*0.68}" height="80" rx="20" fill="#181c24"/>'
    body = (f'<rect x="{ox}" y="{oy}" width="{ow}" height="{oh}" rx="{rx}" fill="#23272f" stroke="#000" stroke-width="3"/>'
            f'<rect x="{ox+3}" y="{oy+3}" width="{ow-6}" height="{oh//2}" rx="{rx-3}" fill="#ffffff" opacity="0.05"/>')
    crown = f'<rect x="{ox+ow-6}" y="{oy+oh*0.36}" width="16" height="70" rx="8" fill="#2b313d" stroke="#000" stroke-width="2"/>'
    clip = f'<clipPath id="{sid}"><rect x="{ox+bez}" y="{oy+bez}" width="{sw}" height="{sh}" rx="{rx-bez+6}"/></clipPath>'
    img = (f'<image href="{uri}" x="{ox+bez}" y="{oy+bez}" width="{sw}" height="{sh}" '
           f'preserveAspectRatio="xMidYMid slice" clip-path="url(#{sid})"/>')
    srim = f'<rect x="{ox+bez}" y="{oy+bez}" width="{sw}" height="{sh}" rx="{rx-bez+6}" fill="none" stroke="{GREEN}" stroke-opacity="0.3" stroke-width="2"/>'
    refl = f'<ellipse cx="{cx}" cy="{base_y+50}" rx="{sw*0.7}" ry="40" fill="{GREEN}" opacity="0.12" filter="url(#soft)"/>'
    inner = f'<defs>{clip}</defs>{glow}{lug_t}{lug_b}{body}{crown}{img}{srim}'
    return f'{refl}<g transform="rotate({tilt} {cx} {base_y})">{inner}</g>'


def caption(text, cy, expr="smile", fs=62):
    est = int(len(text) * fs * 0.56) + 150
    pw = min(max(est, 520), W - 60)
    ph = int(fs * 2.2)
    px = (W - pw) // 2
    py = cy - ph // 2
    baseline = cy + int(fs * 0.34)
    body = (f'<rect x="{px}" y="{py}" width="{pw}" height="{ph}" rx="{ph//2}" '
            f'fill="#05100a" fill-opacity="0.85" stroke="{GREEN}" stroke-opacity="0.35" stroke-width="3"/>'
            f'<rect x="{px+34}" y="{cy-fs//2-6}" width="10" height="{fs+12}" rx="5" fill="{GREEN}"/>'
            + big(text, W // 2, baseline, fs)
            + wharfie(px - 26, py - 190 + 52, 190, expr=expr, rotate=-12, gid="cap"))
    return body


def render(name, body):
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
           f'viewBox="0 0 {W} {H}">{body}</svg>')
    p = os.path.join(GYM, name + ".svg")
    with open(p, "w") as f:
        f.write(svg)
    subprocess.run(["rsvg-convert", p, "-o", os.path.join(GYM, name + ".png")], check=True)
    print("wrote", name + ".png")


# ================= HERO SCENE: iPad on plyo box =================
def wall_ball(cx, cy, r=96):
    body = f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#16110d" stroke="#000" stroke-width="3"/>'
    seam = f'<path d="M{cx-r} {cy} Q{cx} {cy-r*0.5} {cx+r} {cy}" fill="none" stroke="#241a12" stroke-width="4"/>'
    rim = f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{GREEN}" stroke-opacity="0.16" stroke-width="2"/>'
    return f'<g opacity="0.9">{body}{seam}{rim}</g>'


def scene_ipad():
    cx = W // 2
    box_top = 1740
    body = (
        f'<rect width="{W}" height="{H}" fill="url(#bg)"/>'
        + defs()
        + back_wall()
        + floor_pool(cx, 1820)
        + plyo_box(cx, box_top, 820, faceh=360)
        + f'<ellipse cx="{cx}" cy="{box_top-4}" rx="400" ry="66" fill="{GREEN}" opacity="0.16" filter="url(#soft)"/>'
        + framed_ipad(cx, box_top + 4, 900, os.path.join(GYM, "tablet_hero.png"), tilt=-3)
        + f'<ellipse cx="{cx}" cy="2440" rx="760" ry="150" fill="{GREEN}" opacity="0.07" filter="url(#soft2)"/>'
        + kettlebell(228, 2320, 1.2)
        + wall_ball(1085, 2360, 96)
        + barbell(2430)
        + f'<rect width="{W}" height="{H}" fill="url(#vig)"/>'
        + caption("PROP IT UP. WHOLE-GYM CLOCK.", 2660, expr="yell", fs=58)
    )
    render("scene_ipad", body)


# ================= WATCH SCENE: on a plate-stack pedestal =================
def scene_watch():
    cx = W // 2
    ped_top = 2060
    body = (
        f'<rect width="{W}" height="{H}" fill="url(#bg)"/>'
        + defs()
        + back_wall()
        + floor_pool(cx, 1960)
        + f'<ellipse cx="{cx}" cy="1720" rx="340" ry="300" fill="{GREEN}" opacity="0.08" filter="url(#soft2)"/>'
        + plate_stack(cx, ped_top, n=3, rx=330, ry=74, gap=46)
        + framed_watch(cx, ped_top + 30, 476, os.path.join(GYM, "watch_hero.png"), tilt=-5)
        + kettlebell(230, 2380, 1.15)
        + barbell(2500)
        + f'<rect width="{W}" height="{H}" fill="url(#vig)"/>'
        + caption("STRAP IT ON. SAME COACH.", 2680, expr="yell", fs=60)
    )
    render("scene_watch", body)


if __name__ == "__main__":
    scene_ipad()
    scene_watch()
    print("done")
