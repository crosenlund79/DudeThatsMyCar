"""Facade strips. Each is 256 x 192: rows 0-95 = an upper storey (repeats for
every storey above the ground floor), rows 96-191 = the ground storey.
Horizontally seamless. A matching *_lit image holds only the light coming from
the windows (drawn unshaded and additive at night)."""
import math
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from paintkit import *
from paint_ground import brick_field

W, H = 256, 192
WARM = ["#ffd27a", "#ffc35e", "#ffdc96", "#ffb04a", "#f7e2a4"]


def soot(img, top_dark=0.25, bottom_dark=0.2):
    a = np.asarray(img, dtype=np.float32).copy()
    h = a.shape[0]
    yy = np.linspace(0, 1, h, dtype=np.float32)
    # each storey darker under its cornice / at its base
    band = (yy * 2) % 1.0
    f = 1.0 - top_dark * np.exp(-band * 10) - bottom_dark * np.exp(-(1 - band) * 14)
    a[..., :3] *= f[:, None, None]
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")


def brick_wall(cols, mortar, seed, bw=16, bh=6):
    img = brick_field(W, H, bw, bh, cols, mortar, seed)
    img = wrap_blur(img, 0.45 * SS)
    n = tnoise(W * SS, H * SS, 4, seed + 1, octaves=4)
    img = modulate(img, n, 0.4)
    strokes(img, 70, [shade(cols[0], 0.8), shade(cols[0], 1.15)], 12, 5, seed + 2, alpha=(10, 26), blur=1.4)
    return img


def stone_band(d, y0, y1, color="#9b9488", dark="#5e5850"):
    d.rectangle([0, y0 * SS, W * SS, y1 * SS], fill=rgba(color))
    d.line([(0, y1 * SS), (W * SS, y1 * SS)], fill=rgba(dark), width=SS)


def window(img, lit, x, y, w, h, seed, is_lit, style="sash", frame="#d8d0bf", glass="#1f2a36", curtain=None,
           lintel="#a49c8e", sill=True, light_col=None):
    """A window in template px. Paints albedo on img and (if lit) light on lit."""
    rnd = random.Random(seed)
    d = ImageDraw.Draw(img)
    if lintel:
        d.rectangle([S(x - 4), S(y - 6), S(x + w + 4), S(y)], fill=rgba(lintel))
        d.line([(S(x - 4), S(y)), (S(x + w + 4), S(y))], fill=rgba("#3d3632"), width=SS)
    if sill:
        d.rectangle([S(x - 3), S(y + h), S(x + w + 3), S(y + h + 3)], fill=rgba("#b7ae9e"))
        d.line([(S(x - 3), S(y + h + 3)), (S(x + w + 3), S(y + h + 3))], fill=rgba("#2f2a27"), width=SS)
    d.rectangle([S(x), S(y), S(x + w), S(y + h)], fill=rgba(frame))
    gx0, gy0, gx1, gy1 = x + 2, y + 2, x + w - 2, y + h - 2
    # glass with a cool reflection gradient
    for k in range(int(gy1 - gy0) * SS):
        t = k / max(1, (gy1 - gy0) * SS)
        d.line([(S(gx0), S(gy0) + k), (S(gx1), S(gy0) + k)], fill=mix(glass, shade(glass, 1.6), 0.6 - 0.6 * t))
    # sashes / muntins
    mid = (gy0 + gy1) / 2
    if style == "sash":
        d.rectangle([S(gx0), S(mid - 1), S(gx1), S(mid + 1)], fill=rgba(frame))
        d.line([(S((gx0 + gx1) / 2), S(gy0)), (S((gx0 + gx1) / 2), S(mid))], fill=rgba(frame), width=SS)
    elif style == "grid":
        for gx in np.arange(gx0, gx1, (gx1 - gx0) / 4)[1:]:
            d.line([(S(gx), S(gy0)), (S(gx), S(gy1))], fill=rgba(frame), width=SS)
        for gy in np.arange(gy0, gy1, (gy1 - gy0) / 4)[1:]:
            d.line([(S(gx0), S(gy)), (S(gx1), S(gy))], fill=rgba(frame), width=SS)
    elif style == "shop":
        d.rectangle([S(gx0), S(gy0 + (gy1 - gy0) * 0.22) - SS, S(gx1), S(gy0 + (gy1 - gy0) * 0.22) + SS], fill=rgba(frame))
    # a cold glint
    line(img, [(S(gx0 + 2), S(gy1 - 3)), (S(gx0 + (gx1 - gx0) * 0.5), S(gy0 + 3))], "#9fb4c8", SS, 60, blur=0)
    if curtain:
        cw = (gx1 - gx0) * rnd.uniform(0.22, 0.32)
        d.polygon([(S(gx0), S(gy0)), (S(gx0 + cw), S(gy0)), (S(gx0 + cw * 0.6), S(gy1)), (S(gx0), S(gy1))], fill=rgba(curtain))
        d.polygon([(S(gx1), S(gy0)), (S(gx1 - cw), S(gy0)), (S(gx1 - cw * 0.6), S(gy1)), (S(gx1), S(gy1))], fill=rgba(curtain))
    if not is_lit:
        return
    L = ImageDraw.Draw(lit)
    col = light_col or rnd.choice(WARM)
    shade_down = rnd.uniform(0.0, 0.45)  # blind pulled down
    for k in range(int((gy1 - gy0) * SS)):
        t = k / max(1, (gy1 - gy0) * SS)
        a = 235 if t > shade_down else 120
        L.line([(S(gx0), S(gy0) + k), (S(gx1), S(gy0) + k)], fill=rgba(mix(col, "#fff2cc", 0.25 * (1 - t)), a))
    if style == "sash":
        L.rectangle([S(gx0), S(mid - 1), S(gx1), S(mid + 1)], fill=rgba(col, 60))
    elif style == "grid":
        for gx in np.arange(gx0, gx1, (gx1 - gx0) / 4)[1:]:
            L.line([(S(gx), S(gy0)), (S(gx), S(gy1))], fill=(0, 0, 0, 0), width=SS)
    if curtain:
        cw = (gx1 - gx0) * 0.27
        cc = mix(curtain, col, 0.35)
        L.polygon([(S(gx0), S(gy0)), (S(gx0 + cw), S(gy0)), (S(gx0 + cw * 0.6), S(gy1)), (S(gx0), S(gy1))], fill=rgba(cc, 200))
        L.polygon([(S(gx1), S(gy0)), (S(gx1 - cw), S(gy0)), (S(gx1 - cw * 0.6), S(gy1)), (S(gx1), S(gy1))], fill=rgba(cc, 200))
    # a silhouette now and then: a figure, a plant, a cat
    sil = rnd.random()
    cx = (gx0 + gx1) / 2 + rnd.uniform(-3, 3)
    if sil < 0.18:
        L.ellipse([S(cx - 3), S(gy0 + 6), S(cx + 3), S(gy0 + 12)], fill=rgba("#3a2414", 230))
        L.rounded_rectangle([S(cx - 6), S(gy0 + 12), S(cx + 6), S(gy1)], radius=S(4), fill=rgba("#3a2414", 230))
    elif sil < 0.3:
        L.ellipse([S(cx - 5), S(gy1 - 9), S(cx + 5), S(gy1 - 1)], fill=rgba("#2f3a1e", 230))
        L.rectangle([S(cx - 3), S(gy1 - 3), S(cx + 3), S(gy1)], fill=rgba("#4a2a18", 230))
    elif sil < 0.36:
        L.ellipse([S(cx - 4), S(gy1 - 6), S(cx + 4), S(gy1)], fill=rgba("#20140c", 230))
        L.ellipse([S(cx + 1), S(gy1 - 10), S(cx + 6), S(gy1 - 5)], fill=rgba("#20140c", 230))
        L.polygon([(S(cx + 2), S(gy1 - 10)), (S(cx + 3), S(gy1 - 13)), (S(cx + 4), S(gy1 - 10))], fill=rgba("#20140c", 230))


def finalize(img, lit):
    img = grain(img, 4, 7)
    out = {"albedo": finish(img, W, H)}
    if lit is not None:
        lit = glow_from(lit, 5 * SS, 0.55)
        out["lit"] = finish(lit, W, H)
    return out


def door(d, x, y, w, h, color="#4a2f22", glass=True, transom=True):
    d.rectangle([S(x - 3), S(y - 4), S(x + w + 3), S(y + h)], fill=rgba("#a39a8b"))
    d.rectangle([S(x), S(y), S(x + w), S(y + h)], fill=rgba(color))
    if transom:
        d.rectangle([S(x + 2), S(y + 2), S(x + w - 2), S(y + 9)], fill=rgba("#2a3540"))
    if glass:
        d.rectangle([S(x + 4), S(y + 13), S(x + w - 4), S(y + h * 0.55)], fill=rgba("#25303b"))
    d.ellipse([S(x + w - 6), S(y + h * 0.6), S(x + w - 3), S(y + h * 0.6 + 3)], fill=rgba("#c9a54a"))


def facade_brick_red(seed=100):
    img = brick_wall(["#7b3b2c", "#8a4433", "#6e3428", "#934c38", "#763a2e"], "#5a4a40", seed)
    lit = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    stone_band(d, 0, 5, "#a59d90")             # cornice / floor line
    stone_band(d, 96, 100, "#a59d90")
    rnd = random.Random(seed)
    curtains = ["#7c2b2b", "#2f4a62", "#6b5a2a", None, "#4f6b3a"]
    for i, cx in enumerate((42, 128, 214)):
        window(img, lit, cx - 17, 22, 34, 52, seed + i, rnd.random() < 0.6, curtain=rnd.choice(curtains))
    # ground: door in the middle with stoop, windows either side, base course
    door(d, 112, 124, 32, 62)
    for i, cx in enumerate((44, 212)):
        window(img, lit, cx - 17, 118, 34, 50, seed + 10 + i, rnd.random() < 0.55, curtain=rnd.choice(curtains))
    d.rectangle([0, S(180), S(W), S(192)], fill=rgba("#5c5650"))
    if True:
        L = ImageDraw.Draw(lit)
        L.rectangle([S(114), S(126), S(142), S(133)], fill=rgba("#ffd27a", 220))  # transom light
    return finalize(soot(img), lit)


def facade_brick_brown(seed=200):
    img = brick_wall(["#5e4434", "#6a4c3a", "#56402f", "#73523e"], "#463a32", seed)
    lit = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    stone_band(d, 0, 6, "#9a9284")
    rnd = random.Random(seed)
    for i, cx in enumerate((64, 192)):
        window(img, lit, cx - 26, 20, 52, 54, seed + i, rnd.random() < 0.55, style="sash",
               curtain=rnd.choice(["#7c2b2b", "#3f5a3a", None]))
    # shopfront: sign band, two display windows, central door
    d.rectangle([0, S(96), S(W), S(112)], fill=rgba("#1f3a2e"))
    d.line([(0, S(98)), (S(W), S(98))], fill=rgba("#c8a24a"), width=SS)
    d.line([(0, S(110)), (S(W), S(110))], fill=rgba("#c8a24a"), width=SS)
    for x0 in (8, 136):
        window(img, lit, x0, 116, 104, 62, seed + 20 + x0, True, style="shop", frame="#2c2a26", lintel=None, sill=False,
               light_col=rnd.choice(["#ffd88a", "#ffe6a8"]))
    d.rectangle([S(112), S(116), S(136), S(186)], fill=rgba("#3b2a20"))
    d.rectangle([S(116), S(120), S(132), S(150)], fill=rgba("#2a3540"))
    d.rectangle([0, S(184), S(W), S(192)], fill=rgba("#4d4a46"))
    # goods in the display windows (lit mask): bottles, hats, cakes
    L = ImageDraw.Draw(lit)
    for x0 in (8, 136):
        for k in range(7):
            gx = x0 + 10 + k * 13 + rnd.uniform(-2, 2)
            kind = rnd.choice(["bottle", "hat", "box"])
            col = rnd.choice(["#6b3d1e", "#2e4a2a", "#7a2a22", "#3a3046"])
            if kind == "bottle":
                L.rectangle([S(gx), S(160), S(gx + 5), S(176)], fill=rgba(col, 255))
                L.rectangle([S(gx + 1.5), S(154), S(gx + 3.5), S(160)], fill=rgba(col, 255))
            elif kind == "hat":
                L.ellipse([S(gx - 3), S(166), S(gx + 9), S(172)], fill=rgba(col, 255))
                L.rectangle([S(gx), S(158), S(gx + 6), S(168)], fill=rgba(col, 255))
            else:
                L.rectangle([S(gx), S(164), S(gx + 10), S(176)], fill=rgba(col, 255))
    L.rectangle([S(116), S(120), S(132), S(150)], fill=rgba("#ffcf80", 200))
    return finalize(soot(img, 0.2), lit)


def facade_greystone(seed=300):
    n = tnoise(W * SS, H * SS, 4, seed, octaves=4)
    img = ramp(n, ["#8b867d", "#958f85", "#9e988d", "#8f8a80"])
    d = ImageDraw.Draw(img)
    for y in range(0, H, 12):
        d.line([(0, S(y)), (S(W), S(y))], fill=rgba("#757068"), width=SS)
        off = 0 if (y // 12) % 2 == 0 else 24
        for x in range(off, W + 48, 48):
            d.line([(S(x), S(y)), (S(x), S(y + 12))], fill=rgba("#7a756c"), width=SS)
    img = wrap_blur(img, 0.5 * SS)
    strokes(img, 220, ["#b1aa9e", "#706a61", "#a39d92"], 16, 4, seed + 1, alpha=(15, 45))
    lit = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    stone_band(d, 0, 7, "#b5ae9f", "#57524b")
    rnd = random.Random(seed)
    for i, cx in enumerate((40, 92, 164, 216)):
        window(img, lit, cx - 15, 22, 30, 52, seed + i, rnd.random() < 0.5, lintel="#b8b1a3",
               curtain=rnd.choice(["#6d3434", "#3c4f63", None, None]))
    for i, cx in enumerate((40, 92, 216)):
        window(img, lit, cx - 15, 116, 30, 50, seed + 10 + i, rnd.random() < 0.5, lintel="#b8b1a3",
               curtain=rnd.choice(["#6d3434", None]))
    door(d, 150, 122, 30, 64, color="#3c2a1f")
    d.rectangle([0, S(182), S(W), S(192)], fill=rgba("#6a655d"))
    ImageDraw.Draw(lit).rectangle([S(152), S(124), S(178), S(131)], fill=rgba("#ffd27a", 200))
    return finalize(soot(img, 0.15, 0.25), lit)


def facade_warehouse(seed=400):
    img = brick_wall(["#4e3530", "#583b34", "#47302b", "#5f413a"], "#3a312d", seed, bw=18, bh=6)
    lit = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # pilasters
    for x in (0, 128):
        d.rectangle([S(x), 0, S(x + 10), S(H)], fill=rgba("#4a332d"))
        d.line([(S(x + 10), 0), (S(x + 10), S(H))], fill=rgba("#2e2522"), width=SS)
    stone_band(d, 0, 4, "#7e776c")
    rnd = random.Random(seed)
    for i, x0 in enumerate((22, 150)):
        window(img, lit, x0, 20, 92, 50, seed + i, rnd.random() < 0.45, style="grid", frame="#2b2d2f", lintel="#6f685e",
               glass="#1a242a", light_col=rnd.choice(["#e8d48a", "#d6e0a0"]))
    # ground: big loading door + man door
    d.rectangle([S(18), S(110), S(112), S(190)], fill=rgba("#3a2c22"))
    for k in range(6):
        d.line([(S(18), S(110 + k * 14)), (S(112), S(110 + k * 14))], fill=rgba("#2a2019"), width=SS)
    for k in range(5):
        d.line([(S(18 + k * 19), S(110)), (S(18 + k * 19), S(190))], fill=rgba("#4a382c"), width=SS)
    d.rectangle([S(14), S(104), S(116), S(110)], fill=rgba("#6f685e"))
    window(img, lit, 150, 118, 92, 34, seed + 9, rnd.random() < 0.6, style="grid", frame="#2b2d2f", lintel=None,
           glass="#1a242a", light_col="#e8d48a")
    door(d, 178, 156, 26, 34, color="#2f3a2e", transom=False)
    d.rectangle([0, S(188), S(W), S(192)], fill=rgba("#3f3a35"))
    return finalize(soot(img, 0.3, 0.25), lit)


def facade_club(seed=500):
    """The Copper Owl: black-green glazed terracotta with copper deco lines."""
    n = tnoise(W * SS, H * SS, 4, seed, octaves=4)
    img = ramp(n, ["#16241f", "#1c2d27", "#22362f", "#1a2a24"])
    d = ImageDraw.Draw(img)
    for y in range(0, H, 16):
        d.line([(0, S(y)), (S(W), S(y))], fill=rgba("#111c18"), width=SS)
    for x in range(0, W, 32):
        d.line([(S(x), 0), (S(x), S(H))], fill=rgba("#142019"), width=SS)
    img = wrap_blur(img, 0.4 * SS)
    strokes(img, 160, ["#2e463d", "#0f1a16", "#3a5248"], 18, 3, seed, alpha=(20, 50))
    lit = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    copper = "#b8743a"
    for x in (16, 112, 144, 240):
        d.rectangle([S(x - 2), 0, S(x + 2), S(96)], fill=rgba(copper))
    d.rectangle([0, 0, S(W), S(5)], fill=rgba(copper))
    rnd = random.Random(seed)
    for i, cx in enumerate((64, 192)):
        window(img, lit, cx - 18, 16, 36, 64, seed + i, True, frame="#2a1a12", lintel=None, sill=False,
               glass="#2a1218", curtain="#6a1622", light_col="#ff9a5a")
    # ground: deco entrance with brass doors, two poster frames
    d.rectangle([0, S(96), S(W), S(104)], fill=rgba(copper))
    d.rectangle([S(96), S(110), S(160), S(190)], fill=rgba("#2a1a12"))
    for x0 in (100, 130):
        d.rectangle([S(x0), S(114), S(x0 + 26), S(188)], fill=rgba("#6b4a26"))
        d.rectangle([S(x0 + 4), S(120), S(x0 + 22), S(160)], fill=rgba("#2a1810"))
    for x0 in (22, 186):
        d.rectangle([S(x0), S(120), S(x0 + 48), S(176)], fill=rgba(copper))
        d.rectangle([S(x0 + 3), S(123), S(x0 + 45), S(173)], fill=rgba("#e6d6b0"))
        d.ellipse([S(x0 + 14), S(130), S(x0 + 34), S(150)], fill=rgba("#2a2a2a"))
        d.rectangle([S(x0 + 8), S(156), S(x0 + 40), S(160)], fill=rgba("#7a1e22"))
        d.rectangle([S(x0 + 12), S(164), S(x0 + 36), S(167)], fill=rgba("#2a2a2a"))
    L = ImageDraw.Draw(lit)
    for x0 in (100, 130):
        L.rectangle([S(x0 + 4), S(120), S(x0 + 22), S(160)], fill=rgba("#ffb060", 230))
    for x0 in (22, 186):
        L.rectangle([S(x0 + 3), S(123), S(x0 + 45), S(173)], fill=rgba("#ffe0a0", 120))
    # bulbs along the copper bands
    for x in range(8, W, 16):
        L.ellipse([S(x - 2), S(98), S(x + 2), S(102)], fill=rgba("#fff0b0", 255))
    return finalize(img, lit)


def facade_garage(seed=600):
    img = brick_wall(["#b5a27c", "#bfab84", "#a99773", "#c4b28c"], "#8a7c63", seed, bw=16, bh=6)
    lit = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    stone_band(d, 0, 6, "#7a2e24", "#3a1a14")
    rnd = random.Random(seed)
    for i, cx in enumerate((40, 128, 216)):
        window(img, lit, cx - 16, 22, 32, 44, seed + i, rnd.random() < 0.35, style="grid", frame="#3b3a35", lintel="#7a2e24")
    for x0 in (14, 138):
        d.rectangle([S(x0 - 4), S(104), S(x0 + 108), S(110)], fill=rgba("#7a2e24"))
        d.rectangle([S(x0), S(110), S(x0 + 104), S(190)], fill=rgba("#3d4a44"))
        for k in range(1, 5):
            d.line([(S(x0), S(110 + k * 16)), (S(x0 + 104), S(110 + k * 16))], fill=rgba("#2a3430"), width=SS)
        for k in range(4):
            d.rectangle([S(x0 + 6 + k * 25), S(116), S(x0 + 24 + k * 25), S(124)], fill=rgba("#25303b"))
    d.rectangle([0, S(188), S(W), S(192)], fill=rgba("#5a5248"))
    L = ImageDraw.Draw(lit)
    for x0 in (14, 138):
        for k in range(4):
            if rnd.random() < 0.8:
                L.rectangle([S(x0 + 6 + k * 25), S(116), S(x0 + 24 + k * 25), S(124)], fill=rgba("#ffe0a0", 210))
    return finalize(soot(img, 0.2, 0.3), lit)


def facade_party(seed=700):
    """Blank side wall: brick, a downpipe, patches, a faded painted sign."""
    img = brick_wall(["#704032", "#7b4838", "#653a2e", "#80503f"], "#54463e", seed)
    d = ImageDraw.Draw(img)
    rnd = random.Random(seed)
    # faded ghost-sign paint (no words, just the bands of an old advert)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    L = ImageDraw.Draw(layer)
    L.rectangle([S(20), S(14), S(236), S(70)], fill=rgba("#d8cfae", 46))
    L.rectangle([S(30), S(26), S(226), S(40)], fill=rgba("#7a2a22", 50))
    L.rectangle([S(46), S(48), S(210), S(58)], fill=rgba("#2a3a5a", 40))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(1.2 * SS)))
    d = ImageDraw.Draw(img)
    d.rectangle([S(200), 0, S(205), S(H)], fill=rgba("#3b3f42"))
    for y in range(10, H, 40):
        d.rectangle([S(198), S(y), S(207), S(y + 3)], fill=rgba("#2a2d2f"))
    d.rectangle([0, S(184), S(W), S(192)], fill=rgba("#5c5650"))
    return finalize(soot(img, 0.2, 0.2), None)


def facade_rear(seed=800):
    """Alley side: brick, back windows and a black iron fire escape."""
    img = brick_wall(["#6b3d30", "#76463a", "#5f362b", "#7f4c3c"], "#4f433b", seed)
    lit = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rnd = random.Random(seed)
    for i, cx in enumerate((48, 150, 210)):
        window(img, lit, cx - 15, 24, 30, 46, seed + i, rnd.random() < 0.5, curtain=rnd.choice(["#6b5a2a", None, "#2f4a62"]))
    for i, cx in enumerate((48, 210)):
        window(img, lit, cx - 15, 118, 30, 40, seed + 10 + i, rnd.random() < 0.4)
    door(d, 136, 132, 28, 54, color="#3a2f28", transom=False)
    # fire escape: landing at the floor line of each storey, rails, zig-zag stair
    iron = "#151517"
    fe = Image.new("RGBA", img.size, (0, 0, 0, 0))
    F = ImageDraw.Draw(fe)
    for base in (0, 96):
        F.rectangle([S(110), S(base + 78), S(250), S(base + 86)], fill=rgba(iron, 235))   # landing
        for x in range(112, 250, 5):
            F.line([(S(x), S(base + 78)), (S(x), S(base + 86))], fill=rgba("#4a4a50", 200), width=SS)
        F.line([(S(110), S(base + 64)), (S(250), S(base + 64))], fill=rgba(iron, 240), width=2 * SS)  # rail
        for x in range(110, 252, 14):
            F.line([(S(x), S(base + 64)), (S(x), S(base + 80))], fill=rgba(iron, 230), width=SS)
        F.line([(S(120), S(base + 82)), (S(176), S(base - 14))], fill=rgba(iron, 240), width=3 * SS)  # stair
        for k in range(8):
            t = k / 8
            x, y = 120 + 56 * t, base + 82 - 96 * t
            F.line([(S(x - 4), S(y)), (S(x + 6), S(y))], fill=rgba("#3a3a3f", 220), width=SS)
    img.alpha_composite(fe.filter(ImageFilter.GaussianBlur(0.3 * SS)))
    d = ImageDraw.Draw(img)
    d.rectangle([0, S(186), S(W), S(192)], fill=rgba("#4f4a45"))
    L = ImageDraw.Draw(lit)
    L.ellipse([S(146), S(124), S(154), S(132)], fill=rgba("#fff1c0", 255))  # bare bulb over the back door
    return finalize(soot(img, 0.25, 0.25), lit)


def facade_steel(seed=900):
    """Riveted steel truss (the raised bascule bridge leaf)."""
    n = tnoise(W * SS, H * SS, 4, seed, octaves=3)
    img = ramp(n, ["#3c4a46", "#46554f", "#40504a"])
    d = ImageDraw.Draw(img)
    for base in (0, 96):
        d.rectangle([0, S(base), S(W), S(base + 10)], fill=rgba("#2e3a36"))
        d.rectangle([0, S(base + 86), S(W), S(base + 96)], fill=rgba("#2e3a36"))
        for x in range(0, W, 64):
            d.line([(S(x), S(base + 10)), (S(x + 64), S(base + 86))], fill=rgba("#26302d"), width=5 * SS)
            d.line([(S(x + 64), S(base + 10)), (S(x), S(base + 86))], fill=rgba("#26302d"), width=5 * SS)
            d.rectangle([S(x - 3), S(base), S(x + 3), S(base + 96)], fill=rgba("#2b3633"))
        for x in range(2, W, 8):
            for y in (base + 4, base + 91):
                d.ellipse([S(x), S(y), S(x + 2), S(y + 2)], fill=rgba("#7c8a84"))
    img = wrap_blur(img, 0.4 * SS)
    strokes(img, 120, ["#7a4a2a", "#5a6a64"], 16, 3, seed, alpha=(20, 50))
    return finalize(img, None)


def facade_stone(seed=950):
    """Rusticated granite: the railroad embankment wall."""
    rnd = random.Random(seed)
    img = Image.new("RGBA", (W * SS, H * SS), rgba("#3b3a38"))
    d = ImageDraw.Draw(img)
    for r in range(H // 24):
        off = (r % 2) * 20
        x = -40 + off
        while x < W + 40:
            bw = rnd.choice([36, 40, 44])
            c = shade(rnd.choice(["#6a665f", "#75716a", "#5f5b55", "#7d786f"]), rnd.uniform(0.9, 1.08))
            pts = rrect_pts(S(x) + 2, S(r * 24) + 2, S(x + bw) - 3, S(r * 24 + 24) - 3, 4 * SS)
            for ox in (-W * SS, 0, W * SS):
                d.polygon([(p[0] + ox, p[1]) for p in pts], fill=c)
            x += bw
    img = wrap_blur(img, 0.8 * SS)
    n = tnoise(W * SS, H * SS, 8, seed + 1, octaves=4)
    img = modulate(img, n, 0.4)
    strokes(img, 180, ["#8a857b", "#3c3a36", "#4b5a3c"], 14, 3, seed + 2, alpha=(18, 50))
    return finalize(img, None)


def _pack(name, fn):
    def run():
        r = fn()
        out = {"facades/" + name: r["albedo"]}
        if "lit" in r:
            out["facades/" + name + "_lit"] = r["lit"]
        return out
    return run


ASSETS = {
    "facades/brick_red": _pack("brick_red", facade_brick_red),
    "facades/brick_brown": _pack("brick_brown", facade_brick_brown),
    "facades/greystone": _pack("greystone", facade_greystone),
    "facades/warehouse": _pack("warehouse", facade_warehouse),
    "facades/club": _pack("club", facade_club),
    "facades/garage": _pack("garage", facade_garage),
    "facades/party": _pack("party", facade_party),
    "facades/rear": _pack("rear", facade_rear),
    "facades/steel": _pack("steel", facade_steel),
    "facades/stone": _pack("stone", facade_stone),
}
