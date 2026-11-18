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


# ------------------------------------------------------------------ Sal's Barber Shop

def floor_tile(seed=61):
    """Small black-and-cream checkerboard tile, the barbershop classic (seamless)."""
    w = h = 128
    img = new(w, h)
    d = ImageDraw.Draw(img)
    rnd = random.Random(seed)
    cell = 16
    for y in range(0, h, cell):
        for x in range(0, w, cell):
            dark = ((x + y) // cell) % 2 == 0
            col = rnd.choice(["#3a3632", "#403b36"]) if dark else rnd.choice(["#b9af9b", "#b3a994", "#bdb4a1"])
            d.rectangle([S(x), S(y), S(x + cell) - 1, S(y + cell) - 1], fill=rgba(col))
            d.rectangle([S(x), S(y), S(x + cell) - 1, S(y + cell) - 1], outline=rgba("#1c1a18", 120), width=1)
    n = tnoise(w * SS, h * SS, 3, seed + 1, octaves=3)
    img = modulate(img, n, 0.2)
    # a little wear and a wet-mop sheen
    sheen = tnoise(w * SS, h * SS, 2, seed + 4, octaves=2)
    a = np.asarray(img, dtype=np.float32).copy()
    s2 = np.clip((sheen - 0.55) * 2.5, 0, 1)
    a[..., :3] += s2[..., None] * 12
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    return finish(grain(img, 4, seed), w, h)


def barber_chair(seed=63):
    """A barber chair from above, the sitter facing right: leather seat, chrome arms, headrest at the left, footrest at the right."""
    w, h = 72, 56
    img = new(w, h)
    soft_blob(img, S(37), S(30), S(30), S(22), "#000000", 80, 3 * SS)
    paint_shape(img, SP(rrect_pts(52, 18, 68, 38, 3)), "#b9bcbf", seed, outline=OUT, ow=1.0, wob=0.1, light=(0.4, -1, 0.5))
    paint_shape(img, SP(rrect_pts(14, 10, 56, 46, 8)), "#c9ccce", seed + 1, outline=OUT, ow=1.4, wob=0.15, light=(0.4, -1, 0.5))
    paint_shape(img, SP(rrect_pts(18, 15, 52, 41, 7)), "#7a2a22", seed + 2, outline=OUT, ow=1.0, wob=0.2, tex=0.25,
                light=(0.4, -1, 0.5), inner_shadow=0.3)
    paint_shape(img, SP(rrect_pts(4, 20, 16, 36, 4)), "#7a2a22", seed + 3, outline=OUT, ow=1.0, wob=0.1, tex=0.2)
    line(img, [(S(22), S(28)), (S(48), S(28))], "#5a1c16", 1.0 * SS, 180)
    soft_blob(img, S(30), S(20), S(9), S(3), "#ffffff", 60, 1 * SS)
    return finish(img, w, h)


def barber_counter(seed=65):
    """The mirror wall above a marble counter with tonics, combs and a jar of blue Barbicide (wall side top)."""
    w, h = 336, 44
    img = new(w, h)
    soft_blob(img, S(w / 2), S(26), S(w / 2 - 6), S(14), "#000000", 70, 3 * SS)
    paint_shape(img, SP(rrect_pts(2, 2, w - 2, 12, 2)), "#9fb3bd", seed, outline=OUT, ow=1.2, wob=0.1, tex=0.1, light=(0, 1, 0.4))
    soft_blob(img, S(w * 0.3), S(6), S(40), S(2), "#ffffff", 90, 1 * SS)
    paint_shape(img, SP(rrect_pts(4, 11, w - 4, 38, 3)), "#e2ddd2", seed + 1, outline=OUT, ow=1.4, wob=0.2, tex=0.15,
                strokes_n=16, stroke_cols=["#cfc8ba", "#f0ece2"], light=(0, -1, 0.3))
    rnd = random.Random(seed)
    for x in range(20, w - 20, 22):
        kind = rnd.random()
        if kind < 0.45:
            c = rnd.choice(["#7a9a4a", "#b5651d", "#c9b26a", "#6a3a7a"])
            paint_shape(img, SP(ellipse_pts(x, 22, 3.6, 3.6)), c, x, outline=OUT, ow=0.7, wob=0.05)
            soft_blob(img, S(x - 1), S(21), S(1.2), S(1.2), "#ffffff", 140, 0.4 * SS)
        elif kind < 0.65:
            line(img, [(S(x - 6), S(28)), (S(x + 6), S(26))], "#2a2a2a", 1.6 * SS, 230)
        elif kind < 0.8:
            paint_shape(img, SP(rrect_pts(x - 5, 18, x + 5, 30, 2)), "#4a8ab0", x, outline=OUT, ow=0.8, wob=0.05, tex=0.05)
        else:
            paint_shape(img, SP(ellipse_pts(x, 24, 5, 3)), "#f4f0e6", x, outline=OUT, ow=0.6, wob=0.1)
    return finish(grain(img, 3, seed), w, h)


def bench(seed=67):
    """A slatted waiting bench from above, wall side at the top, with a folded newspaper."""
    w, h = 160, 40
    img = new(w, h)
    soft_blob(img, S(w / 2), S(22), S(w / 2 - 6), S(14), "#000000", 70, 3 * SS)
    paint_shape(img, SP(rrect_pts(4, 4, w - 4, 34, 3)), "#5a3a22", seed, outline=OUT, ow=1.4, wob=0.2, tex=0.2, light=(0, -1, 0.3))
    for y in (11, 18, 25):
        line(img, [(S(8), S(y)), (S(w - 8), S(y))], "#3a2414", 1.0 * SS, 200)
    paint_shape(img, SP(rrect_pts(100, 12, 126, 30, 1)), "#e6e0cf", seed + 1, outline=OUT, ow=0.7, wob=0.1, tex=0.05)
    for k in range(4):
        line(img, [(S(103), S(16 + k * 3.5)), (S(123), S(16 + k * 3.5))], "#55524c", 0.8 * SS, 160)
    return finish(img, w, h)


def cabinet(seed=69):
    """A tall cupboard seen from above (wall side at the top): dark wood top, a fold of cloth."""
    w, h = 64, 52
    img = new(w, h)
    soft_blob(img, S(33), S(28), S(28), S(22), "#000000", 80, 3 * SS)
    paint_shape(img, SP(rrect_pts(4, 4, 60, 46, 2)), "#4a2e1c", seed, outline=OUT, ow=1.4, wob=0.15, tex=0.25,
                strokes_n=10, stroke_cols=["#5a3a24", "#3a2214"], light=(0.3, -1, 0.4))
    line(img, [(S(8), S(10)), (S(56), S(10))], "#6a4630", 1.2 * SS, 200)
    paint_shape(img, SP([(12, 20), (40, 18), (44, 34), (14, 36)]), "#d8d0b8", seed + 1, outline=OUT, ow=0.6, wob=0.3, tex=0.1)
    return finish(img, w, h)


def coat_rack(seed=71):
    w = h = 40
    img = new(w, h)
    soft_blob(img, S(21), S(21), S(14), S(14), "#000000", 70, 2 * SS)
    for k, c in enumerate(("#3a3a40", "#5a4a32")):
        a = k * 2.4
        paint_shape(img, SP(ellipse_pts(20 + math.cos(a) * 7, 20 + math.sin(a) * 7, 8, 6, rot=a)), c, seed + k, outline=OUT,
                    ow=1.0, wob=0.2, tex=0.2, light=(0.3, -1, 0.4))
    paint_shape(img, SP(ellipse_pts(20, 20, 4, 4)), "#4a2e1c", seed + 5, outline=OUT, ow=0.8, wob=0.05)
    return finish(img, w, h)


# ------------------------------------------------------------------ Novak's Grocery, Lindqvist Hardware

def floor_boards(seed=81):
    """Worn pine floorboards running left-right, scuffed paths and knots (seamless)."""
    w = h = 256
    img = new(w, h, "#6a5034")
    d = ImageDraw.Draw(img)
    rnd = random.Random(seed)
    board = 16
    for y in range(0, h, board):
        x = rnd.uniform(-120, 0)
        while x < w:
            L = rnd.uniform(70, 150)
            c = rgba(rnd.choice(["#7a5c3a", "#6e5233", "#836240", "#735737"]))
            for ox in (-w, 0, w):
                d.rectangle([S(x + ox), S(y), S(x + L + ox) - 1, S(y + board) - 1], fill=c)
                d.line([(S(x + ox), S(y)), (S(x + ox), S(y + board))], fill=rgba("#3a2a1a", 200), width=SS)
            for g in range(3):
                gy = y + rnd.uniform(3, board - 3)
                d.line([(S(x + 2), S(gy)), (S(x + L - 2), S(gy + rnd.uniform(-1, 1)))], fill=shade(c, 0.85), width=1)
            if rnd.random() < 0.25:
                kx = x + rnd.uniform(10, L - 10)
                d.ellipse([S(kx - 2.5), S(y + 5), S(kx + 2.5), S(y + 10)], fill=rgba("#4a321e"))
            x += L
        d.line([(0, S(y)), (S(w), S(y))], fill=rgba("#2e2014", 220), width=SS)
    n = tnoise(w * SS, h * SS, 3, seed + 1, octaves=4)
    img = modulate(img, n, 0.3)
    return finish(grain(img, 5, seed), w, h)


def shop_counter(seed=83):
    """A shop counter from above (wall side, where the shopkeeper stands, at the top): worn wood, a brass
    cash register at the left, a scale and a roll of brown paper at the right."""
    w, h = 220, 56
    img = new(w, h)
    soft_blob(img, S(w / 2), S(h / 2 + 3), S(w / 2 - 6), S(h / 2 - 6), "#000000", 80, 4 * SS)
    paint_shape(img, SP(rrect_pts(4, 6, w - 4, h - 6, 4)), "#7a5634", seed, outline=OUT, ow=1.6, wob=0.2, tex=0.25,
                strokes_n=16, stroke_cols=["#8a6440", "#664628"], light=(0, -1, 0.3), inner_shadow=0.25)
    paint_shape(img, SP(rrect_pts(14, 12, 54, 44, 4)), BRASS, seed + 1, outline=OUT, ow=1.2, wob=0.15, tex=0.15, light=(0.3, -1, 0.5))
    for k in range(4):
        for j in range(2):
            paint_shape(img, SP(ellipse_pts(22 + k * 8, 30 + j * 7, 2.4, 2.4)), "#efe6cc", seed + 2 + k + j * 5, outline=OUT, ow=0.5, wob=0.02)
    paint_shape(img, SP(rrect_pts(20, 14, 48, 22, 1)), "#2a2a2a", seed + 20, outline=None, wob=0.05)
    paint_shape(img, SP(ellipse_pts(160, 28, 13, 13)), "#c9ccce", seed + 21, outline=OUT, ow=1.0, wob=0.1, light=(0.3, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(160, 28, 9, 9)), "#9a9ea2", seed + 22, outline=None, wob=0.1)
    paint_shape(img, SP(rrect_pts(184, 12, 204, 44, 6)), "#b08a5a", seed + 23, outline=OUT, ow=1.0, wob=0.1, tex=0.2)
    line(img, [(S(186), S(28)), (S(202), S(28))], "#8a6a40", 1.0 * SS, 200)
    return finish(grain(img, 3, seed), w, h)


def _shelf(seed, items):
    w, h = 260, 44
    img = new(w, h)
    soft_blob(img, S(w / 2), S(24), S(w / 2 - 4), S(16), "#000000", 70, 3 * SS)
    paint_shape(img, SP(rrect_pts(2, 2, w - 2, 40, 2)), "#5a3e26", seed, outline=OUT, ow=1.4, wob=0.15, tex=0.2, light=(0, 1, 0.3))
    rnd = random.Random(seed)
    x = 10.0
    while x < w - 12:
        x = items(img, rnd, x)
    return finish(grain(img, 3, seed), w, h)


def shelf_grocery(seed=85):
    """Wall shelves of tins, jars and boxes seen from above (wall side at the top)."""
    def items(img, rnd, x):
        kind = rnd.random()
        if kind < 0.5:  # a row of tins
            c = rnd.choice(["#b03a2a", "#3a6a9a", "#d8b04a", "#4a7a3a", "#c9c4b8"])
            for y in (13, 27):
                paint_shape(img, SP(ellipse_pts(x + 4, y, 4.2, 4.2)), c, int(x * 3 + y), outline=OUT, ow=0.7, wob=0.05, light=(0.3, -1, 0.5))
                paint_shape(img, SP(ellipse_pts(x + 4, y, 2.5, 2.5)), "#d6d9db", int(x * 3 + y + 1), outline=None, wob=0.02)
            return x + 10
        if kind < 0.8:  # a cardboard box
            c = rnd.choice(["#c9a46a", "#d8c49a", "#b5895a", "#e0d6bc"])
            bw = rnd.uniform(12, 20)
            paint_shape(img, SP(rrect_pts(x, 8, x + bw, 34, 1)), c, int(x * 5), outline=OUT, ow=0.8, wob=0.1, tex=0.15)
            line(img, [(S(x + 2), S(21)), (S(x + bw - 2), S(21))], "#8a6a40", 0.8 * SS, 160)
            return x + bw + 3
        c = rnd.choice(["#e8d8a8", "#c96a3a", "#8a3a5a"])  # jars
        for y in (12, 26):
            paint_shape(img, SP(ellipse_pts(x + 4, y, 3.6, 3.6)), "#b9cfd6", int(x * 7 + y), outline=OUT, ow=0.6, wob=0.05)
            paint_shape(img, SP(ellipse_pts(x + 4, y, 2.4, 2.4)), c, int(x * 7 + y + 1), outline=None, wob=0.05)
        return x + 9
    return _shelf(seed, items)


def shelf_hardware(seed=87):
    """Wall shelves of paint tins, coils of rope, boxes of nails and tools (wall side at the top)."""
    def items(img, rnd, x):
        kind = rnd.random()
        if kind < 0.35:
            c = rnd.choice(["#b02a2a", "#2a5a9a", "#e8e0cf", "#3a6a3a"])
            paint_shape(img, SP(ellipse_pts(x + 6, 20, 6, 6)), "#a9adb0", int(x * 3), outline=OUT, ow=0.8, wob=0.05, light=(0.3, -1, 0.5))
            paint_shape(img, SP(ellipse_pts(x + 6, 20, 4, 4)), c, int(x * 3 + 1), outline=None, wob=0.05)
            return x + 14
        if kind < 0.55:
            paint_shape(img, SP(ellipse_pts(x + 8, 20, 8, 8)), "#c9b07a", int(x * 5), outline=OUT, ow=0.8, wob=0.1, tex=0.3)
            paint_shape(img, SP(ellipse_pts(x + 8, 20, 3.5, 3.5)), "#5a3e26", int(x * 5 + 1), outline=None, wob=0.05)
            return x + 18
        if kind < 0.8:
            bw = rnd.uniform(10, 16)
            paint_shape(img, SP(rrect_pts(x, 9, x + bw, 32, 1)), rnd.choice(["#c9a46a", "#a87a4a"]), int(x * 7), outline=OUT, ow=0.8, wob=0.1, tex=0.2)
            return x + bw + 3
        line(img, [(S(x), S(12)), (S(x + 14), S(30))], "#3a3a3e", 2.2 * SS, 240)  # a saw or a hammer
        line(img, [(S(x + 10), S(10)), (S(x + 10), S(32))], "#7a5634", 2.0 * SS, 240)
        return x + 18
    return _shelf(seed, items)


def produce(seed=89):
    """Three crates of produce under the shop window: apples, potatoes, cabbages."""
    w, h = 132, 56
    img = new(w, h)
    soft_blob(img, S(w / 2), S(30), S(w / 2 - 4), S(22), "#000000", 70, 3 * SS)
    rnd = random.Random(seed)
    for k, (fruit, r) in enumerate((("#b8322a", 4.0), ("#a8845a", 4.5), ("#7aa84a", 6.0))):
        x0 = 4 + k * 42
        paint_shape(img, SP(rrect_pts(x0, 6, x0 + 40, 50, 1.5)), "#8a6440", seed + k, outline=OUT, ow=1.2, wob=0.2, tex=0.25)
        for j in range(14 if r < 5 else 7):
            fx = rnd.uniform(x0 + 6, x0 + 34)
            fy = rnd.uniform(11, 45)
            paint_shape(img, SP(ellipse_pts(fx, fy, r, r * 0.92)), fruit, seed + k * 20 + j, outline=OUT, ow=0.6, wob=0.15,
                        tex=0.2, light=(0.4, -1, 0.5))
    return finish(grain(img, 3, seed), w, h)


def sacks(seed=91):
    """Flour and sugar sacks slumped together."""
    w = h = 64
    img = new(w, h)
    soft_blob(img, S(33), S(34), S(24), S(22), "#000000", 70, 3 * SS)
    for k, (x, y) in enumerate(((22, 26), (40, 30), (28, 42))):
        paint_shape(img, SP(ellipse_pts(x, y, 13, 11, rot=k)), "#e2d8bc", seed + k, outline=OUT, ow=1.0, wob=0.4, tex=0.2,
                    light=(0.4, -1, 0.5))
        line(img, [(S(x - 6), S(y)), (S(x + 6), S(y))], "#8a3a2a", 1.0 * SS, 180)
    return finish(img, w, h)


def card_table(seed=93):
    """The back-room table: green baize, a hand of cards, chips, an ashtray, a bottle; two chairs."""
    w = h = 112
    img = new(w, h)
    cx = cy = 56
    soft_blob(img, S(cx + 3), S(cy + 4), S(36), S(36), "#000000", 80, 5 * SS)
    for k, a in enumerate((math.pi, 0.0)):
        chair(img, cx + math.cos(a) * 38, cy + math.sin(a) * 38, a, seed + k * 3)
    paint_shape(img, SP(ellipse_pts(cx, cy, 30, 30)), "#2f5a3a", seed + 10, outline=OUT, ow=1.6, wob=0.25, tex=0.25,
                light=(0.3, -1, 0.35), inner_shadow=0.3)
    rnd = random.Random(seed)
    for k in range(5):
        x = cx - 14 + k * 5 + rnd.uniform(-1, 1)
        y = cy + 6 + rnd.uniform(-2, 2)
        paint_shape(img, SP(rrect_pts(x, y, x + 6, y + 9, 0.8)), "#f2ecdc", seed + 20 + k, outline=OUT, ow=0.5, wob=0.05)
    for k in range(6):
        paint_shape(img, SP(ellipse_pts(cx + 12 + (k % 3) * 4, cy - 12 + (k // 3) * 4, 2.2, 2.2)),
                    rnd.choice(["#b02a2a", "#e8e0cf", "#2a4a9a"]), seed + 30 + k, outline=OUT, ow=0.4, wob=0.02)
    paint_shape(img, SP(ellipse_pts(cx - 14, cy - 12, 4, 4)), "#4a4a4e", seed + 40, outline=OUT, ow=0.6, wob=0.05)
    paint_shape(img, SP(ellipse_pts(cx + 4, cy - 16, 3.6, 3.6)), "#6a4a1a", seed + 41, outline=OUT, ow=0.6, wob=0.05)
    return finish(grain(img, 3, seed), w, h)


def gun_crate(seed=95):
    """An open long crate packed in straw: wrapped pistols and boxes of .45 rounds."""
    w, h = 112, 56
    img = new(w, h)
    soft_blob(img, S(w / 2), S(30), S(w / 2 - 4), S(22), "#000000", 80, 3 * SS)
    paint_shape(img, SP(rrect_pts(4, 6, w - 4, 50, 2)), "#7a5634", seed, outline=OUT, ow=1.4, wob=0.2, tex=0.25)
    paint_shape(img, SP(rrect_pts(9, 11, w - 9, 45, 1)), "#c9b06a", seed + 1, outline=None, wob=0.3, tex=0.4, strokes_n=20,
                stroke_cols=["#e0c880", "#a88a4a"])
    for k in range(3):
        x = 16 + k * 22
        paint_shape(img, SP(rrect_pts(x, 15, x + 18, 41, 3)), "#3a3a3e", seed + 2 + k, outline=OUT, ow=0.8, wob=0.15,
                    tex=0.2, light=(0.3, -1, 0.5))
    for k in range(2):
        paint_shape(img, SP(rrect_pts(84, 13 + k * 15, 102, 25 + k * 15, 1)), "#a8322a", seed + 9 + k, outline=OUT, ow=0.8, wob=0.05)
        line(img, [(S(86), S(19 + k * 15)), (S(100), S(19 + k * 15))], "#e8e0cf", 0.8 * SS, 200)
    return finish(grain(img, 3, seed), w, h)


# ------------------------------------------------------------------ the henchman's flat

def bed(seed=101):
    """An iron bedstead from above, headboard at the top: rumpled grey blanket, a flat pillow."""
    w, h = 76, 136
    img = new(w, h)
    soft_blob(img, S(39), S(70), S(34), S(64), "#000000", 80, 4 * SS)
    paint_shape(img, SP(rrect_pts(4, 4, 72, 132, 3)), "#2a2a2e", seed, outline=OUT, ow=1.4, wob=0.1, light=(0.3, -1, 0.4))
    paint_shape(img, SP(rrect_pts(8, 10, 68, 128, 4)), "#e2dccb", seed + 1, outline=None, wob=0.2, tex=0.15)
    paint_shape(img, SP(rrect_pts(14, 14, 62, 36, 8)), "#efe9da", seed + 2, outline=OUT, ow=1.0, wob=0.3, tex=0.1,
                light=(0.3, -1, 0.5))
    blanket = [(8, 48), (40, 44), (68, 50), (68, 128), (8, 128)]
    paint_shape(img, SP(blanket), "#5a5f68", seed + 3, outline=OUT, ow=1.2, wob=0.6, tex=0.3, strokes_n=14,
                stroke_cols=["#6a707a", "#474b52"], light=(0.3, -1, 0.4))
    line(img, [(S(10), S(52)), (S(66), S(54))], "#7a2a26", 2.0 * SS, 220)
    for k in range(3):
        line(img, [(S(18 + k * 14), S(70)), (S(24 + k * 13), S(118))], "#41454c", 1.2 * SS, 160)
    for x in (6, 70):  # iron posts
        for y in (6, 130):
            paint_shape(img, SP(ellipse_pts(x, y, 3, 3)), "#c9b06a", seed + x + y, outline=OUT, ow=0.6, wob=0.02)
    return finish(grain(img, 3, seed), w, h)


def rug(seed=103):
    """A worn oval rag rug (lies flat under everything)."""
    w, h = 160, 100
    img = new(w, h)
    rnd = random.Random(seed)
    for k, c in enumerate(["#6a3a2a", "#8a6a3a", "#4a5a6a", "#7a2a2a", "#9a8a5a", "#5a4a3a"]):
        f = 1.0 - k * 0.15
        paint_shape(img, SP(ellipse_pts(80, 50, 76 * f, 46 * f)), c, seed + k, outline=None if k else OUT, ow=1.0,
                    wob=0.4, tex=0.35, strokes_n=8, stroke_cols=[shade(c, 1.2), shade(c, 0.8)])
    return finish(grain(img, 5, seed), w, h)


def flat_table(seed=105):
    """A small kitchen table with an oilcloth, two chairs, a bottle, a glass and the Tribune."""
    w = h = 112
    img = new(w, h)
    cx = cy = 56
    soft_blob(img, S(cx + 3), S(cy + 4), S(36), S(34), "#000000", 70, 5 * SS)
    for k, a in enumerate((math.pi * 0.5, math.pi * 1.5)):
        chair(img, cx + math.cos(a) * 36, cy + math.sin(a) * 36, a, seed + k * 3)
    paint_shape(img, SP(rrect_pts(28, 32, 84, 80, 3)), "#a8b8a0", seed + 10, outline=OUT, ow=1.4, wob=0.2, tex=0.15,
                light=(0.3, -1, 0.35))
    d = ImageDraw.Draw(img)
    for x in range(32, 84, 8):  # gingham
        d.line([(S(x), S(33)), (S(x), S(79))], fill=rgba("#c94a3a", 70), width=2 * SS)
    for y in range(36, 80, 8):
        d.line([(S(29), S(y)), (S(83), S(y))], fill=rgba("#c94a3a", 70), width=2 * SS)
    paint_shape(img, SP(rrect_pts(36, 44, 60, 62, 1)), "#e6e0cf", seed + 11, outline=OUT, ow=0.7, wob=0.1)
    for k in range(4):
        line(img, [(S(39), S(48 + k * 3.5)), (S(57), S(48 + k * 3.5))], "#55524c", 0.8 * SS, 160)
    paint_shape(img, SP(ellipse_pts(70, 46, 4.6, 4.6)), "#6a4a1a", seed + 12, outline=OUT, ow=0.6, wob=0.05)
    paint_shape(img, SP(ellipse_pts(70, 46, 1.8, 1.8)), "#d8c08a", seed + 13, outline=None, wob=0.02)
    paint_shape(img, SP(ellipse_pts(72, 66, 3.2, 3.2)), "#b9cfd6", seed + 14, outline=OUT, ow=0.6, wob=0.05)
    return finish(grain(img, 3, seed), w, h)


def stove(seed=107):
    """A small black kitchen range from above with a kettle (wall side at the top)."""
    w, h = 60, 56
    img = new(w, h)
    soft_blob(img, S(31), S(30), S(26), S(24), "#000000", 80, 3 * SS)
    paint_shape(img, SP(rrect_pts(4, 4, 56, 52, 3)), "#25252a", seed, outline=OUT, ow=1.4, wob=0.1, tex=0.15, light=(0.3, -1, 0.5))
    for x, y in ((18, 20), (42, 20), (18, 40), (42, 40)):
        layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ImageDraw.Draw(layer).ellipse([S(x - 8), S(y - 8), S(x + 8), S(y + 8)], outline=rgba("#4a4a50"), width=2 * SS)
        img.alpha_composite(layer)
    paint_shape(img, SP(ellipse_pts(42, 20, 7.5, 7.5)), "#b9bcbf", seed + 1, outline=OUT, ow=0.8, wob=0.05, light=(0.4, -1, 0.6))
    line(img, [(S(36), S(14)), (S(48), S(26))], "#2a2a2e", 1.4 * SS, 220)
    return finish(grain(img, 3, seed), w, h)


def radio(seed=109):
    """A cathedral radio from above: walnut case, fabric grille towards the room (bottom), two knobs."""
    w, h = 44, 34
    img = new(w, h)
    soft_blob(img, S(23), S(18), S(19), S(14), "#000000", 70, 2 * SS)
    paint_shape(img, SP(rrect_pts(4, 4, 40, 30, 8)), "#6a3a1e", seed, outline=OUT, ow=1.2, wob=0.1, tex=0.2,
                strokes_n=6, stroke_cols=["#7e4a2a", "#5a2e16"], light=(0.3, -1, 0.5))
    paint_shape(img, SP(rrect_pts(12, 18, 32, 28, 3)), "#c9b48a", seed + 1, outline=None, wob=0.05, tex=0.3)
    for x in (16, 28):
        paint_shape(img, SP(ellipse_pts(x, 11, 2.2, 2.2)), "#d8c08a", seed + x, outline=OUT, ow=0.5, wob=0.02)
    return finish(img, w, h)


def microphone(seed=61):
    """A 1930s ribbon microphone on a tall stand, from above: the round base, the chrome
    stem seen end-on and the grille box at the top facing the singer (at the right)."""
    w = h = 48
    img = new(w, h)
    soft_blob(img, S(25), S(26), S(13), S(13), "#000000", 90, 3 * SS)
    paint_shape(img, SP(ellipse_pts(24, 24, 11, 11)), "#2a2622", seed, outline=OUT, ow=1.2, wob=0.15, tex=0.1, light=(0.3, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(24, 24, 3, 3)), "#b8b4aa", seed + 1, outline=OUT, ow=0.8, wob=0.05, light=(0.3, -1, 0.7))
    # the grille: a rounded chrome box with its slots, a little above the stand (towards the singer)
    paint_shape(img, SP(rrect_pts(27, 18, 37, 30, 2.5)), "#c9c4b8", seed + 2, outline=OUT, ow=1.1, wob=0.05, tex=0.05,
                light=(0.3, -1, 0.7))
    d = ImageDraw.Draw(img)
    for y in range(20, 29, 2):
        d.line([(S(29), S(y)), (S(35), S(y))], fill=rgba("#6a665e"), width=1)
    soft_blob(img, S(30), S(20), S(3), S(1.2), "#ffffff", 120, 0.5 * SS)
    return finish(grain(img, 2, seed), w, h)


ASSETS = {
    "interiors/microphone": microphone,
    "interiors/bed": bed,
    "interiors/rug": rug,
    "interiors/flat_table": flat_table,
    "interiors/stove": stove,
    "interiors/radio": radio,
    "interiors/floor_boards": floor_boards,
    "interiors/shop_counter": shop_counter,
    "interiors/shelf_grocery": shelf_grocery,
    "interiors/shelf_hardware": shelf_hardware,
    "interiors/produce": produce,
    "interiors/sacks": sacks,
    "interiors/card_table": card_table,
    "interiors/gun_crate": gun_crate,
    "interiors/floor_tile": floor_tile,
    "interiors/barber_chair": barber_chair,
    "interiors/barber_counter": barber_counter,
    "interiors/bench": bench,
    "interiors/cabinet": cabinet,
    "interiors/coat_rack": coat_rack,
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
