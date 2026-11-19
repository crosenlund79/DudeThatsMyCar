"""M012: the game menu (Esc) and the door plates by the entrances.

ui/menu_panel - the menu's case: worn oxblood leather, a tooled border, brass corner fittings (stretched by the game).
ui/menu_card  - the page inside: a cream card gone soft at the edges, a ruled Art Deco border (stretched by the game).
ui/door_plate - a small brass plate on the pavement before a door, seen from above (tinted by the game: warm for a door
                that opens, cold for one shut for the night, amber for a bell)."""
import math
import random

import numpy as np
from PIL import Image, ImageDraw

from paintkit import *

OUT = (20, 14, 12)
BRASS = "#c9a24e"


def _corner(img, cx, cy, sx, sy, seed):
    """A brass corner fitting: a quarter fan with a rivet, pointing into the corner (sx, sy = +-1)."""
    pts = [(cx, cy), (cx + 34 * sx, cy), (cx + 34 * sx, cy + 8 * sy), (cx + 8 * sx, cy + 8 * sy), (cx + 8 * sx, cy + 34 * sy),
           (cx, cy + 34 * sy)]
    paint_shape(img, SP(pts), BRASS, seed, outline=OUT, ow=1.2, wob=0.05, tex=0.25, light=(0.3, -1, 0.6))
    for k in range(3):
        r = 14 + k * 6
        a0 = 0 if sx > 0 else math.pi
        pts2 = []
        for j in range(9):
            a = math.pi / 2 * j / 8
            pts2.append((cx + sx * math.cos(a) * r, cy + sy * math.sin(a) * r))
        line(img, [S(px, py) for px, py in pts2], "#8a6a2e", 1.0 * SS, 200)
    paint_shape(img, SP(ellipse_pts(cx + 5 * sx, cy + 5 * sy, 2.6, 2.6)), "#e8cc80", seed + 1, outline=OUT, ow=0.6, wob=0.0,
                light=(0.3, -1, 0.8))


def menu_panel(seed=1201):
    w, h = 640, 480
    n = tnoise(w * SS, h * SS, 5, seed, octaves=5)
    img = ramp(n, ["#2a1210", "#3a1a16", "#4a221c", "#331614"])
    img = modulate(img, tnoise(w * SS, h * SS, 30, seed + 1, octaves=2), 0.12)  # the leather's grain
    rnd = random.Random(seed)
    d = ImageDraw.Draw(img)
    # scuffs and creases
    for k in range(40):
        x, y = rnd.uniform(0, w), rnd.uniform(0, h)
        line(img, [S(x, y), S(x + rnd.uniform(-30, 30), y + rnd.uniform(-6, 6))], "#5a3028", rnd.uniform(0.5, 1.5) * SS,
             rnd.randint(30, 90))
    # the tooled border: two gilt rules and a row of stamped diamonds
    for inset, wd, a in ((14, 1.6, 200), (22, 0.8, 150)):
        line(img, [S(inset, inset), S(w - inset, inset), S(w - inset, h - inset), S(inset, h - inset), S(inset, inset)],
             "#a8823e", wd * SS, a)
    for x in range(40, w - 30, 16):
        for y0 in (18, h - 18):
            paint_shape(img, SP([(x, y0 - 2.5), (x + 2.5, y0), (x, y0 + 2.5), (x - 2.5, y0)]), "#8a6a2e", seed + x, outline=None,
                        wob=0.0)
    # edges worn darker
    a = np.asarray(img, dtype=np.float32).copy()
    yy, xx = np.mgrid[0:h * SS, 0:w * SS]
    edge = np.minimum(np.minimum(xx, w * SS - xx), np.minimum(yy, h * SS - yy)) / (40.0 * SS)
    a[..., :3] *= (0.62 + 0.38 * np.clip(edge, 0, 1))[..., None]
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    for cx, cy, sx, sy in ((4, 4, 1, 1), (w - 4, 4, -1, 1), (4, h - 4, 1, -1), (w - 4, h - 4, -1, -1)):
        _corner(img, cx, cy, sx, sy, seed + cx + cy)
    return finish(grain(img, 6, seed), w, h)


def menu_card(seed=1211):
    w, h = 400, 480
    n = tnoise(w * SS, h * SS, 4, seed, octaves=5)
    img = ramp(n, ["#d9caa4", "#e6d8b6", "#efe3c4", "#ddcda8"])
    rnd = random.Random(seed)
    # foxing and a coffee ring
    for k in range(14):
        soft_blob(img, S(rnd.uniform(10, w - 10)), S(rnd.uniform(10, h - 10)), S(rnd.uniform(2, 6)), S(rnd.uniform(2, 6)),
                  "#b08850", rnd.randint(30, 70), 1.5 * SS)
    ring = Image.new("RGBA", img.size, (0, 0, 0, 0))
    cx, cy, r = w * 0.78, h * 0.86, 30
    ImageDraw.Draw(ring).ellipse([S(cx - r), S(cy - r), S(cx + r), S(cy + r)], outline=rgba("#9a7444", 60), width=int(2.4 * SS))
    img.alpha_composite(ring)
    # the Art Deco rules: a double line and stepped corners
    for inset, wd in ((12, 1.4), (17, 0.7)):
        line(img, [S(inset, inset), S(w - inset, inset), S(w - inset, h - inset), S(inset, h - inset), S(inset, inset)],
             "#6a4a26", wd * SS, 210)
    for sx, sy, x0, y0 in ((1, 1, 12, 12), (-1, 1, w - 12, 12), (1, -1, 12, h - 12), (-1, -1, w - 12, h - 12)):
        for k in range(3):
            o = 8 + k * 6
            line(img, [S(x0 + sx * o, y0), S(x0 + sx * o, y0 + sy * o), S(x0, y0 + sy * o)], "#6a4a26", 0.8 * SS, 170)
    # soft, darker edges
    a = np.asarray(img, dtype=np.float32).copy()
    yy, xx = np.mgrid[0:h * SS, 0:w * SS]
    edge = np.minimum(np.minimum(xx, w * SS - xx), np.minimum(yy, h * SS - yy)) / (18.0 * SS)
    a[..., :3] *= (0.78 + 0.22 * np.clip(edge, 0, 1))[..., None]
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    return finish(grain(img, 5, seed), w, h)


def door_plate(seed=1221):
    """A worn brass threshold plate, long side across the doorway, a row of grip studs (drawn light: the game tints it)."""
    w, h = 64, 20
    img = new(w, h)
    soft_blob(img, S(32), S(11), S(29), S(7), "#000000", 110, 2 * SS)
    paint_shape(img, SP(rrect_pts(3, 4, w - 3, h - 4, 2)), "#efe6cf", seed, outline=(60, 50, 36), ow=0.9, wob=0.04, tex=0.25,
                light=(0.3, -1, 0.5))
    for k in range(9):
        x = 9 + k * 5.8
        soft_blob(img, S(x), S(10), S(1.1), S(1.1), "#a89a80", 220, 0.3 * SS)
    line(img, [S(6, 6), S(w - 6, 6)], "#ffffff", 0.8 * SS, 120)
    return finish(img, w, h)


ASSETS = {
    "ui/menu_panel": menu_panel,
    "ui/menu_card": menu_card,
    "ui/door_plate": door_plate,
}
