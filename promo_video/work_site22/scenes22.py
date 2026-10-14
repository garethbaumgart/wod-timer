#!/usr/bin/env python3
# Wharf WOD 2.2 device scenes for the portfolio card film: the same "in the gym"
# look as promo_video/gym_scene.py, with the 2.2 screens: Apple Watch (store shot),
# iPad in portrait (store shot), and a round Wear OS watch (emulator capture).
import os, sys
WT = os.path.expanduser("~/Source/mentalmetal-worktrees/wod-site-media/promo_video")
sys.path.insert(0, WT)
import gym_scene as g
OUT = os.path.dirname(os.path.abspath(__file__))
g.GYM = OUT  # render into the scratch dir, not the repo
W, H, GREEN = g.W, g.H, g.GREEN
SHOTS = os.path.expanduser("~/Source/mentalmetal-worktrees/wod-site-media/fastlane/screenshots/en-US")

def framed_ipad_portrait(cx, base_y, screen_w, footage, tilt=-3):
    ar = 2048 / 2732
    sw = screen_w; sh = int(sw / ar); bez = 30
    ow, oh = sw + bez * 2, sh + bez * 2
    ox, oy = cx - ow // 2, base_y - oh
    uri = g.data_uri(footage)
    glow = f'<ellipse cx="{cx}" cy="{oy+oh//2}" rx="{ow*0.66}" ry="{oh*0.6}" fill="{GREEN}" opacity="0.16" filter="url(#soft2)"/>'
    body = (f'<rect x="{ox}" y="{oy}" width="{ow}" height="{oh}" rx="40" fill="#23272f" stroke="#000" stroke-width="3"/>'
            f'<rect x="{ox+2}" y="{oy+2}" width="{ow-4}" height="{oh//2}" rx="38" fill="#ffffff" opacity="0.04"/>')
    clip = f'<clipPath id="ipadp"><rect x="{ox+bez}" y="{oy+bez}" width="{sw}" height="{sh}" rx="10"/></clipPath>'
    img = f'<image href="{uri}" x="{ox+bez}" y="{oy+bez}" width="{sw}" height="{sh}" preserveAspectRatio="xMidYMid slice" clip-path="url(#ipadp)"/>'
    rim = f'<rect x="{ox+bez}" y="{oy+bez}" width="{sw}" height="{sh}" rx="10" fill="none" stroke="{GREEN}" stroke-opacity="0.28" stroke-width="2"/>'
    cam = f'<circle cx="{cx}" cy="{oy+15}" r="4" fill="#12151b"/>'
    refl = f'<ellipse cx="{cx}" cy="{base_y+70}" rx="{sw*0.5}" ry="46" fill="{GREEN}" opacity="0.12" filter="url(#soft)"/>'
    return f'{refl}<g transform="rotate({tilt} {cx} {base_y})"><defs>{clip}</defs>{glow}{body}{cam}{img}{rim}</g>'

def framed_round_watch(cx, base_y, d, footage, tilt=-5):
    # a round Wear OS watch: screen diameter d, slim bezel, two side buttons, strap stubs
    bez = 34; r = d // 2 + bez; cy = base_y - r
    uri = g.data_uri(footage)
    glow = f'<circle cx="{cx}" cy="{cy}" r="{r*1.5}" fill="{GREEN}" opacity="0.17" filter="url(#soft2)"/>'
    strap_t = f'<rect x="{cx-d*0.30}" y="{cy-r-70}" width="{d*0.60}" height="110" rx="26" fill="#181c24"/>'
    strap_b = f'<rect x="{cx-d*0.30}" y="{cy+r-40}" width="{d*0.60}" height="120" rx="26" fill="#181c24"/>'
    body = (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#23272f" stroke="#000" stroke-width="3"/>'
            f'<circle cx="{cx}" cy="{cy-r*0.25}" r="{r*0.7}" fill="#ffffff" opacity="0.04"/>')
    btn = (f'<rect x="{cx+r-8}" y="{cy-70}" width="18" height="52" rx="8" fill="#2b313d" stroke="#000" stroke-width="2"/>'
           f'<rect x="{cx+r-8}" y="{cy+18}" width="18" height="52" rx="8" fill="#2b313d" stroke="#000" stroke-width="2"/>')
    clip = f'<clipPath id="wearscr"><circle cx="{cx}" cy="{cy}" r="{d//2}"/></clipPath>'
    img = f'<image href="{uri}" x="{cx-d//2}" y="{cy-d//2}" width="{d}" height="{d}" preserveAspectRatio="xMidYMid slice" clip-path="url(#wearscr)"/>'
    rim = f'<circle cx="{cx}" cy="{cy}" r="{d//2}" fill="none" stroke="{GREEN}" stroke-opacity="0.3" stroke-width="2"/>'
    refl = f'<ellipse cx="{cx}" cy="{base_y+50}" rx="{d*0.7}" ry="40" fill="{GREEN}" opacity="0.12" filter="url(#soft)"/>'
    return f'{refl}<g transform="rotate({tilt} {cx} {base_y})"><defs>{clip}</defs>{glow}{strap_t}{strap_b}{body}{btn}{img}{rim}</g>'

def scene(name, device_svg, caption_text):
    cx = W // 2
    body = (f'<rect width="{W}" height="{H}" fill="url(#bg)"/>' + g.defs() + g.back_wall()
            + g.floor_pool(cx, 1960) + device_svg
            + g.kettlebell(230, 2380, 1.15) + g.barbell(2500)
            + f'<rect width="{W}" height="{H}" fill="url(#vig)"/>'
            + g.caption(caption_text, 2680, expr="yell", fs=58))
    g.render(name, body)

def apple_watch():
    cx = W // 2; ped_top = 2060
    dev = (g.plate_stack(cx, ped_top, n=3, rx=330, ry=74, gap=46)
           + g.framed_watch(cx, ped_top + 30, 476, os.path.join(SHOTS, "watch_1_live_amrap.png"), tilt=-5))
    scene("s22_watch", dev, "APPLE WATCH. SAME COACH.")

def ipad():
    cx = W // 2; box_top = 1900
    dev = (g.plyo_box(cx, box_top, 820, faceh=360)
           + f'<ellipse cx="{cx}" cy="{box_top-4}" rx="400" ry="66" fill="{GREEN}" opacity="0.16" filter="url(#soft)"/>'
           + framed_ipad_portrait(cx, box_top + 4, 700, os.path.join(SHOTS, "ipad_active_work.png"), tilt=-3))
    scene("s22_ipad", dev, "IPAD. WHOLE-GYM CLOCK.")

def wear(path):
    cx = W // 2; ped_top = 2060
    dev = (g.plate_stack(cx, ped_top, n=3, rx=330, ry=74, gap=46)
           + framed_round_watch(cx, ped_top + 30, 500, path, tilt=-5))
    scene("s22_wear", dev, "WEAR OS. SAME COACH.")

if __name__ == "__main__":
    which = sys.argv[1:] or ["watch", "ipad"]
    if "watch" in which: apple_watch()
    if "ipad" in which: ipad()
    if "wear" in which: wear(sys.argv[sys.argv.index("wear") + 1])
