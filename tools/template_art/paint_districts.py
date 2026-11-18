"""M008: the art of the two neighbourhoods beyond the Riverside Ward.

The Riverfront Yards (industrial, south along the river): a factory facade with
tall steel-framed windows, plain sooty brick for the smokestacks, a parked
1930s stake truck, a freight boxcar on the sidings and the yards' painted signs.
Halloran Square (residential and shops, west along Marlowe Avenue): a buff
"Chicago common brick" tenement facade with more lit windows, a leafy plane
tree over the square, and the quarter's shop and cinema signs.
Same conventions as the rest: facades 256 x 192 (upper storey above, ground
storey below, horizontally seamless) with a *_lit light image; props top-down,
long axis along +X (nose right for the truck)."""
import math
import random

from PIL import Image, ImageDraw, ImageFilter

from paintkit import *
import paint_buildings as pb
from paint_props import painted_roof_sign

OUT_C = (22, 18, 18)


# ---------------------------------------------------------------- facades

def facade_factory(seed=1100):
    """A works building: sooty brick between pilasters, tall steel-framed windows,
    a sliding freight door at street level."""
    img = pb.brick_wall(["#5a3a2e", "#64402f", "#50342a", "#6b4634"], "#3b302a", seed, bw=18, bh=6)
    lit = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for x in (0, 64, 128, 192):
        d.rectangle([S(x), 0, S(x + 8), S(pb.H)], fill=rgba("#4b3027"))
        d.line([(S(x + 8), 0), (S(x + 8), S(pb.H))], fill=rgba("#2c221d"), width=SS)
    pb.stone_band(d, 0, 4, "#6f685e")
    pb.stone_band(d, 96, 99, "#5f594f", "#2e2924")
    rnd = random.Random(seed)
    for i, x0 in enumerate((14, 78, 142, 206)):
        pb.window(img, lit, x0, 14, 42, 68, seed + i, rnd.random() < 0.35, style="grid", frame="#25282b", lintel="#6a6358",
                  glass="#18212a", light_col=rnd.choice(["#e9d690", "#d9e3a8", "#f0c070"]))
    for i, x0 in enumerate((14, 142, 206)):
        pb.window(img, lit, x0, 112, 42, 52, seed + 10 + i, rnd.random() < 0.3, style="grid", frame="#25282b", lintel=None,
                  glass="#18212a", light_col="#e9d690")
    # the freight door between the second pair of pilasters: planked, on an iron rail
    d.rectangle([S(70), S(104), S(126), S(190)], fill=rgba("#34291f"))
    for k in range(7):
        d.line([(S(70 + k * 8), S(104)), (S(70 + k * 8), S(190))], fill=rgba("#251d16"), width=SS)
    d.line([(S(70), S(146)), (S(126), S(108))], fill=rgba("#251d16"), width=SS)
    d.rectangle([S(66), S(100), S(130), S(104)], fill=rgba("#2a2c2e"))
    d.rectangle([0, S(186), S(pb.W), S(192)], fill=rgba("#3a3530"))
    return pb.finalize(pb.soot(img, 0.35, 0.3), lit)


def facade_tenement(seed=1200):
    """Buff 'Chicago common brick' flats: paired sash windows, more of them lit
    and curtained, a stoop door with a lit transom."""
    img = pb.brick_wall(["#9c7f55", "#a88a5e", "#90744d", "#b09468", "#987a52"], "#6e604c", seed)
    lit = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pb.stone_band(d, 0, 6, "#b9b0a0", "#5a544b")
    pb.stone_band(d, 96, 99, "#b0a796", "#5a544b")
    rnd = random.Random(seed)
    curtains = ["#8a3030", "#36506a", "#7a6a2c", "#4a6a3a", None, "#7a4a62"]
    for i, cx in enumerate((30, 72, 156, 198)):
        pb.window(img, lit, cx - 14, 22, 28, 50, seed + i, rnd.random() < 0.72, curtain=rnd.choice(curtains),
                  light_col=rnd.choice(pb.WARM))
    pb.door(d, 100, 122, 30, 64, color="#2f2620")
    for i, cx in enumerate((32, 70, 176, 220)):
        pb.window(img, lit, cx - 14, 116, 28, 48, seed + 10 + i, rnd.random() < 0.65, curtain=rnd.choice(curtains),
                  light_col=rnd.choice(pb.WARM))
    d.rectangle([0, S(182), S(pb.W), S(192)], fill=rgba("#6b655c"))
    ImageDraw.Draw(lit).rectangle([S(102), S(124), S(128), S(131)], fill=rgba("#ffd27a", 210))
    return pb.finalize(pb.soot(img, 0.15, 0.18), lit)


def facade_stack(seed=1300):
    """A works smokestack's walls: small dark brick, iron bands, soot thickest at the top."""
    img = pb.brick_wall(["#4a2e26", "#55342a", "#3f2822", "#5c3a2e"], "#2e2622", seed, bw=12, bh=5)
    d = ImageDraw.Draw(img)
    pb.stone_band(d, 0, 4, "#6a645a")
    for y in (40, 136):
        d.rectangle([0, S(y), S(pb.W), S(y + 3)], fill=rgba("#26282a"))
        for x in range(4, pb.W, 32):
            d.ellipse([S(x), S(y + 0.5), S(x + 2), S(y + 2.5)], fill=rgba("#55585a"))
    return pb.finalize(pb.soot(img, 0.55, 0.25), None)


# ---------------------------------------------------------------- props

def truck(cab="#2f4434", seed=21):
    """A parked 1930s stake truck from above, nose right: a long bonnet and
    cab, a planked bed with stake sides and a lashed tarpaulin."""
    w, h = 224, 96
    img = new(w, h)
    soft_blob(img, S(112), S(50), S(104), S(40), "#000000", 70, 6 * SS)
    for x0 in (36, 70, 168):  # the tyres show at the sides
        paint_shape(img, SP(rrect_pts(x0, 8, x0 + 22, 15, 2.5)), "#141414", seed + x0, outline=None, wob=0.1, tex=0.2)
        paint_shape(img, SP(rrect_pts(x0, 81, x0 + 22, 88, 2.5)), "#141414", seed + x0 + 1, outline=None, wob=0.1, tex=0.2)
    # the bed: planks inside stake sides
    paint_shape(img, SP(rrect_pts(10, 13, 140, 83, 2)), "#6a4a2e", seed, outline=OUT_C, ow=1.6, wob=0.2, tex=0.3,
                light=(0.3, -1, 0.4))
    d = ImageDraw.Draw(img)
    for y in range(18, 82, 7):
        d.line([(S(13), S(y)), (S(137), S(y))], fill=rgba("#4e3520"), width=SS)
    for x in range(14, 140, 18):
        d.rectangle([S(x), S(12), S(x + 3), S(16)], fill=rgba("#3a2818"))
        d.rectangle([S(x), S(80), S(x + 3), S(84)], fill=rgba("#3a2818"))
    # a tarpaulin lashed over the load at the back
    paint_shape(img, SP([(16, 20), (96, 19), (100, 48), (96, 77), (16, 76), (13, 48)]), "#5d6248", seed + 3, outline=OUT_C,
                ow=1.2, wob=0.6, tex=0.35, strokes_n=10, stroke_cols=["#6e7458", "#4a4e3a"], light=(0.3, -1, 0.5))
    for x in (34, 58, 82):
        line(img, [(S(x), S(19)), (S(x - 2), S(77))], "#2a2418", 1.2 * SS, 220)
    # cab and bonnet
    paint_shape(img, SP(rrect_pts(140, 17, 176, 79, 5)), cab, seed + 4, outline=OUT_C, ow=1.6, wob=0.2, tex=0.2,
                light=(0.3, -1, 0.5))
    paint_shape(img, SP([(176, 24), (206, 28), (214, 36), (214, 60), (206, 68), (176, 72)]), shade(cab, 1.08), seed + 5,
                outline=OUT_C, ow=1.5, wob=0.2, tex=0.2, light=(0.4, -1, 0.5))
    for y in range(32, 66, 4):  # bonnet louvres
        d.line([(S(184), S(y)), (S(198), S(y))], fill=rgba(shade(cab, 0.7)), width=SS)
    paint_shape(img, SP([(168, 22), (176, 24), (176, 72), (168, 74)]), "#6f97b2", seed + 6, outline=OUT_C, ow=1.0, wob=0.1,
                light=(1, -1, 0.6))
    line(img, [(S(170), S(28)), (S(174), S(40))], "#e6f2fa", 1.0 * SS, 180)
    # radiator and headlamps at the nose; red lamp at the tail
    paint_shape(img, SP(rrect_pts(212, 34, 218, 62, 1.5)), "#cfd2d4", seed + 7, outline=OUT_C, ow=1.0, wob=0.05,
                light=(1, -1, 0.4))
    for y in (26, 70):
        paint_shape(img, SP(ellipse_pts(208, y, 4.2, 3.8)), "#cfd2d4", seed + y, outline=OUT_C, ow=0.9, wob=0.1)
        soft_blob(img, S(209), S(y), S(2.2), S(2.2), "#e9e4c8", 230, 0.5 * SS)
    soft_blob(img, S(11), S(20), S(2.6), S(2.6), "#c8322a", 240, 0.6 * SS)
    return finish(img, w, h)


def boxcar(body="#6a2f22", seed=31):
    """A freight boxcar on the sidings from above: a long rusty-red roof with
    ribs and a plank running board down the middle, couplers at both ends."""
    w, h = 320, 96
    img = new(w, h)
    soft_blob(img, S(160), S(50), S(156), S(42), "#000000", 80, 6 * SS)
    paint_shape(img, SP(rrect_pts(12, 12, 308, 84, 3)), body, seed, outline=OUT_C, ow=1.8, wob=0.2, tex=0.3,
                strokes_n=18, stroke_cols=[shade(body, 1.2), shade(body, 0.8)], light=(0.3, -1, 0.4))
    d = ImageDraw.Draw(img)
    for x in range(26, 300, 18):
        d.line([(S(x), S(13)), (S(x), S(83))], fill=rgba(shade(body, 0.72)), width=SS)
    # the running board (catwalk) along the roof
    paint_shape(img, SP(rrect_pts(16, 43, 304, 53, 1)), "#5a4632", seed + 1, outline=OUT_C, ow=0.9, wob=0.1, tex=0.4)
    for x in range(20, 302, 9):
        d.line([(S(x), S(43.5)), (S(x), S(52.5))], fill=rgba("#3d2f22"), width=1)
    for x in (12, 308):  # couplers
        paint_shape(img, SP(rrect_pts(x - 6, 44, x + 6, 52, 1)), "#2a2a2c", seed + x, outline=OUT_C, ow=0.8, wob=0.05)
    for x, y in ((40, 20), (280, 76)):  # hand brakes
        paint_shape(img, SP(ellipse_pts(x, y, 4, 4)), "#2a2a2c", seed + x + y, outline=OUT_C, ow=0.8, wob=0.05)
    return finish(img, w, h)


def tree(seed=41):
    """A plane tree's crown from above: clumps of dark leaves, lighter where
    the lamps catch them, the trunk hidden beneath."""
    w = h = 192
    img = new(w, h)
    rnd = random.Random(seed)
    soft_blob(img, S(100), S(104), S(86), S(82), "#000000", 70, 10 * SS)
    clumps = [(96, 96, 52)]
    for k in range(13):
        a = rnd.uniform(0, 2 * math.pi)
        r = rnd.uniform(18, 58)
        clumps.append((96 + math.cos(a) * r, 96 + math.sin(a) * r, rnd.uniform(18, 30)))
    for k, (cx, cy, r) in enumerate(clumps):
        col = rnd.choice(["#2f4a2c", "#355232", "#2a4228", "#3b5a35"])
        paint_shape(img, SP(ellipse_pts(cx, cy, r, r * rnd.uniform(0.85, 1.05))), col, seed + k, outline=OUT_C, ow=1.2,
                    wob=0.9, tex=0.45, strokes_n=12, stroke_cols=[shade(col, 1.35), shade(col, 0.75)], light=(0.4, -1, 0.5))
    for k in range(40):  # leaves catching the light
        x, y = rnd.uniform(40, 152), rnd.uniform(40, 152)
        if (x - 96) ** 2 + (y - 96) ** 2 < 70 ** 2:
            soft_blob(img, S(x), S(y), S(2.4), S(1.8), "#6e8a52", 120, 0.6 * SS)
    return finish(img, w, h)


ASSETS = {
    "facades/factory": pb._pack("factory", facade_factory),
    "facades/tenement": pb._pack("tenement", facade_tenement),
    "facades/stack": pb._pack("stack", facade_stack),
    "props/truck": truck,
    "props/truck_b": lambda: truck("#5a3a2a", 22),
    "props/boxcar": boxcar,
    "props/tree": tree,
    # the Riverfront Yards
    "signs/coal": lambda: painted_roof_sign("coal", "BRENNAN COAL & ICE", 18, 384, 64),
    "signs/tannery": lambda: painted_roof_sign("tannery", "GREAT LAKES TANNING CO.", 17, 384, 64),
    "signs/freight": lambda: painted_roof_sign("freight", "NORTH BRANCH FREIGHT", 17, 384, 64, col="#d8d2c0"),
    "signs/lunch": lambda: painted_roof_sign("lunch", "DUTCH'S NIGHT LUNCH", 17, 256, 64, col="#f2dca0"),
    # Halloran Square
    "signs/bijou": lambda: painted_roof_sign("bijou", "THE BIJOU", 28, 256, 64, col="#f4e2a8"),
    "signs/bakery": lambda: painted_roof_sign("bakery", "KOWALSKI BAKERY", 18, 256, 64),
    "signs/drugstore": lambda: painted_roof_sign("drugstore", "HALLORAN DRUGS", 18, 256, 64),
    "signs/church": lambda: painted_roof_sign("church", "ST. BRENDAN'S", 22, 256, 64, col="#e8e4d8"),
}
