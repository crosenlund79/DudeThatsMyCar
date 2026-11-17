"""Interiors seen from straight above: floors (seamless tiles) and furniture.
Furniture images keep the wall side at the top unless noted; the game turns them."""
import math
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from paintkit import *

OUT = (22, 17, 14)
BRASS = "#c9a24e"
MAHOGANY = "#5a2a1a"
CLOTH = "#ece6d6"


# ------------------------------------------------------------------ floors

def floor_parquet(seed=31):
    """Basket-weave oak parquet: 32 px squares of four planks, alternating direction (seamless)."""
    w = h = 256
    img = new(w, h, "#6b4528")
    d = ImageDraw.Draw(img)
    rnd = random.Random(seed)
    cols = ["#7a4f2c", "#845733", "#6f4626", "#8c5f38", "#76502f"]
    cell = 32
    for cy in range(0, h, cell):
        for cx in range(0, w, cell):
            vertical = ((cx // cell) + (cy // cell)) % 2 == 0
            for k in range(4):
                c = rgba(rnd.choice(cols))
                if vertical:
                    x0, y0, x1, y1 = cx + k * 8, cy, cx + k * 8 + 8, cy + cell
                else:
                    x0, y0, x1, y1 = cx, cy + k * 8, cx + cell, cy + k * 8 + 8
                d.rectangle([S(x0), S(y0), S(x1) - 1, S(y1) - 1], fill=c)
                # grain along the plank
                for g in range(3):
                    if vertical:
                        gx = S(x0 + rnd.uniform(1.5, 6.5))
                        d.line([(gx, S(y0 + 1)), (gx, S(y1 - 1))], fill=shade(c, 0.86), width=1)
                    else:
                        gy = S(y0 + rnd.uniform(1.5, 6.5))
                        d.line([(S(x0 + 1), gy), (S(x1 - 1), gy)], fill=shade(c, 0.86), width=1)
                d.rectangle([S(x0), S(y0), S(x1) - 1, S(y1) - 1], outline=rgba("#3a2414", 200), width=1)
    n = tnoise(w * SS, h * SS, 3, seed + 1, octaves=3)
    img = modulate(img, n, 0.22)
    # polish: a few soft lighter patches (pick up the lamps)
    sheen = tnoise(w * SS, h * SS, 2, seed + 5, octaves=2)
    a = np.asarray(img, dtype=np.float32).copy()
    s = np.clip((sheen - 0.5) * 2.5, 0, 1)
    a[..., :3] += s[..., None] * np.array([16, 11, 6], dtype=np.float32)
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    return finish(grain(img, 4, seed), w, h)


# ------------------------------------------------------------------ the Copper Owl

def bar_counter(seed=41):
    """The long bar seen from above, wall side at the top, customers along the bottom edge."""
    w, h = 420, 56
    img = new(w, h)
    soft_blob(img, S(w / 2), S(h / 2 + 4), S(w / 2 - 6), S(h / 2 - 6), "#000000", 90, 4 * SS)
    paint_shape(img, SP(rrect_pts(4, 6, w - 4, h - 8, 6)), MAHOGANY, seed, outline=OUT, ow=1.8, wob=0.25, tex=0.2,
                strokes_n=30, stroke_cols=["#6e3622", "#4a2014"], light=(0, -1, 0.35), inner_shadow=0.3)
    # polished top: long highlight, inlaid edge
    line(img, [(S(10), S(12)), (S(w - 10), S(12))], "#8a4a2c", 1.6 * SS, 200)
    soft_blob(img, S(w * 0.45), S(18), S(w * 0.35), S(3), "#ffffff", 40, 2 * SS)
    # brass rail along the customer side
    line(img, [(S(8), S(h - 6)), (S(w - 8), S(h - 6))], BRASS, 2.6 * SS, 255)
    line(img, [(S(8), S(h - 6.8)), (S(w - 8), S(h - 6.8))], "#f0d890", 0.8 * SS, 200)
    # things on the bar: glasses, a cocktail shaker, an ashtray, a cash register at the left
    rnd = random.Random(seed)
    paint_shape(img, SP(rrect_pts(20, 12, 54, 38, 3)), "#3a3a3e", seed + 1, outline=OUT, ow=1.2, wob=0.2, tex=0.15, light=(0.3, -1, 0.5))
    paint_shape(img, SP(rrect_pts(24, 14, 50, 24, 2)), BRASS, seed + 2, outline=None, wob=0.1, tex=0.1)
    for k in range(9):
        x = 80 + k * 36 + rnd.uniform(-6, 6)
        y = 26 + rnd.uniform(-5, 6)
        r = rnd.uniform(3.2, 4.2)
        paint_shape(img, SP(ellipse_pts(x, y, r, r)), "#b9cfd6", seed + 3 + k, outline=(60, 70, 74), ow=0.8, wob=0.05, tex=0.05)
        soft_blob(img, S(x - 1), S(y - 1), S(r * 0.45), S(r * 0.45), "#ffffff", 140, 0.6 * SS)
        if k % 3 == 1:
            paint_shape(img, SP(ellipse_pts(x, y, r * 0.6, r * 0.6)), "#b5651d", seed + 30 + k, outline=None, wob=0.05)
    paint_shape(img, SP(ellipse_pts(300, 22, 4.5, 4.5)), "#d4d6d8", seed + 50, outline=OUT, ow=0.8, wob=0.05, light=(0.3, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(372, 30, 6, 6)), "#3d3d40", seed + 51, outline=OUT, ow=0.8, wob=0.05)
    return finish(grain(img, 3, seed), w, h)


def back_bar(seed=43):
    """Shelves of bottles against the wall (top), seen from above, with the mirror's edge."""
    w, h = 420, 42
    img = new(w, h)
    paint_shape(img, SP(rrect_pts(2, 2, w - 2, h - 4, 3)), "#3b1d12", seed, outline=OUT, ow=1.6, wob=0.2, tex=0.2,
                light=(0, 1, 0.3))
    line(img, [(S(6), S(6)), (S(w - 6), S(6))], "#a9b9c2", 2.0 * SS, 170)
    rnd = random.Random(seed)
    glass = ["#4f7a3a", "#8a5a22", "#d8c9a0", "#3f6b5a", "#7a2d24", "#b8b8b0", "#5c3a1c"]
    x = 12
    while x < w - 12:
        for row, y in enumerate((16, 29)):
            if rnd.random() < 0.85:
                c = rnd.choice(glass)
                r = rnd.uniform(3.4, 4.6)
                xx = x + (5 if row else 0)
                paint_shape(img, SP(ellipse_pts(xx, y, r, r)), c, int(x * 3 + row), outline=OUT, ow=0.7, wob=0.05, tex=0.1)
                paint_shape(img, SP(ellipse_pts(xx, y, r * 0.38, r * 0.38)), "#d8c08a", int(x * 3 + row + 1), outline=None, wob=0.02)
                soft_blob(img, S(xx - r * 0.4), S(y - r * 0.4), S(r * 0.3), S(r * 0.3), "#ffffff", 120, 0.5 * SS)
        x += rnd.uniform(9.5, 12)
    return finish(grain(img, 3, seed), w, h)


def stool(seed=45):
    w = h = 36
    img = new(w, h)
    soft_blob(img, S(19), S(20), S(13), S(13), "#000000", 80, 2 * SS)
    paint_shape(img, SP(ellipse_pts(18, 18, 13, 13)), "#c9ccce", seed, outline=OUT, ow=1.2, wob=0.1, tex=0.1, light=(0.4, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(18, 18, 10.5, 10.5)), "#8e2422", seed + 1, outline=OUT, ow=0.9, wob=0.15, tex=0.25,
                light=(0.4, -1, 0.5), inner_shadow=0.3)
    soft_blob(img, S(15), S(14), S(4), S(3), "#ffffff", 60, 1 * SS)
    return finish(img, w, h)


def chair(img, cx, cy, a, seed):
    """A bentwood chair at (cx, cy) whose back faces away from the table along angle a."""
    ca, sa = math.cos(a), math.sin(a)
    seat = ellipse_pts(cx, cy, 8, 8)
    paint_shape(img, SP(seat), "#4a2c1a", seed, outline=OUT, ow=1.1, wob=0.1, tex=0.2, light=(0.3, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(cx, cy, 5.5, 5.5)), "#6e2a22", seed + 1, outline=None, wob=0.1, tex=0.2)
    back = [(cx + ca * 8 + math.cos(a + t) * 9.5, cy + sa * 8 + math.sin(a + t) * 9.5) for t in np.linspace(-1.0, 1.0, 9)]
    line(img, [S(*p) for p in back], "#3a2214", 3.0 * SS, 255)


def table_club(seed=47):
    """Round table for two or three: white cloth, a little shaded lamp, glasses; bentwood chairs."""
    w = h = 128
    img = new(w, h)
    cx = cy = 64
    soft_blob(img, S(cx + 3), S(cy + 4), S(40), S(40), "#000000", 70, 5 * SS)
    for k, a in enumerate((math.pi * 0.95, math.pi * 1.6, math.pi * 0.25)):
        chair(img, cx + math.cos(a) * 40, cy + math.sin(a) * 40, a, seed + k * 3)
    paint_shape(img, SP(ellipse_pts(cx, cy, 31, 31)), CLOTH, seed + 10, outline=OUT, ow=1.4, wob=0.35, tex=0.1,
                strokes_n=10, stroke_cols=["#fbf7ec", "#d6cfbd"], light=(0.3, -1, 0.35), inner_shadow=0.2)
    # cloth folds round the edge
    for k in range(10):
        a = k * math.pi / 5
        line(img, [(S(cx + math.cos(a) * 25), S(cy + math.sin(a) * 25)), (S(cx + math.cos(a) * 30.5), S(cy + math.sin(a) * 30.5))],
             "#c9c1ad", 1.1 * SS, 160)
    # the table lamp with its pleated shade
    paint_shape(img, SP(ellipse_pts(cx, cy, 8.5, 8.5)), "#e8b46a", seed + 11, outline=OUT, ow=1.0, wob=0.1, tex=0.1)
    soft_blob(img, S(cx), S(cy), S(5), S(5), "#fff2c8", 230, 1.5 * SS)
    for k in range(8):
        a = k * math.pi / 4
        line(img, [(S(cx + math.cos(a) * 3), S(cy + math.sin(a) * 3)), (S(cx + math.cos(a) * 8), S(cy + math.sin(a) * 8))],
             "#b07a3a", 0.8 * SS, 160)
    rnd = random.Random(seed)
    for a in (math.pi * 0.95, math.pi * 1.6, math.pi * 0.25):
        gx, gy = cx + math.cos(a + 0.35) * 18, cy + math.sin(a + 0.35) * 18
        paint_shape(img, SP(ellipse_pts(gx, gy, 3.6, 3.6)), "#b9cfd6", int(gx), outline=(60, 70, 74), ow=0.7, wob=0.05)
        soft_blob(img, S(gx - 1), S(gy - 1), S(1.4), S(1.4), "#ffffff", 150, 0.5 * SS)
    paint_shape(img, SP(ellipse_pts(cx + 14, cy - 13, 3.2, 3.2)), "#4a4a4e", seed + 20, outline=OUT, ow=0.6, wob=0.05)
    return finish(grain(img, 3, seed), w, h)


def piano(seed=49):
    """Baby grand from above, keyboard at the left with its bench, lid open (curved side at the right)."""
    w, h = 128, 88
    img = new(w, h)
    soft_blob(img, S(68), S(48), S(54), S(36), "#000000", 90, 5 * SS)
    body = [(18, 14), (70, 12), (96, 16), (114, 28), (120, 44), (114, 60), (100, 70), (80, 74), (18, 74)]
    paint_shape(img, SP(body), "#121014", seed, outline=(60, 50, 44), ow=1.6, wob=0.25, tex=0.08, light=(0.3, -1, 0.6))
    # the open lid: a lighter plane with the prop stick, strings glinting beneath
    lid = [(24, 18), (68, 16), (92, 20), (108, 30), (112, 44)]
    line(img, [S(*p) for p in lid], "#3a3438", 2.0 * SS, 230)
    for k in range(9):
        y = 24 + k * 5.5
        line(img, [(S(30), S(y)), (S(100 - abs(k - 4) * 4), S(y + 2))], "#c9a24e", 0.7 * SS, 120)
    soft_blob(img, S(60), S(30), S(26), S(6), "#ffffff", 50, 2 * SS)
    # keyboard
    paint_shape(img, SP(rrect_pts(12, 16, 22, 72, 1.5)), "#efe8d6", seed + 1, outline=OUT, ow=1.0, wob=0.05, tex=0.05)
    d = ImageDraw.Draw(img)
    for y in range(18, 71, 3):
        d.line([(S(12.5), S(y)), (S(21.5), S(y))], fill=rgba("#9a9488"), width=1)
    for y in range(19, 70, 6):
        d.rectangle([S(12.5), S(y), S(17), S(y + 1.6)], fill=rgba("#141414"))
    # bench
    paint_shape(img, SP(rrect_pts(1, 30, 9, 58, 2)), "#2a1a12", seed + 2, outline=OUT, ow=1.0, wob=0.1, tex=0.2, light=(0.3, -1, 0.5))
    return finish(grain(img, 2, seed), w, h)


def bandstand(seed=51):
    """A low bandstand along a wall (right edge), its curved front to the left: carpet, a drum, music stands."""
    w, h = 128, 240
    img = new(w, h)
    soft_blob(img, S(70), S(120), S(58), S(112), "#000000", 80, 5 * SS)
    pts = [(126, 4)] + [(70 + math.cos(t) * 64, 120 - math.sin(t) * 114)
                        for t in np.linspace(math.pi * 0.5, math.pi * 1.5, 24)] + [(126, 236)]
    paint_shape(img, SP(pts), "#4a2c1a", seed, outline=OUT, ow=1.8, wob=0.3, tex=0.2, strokes_n=20,
                stroke_cols=["#5a3620", "#3a2214"], light=(-1, -0.3, 0.3))
    inner = [(124, 14)] + [(72 + math.cos(t) * 54, 120 - math.sin(t) * 104)
                           for t in np.linspace(math.pi * 0.5, math.pi * 1.5, 24)] + [(124, 226)]
    paint_shape(img, SP(inner), "#6a1e24", seed + 1, outline=None, wob=0.3, tex=0.3, strokes_n=12,
                stroke_cols=["#7e2a2e", "#521418"], light=(-1, -0.3, 0.3))
    # a drum kit and two music stands
    paint_shape(img, SP(ellipse_pts(98, 200, 13, 13)), "#d8d0bc", seed + 2, outline=OUT, ow=1.2, wob=0.1, light=(0.3, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(98, 200, 9, 9)), "#9a2c2a", seed + 3, outline=None, wob=0.1)
    paint_shape(img, SP(ellipse_pts(80, 186, 7, 7)), "#c9a24e", seed + 4, outline=OUT, ow=0.8, wob=0.05, light=(0.3, -1, 0.6))
    for y in (52, 166):
        paint_shape(img, SP(rrect_pts(64, y - 7, 70, y + 7, 1)), "#1c1c1e", seed + y, outline=OUT, ow=0.8, wob=0.05)
        paint_shape(img, SP(rrect_pts(71, y - 6, 74, y + 6, 0.5)), "#ece6d6", seed + y + 1, outline=None, wob=0.05)
    return finish(grain(img, 3, seed), w, h)


def palm(seed=53):
    """Potted palm from above: fronds radiating from a brass pot."""
    w = h = 72
    img = new(w, h)
    soft_blob(img, S(38), S(39), S(26), S(26), "#000000", 70, 3 * SS)
    paint_shape(img, SP(ellipse_pts(36, 36, 11, 11)), BRASS, seed, outline=OUT, ow=1.0, wob=0.1, light=(0.4, -1, 0.5))
    rnd = random.Random(seed)
    for k in range(9):
        a = k * 2 * math.pi / 9 + rnd.uniform(-0.2, 0.2)
        L = rnd.uniform(24, 32)
        tip = (36 + math.cos(a) * L, 36 + math.sin(a) * L)
        side = (math.cos(a + math.pi / 2), math.sin(a + math.pi / 2))
        mid = (36 + math.cos(a) * L * 0.55, 36 + math.sin(a) * L * 0.55)
        leaf = [(36, 36), (mid[0] + side[0] * 6, mid[1] + side[1] * 6), tip, (mid[0] - side[0] * 6, mid[1] - side[1] * 6)]
        paint_shape(img, SP(leaf), rnd.choice(["#3c6a34", "#4a7a3a", "#33592c"]), seed + k, outline=OUT, ow=0.8, wob=0.3,
                    tex=0.2, light=(0.3, -1, 0.5))
        line(img, [S(36, 36), S(*tip)], "#24401f", 0.8 * SS, 200)
    return finish(img, w, h)


def door(seed=55):
    """A door leaf seen from above, hinge at the left end, brass knob near the right end."""
    w, h = 64, 12
    img = new(w, h)
    paint_shape(img, SP(rrect_pts(1, 2, 63, 10, 1)), "#5a3320", seed, outline=OUT, ow=1.0, wob=0.1, tex=0.25, light=(0.2, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(56, 6, 2.2, 2.2)), BRASS, seed + 1, outline=None, wob=0.02)
    return finish(img, w, h)


ASSETS = {
    "interiors/floor_parquet": floor_parquet,
    "interiors/bar_counter": bar_counter,
    "interiors/back_bar": back_bar,
    "interiors/stool": stool,
    "interiors/table_club": table_club,
    "interiors/piano": piano,
    "interiors/bandstand": bandstand,
    "interiors/palm": palm,
    "interiors/door": door,
}
