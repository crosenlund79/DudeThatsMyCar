"""M011: the Copper Owl's gaming room (seen from straight above, like the other
interiors; wall side at the top).

interiors/roulette_table - the wheel table: a dark wooden rail round green baize,
                 the wheel's bowl at the left end, the betting layout (the zero,
                 twelve columns of three numbers, the outside bets) to the right,
                 a few chips left on it.
interiors/roulette_rotor - the wheel head on its own (turned by the game while it
                 spins): thirty-seven pockets, brass turret in the middle.
interiors/slot_machine_owl, _bell, _star - three nickel machines against the wall:
                 a cast cabinet with its crest, the reel window and the payout cup
                 showing at the front (bottom), the lever at the right side.
interiors/side_table - a small round table with two glasses and an ashtray.
interiors/floor_gaming - dark stained boards, scuffed and burnt (seamless).
interiors/wall_prints - framed prints along a wall (racehorses, a prize fighter).
interiors/tall_clock - a tall-case clock against the wall.
interiors/spittoon - a dented brass spittoon."""
import math
import random

import numpy as np
from PIL import Image, ImageDraw

from paintkit import *

OUT = (24, 18, 15)
BRASS = "#c9a24e"
BAIZE = "#24543a"
WOOD = "#3a2216"
RED = "#9a2322"
BLACK = "#1c1a1e"
# the single-zero wheel, clockwise from the zero (the standard European order)
WHEEL = [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22,
         18, 29, 7, 28, 12, 35, 3, 26]
REDS = {1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36}


def _pocket_colour(n):
    return "#2f7a3a" if n == 0 else (RED if n in REDS else BLACK)


def rotor(seed=401, size=96):
    """The wheel head from above: pockets in their real order, numbers' colours, the turret."""
    w = h = size
    img = new(w, h)
    c = size / 2
    R = size / 2 - 2
    paint_shape(img, SP(ellipse_pts(c, c, R, R, n=96)), "#5a3420", seed, outline=OUT, ow=1.2, wob=0.05, tex=0.2,
                light=(0.3, -1, 0.35))
    ring_o, ring_i = R * 0.86, R * 0.58
    for k, n in enumerate(WHEEL):
        a0 = -math.pi / 2 + 2 * math.pi * (k - 0.5) / 37
        a1 = -math.pi / 2 + 2 * math.pi * (k + 0.5) / 37
        pts = []
        for t in np.linspace(a0, a1, 5):
            pts.append((c + math.cos(t) * ring_o, c + math.sin(t) * ring_o))
        for t in np.linspace(a1, a0, 5):
            pts.append((c + math.cos(t) * ring_i, c + math.sin(t) * ring_i))
        paint_shape(img, SP(pts), _pocket_colour(n), seed + k, outline=(120, 96, 50), ow=0.5, wob=0.0, tex=0.12)
    paint_shape(img, SP(ellipse_pts(c, c, ring_i, ring_i, n=72)), "#6a4024", seed + 50, outline=(120, 96, 50), ow=0.8,
                wob=0.03, tex=0.2, light=(0.3, -1, 0.4))
    # the turret: four brass arms and a knob
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        line(img, [S(c, c), S(c + math.cos(a) * ring_i * 0.8, c + math.sin(a) * ring_i * 0.8)], BRASS, 2.2 * SS, 255)
        paint_shape(img, SP(ellipse_pts(c + math.cos(a) * ring_i * 0.8, c + math.sin(a) * ring_i * 0.8, 2.2, 2.2)),
                    "#e0c070", seed + 60 + k, outline=OUT, ow=0.5, wob=0.02)
    paint_shape(img, SP(ellipse_pts(c, c, size * 0.09, size * 0.09)), "#e0c070", seed + 70, outline=OUT, ow=0.8, wob=0.02,
                light=(0.3, -1, 0.6))
    soft_blob(img, S(c - 2), S(c - 3), S(size * 0.05), S(size * 0.03), "#ffffff", 120, 0.6 * SS)
    return finish(grain(img, 3, seed), w, h)


def roulette_table(seed=411):
    w, h = 288, 136
    img = new(w, h)
    soft_blob(img, S(w / 2 + 3), S(h / 2 + 6), S(w / 2 - 4), S(h / 2 - 8), "#000000", 110, 6 * SS)
    paint_shape(img, SP(rrect_pts(4, 6, w - 4, h - 6, 26)), WOOD, seed, outline=OUT, ow=1.6, wob=0.12, tex=0.25,
                strokes_n=18, stroke_cols=["#4a2c1c", "#2a160c"], light=(0.3, -1, 0.35))
    paint_shape(img, SP(rrect_pts(12, 14, w - 12, h - 14, 20)), BAIZE, seed + 1, outline=(16, 30, 20), ow=1.2, wob=0.1,
                tex=0.25, strokes_n=24, stroke_cols=["#2c6244", "#1e4630"], light=(0.3, -1, 0.3), inner_shadow=0.4)
    # the wheel's bowl at the left end (the rotor is drawn on top by the game)
    bx, by = 58, h / 2
    paint_shape(img, SP(ellipse_pts(bx, by, 44, 44, n=96)), "#4a2a18", seed + 2, outline=OUT, ow=1.4, wob=0.05, tex=0.2,
                light=(0.3, -1, 0.4))
    paint_shape(img, SP(ellipse_pts(bx, by, 38, 38, n=96)), "#2a1a12", seed + 3, outline=(90, 70, 40), ow=1.0, wob=0.03,
                tex=0.15, inner_shadow=0.5)
    rot = rotor(seed + 4, 72)
    img.alpha_composite(rot.resize((S(72), S(72)), Image.LANCZOS), (S(int(bx - 36)), S(int(by - 36))))
    # the layout: the zero, then twelve columns of three, the dozens and evens below
    x0, y0, cw, ch = 116, 24, 12.0, 20.0
    zero = [(x0, y0 + ch * 1.5), (x0 + 9, y0), (x0 + 13, y0), (x0 + 13, y0 + ch * 3), (x0 + 9, y0 + ch * 3)]
    paint_shape(img, SP(zero), "#2f7a3a", seed + 5, outline=(220, 210, 180), ow=0.6, wob=0.02, tex=0.1)
    gx = x0 + 13
    for col in range(12):
        for row in range(3):
            n = col * 3 + (3 - row)
            px, py = gx + col * cw, y0 + row * ch
            paint_shape(img, SP([(px, py), (px + cw, py), (px + cw, py + ch), (px, py + ch)]),
                        RED if n in REDS else BLACK, seed + 10 + n, outline=(220, 210, 180), ow=0.5, wob=0.01, tex=0.12)
            if n % 2:
                soft_blob(img, S(px + cw / 2), S(py + ch / 2), S(2.2), S(3.2), "#efe6cf", 90, 0.5 * SS)
            else:
                line(img, [S(px + cw / 2 - 2, py + ch / 2), S(px + cw / 2 + 2, py + ch / 2)], "#efe6cf", 0.9 * SS, 120)
    for k in range(3):  # 2 to 1 at the end of each row
        px, py = gx + 12 * cw, y0 + k * ch
        paint_shape(img, SP([(px, py), (px + 12, py), (px + 12, py + ch), (px, py + ch)]), BAIZE, seed + 60 + k,
                    outline=(220, 210, 180), ow=0.5, wob=0.01, tex=0.1)
    yd = y0 + 3 * ch
    for k in range(3):  # the dozens
        px = gx + k * cw * 4
        paint_shape(img, SP([(px, yd), (px + cw * 4, yd), (px + cw * 4, yd + 13), (px, yd + 13)]), BAIZE, seed + 70 + k,
                    outline=(220, 210, 180), ow=0.5, wob=0.01, tex=0.1)
    for k in range(6):  # 1-18, even, red, black, odd, 19-36
        px = gx + k * cw * 2
        col = RED if k == 2 else (BLACK if k == 3 else BAIZE)
        paint_shape(img, SP([(px, yd + 13), (px + cw * 2, yd + 13), (px + cw * 2, yd + 25), (px, yd + 25)]), col,
                    seed + 80 + k, outline=(220, 210, 180), ow=0.5, wob=0.01, tex=0.1)
    # chips left on the layout and the croupier's rake
    rnd = random.Random(seed)
    for k in range(7):
        px, py = gx + rnd.uniform(4, 140), y0 + rnd.uniform(4, 80)
        paint_shape(img, SP(ellipse_pts(px, py, 3.4, 3.4)), rnd.choice(["#b02a2a", "#e8e0cf", "#2a4a9a", "#d8b050"]),
                    seed + 90 + k, outline=OUT, ow=0.5, wob=0.02, light=(0.3, -1, 0.4))
    line(img, [S(108, 18), S(150, 12)], "#8a6a40", 1.4 * SS, 230)
    paint_shape(img, SP(rrect_pts(146, 8, 160, 15, 1)), "#8a6a40", seed + 99, outline=OUT, ow=0.5, wob=0.02)
    return finish(grain(img, 3, seed), w, h)


def roulette_rotor(seed=421):
    return rotor(seed, 96)


CRESTS = {"owl": ("#8a5a2a", "#d8a85a"), "bell": ("#7a1e1e", "#e0c070"), "star": ("#2e4a3a", "#c8ccd0")}


def slot_machine(kind, seed):
    """A nickel machine from above against the wall (wall at the top): the cabinet's top
    with its crest, the front showing at the bottom - reel window, coin slot, payout cup -
    the lever at the right."""
    body, trim = CRESTS[kind]
    w, h = 64, 76
    img = new(w, h)
    soft_blob(img, S(32), S(44), S(26), S(26), "#000000", 110, 4 * SS)
    # the stand
    paint_shape(img, SP(rrect_pts(8, 6, 54, 70, 4)), "#2a1a10", seed, outline=OUT, ow=1.2, wob=0.08, tex=0.25,
                light=(0.3, -1, 0.3))
    # the cabinet's top, a rounded cast crest
    paint_shape(img, SP(rrect_pts(10, 6, 52, 40, 10)), body, seed + 1, outline=OUT, ow=1.3, wob=0.08, tex=0.25,
                strokes_n=8, light=(0.3, -1, 0.45), inner_shadow=0.25)
    paint_shape(img, SP(rrect_pts(15, 10, 47, 34, 7)), shade(body, 1.25), seed + 2, outline=(60, 40, 20), ow=0.6, wob=0.06,
                tex=0.2, light=(0.3, -1, 0.5))
    cx, cy = 31, 22
    if kind == "owl":
        paint_shape(img, SP(ellipse_pts(cx, cy, 8, 9)), trim, seed + 3, outline=OUT, ow=0.8, wob=0.05, light=(0.3, -1, 0.5))
        for ex in (-3.4, 3.4):
            paint_shape(img, SP(ellipse_pts(cx + ex, cy - 2, 2.6, 2.6)), "#f2e6c0", seed + 4, outline=OUT, ow=0.5, wob=0.02)
            soft_blob(img, S(cx + ex), S(cy - 2), S(1.0), S(1.0), "#1a1208", 255, 0.2 * SS)
        paint_shape(img, SP([(cx - 1.2, cy + 1), (cx + 1.2, cy + 1), (cx, cy + 3.6)]), "#6a4010", seed + 5, outline=None, wob=0.0)
    elif kind == "bell":
        bell = [(cx - 2.5, cy - 8), (cx + 2.5, cy - 8), (cx + 5, cy - 2), (cx + 8.5, cy + 6), (cx - 8.5, cy + 6), (cx - 5, cy - 2)]
        paint_shape(img, SP(bell), trim, seed + 3, outline=OUT, ow=0.8, wob=0.04, light=(0.3, -1, 0.6))
        paint_shape(img, SP(ellipse_pts(cx, cy + 7.5, 2, 2)), trim, seed + 4, outline=OUT, ow=0.5, wob=0.02)
    else:
        star = [(cx + math.cos(-math.pi / 2 + k * math.pi / 5) * (9 if k % 2 == 0 else 3.8),
                 cy + math.sin(-math.pi / 2 + k * math.pi / 5) * (9 if k % 2 == 0 else 3.8)) for k in range(10)]
        paint_shape(img, SP(star), trim, seed + 3, outline=OUT, ow=0.8, wob=0.03, light=(0.3, -1, 0.6))
    # the front: the reel window with three symbols showing, the coin slot, the payout cup
    paint_shape(img, SP(rrect_pts(13, 42, 49, 56, 2)), "#d8d0bc", seed + 6, outline=OUT, ow=0.9, wob=0.04, tex=0.1)
    for k, col in enumerate(("#b02a2a", "#e0b030", "#2a2a2e")):
        x = 19 + k * 12
        paint_shape(img, SP(rrect_pts(x - 4.5, 44, x + 4.5, 54, 1)), "#f2ecdc", seed + 7 + k, outline=(80, 70, 60),
                    ow=0.5, wob=0.02)
        paint_shape(img, SP(ellipse_pts(x, 49, 2.6, 2.6)), col, seed + 10 + k, outline=None, wob=0.02)
    line(img, [S(13, 42), S(49, 42)], trim, 1.4 * SS, 230)
    paint_shape(img, SP(rrect_pts(22, 58, 40, 67, 3)), trim, seed + 13, outline=OUT, ow=0.8, wob=0.04, light=(0.3, -1, 0.5),
                inner_shadow=0.4)
    soft_blob(img, S(31), S(63), S(5), S(2), "#1a1208", 140, 0.6 * SS)
    # the lever, along the right side, its black knob at the end
    line(img, [S(53, 30), S(60, 30)], "#9a9aa0", 1.6 * SS, 255)
    line(img, [S(60, 30), S(60, 52)], "#b8b8be", 2.0 * SS, 255)
    paint_shape(img, SP(ellipse_pts(60, 54, 3.4, 3.4)), "#141210", seed + 14, outline=OUT, ow=0.6, wob=0.02,
                light=(0.3, -1, 0.6))
    soft_blob(img, S(22), S(14), S(6), S(3), "#ffffff", 50, 1.0 * SS)
    # wear: scuffs on the stand
    rnd = random.Random(seed)
    for k in range(4):
        soft_blob(img, S(rnd.uniform(12, 50)), S(rnd.uniform(58, 68)), S(rnd.uniform(1, 3)), S(0.8), "#6a5a48", 90, 0.4 * SS)
    return finish(grain(img, 3, seed), w, h)


def side_table(seed=431):
    w = h = 72
    img = new(w, h)
    c = 36
    soft_blob(img, S(c + 2), S(c + 4), S(26), S(26), "#000000", 100, 4 * SS)
    paint_shape(img, SP(ellipse_pts(c, c, 24, 24, n=72)), "#3a2014", seed, outline=OUT, ow=1.3, wob=0.1, tex=0.25,
                strokes_n=10, stroke_cols=["#4a2a1a", "#2c160e"], light=(0.3, -1, 0.35))
    paint_shape(img, SP(ellipse_pts(c, c, 19, 19, n=72)), "#d8d0c0", seed + 1, outline=(80, 60, 40), ow=0.8, wob=0.08,
                tex=0.18, light=(0.3, -1, 0.3))  # a marble top, stained
    soft_blob(img, S(c + 6), S(c + 5), S(4), S(3), "#8a6a40", 70, 1 * SS)
    for gx, gy, col in ((c - 7, c - 5, "#c9a35a"), (c + 3, c - 9, "#b9cfd6")):
        paint_shape(img, SP(ellipse_pts(gx, gy, 3.6, 3.6)), col, seed + 2 + gx, outline=(60, 50, 40), ow=0.6, wob=0.03)
        soft_blob(img, S(gx - 1), S(gy - 1), S(1.2), S(1.2), "#ffffff", 150, 0.5 * SS)
    ax, ay = c + 6, c + 7
    paint_shape(img, SP(ellipse_pts(ax, ay, 5, 5)), "#5a5a60", seed + 5, outline=OUT, ow=0.7, wob=0.03, light=(0.3, -1, 0.4))
    line(img, [S(ax - 1, ay), S(ax + 6, ay - 3)], "#e8e2d4", 1.2 * SS, 255)  # a cigarette
    soft_blob(img, S(ax + 6), S(ay - 3), S(1.0), S(1.0), "#ff8a3a", 220, 0.4 * SS)
    paint_shape(img, SP(rrect_pts(c - 12, c + 4, c - 3, c + 12, 1)), "#6a1c1e", seed + 6, outline=OUT, ow=0.5, wob=0.03)
    return finish(grain(img, 3, seed), w, h)


def floor_gaming(seed=441):
    """Dark stained oak boards running across the room, scuffed paths and a few burns (seamless)."""
    w = h = 256
    rnd = random.Random(seed)
    n = tnoise(w * SS, h * SS, 3, seed, octaves=4)
    img = ramp(n, ["#24140c", "#33200f", "#3e2814", "#2c1a0e"])
    d = ImageDraw.Draw(img)
    board = 24
    for y in range(0, h, board):
        d.line([(0, S(y)), (S(w), S(y))], fill=rgba("#140a05", 220), width=SS)
        off = rnd.randrange(0, w)
        for x in (off, (off + 128) % w):
            d.line([(S(x), S(y)), (S(x), S(y + board))], fill=rgba("#140a05", 200), width=SS)
    img = strokes(img, 120, ["#4a301a", "#20120a", "#3a2412"], 40, 2, seed + 1, angle=0.0, alpha=(18, 45))
    wear = tnoise(w * SS, h * SS, 2, seed + 3, octaves=2)
    a = np.asarray(img, dtype=np.float32).copy()
    s = np.clip((wear - 0.5) * 2.0, 0, 1)
    a[..., :3] += s[..., None] * np.array([26, 18, 10], dtype=np.float32)
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    for k in range(4):  # cigarette burns
        x, y = rnd.uniform(10, w - 10), rnd.uniform(10, h - 10)
        soft_blob(img, S(x), S(y), S(rnd.uniform(1.2, 2.2)), S(rnd.uniform(1.0, 1.8)), "#0a0604", 200, 0.6 * SS)
    return finish(grain(img, 5, seed), w, h)


def wall_prints(seed=451):
    """Three framed prints hanging on a wall (the wall at the top), seen a little from the front."""
    w, h = 140, 26
    img = new(w, h)
    soft_blob(img, S(w / 2), S(16), S(w / 2 - 4), S(7), "#000000", 70, 3 * SS)
    frames = [(6, 40, "horse"), (50, 90, "fighter"), (100, 134, "horse2")]
    rnd = random.Random(seed)
    for x0, x1, subj in frames:
        paint_shape(img, SP(rrect_pts(x0, 3, x1, 22, 1)), "#6a4a22", seed + x0, outline=OUT, ow=1.0, wob=0.04, tex=0.2,
                    light=(0.3, -1, 0.4))
        paint_shape(img, SP(rrect_pts(x0 + 3, 6, x1 - 3, 19, 0.5)), "#d8c8a0", seed + x0 + 1, outline=(80, 60, 40),
                    ow=0.4, wob=0.02, tex=0.2)
        mx = (x0 + x1) / 2
        if subj.startswith("horse"):
            # a racehorse in silhouette at full stretch, a jockey's red silks
            soft_blob(img, S(mx), S(13), S(8), S(2.6), "#3a2a1a", 230, 0.4 * SS)
            line(img, [S(mx - 8, 13), S(mx - 13, 17)], "#3a2a1a", 1.0 * SS, 230)
            line(img, [S(mx + 7, 12), S(mx + 11, 9)], "#3a2a1a", 1.4 * SS, 230)
            line(img, [S(mx + 4, 15), S(mx + 10, 18)], "#3a2a1a", 1.0 * SS, 230)
            soft_blob(img, S(mx + 1), S(9.6), S(1.8), S(1.4), "#a02020" if subj == "horse" else "#204a90", 230, 0.3 * SS)
        else:
            # a prize fighter, gloves up
            soft_blob(img, S(mx), S(13), S(2.4), S(4.2), "#3a2a1a", 230, 0.4 * SS)
            soft_blob(img, S(mx), S(8), S(1.6), S(1.6), "#3a2a1a", 230, 0.3 * SS)
            soft_blob(img, S(mx - 3.5), S(10), S(1.6), S(1.6), "#a02020", 230, 0.3 * SS)
            soft_blob(img, S(mx + 3.5), S(10), S(1.6), S(1.6), "#a02020", 230, 0.3 * SS)
        soft_blob(img, S(x0 + 6), S(8), S(4), S(1.4), "#ffffff", 40, 0.8 * SS)
    return finish(grain(img, 3, seed), w, h)


def tall_clock(seed=461):
    w, h = 40, 32
    img = new(w, h)
    soft_blob(img, S(21), S(18), S(16), S(12), "#000000", 90, 3 * SS)
    paint_shape(img, SP(rrect_pts(4, 3, 36, 28, 3)), "#4a2a16", seed, outline=OUT, ow=1.2, wob=0.06, tex=0.25,
                strokes_n=6, light=(0.3, -1, 0.4))
    paint_shape(img, SP(rrect_pts(8, 6, 32, 14, 2)), "#5e3820", seed + 1, outline=(40, 24, 14), ow=0.6, wob=0.04)
    paint_shape(img, SP(ellipse_pts(20, 20, 8, 6)), "#efe2c0", seed + 2, outline=(90, 70, 40), ow=0.8, wob=0.02)
    line(img, [S(20, 20), S(20, 16)], "#1a1208", 0.8 * SS, 255)
    line(img, [S(20, 20), S(24, 21)], "#1a1208", 0.8 * SS, 255)
    line(img, [S(6, 28), S(34, 28)], BRASS, 1.0 * SS, 200)
    return finish(grain(img, 3, seed), w, h)


def spittoon(seed=471):
    w = h = 24
    img = new(w, h)
    soft_blob(img, S(13), S(14), S(9), S(9), "#000000", 100, 2 * SS)
    paint_shape(img, SP(ellipse_pts(12, 12, 9, 9)), "#b08a3a", seed, outline=OUT, ow=0.9, wob=0.12, tex=0.2,
                light=(0.3, -1, 0.6))
    paint_shape(img, SP(ellipse_pts(12, 12, 4.5, 4.5)), "#3a2a14", seed + 1, outline=(90, 70, 30), ow=0.6, wob=0.05)
    soft_blob(img, S(9), S(8), S(2.4), S(1.4), "#fff0c0", 120, 0.6 * SS)
    return finish(img, w, h)


ASSETS = {
    "interiors/roulette_table": roulette_table,
    "interiors/roulette_rotor": roulette_rotor,
    "interiors/slot_machine_owl": lambda: slot_machine("owl", 481),
    "interiors/slot_machine_bell": lambda: slot_machine("bell", 483),
    "interiors/slot_machine_star": lambda: slot_machine("star", 485),
    "interiors/side_table": side_table,
    "interiors/floor_gaming": floor_gaming,
    "interiors/wall_prints": wall_prints,
    "interiors/tall_clock": tall_clock,
    "interiors/spittoon": spittoon,
}


# ------------------------------------------------------------------ on screen (the wheel table)

def ui_felt(seed=501):
    """The wheel table on screen: green baize inside a dark wooden rail with a brass inlay (the
    layout and the wheel are drawn on it by the game)."""
    w, h = 720, 320
    img = new(w, h)
    soft_blob(img, S(w / 2), S(h / 2 + 6), S(w / 2 - 6), S(h / 2 - 6), "#000000", 140, 8 * SS)
    paint_shape(img, SP(rrect_pts(4, 4, w - 4, h - 4, 34)), WOOD, seed, outline=OUT, ow=2.0, wob=0.1, tex=0.25,
                strokes_n=40, stroke_cols=["#4a2c1c", "#2a160c"], light=(0.3, -1, 0.35))
    line(img, [S(*p) for p in rrect_pts(13, 13, w - 13, h - 13, 27)] + [S(13 + 27, 13)], BRASS, 1.2 * SS, 150)
    paint_shape(img, SP(rrect_pts(20, 20, w - 20, h - 20, 24)), BAIZE, seed + 1, outline=(16, 30, 20), ow=1.4, wob=0.08,
                tex=0.22, strokes_n=60, stroke_cols=["#2c6244", "#1e4630"], light=(0.2, -1, 0.25), inner_shadow=0.5)
    # wear: a lighter patch where the croupier's rake goes, a couple of old burns
    soft_blob(img, S(w * 0.62), S(h * 0.5), S(150), S(70), "#3a7a54", 40, 20 * SS)
    rnd = random.Random(seed)
    for k in range(3):
        soft_blob(img, S(rnd.uniform(60, w - 60)), S(rnd.uniform(40, h - 40)), S(1.6), S(1.2), "#0e1a12", 160, 0.6 * SS)
    return finish(grain(img, 3, seed), w, h)


def ui_bowl(seed=511):
    """The wheel's wooden bowl from above (the rotor is drawn on top, turning): the outer rim,
    the polished ball track, eight brass deflectors, the dark gap round the rotor."""
    w = h = 512
    img = new(w, h)
    c = 256
    R = 250
    soft_blob(img, S(c + 6), S(c + 10), S(R), S(R), "#000000", 150, 10 * SS)
    paint_shape(img, SP(ellipse_pts(c, c, R, R, n=160)), "#3a2014", seed, outline=OUT, ow=2.0, wob=0.04, tex=0.25,
                strokes_n=40, stroke_cols=["#4a2a18", "#2a140a"], light=(0.3, -1, 0.4))
    paint_shape(img, SP(ellipse_pts(c, c, R * 0.95, R * 0.95, n=160)), "#7a4a26", seed + 1, outline=(40, 24, 12), ow=1.2,
                wob=0.02, tex=0.2, light=(-0.3, 1, 0.45))  # the ball track, sloping in
    paint_shape(img, SP(ellipse_pts(c, c, R * 0.80, R * 0.80, n=160)), "#4a2a16", seed + 2, outline=(30, 18, 10), ow=1.0,
                wob=0.02, tex=0.2, light=(0.3, -1, 0.3))
    for k in range(8):  # the deflectors ("diamonds")
        a = k * math.pi / 4 + math.pi / 8
        x, y = c + math.cos(a) * R * 0.85, c + math.sin(a) * R * 0.85
        pts = [(x + math.cos(a) * 7, y + math.sin(a) * 7), (x + math.cos(a + math.pi / 2) * 3.4, y + math.sin(a + math.pi / 2) * 3.4),
               (x - math.cos(a) * 7, y - math.sin(a) * 7), (x - math.cos(a + math.pi / 2) * 3.4, y - math.sin(a + math.pi / 2) * 3.4)]
        paint_shape(img, SP(pts), "#e0c070", seed + 10 + k, outline=OUT, ow=0.7, wob=0.0, light=(0.3, -1, 0.6))
    paint_shape(img, SP(ellipse_pts(c, c, R * 0.785, R * 0.785, n=160)), "#140a06", seed + 3, outline=None, wob=0.0, tex=0.1)
    soft_blob(img, S(c - 70), S(c - 150), S(70), S(18), "#ffffff", 30, 10 * SS, rot=-0.4)
    return finish(grain(img, 3, seed), w, h)


def ui_rotor(seed=521):
    """The wheel head on screen, its zero at the top, pockets clockwise in the European order:
    the number ring (white numbers on red, black and green), the pockets with brass frets, the
    cone and the turret. The game turns it."""
    w = h = 512
    img = new(w, h)
    c = 256
    R = 254
    paint_shape(img, SP(ellipse_pts(c, c, R, R, n=180)), "#2a1a10", seed, outline=OUT, ow=1.4, wob=0.0, tex=0.15)
    for k, n in enumerate(WHEEL):
        a0 = -math.pi / 2 + 2 * math.pi * (k - 0.5) / 37
        a1 = -math.pi / 2 + 2 * math.pi * (k + 0.5) / 37
        for r_out, r_in, col in ((R * 0.99, R * 0.86, _pocket_colour(n)), (R * 0.86, R * 0.66, shade(_pocket_colour(n), 0.62))):
            pts = [(c + math.cos(t) * r_out, c + math.sin(t) * r_out) for t in np.linspace(a0, a1, 6)]
            pts += [(c + math.cos(t) * r_in, c + math.sin(t) * r_in) for t in np.linspace(a1, a0, 6)]
            paint_shape(img, SP(pts), col, seed + k, outline=None, wob=0.0, tex=0.12)
        # the fret between this pocket and the next
        line(img, [S(c + math.cos(a1) * R * 0.66, c + math.sin(a1) * R * 0.66), S(c + math.cos(a1) * R * 0.99, c + math.sin(a1) * R * 0.99)],
             "#d8b060", 1.4 * SS, 230)
        # the number, standing out from the middle
        am = -math.pi / 2 + 2 * math.pi * k / 37
        tile = Image.new("RGBA", (S(40), S(28)), (0, 0, 0, 0))
        text(tile, (20, 14), str(n), 17, "#f4ecd8")
        tile = tile.rotate(-math.degrees(am) - 90, resample=Image.BICUBIC, expand=True)
        tx, ty = c + math.cos(am) * R * 0.925, c + math.sin(am) * R * 0.925
        img.alpha_composite(tile, (int(S(tx) - tile.width / 2), int(S(ty) - tile.height / 2)))
    line(img, [S(*p) for p in ellipse_pts(c, c, R * 0.86, R * 0.86, n=180)] + [S(c + R * 0.86, c)], "#d8b060", 1.4 * SS, 220)
    line(img, [S(*p) for p in ellipse_pts(c, c, R * 0.66, R * 0.66, n=180)] + [S(c + R * 0.66, c)], "#d8b060", 1.6 * SS, 230)
    paint_shape(img, SP(ellipse_pts(c, c, R * 0.655, R * 0.655, n=160)), "#6a3e20", seed + 50, outline=None, wob=0.0, tex=0.25,
                strokes_n=20, stroke_cols=["#7a4a28", "#4a2a14"], light=(0.3, -1, 0.45))
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        line(img, [S(c, c), S(c + math.cos(a) * R * 0.42, c + math.sin(a) * R * 0.42)], BRASS, 6 * SS, 255)
        paint_shape(img, SP(ellipse_pts(c + math.cos(a) * R * 0.42, c + math.sin(a) * R * 0.42, 9, 9)), "#e0c070",
                    seed + 60 + k, outline=OUT, ow=0.8, wob=0.0, light=(0.3, -1, 0.6))
    paint_shape(img, SP(ellipse_pts(c, c, 26, 26)), "#e0c070", seed + 70, outline=OUT, ow=1.0, wob=0.0, light=(0.3, -1, 0.6))
    soft_blob(img, S(c - 8), S(c - 10), S(9), S(6), "#ffffff", 130, 2 * SS)
    return finish(grain(img, 2, seed), w, h)


def ui_ball(seed=531):
    w = h = 32
    img = new(w, h)
    soft_blob(img, S(17), S(18), S(12), S(12), "#000000", 120, 2 * SS)
    paint_shape(img, SP(ellipse_pts(16, 16, 12, 12)), "#f3eee2", seed, outline=(90, 80, 70), ow=0.8, wob=0.0, tex=0.06,
                light=(-0.4, -1, 0.5))
    soft_blob(img, S(12), S(11), S(4), S(3), "#ffffff", 220, 1 * SS)
    return finish(img, w, h)


def ui_dolly(seed=541):
    """The croupier's brass marker set on the winning number."""
    w = h = 48
    img = new(w, h)
    soft_blob(img, S(25), S(27), S(14), S(14), "#000000", 130, 3 * SS)
    paint_shape(img, SP(ellipse_pts(24, 24, 14, 14)), "#b8913e", seed, outline=OUT, ow=1.0, wob=0.02, light=(0.3, -1, 0.6))
    paint_shape(img, SP(ellipse_pts(24, 24, 8, 8)), "#e8cc7a", seed + 1, outline=(90, 60, 20), ow=0.8, wob=0.02,
                light=(0.3, -1, 0.6))
    soft_blob(img, S(20), S(19), S(4), S(2.5), "#ffffff", 150, 1 * SS)
    return finish(img, w, h)


ASSETS.update({
    "ui/roulette_felt": ui_felt,
    "ui/roulette_bowl": ui_bowl,
    "ui/roulette_rotor": ui_rotor,
    "ui/roulette_ball": ui_ball,
    "ui/roulette_dolly": ui_dolly,
})


# ------------------------------------------------------------------ on screen (the nickel machines)

FRONTS = {"owl": ("#9a5a26", "#d8a85a", "OWL"), "bell": ("#7e1c1c", "#e0c070", "BELL"), "star": ("#24463a", "#d0d4d8", "STAR")}
# the reel windows in the front (holes the reels show through), the pay line's height
WINDOWS = [(75, 150, 165, 270), (175, 150, 265, 270), (275, 150, 365, 270)]
PAY_Y = 210


def ui_front(kind, seed):
    """A 1930s three-reel machine's cast front, 440 x 600: the crest at the top with its emblem
    and name, the three reel windows (transparent: the game draws the reels behind), the
    paytable plate (blank: the game prints the machine's own lines), the coin plaque and the
    payout cup at the bottom. Worn paint, scuffed brass."""
    body, trim, word = FRONTS[kind]
    w, h = 440, 600
    img = new(w, h)
    soft_blob(img, S(w / 2 + 6), S(h / 2 + 10), S(w / 2 - 10), S(h / 2 - 10), "#000000", 150, 10 * SS)
    # the cabinet with its arched crest
    pts = [(30, 600), (30, 150)]
    for k in range(25):
        a = math.pi + math.pi * k / 24
        pts.append((220 + math.cos(a) * 190, 150 + math.sin(a) * 130))
    pts += [(410, 150), (410, 600)]
    paint_shape(img, SP(pts), body, seed, outline=OUT, ow=2.2, wob=0.15, tex=0.3, strokes_n=40,
                stroke_cols=[shade(body, 1.2), shade(body, 0.8)], light=(0.3, -1, 0.4), inner_shadow=0.3)
    # cast ribs down the sides
    for x in (46, 394):
        for k in range(8):
            y = 300 + k * 36
            line(img, [S(x - 6, y), S(x + 6, y)], shade(trim, 0.8), 2.0 * SS, 170)
    # the crest's emblem and name
    cx, cy = 220, 70
    paint_shape(img, SP(ellipse_pts(cx, cy, 56, 42)), shade(body, 1.3), seed + 1, outline=OUT, ow=1.4, wob=0.08, tex=0.2,
                light=(0.3, -1, 0.5))
    if kind == "owl":
        paint_shape(img, SP(ellipse_pts(cx, cy + 4, 30, 34)), trim, seed + 2, outline=OUT, ow=1.2, wob=0.08, light=(0.3, -1, 0.5))
        for ex in (-12, 12):
            paint_shape(img, SP(ellipse_pts(cx + ex, cy - 6, 10, 10)), "#f2e6c0", seed + 3, outline=OUT, ow=0.9, wob=0.02)
            soft_blob(img, S(cx + ex), S(cy - 6), S(4), S(4), "#1a1208", 255, 0.4 * SS)
        paint_shape(img, SP([(cx - 4, cy + 6), (cx + 4, cy + 6), (cx, cy + 15)]), "#6a4010", seed + 4, outline=None, wob=0.0)
        for ex in (-1, 1):
            paint_shape(img, SP([(cx + ex * 18, cy - 26), (cx + ex * 28, cy - 40), (cx + ex * 26, cy - 18)]), trim, seed + 5,
                        outline=OUT, ow=0.9, wob=0.02)
    elif kind == "bell":
        bell = [(cx - 8, cy - 32), (cx + 8, cy - 32), (cx + 16, cy - 12), (cx + 30, cy + 22), (cx - 30, cy + 22), (cx - 16, cy - 12)]
        paint_shape(img, SP(bell), trim, seed + 2, outline=OUT, ow=1.2, wob=0.05, light=(0.3, -1, 0.6))
        paint_shape(img, SP(ellipse_pts(cx, cy + 27, 6, 6)), trim, seed + 3, outline=OUT, ow=0.8, wob=0.02)
    else:
        star = [(cx + math.cos(-math.pi / 2 + k * math.pi / 5) * (36 if k % 2 == 0 else 15),
                 cy + math.sin(-math.pi / 2 + k * math.pi / 5) * (36 if k % 2 == 0 else 15)) for k in range(10)]
        paint_shape(img, SP(star), trim, seed + 2, outline=OUT, ow=1.2, wob=0.03, light=(0.3, -1, 0.6))
    text(img, (cx, 124), word, 20, trim, stroke=1.2, stroke_color=(30, 20, 10), spacing=6)
    # Art Deco fluting beside the window, a brass band round it
    for x in (40, 50, 390, 400):
        line(img, [S(x, 150), S(x, 280)], shade(body, 0.7), 1.6 * SS, 200)
    line(img, [S(*q) for q in rrect_pts(56, 132, 384, 288, 11)] + [S(56 + 11, 132)], trim, 2.0 * SS, 230)
    # the window frame, chromed, with the pay line's pointers
    paint_shape(img, SP(rrect_pts(62, 138, 378, 282, 8)), "#b8b8be", seed + 6, outline=OUT, ow=1.4, wob=0.04, tex=0.15,
                light=(0.3, -1, 0.6))
    for k, (x0, y0, x1, y1) in enumerate(WINDOWS):
        paint_shape(img, SP(rrect_pts(x0 - 3, y0 - 3, x1 + 3, y1 + 3, 3)), "#2a2a2e", seed + 7 + k, outline=None, wob=0.0)
    for side in (1, -1):
        x = 66 if side == 1 else 374
        paint_shape(img, SP([(x, PAY_Y - 7), (x + side * 9, PAY_Y), (x, PAY_Y + 7)]), "#c0392b", seed + 12, outline=OUT, ow=0.6,
                    wob=0.0)
    # the paytable plate (the game prints it), the coin plaque, the payout cup
    paint_shape(img, SP(rrect_pts(52, 296, 388, 478, 6)), trim, seed + 13, outline=OUT, ow=1.4, wob=0.05, light=(0.3, -1, 0.5))
    paint_shape(img, SP(rrect_pts(60, 304, 380, 470, 4)), "#ece2c8", seed + 14, outline=(90, 70, 40), ow=0.8, wob=0.03, tex=0.15)
    paint_shape(img, SP(rrect_pts(320, 488, 396, 520, 4)), trim, seed + 15, outline=OUT, ow=1.0, wob=0.04, light=(0.3, -1, 0.5))
    paint_shape(img, SP(rrect_pts(330, 500, 386, 506, 2)), "#1a1410", seed + 16, outline=None, wob=0.0)  # the coin slot
    paint_shape(img, SP(rrect_pts(150, 520, 290, 590, 18)), trim, seed + 17, outline=OUT, ow=1.4, wob=0.05, light=(0.3, -1, 0.5),
                inner_shadow=0.5)
    paint_shape(img, SP(rrect_pts(164, 532, 276, 578, 12)), "#2a1e12", seed + 18, outline=(80, 60, 30), ow=0.8, wob=0.04,
                inner_shadow=0.6)
    # wear: chipped paint, scuffs, a little grime at the foot
    rnd = random.Random(seed)
    for k in range(26):
        x, y = rnd.uniform(40, 400), rnd.uniform(160, 590)
        if 62 < x < 378 and 138 < y < 282:
            continue
        soft_blob(img, S(x), S(y), S(rnd.uniform(1, 4)), S(rnd.uniform(0.6, 2)), rnd.choice(["#d8c8a0", "#3a2a1a", "#8a7a6a"]),
                  rnd.randint(60, 140), 0.5 * SS, rot=rnd.uniform(0, 3))
    soft_blob(img, S(220), S(596), S(180), S(14), "#1a120a", 90, 6 * SS)
    soft_blob(img, S(150), S(60), S(40), S(14), "#ffffff", 40, 8 * SS, rot=-0.3)
    img = grain(img, 4, seed)
    # punch the reel windows through
    a = np.asarray(img).copy()
    for (x0, y0, x1, y1) in WINDOWS:
        a[S(y0):S(y1), S(x0):S(x1), 3] = 0
    img = Image.fromarray(a, "RGBA")
    return finish(img, w, h)


def ui_symbol(kind, seed):
    """A reel symbol, 96 x 96, on nothing (the reel's cream paper is drawn by the game)."""
    w = h = 96
    img = new(w, h)
    c = 48
    if kind == "cherry":
        line(img, [S(36, 62), S(46, 30), S(58, 18)], "#3a5a20", 3 * SS, 255)
        line(img, [S(62, 64), S(54, 34), S(58, 18)], "#3a5a20", 3 * SS, 255)
        paint_shape(img, SP([(58, 18), (78, 12), (84, 26), (66, 28)]), "#4a8a2a", seed, outline=OUT, ow=1.0, wob=0.1)
        for x, y in ((34, 66), (62, 68)):
            paint_shape(img, SP(ellipse_pts(x, y, 15, 15)), "#b01e22", seed + x, outline=OUT, ow=1.4, wob=0.1, tex=0.15,
                        light=(-0.4, -1, 0.5))
            soft_blob(img, S(x - 5), S(y - 6), S(4), S(3), "#ffffff", 150, 1 * SS)
    elif kind == "lemon":
        paint_shape(img, SP(ellipse_pts(c, c, 34, 24, rot=-0.25)), "#e8c830", seed, outline=OUT, ow=1.4, wob=0.2, tex=0.2,
                    light=(-0.4, -1, 0.5))
        for sx in (-1, 1):
            paint_shape(img, SP(ellipse_pts(c + sx * 34, c - sx * 9, 5, 4, rot=-0.25)), "#d8b820", seed + 3, outline=OUT, ow=0.8, wob=0.05)
        soft_blob(img, S(c - 10), S(c - 10), S(9), S(4), "#ffffff", 110, 2 * SS, rot=-0.25)
    elif kind == "orange":
        paint_shape(img, SP(ellipse_pts(c, c + 4, 30, 30)), "#e47a1e", seed, outline=OUT, ow=1.4, wob=0.12, tex=0.25,
                    light=(-0.4, -1, 0.5))
        paint_shape(img, SP([(c, c - 26), (c + 18, c - 38), (c + 22, c - 28), (c + 6, c - 24)]), "#3a7a2a", seed + 2, outline=OUT,
                    ow=0.9, wob=0.05)
        soft_blob(img, S(c - 10), S(c - 8), S(7), S(5), "#ffffff", 100, 2 * SS)
    elif kind == "plum":
        paint_shape(img, SP(ellipse_pts(c, c + 4, 26, 32)), "#5a2a6a", seed, outline=OUT, ow=1.4, wob=0.12, tex=0.2,
                    light=(-0.4, -1, 0.5))
        line(img, [S(c, c - 26), S(c + 4, c - 38)], "#4a3a20", 2.4 * SS, 255)
        soft_blob(img, S(c - 8), S(c - 8), S(6), S(10), "#d8c8f0", 70, 3 * SS)
    elif kind == "bell":
        bell = [(c - 9, c - 32), (c + 9, c - 32), (c + 18, c - 12), (c + 32, c + 24), (c - 32, c + 24), (c - 18, c - 12)]
        paint_shape(img, SP(bell), "#e0b030", seed, outline=OUT, ow=1.4, wob=0.05, tex=0.15, light=(-0.4, -1, 0.6))
        paint_shape(img, SP(ellipse_pts(c, c + 30, 7, 7)), "#e0b030", seed + 1, outline=OUT, ow=1.0, wob=0.02)
        line(img, [S(c - 24), S(c + 14), S(c + 24), S(c + 14)], "#a07010", 1.4 * SS, 200)
        soft_blob(img, S(c - 8), S(c - 12), S(5), S(10), "#fff0c0", 140, 2 * SS)
    elif kind == "bar":
        paint_shape(img, SP(rrect_pts(10, 30, 86, 66, 4)), "#1a1612", seed, outline=OUT, ow=1.4, wob=0.05, tex=0.1)
        text(img, (c, c), "BAR", 24, "#f0e4c8", spacing=3)
    elif kind == "seven":
        text(img, (c, c + 2), "7", 74, "#b01e22", stroke=2.5, stroke_color=(220, 170, 60))
    return finish(grain(img, 2, seed), w, h)


def ui_lever(seed=561):
    """The lever on the machine's right side, upright, its pivot at the bottom middle."""
    w, h = 40, 200
    img = new(w, h)
    line(img, [S(20, 190), S(20, 34)], "#9a9aa0", 7 * SS, 255)
    line(img, [S(17, 186), S(17, 36)], "#e0e0e6", 2 * SS, 200)
    paint_shape(img, SP(ellipse_pts(20, 22, 16, 16)), "#141210", seed, outline=OUT, ow=1.2, wob=0.02, light=(-0.4, -1, 0.6))
    soft_blob(img, S(14), S(15), S(5), S(4), "#ffffff", 150, 1.4 * SS)
    paint_shape(img, SP(ellipse_pts(20, 188, 11, 11)), "#b8b8be", seed + 1, outline=OUT, ow=1.0, wob=0.02, light=(-0.4, -1, 0.6))
    return finish(img, w, h)


def ui_coin(seed=571):
    w = h = 40
    img = new(w, h)
    paint_shape(img, SP(ellipse_pts(20, 20, 17, 17)), "#b8b8b0", seed, outline=(70, 70, 66), ow=1.2, wob=0.02, tex=0.2,
                light=(-0.4, -1, 0.5))
    line(img, [S(*p) for p in ellipse_pts(20, 20, 13, 13)] + [S(33, 20)], "#8a8a84", 0.8 * SS, 200)
    text(img, (20, 21), "5", 14, "#6a6a64")
    soft_blob(img, S(14), S(13), S(4), S(3), "#ffffff", 140, 1 * SS)
    return finish(img, w, h)


ASSETS.update({
    "ui/slot_front_owl": lambda: ui_front("owl", 601),
    "ui/slot_front_bell": lambda: ui_front("bell", 603),
    "ui/slot_front_star": lambda: ui_front("star", 605),
    "ui/slot_cherry": lambda: ui_symbol("cherry", 611),
    "ui/slot_lemon": lambda: ui_symbol("lemon", 613),
    "ui/slot_orange": lambda: ui_symbol("orange", 615),
    "ui/slot_plum": lambda: ui_symbol("plum", 617),
    "ui/slot_bell": lambda: ui_symbol("bell", 619),
    "ui/slot_bar": lambda: ui_symbol("bar", 621),
    "ui/slot_seven": lambda: ui_symbol("seven", 623),
    "ui/slot_lever": ui_lever,
    "ui/slot_coin": ui_coin,
})


# ------------------------------------------------------------------ M011: the union hall (wall side at the top)

def desk(seed=701):
    """The business agent's desk: a scuffed oak top, a green-shaded lamp, a telephone, a ledger and papers."""
    w, h = 160, 80
    img = new(w, h)
    soft_blob(img, S(82), S(44), S(74), S(34), "#000000", 100, 4 * SS)
    paint_shape(img, SP(rrect_pts(6, 8, w - 6, h - 8, 3)), "#5a3a20", seed, outline=OUT, ow=1.4, wob=0.08, tex=0.25,
                strokes_n=16, stroke_cols=["#6a4628", "#462a16"], light=(0.3, -1, 0.35))
    paint_shape(img, SP(rrect_pts(40, 22, 96, 56, 1)), "#e8dcbc", seed + 1, outline=(90, 70, 40), ow=0.6, wob=0.04, tex=0.15)
    paint_shape(img, SP(rrect_pts(52, 30, 92, 60, 1)), "#efe4c6", seed + 2, outline=(90, 70, 40), ow=0.6, wob=0.04, tex=0.15)
    for k in range(5):
        line(img, [S(56, 36 + k * 4), S(86, 36 + k * 4)], "#7a6a50", 0.6 * SS, 150)
    paint_shape(img, SP(rrect_pts(104, 18, 140, 44, 2)), "#2a3a2a", seed + 3, outline=OUT, ow=0.8, wob=0.04, light=(0.3, -1, 0.4))
    line(img, [S(110, 22), S(134, 22)], "#c9a24e", 1.0 * SS, 200)  # the ledger's band
    paint_shape(img, SP(ellipse_pts(26, 26, 11, 11)), "#2f6a46", seed + 4, outline=OUT, ow=0.9, wob=0.03, light=(0.3, -1, 0.6))
    soft_blob(img, S(26), S(26), S(4), S(4), "#fff0c0", 200, 1.2 * SS)  # the lamp lit
    paint_shape(img, SP(rrect_pts(108, 50, 132, 66, 3)), "#1a1614", seed + 5, outline=OUT, ow=0.8, wob=0.03)  # the telephone
    line(img, [S(110, 52), S(130, 52)], "#3a3430", 2.4 * SS, 255)
    soft_blob(img, S(30), S(60), S(5), S(3), "#3a2a1a", 120, 1 * SS)  # a ring from a cup
    return finish(grain(img, 3, seed), w, h)


def filing_cabinet(seed=711):
    w, h = 48, 40
    img = new(w, h)
    soft_blob(img, S(25), S(22), S(20), S(16), "#000000", 90, 3 * SS)
    paint_shape(img, SP(rrect_pts(4, 4, w - 4, h - 4, 2)), "#5a5e52", seed, outline=OUT, ow=1.1, wob=0.05, tex=0.2,
                light=(0.3, -1, 0.4))
    for k in range(3):
        y = 12 + k * 8
        line(img, [S(10, y), S(w - 10, y)], "#3a3c34", 1.0 * SS, 200)
        paint_shape(img, SP(rrect_pts(20, y + 1.5, 28, y + 4, 1)), "#b8b8a8", seed + k, outline=None, wob=0.02)
    soft_blob(img, S(14), S(10), S(5), S(2), "#ffffff", 50, 1 * SS)
    return finish(grain(img, 3, seed), w, h)


def safe(seed=721):
    w = h = 44
    img = new(w, h)
    soft_blob(img, S(23), S(24), S(18), S(18), "#000000", 110, 3 * SS)
    paint_shape(img, SP(rrect_pts(4, 4, w - 4, h - 4, 3)), "#2a2c30", seed, outline=OUT, ow=1.2, wob=0.04, tex=0.15,
                light=(0.3, -1, 0.45))
    paint_shape(img, SP(ellipse_pts(22, 24, 7, 7)), "#9a8a5a", seed + 1, outline=OUT, ow=0.8, wob=0.02, light=(0.3, -1, 0.6))
    line(img, [S(8, 9), S(36, 9)], "#c9a24e", 1.0 * SS, 200)
    return finish(grain(img, 3, seed), w, h)


def noticeboard(seed=731):
    """A cork board on the wall (wall at the top) crowded with notices, shift lists and a poster, pinned."""
    w, h = 128, 30
    img = new(w, h)
    soft_blob(img, S(64), S(18), S(60), S(10), "#000000", 70, 3 * SS)
    paint_shape(img, SP(rrect_pts(3, 2, w - 3, h - 4, 1)), "#5a3a20", seed, outline=OUT, ow=1.0, wob=0.04, tex=0.2)
    paint_shape(img, SP(rrect_pts(6, 4, w - 6, h - 7, 1)), "#a07a4a", seed + 1, outline=None, wob=0.03, tex=0.35)
    rnd = random.Random(seed)
    x = 9
    while x < w - 16:
        pw = rnd.uniform(10, 18)
        col = rnd.choice(["#efe6cf", "#e8dca8", "#f2ece0", "#d8c8a0", "#c8d8e8"])
        paint_shape(img, SP(rrect_pts(x, 5 + rnd.uniform(0, 2), x + pw, 20 + rnd.uniform(0, 3), 0.5)), col, seed + int(x), outline=(90, 80, 60),
                    ow=0.4, wob=0.05)
        for k in range(3):
            line(img, [S(x + 2, 9 + k * 3.5), S(x + pw - 2, 9 + k * 3.5)], "#5a5040", 0.5 * SS, 140)
        soft_blob(img, S(x + pw / 2), S(6), S(1), S(1), rnd.choice(["#b02a2a", "#2a4a9a"]), 255, 0.2 * SS)
        x += pw + rnd.uniform(1, 4)
    return finish(grain(img, 3, seed), w, h)


def wall_map(seed=741):
    """A big map of the river docks and the rail yards pinned to the wall (wall at the top)."""
    w, h = 150, 26
    img = new(w, h)
    soft_blob(img, S(75), S(15), S(70), S(9), "#000000", 70, 3 * SS)
    paint_shape(img, SP(rrect_pts(3, 2, w - 3, h - 4, 1)), "#e4d8b8", seed, outline=(80, 66, 46), ow=0.9, wob=0.04, tex=0.25)
    paint_shape(img, SP([(100, 3), (118, 3), (114, 21), (96, 21)]), "#8aa4b8", seed + 1, outline=None, wob=0.1)  # the river
    for k in range(4):
        line(img, [S(10, 7 + k * 4), S(92, 7 + k * 4)], "#6a5a40", 0.6 * SS, 160)  # the sidings
    for x in (24, 46, 70):
        paint_shape(img, SP(rrect_pts(x, 6, x + 14, 18, 0.5)), "#b8956a", seed + x, outline=(80, 60, 40), ow=0.4, wob=0.05)
    for k in range(6):
        soft_blob(img, S(20 + k * 22), S(12 + (k % 3)), S(1.2), S(1.2), "#b02a2a", 255, 0.3 * SS)
    return finish(grain(img, 3, seed), w, h)


def charter(seed=751):
    """The local's charter, framed, and a photograph of the members on the wall (wall at the top)."""
    w, h = 84, 24
    img = new(w, h)
    soft_blob(img, S(42), S(14), S(38), S(8), "#000000", 70, 3 * SS)
    paint_shape(img, SP(rrect_pts(4, 2, 40, 20, 1)), "#6a4a22", seed, outline=OUT, ow=0.9, wob=0.04, light=(0.3, -1, 0.4))
    paint_shape(img, SP(rrect_pts(7, 4, 37, 18, 0.5)), "#efe4c6", seed + 1, outline=None, wob=0.02, tex=0.15)
    soft_blob(img, S(22), S(14), S(3), S(3), "#b02a2a", 220, 0.4 * SS)  # the seal
    for k in range(2):
        line(img, [S(10, 7 + k * 3), S(34, 7 + k * 3)], "#5a4a30", 0.6 * SS, 160)
    paint_shape(img, SP(rrect_pts(46, 3, 80, 20, 1)), "#2a2018", seed + 2, outline=OUT, ow=0.9, wob=0.04)
    paint_shape(img, SP(rrect_pts(49, 5, 77, 18, 0.5)), "#8a8274", seed + 3, outline=None, wob=0.02, tex=0.3)
    for k in range(6):
        soft_blob(img, S(52 + k * 4.4), S(12), S(1.6), S(2.6), "#3a342c", 220, 0.4 * SS)  # the men in a row
    return finish(grain(img, 3, seed), w, h)


def potbelly(seed=761):
    """A cast-iron pot-bellied stove from above, its pipe going up, a warm glow at the grate."""
    w = h = 52
    img = new(w, h)
    soft_blob(img, S(27), S(28), S(20), S(20), "#000000", 110, 3 * SS)
    paint_shape(img, SP(ellipse_pts(26, 26, 18, 18)), "#24221f", seed, outline=OUT, ow=1.2, wob=0.06, tex=0.2, light=(0.3, -1, 0.4))
    paint_shape(img, SP(ellipse_pts(26, 26, 9, 9)), "#3a3632", seed + 1, outline=OUT, ow=0.8, wob=0.03, light=(0.3, -1, 0.5))
    soft_blob(img, S(26), S(40), S(7), S(3), "#ff8a3a", 160, 1.5 * SS)
    return finish(grain(img, 3, seed), w, h)


ASSETS.update({
    "interiors/desk": desk,
    "interiors/filing_cabinet": filing_cabinet,
    "interiors/safe": safe,
    "interiors/noticeboard": noticeboard,
    "interiors/wall_map": wall_map,
    "interiors/charter": charter,
    "interiors/potbelly": potbelly,
})
