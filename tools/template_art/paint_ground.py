"""Seamless ground and roof tiles and seamless strips."""
import math
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from paintkit import *


def tile_asphalt(seed=1):
    w = h = 256
    n = tnoise(w * SS, h * SS, 4, seed, octaves=5)
    img = ramp(n, ["#2d2e32", "#35373c", "#3c3e44", "#33353a"])
    strokes(img, 260, ["#4a4d55", "#2a2c31", "#474a52", "#30333a"], 26, 5, seed + 1, alpha=(20, 50))
    # patched repairs: slightly different rectangles
    rnd = random.Random(seed)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(3):
        x, y = rnd.uniform(0, w * SS), rnd.uniform(0, h * SS)
        pw, ph = rnd.uniform(30, 70) * SS, rnd.uniform(20, 45) * SS
        for ox in (-w * SS, 0, w * SS):
            for oy in (-h * SS, 0, h * SS):
                d.polygon(wobble_poly([(x + ox, y + oy), (x + pw + ox, y + oy), (x + pw + ox, y + ph + oy), (x + ox, y + ph + oy)], 1.2, rnd.randint(0, 999)),
                          fill=rgba("#25272b", 70))
    img.alpha_composite(wrap_blur(layer, 1.2 * SS))
    # cracks
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(7):
        x, y = rnd.uniform(0, w * SS), rnd.uniform(0, h * SS)
        a = rnd.uniform(0, math.pi * 2)
        pts = [(x, y)]
        for _ in range(rnd.randint(4, 9)):
            a += rnd.uniform(-0.8, 0.8)
            x += math.cos(a) * rnd.uniform(6, 14) * SS
            y += math.sin(a) * rnd.uniform(6, 14) * SS
            pts.append((x, y))
        for ox in (-w * SS, 0, w * SS):
            for oy in (-h * SS, 0, h * SS):
                d.line([(p[0] + ox, p[1] + oy) for p in pts], fill=rgba("#1b1c1f", 150), width=SS)
    img.alpha_composite(wrap_blur(layer, 0.5 * SS))
    # wet sheen: smooth lighter patches (pick up lamp light at night)
    sheen = tnoise(w * SS, h * SS, 2, seed + 7, octaves=3)
    a = np.asarray(img, dtype=np.float32).copy()
    s = np.clip((sheen - 0.55) * 3.0, 0, 1)
    a[..., 0] += s * 14
    a[..., 1] += s * 17
    a[..., 2] += s * 23
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    img = grain(img, 5, seed)
    return finish(img, w, h)


def tile_sidewalk(seed=2):
    w = h = 256
    slab = 32
    n = tnoise(w * SS, h * SS, 4, seed, octaves=4)
    img = ramp(n, ["#77736b", "#837e74", "#8d887d", "#7a766d"])
    rnd = random.Random(seed)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for i in range(w // slab):
        for j in range(h // slab):
            x0, y0 = i * slab * SS, j * slab * SS
            tint = rnd.choice(["#8f897e", "#7b766c", "#86817a", "#928c80", "#76726a"])
            d.rectangle([x0 + 2, y0 + 2, x0 + slab * SS - 3, y0 + slab * SS - 3], fill=rgba(tint, rnd.randint(40, 90)))
    img.alpha_composite(wrap_blur(layer, 1.0 * SS))
    joints = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(joints)
    for i in range(w // slab + 1):
        x = i * slab * SS
        d.line([(x, 0), (x, h * SS)], fill=rgba("#4a4741", 170), width=2 * SS // 2 + 1)
    for j in range(h // slab + 1):
        y = j * slab * SS
        d.line([(0, y), (w * SS, y)], fill=rgba("#4a4741", 170), width=2 * SS // 2 + 1)
    img.alpha_composite(wrap_blur(joints, 0.6 * SS))
    strokes(img, 160, ["#9a958a", "#66625b", "#8a857b"], 14, 3, seed + 4, alpha=(15, 45))
    # a few stains
    for _ in range(5):
        cx, cy = rnd.uniform(0, w * SS), rnd.uniform(0, h * SS)
        layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
        r = rnd.uniform(6, 16) * SS
        for ox in (-w * SS, 0, w * SS):
            for oy in (-h * SS, 0, h * SS):
                ImageDraw.Draw(layer).ellipse([cx - r + ox, cy - r * 0.7 + oy, cx + r + ox, cy + r * 0.7 + oy], fill=rgba("#55524c", 45))
        img.alpha_composite(wrap_blur(layer, 3 * SS))
    img = grain(img, 4, seed)
    return finish(img, w, h)


def brick_field(w, h, bw, bh, cols, mortar, seed, stagger=0.5, herring=False, jitter=0.12, wrapped=True):
    """A seamless brick pattern in drawing coordinates (w, h are template px)."""
    rnd = random.Random(seed)
    img = Image.new("RGBA", (w * SS, h * SS), rgba(mortar))
    d = ImageDraw.Draw(img)
    rows = h // bh
    for r in range(rows):
        off = (r % 2) * stagger * bw
        x = -bw + off
        while x < w + bw:
            c = shade(rnd.choice(cols), rnd.uniform(1 - jitter, 1 + jitter))
            x0, y0 = x * SS + 1, r * bh * SS + 1
            x1, y1 = (x + bw) * SS - 2, (r + 1) * bh * SS - 2
            for ox in (-w * SS, 0, w * SS):
                d.rounded_rectangle([x0 + ox, y0, x1 + ox, y1], radius=SS, fill=c)
            x += bw
    return img


def tile_alley(seed=3):
    """Worn brick paving (Chicago alleys)."""
    w = h = 256
    img = brick_field(w, h, 24, 12, ["#6d4a3a", "#7a5241", "#5e4034", "#80594a", "#6a4f45"], "#3f3631", seed)
    img = wrap_blur(img, 0.5 * SS)
    n = tnoise(w * SS, h * SS, 4, seed + 1, octaves=4)
    img = modulate(img, n, 0.45)
    strokes(img, 220, ["#4a3a33", "#8a6a58", "#3a302b"], 18, 4, seed + 2, alpha=(18, 50))
    # grime: darker band centre (wheel ruts) left as noise, puddle sheen
    sheen = tnoise(w * SS, h * SS, 2, seed + 9, octaves=3)
    a = np.asarray(img, dtype=np.float32).copy()
    s = np.clip((sheen - 0.6) * 3.0, 0, 1)
    a[..., :3] = a[..., :3] * (1 - s[..., None] * 0.25) + np.array([60, 70, 85]) * s[..., None] * 0.25
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    return finish(grain(img, 5, seed), w, h)


def tile_cobble(seed=4):
    """Granite setts for the streetcar right-of-way."""
    w = h = 256
    rnd = random.Random(seed)
    img = Image.new("RGBA", (w * SS, h * SS), rgba("#2a2a2c"))
    d = ImageDraw.Draw(img)
    bw, bh = 20, 14
    for r in range(h // bh + 1):
        off = (r % 2) * bw * 0.5
        x = -bw + off
        while x < w + bw:
            c = shade(rnd.choice(["#5b5a5e", "#66656a", "#504f54", "#6e6a68", "#58565a"]), rnd.uniform(0.85, 1.1))
            x0 = x * SS + rnd.uniform(1, 3)
            y0 = r * bh * SS + rnd.uniform(1, 3)
            pts = rrect_pts(x0, y0, x0 + bw * SS - 4, y0 + bh * SS - 4, 5 * SS)
            for ox in (-w * SS, 0, w * SS):
                for oy in (-h * SS, 0, h * SS):
                    d.polygon([(p[0] + ox, p[1] + oy) for p in pts], fill=c)
            x += bw
    img = wrap_blur(img, 0.6 * SS)
    # top highlight on each sett from noise
    n = tnoise(w * SS, h * SS, 8, seed + 1, octaves=3)
    img = modulate(img, n, 0.35)
    strokes(img, 150, ["#77767a", "#3a393c"], 10, 3, seed + 2, alpha=(15, 40))
    sheen = tnoise(w * SS, h * SS, 2, seed + 5, octaves=3)
    a = np.asarray(img, dtype=np.float32).copy()
    s = np.clip((sheen - 0.55) * 2.5, 0, 1)
    a[..., :3] += s[..., None] * np.array([18, 22, 30])
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    return finish(grain(img, 5, seed), w, h)


def tile_lot(seed=5):
    """Cinders, packed dirt and weeds: yards and the vacant lot."""
    w = h = 256
    n = tnoise(w * SS, h * SS, 4, seed, octaves=5)
    img = ramp(n, ["#3d3830", "#4a4237", "#544b3d", "#433d33"])
    strokes(img, 300, ["#5e5444", "#2f2b25", "#585040", "#3b4a32"], 12, 3, seed + 1, alpha=(25, 60))
    rnd = random.Random(seed)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(500):
        x, y = rnd.uniform(0, w * SS), rnd.uniform(0, h * SS)
        r = rnd.uniform(0.5, 1.6) * SS
        d.ellipse([x - r, y - r, x + r, y + r], fill=rgba(rnd.choice(["#2a2622", "#6b6252", "#5a5a50"]), rnd.randint(60, 140)))
    img.alpha_composite(layer)
    # weed tufts
    for _ in range(18):
        x, y = rnd.uniform(0, w * SS), rnd.uniform(0, h * SS)
        for k in range(7):
            a = rnd.uniform(0, 2 * math.pi)
            L = rnd.uniform(3, 7) * SS
            line(img, [(x, y), (x + math.cos(a) * L, y + math.sin(a) * L)], rnd.choice(["#4b5a36", "#56663e", "#3f4c2f"]), 1.2 * SS, 160, blur=0.3)
    return finish(grain(img, 5, seed), w, h)


def tile_water(seed=6):
    w = h = 256
    n = tnoise(w * SS, h * SS, 2, seed, octaves=5)
    img = ramp(n, ["#121a22", "#17222c", "#1d2a35", "#152029"])
    strokes(img, 320, ["#2a3a48", "#0d141a", "#26384a", "#1f2f3c"], 34, 3, seed + 1, angle=0.0, alpha=(25, 70))
    strokes(img, 80, ["#3d5468", "#40566a"], 18, 1.5, seed + 2, angle=0.0, alpha=(30, 80))
    return finish(grain(img, 4, seed), w, h)


# ---------------------------------------------------------------- roofs

def tile_roof_tar(seed=10):
    """Tar-paper flat roof: overlapping rolls, patches, soot."""
    w = h = 256
    n = tnoise(w * SS, h * SS, 4, seed, octaves=4)
    img = ramp(n, ["#47454a", "#524f55", "#5d5a60", "#4c4a4f"])
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    roll = 36
    for k in range(h // roll + 1):
        y = k * roll * SS
        d.line([(0, y), (w * SS, y)], fill=rgba("#262529", 220), width=3 * SS)
        d.line([(0, y + 4 * SS), (w * SS, y + 4 * SS)], fill=rgba("#6e6b72", 120), width=SS)
    img.alpha_composite(wrap_blur(layer, 0.7 * SS))
    rnd = random.Random(seed)
    for _ in range(9):
        x, y = rnd.uniform(0, w * SS), rnd.uniform(0, h * SS)
        pw, ph = rnd.uniform(24, 70) * SS, rnd.uniform(18, 44) * SS
        layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
        dd = ImageDraw.Draw(layer)
        col = rnd.choice(["#67646b", "#333236", "#6a5f52", "#3d3b40"])
        for ox in (-w * SS, 0, w * SS):
            for oy in (-h * SS, 0, h * SS):
                dd.polygon(wobble_poly([(x + ox, y + oy), (x + pw + ox, y + oy), (x + pw + ox, y + ph + oy), (x + ox, y + ph + oy)], 1.0, rnd.randint(0, 99)), fill=rgba(col, 120))
        img.alpha_composite(wrap_blur(layer, 0.8 * SS))
    strokes(img, 240, ["#5c5a61", "#2f2e33", "#56544a"], 22, 4, seed + 3, angle=0.0, alpha=(18, 45))
    return finish(grain(img, 5, seed), w, h)


def tile_roof_gravel(seed=11):
    w = h = 256
    n = tnoise(w * SS, h * SS, 4, seed, octaves=4)
    img = ramp(n, ["#6a645b", "#766f65", "#837b70", "#6e685f"])
    rnd = random.Random(seed)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(2600):
        x, y = rnd.uniform(0, w * SS), rnd.uniform(0, h * SS)
        r = rnd.uniform(0.6, 1.8) * SS
        d.ellipse([x - r, y - r * 0.8, x + r, y + r * 0.8], fill=rgba(rnd.choice(["#7d766b", "#4a463f", "#8a8378", "#3c3934"]), rnd.randint(80, 170)))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(0.3 * SS)))
    strokes(img, 120, ["#3a3631", "#7a7367"], 30, 6, seed + 3, alpha=(12, 35))
    return finish(grain(img, 5, seed), w, h)


def tile_roof_tin(seed=12):
    """Corrugated sheet roof (garage, warehouse annexes), rust streaks."""
    w = h = 256
    n = tnoise(w * SS, h * SS, 4, seed, octaves=4)
    img = ramp(n, ["#5c6066", "#686d73", "#72767b", "#60646a"])
    a = np.asarray(img, dtype=np.float32).copy()
    yy = np.arange(h * SS, dtype=np.float32)
    rib = 0.5 + 0.5 * np.sin(yy / (8 * SS) * 2 * math.pi)
    a[..., :3] *= (0.82 + 0.3 * rib)[:, None, None]
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    rnd = random.Random(seed)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for k in range(4):
        x = k * 64 * SS
        d.line([(x, 0), (x, h * SS)], fill=rgba("#3d4045", 150), width=SS)
    for _ in range(40):
        x, y = rnd.uniform(0, w * SS), rnd.uniform(0, h * SS)
        L = rnd.uniform(10, 40) * SS
        for ox in (-w * SS, 0, w * SS):
            d.line([(x + ox, y), (x + ox + L, y + rnd.uniform(-2, 2))], fill=rgba(rnd.choice(["#7a4a2c", "#8c5a34", "#5e3a24"]), rnd.randint(50, 110)), width=int(rnd.uniform(2, 5) * SS))
    img.alpha_composite(wrap_blur(layer, 1.2 * SS))
    return finish(grain(img, 4, seed), w, h)


def tile_ballast(seed=13):
    """Railroad embankment top: ballast with two tracks (runs left-right)."""
    w = h = 256
    img = Image.open(None) if False else None
    base = tile_roof_gravel(seed + 100).resize((w * SS, h * SS), Image.BICUBIC)
    a = np.asarray(base, dtype=np.float32).copy()
    a[..., :3] *= np.array([0.78, 0.74, 0.7])
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(img)
    for ty in (64, 192):
        for k in range(16):
            x = k * 16 * SS
            d.rectangle([x + 2 * SS, (ty - 30) * SS, x + 10 * SS, (ty + 30) * SS], fill=rgba(random.Random(k + ty).choice(["#4a3a2e", "#3e3128", "#56443a"])))
        for ry in (ty - 20, ty + 20):
            d.rectangle([0, (ry - 2) * SS, w * SS, (ry + 2) * SS], fill=rgba("#2c2b2d"))
            d.line([(0, (ry - 1) * SS), (w * SS, (ry - 1) * SS)], fill=rgba("#86868c"), width=SS)
    img = wrap_blur(img, 0.5 * SS)
    return finish(grain(img, 4, seed), w, h)


def tile_bridge_deck(seed=14):
    """Steel grating / riveted deck (the raised bascule leaf)."""
    w = h = 256
    n = tnoise(w * SS, h * SS, 4, seed, octaves=4)
    img = ramp(n, ["#3a4448", "#465156", "#3f494d"])
    d = ImageDraw.Draw(img)
    for k in range(0, w, 16):
        d.line([(k * SS, 0), (k * SS, h * SS)], fill=rgba("#2c3336"), width=SS)
    for k in range(0, h, 64):
        d.rectangle([0, k * SS, w * SS, (k + 6) * SS], fill=rgba("#2f383c"))
        for x in range(0, w, 8):
            d.ellipse([(x + 3) * SS, (k + 2) * SS, (x + 5) * SS, (k + 4) * SS], fill=rgba("#6c777c"))
    img = wrap_blur(img, 0.5 * SS)
    strokes(img, 90, ["#6b4a33", "#2a3236"], 20, 4, seed, alpha=(15, 40))
    return finish(grain(img, 4, seed), w, h)


# ---------------------------------------------------------------- strips (seamless left-right)

def strip_curb(seed=20):
    w, h = 128, 24
    img = new(w, h, "#8e897f")
    n = tnoise(w * SS, h * SS, 8, seed, octaves=3)
    img = modulate(img, n, 0.3)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w * SS, 6 * SS], fill=rgba("#a8a296"))       # top face (sidewalk side)
    d.rectangle([0, 15 * SS, w * SS, h * SS], fill=rgba("#5f5b55"))  # vertical face (road side), in shadow
    for k in range(0, w, 32):
        d.line([(k * SS, 0), (k * SS, h * SS)], fill=rgba("#5a5650"), width=SS)
    img = wrap_blur(img, 0.7 * SS)
    strokes(img, 40, ["#b4ad9f", "#6e6a62"], 10, 2, seed, angle=0.0, alpha=(25, 60))
    return finish(grain(img, 4, seed), w, h)


def strip_parapet(seed=21):
    """Brick parapet with stone coping (roof edge), outside edge at the bottom."""
    w, h = 128, 32
    img = brick_field(w, h, 16, 8, ["#6e4436", "#7a4c3c", "#653f33"], "#4a3b34", seed)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w * SS, 14 * SS], fill=rgba("#a9a193"))         # stone coping on top
    d.rectangle([0, 0, w * SS, 3 * SS], fill=rgba("#c4bcad"))
    d.line([(0, 14 * SS), (w * SS, 14 * SS)], fill=rgba("#3b3330"), width=SS)
    for k in range(0, w, 24):
        d.line([(k * SS, 0), (k * SS, 14 * SS)], fill=rgba("#7a7468"), width=SS)
    d.rectangle([0, 26 * SS, w * SS, h * SS], fill=rgba("#2c2522"))       # shadow at the roof side
    img = wrap_blur(img, 0.6 * SS)
    n = tnoise(w * SS, h * SS, 8, seed + 1, octaves=3)
    img = modulate(img, n, 0.3)
    return finish(grain(img, 4, seed), w, h)


def strip_rails(seed=22):
    """One streetcar track: two grooved rails, worn shiny tops."""
    w, h = 128, 40
    img = new(w, h)
    d = ImageDraw.Draw(img)
    for y in (8, 32):
        d.rectangle([0, (y - 3) * SS, w * SS, (y + 3) * SS], fill=rgba("#26262a", 230))
        d.rectangle([0, (y - 1.5) * SS, w * SS, (y + 0.5) * SS], fill=rgba("#a8aab0", 235))
        d.line([(0, (y + 1.6) * SS), (w * SS, (y + 1.6) * SS)], fill=rgba("#141416", 230), width=SS)
    img = wrap_blur(img, 0.4 * SS)
    strokes(img, 30, ["#d0d2d8", "#6a6c70"], 20, 1, seed, angle=0.0, alpha=(30, 80), blur=0.3, area=(0, 4 * SS, w * SS, 12 * SS))
    return finish(img, w, h)


def strip_quay(seed=23):
    """Stone quay edge with an iron railing (water side at the bottom)."""
    w, h = 128, 32
    img = new(w, h, "#6d6860")
    n = tnoise(w * SS, h * SS, 8, seed, octaves=3)
    img = modulate(img, n, 0.35)
    d = ImageDraw.Draw(img)
    for k in range(0, w, 32):
        d.line([(k * SS, 0), (k * SS, 20 * SS)], fill=rgba("#4b4741"), width=SS)
    d.rectangle([0, 20 * SS, w * SS, h * SS], fill=rgba("#2d2b28"))  # face down to the water
    # railing: rail + posts
    d.rectangle([0, 9 * SS, w * SS, 12 * SS], fill=rgba("#1e1f22"))
    d.line([(0, 9.5 * SS), (w * SS, 9.5 * SS)], fill=rgba("#5d6065"), width=SS)
    for k in range(8, w, 32):
        d.ellipse([(k - 3) * SS, (10.5 - 3) * SS, (k + 3) * SS, (10.5 + 3) * SS], fill=rgba("#1b1c1e"))
        d.ellipse([(k - 1.5) * SS, (9 - 1.5) * SS, (k + 0.5) * SS, (9 + 0.5) * SS], fill=rgba("#777a80"))
    img = wrap_blur(img, 0.5 * SS)
    return finish(grain(img, 4, seed), w, h)


def strip_fence(seed=24):
    """Wooden board fence (yards along alleys)."""
    w, h = 128, 16
    rnd = random.Random(seed)
    img = new(w, h)
    d = ImageDraw.Draw(img)
    for k in range(0, w, 8):
        c = shade(rnd.choice(["#5a4636", "#4e3d30", "#634c3a"]), rnd.uniform(0.9, 1.1))
        d.rectangle([k * SS, 3 * SS, (k + 7) * SS, 13 * SS], fill=c)
    d.line([(0, 8 * SS), (w * SS, 8 * SS)], fill=rgba("#3a2c22"), width=2 * SS)
    img = img.filter(ImageFilter.GaussianBlur(0.4 * SS))
    return finish(img, w, h)


TILES = {
    "city/asphalt": tile_asphalt,
    "city/sidewalk": tile_sidewalk,
    "city/alley": tile_alley,
    "city/cobbles": tile_cobble,
    "city/lot": tile_lot,
    "city/water": tile_water,
    "roofs/tar": tile_roof_tar,
    "roofs/gravel": tile_roof_gravel,
    "roofs/tin": tile_roof_tin,
    "roofs/ballast": tile_ballast,
    "roofs/steel": tile_bridge_deck,
    "city/curb": strip_curb,
    "roofs/parapet": strip_parapet,
    "city/rails": strip_rails,
    "city/quay": strip_quay,
    "city/fence": strip_fence,
}
