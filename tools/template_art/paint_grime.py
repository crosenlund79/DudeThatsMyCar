"""M010: the grit of the city and the fences you can see.

decals/grime - one sheet of twelve 64 x 64 frames of street rubbish, drawn
flat on the ground (visual only, never solid): 0 an open newspaper, 1 a
folded newspaper, 2 loose paper scraps, 3 a brown bottle, 4 a broken green
bottle, 5 a flattened cardboard box, 6 a burst box, 7 coal dust, 8 a soot
stain, 9 a loose board, 10 a little pile of brick rubble, 11 a worn, wet
stain on the paving. One texture, so a district's whole litter is one draw.

fences/boards, fences/chain, fences/iron - a fence's upright face, seamless
left to right, the ground at the bottom edge, 128 x 48 (one repeat = 64
world px, 26 px high): weathered boards between posts; chain-link mesh
between pipe posts; a wrought-iron railing with spear tops. Painted bright
enough at the top edge to read against the night."""
import math
import random

from PIL import Image, ImageDraw, ImageFilter

from paintkit import *

OUT = (24, 20, 18)
F = 64


def _frame(fn, seed):
    img = new(F, F)
    fn(img, random.Random(seed), seed)
    return img


def _newspaper(img, rnd, seed):
    pts = [(10, 18), (50, 12), (55, 44), (14, 50)]
    paint_shape(img, SP(pts), "#cfc8b2", seed, outline=(70, 64, 56), ow=0.8, wob=0.8, tex=0.12, light=(0.3, -1, 0.3))
    line(img, [(S(32), S(14)), (S(35), S(47))], "#8f8878", 0.8 * SS, 160)  # the fold
    for k in range(6):
        line(img, [(S(15), S(21 + k * 4.6)), (S(29), S(19 + k * 4.4))], "#6b665c", 0.9 * SS, 150)
        line(img, [(S(37), S(18 + k * 4.4)), (S(51), S(16 + k * 4.4))], "#6b665c", 0.9 * SS, 150)
    paint_shape(img, SP(rrect_pts(15, 20, 28, 27, 1)), "#5d584f", seed + 1, outline=None, wob=0.2, tex=0.2)  # a photograph


def _folded(img, rnd, seed):
    pts = [(18, 22), (46, 18), (48, 40), (20, 44)]
    paint_shape(img, SP(pts), "#c8c0a8", seed, outline=(70, 64, 56), ow=0.8, wob=0.6, tex=0.12, light=(0.3, -1, 0.3))
    for k in range(4):
        line(img, [(S(22), S(25 + k * 4.5)), (S(43), S(22 + k * 4.5))], "#6b665c", 0.9 * SS, 140)
    line(img, [(S(20), S(33)), (S(47), S(29))], "#8a8270", 1.0 * SS, 180)


def _scraps(img, rnd, seed):
    for k in range(6):
        cx, cy = rnd.uniform(14, 50), rnd.uniform(14, 50)
        r = rnd.uniform(3, 7)
        pts = [(cx + math.cos(a) * r * rnd.uniform(0.6, 1.2), cy + math.sin(a) * r * rnd.uniform(0.6, 1.2))
               for a in [i * math.pi / 2 + rnd.uniform(-0.4, 0.4) for i in range(4)]]
        paint_shape(img, SP(pts), rnd.choice(["#d3ccb6", "#bdb59e", "#e0d9c4", "#a89f88"]), seed + k, outline=(80, 72, 62),
                    ow=0.6, wob=0.4, tex=0.1)


def _bottle(img, rnd, seed, glass="#5a3a1c"):
    soft_blob(img, S(33), S(35), S(18), S(6), "#000000", 70, 2 * SS, rot=-0.5)
    body = [(16, 40), (38, 26), (42, 31), (20, 45)]
    paint_shape(img, SP(body), glass, seed, outline=OUT, ow=0.9, wob=0.15, tex=0.05, light=(0.5, -1, 0.7))
    neck = [(38, 26), (48, 20), (50, 23), (42, 31)]
    paint_shape(img, SP(neck), shade(glass, 0.9), seed + 1, outline=OUT, ow=0.8, wob=0.1, tex=0.05, light=(0.5, -1, 0.7))
    line(img, [(S(20), S(38)), (S(36), S(28))], "#f4e6c8", 0.9 * SS, 150, blur=0.3)  # a glint


def _broken(img, rnd, seed):
    for k in range(7):
        cx, cy = 32 + rnd.uniform(-14, 14), 32 + rnd.uniform(-10, 10)
        r = rnd.uniform(2, 5)
        pts = [(cx + math.cos(a) * r, cy + math.sin(a) * r * 0.7) for a in (rnd.uniform(0, 6.28) + i * 2.1 for i in range(3))]
        paint_shape(img, SP(pts), "#3f6a3a", seed + k, outline=(20, 36, 20), ow=0.5, wob=0.05, tex=0.05, light=(0.5, -1, 0.8))
    _bottle_neck = [(22, 26), (31, 22), (33, 26), (24, 30)]
    paint_shape(img, SP(_bottle_neck), "#36603a", seed + 9, outline=OUT, ow=0.7, wob=0.1, tex=0.05, light=(0.5, -1, 0.8))


def _box_flat(img, rnd, seed):
    pts = [(8, 18), (54, 14), (57, 46), (11, 50)]
    paint_shape(img, SP(pts), "#8a6a44", seed, outline=(60, 44, 28), ow=1.0, wob=0.5, tex=0.25, light=(0.3, -1, 0.4))
    line(img, [(S(31), S(16)), (S(34), S(48))], "#5e4428", 1.0 * SS, 170)
    line(img, [(S(10), S(33)), (S(55), S(30))], "#6e522f", 0.8 * SS, 120)
    text(img, (21, 26), "SOAP", 5, "#3e2c18")


def _box_burst(img, rnd, seed):
    paint_shape(img, SP([(16, 20), (44, 18), (46, 44), (18, 46)]), "#7e603c", seed, outline=(60, 44, 28), ow=1.0, wob=0.6,
                tex=0.25, light=(0.3, -1, 0.4))
    for flap in ([(16, 20), (6, 12), (26, 14)], [(44, 18), (56, 10), (48, 28)], [(46, 44), (58, 52), (36, 48)]):
        paint_shape(img, SP(flap), "#94744a", seed + 3, outline=(60, 44, 28), ow=0.8, wob=0.4, tex=0.2, light=(0.3, -1, 0.5))
    paint_shape(img, SP([(22, 26), (40, 24), (40, 38), (24, 40)]), "#3a2a1a", seed + 4, outline=None, wob=0.3, tex=0.2)


def _coal_dust(img, rnd, seed):
    soft_blob(img, S(32), S(32), S(24), S(16), "#141312", 120, 5 * SS, rot=rnd.uniform(0, 3))
    for k in range(26):
        x, y = 32 + rnd.gauss(0, 9), 32 + rnd.gauss(0, 6)
        r = rnd.uniform(0.7, 2.2)
        paint_shape(img, SP(ellipse_pts(x, y, r, r * 0.8, n=10)), rnd.choice(["#0f0f10", "#1d1d20", "#2a2a2e"]), seed + k,
                    outline=None, wob=0.3, tex=0.2, light=(0.4, -1, 0.5))


def _soot(img, rnd, seed):
    soft_blob(img, S(32), S(33), S(26), S(18), "#0d0c0b", 95, 7 * SS, rot=0.3)
    soft_blob(img, S(26), S(30), S(10), S(7), "#0a0909", 90, 4 * SS)


def _board(img, rnd, seed):
    soft_blob(img, S(34), S(35), S(26), S(5), "#000000", 70, 2 * SS, rot=-0.25)
    pts = [(6, 34), (56, 22), (58, 28), (8, 40)]
    paint_shape(img, SP(pts), "#6a5038", seed, outline=(44, 32, 22), ow=1.0, wob=0.2, tex=0.3, strokes_n=6,
                stroke_cols=["#7a5e42", "#584230"], light=(0.3, -1, 0.5))
    for x, y in ((14, 35), (48, 26)):
        paint_shape(img, SP(ellipse_pts(x, y, 1.0, 1.0, n=8)), "#9a9894", seed + x, outline=None, wob=0.02)


def _rubble(img, rnd, seed):
    soft_blob(img, S(33), S(35), S(20), S(13), "#000000", 70, 3 * SS)
    for k in range(9):
        x, y = 32 + rnd.uniform(-13, 13), 32 + rnd.uniform(-9, 9)
        w, h = rnd.uniform(4, 8), rnd.uniform(3, 5)
        paint_shape(img, SP(rrect_pts(x - w / 2, y - h / 2, x + w / 2, y + h / 2, 1)),
                    rnd.choice(["#7a3a2a", "#8a4632", "#6a3226", "#8c8478"]), seed + k, outline=(40, 24, 20), ow=0.7,
                    wob=0.4, tex=0.3, light=(0.3, -1, 0.6))


def _stain(img, rnd, seed):
    soft_blob(img, S(32), S(32), S(26), S(19), "#1a1714", 80, 6 * SS, rot=rnd.uniform(0, 3))
    soft_blob(img, S(38), S(28), S(10), S(6), "#2a2620", 70, 3 * SS)
    soft_blob(img, S(30), S(36), S(6), S(3), "#8090a8", 30, 2 * SS)  # a wet sheen


def grime():
    """The sheet: twelve frames left to right."""
    fns = [_newspaper, _folded, _scraps, _bottle, _broken, _box_flat, _box_burst, _coal_dust, _soot, _board, _rubble, _stain]
    sheet = new(F * len(fns), F)
    for k, fn in enumerate(fns):
        sheet.alpha_composite(_frame(fn, 1000 + k * 17), (k * F * SS, 0))
    return finish(sheet, F * len(fns), F)


# ---------------------------------------------------------------- fences (upright faces)

FW, FH = 128, 48


def _post(img, x, col, seed, top=2):
    paint_shape(img, SP(rrect_pts(x - 3.5, top, x + 3.5, FH, 1)), col, seed, outline=OUT, ow=1.0, wob=0.1, tex=0.25,
                light=(1, -1, 0.5))


def fence_boards(seed=2401):
    """Weathered boards between square posts, a top rail catching the lamplight."""
    img = new(FW, FH)
    rnd = random.Random(seed)
    for k in range(0, FW, 9):
        top = 7 + rnd.uniform(-1.5, 1.5)
        col = rnd.choice(["#6e5640", "#5e4836", "#7a6048", "#664e3a"])
        paint_shape(img, SP(rrect_pts(k + 0.5, top, k + 8.5, FH, 1)), col, seed + k, outline=(40, 30, 22), ow=0.7, wob=0.15,
                    tex=0.3, strokes_n=3, stroke_cols=[shade(col, 1.15), shade(col, 0.85)], light=(0.4, -1, 0.5))
        if rnd.random() < 0.25:  # a knot, a missing paint scrap
            soft_blob(img, S(k + 4), S(rnd.uniform(16, 40)), S(1.6), S(1.2), "#3a2a1c", 160, 0.4 * SS)
    for y in (13, 36):  # the rails behind
        line(img, [(S(0), S(y)), (S(FW), S(y))], "#3c2c20", 1.6 * SS, 150)
    for x in (2, 66):
        _post(img, x, "#5a4434", seed + x)
    line(img, [(S(0), S(6)), (S(FW), S(6))], "#c8b08a", 1.5 * SS, 210)  # the lit top edge
    soft_blob(img, S(64), S(FH - 3), S(70), S(4), "#000000", 90, 2 * SS)  # dirt at the foot
    return finish(grain(img, 3, seed), FW, FH)


def fence_chain(seed=2402):
    """Chain-link mesh between galvanised pipe posts, a top pipe and a strand of wire."""
    img = new(FW, FH)
    d = ImageDraw.Draw(img)
    mesh = rgba("#9aa2a6", 150)
    step = 5
    for k in range(-FH, FW + FH, step):
        d.line([(S(k), S(8)), (S(k + FH - 8), S(FH))], fill=mesh, width=SS)
        d.line([(S(k), S(FH)), (S(k + FH - 8), S(8))], fill=mesh, width=SS)
    img = img.filter(ImageFilter.GaussianBlur(0.3 * SS))
    for x in (3, 67):
        paint_shape(img, SP(rrect_pts(x - 2.5, 3, x + 2.5, FH, 2)), "#aeb4b6", seed + x, outline=OUT, ow=0.9, wob=0.05,
                    tex=0.15, light=(1, -1, 0.6))
    paint_shape(img, SP(rrect_pts(0, 6, FW, 10, 2)), "#c2c8ca", seed + 5, outline=OUT, ow=0.8, wob=0.05, tex=0.1,
                light=(0, -1, 0.6))
    d = ImageDraw.Draw(img)
    for x in range(0, FW, 6):  # the barbed strand above
        d.line([(S(x), S(3)), (S(x + 6), S(3.6))], fill=rgba("#8a9094", 220), width=SS)
        d.line([(S(x + 2), S(1.8)), (S(x + 4), S(4.8))], fill=rgba("#8a9094", 200), width=SS)
    soft_blob(img, S(64), S(FH - 2), S(70), S(3), "#000000", 70, 2 * SS)
    return finish(img, FW, FH)


def fence_iron(seed=2403):
    """A wrought-iron railing: square bars with spear tops between stone-capped posts."""
    img = new(FW, FH)
    for x in range(6, FW, 8):
        paint_shape(img, SP(rrect_pts(x - 1.1, 10, x + 1.1, FH, 0.5)), "#26282c", seed + x, outline=None, wob=0.02, tex=0.1)
        paint_shape(img, SP([(x - 2.4, 11), (x, 5), (x + 2.4, 11)]), "#3a3d42", seed + x + 1, outline=(14, 14, 16), ow=0.5,
                    wob=0.02, light=(1, -1, 0.6))
    for y in (14, 40):
        paint_shape(img, SP(rrect_pts(0, y - 1.2, FW, y + 1.2, 0.5)), "#30333a", seed + y, outline=(14, 14, 16), ow=0.5, wob=0.02,
                    light=(0, -1, 0.5))
    for x in (2, 66):
        paint_shape(img, SP(rrect_pts(x - 4, 4, x + 4, FH, 1)), "#6c6a64", seed + 70 + x, outline=OUT, ow=1.0, wob=0.1,
                    tex=0.3, light=(1, -1, 0.5))
        paint_shape(img, SP(rrect_pts(x - 5, 2, x + 5, 6, 1)), "#9a968c", seed + 80 + x, outline=OUT, ow=0.8, wob=0.05,
                    light=(0, -1, 0.6))
    line(img, [(S(0), S(13)), (S(FW), S(13))], "#8c8a90", 0.9 * SS, 160)  # the lamplit top rail
    return finish(img, FW, FH)


ASSETS = {
    "decals/grime": grime,
    "fences/boards": fence_boards,
    "fences/chain": fence_chain,
    "fences/iron": fence_iron,
}
