"""M012: the rooms behind closed doors (seen from straight above like the other interiors; wall side at
the top). City Hall, the aldermen's offices, the Regulars' Club, the freight dispatch office and the
storeroom in the yards, and the people who keep them.

interiors/floor_marble   - City Hall's hall: worn cream and grey marble squares (seamless).
interiors/floor_concrete - the yards' storeroom and dispatch office: stained concrete (seamless).
interiors/clerk_counter  - the night clerk's counter with its brass grille (the clerk's side at the top).
interiors/column         - a fluted stone column from above.
interiors/flag_stand     - a flag on a brass pole, furled, on its stand.
interiors/staircase      - the stairs up to the Mayor's office, a velvet rope across the foot.
interiors/records_shelf  - shelves of bound ledgers and records (wall side at the top).
interiors/portrait       - a framed portrait in oils on a wall (the wall at the top).
interiors/billiard_table - the Regulars' Club's billiard table, balls racked, a cue across it.
interiors/armchair       - a cracked leather club armchair (its back at the top; turned by the game).
interiors/chalkboard     - the dispatch board: chalked train numbers, bays and times (wall at the top).
interiors/crate_stack    - a stack of plain crates.
interiors/freight_crates - the held shipment: twelve stencilled crates under a tarpaulin, a tag.
interiors/hand_truck     - a two-wheeled hand truck.
interiors/photo_wall     - framed photographs: handshakes, a picnic, a ribbon cut (the wall at the top).
interiors/couch          - a worn horsehair couch (the wall side at the top)."""
import math
import random

import numpy as np
from PIL import Image, ImageDraw

from paintkit import *

OUT = (24, 18, 15)
BRASS = "#c9a24e"


def floor_marble(seed=801):
    w = h = 256
    img = new(w, h, "#d8d2c4")
    d = ImageDraw.Draw(img)
    cell = 64
    for y in range(0, h, cell):
        for x in range(0, w, cell):
            col = "#c9c1ae" if ((x + y) // cell) % 2 == 0 else "#a39e92"
            d.rectangle([S(x), S(y), S(x + cell), S(y + cell)], fill=rgba(col))
    n = tnoise(w * SS, h * SS, 6, seed, octaves=5)
    img = modulate(img, n, 0.25)
    rnd = random.Random(seed)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    dl = ImageDraw.Draw(layer)
    for k in range(40):  # veins
        x, y = rnd.uniform(0, w), rnd.uniform(0, h)
        pts = [(x, y)]
        for j in range(5):
            x += rnd.uniform(-14, 14)
            y += rnd.uniform(-14, 14)
            pts.append((x, y))
        dl.line([(S(px % w), S(py % h)) for px, py in pts], fill=rgba("#7a776f", 50), width=SS)
    img.alpha_composite(layer)
    for y in range(0, h + 1, cell):
        d = ImageDraw.Draw(img)
        d.line([(0, S(y % h)), (S(w), S(y % h))], fill=rgba("#6a675f", 140), width=SS)
        d.line([(S(y % w), 0), (S(y % w), S(h))], fill=rgba("#6a675f", 140), width=SS)
    wear = tnoise(w * SS, h * SS, 2, seed + 3, octaves=2)
    a = np.asarray(img, dtype=np.float32).copy()
    a[..., :3] *= (1.0 - np.clip((wear - 0.6) * 0.8, 0, 0.18))[..., None]
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    return finish(grain(img, 3, seed), w, h)


def floor_concrete(seed=811):
    w = h = 256
    n = tnoise(w * SS, h * SS, 3, seed, octaves=5)
    img = ramp(n, ["#4a4844", "#575550", "#62605a", "#4e4c48"])
    d = ImageDraw.Draw(img)
    for x in (0, 128):
        d.line([(S(x), 0), (S(x), S(h))], fill=rgba("#2e2c2a", 160), width=SS)
        d.line([(0, S(x)), (S(w), S(x))], fill=rgba("#2e2c2a", 160), width=SS)
    rnd = random.Random(seed)
    for k in range(7):  # oil stains, coal dust
        soft_blob(img, S(rnd.uniform(20, w - 20)), S(rnd.uniform(20, h - 20)), S(rnd.uniform(8, 24)), S(rnd.uniform(6, 18)),
                  rnd.choice(["#1e1c1a", "#2a2622"]), rnd.randint(50, 110), 6 * SS)
    for k in range(5):  # cracks
        x, y = rnd.uniform(0, w), rnd.uniform(0, h)
        pts = [(x, y)]
        for j in range(4):
            x += rnd.uniform(-18, 18)
            y += rnd.uniform(-18, 18)
            pts.append((x, y))
        line(img, [S(px % w, py % h) for px, py in pts], "#24221f", 0.8 * SS, 160)
    return finish(grain(img, 6, seed), w, h)


def clerk_counter(seed=821):
    """A long oak counter, a brass grille along its front edge, a bell, a ledger, a pen stand."""
    w, h = 320, 60
    img = new(w, h)
    soft_blob(img, S(w / 2), S(34), S(w / 2 - 6), S(22), "#000000", 100, 4 * SS)
    paint_shape(img, SP(rrect_pts(4, 8, w - 4, 50, 3)), "#5a3a20", seed, outline=OUT, ow=1.4, wob=0.08, tex=0.25,
                strokes_n=24, stroke_cols=["#6a4628", "#462a16"], light=(0.3, -1, 0.35))
    paint_shape(img, SP(rrect_pts(8, 12, w - 8, 30, 2)), "#7a5432", seed + 1, outline=(60, 40, 20), ow=0.6, wob=0.04,
                light=(0.3, -1, 0.4))
    for k in range(int((w - 20) / 8)):  # the grille's bars
        x = 12 + k * 8
        line(img, [S(x, 33), S(x, 48)], BRASS, 1.0 * SS, 220)
    line(img, [S(10, 33), S(w - 10, 33)], BRASS, 1.6 * SS, 240)
    line(img, [S(10, 48), S(w - 10, 48)], BRASS, 1.6 * SS, 240)
    for gx in (80, 220):  # two windows in the grille
        paint_shape(img, SP(rrect_pts(gx - 14, 34, gx + 14, 47, 2)), "#3a2a18", seed + gx, outline=(120, 90, 40), ow=0.8, wob=0.02)
    paint_shape(img, SP(rrect_pts(120, 14, 160, 28, 1)), "#2a3a2a", seed + 2, outline=OUT, ow=0.6, wob=0.03)  # a ledger
    paint_shape(img, SP(ellipse_pts(185, 21, 5, 5)), BRASS, seed + 3, outline=OUT, ow=0.6, wob=0.02, light=(0.3, -1, 0.6))  # the bell
    paint_shape(img, SP(rrect_pts(250, 15, 290, 27, 1)), "#e8dcbc", seed + 4, outline=(90, 70, 40), ow=0.5, wob=0.03)  # forms
    return finish(grain(img, 3, seed), w, h)


def column(seed=831):
    w = h = 64
    img = new(w, h)
    soft_blob(img, S(34), S(35), S(26), S(26), "#000000", 110, 4 * SS)
    paint_shape(img, SP(rrect_pts(6, 6, 58, 58, 3)), "#bdb6a6", seed, outline=OUT, ow=1.2, wob=0.05, tex=0.2,
                light=(0.3, -1, 0.4))  # the plinth
    paint_shape(img, SP(ellipse_pts(32, 32, 22, 22, n=40)), "#d6cfbd", seed + 1, outline=(80, 70, 56), ow=1.0, wob=0.04,
                tex=0.15, light=(0.3, -1, 0.5))
    for k in range(16):  # the flutes
        a = 2 * math.pi * k / 16
        line(img, [S(32 + math.cos(a) * 12, 32 + math.sin(a) * 12), S(32 + math.cos(a) * 21, 32 + math.sin(a) * 21)],
             "#a8a190", 1.0 * SS, 170)
    soft_blob(img, S(26), S(24), S(7), S(4), "#ffffff", 60, 2 * SS)
    return finish(grain(img, 2, seed), w, h)


def flag_stand(seed=841):
    """A flag furled on its brass pole and a round stand (stars and stripes as a few painted folds)."""
    w, h = 48, 48
    img = new(w, h)
    soft_blob(img, S(25), S(26), S(15), S(15), "#000000", 100, 3 * SS)
    paint_shape(img, SP(ellipse_pts(24, 24, 11, 11)), "#3a2a18", seed, outline=OUT, ow=0.9, wob=0.04, light=(0.3, -1, 0.4))
    fold = [(24, 24), (40, 14), (44, 20), (28, 30)]
    paint_shape(img, SP(fold), "#b02a2a", seed + 1, outline=OUT, ow=0.7, wob=0.05, tex=0.2)
    for k in range(3):
        line(img, [S(27 + k * 4, 22 - k * 2), S(31 + k * 4, 28 - k * 2)], "#efe6cf", 1.0 * SS, 230)
    paint_shape(img, SP([(36, 14), (42, 12), (44, 18), (38, 20)]), "#24345a", seed + 2, outline=None, wob=0.03)
    paint_shape(img, SP(ellipse_pts(24, 24, 3, 3)), BRASS, seed + 3, outline=OUT, ow=0.6, wob=0.02, light=(0.3, -1, 0.6))
    return finish(img, w, h)


def staircase(seed=851):
    """A broad stair going up from the hall (the top at the top), brass rods, a red runner, a velvet rope at the foot."""
    w, h = 112, 128
    img = new(w, h)
    soft_blob(img, S(56), S(64), S(52), S(60), "#000000", 110, 5 * SS)
    for k in range(10):
        y0 = 6 + k * 11
        shade_k = 0.55 + 0.045 * k  # darker as it goes up
        paint_shape(img, SP(rrect_pts(8, y0, w - 8, y0 + 11, 1)), shade("#d6cfbd", shade_k), seed + k, outline=(60, 54, 44),
                    ow=0.6, wob=0.02, tex=0.12)
        line(img, [S(30, y0 + 10), S(w - 30, y0 + 10)], BRASS, 0.8 * SS, 200)
    paint_shape(img, SP(rrect_pts(30, 6, w - 30, 116, 1)), "#7a1e22", seed + 20, outline=None, wob=0.02, tex=0.25)
    for k in range(10):
        line(img, [S(30, 16 + k * 11), S(w - 30, 16 + k * 11)], BRASS, 0.9 * SS, 210)
    for x in (10, w - 10):  # newel posts
        paint_shape(img, SP(ellipse_pts(x, 116, 5, 5)), "#4a2a16", seed + x, outline=OUT, ow=0.6, wob=0.02, light=(0.3, -1, 0.5))
    line(img, [S(14, 118), S(56, 124), S(w - 14, 118)], "#8a1a22", 2.2 * SS, 255)  # the velvet rope
    return finish(grain(img, 3, seed), w, h)


def records_shelf(seed=861):
    w, h = 144, 34
    img = new(w, h)
    soft_blob(img, S(w / 2), S(20), S(w / 2 - 4), S(12), "#000000", 80, 3 * SS)
    paint_shape(img, SP(rrect_pts(3, 3, w - 3, 29, 1)), "#3a2414", seed, outline=OUT, ow=1.1, wob=0.05, tex=0.2,
                light=(0.3, -1, 0.35))
    rnd = random.Random(seed)
    x = 6
    while x < w - 8:
        bw = rnd.uniform(4, 8)
        col = rnd.choice(["#4a2a1a", "#2a3a4a", "#5a4a2a", "#3a2a2a", "#2e4a36"])
        paint_shape(img, SP(rrect_pts(x, 6, x + bw, 26, 0.5)), col, seed + int(x * 10), outline=(30, 22, 16), ow=0.4, wob=0.02)
        line(img, [S(x + 1, 10), S(x + bw - 1, 10)], "#c9a24e", 0.5 * SS, 160)
        x += bw + 0.6
    return finish(grain(img, 3, seed), w, h)


def portrait(seed=871):
    w, h = 64, 30
    img = new(w, h)
    soft_blob(img, S(32), S(17), S(28), S(10), "#000000", 80, 3 * SS)
    paint_shape(img, SP(rrect_pts(6, 2, 58, 26, 1)), "#b8913e", seed, outline=OUT, ow=1.0, wob=0.04, tex=0.2, light=(0.3, -1, 0.5))
    paint_shape(img, SP(rrect_pts(10, 5, 54, 23, 0.5)), "#3a2a1e", seed + 1, outline=None, wob=0.02, tex=0.3)
    soft_blob(img, S(32), S(13), S(5), S(5), "#c8a07a", 230, 0.6 * SS)  # a stern face
    soft_blob(img, S(32), S(21), S(10), S(4), "#1a1614", 230, 0.6 * SS)  # dark coat
    soft_blob(img, S(32), S(19), S(2), S(1.5), "#efe6cf", 220, 0.3 * SS)  # collar
    return finish(grain(img, 3, seed), w, h)


def billiard_table(seed=881):
    w, h = 192, 112
    img = new(w, h)
    soft_blob(img, S(98), S(60), S(90), S(50), "#000000", 120, 5 * SS)
    paint_shape(img, SP(rrect_pts(6, 6, w - 6, h - 6, 8)), "#4a2a16", seed, outline=OUT, ow=1.6, wob=0.08, tex=0.25,
                strokes_n=20, stroke_cols=["#5a3420", "#3a1e10"], light=(0.3, -1, 0.35))
    paint_shape(img, SP(rrect_pts(18, 18, w - 18, h - 18, 3)), "#24543a", seed + 1, outline=(16, 30, 20), ow=1.0, wob=0.04,
                tex=0.22, strokes_n=20, stroke_cols=["#2c6244", "#1e4630"], inner_shadow=0.4)
    for px, py in ((18, 18), (w / 2, 16), (w - 18, 18), (18, h - 18), (w / 2, h - 16), (w - 18, h - 18)):
        soft_blob(img, S(px), S(py), S(5), S(5), "#0a0806", 255, 0.5 * SS)  # pockets
    rnd = random.Random(seed)
    cols = ["#e8d040", "#2a4a9a", "#b02a2a", "#5a2a6a", "#e47a1e", "#2a6a3a", "#7a1e1e", "#1a1614"]
    k = 0
    for row in range(4):
        for j in range(row + 1):
            x = 128 + row * 6
            y = h / 2 - row * 3.4 + j * 6.8
            paint_shape(img, SP(ellipse_pts(x, y, 3.2, 3.2)), cols[k % len(cols)], seed + 10 + k, outline=OUT, ow=0.4, wob=0.0,
                        light=(0.3, -1, 0.6))
            k += 1
    paint_shape(img, SP(ellipse_pts(60, h / 2, 3.2, 3.2)), "#f2ecdc", seed + 40, outline=OUT, ow=0.4, wob=0.0)
    line(img, [S(30, 30), S(110, 80)], "#c8a060", 2.0 * SS, 255)  # a cue left on the cloth
    return finish(grain(img, 3, seed), w, h)


def armchair(seed=891):
    w = h = 44
    img = new(w, h)
    soft_blob(img, S(23), S(24), S(17), S(17), "#000000", 100, 3 * SS)
    paint_shape(img, SP(rrect_pts(6, 4, 38, 40, 6)), "#5a2a1a", seed, outline=OUT, ow=1.2, wob=0.1, tex=0.3,
                light=(0.3, -1, 0.45))
    paint_shape(img, SP(rrect_pts(11, 12, 33, 36, 4)), "#7a3a24", seed + 1, outline=(50, 24, 14), ow=0.8, wob=0.08, tex=0.3)
    rnd = random.Random(seed)
    for k in range(5):  # cracks in the leather
        x, y = rnd.uniform(13, 31), rnd.uniform(14, 34)
        line(img, [S(x, y), S(x + rnd.uniform(-3, 3), y + rnd.uniform(-3, 3))], "#3a1a10", 0.6 * SS, 160)
    return finish(img, w, h)


def chalkboard(seed=901):
    w, h = 144, 30
    img = new(w, h)
    soft_blob(img, S(w / 2), S(17), S(w / 2 - 4), S(10), "#000000", 80, 3 * SS)
    paint_shape(img, SP(rrect_pts(3, 2, w - 3, 26, 1)), "#5a3a20", seed, outline=OUT, ow=1.0, wob=0.04)
    paint_shape(img, SP(rrect_pts(6, 4, w - 6, 23, 0.5)), "#2a3230", seed + 1, outline=None, wob=0.02, tex=0.35)
    rnd = random.Random(seed)
    for row in range(3):
        x = 10
        while x < w - 14:
            ln = rnd.uniform(6, 16)
            line(img, [S(x, 8 + row * 5), S(x + ln, 8 + row * 5 + rnd.uniform(-0.4, 0.4))], "#e8e4d8", 0.8 * SS, 170)
            x += ln + rnd.uniform(3, 8)
    for x in (50, 96):
        line(img, [S(x, 5), S(x, 22)], "#e8e4d8", 0.6 * SS, 120)
    return finish(grain(img, 3, seed), w, h)


def crate_stack(seed=911):
    w = h = 64
    img = new(w, h)
    soft_blob(img, S(34), S(35), S(27), S(26), "#000000", 110, 4 * SS)
    rnd = random.Random(seed)
    for k, (x, y, s) in enumerate(((8, 8, 26), (32, 10, 24), (12, 32, 24), (34, 34, 24))):
        paint_shape(img, SP(rrect_pts(x, y, x + s, y + s, 1)), rnd.choice(["#8a6a42", "#7a5a36", "#94744a"]), seed + k,
                    outline=OUT, ow=1.0, wob=0.06, tex=0.3, strokes_n=6, light=(0.3, -1, 0.4))
        line(img, [S(x + 2, y + 2), S(x + s - 2, y + s - 2)], "#5a4024", 1.2 * SS, 180)
        line(img, [S(x + s - 2, y + 2), S(x + 2, y + s - 2)], "#5a4024", 1.2 * SS, 180)
    return finish(grain(img, 3, seed), w, h)


def freight_crates(seed=921):
    """The held shipment: a dozen crates stacked under a tarpaulin pulled half back, stencilled, a waybill tag."""
    w, h = 112, 80
    img = new(w, h)
    soft_blob(img, S(58), S(44), S(50), S(34), "#000000", 120, 5 * SS)
    for row in range(3):
        for col in range(4):
            x, y = 8 + col * 24, 8 + row * 22
            paint_shape(img, SP(rrect_pts(x, y, x + 23, y + 21, 1)), "#8f6c42", seed + row * 5 + col, outline=OUT, ow=0.9,
                        wob=0.05, tex=0.3, light=(0.3, -1, 0.4))
            text(img, (x + 11.5, y + 10.5), "NBF", 6, "#2a1e12")
    tarp = [(4, 4), (60, 2), (70, 30), (54, 50), (6, 44)]
    paint_shape(img, SP(tarp), "#4a5a3a", seed + 30, outline=OUT, ow=1.0, wob=0.25, tex=0.3, strokes_n=10, light=(0.3, -1, 0.4))
    paint_shape(img, SP(rrect_pts(94, 58, 106, 72, 1)), "#e8dcbc", seed + 31, outline=(90, 70, 40), ow=0.6, wob=0.04)  # the tag
    line(img, [S(100, 58), S(96, 52)], "#8a6a40", 0.8 * SS, 220)
    return finish(grain(img, 3, seed), w, h)


def hand_truck(seed=931):
    w, h = 32, 48
    img = new(w, h)
    soft_blob(img, S(17), S(26), S(10), S(18), "#000000", 100, 3 * SS)
    line(img, [S(8, 6), S(10, 40)], "#6a6a6e", 2.4 * SS, 255)
    line(img, [S(24, 6), S(22, 40)], "#6a6a6e", 2.4 * SS, 255)
    for y in (14, 24, 34):
        line(img, [S(9, y), S(23, y)], "#6a6a6e", 1.4 * SS, 255)
    paint_shape(img, SP(rrect_pts(6, 38, 26, 44, 1)), "#5a5a5e", seed, outline=OUT, ow=0.7, wob=0.03)
    for x in (5, 27):
        paint_shape(img, SP(ellipse_pts(x, 40, 3.5, 5.5)), "#1a1614", seed + x, outline=OUT, ow=0.6, wob=0.02)
    return finish(img, w, h)


def photo_wall(seed=941):
    w, h = 112, 24
    img = new(w, h)
    soft_blob(img, S(w / 2), S(14), S(w / 2 - 4), S(8), "#000000", 70, 3 * SS)
    rnd = random.Random(seed)
    x = 6
    for k in range(5):
        fw = rnd.uniform(14, 20)
        paint_shape(img, SP(rrect_pts(x, 3 + rnd.uniform(0, 3), x + fw, 19 + rnd.uniform(0, 2), 0.5)),
                    rnd.choice(["#2a2018", "#6a4a22", "#3a2a1e"]), seed + k, outline=OUT, ow=0.7, wob=0.03)
        paint_shape(img, SP(rrect_pts(x + 2, 6, x + fw - 2, 17, 0.5)), "#8a8274", seed + 10 + k, outline=None, wob=0.02, tex=0.3)
        for j in range(2):
            soft_blob(img, S(x + fw * (0.35 + 0.3 * j)), S(12), S(1.6), S(2.6), "#2a2420", 220, 0.4 * SS)
        x += fw + rnd.uniform(2, 5)
    return finish(grain(img, 3, seed), w, h)


def couch(seed=951):
    w, h = 112, 40
    img = new(w, h)
    soft_blob(img, S(w / 2), S(22), S(w / 2 - 4), S(15), "#000000", 100, 3 * SS)
    paint_shape(img, SP(rrect_pts(4, 4, w - 4, 36, 6)), "#3a2a22", seed, outline=OUT, ow=1.2, wob=0.1, tex=0.3,
                light=(0.3, -1, 0.4))
    for k in range(3):
        x0 = 12 + k * 30
        paint_shape(img, SP(rrect_pts(x0, 14, x0 + 28, 32, 3)), "#4a362a", seed + k, outline=(30, 20, 14), ow=0.7, wob=0.06,
                    tex=0.3)
    soft_blob(img, S(70), S(24), S(5), S(3), "#2a1e16", 140, 1 * SS)  # a worn patch
    return finish(grain(img, 3, seed), w, h)


ASSETS = {
    "interiors/floor_marble": floor_marble,
    "interiors/floor_concrete": floor_concrete,
    "interiors/clerk_counter": clerk_counter,
    "interiors/column": column,
    "interiors/flag_stand": flag_stand,
    "interiors/staircase": staircase,
    "interiors/records_shelf": records_shelf,
    "interiors/portrait": portrait,
    "interiors/billiard_table": billiard_table,
    "interiors/armchair": armchair,
    "interiors/chalkboard": chalkboard,
    "interiors/crate_stack": crate_stack,
    "interiors/freight_crates": freight_crates,
    "interiors/hand_truck": hand_truck,
    "interiors/photo_wall": photo_wall,
    "interiors/couch": couch,
}
