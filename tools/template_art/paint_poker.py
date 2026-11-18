"""M010: the Copper Owl's back-room card game.

On screen (drawn by the game's card table, screen px):
ui/card_face   - a blank playing card face, aged cream with a thin border (the
                 game prints the rank and the suit pips on it).
ui/card_back   - the back of the house deck: oxblood with a brass Art Deco fan.
ui/suit_spades, ui/suit_hearts, ui/suit_diamonds, ui/suit_clubs - pips.
ui/poker_chip  - a clay chip from above, light grey (tinted by the game for
                 its value) with its edge spots.
ui/dealer_button - the ivory dealer's button.
ui/poker_felt  - the table on screen: green baize in a padded oval rail.

In the room (seen from straight above, like the other interiors):
interiors/poker_table - the round card table: baize, a rail, chips, cards,
                 an ashtray and glasses (the chairs are separate).
interiors/chair - a bentwood chair, its back at the top.
interiors/sideboard - bottles, glasses and a cigar box on a dark sideboard
                 (wall side at the top).
interiors/floor_carpet - a worn wine-red carpet with a faded diamond pattern (seamless).
interiors/smoke - a soft drift of cigar smoke hanging over the table."""
import math
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from paintkit import *

OUT = (24, 18, 15)
INK = "#1c1a1e"
RED_INK = "#a3201e"
BRASS = "#c9a24e"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"


# ------------------------------------------------------------------ on screen

def card_face(seed=301):
    w, h = 72, 100
    img = new(w, h)
    paint_shape(img, SP(rrect_pts(2, 2, w - 2, h - 2, 7)), "#efe6cf", seed, outline=(70, 58, 44), ow=1.2, wob=0.05,
                tex=0.08, light=(-0.3, -1, 0.12))
    # age: a faint warm edge and a few foxing spots
    soft_blob(img, S(w / 2), S(h / 2), S(w / 2 - 3), S(h / 2 - 3), "#efe6cf", 0, 1)
    rnd = random.Random(seed)
    for k in range(5):
        soft_blob(img, S(rnd.uniform(8, w - 8)), S(rnd.uniform(8, h - 8)), S(rnd.uniform(1, 2.5)), S(rnd.uniform(1, 2.5)),
                  "#c8b48a", 60, 1.2 * SS)
    line(img, [S(6, 6), S(w - 6, 6), S(w - 6, h - 6), S(6, h - 6), S(6, 6)], "#b9a77e", 0.8 * SS, 140)
    return finish(img, w, h)


def card_back(seed=303):
    w, h = 72, 100
    img = new(w, h)
    paint_shape(img, SP(rrect_pts(2, 2, w - 2, h - 2, 7)), "#efe6cf", seed, outline=(70, 58, 44), ow=1.2, wob=0.05, tex=0.06)
    paint_shape(img, SP(rrect_pts(7, 7, w - 7, h - 7, 4)), "#6a1c1e", seed + 1, outline=None, wob=0.05, tex=0.2,
                light=(-0.3, -1, 0.25))
    cx, cy = w / 2, h / 2
    # an Art Deco sunburst fan, top and bottom, and a diamond in the middle
    for half in (-1, 1):
        bx, by = cx, cy + half * 38
        for k in range(9):
            a = math.pi * (0.15 + 0.7 * k / 8)
            ex, ey = bx + math.cos(a) * 22, by - half * math.sin(a) * 22
            line(img, [S(bx, by), S(ex, ey)], BRASS, 0.9 * SS, 200)
    pts = [(cx, cy - 16), (cx + 11, cy), (cx, cy + 16), (cx - 11, cy)]
    paint_shape(img, SP(pts), BRASS, seed + 2, outline=(70, 50, 20), ow=0.8, wob=0.05, tex=0.15)
    pts2 = [(cx, cy - 9), (cx + 6, cy), (cx, cy + 9), (cx - 6, cy)]
    paint_shape(img, SP(pts2), "#6a1c1e", seed + 3, outline=None, wob=0.05, tex=0.1)
    line(img, [S(9, 9), S(w - 9, 9), S(w - 9, h - 9), S(9, h - 9), S(9, 9)], BRASS, 0.7 * SS, 170)
    return finish(grain(img, 3, seed), w, h)


def _heart(cx, cy, r):
    pts = []
    for t in np.linspace(0, 2 * math.pi, 64, endpoint=False):
        x = 16 * math.sin(t) ** 3
        y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
        pts.append((cx + x * r / 17, cy + y * r / 17 - r * 0.05))
    return pts


def suit(kind, seed):
    w = h = 48
    img = new(w, h)
    c = 24
    if kind == "hearts":
        paint_shape(img, SP(_heart(c, c, 19)), RED_INK, seed, outline=None, wob=0.05, tex=0.1)
    elif kind == "diamonds":
        paint_shape(img, SP([(c, 3), (c + 16, c), (c, h - 3), (c - 16, c)]), RED_INK, seed, outline=None, wob=0.05, tex=0.1)
    elif kind == "spades":
        flipped = [(x, 2 * c - y + 4) for x, y in _heart(c, c, 19)]
        paint_shape(img, SP(flipped), INK, seed, outline=None, wob=0.05, tex=0.08)
        paint_shape(img, SP([(c - 2.5, c + 6), (c + 2.5, c + 6), (c + 8, h - 3), (c - 8, h - 3)]), INK, seed + 1,
                    outline=None, wob=0.02, tex=0.0)
    else:  # clubs
        for (dx, dy) in ((0, -9), (-10, 5), (10, 5)):
            paint_shape(img, SP(ellipse_pts(c + dx, c + dy - 2, 9.5, 9.5)), INK, seed + dx, outline=None, wob=0.03, tex=0.08)
        paint_shape(img, SP(ellipse_pts(c, c, 6, 6)), INK, seed + 5, outline=None, wob=0.02, tex=0.0)  # no gap in the middle
        paint_shape(img, SP([(c - 2.5, c + 2), (c + 2.5, c + 2), (c + 8, h - 3), (c - 8, h - 3)]), INK, seed + 1,
                    outline=None, wob=0.02, tex=0.0)
    return finish(img, w, h)


def poker_chip(seed=311):
    w = h = 48
    img = new(w, h)
    c = 24
    soft_blob(img, S(c + 1), S(c + 2), S(21), S(21), "#000000", 90, 1.5 * SS)
    paint_shape(img, SP(ellipse_pts(c, c, 21, 21)), "#e4e0d6", seed, outline=(40, 34, 30), ow=1.2, wob=0.05, tex=0.08,
                light=(-0.4, -1, 0.3))
    for k in range(8):  # the edge spots
        a = k * math.pi / 4 + 0.2
        x, y = c + math.cos(a) * 17, c + math.sin(a) * 17
        paint_shape(img, SP(rrect_pts(x - 2.6, y - 3.6, x + 2.6, y + 3.6, 1)), "#fbf8f0", seed + k, outline=None, wob=0.02)
    paint_shape(img, SP(ellipse_pts(c, c, 12, 12)), "#cfc9bc", seed + 20, outline=(90, 80, 70), ow=0.7, wob=0.03, tex=0.05)
    paint_shape(img, SP(ellipse_pts(c, c, 9, 9)), "#d9d3c6", seed + 21, outline=None, wob=0.03, tex=0.05, light=(0.4, 1, 0.2))
    return finish(img, w, h)


def dealer_button(seed=313):
    w = h = 48
    img = new(w, h)
    c = 24
    soft_blob(img, S(c + 1), S(c + 2), S(21), S(21), "#000000", 100, 1.5 * SS)
    paint_shape(img, SP(ellipse_pts(c, c, 21, 21)), "#efe8d4", seed, outline=(60, 48, 34), ow=1.3, wob=0.04, tex=0.08,
                light=(-0.4, -1, 0.35))
    line(img, [S(*p) for p in ellipse_pts(c, c, 17, 17)] + [S(*ellipse_pts(c, c, 17, 17)[0])], "#9a7a3a", 0.9 * SS, 200)
    text(img, (c, c), "D", 22, "#2a2018", font=FONT)
    return finish(img, w, h)


def poker_felt(seed=321):
    """The card table on screen: an oval of green baize in a padded leather rail with a brass inlay."""
    w, h = 960, 440
    img = new(w, h)
    cx, cy = w / 2, h / 2
    soft_blob(img, S(cx), S(cy + 10), S(cx - 8), S(cy - 6), "#000000", 140, 12 * SS)
    paint_shape(img, SP(ellipse_pts(cx, cy, cx - 12, cy - 12, n=120)), "#3a2216", seed, outline=OUT, ow=2.0, wob=0.2,
                tex=0.25, strokes_n=60, stroke_cols=["#4a2c1c", "#2c1810"], light=(-0.2, -1, 0.35))
    paint_shape(img, SP(ellipse_pts(cx, cy, cx - 44, cy - 42, n=120)), "#24543a", seed + 1, outline=(16, 30, 20), ow=1.6,
                wob=0.15, tex=0.22, strokes_n=90, stroke_cols=["#2c6244", "#1e4630"], light=(-0.1, -1, 0.25), inner_shadow=0.45)
    line(img, [S(*p) for p in ellipse_pts(cx, cy, cx - 70, cy - 66, n=120)] + [S(*ellipse_pts(cx, cy, cx - 70, cy - 66, n=120)[0])],
         BRASS, 1.2 * SS, 110)
    # a betting line round the middle and a little wear where the elbows go
    rnd = random.Random(seed)
    for k in range(10):
        a = rnd.uniform(0, 2 * math.pi)
        soft_blob(img, S(cx + math.cos(a) * (cx - 90)), S(cy + math.sin(a) * (cy - 80)), S(30), S(14), "#3c6e50", 50, 6 * SS)
    return finish(grain(img, 3, seed), w, h)


# ------------------------------------------------------------------ in the room

def poker_table(seed=331):
    w = h = 160
    img = new(w, h)
    cx = cy = 80
    soft_blob(img, S(cx + 3), S(cy + 5), S(62), S(62), "#000000", 100, 6 * SS)
    paint_shape(img, SP(ellipse_pts(cx, cy, 60, 60, n=96)), "#3a2216", seed, outline=OUT, ow=1.6, wob=0.15, tex=0.25,
                light=(0.3, -1, 0.35))
    paint_shape(img, SP(ellipse_pts(cx, cy, 50, 50, n=96)), "#24543a", seed + 1, outline=(16, 30, 20), ow=1.2, wob=0.15,
                tex=0.25, strokes_n=30, stroke_cols=["#2c6244", "#1e4630"], light=(0.3, -1, 0.3), inner_shadow=0.4)
    rnd = random.Random(seed)
    # community cards in the middle, a pot of chips beside them
    for k in range(5):
        x = cx - 20 + k * 8
        paint_shape(img, SP(rrect_pts(x, cy - 7, x + 7, cy + 3, 0.8)), "#f2ecdc", seed + 10 + k, outline=OUT, ow=0.5, wob=0.03)
    for k in range(9):
        a = rnd.uniform(0, 2 * math.pi)
        r = rnd.uniform(0, 5)
        paint_shape(img, SP(ellipse_pts(cx + 4 + math.cos(a) * r, cy + 12 + math.sin(a) * r, 2.6, 2.6)),
                    rnd.choice(["#b02a2a", "#e8e0cf", "#2a4a9a", "#2a6a3a"]), seed + 20 + k, outline=OUT, ow=0.4, wob=0.02)
    # each place: a little stack of chips and two cards; an ashtray and glasses on the rail
    for k, a in enumerate((math.pi * 0.5, math.pi, math.pi * 1.5, 0.0)):
        px, py = cx + math.cos(a) * 36, cy + math.sin(a) * 36
        for j in range(3):
            paint_shape(img, SP(ellipse_pts(px + math.cos(a + 1.4) * 7 + j * 0.6, py + math.sin(a + 1.4) * 7 - j * 0.8, 2.6, 2.6)),
                        ["#b02a2a", "#e8e0cf", "#2a4a9a"][j], seed + 40 + k * 3 + j, outline=OUT, ow=0.4, wob=0.02)
        paint_shape(img, SP(rrect_pts(px - 4, py - 4, px + 3, py + 5, 0.8)), "#6a1c1e", seed + 50 + k, outline=OUT, ow=0.5, wob=0.03)
        gx, gy = cx + math.cos(a - 0.5) * 54, cy + math.sin(a - 0.5) * 54
        paint_shape(img, SP(ellipse_pts(gx, gy, 3.4, 3.4)), "#c9a35a" if k % 2 else "#b9cfd6", seed + 60 + k,
                    outline=(60, 50, 40), ow=0.6, wob=0.03)
        soft_blob(img, S(gx - 1), S(gy - 1), S(1.2), S(1.2), "#ffffff", 140, 0.5 * SS)
    ax, ay = cx + 38, cy - 40
    paint_shape(img, SP(ellipse_pts(ax, ay, 6, 6)), "#5a5a60", seed + 70, outline=OUT, ow=0.7, wob=0.03, light=(0.3, -1, 0.4))
    line(img, [S(ax - 2, ay), S(ax + 6, ay - 4)], "#6a4a2a", 1.6 * SS, 255)  # a cigar on the ashtray
    soft_blob(img, S(ax + 6), S(ay - 4), S(1.2), S(1.2), "#ff8a3a", 220, 0.4 * SS)
    return finish(grain(img, 3, seed), w, h)


def chair(seed=341):
    """A bentwood chair from above, its back at the top (the game turns it)."""
    w = h = 36
    img = new(w, h)
    c = 18
    soft_blob(img, S(c + 1), S(c + 2), S(11), S(11), "#000000", 80, 2 * SS)
    paint_shape(img, SP(ellipse_pts(c, c + 2, 10, 10)), "#4a2c1a", seed, outline=OUT, ow=1.1, wob=0.1, tex=0.2, light=(0.3, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(c, c + 2, 7, 7)), "#6e2a22", seed + 1, outline=None, wob=0.1, tex=0.2)
    back = [(c + math.cos(t) * 12, c + 2 + math.sin(t) * 12) for t in np.linspace(math.pi * 1.15, math.pi * 1.85, 9)]
    line(img, [S(*p) for p in back], "#3a2214", 3.2 * SS, 255)
    return finish(img, w, h)


def sideboard(seed=343):
    w, h = 112, 40
    img = new(w, h)
    soft_blob(img, S(w / 2), S(22), S(w / 2 - 4), S(16), "#000000", 80, 3 * SS)
    paint_shape(img, SP(rrect_pts(3, 4, w - 3, 34, 2)), "#3a2014", seed, outline=OUT, ow=1.3, wob=0.1, tex=0.25,
                strokes_n=14, stroke_cols=["#4a2a1a", "#2c160e"], light=(0.3, -1, 0.35))
    rnd = random.Random(seed)
    for k in range(5):  # bottles from above: a round shoulder and a neck
        x = 14 + k * 12 + rnd.uniform(-1, 1)
        col = rnd.choice(["#4a2a12", "#2e4a26", "#6a4a1a", "#b9cfd6"])
        paint_shape(img, SP(ellipse_pts(x, 17, 4.4, 4.4)), col, seed + k, outline=OUT, ow=0.6, wob=0.04, light=(0.3, -1, 0.5))
        paint_shape(img, SP(ellipse_pts(x, 17, 1.6, 1.6)), "#c9a24e", seed + 10 + k, outline=None, wob=0.02)
    for k in range(3):
        gx = 76 + k * 8
        paint_shape(img, SP(ellipse_pts(gx, 24, 3.2, 3.2)), "#b9cfd6", seed + 20 + k, outline=(60, 70, 74), ow=0.6, wob=0.03)
    paint_shape(img, SP(rrect_pts(92, 9, 108, 20, 1)), "#7a4a24", seed + 30, outline=OUT, ow=0.6, wob=0.04)  # cigar box
    line(img, [S(93, 14), S(107, 14)], "#e0c070", 0.8 * SS, 200)
    return finish(grain(img, 3, seed), w, h)


def floor_carpet(seed=351):
    """Worn wine-red carpet with a faded diamond lattice (seamless, 32 px cells)."""
    w = h = 256
    img = new(w, h, "#4a1a1c")
    d = ImageDraw.Draw(img)
    cell = 32
    for y in range(0, h + cell, cell):
        for x in range(0, w + cell, cell):
            pts = [(x, y - cell / 2), (x + cell / 2, y), (x, y + cell / 2), (x - cell / 2, y)]
            d.polygon([(S(px), S(py)) for px, py in pts], outline=rgba("#6e3a2a", 160))
            d.ellipse([S(x - 2), S(y - 2), S(x + 2), S(y + 2)], fill=rgba("#8a5a34", 140))
    n = tnoise(w * SS, h * SS, 4, seed + 1, octaves=4)
    img = modulate(img, n, 0.35)
    # wear: lighter, flattened paths
    wear = tnoise(w * SS, h * SS, 2, seed + 3, octaves=2)
    a = np.asarray(img, dtype=np.float32).copy()
    s = np.clip((wear - 0.55) * 2.2, 0, 1)
    a[..., :3] += s[..., None] * np.array([22, 12, 10], dtype=np.float32)
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    return finish(grain(img, 5, seed), w, h)


def smoke(seed=361):
    w = h = 128
    img = new(w, h)
    rnd = random.Random(seed)
    for k in range(14):
        a = rnd.uniform(0, 2 * math.pi)
        r = rnd.uniform(0, 30)
        soft_blob(img, S(64 + math.cos(a) * r), S(64 + math.sin(a) * r), S(rnd.uniform(14, 26)), S(rnd.uniform(8, 16)),
                  "#c8c4bc", rnd.randint(14, 30), 7 * SS, rot=rnd.uniform(0, math.pi))
    return finish(img, w, h)


ASSETS = {
    "ui/card_face": card_face,
    "ui/card_back": card_back,
    "ui/suit_spades": lambda: suit("spades", 371),
    "ui/suit_hearts": lambda: suit("hearts", 373),
    "ui/suit_diamonds": lambda: suit("diamonds", 375),
    "ui/suit_clubs": lambda: suit("clubs", 377),
    "ui/poker_chip": poker_chip,
    "ui/dealer_button": dealer_button,
    "ui/poker_felt": poker_felt,
    "interiors/poker_table": poker_table,
    "interiors/chair": chair,
    "interiors/sideboard": sideboard,
    "interiors/floor_carpet": floor_carpet,
    "interiors/smoke": smoke,
}
