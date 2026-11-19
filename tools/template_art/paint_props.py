"""Street props, ground decals, rooftop furniture, signs, effects and UI pieces.
All top-down, transparent backgrounds, centred."""
import math
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from paintkit import *

OUT = (24, 20, 18)
IRON = "#26282b"
DECO = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
SANS = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def lamp_head():
    w = h = 64
    img = new(w, h)
    c = 32
    # four-sided lantern hood (iron) with the glass panes showing at the edges
    paint_shape(img, SP(ellipse_pts(c, c, 17, 17, n=8, rot=math.pi / 8)), "#d9cfa6", 1, outline=OUT, ow=1.2, wob=0.2, tex=0.1)
    paint_shape(img, SP(ellipse_pts(c, c, 13, 13, n=8, rot=math.pi / 8)), IRON, 2, outline=OUT, ow=1.2, wob=0.2, tex=0.2,
                light=(0.5, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(c, c, 6, 6, n=8, rot=math.pi / 8)), "#3a3d41", 3, outline=OUT, ow=1, wob=0.1, light=(0.5, -1, 0.6))
    paint_shape(img, SP(ellipse_pts(c, c, 2.4, 2.4)), "#8a8d90", 4, outline=None, wob=0.05)
    return finish(img, w, h)


def lamp_base():
    w = h = 32
    img = new(w, h)
    paint_shape(img, SP(ellipse_pts(16, 16, 11, 11, n=12)), IRON, 1, outline=OUT, ow=1.2, wob=0.2, tex=0.2, light=(0.4, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(16, 16, 5.5, 5.5)), "#3b3e43", 2, outline=OUT, ow=1, wob=0.1, light=(0.4, -1, 0.6))
    return finish(img, w, h)


def hydrant():
    w = h = 40
    img = new(w, h)
    for a in (0, math.pi):
        x, y = 20 + math.cos(a) * 11, 20 + math.sin(a) * 11
        paint_shape(img, SP(ellipse_pts(x, y, 4, 3.4)), "#8c2a22", 1 + a, outline=OUT, ow=1, wob=0.1)
    paint_shape(img, SP(ellipse_pts(20, 20, 9.5, 9.5)), "#a8342a", 3, outline=OUT, ow=1.3, wob=0.25, tex=0.2, light=(0.4, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(20, 20, 5, 5, n=5)), "#c9b26a", 4, outline=OUT, ow=1, wob=0.1, light=(0.4, -1, 0.5))
    return finish(img, w, h)


def trash_can():
    w = h = 48
    img = new(w, h)
    paint_shape(img, SP(ellipse_pts(24, 24, 15, 15)), "#7d8287", 1, outline=OUT, ow=1.4, wob=0.3, tex=0.2, light=(0.4, -1, 0.5))
    d = ImageDraw.Draw(img)
    for r in (11, 7):
        layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ImageDraw.Draw(layer).ellipse([S(24 - r), S(24 - r), S(24 + r), S(24 + r)], outline=rgba("#5d6166", 200), width=SS)
        img.alpha_composite(layer)
    paint_shape(img, SP(rrect_pts(17, 22.5, 31, 25.5, 1.5)), "#4a4e52", 2, outline=OUT, ow=0.8, wob=0.1)
    return finish(img, w, h)


def crate(seed=1):
    w = h = 64
    img = new(w, h)
    paint_shape(img, SP(rrect_pts(8, 8, 56, 56, 2)), "#8a6440", seed, outline=OUT, ow=1.6, wob=0.4, tex=0.25, light=(0.4, -1, 0.4))
    for k in range(4):
        y = 8 + k * 12
        line(img, [(S(9), S(y)), (S(55), S(y))], "#5a3e26", 1.3 * SS, 220)
    line(img, [(S(10), S(10)), (S(54), S(54))], "#6b4a2e", 2.2 * SS, 230)
    text(img, (32, 34), "XXX", 8, "#3a2a1c", font=SANS)
    return finish(img, w, h)


def crates():
    w = h = 96
    img = new(w, h)
    c1 = crate(2).resize((S(44), S(44)), Image.LANCZOS)
    c2 = crate(3).resize((S(44), S(44)), Image.LANCZOS).rotate(12, expand=False)
    c3 = crate(4).resize((S(48), S(48)), Image.LANCZOS).rotate(-6, expand=False)
    soft_blob(img, S(48), S(52), S(40), S(36), "#000000", 70, 6 * SS)
    img.alpha_composite(c1, (S(6), S(40)))
    img.alpha_composite(c2, (S(46), S(42)))
    img.alpha_composite(c3, (S(24), S(8)))
    return finish(img, w, h)


def barrel():
    w = h = 48
    img = new(w, h)
    paint_shape(img, SP(ellipse_pts(24, 24, 17, 17)), "#7a4c2a", 1, outline=OUT, ow=1.4, wob=0.2, tex=0.25, light=(0.4, -1, 0.4))
    for k in range(12):
        a = 2 * math.pi * k / 12
        line(img, [(S(24 + math.cos(a) * 9), S(24 + math.sin(a) * 9)), (S(24 + math.cos(a) * 16.5), S(24 + math.sin(a) * 16.5))],
             "#55331b", SS, 200)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse([S(8), S(8), S(40), S(40)], outline=rgba("#2c2c2e", 255), width=2 * SS)
    img.alpha_composite(layer)
    paint_shape(img, SP(ellipse_pts(24, 24, 9, 9)), "#8a5a34", 2, outline=OUT, ow=1, wob=0.1, tex=0.2)
    paint_shape(img, SP(ellipse_pts(27, 22, 1.8, 1.8)), "#2a1a10", 3, outline=None, wob=0.05)
    return finish(img, w, h)


def barricade():
    w, h = 192, 64
    img = new(w, h)
    # splayed sawhorse legs
    for x in (24, 168):
        for dy in (-14, 14):
            line(img, [(S(x), S(32)), (S(x + (6 if x < 96 else -6)), S(32 + dy))], "#5a4630", 3 * SS, 255)
    paint_shape(img, SP(rrect_pts(8, 24, 184, 40, 2)), "#e8e0cc", 1, outline=OUT, ow=1.6, wob=0.3, tex=0.15)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for x in range(0, w + 16, 22):
        d.polygon([(S(x), S(24)), (S(x + 11), S(24)), (S(x - 5), S(40)), (S(x - 16), S(40))], fill=rgba("#a3261c"))
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rectangle([S(9), S(25), S(183), S(39)], fill=255)
    stripes = Image.new("RGBA", img.size, (0, 0, 0, 0))
    stripes.paste(layer, (0, 0), mask)
    img.alpha_composite(stripes)
    paint_shape(img, SP(rrect_pts(62, 26.5, 130, 37.5, 1.5)), "#efe7d2", 2, outline=OUT, ow=0.8, wob=0.1)
    text(img, (96, 32.3), "STREET CLOSED", 7, "#1f1a16", font=SANS)
    return finish(img, w, h)


def lantern():
    w = h = 32
    img = new(w, h)
    paint_shape(img, SP(ellipse_pts(16, 16, 8, 8)), "#c4372a", 1, outline=OUT, ow=1.2, wob=0.15, light=(0.3, -1, 0.6))
    paint_shape(img, SP(ellipse_pts(16, 16, 4, 4)), IRON, 2, outline=OUT, ow=1, wob=0.1)
    line(img, [(S(8), S(16)), (S(24), S(16))], IRON, 1.4 * SS, 255)
    return finish(img, w, h)


def mailbox():
    w = h = 40
    img = new(w, h)
    paint_shape(img, SP(rrect_pts(8, 11, 32, 29, 7)), "#3e5034", 1, outline=OUT, ow=1.3, wob=0.25, tex=0.2, light=(0, -1, 0.6))
    line(img, [(S(10), S(20)), (S(30), S(20))], "#2c3a25", 1.2 * SS, 230)
    text(img, (20, 15.5), "U.S.MAIL", 3.4, "#d8cfa6", font=SANS)
    return finish(img, w, h)


def gas_pump():
    w = h = 48
    img = new(w, h)
    paint_shape(img, SP(rrect_pts(12, 12, 36, 36, 4)), "#b0281f", 1, outline=OUT, ow=1.4, wob=0.25, tex=0.2, light=(0.4, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(24, 24, 8.5, 8.5)), "#ece6d0", 2, outline=OUT, ow=1.2, wob=0.15, light=(0.4, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(24, 24, 4, 4)), "#c99a3a", 3, outline=None, wob=0.1)
    line(img, [(S(36), S(28)), (S(42), S(34)), (S(40), S(40))], "#1a1a1a", 1.8 * SS, 255)
    return finish(img, w, h)


def newsstand():
    w, h = 96, 64
    img = new(w, h)
    paint_shape(img, SP(rrect_pts(8, 10, 88, 54, 3)), "#4a3a28", 1, outline=OUT, ow=1.6, wob=0.3, tex=0.25, light=(0.3, -1, 0.4))
    paint_shape(img, SP([(4, 8), (92, 8), (88, 26), (8, 26)]), "#2f4a3a", 2, outline=OUT, ow=1.4, wob=0.3, tex=0.2,
                light=(0, -1, 0.5))
    rnd = random.Random(3)
    for k in range(7):
        x = 12 + k * 11
        paint_shape(img, SP(rrect_pts(x, 32, x + 9, 50, 1)), rnd.choice(["#e8e2cf", "#d9d0b6", "#efe8d4"]), 10 + k,
                    outline=OUT, ow=0.6, wob=0.1, tex=0.05)
        line(img, [(S(x + 1.5), S(35)), (S(x + 7.5), S(35))], "#2a2a2a", SS, 200)
        line(img, [(S(x + 1.5), S(39)), (S(x + 7.5), S(39))], "#555555", SS, 160)
    return finish(img, w, h)


def awning(c1="#9e2b25", c2="#e9dcc0", seed=1):
    w, h = 160, 64
    img = new(w, h)
    soft_blob(img, S(80), S(36), S(74), S(22), "#000000", 60, 4 * SS)
    base = [(4, 6), (156, 6), (156, 50), (4, 50)]
    paint_shape(img, SP(base), c2, seed, outline=None, wob=0.3, tex=0.12, light=(0, 1, 0.35))
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for x in range(4, 156, 16):
        d.rectangle([S(x), S(6), S(x + 8), S(56)], fill=rgba(c1))
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(SP(base), fill=255)
    st = Image.new("RGBA", img.size, (0, 0, 0, 0))
    st.paste(layer, (0, 0), mask)
    img.alpha_composite(st)
    # scalloped valance at the street edge (bottom)
    for x in range(4, 156, 8):
        col = c1 if ((x - 4) // 8) % 2 == 0 else c2
        paint_shape(img, SP(ellipse_pts(x + 4, 51, 4.3, 4)), col, seed + x, outline=OUT, ow=0.8, wob=0.1, tex=0.1)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).polygon(SP(base), outline=rgba(OUT, 220), width=SS)
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(0.4 * SS)))
    # shading towards the wall (top) where it is folded
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rectangle([S(4), S(6), S(156), S(14)], fill=(0, 0, 0, 70))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(2 * SS)))
    return finish(img, w, h)


def marquee():
    """The Copper Owl's canopy over the sidewalk (wall side at the top)."""
    w, h = 256, 96
    img = new(w, h)
    lit = new(w, h)
    soft_blob(img, S(128), S(54), S(122), S(38), "#000000", 70, 5 * SS)
    paint_shape(img, SP(rrect_pts(6, 4, 250, 86, 6)), "#b8743a", 1, outline=OUT, ow=1.8, wob=0.3, tex=0.18, light=(0, 1, 0.4))
    paint_shape(img, SP(rrect_pts(14, 12, 242, 78, 4)), "#1a2622", 2, outline=OUT, ow=1.2, wob=0.2, tex=0.15)
    text(img, (128, 40), "COPPER OWL", 25, "#e8c88a", font=DECO, spacing=2.5)
    text(img, (128, 64), "· SUPPER CLUB · DANCING ·", 8.5, "#b8743a", font=DECO)
    text(lit, (128, 40), "COPPER OWL", 25, "#ffcf7a", font=DECO, spacing=2.5)
    L = ImageDraw.Draw(lit)
    for x in range(14, 246, 9):
        for y in (8, 82):
            L.ellipse([S(x - 1.8), S(y - 1.8), S(x + 1.8), S(y + 1.8)], fill=rgba("#fff0b8"))
            ImageDraw.Draw(img).ellipse([S(x - 1.8), S(y - 1.8), S(x + 1.8), S(y + 1.8)], fill=rgba("#d9cfa0"))
    for y in range(14, 80, 9):
        for x in (10, 246):
            L.ellipse([S(x - 1.8), S(y - 1.8), S(x + 1.8), S(y + 1.8)], fill=rgba("#fff0b8"))
            ImageDraw.Draw(img).ellipse([S(x - 1.8), S(y - 1.8), S(x + 1.8), S(y + 1.8)], fill=rgba("#d9cfa0"))
    return {"props/marquee": finish(img, w, h), "props/marquee_lit": finish(glow_from(lit, 3 * SS, 0.8), w, h)}


# ---------------------------------------------------------------- decals

def manhole():
    w = h = 48
    img = new(w, h)
    paint_shape(img, SP(ellipse_pts(24, 24, 18, 18)), "#3a3b3e", 1, outline=OUT, ow=1.2, wob=0.15, tex=0.3)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for r in (14, 9):
        d.ellipse([S(24 - r), S(24 - r), S(24 + r), S(24 + r)], outline=rgba("#4e5054", 230), width=SS)
    for k in range(8):
        a = math.pi * k / 4
        d.line([(S(24 + math.cos(a) * 9), S(24 + math.sin(a) * 9)), (S(24 + math.cos(a) * 14), S(24 + math.sin(a) * 14))],
               fill=rgba("#4e5054", 230), width=SS)
    img.alpha_composite(layer)
    text(img, (24, 24.5), "C.W.D.", 5, "#56585c", font=SANS)
    return finish(img, w, h)


def drain():
    w, h = 48, 24
    img = new(w, h)
    paint_shape(img, SP(rrect_pts(4, 4, 44, 20, 2)), "#2a2b2d", 1, outline=OUT, ow=1, wob=0.1, tex=0.2)
    for x in range(8, 42, 4):
        line(img, [(S(x), S(6)), (S(x), S(18))], "#0c0c0d", 1.6 * SS, 255, blur=0)
    return finish(img, w, h)


def puddle(seed=1):
    w, h = 128, 80
    img = new(w, h)
    rnd = random.Random(seed)
    pts = []
    for i in range(24):
        a = 2 * math.pi * i / 24
        r = 1 + 0.18 * math.sin(a * 3 + seed) + rnd.uniform(-0.08, 0.08)
        pts.append((64 + math.cos(a) * 56 * r, 40 + math.sin(a) * 30 * r))
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(SP(pts), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(3 * SS))
    n = tnoise(img.size[0], img.size[1], 4, seed, octaves=3)
    col = ramp(n, ["#141a22", "#1b2430", "#25303f"])
    a = np.asarray(col).copy()
    m = np.asarray(mask, dtype=np.float32) / 255.0
    # a thin light rim where the water meets the street, and a soft sky sheen
    rim = np.clip(m * (1.0 - m) * 4.0, 0, 1)
    a[..., :3] = np.clip(a[..., :3] + (rim[..., None] * np.array([70, 80, 95])), 0, 255)
    yy, xx = np.mgrid[0:a.shape[0], 0:a.shape[1]].astype(np.float32)
    sheen = np.clip(1.0 - np.hypot((xx - a.shape[1] * 0.42) / (a.shape[1] * 0.3), (yy - a.shape[0] * 0.4) / (a.shape[0] * 0.25)), 0, 1)
    a[..., :3] = np.clip(a[..., :3] + sheen[..., None] * np.array([28, 34, 44]), 0, 255)
    a[..., 3] = (m * 0.82 * 255).astype(np.uint8)
    img = Image.fromarray(a.astype(np.uint8), "RGBA")
    return finish(img, w, h)


def litter():
    w = h = 48
    img = new(w, h)
    pts = [(10, 14), (36, 10), (40, 34), (14, 38)]
    paint_shape(img, SP(pts), "#d6cfba", 1, outline=(80, 70, 60), ow=0.8, wob=0.6, tex=0.1)
    for k in range(5):
        line(img, [(S(16), S(17 + k * 4)), (S(33), S(14 + k * 4))], "#6b665c", 0.8 * SS, 150)
    return finish(img, w, h)


def oil():
    w = h = 96
    img = new(w, h)
    for k, (x, y, r) in enumerate(((48, 48, 26), (34, 56, 14), (62, 38, 12))):
        soft_blob(img, S(x), S(y), S(r), S(r * 0.8), "#0e0d0c", 120, 4 * SS)
    soft_blob(img, S(44), S(46), S(10), S(5), "#5a4a7a", 40, 3 * SS)
    return finish(img, w, h)


# ---------------------------------------------------------------- rooftop furniture

def chimney():
    w = h = 48
    img = new(w, h)
    soft_blob(img, S(28), S(28), S(16), S(14), "#000000", 90, 3 * SS)
    paint_shape(img, SP(rrect_pts(10, 12, 38, 36, 2)), "#6e3d30", 1, outline=OUT, ow=1.4, wob=0.3, tex=0.3, light=(0.4, -1, 0.5))
    for y in range(15, 36, 4):
        line(img, [(S(11), S(y)), (S(37), S(y))], "#4e2c22", SS, 180)
    paint_shape(img, SP(rrect_pts(15, 17, 33, 31, 2)), "#141210", 2, outline=OUT, ow=1, wob=0.2, tex=0.2)
    paint_shape(img, SP(rrect_pts(9, 11, 39, 14, 1)), "#8a8276", 3, outline=None, wob=0.1)
    return finish(img, w, h)


def vent():
    w = h = 32
    img = new(w, h)
    soft_blob(img, S(18), S(18), S(11), S(10), "#000000", 90, 2 * SS)
    paint_shape(img, SP(ellipse_pts(16, 16, 10, 10)), "#8a8f94", 1, outline=OUT, ow=1.2, wob=0.15, tex=0.2, light=(0.4, -1, 0.6))
    paint_shape(img, SP(ellipse_pts(16, 16, 3.5, 3.5)), "#5d6267", 2, outline=None, wob=0.1)
    return finish(img, w, h)


def skylight():
    w, h = 96, 64
    img = new(w, h)
    lit = new(w, h)
    soft_blob(img, S(52), S(36), S(42), S(26), "#000000", 80, 3 * SS)
    paint_shape(img, SP(rrect_pts(6, 6, 90, 58, 3)), "#4e5258", 1, outline=OUT, ow=1.4, wob=0.2, tex=0.2)
    d = ImageDraw.Draw(img)
    L = ImageDraw.Draw(lit)
    rnd = random.Random(4)
    for i in range(4):
        for j in range(2):
            x0, y0 = 10 + i * 20, 10 + j * 23
            d.rectangle([S(x0), S(y0), S(x0 + 17), S(y0 + 20)], fill=rgba("#33465a"))
            d.line([(S(x0 + 2), S(y0 + 17)), (S(x0 + 12), S(y0 + 3))], fill=rgba("#6d8aa6"), width=SS)
            if rnd.random() < 0.6:
                L.rectangle([S(x0), S(y0), S(x0 + 17), S(y0 + 20)], fill=rgba(rnd.choice(["#e8a850", "#d99a48", "#f0b860"]), rnd.randint(90, 150)))
    return {"roof/skylight": finish(img, w, h), "roof/skylight_lit": finish(glow_from(lit, 3 * SS, 0.6), w, h)}


def cupola():
    """M011: City Hall's copper cupola from above: a verdigris dome on a stone drum, ribbed, with a
    lantern and a gilt finial at its crown."""
    w = h = 128
    img = new(w, h)
    soft_blob(img, S(70), S(70), S(52), S(52), "#000000", 130, 8 * SS)
    paint_shape(img, SP(ellipse_pts(64, 64, 56, 56, n=72)), "#b8b1a0", 1, outline=OUT, ow=1.6, wob=0.2, tex=0.2,
                light=(0.4, -1, 0.4))  # the stone drum
    for k in range(12):
        a = 2 * math.pi * k / 12
        paint_shape(img, SP(ellipse_pts(64 + math.cos(a) * 51, 64 + math.sin(a) * 51, 3.4, 3.4)), "#d8d0bc", 10 + k,
                    outline=OUT, ow=0.6, wob=0.05)  # little columns round the drum
    paint_shape(img, SP(ellipse_pts(64, 64, 45, 45, n=72)), "#4f8a74", 2, outline=OUT, ow=1.4, wob=0.15, tex=0.25,
                strokes_n=16, stroke_cols=["#6aa48c", "#3c6e5c"], light=(0.4, -1, 0.6), inner_shadow=0.3)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for k in range(16):
        a = 2 * math.pi * k / 16
        d.line([(S(64 + math.cos(a) * 12), S(64 + math.sin(a) * 12)), (S(64 + math.cos(a) * 44), S(64 + math.sin(a) * 44))],
               fill=rgba("#2f5a4a", 170), width=SS)
    img.alpha_composite(layer)
    paint_shape(img, SP(ellipse_pts(64, 64, 13, 13)), "#c8c0aa", 3, outline=OUT, ow=1.0, wob=0.1, light=(0.4, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(64, 64, 6, 6)), "#e0b84a", 4, outline=OUT, ow=0.8, wob=0.05, light=(0.4, -1, 0.7))
    soft_blob(img, S(52), S(46), S(14), S(8), "#ffffff", 50, 4 * SS, rot=-0.6)
    return finish(img, w, h)


def stair_hut():
    w = h = 96
    img = new(w, h)
    soft_blob(img, S(54), S(54), S(38), S(36), "#000000", 110, 5 * SS)
    paint_shape(img, SP(rrect_pts(14, 14, 82, 82, 2)), "#6a3d31", 1, outline=OUT, ow=1.6, wob=0.4, tex=0.25, light=(0.4, -1, 0.4))
    paint_shape(img, SP(rrect_pts(18, 18, 78, 78, 2)), "#414045", 2, outline=OUT, ow=1.2, wob=0.3, tex=0.25, light=(0.4, -1, 0.4))
    for y in range(24, 78, 10):
        line(img, [(S(19), S(y)), (S(77), S(y))], "#353438", SS, 200)
    paint_shape(img, SP(rrect_pts(84, 34, 92, 62, 1)), "#4a3426", 3, outline=OUT, ow=1, wob=0.1)  # door seen edge-on
    return finish(img, w, h)


def water_tank():
    w = h = 112
    img = new(w, h)
    soft_blob(img, S(64), S(64), S(44), S(42), "#000000", 120, 6 * SS)
    for a in (0.6, 2.2, 3.8, 5.4):
        x, y = 56 + math.cos(a) * 42, 56 + math.sin(a) * 42
        paint_shape(img, SP(rrect_pts(x - 3, y - 3, x + 3, y + 3, 1)), IRON, int(a * 10), outline=OUT, ow=0.8, wob=0.1)
    paint_shape(img, SP(ellipse_pts(56, 56, 38, 38)), "#7a5636", 1, outline=OUT, ow=1.8, wob=0.4, tex=0.25, light=(0.4, -1, 0.4))
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for k in range(16):
        a = 2 * math.pi * k / 16
        d.line([(S(56), S(56)), (S(56 + math.cos(a) * 37), S(56 + math.sin(a) * 37))], fill=rgba("#5a3e26", 200), width=SS)
    img.alpha_composite(layer)
    paint_shape(img, SP(ellipse_pts(56, 56, 10, 10)), "#3a3c40", 2, outline=OUT, ow=1.2, wob=0.2, light=(0.4, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(56, 56, 3, 3)), "#6c7075", 3, outline=None, wob=0.1)
    return finish(img, w, h)


def laundry():
    w, h = 128, 64
    img = new(w, h)
    for y in (18, 42):
        line(img, [(S(6), S(y)), (S(122), S(y + 2))], "#c9c2b0", 0.9 * SS, 220)
    rnd = random.Random(7)
    for y in (18, 42):
        x = 12
        while x < 112:
            wdt = rnd.uniform(10, 18)
            col = rnd.choice(["#e9e4d6", "#c9d2dc", "#b54a3a", "#e4d3a1", "#7d8ca8", "#f2efe6"])
            paint_shape(img, SP([(x, y + 1), (x + wdt, y + 1.5), (x + wdt - 1, y + 9), (x + 1, y + 8.5)]), col, int(x * 3 + y),
                        outline=OUT, ow=0.8, wob=0.3, tex=0.1, light=(0, 1, 0.3))
            x += wdt + rnd.uniform(3, 8)
    for x in (6, 122):
        paint_shape(img, SP(ellipse_pts(x, 30, 2.5, 16)), "#3e3a36", x, outline=OUT, ow=0.8, wob=0.1)
    return finish(img, w, h)


def fire_escape():
    """An iron fire-escape landing seen from above; the wall is along the top edge."""
    w, h = 128, 40
    img = new(w, h)
    soft_blob(img, S(66), S(26), S(60), S(14), "#000000", 90, 3 * SS)
    paint_shape(img, SP(rrect_pts(4, 2, 124, 34, 2)), "#1b1c1f", 1, outline=OUT, ow=1.4, wob=0.2, tex=0.2)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for x in range(8, 122, 5):
        d.line([(S(x), S(5)), (S(x), S(31))], fill=rgba("#3e4046", 230), width=SS)
    d.line([(S(6), S(18)), (S(122), S(18))], fill=rgba("#3e4046", 230), width=SS)
    img.alpha_composite(layer)
    # railing round the open sides, the stair hatch and a drop ladder
    line(img, [(S(4), S(3)), (S(4), S(34)), (S(124), S(34)), (S(124), S(3))], "#56595f", 2.2 * SS, 255, blur=0.2)
    for x in range(4, 126, 12):
        paint_shape(img, SP(ellipse_pts(x, 34, 1.6, 1.6)), "#6a6d73", x, outline=None, wob=0.05)
    paint_shape(img, SP(rrect_pts(84, 8, 116, 28, 1)), "#0b0b0d", 2, outline=OUT, ow=1, wob=0.1)
    for k in range(6):
        y = 9 + k * 3.4
        line(img, [(S(86), S(y)), (S(114), S(y))], "#4a4c52", 1.2 * SS, 255, blur=0.1)
    return finish(img, w, h)


def pistol():
    """A .45 automatic seen from above, muzzle to the right; the grip end (left) sits in the hand."""
    w, h = 48, 20
    img = new(w, h)
    soft_blob(img, S(26), S(12), S(20), S(5), "#000000", 70, 1.5 * SS)
    paint_shape(img, SP(rrect_pts(6, 6, 44, 13, 1.5)), "#3a3f47", 1, outline=OUT, ow=1.1, wob=0.1, tex=0.15,
                light=(0, -1, 0.7))
    line(img, [(S(10), S(7.5)), (S(42), S(7.5))], "#8d96a3", 1.0 * SS, 230, blur=0.15)  # light on the slide
    for x in range(10, 20, 2):
        line(img, [(S(x), S(6.5)), (S(x), S(12.5))], "#23272c", 0.7 * SS, 220, blur=0.05)  # slide serrations
    paint_shape(img, SP(rrect_pts(2, 7, 9, 12, 1)), "#5a3a24", 2, outline=OUT, ow=0.9, wob=0.1, tex=0.2)  # grip / hammer end
    paint_shape(img, SP(ellipse_pts(44.5, 9.5, 1.2, 1.4)), "#0b0b0d", 3, outline=None, wob=0.02)  # muzzle
    return finish(img, w, h)


def muzzle_flash():
    """Additive flash: a hot core at the left (the muzzle) and a forward cone of fire."""
    w, h = 64, 40
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    u = xx / w
    v = (yy - h / 2) / (h / 2)
    cone = np.clip(1.0 - np.abs(v) / (0.15 + 0.9 * u), 0, 1) * np.clip(1.0 - u, 0, 1) ** 0.8
    core = np.clip(1.0 - np.hypot((xx - 6) / 10.0, (yy - h / 2) / 9.0), 0, 1) ** 1.5
    star = np.zeros_like(cone)
    for ang in (-0.9, -0.45, 0.45, 0.9):
        dx, dy = math.cos(ang), math.sin(ang)
        dist = np.abs((xx - 6) * dy - (yy - h / 2) * dx)
        along = (xx - 6) * dx + (yy - h / 2) * dy
        star += np.clip(1.0 - dist / 1.6, 0, 1) * np.clip(1.0 - along / 22.0, 0, 1) * (along > 0)
    a = np.clip(cone * 0.9 + core + star * 0.6, 0, 1)
    out = np.zeros((h, w, 4), dtype=np.uint8)
    out[..., 0] = 255
    out[..., 1] = np.clip(170 + 85 * core, 0, 255).astype(np.uint8)
    out[..., 2] = np.clip(70 + 150 * core, 0, 255).astype(np.uint8)
    out[..., 3] = (a * 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def tracer():
    """A bullet's streak (additive): bright head at the right, fading tail."""
    w, h = 64, 8
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    along = (xx / w) ** 1.8
    across = np.clip(1.0 - np.abs(yy - (h - 1) / 2) / (h / 2), 0, 1) ** 1.5
    a = along * across
    out = np.zeros((h, w, 4), dtype=np.uint8)
    out[..., 0] = 255
    out[..., 1] = 226
    out[..., 2] = 160
    out[..., 3] = (np.clip(a, 0, 1) * 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def impact_dust():
    """Brick dust and grit knocked off a wall (normal-blended sprite)."""
    w = h = 48
    img = new(w, h)
    rnd = random.Random(11)
    for k in range(6):
        soft_blob(img, S(24 + rnd.uniform(-7, 7)), S(24 + rnd.uniform(-7, 7)), S(rnd.uniform(5, 10)), S(rnd.uniform(4, 8)),
                  rnd.choice(["#b98a6a", "#a07560", "#c7a58a"]), rnd.randint(110, 170), 2.5 * SS)
    for k in range(14):
        x, y = 24 + rnd.uniform(-16, 16), 24 + rnd.uniform(-16, 16)
        paint_shape(img, SP(ellipse_pts(x, y, rnd.uniform(0.8, 1.8), rnd.uniform(0.6, 1.4))), rnd.choice(["#5a3528", "#7a4a36"]),
                    k + 5, outline=None, wob=0.1)
    return finish(img, w, h)


def spark():
    """A small spark star (additive): bullets striking metal or stone."""
    w = h = 32
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    dx, dy = xx - 15.5, yy - 15.5
    r = np.hypot(dx, dy)
    a = np.clip(1.0 - r / 5.0, 0, 1) ** 1.2
    for ang in np.linspace(0, math.pi, 4, endpoint=False):
        dist = np.abs(dx * math.sin(ang) - dy * math.cos(ang))
        a += np.clip(1.0 - dist / 1.1, 0, 1) * np.clip(1.0 - r / 15.0, 0, 1)
    out = np.zeros((h, w, 4), dtype=np.uint8)
    out[..., 0] = 255
    out[..., 1] = 230
    out[..., 2] = 150
    out[..., 3] = (np.clip(a, 0, 1) * 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def badge(symbol, color):
    """A small painted badge floating over a character: '!' noticed, '?' searching."""
    w = h = 48
    img = new(w, h)
    soft_blob(img, S(25), S(27), S(15), S(15), "#000000", 90, 3 * SS)
    paint_shape(img, SP(ellipse_pts(24, 24, 15, 15)), color, 1, outline=OUT, ow=1.8, wob=0.4, tex=0.12, light=(0.3, -1, 0.5))
    paint_shape(img, SP(ellipse_pts(24, 24, 11.5, 11.5)), shade(color, 1.18), 2, outline=None, wob=0.3, tex=0.1)
    text(img, (24, 25.5), symbol, 21, "#2a1610", font=DECO)
    return finish(img, w, h)


# ---------------------------------------------------------------- place markers (M004)

MARK_ENAMEL = "#5a1e1a"      # businesses: oxblood enamel, copper rim, cream picture
MARK_HOME = "#1f4a4a"        # your flat: teal enamel in a house-shaped badge
MARK_CREAM = "#f1e4c6"
MARK_COPPER = "#d8a060"


def _pictogram(img, kind, cx, cy, col=MARK_CREAM):
    """A simple cream pictogram centred on (cx, cy) (template px of a 64 px badge)."""
    if kind == "bar":  # cocktail glass with an olive
        paint_shape(img, SP([(cx - 9, cy - 8), (cx + 9, cy - 8), (cx, cy + 2)]), col, 3, outline=None, wob=0.05)
        line(img, [(S(cx), S(cy + 1)), (S(cx), S(cy + 8))], col, 2.2 * SS, 255)
        line(img, [(S(cx - 5), S(cy + 9)), (S(cx + 5), S(cy + 9))], col, 2.2 * SS, 255)
        paint_shape(img, SP(ellipse_pts(cx + 3, cy - 5, 2.2, 2.2)), "#7a9a3a", 4, outline=None, wob=0.02)
        line(img, [(S(cx + 3), S(cy - 5)), (S(cx + 8), S(cy - 12))], col, 1.2 * SS, 255)
    elif kind == "barber":  # the striped pole with its caps
        paint_shape(img, SP(rrect_pts(cx - 4.5, cy - 9, cx + 4.5, cy + 9, 2)), col, 5, outline=None, wob=0.03)
        for k in range(4):
            y = cy - 8 + k * 5
            paint_shape(img, SP([(cx - 4.5, y + 2), (cx + 4.5, y - 1.5), (cx + 4.5, y + 1), (cx - 4.5, y + 4.5)]),
                        "#b8322a" if k % 2 == 0 else "#2a4a9a", 6 + k, outline=None, wob=0.02)
        for y in (cy - 11, cy + 11):
            paint_shape(img, SP(rrect_pts(cx - 6, y - 2, cx + 6, y + 2, 1.5)), MARK_COPPER, 9, outline=None, wob=0.02)
    elif kind == "grocery":  # an apple with a leaf
        paint_shape(img, SP(ellipse_pts(cx, cy + 2, 9, 8.5)), col, 11, outline=None, wob=0.15)
        soft_blob(img, S(cx - 3.5), S(cy - 0.5), S(1.8), S(1.4), "#ffffff", 150, 0.5 * SS)
        line(img, [(S(cx), S(cy - 5)), (S(cx + 1.5), S(cy - 11))], col, 1.8 * SS, 255)
        paint_shape(img, SP(ellipse_pts(cx + 5, cy - 9, 4, 2, rot=-0.5)), "#8ab04a", 13, outline=None, wob=0.05)
    elif kind == "hardware":  # a claw hammer
        line(img, [(S(cx - 7), S(cy + 10)), (S(cx + 4), S(cy - 5))], col, 3.2 * SS, 255)
        paint_shape(img, SP([(cx - 2, cy - 11), (cx + 9, cy - 3), (cx + 6, cy + 1), (cx - 5, cy - 7)]), col, 14, outline=None, wob=0.05)
        line(img, [(S(cx - 5), S(cy - 7)), (S(cx - 9), S(cy - 4))], col, 2.2 * SS, 255)
    elif kind == "vet":  # M006: a paw print - the animal hospital where gangsters get patched up too
        paint_shape(img, SP(ellipse_pts(cx, cy + 4, 7.5, 6.2)), col, 21, outline=None, wob=0.1)
        for k, (tx, ty) in enumerate(((-8, -4), (-3, -9), (3, -9), (8, -4))):
            paint_shape(img, SP(ellipse_pts(cx + tx, cy + ty, 2.8, 3.3)), col, 22 + k, outline=None, wob=0.05)
    elif kind == "morgue":  # M006: a plain coffin, lid shut
        coffin = [(cx - 4, cy - 12), (cx + 4, cy - 12), (cx + 8, cy - 5), (cx + 5, cy + 12), (cx - 5, cy + 12), (cx - 8, cy - 5)]
        paint_shape(img, SP(coffin), col, 26, outline=None, wob=0.04)
        line(img, [(S(cx), S(cy - 8)), (S(cx), S(cy + 2))], "#3a3f46", 1.6 * SS, 255)
        line(img, [(S(cx - 3.5), S(cy - 4.5)), (S(cx + 3.5), S(cy - 4.5))], "#3a3f46", 1.6 * SS, 255)
    elif kind == "union":  # M011: a longshoreman's cargo hook - the dock and freight men's union hall
        line(img, [(S(cx - 7), S(cy - 9)), (S(cx + 7), S(cy - 9))], col, 4.2 * SS, 255)  # the wooden grip
        line(img, [(S(cx), S(cy - 8)), (S(cx), S(cy + 3))], col, 2.4 * SS, 255)
        hook = [(cx - 5 + 5 * math.cos(a), cy + 2 + 6 * math.sin(a)) for a in np.linspace(0.0, math.pi * 1.2, 14)]
        line(img, [S(x, y) for x, y in hook], col, 2.4 * SS, 255)
    elif kind == "home":  # a bed under a crescent moon: where the henchman sleeps by day
        paint_shape(img, SP(rrect_pts(cx - 10, cy + 1, cx + 10, cy + 7, 1.5)), col, 15, outline=None, wob=0.05)
        paint_shape(img, SP(rrect_pts(cx - 10, cy - 4, cx - 7, cy + 10, 1)), col, 16, outline=None, wob=0.03)
        paint_shape(img, SP(ellipse_pts(cx - 3, cy - 1, 3.4, 2.4)), col, 17, outline=None, wob=0.05)
        moon = ellipse_pts(cx + 6, cy - 9, 4.5, 4.5)
        paint_shape(img, SP(moon), "#f4d88a", 18, outline=None, wob=0.02)
        paint_shape(img, SP(ellipse_pts(cx + 8, cy - 10.5, 3.8, 3.8)), MARK_HOME, 19, outline=None, wob=0.02)


def place_marker(kind):
    """A floating enamel badge marking a place you can walk into (64 x 80, the pin's point at the bottom middle).
    Businesses: a round oxblood badge with a copper rim; your flat: a teal house-shaped badge."""
    w, h = 64, 80
    img = new(w, h)
    soft_blob(img, S(33), S(35), S(24), S(24), "#000000", 90, 4 * SS)
    if kind == "home":
        outer = [(32, 4), (60, 28), (56, 30), (56, 58), (38, 58), (32, 74), (26, 58), (8, 58), (8, 30), (4, 28)]
        inner = [(32, 9.5), (52, 27), (51, 28.5), (51, 53), (13, 53), (13, 28.5), (12, 27)]
        paint_shape(img, SP(outer), MARK_COPPER, 1, outline=OUT, ow=1.8, wob=0.2, tex=0.12, light=(0.3, -1, 0.5))
        paint_shape(img, SP(inner), MARK_HOME, 2, outline=None, wob=0.15, tex=0.15, light=(0.3, -1, 0.4))
        _pictogram(img, "home", 32, 38)
    else:
        pin = ellipse_pts(32, 30, 26, 26)
        tail = [(22, 50), (32, 76), (42, 50)]
        paint_shape(img, SP(tail), MARK_COPPER, 3, outline=OUT, ow=1.6, wob=0.1, light=(0.3, -1, 0.5))
        paint_shape(img, SP(pin), MARK_COPPER, 1, outline=OUT, ow=1.8, wob=0.2, tex=0.12, light=(0.3, -1, 0.5))
        enamel = "#3a3f46" if kind == "morgue" else MARK_ENAMEL  # a landmark, not a business: slate grey
        paint_shape(img, SP(ellipse_pts(32, 30, 21, 21)), enamel, 2, outline=None, wob=0.15, tex=0.18,
                    light=(0.3, -1, 0.4), inner_shadow=0.3)
        _pictogram(img, kind, 32, 30)
    soft_blob(img, S(24), S(18), S(7), S(4), "#ffffff", 50, 1.5 * SS)
    return finish(img, w, h)


def status_figure():
    """M006: Danny seen from the front for the status screen, in six pieces that line up on one
    160 x 320 canvas (head, torso, left arm, right arm, left leg, right leg; his left is on the
    viewer's right). Light grey, so the game can tint each piece by how badly it is hurt."""
    w, h = 160, 320
    col, edge = "#ece6da", (60, 52, 44)
    parts = {}
    def piece(seed, shapes):
        img = new(w, h)
        for pts in shapes:
            paint_shape(img, SP(pts), col, seed, outline=edge, ow=1.6, wob=0.25, tex=0.12, light=(0.4, -1, 0.4))
        return finish(img, w, h)
    hat = [(52, 34), (108, 34), (102, 22), (92, 14), (68, 14), (58, 22)]
    brim = ellipse_pts(80, 36, 34, 6)
    parts["head"] = piece(1, [brim, hat, ellipse_pts(80, 54, 15, 18)])
    torso = [(56, 76), (104, 76), (110, 96), (106, 168), (54, 168), (50, 96)]
    parts["torso"] = piece(2, [torso, [(74, 76), (86, 76), (80, 104)]])
    # Danny's right arm is on the viewer's left
    parts["right_arm"] = piece(3, [[(50, 80), (56, 84), (52, 130), (46, 176), (34, 176), (36, 128), (40, 88)]])
    parts["left_arm"] = piece(4, [[(110, 80), (104, 84), (108, 130), (114, 176), (126, 176), (124, 128), (120, 88)]])
    parts["right_leg"] = piece(5, [[(56, 170), (79, 170), (76, 238), (74, 300), (52, 304), (56, 238)]])
    parts["left_leg"] = piece(6, [[(81, 170), (104, 170), (104, 238), (108, 304), (86, 300), (84, 238)]])
    return {"ui/status_" + k: v for k, v in parts.items()}


def fight_dial():
    """M007: the fistfight dial - a ring of dark, worn brass with a copper bevel, aged cream
    ticks round it and stepped Art Deco chevrons at the quarters, a sunburst boss in the
    middle. 256 x 256; the game lights the zone and turns the needle over it (top = 0)."""
    w = h = 256
    img = new(w, h)
    c = 128
    soft_blob(img, S(c + 3), S(c + 5), S(124), S(124), "#000000", 140, 6 * SS)
    paint_shape(img, SP(ellipse_pts(c, c, 120, 120, n=96)), "#5a4428", 1, outline=(26, 18, 10), ow=2.4, wob=0.25, tex=0.3,
                strokes_n=26, stroke_cols=["#7a5c34", "#3e2e1a"], light=(0.4, -1, 0.5), inner_shadow=0.35)
    paint_shape(img, SP(ellipse_pts(c, c, 112, 112, n=96)), "#9a6a3a", 2, outline=None, wob=0.2, tex=0.25,
                light=(0.4, -1, 0.6))  # the copper bevel
    paint_shape(img, SP(ellipse_pts(c, c, 104, 104, n=96)), "#2a2018", 3, outline=(26, 18, 10), ow=1.4, wob=0.2, tex=0.35,
                strokes_n=18, stroke_cols=["#3a2c20", "#1e1610"], light=(0.4, -1, 0.3))  # the dark track
    paint_shape(img, SP(ellipse_pts(c, c, 76, 76, n=80)), "#4a3822", 4, outline=(26, 18, 10), ow=1.6, wob=0.2, tex=0.3,
                light=(0.4, -1, 0.5), inner_shadow=0.3)
    # aged cream ticks: long at the quarters and eighths, short between
    for k in range(48):
        a = math.radians(k * 7.5 - 90)
        long_ = k % 6 == 0
        r0, r1 = (92, 104) if long_ else (98, 104)
        line(img, [(S(c + math.cos(a) * r0), S(c + math.sin(a) * r0)), (S(c + math.cos(a) * r1), S(c + math.sin(a) * r1))],
             "#e6d6b0", (2.2 if long_ else 1.2) * SS, 230 if long_ else 170)
    # stepped Deco chevrons at the four quarters, on the brass ring
    for q in range(4):
        a = math.radians(q * 90 - 90)
        ux, uy = math.cos(a), math.sin(a)
        px, py = -uy, ux
        for step, (r, half) in enumerate(((109, 7), (114, 4.5), (118, 2.2))):
            pts = [(c + ux * r + px * half, c + uy * r + py * half), (c + ux * (r + 3.5), c + uy * (r + 3.5)),
                   (c + ux * r - px * half, c + uy * r - py * half)]
            paint_shape(img, SP(pts), "#e8d8b2", 10 + q * 3 + step, outline=None, wob=0.02)
    # the sunburst boss
    for k in range(16):
        a = math.radians(k * 22.5)
        line(img, [(S(c + math.cos(a) * 18), S(c + math.sin(a) * 18)), (S(c + math.cos(a) * 64), S(c + math.sin(a) * 64))],
             "#6a5032", 2.0 * SS, 120)
    paint_shape(img, SP(ellipse_pts(c, c, 16, 16)), "#b88a4a", 30, outline=(26, 18, 10), ow=1.4, wob=0.1, light=(0.4, -1, 0.7))
    soft_blob(img, S(c - 40), S(c - 60), S(40), S(16), "#ffffff", 30, 6 * SS)  # a worn sheen
    return finish(grain(img, 6, 31), w, h)


def fight_needle():
    """M007: the dial's needle - brass with an aged cream tip, pointing up from the centre
    (the same 256 x 256 frame as the dial, so it turns about the middle)."""
    w = h = 256
    img = new(w, h)
    c = 128
    soft_blob(img, S(c + 3), S(c - 40), S(8), S(60), "#000000", 110, 3 * SS)
    paint_shape(img, SP([(c - 6, c + 14), (c - 3.5, c - 70), (c, c - 100), (c + 3.5, c - 70), (c + 6, c + 14)]), "#c9974e", 1,
                outline=(26, 18, 10), ow=1.4, wob=0.05, tex=0.1, light=(0.4, -1, 0.6))
    paint_shape(img, SP([(c - 3.5, c - 70), (c, c - 100), (c + 3.5, c - 70), (c, c - 78)]), "#f4e8c8", 2, outline=None, wob=0.02)
    paint_shape(img, SP(ellipse_pts(c, c, 11, 11)), "#8a5e30", 3, outline=(26, 18, 10), ow=1.4, wob=0.1, light=(0.4, -1, 0.7))
    paint_shape(img, SP(ellipse_pts(c, c, 4, 4)), "#e8d8b2", 4, outline=None, wob=0.05)
    return finish(img, w, h)


def player_arrow():
    """The minimap's 'you are here': a cream arrowhead with a dark edge, pointing right."""
    w = h = 32
    img = new(w, h)
    soft_blob(img, S(16), S(17), S(11), S(9), "#000000", 110, 2 * SS)
    paint_shape(img, SP([(29, 16), (5, 4), (11, 16), (5, 28)]), "#fff4d6", 1, outline=(20, 14, 10), ow=2.0, wob=0.05,
                light=(0.3, -1, 0.4))
    return finish(img, w, h)


def police_mark():
    """Police presence on the minimap: a small blue enamel disc with a gold star."""
    w = h = 32
    img = new(w, h)
    paint_shape(img, SP(ellipse_pts(16, 16, 13, 13)), "#2a3a6a", 1, outline=(14, 16, 26), ow=1.6, wob=0.1, light=(0.3, -1, 0.5))
    star = [(16 + math.cos(-math.pi / 2 + k * math.pi / 5) * (8.5 if k % 2 == 0 else 3.6),
             16 + math.sin(-math.pi / 2 + k * math.pi / 5) * (8.5 if k % 2 == 0 else 3.6)) for k in range(10)]
    paint_shape(img, SP(star), "#f0cc66", 2, outline=None, wob=0.02)
    return finish(img, w, h)


def call_box():
    """A police call box on its post (Chicago 'Police Telegraph'), seen from above."""
    w = h = 40
    img = new(w, h)
    soft_blob(img, S(22), S(23), S(13), S(12), "#000000", 100, 2 * SS)
    paint_shape(img, SP(rrect_pts(9, 9, 31, 31, 3)), "#2d3d5c", 1, outline=OUT, ow=1.4, wob=0.25, tex=0.2, light=(0.4, -1, 0.5))
    paint_shape(img, SP(rrect_pts(13, 13, 27, 27, 2)), "#22304a", 2, outline=OUT, ow=1.0, wob=0.2, tex=0.2)
    paint_shape(img, SP(ellipse_pts(20, 20, 3.4, 3.4)), "#d9b45a", 3, outline=OUT, ow=0.8, wob=0.05, light=(0.4, -1, 0.6))
    return finish(img, w, h)


# ---------------------------------------------------------------- roof signs

def copper_owl_sign():
    w, h = 256, 128
    img = new(w, h)
    lit = new(w, h)
    # iron frame
    paint_shape(img, SP(rrect_pts(4, 30, 252, 120, 4)), "#1f2422", 1, outline=OUT, ow=1.6, wob=0.2, tex=0.2)
    for x in range(10, 250, 20):
        line(img, [(S(x), S(32)), (S(x + 16), S(118))], "#2c3330", 1.5 * SS, 200)
    # owl (neon outline) on the left
    owl = [(40, 46), (52, 56), (64, 46), (66, 70), (60, 100), (44, 100), (38, 70)]
    for tgt, col, wd in ((img, "#7a4a2a", 3.4), (lit, "#ff9a3c", 3.0)):
        line(tgt, SP(owl + [owl[0]]), col, wd * SS, 255, blur=0.2)
        for ex in (46, 58):
            ImageDraw.Draw(tgt).ellipse([S(ex - 5), S(60), S(ex + 5), S(70)], outline=rgba("#ffe6a0" if tgt is lit else "#a07a4a"), width=int(2.4 * SS))
    text(img, (162, 60), "COPPER", 26, "#6a5a40", font=DECO, spacing=2)
    text(img, (162, 96), "OWL", 30, "#6a5a40", font=DECO, spacing=6)
    text(lit, (162, 60), "COPPER", 26, "#ffb05a", font=DECO, spacing=2)
    text(lit, (162, 96), "OWL", 30, "#ff7a6a", font=DECO, spacing=6)
    return {"signs/copper_owl": finish(img, w, h), "signs/copper_owl_lit": finish(glow_from(lit, 6 * SS, 1.0), w, h)}


def hotel_sign():
    w, h = 256, 64
    img = new(w, h)
    lit = new(w, h)
    paint_shape(img, SP(rrect_pts(4, 10, 252, 54, 3)), "#22262a", 1, outline=OUT, ow=1.4, wob=0.2, tex=0.2)
    text(img, (128, 33), "HOTEL MARLOWE", 22, "#8a8270", font=DECO, spacing=1)
    text(lit, (128, 33), "HOTEL MARLOWE", 22, "#ffe9b0", font=DECO, spacing=1)
    return {"signs/hotel": finish(img, w, h), "signs/hotel_lit": finish(glow_from(lit, 5 * SS, 0.9), w, h)}


def barber_pole():
    """A barber's pole on its wall bracket, seen from above: the striped glass cylinder's cap."""
    w = h = 32
    img = new(w, h)
    soft_blob(img, S(17), S(17), S(11), S(11), "#000000", 80, 2 * SS)
    paint_shape(img, SP(ellipse_pts(16, 16, 10, 10)), "#e8e2d4", 1, outline=OUT, ow=1.2, wob=0.1, light=(0.4, -1, 0.5))
    for k in range(3):
        a0 = k * 2 * math.pi / 3
        pts = [(16, 16)] + [(16 + math.cos(a0 + t) * 9, 16 + math.sin(a0 + t) * 9) for t in np.linspace(0, 0.9, 6)]
        paint_shape(img, SP(pts), "#b22a24" if k != 1 else "#2a4a9a", 2 + k, outline=None, wob=0.05)
    paint_shape(img, SP(ellipse_pts(16, 16, 4, 4)), "#d6d9db", 6, outline=OUT, ow=0.8, wob=0.05, light=(0.4, -1, 0.6))
    return finish(img, w, h)


def painted_roof_sign(name, words, size, w, h, col="#e8e0c8"):
    img = new(w, h)
    layer = new(w, h)
    text(layer, (w / 2, h / 2), words, size, col, font=DECO, spacing=1.5)
    a = np.asarray(layer, dtype=np.float32).copy()
    n = tnoise(layer.size[0], layer.size[1], 8, 3, octaves=4)
    a[..., 3] *= np.clip(0.55 + 0.6 * n, 0, 1) * 0.85  # weathered paint
    img.alpha_composite(Image.fromarray(a.astype(np.uint8), "RGBA"))
    return finish(img, w, h)


# ---------------------------------------------------------------- effects

def steam():
    w = h = 64
    img = new(w, h)
    for k, (x, y, r) in enumerate(((32, 32, 20), (24, 28, 12), (40, 36, 13), (30, 40, 10))):
        soft_blob(img, S(x), S(y), S(r), S(r), "#e6eaee", 110 - k * 15, 5 * SS)
    return finish(img, w, h)


def glow():
    w = h = 128
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    r = np.hypot(xx - 63.5, yy - 63.5) / 64.0
    a = np.clip(1 - r, 0, 1) ** 2.2
    out = np.zeros((h, w, 4), dtype=np.uint8)
    out[..., 0] = 255
    out[..., 1] = 222
    out[..., 2] = 160
    out[..., 3] = (a * 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def reflection():
    """A vertical streak: the reflection of a light on wet ground (centre at the top)."""
    w, h = 64, 192
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    u = (xx - 31.5) / 32.0
    v = yy / h
    wobble = 0.08 * np.sin(v * 40) * v
    a = np.clip(1 - np.abs(u + wobble) / (0.35 + 0.4 * v), 0, 1) ** 1.6 * np.clip(1 - v, 0, 1) ** 1.3
    stripes = 0.75 + 0.25 * np.sin(v * 70)
    out = np.zeros((h, w, 4), dtype=np.uint8)
    out[..., 0] = 255
    out[..., 1] = 214
    out[..., 2] = 150
    out[..., 3] = np.clip(a * stripes * 255, 0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


# ---------------------------------------------------------------- UI

def crosshair():
    w = h = 64
    img = new(w, h)
    for col, wd in (((20, 16, 14), 4.2), ("#e9d9b0", 2.2)):
        layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        d.arc([S(14), S(14), S(50), S(50)], 20, 70, fill=rgba(col), width=int(wd * SS))
        d.arc([S(14), S(14), S(50), S(50)], 110, 160, fill=rgba(col), width=int(wd * SS))
        d.arc([S(14), S(14), S(50), S(50)], 200, 250, fill=rgba(col), width=int(wd * SS))
        d.arc([S(14), S(14), S(50), S(50)], 290, 340, fill=rgba(col), width=int(wd * SS))
        d.ellipse([S(30), S(30), S(34), S(34)], fill=rgba(col))
        img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(0.4 * SS)))
    return finish(img, w, h)


def panel():
    """Nine-patch: dark lacquer with a copper deco border (24 px margins)."""
    w = h = 96
    img = new(w, h)
    paint_shape(img, SP(rrect_pts(2, 2, 94, 94, 10)), "#16130f", 1, outline=None, wob=0.1, tex=0.12)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle([S(5), S(5), S(91), S(91)], radius=S(8), outline=rgba("#b8743a"), width=int(2 * SS))
    d.rounded_rectangle([S(10), S(10), S(86), S(86)], radius=S(5), outline=rgba("#6a4424"), width=SS)
    for cx, cy in ((10, 10), (86, 10), (10, 86), (86, 86)):
        d.polygon([(S(cx), S(cy - 4)), (S(cx + 4), S(cy)), (S(cx), S(cy + 4)), (S(cx - 4), S(cy))], fill=rgba("#d8a060"))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(0.3 * SS)))
    a = np.asarray(img).copy()
    a[..., 3] = (a[..., 3].astype(np.float32) * 0.92).astype(np.uint8)
    return finish(Image.fromarray(a, "RGBA"), w, h)


ASSETS = {
    "props/lamp_head": lamp_head,
    "props/lamp_base": lamp_base,
    "props/hydrant": hydrant,
    "props/trash_can": trash_can,
    "props/crate": crate,
    "props/crates": crates,
    "props/barrel": barrel,
    "props/barricade": barricade,
    "props/lantern": lantern,
    "props/mailbox": mailbox,
    "props/gas_pump": gas_pump,
    "props/newsstand": newsstand,
    "props/awning_red": lambda: awning("#9e2b25", "#e9dcc0", 1),
    "props/awning_green": lambda: awning("#2f5a3e", "#e4dcc4", 2),
    "props/marquee": marquee,
    "props/fire_escape": fire_escape,
    "props/call_box": call_box,
    "weapons/pistol": pistol,
    "fx/muzzle_flash": muzzle_flash,
    "fx/tracer": tracer,
    "fx/impact_dust": impact_dust,
    "fx/spark": spark,
    "ui/alert": lambda: badge("!", "#e8a23c"),
    "ui/search": lambda: badge("?", "#c9b98a"),
    "decals/manhole": manhole,
    "decals/drain": drain,
    "decals/puddle": puddle,
    "decals/litter": litter,
    "decals/oil": oil,
    "roof/chimney": chimney,
    "roof/vent": vent,
    "roof/skylight": skylight,
    "roof/stair_hut": stair_hut,
    "roof/cupola": cupola,
    "roof/water_tank": water_tank,
    "roof/laundry": laundry,
    "signs/copper_owl": copper_owl_sign,
    "signs/hotel": hotel_sign,
    "signs/garage": lambda: painted_roof_sign("garage", "DOYLE'S GARAGE", 20, 256, 64),
    "signs/barber": lambda: painted_roof_sign("barber", "SAL'S BARBER SHOP", 17, 256, 64),
    "ui/marker_bar": lambda: place_marker("bar"),
    "ui/marker_barber": lambda: place_marker("barber"),
    "ui/marker_grocery": lambda: place_marker("grocery"),
    "ui/marker_hardware": lambda: place_marker("hardware"),
    "ui/marker_home": lambda: place_marker("home"),
    "ui/marker_vet": lambda: place_marker("vet"),
    "ui/marker_morgue": lambda: place_marker("morgue"),
    "ui/marker_union": lambda: place_marker("union"),
    "signs/vet": lambda: painted_roof_sign("vet", "PETTIBONE ANIMAL HOSPITAL", 16, 384, 64),
    "signs/morgue": lambda: painted_roof_sign("morgue", "THE MORGUE", 26, 256, 64, col="#d6dde4"),
    "signs/union": lambda: painted_roof_sign("union", "DOCK & FREIGHT WORKERS  LOCAL 9", 15, 384, 64),
    "signs/city_hall": lambda: painted_roof_sign("city_hall", "CITY HALL", 30, 320, 64, col="#e8dcb4"),
    "signs/doran": lambda: painted_roof_sign("doran", "ALD. M. J. DORAN  WARD OFFICE", 16, 384, 64),
    "signs/quilty": lambda: painted_roof_sign("quilty", "ALD. P. J. QUILTY  WARD OFFICE", 16, 384, 64),
    "signs/regulars": lambda: painted_roof_sign("regulars", "THE REGULARS' CLUB", 20, 320, 64),
    "ui/status_figure": status_figure,
    "ui/fight_dial": fight_dial,
    "ui/fight_needle": fight_needle,
    "ui/map_player": player_arrow,
    "ui/map_police": police_mark,
    "signs/grocery": lambda: painted_roof_sign("grocery", "NOVAK'S GROCERY", 18, 256, 64),
    "signs/hardware": lambda: painted_roof_sign("hardware", "LINDQVIST HARDWARE", 16, 256, 64),
    "props/barber_pole": barber_pole,
    "signs/cold_storage": lambda: painted_roof_sign("cold_storage", "LAKESHORE COLD STORAGE", 17, 384, 64),
    "fx/steam": steam,
    "fx/glow": glow,
    "fx/reflection": reflection,
    "ui/crosshair": crosshair,
    "ui/panel": panel,
}
