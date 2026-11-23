"""M015: the art of the two new quarters.

CANAL MARKET (south of Halloran Square, west of the yards): the old market
quarter under the El - the elevated railway's riveted deck and columns over
Market Street and a train that rumbles along it, the market hall's arched
brick and glass roof lights, the Golden Lantern's red-lacquered front and its
string of paper lanterns, shuttered stalls and pushcarts along the kerbs,
St. Casimir's fountain in its little plaza, coal barges on the canal.

LINCOLN TERRACE (north of the railroad, through the Wharf Street underpass):
the swells' quarter - the Belvedere Hotel's Art Deco limestone and its lit
canopy, the Paradise Ballroom's starry marquee and dome, the old water
tower's crenellated top, and the railroad's bridge over the underpass.

Same conventions as the rest: facades 256 x 192 (upper storey above, ground
storey below, horizontally seamless) with a *_lit light image; props and roof
furniture top-down (a canopy's wall side at the top), long axis along +X."""
import math
import random

from PIL import Image, ImageDraw, ImageFilter

from paintkit import *
import paint_buildings as pb
from paint_props import painted_roof_sign, DECO

OUT = (22, 18, 18)
STEEL = "#2f3430"
STEEL_LIGHT = "#4a514b"
W, H = pb.W, pb.H


# ---------------------------------------------------------------- facades

def facade_deco(seed=1500):
    """The Belvedere: Art Deco limestone - pale piers running up between the
    window bays, dark fluted spandrels, a stepped zigzag band under the parapet;
    the ground storey polished black granite with bronze-framed glass. Most
    windows lit warm, late."""
    n = tnoise(W * SS, H * SS, 4, seed, octaves=4)
    img = ramp(n, ["#c9c1ad", "#d3cbb7", "#dcd4c0", "#cec6b2"])
    img = wrap_blur(img, 0.5 * SS)
    strokes(img, 120, ["#e4dccb", "#b0a894", "#d0c8b4"], 16, 4, seed + 1, alpha=(10, 28))
    lit = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for x in range(0, W, 8):  # the zigzag band
        d.polygon([(S(x), S(10)), (S(x + 4), S(3)), (S(x + 8), S(10))], fill=rgba("#b8ae96"))
    d.rectangle([0, S(10), S(W), S(13)], fill=rgba("#9e947e"))
    rnd = random.Random(seed)
    for cx in (0, 64, 128, 192):  # the piers
        d.rectangle([S(cx - 7), S(13), S(cx + 7), S(96)], fill=rgba("#e6dfcd"))
        d.line([(S(cx), S(16)), (S(cx), S(94))], fill=rgba("#c9c0aa"), width=SS)
    for i, cx in enumerate((32, 96, 160, 224)):
        for k, y in enumerate((18, 58)):
            window(img, lit, cx - 17, y, 34, 30, seed + i * 3 + k, rnd.random() < 0.72, style="grid", frame="#8a7a52",
                   lintel=None, sill=False, light_col="#ffdc94")
        d.rectangle([S(cx - 17), S(49), S(cx + 17), S(57)], fill=rgba("#4a4438"))  # the spandrel between them
        for k in range(-14, 16, 4):
            d.line([(S(cx + k), S(49)), (S(cx + k), S(57))], fill=rgba("#2e2a22"), width=SS)
    # the ground storey: black granite, bronze shopfronts, a revolving door
    d.rectangle([0, S(96), S(W), S(192)], fill=rgba("#1c1d20"))
    for x in range(0, W, 32):
        d.line([(S(x), S(96)), (S(x), S(192))], fill=rgba("#2c2e33"), width=SS)
    d.rectangle([0, S(96), S(W), S(102)], fill=rgba("#8a6a3a"))  # a bronze band
    for i, x0 in enumerate((14, 142)):
        d.rectangle([S(x0), S(112), S(x0 + 100), S(176)], fill=rgba("#9a7a46"))
        d.rectangle([S(x0 + 3), S(115), S(x0 + 97), S(173)], fill=rgba("#2a2418"))
        L = ImageDraw.Draw(lit)
        L.rectangle([S(x0 + 3), S(115), S(x0 + 97), S(173)], fill=rgba("#ffd890", 170 if i == 0 else 120))
        for k in range(1, 4):
            d.line([(S(x0 + k * 25), S(115)), (S(x0 + k * 25), S(173))], fill=rgba("#9a7a46"), width=SS)
    return pb.finalize(pb.soot(img, 0.04, 0.06), lit)


def facade_market(seed=1600):
    """The Canal Market hall: dark red brick with tall round-arched iron
    windows above, wide arched openings below with iron shutters half down
    over the lit stalls inside."""
    img = pb.brick_wall(["#6e2e22", "#7a3428", "#682a20", "#82392b"], "#3a2a24", seed)
    lit = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pb.stone_band(d, 0, 7, "#a89a80", "#4e463c")
    rnd = random.Random(seed)
    for i, cx in enumerate((32, 96, 160, 224)):
        d.rectangle([S(cx - 14), S(26), S(cx + 14), S(86)], fill=rgba("#2b2a26"))
        d.pieslice([S(cx - 14), S(12), S(cx + 14), S(40)], 180, 360, fill=rgba("#2b2a26"))
        on = rnd.random() < 0.55
        L = ImageDraw.Draw(lit)
        for gx in range(-10, 12, 7):
            for gy in range(30, 84, 8):
                d.rectangle([S(cx + gx), S(gy), S(cx + gx + 5), S(gy + 6)], fill=rgba("#3e4a52"))
                if on:
                    L.rectangle([S(cx + gx), S(gy), S(cx + gx + 5), S(gy + 6)], fill=rgba("#ffd27a", 150))
        d.arc([S(cx - 16), S(10), S(cx + 16), S(42)], 180, 360, fill=rgba("#a89a80"), width=2 * SS)
    for i, cx in enumerate((64, 192)):  # the wide arches below
        d.rectangle([S(cx - 46), S(122), S(cx + 46), S(192)], fill=rgba("#1e1b18"))
        d.pieslice([S(cx - 46), S(100), S(cx + 46), S(146)], 180, 360, fill=rgba("#1e1b18"))
        d.arc([S(cx - 48), S(98), S(cx + 48), S(148)], 180, 360, fill=rgba("#a89a80"), width=3 * SS)
        L = ImageDraw.Draw(lit)
        L.rectangle([S(cx - 42), S(160), S(cx + 42), S(190)], fill=rgba("#ffcc70", 190))
        for y in range(122, 160, 4):  # the shutter, half down
            d.line([(S(cx - 46), S(y)), (S(cx + 46), S(y))], fill=rgba("#5a5a52"), width=2 * SS)
    return pb.finalize(pb.soot(img, 0.3, 0.25), lit)


def facade_lantern(seed=1700):
    """The Golden Lantern: an old brick front painted oxblood above, green
    shutters at its windows; below, a red-lacquered wooden shopfront with gilt
    lattice, a moon window glowing and the door between."""
    img = pb.brick_wall(["#5a2420", "#62281f", "#52201c", "#6b2d24"], "#2a1a18", seed)
    lit = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rnd = random.Random(seed)
    for i, cx in enumerate((32, 96, 160, 224)):
        window(img, lit, cx - 13, 22, 26, 50, seed + i, rnd.random() < 0.6, lintel="#3a5a3a", light_col="#ffb070")
        d.rectangle([S(cx - 21), S(22), S(cx - 15), S(72)], fill=rgba("#2f5a3a"))
        d.rectangle([S(cx + 15), S(22), S(cx + 21), S(72)], fill=rgba("#2f5a3a"))
    d.rectangle([0, S(96), S(W), S(192)], fill=rgba("#8a1c16"))
    d.rectangle([0, S(96), S(W), S(104)], fill=rgba("#c8a040"))
    L = ImageDraw.Draw(lit)
    for i, cx in enumerate((64, 192)):
        d.ellipse([S(cx - 30), S(112), S(cx + 30), S(172)], fill=rgba("#c8a040"))
        d.ellipse([S(cx - 26), S(116), S(cx + 26), S(168)], fill=rgba("#2a1810"))
        L.ellipse([S(cx - 26), S(116), S(cx + 26), S(168)], fill=rgba("#ffb060", 200))
        for k in range(-24, 26, 8):
            d.line([(S(cx + k), S(118)), (S(cx + k), S(166))], fill=rgba("#c8a040"), width=SS)
            d.line([(S(cx - 24), S(142 + k)), (S(cx + 24), S(142 + k))], fill=rgba("#c8a040"), width=SS)
    pb.door(d, 116, 120, 24, 64, color="#3a120e")
    return pb.finalize(pb.soot(img, 0.15, 0.1), lit)


def window(*a, **k):
    return pb.window(*a, **k)


# ---------------------------------------------------------------- the El

def el_deck(seed=1800):
    """A length of the elevated railway's deck from above (seamless along x):
    riveted plate girders along both edges, two tracks of rails on wooden
    ties, a plank walk between them."""
    w, h = 256, 112
    img = new(w, h, rgba("#1c1d1c"))
    d = ImageDraw.Draw(img)
    rnd = random.Random(seed)
    for x in range(0, w, 6):  # the ties
        c = rnd.choice(["#3a2c22", "#33271e", "#40322a"])
        d.rectangle([S(x), S(16), S(x + 3.5), S(96)], fill=rgba(c))
    for y in (26, 42, 70, 86):  # the rails
        d.rectangle([0, S(y - 1.2), S(w), S(y + 1.2)], fill=rgba("#9aa0a2"))
        d.line([(0, S(y - 0.4)), (S(w), S(y - 0.4))], fill=rgba("#d8dcdc"), width=SS)
    d.rectangle([0, S(52), S(w), S(60)], fill=rgba("#5a4a38"))  # the walk
    for x in range(0, w, 14):
        d.line([(S(x), S(52)), (S(x), S(60))], fill=rgba("#3a2e22"), width=SS)
    for y0, y1 in ((0, 14), (98, 112)):  # the girders, riveted
        d.rectangle([0, S(y0), S(w), S(y1)], fill=rgba(STEEL))
        d.line([(0, S(y0 + 2)), (S(w), S(y0 + 2))], fill=rgba(STEEL_LIGHT), width=SS)
        for x in range(4, w, 8):
            for yy in (y0 + 5, y1 - 5):
                d.ellipse([S(x - 0.9), S(yy - 0.9), S(x + 0.9), S(yy + 0.9)], fill=rgba("#5c635c"))
    img = img.filter(ImageFilter.GaussianBlur(0.3 * SS))
    return finish(grain(img, 4, seed), w, h)


def el_column(seed=1810):
    """One of the El's steel columns, its cap from above: an H of riveted plates and gusset knees."""
    w = h = 64
    img = new(w, h)
    soft_blob(img, S(34), S(34), S(24), S(24), "#000000", 90, 4 * SS)
    for r in ((14, 8, 50, 16), (14, 48, 50, 56), (28, 16, 36, 48)):
        paint_shape(img, SP(rrect_pts(*r, 1.5)), STEEL, seed + r[1], outline=OUT, ow=1.0, wob=0.05, tex=0.2, light=(0.3, -1, 0.5))
    for x, y in ((18, 12), (46, 12), (18, 52), (46, 52), (32, 24), (32, 40)):
        soft_blob(img, S(x), S(y), S(1.2), S(1.2), "#7a827a", 220, 0.2 * SS)
    return finish(img, w, h)


def el_train(seed=1820):
    """Two El cars coupled, from above: dark green roofs with a clerestory and
    vents, the motorman's ends rounded; their windows a lit strip along both
    sides (the *_lit image)."""
    w, h = 600, 96
    img = new(w, h)
    lit = new(w, h)
    soft_blob(img, S(300), S(50), S(292), S(42), "#000000", 60, 5 * SS)
    for k, x0 in enumerate((6, 304)):
        paint_shape(img, SP(rrect_pts(x0, 10, x0 + 290, 86, 14)), "#2e4a36", seed + k, outline=OUT, ow=1.6, wob=0.15, tex=0.15,
                    light=(0.2, -1, 0.45), inner_shadow=0.3)
        paint_shape(img, SP(rrect_pts(x0 + 18, 32, x0 + 272, 64, 6)), "#3a5a42", seed + 10 + k, outline=(30, 40, 32), ow=1.0,
                    wob=0.1, tex=0.1, light=(0.2, -1, 0.5))
        for x in range(int(x0 + 30), int(x0 + 270), 34):
            soft_blob(img, S(x), S(48), S(4), S(3), "#1a2a1e", 200, 0.5 * SS)
        L = ImageDraw.Draw(lit)
        D = ImageDraw.Draw(img)
        for y in (13, 79):
            for x in range(int(x0 + 22), int(x0 + 270), 18):
                D.rectangle([S(x), S(y), S(x + 12), S(y + 4)], fill=rgba("#c8b070"))
                L.rectangle([S(x), S(y), S(x + 12), S(y + 4)], fill=rgba("#ffe0a0"))
    paint_shape(img, SP(rrect_pts(294, 38, 306, 58, 2)), "#1a1a1a", seed + 30, outline=OUT, ow=0.8, wob=0.05)
    return {"props/el_train": finish(grain(img, 3, seed), w, h), "props/el_train_lit": finish(glow_from(lit, 3 * SS, 0.7), w, h)}


def rail_bridge(seed=1830):
    """The railroad's bridge over the Wharf Street underpass, from above:
    four tracks on ballast running across it (along x), heavy riveted girders
    between them, the deck's steel plating at the ends."""
    w, h = 272, 352
    img = new(w, h, rgba("#3a3834"))
    d = ImageDraw.Draw(img)
    rnd = random.Random(seed)
    for k, y0 in enumerate((30, 110, 190, 270)):  # four tracks
        d.rectangle([0, S(y0), S(w), S(y0 + 52)], fill=rgba("#4a463e"))
        for i in range(500):
            x, y = rnd.uniform(0, w), rnd.uniform(y0, y0 + 52)
            c = rnd.choice(["#5a554c", "#3e3a34", "#6a645a"])
            d.ellipse([S(x - 1), S(y - 1), S(x + 1), S(y + 1)], fill=rgba(c))
        for x in range(0, w, 7):
            d.rectangle([S(x), S(y0 + 8), S(x + 4), S(y0 + 44)], fill=rgba("#3a2c22"))
        for y in (y0 + 16, y0 + 36):
            d.rectangle([0, S(y - 1.2), S(w), S(y + 1.2)], fill=rgba("#9aa0a2"))
    for y0 in (0, 90, 170, 250, 330):  # girders
        d.rectangle([0, S(y0), S(w), S(y0 + 20)], fill=rgba(STEEL))
        d.line([(0, S(y0 + 3)), (S(w), S(y0 + 3))], fill=rgba(STEEL_LIGHT), width=SS)
        for x in range(5, w, 9):
            d.ellipse([S(x - 0.9), S(y0 + 10 - 0.9), S(x + 0.9), S(y0 + 10 + 0.9)], fill=rgba("#5c635c"))
    img = img.filter(ImageFilter.GaussianBlur(0.3 * SS))
    return finish(grain(img, 5, seed), w, h)


# ---------------------------------------------------------------- the market

def stall(canvas=("#b03a2e", "#e8dcc0"), seed=1900):
    """A market stall shut for the night (wall side at the top): its striped
    canvas roof sagging between the poles, crates and baskets peeking out
    at the front."""
    w, h = 160, 96
    img = new(w, h)
    soft_blob(img, S(82), S(52), S(74), S(40), "#000000", 70, 4 * SS)
    rnd = random.Random(seed)
    for k in range(4):  # crates under the front edge
        x = 18 + k * 34 + rnd.uniform(-3, 3)
        paint_shape(img, SP(rrect_pts(x, 66, x + 26, 90, 2)), rnd.choice(["#8a6a42", "#7a5a38"]), seed + k, outline=OUT, ow=1.0,
                    wob=0.2, tex=0.35, light=(0.2, -1, 0.5))
        soft_blob(img, S(x + 13), S(76), S(8), S(5), rnd.choice(["#c84a2a", "#d8b040", "#6a8a3a"]), 220, 1.2 * SS)
    pts = [(6, 6), (154, 6), (152, 74), (80, 70), (8, 74)]
    paint_shape(img, SP(pts), canvas[1], seed + 10, outline=OUT, ow=1.6, wob=0.3, tex=0.2, light=(0, 1, 0.4))
    layer = new(w, h)
    D = ImageDraw.Draw(layer)
    for k in range(0, 160, 20):
        D.polygon(SP([(k, 6), (k + 10, 6), (k + 10, 72), (k, 72)]), fill=rgba(canvas[0]))
    mask = new(w, h)
    ImageDraw.Draw(mask).polygon(SP(pts), fill=(255, 255, 255, 255))
    layer.putalpha(Image.fromarray(__import__("numpy").minimum(__import__("numpy").asarray(layer)[..., 3], __import__("numpy").asarray(mask)[..., 3])))
    img.alpha_composite(layer)
    for x in (8, 152):  # the poles
        soft_blob(img, S(x), S(8), S(2.2), S(2.2), "#3a2a1e", 240, 0.2 * SS)
    sheen(img, [(14, 12), (146, 12), (146, 18), (14, 18)], 40, 1.6)
    return finish(grain(img, 3, seed), w, h)


def sheen(img, pts, alpha=60, blur=2.0):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).polygon(SP(pts), fill=rgba("#ffffff", alpha))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur * SS)))


def pushcart(seed=1910):
    """A pushcart from above: a wooden bed of produce under a tarp tied down,
    two big spoked wheels, the handles."""
    w, h = 96, 64
    img = new(w, h)
    soft_blob(img, S(46), S(34), S(40), S(24), "#000000", 80, 3 * SS)
    for y in (6, 50):
        paint_shape(img, SP(rrect_pts(30, y, 58, y + 8, 3)), "#1c1a18", seed + y, outline=None, wob=0.1, tex=0.2)
    paint_shape(img, SP(rrect_pts(10, 12, 76, 52, 3)), "#7a5a38", seed, outline=OUT, ow=1.2, wob=0.2, tex=0.35, light=(0.2, -1, 0.5))
    paint_shape(img, SP([(14, 16), (72, 15), (74, 48), (12, 49)]), "#6a6a50", seed + 1, outline=(40, 40, 30), ow=0.8, wob=0.5, tex=0.4,
                light=(0.3, -1, 0.5))
    for x in (28, 44, 60):
        line(img, [(S(x), S(14)), (S(x - 3), S(50))], "#3a3a2a", 1.0 * SS, 200)
    for y in (24, 40):
        line(img, [(S(76), S(y)), (S(92), S(y))], "#5a4028", 2.0 * SS, 255)
    return finish(grain(img, 3, seed), w, h)


def fountain(seed=1920):
    """St. Casimir's fountain from above: a round stone basin, dark water with
    the lamps' light in it, the pedestal and its bronze saint in the middle."""
    w = h = 192
    img = new(w, h)
    soft_blob(img, S(98), S(100), S(90), S(88), "#000000", 80, 6 * SS)
    paint_shape(img, SP(ellipse_pts(96, 96, 88, 88)), "#a8a090", seed, outline=OUT, ow=2.0, wob=0.2, tex=0.3, light=(0.3, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(96, 96, 76, 76)), "#1e3440", seed + 1, outline=(50, 50, 46), ow=1.4, wob=0.1, tex=0.2)
    rnd = random.Random(seed)
    for k in range(26):  # ripples and the lamps' light on the water
        a = rnd.uniform(0, 2 * math.pi)
        r = rnd.uniform(30, 70)
        soft_blob(img, S(96 + math.cos(a) * r), S(96 + math.sin(a) * r), S(rnd.uniform(3, 7)), S(1.4), rnd.choice(["#5a7a88", "#c8b070"]),
                  120, 0.6 * SS, rot=a + math.pi / 2)
    paint_shape(img, SP(ellipse_pts(96, 96, 22, 22)), "#b8b0a0", seed + 2, outline=OUT, ow=1.4, wob=0.1, tex=0.25, light=(0.3, -1, 0.6))
    paint_shape(img, SP(ellipse_pts(96, 92, 10, 12)), "#4a6a52", seed + 3, outline=OUT, ow=1.0, wob=0.3, tex=0.3, light=(0.4, -1, 0.6))
    soft_blob(img, S(93), S(88), S(3), S(3), "#9ab09a", 200, 0.6 * SS)
    return finish(grain(img, 3, seed), w, h)


def barge(seed=1930):
    """A canal barge from above: a long black hull, its hold heaped with coal
    under tarpaulins, the little cabin and the tiller aft."""
    w, h = 480, 120
    img = new(w, h)
    soft_blob(img, S(240), S(62), S(232), S(52), "#000000", 70, 6 * SS)
    paint_shape(img, SP([(14, 20), (420, 14), (466, 40), (470, 60), (466, 80), (420, 106), (14, 100), (6, 60)]), "#1e1c1a", seed,
                outline=OUT, ow=2.0, wob=0.2, tex=0.2, light=(0.2, -1, 0.4), inner_shadow=0.3)
    paint_shape(img, SP(rrect_pts(80, 28, 400, 92, 4)), "#2a2622", seed + 1, outline=(40, 36, 30), ow=1.0, wob=0.1, tex=0.3)
    rnd = random.Random(seed)
    for k in range(300):
        x, y = rnd.uniform(86, 394), 60 + rnd.gauss(0, 12)
        if 32 < y < 88:
            soft_blob(img, S(x), S(y), S(rnd.uniform(2, 4)), S(rnd.uniform(2, 3)), rnd.choice(["#141414", "#222224", "#303034"]), 230, 0.3 * SS)
    for x0 in (90, 250):
        paint_shape(img, SP(rrect_pts(x0, 30, x0 + 120, 90, 3)), "#4a4a3a", seed + x0, outline=(30, 30, 24), ow=0.8, wob=0.5,
                    tex=0.4, light=(0.3, -1, 0.5))
    paint_shape(img, SP(rrect_pts(20, 34, 70, 86, 4)), "#5a3a26", seed + 2, outline=OUT, ow=1.2, wob=0.1, tex=0.25, light=(0.2, -1, 0.5))
    soft_blob(img, S(45), S(60), S(6), S(5), "#ffd080", 120, 1.5 * SS)
    return finish(grain(img, 3, seed), w, h)


def lantern_string(seed=1940):
    """A string of red paper lanterns across a shopfront (wall side at the top); the *_lit glow."""
    w, h = 256, 48
    img = new(w, h)
    lit = new(w, h)
    line(img, [(S(4), S(14)), (S(64), S(22)), (S(128), S(16)), (S(192), S(22)), (S(252), S(14))], "#1a1410", 1.0 * SS, 230)
    for k, x in enumerate(range(18, 250, 26)):
        y = 22 + 3 * math.sin(k)
        paint_shape(img, SP(ellipse_pts(x, y, 8, 10)), "#c82a1e", seed + k, outline=OUT, ow=0.8, wob=0.2, light=(0.3, -1, 0.6))
        for yy in (y - 5, y + 5):
            line(img, [(S(x - 7), S(yy)), (S(x + 7), S(yy))], "#e0a040", 0.8 * SS, 200)
        soft_blob(lit, S(x), S(y), S(9), S(11), "#ff9050", 220, 2 * SS)
    return {"props/lanterns": finish(img, w, h), "props/lanterns_lit": finish(lit, w, h)}


# ---------------------------------------------------------------- the terrace

def porte_cochere(seed=1950):
    """The Belvedere's canopy over the pavement (wall side at the top): dark
    bronze edged in gilt, THE BELVEDERE along its front, bulbs under its rim."""
    w, h = 256, 128
    img = new(w, h)
    lit = new(w, h)
    soft_blob(img, S(128), S(70), S(122), S(54), "#000000", 70, 5 * SS)
    paint_shape(img, SP(rrect_pts(6, 4, 250, 118, 8)), "#c8a65a", seed, outline=OUT, ow=1.8, wob=0.2, tex=0.15, light=(0, 1, 0.4))
    paint_shape(img, SP(rrect_pts(14, 10, 242, 110, 6)), "#2a2418", seed + 1, outline=(60, 50, 30), ow=1.0, wob=0.15, tex=0.2)
    for x in range(30, 240, 30):  # deco ribs
        line(img, [(S(x), S(14)), (S(x), S(80))], "#6a5a36", 1.2 * SS, 200)
    text(img, (128, 94), "THE BELVEDERE", 17, "#f0d890", font=DECO, spacing=2.5)
    text(lit, (128, 94), "THE BELVEDERE", 17, "#ffe8a8", font=DECO, spacing=2.5)
    L = ImageDraw.Draw(lit)
    for x in range(16, 244, 10):
        L.ellipse([S(x - 1.8), S(113 - 1.8), S(x + 1.8), S(113 + 1.8)], fill=rgba("#fff0b8"))
    return {"props/porte_cochere": finish(img, w, h), "props/porte_cochere_lit": finish(glow_from(lit, 3 * SS, 0.8), w, h)}


def marquee_paradise(seed=1960):
    """The Paradise Ballroom's marquee (wall side at the top): midnight blue
    with gilt stars, PARADISE BALLROOM in light, chaser bulbs all round."""
    w, h = 320, 96
    img = new(w, h)
    lit = new(w, h)
    soft_blob(img, S(160), S(54), S(154), S(38), "#000000", 70, 5 * SS)
    paint_shape(img, SP(rrect_pts(6, 4, 314, 88, 8)), "#d8c27a", seed, outline=OUT, ow=1.8, wob=0.25, tex=0.15, light=(0, 1, 0.4))
    paint_shape(img, SP(rrect_pts(14, 12, 306, 80, 5)), "#16244a", seed + 1, outline=OUT, ow=1.2, wob=0.2, tex=0.15)
    rnd = random.Random(seed)
    for k in range(24):
        x, y = rnd.uniform(22, 298), rnd.uniform(16, 76)
        soft_blob(img, S(x), S(y), S(1.4), S(1.4), "#f0e0a0", 220, 0.2 * SS)
    text(img, (160, 38), "PARADISE", 26, "#f4e6b0", font=DECO, spacing=3.0)
    text(img, (160, 64), "BALLROOM · DANCING NIGHTLY", 9, "#d8c27a", font=DECO)
    text(lit, (160, 38), "PARADISE", 26, "#bfe0ff", font=DECO, spacing=3.0)
    L = ImageDraw.Draw(lit)
    D = ImageDraw.Draw(img)
    for x in range(14, 308, 10):
        for y in (8, 84):
            L.ellipse([S(x - 1.8), S(y - 1.8), S(x + 1.8), S(y + 1.8)], fill=rgba("#fff0b8"))
            D.ellipse([S(x - 1.8), S(y - 1.8), S(x + 1.8), S(y + 1.8)], fill=rgba("#d9cfa0"))
    return {"props/marquee_paradise": finish(img, w, h), "props/marquee_paradise_lit": finish(glow_from(lit, 3 * SS, 0.8), w, h)}


def dome(seed=1970):
    """The Paradise Ballroom's dome from above: verdigris copper in ribs round
    a little lantern with a gilt finial."""
    w = h = 160
    img = new(w, h)
    soft_blob(img, S(84), S(86), S(74), S(72), "#000000", 80, 6 * SS)
    paint_shape(img, SP(ellipse_pts(80, 80, 72, 72)), "#4e8a76", seed, outline=OUT, ow=2.0, wob=0.15, tex=0.3, light=(0.4, -1, 0.65))
    for k in range(16):
        a = k * math.pi / 8
        line(img, [(S(80 + math.cos(a) * 18), S(80 + math.sin(a) * 18)), (S(80 + math.cos(a) * 70), S(80 + math.sin(a) * 70))],
             "#3a6a5a", 1.6 * SS, 220)
    paint_shape(img, SP(ellipse_pts(80, 80, 18, 18)), "#d8c27a", seed + 1, outline=OUT, ow=1.2, wob=0.05, light=(0.4, -1, 0.7))
    soft_blob(img, S(76), S(76), S(4), S(4), "#fff4c0", 230, 0.6 * SS)
    return finish(grain(img, 3, seed), w, h)


def turret(seed=1980):
    """The old water tower's top from above: a crenellated stone parapet
    round a pointed slate cap, a flagpole."""
    w = h = 128
    img = new(w, h)
    soft_blob(img, S(66), S(68), S(58), S(56), "#000000", 80, 5 * SS)
    paint_shape(img, SP(rrect_pts(8, 8, 120, 120, 4)), "#b8ae98", seed, outline=OUT, ow=1.8, wob=0.2, tex=0.35, light=(0.3, -1, 0.55))
    d = ImageDraw.Draw(img)
    for k in range(10, 120, 14):  # the merlons
        for (x0, y0, x1, y1) in ((k, 8, k + 8, 16), (k, 112, k + 8, 120), (8, k, 16, k + 8), (112, k, 120, k + 8)):
            d.rectangle([S(x0), S(y0), S(x1), S(y1)], fill=rgba("#d0c6ae"))
    paint_shape(img, SP([(64, 22), (106, 64), (64, 106), (22, 64)]), "#3e4650", seed + 1, outline=OUT, ow=1.4, wob=0.05, tex=0.2,
                light=(0.4, -1, 0.6))
    line(img, [(S(64), S(64)), (S(64), S(40))], "#2a2a2a", 1.4 * SS, 255)
    return finish(grain(img, 3, seed), w, h)


def glass_roof(seed=1990):
    """A ridge of glass in iron glazing bars on the market hall's roof, lit from below."""
    w, h = 192, 96
    img = new(w, h)
    paint_shape(img, SP(rrect_pts(4, 4, 188, 92, 3)), "#2c3a40", seed, outline=OUT, ow=1.6, wob=0.1, tex=0.2)
    d = ImageDraw.Draw(img)
    for x in range(12, 188, 12):
        d.line([(S(x), S(6)), (S(x), S(90))], fill=rgba("#1a1a18"), width=2 * SS)
    d.line([(S(4), S(48)), (S(188), S(48))], fill=rgba("#1a1a18"), width=3 * SS)
    soft_blob(img, S(96), S(48), S(80), S(30), "#ffd27a", 70, 8 * SS)
    return finish(grain(img, 3, seed), w, h)


ASSETS = {
    "facades/deco": pb._pack("deco", facade_deco),
    "facades/market": pb._pack("market", facade_market),
    "facades/lantern": pb._pack("lantern", facade_lantern),
    "props/el_deck": el_deck,
    "props/el_column": el_column,
    "props/el_train": el_train,
    "props/rail_bridge": rail_bridge,
    "props/stall_a": lambda: stall(("#b03a2e", "#e8dcc0"), 1900),
    "props/stall_b": lambda: stall(("#2e6a42", "#e8dcc0"), 1901),
    "props/pushcart": pushcart,
    "props/fountain": fountain,
    "props/barge": barge,
    "props/lanterns": lantern_string,
    "props/porte_cochere": porte_cochere,
    "props/marquee_paradise": marquee_paradise,
    "roof/dome": dome,
    "roof/turret": turret,
    "roof/glass": glass_roof,
    "signs/market_hall": lambda: painted_roof_sign("market_hall", "CANAL MARKET HALL", 18, 384, 64),
    "signs/lantern": lambda: painted_roof_sign("lantern", "GOLDEN LANTERN · CHOP SUEY", 15, 384, 64, col="#f0c860"),
    "signs/pawn": lambda: painted_roof_sign("pawn", "A. FELD · LOANS", 18, 256, 64, col="#e8d8a0"),
    "signs/casimir": lambda: painted_roof_sign("casimir", "ST. CASIMIR'S", 22, 256, 64, col="#e8e4d8"),
    "signs/baths": lambda: painted_roof_sign("baths", "CANAL STREET BATHS", 17, 256, 64),
    "signs/belvedere": lambda: painted_roof_sign("belvedere", "THE BELVEDERE", 26, 384, 64, col="#f0dca0"),
    "signs/paradise": lambda: painted_roof_sign("paradise", "PARADISE BALLROOM", 20, 384, 64, col="#d8e4f4"),
}
