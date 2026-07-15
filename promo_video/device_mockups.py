#!/usr/bin/env python3
# Premium device mockups for the Wharf WOD explainer: clean, recognisable
# Apple Watch Ultra + iPhone + iPad, each with a REAL app screenshot composited
# in, on a dark Signal-green stage. 1920x1080 (matches the explainer dimension).
# SVG -> rsvg-convert. Screenshots embedded as base64 data URIs.
import base64
import os
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
GYM = os.path.join(HERE, "work_gym")
OUT = os.path.join(HERE, "work_dev")
os.makedirs(OUT, exist_ok=True)

W, H = 1920, 1080
GREEN = "#00FF88"
INK = "#F2F7EE"
TITAN = "#c9cccd"
ORANGE = "#f0662a"


def uri(path):
    with open(path, "rb") as f:
        b = base64.b64encode(f.read()).decode()
    ext = "jpeg" if path.lower().endswith((".jpg", ".jpeg")) else "png"
    return f"data:image/{ext};base64,{b}"


def defs():
    return f'''<defs>
      <radialGradient id="stage" cx="0.5" cy="0.44" r="0.7">
        <stop offset="0" stop-color="#111726"/><stop offset="0.5" stop-color="#0a0d15"/>
        <stop offset="1" stop-color="#05070c"/></radialGradient>
      <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5">
        <stop offset="0" stop-color="{GREEN}" stop-opacity="0.22"/>
        <stop offset="1" stop-color="{GREEN}" stop-opacity="0"/></radialGradient>
      <linearGradient id="titan" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="#e4e7e8"/><stop offset="0.5" stop-color="#b9bdbf"/>
        <stop offset="1" stop-color="#8f9395"/></linearGradient>
      <linearGradient id="titan_v" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#e6e9ea"/><stop offset="1" stop-color="#9a9ea0"/></linearGradient>
      <linearGradient id="steel" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#2c313b"/><stop offset="1" stop-color="#14171d"/></linearGradient>
      <linearGradient id="band" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#20302a"/><stop offset="1" stop-color="#0f1713"/></linearGradient>
      <filter id="sh" x="-60%" y="-60%" width="220%" height="220%">
        <feGaussianBlur stdDeviation="34"/></filter>
      <filter id="sh2" x="-60%" y="-60%" width="220%" height="220%">
        <feGaussianBlur stdDeviation="16"/></filter>
    </defs>'''


def ground_shadow(cx, cy, rx, ry):
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#000000" opacity="0.55" filter="url(#sh)"/>'


def ipad(cx, base_y, screen_w, footage):
    ar = 2560 / 1600
    sw = screen_w
    sh = int(sw / ar)
    bez = 22
    ow, oh = sw + bez * 2, sh + bez * 2
    ox, oy = cx - ow // 2, base_y - oh
    sid = "ip"
    clip = f'<clipPath id="{sid}"><rect x="{ox+bez}" y="{oy+bez}" width="{sw}" height="{sh}" rx="10"/></clipPath>'
    body = (f'<rect x="{ox}" y="{oy}" width="{ow}" height="{oh}" rx="40" fill="#1b1e24" stroke="#000" stroke-width="2"/>'
            f'<rect x="{ox+3}" y="{oy+3}" width="{ow-6}" height="{oh-6}" rx="37" fill="none" stroke="#3a3f47" stroke-width="2"/>')
    img = f'<image href="{uri(footage)}" x="{ox+bez}" y="{oy+bez}" width="{sw}" height="{sh}" preserveAspectRatio="xMidYMid slice" clip-path="url(#{sid})"/>'
    glow = f'<ellipse cx="{cx}" cy="{oy+oh//2}" rx="{ow*0.62}" ry="{oh*0.62}" fill="{GREEN}" opacity="0.10" filter="url(#sh)"/>'
    hl = f'<rect x="{ox+bez}" y="{oy+bez}" width="{sw}" height="{sh}" rx="10" fill="url(#glow)" opacity="0.0"/>'
    return f'{ground_shadow(cx, base_y-6, ow*0.44, 34)}{glow}<defs>{clip}</defs>{body}{img}{hl}'


def iphone(cx, base_y, screen_w, footage, gid=""):
    ar = 1320 / 2868
    sw = screen_w
    sh = int(sw / ar)
    bez = 16
    ow, oh = sw + bez * 2, sh + bez * 2
    ox, oy = cx - ow // 2, base_y - oh
    sid = "ph" + str(gid)
    r = 76
    clip = f'<clipPath id="{sid}"><rect x="{ox+bez}" y="{oy+bez}" width="{sw}" height="{sh}" rx="{r-bez}"/></clipPath>'
    body = (f'<rect x="{ox}" y="{oy}" width="{ow}" height="{oh}" rx="{r}" fill="url(#steel)" stroke="#000" stroke-width="2"/>'
            f'<rect x="{ox+3}" y="{oy+3}" width="{ow-6}" height="{oh-6}" rx="{r-3}" fill="none" stroke="#454b55" stroke-width="2"/>')
    img = f'<image href="{uri(footage)}" x="{ox+bez}" y="{oy+bez}" width="{sw}" height="{sh}" preserveAspectRatio="xMidYMid slice" clip-path="url(#{sid})"/>'
    island = f'<rect x="{cx-46}" y="{oy+bez+16}" width="92" height="30" rx="15" fill="#05050a"/>'
    glow = f'<ellipse cx="{cx}" cy="{oy+oh//2}" rx="{ow*0.7}" ry="{oh*0.5}" fill="{GREEN}" opacity="0.10" filter="url(#sh)"/>'
    return f'{ground_shadow(cx, base_y-4, ow*0.5, 30)}{glow}<defs>{clip}</defs>{body}{img}{island}'


def watch_ultra(cx, base_y, screen_w, footage, band=True):
    # Apple Watch Ultra: flat titanium case, orange Action Button (left),
    # crown guard + digital crown + side button (right), flat display.
    ar = 416 / 496
    sw = screen_w
    sh = int(sw / ar)
    bez = 30
    ow, oh = sw + bez * 2, sh + bez * 2
    ox, oy = cx - ow // 2, base_y - oh
    cxr = int(ow * 0.235)  # case corner radius (Ultra is squarish)
    sid = "wu"
    bandsvg = ""
    if band:
        bw = int(ow * 0.72)
        bandsvg = (f'<rect x="{cx-bw//2}" y="{oy-oh*0.62}" width="{bw}" height="{oh*0.7}" rx="26" fill="url(#band)"/>'
                   f'<rect x="{cx-bw//2}" y="{oy+oh-oh*0.08}" width="{bw}" height="{oh*0.72}" rx="26" fill="url(#band)"/>'
                   # trail-loop texture hint
                   + "".join(f'<rect x="{cx-bw//2+8}" y="{int(oy-oh*0.55+i*26)}" width="{bw-16}" height="10" rx="5" fill="#0c120e"/>' for i in range(5))
                   + "".join(f'<rect x="{cx-bw//2+8}" y="{int(oy+oh+18+i*26)}" width="{bw-16}" height="10" rx="5" fill="#0c120e"/>' for i in range(6)))
    # crown guard on the right
    guard = f'<rect x="{ox+ow-10}" y="{oy+oh*0.30}" width="30" height="{oh*0.40}" rx="12" fill="url(#titan_v)" stroke="#7d8183" stroke-width="1.5"/>'
    crown = (f'<rect x="{ox+ow+6}" y="{oy+oh*0.36}" width="20" height="46" rx="7" fill="#b7bbbd" stroke="#6d7173" stroke-width="1.5"/>'
             f'<rect x="{ox+ow+6}" y="{oy+oh*0.36}" width="20" height="46" rx="7" fill="none" stroke="{ORANGE}" stroke-opacity="0.9" stroke-width="2"/>')
    sidebtn = f'<rect x="{ox+ow+2}" y="{oy+oh*0.58}" width="14" height="60" rx="6" fill="url(#titan_v)" stroke="#6d7173" stroke-width="1.5"/>'
    # orange action button on the left
    action = f'<rect x="{ox-16}" y="{oy+oh*0.42}" width="18" height="72" rx="7" fill="{ORANGE}" stroke="#a8481d" stroke-width="1.5"/>'
    # titanium case
    case = (f'<rect x="{ox}" y="{oy}" width="{ow}" height="{oh}" rx="{cxr}" fill="url(#titan)" stroke="#7d8183" stroke-width="2"/>'
            f'<rect x="{ox+4}" y="{oy+4}" width="{ow-8}" height="{oh-8}" rx="{cxr-4}" fill="none" stroke="#ffffff" stroke-opacity="0.5" stroke-width="1.5"/>')
    # black display bezel + screen
    dz = 16
    scr_r = cxr - dz + 2
    screen_bez = f'<rect x="{ox+dz}" y="{oy+dz}" width="{ow-dz*2}" height="{oh-dz*2}" rx="{scr_r}" fill="#000"/>'
    inx, iny = ox + dz + 10, oy + dz + 10
    inw, inh = ow - dz * 2 - 20, oh - dz * 2 - 20
    clip = f'<clipPath id="{sid}"><rect x="{inx}" y="{iny}" width="{inw}" height="{inh}" rx="{scr_r-8}"/></clipPath>'
    img = f'<image href="{uri(footage)}" x="{inx}" y="{iny}" width="{inw}" height="{inh}" preserveAspectRatio="xMidYMid slice" clip-path="url(#{sid})"/>'
    glow = f'<ellipse cx="{cx}" cy="{oy+oh//2}" rx="{ow*0.95}" ry="{oh*0.8}" fill="{GREEN}" opacity="0.16" filter="url(#sh)"/>'
    return (f'{ground_shadow(cx, base_y+6, ow*0.7, 30)}{glow}{bandsvg}'
            f'{action}{guard}{crown}{sidebtn}{case}{screen_bez}<defs>{clip}</defs>{img}')


def big(text, x, y, fs, fill=INK, weight=900, spacing=2, anchor="middle"):
    return (f'<text x="{x}" y="{y}" text-anchor="{anchor}" font-family="Helvetica,Arial,sans-serif" '
            f'font-size="{fs}" font-weight="{weight}" letter-spacing="{spacing}" fill="{fill}">{text}</text>')


def render(name, body):
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{body}</svg>'
    p = os.path.join(OUT, name + ".svg")
    with open(p, "w") as f:
        f.write(svg)
    subprocess.run(["rsvg-convert", p, "-o", os.path.join(OUT, name + ".png")], check=True)
    print("wrote", name + ".png")


def showcase():
    body = (
        f'<rect width="{W}" height="{H}" fill="url(#stage)"/>' + defs()
        + f'<ellipse cx="960" cy="470" rx="760" ry="440" fill="url(#glow)"/>'
        + ipad(560, 720, 720, os.path.join(GYM, "tablet_hero.png"))
        + iphone(1090, 800, 300, os.path.join(GYM, "phone_hero.png"))
        + watch_ultra(1500, 760, 250, os.path.join(GYM, "watch_hero.png"))
        + big("ONE APP.  EVERY SCREEN.", 960, 980, 46, fill=INK, spacing=4)
    )
    render("showcase", body)


def watch_solo():
    body = (
        f'<rect width="{W}" height="{H}" fill="url(#stage)"/>' + defs()
        + f'<ellipse cx="960" cy="500" rx="620" ry="440" fill="url(#glow)"/>'
        + watch_ultra(960, 720, 440, os.path.join(GYM, "watch_hero.png"))
        + big("APPLE WATCH ULTRA", 960, 940, 40, fill=INK, spacing=6)
    )
    render("watch_solo", body)


def modes_4up():
    # the four timer modes, each a real screenshot in an iPhone, labelled.
    modes = [
        ("01", "AMRAP", "mode_amrap.png"),
        ("02", "FOR TIME", "mode_fortime.png"),
        ("03", "EMOM", "mode_emom.png"),
        ("04", "TABATA", "mode_tabata.png"),
    ]
    centers = [366, 758, 1150, 1542]
    base_y = 838
    sw = 274
    phones = ""
    labels = ""
    for i, ((num, name, png), cx) in enumerate(zip(modes, centers)):
        phones += iphone(cx, base_y, sw, os.path.join(GYM, png), gid=f"m{i}")
        labels += (f'<text x="{cx}" y="905" text-anchor="middle" font-family="Helvetica,Arial,sans-serif" '
                   f'font-size="34" font-weight="900" letter-spacing="1">'
                   f'<tspan fill="{GREEN}">{num} </tspan><tspan fill="{INK}">{name}</tspan></text>')
    body = (
        f'<rect width="{W}" height="{H}" fill="url(#stage)"/>' + defs()
        + f'<ellipse cx="960" cy="470" rx="900" ry="440" fill="url(#glow)"/>'
        + big("PICK YOUR POISON.", 960, 116, 56, fill=INK, spacing=3)
        + phones + labels
    )
    render("modes_4up", body)


if __name__ == "__main__":
    watch_solo()
    showcase()
    modes_4up()
    print("done")
