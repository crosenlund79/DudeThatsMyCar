"""1930s cars, top-down, nose pointing right (+X). Template 176 x 80 -> display 80 x 36."""
import math
import random

from PIL import Image, ImageDraw, ImageFilter

from paintkit import *

CW, CH = 176, 80
CHROME = "#cfd2d4"
CHROME_DARK = "#7d8285"
TYRE = "#141414"
OUT = (22, 18, 18)


def fender(cx, cy, rx, ry, taper_front, taper_rear, side):
    """Pontoon fender outline (template px); side -1 top, +1 bottom (outer edge away from the body)."""
    pts = []
    for i in range(40):
        a = 2 * math.pi * i / 40
        x = math.cos(a) * rx
        y = math.sin(a) * ry
        # flatten the inner side (towards the body), taper the ends
        if (y > 0) == (side < 0):
            y *= 0.55
        if x > 0:
            y *= 1 - taper_front * (x / rx) ** 2
        else:
            y *= 1 - taper_rear * (x / rx) ** 2
        pts.append((cx + x, cy + y))
    return pts


def chrome_bar(img, x0, y0, x1, y1, seed):
    paint_shape(img, SP(rrect_pts(x0, y0, x1, y1, 2)), CHROME, seed, outline=OUT, ow=1.1, wob=0.2, tex=0.12,
                light=(0, -1, 0.35))


def lamp(img, cx, cy, r, seed, glass="#e9e4c8"):
    paint_shape(img, SP(ellipse_pts(cx, cy, r, r * 0.9)), CHROME, seed, outline=OUT, ow=1.0, wob=0.15, light=(1, -1, 0.4))
    soft_blob(img, S(cx + r * 0.25), S(cy), S(r * 0.55), S(r * 0.55), glass, 230, 0.6 * SS)


def tyre_top(img, x0, y0, x1, y1, seed):
    paint_shape(img, SP(rrect_pts(x0, y0, x1, y1, 2.5)), TYRE, seed, outline=None, wob=0.1, tex=0.25)
    d = ImageDraw.Draw(img)
    for x in range(int(x0) + 2, int(x1) - 1, 3):
        d.line([(S(x), S(y0 + 0.8)), (S(x), S(y1 - 0.8))], fill=rgba("#2c2c2c"), width=1)


def sheen(img, pts, alpha=60, blur=2.0):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).polygon(SP(pts), fill=rgba("#ffffff", alpha))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur * SS)))


def sedan(body="#1d2b25", roof=None, seed=1):
    roof = roof or shade(body, 1.18)
    img = new(CW, CH)
    # rear tyres peeking from under the fenders (the front ones are cars/wheel, turned by the steering)
    tyre_top(img, 26, 3.5, 50, 11, seed)
    tyre_top(img, 26, 69, 50, 76.5, seed + 1)
    # running boards
    for y0, y1 in ((10, 17), (63, 70)):
        paint_shape(img, SP(rrect_pts(52, y0, 120, y1, 2)), "#1b1b1c", seed + 2, outline=OUT, ow=1, wob=0.2, tex=0.3)
        ImageDraw.Draw(img).line([(S(54), S((y0 + y1) / 2)), (S(118), S((y0 + y1) / 2))], fill=rgba("#55585a"), width=SS)
    # body: trunk + cabin + hood in one organic outline
    body_pts = [(14, 30), (18, 21), (30, 18), (52, 15.5), (104, 15.5), (112, 19.5), (162, 21), (170, 26),
                (172, 40), (170, 54), (162, 59), (112, 60.5), (104, 64.5), (52, 64.5), (30, 62), (18, 59), (14, 50)]
    paint_shape(img, SP(body_pts), body, seed + 3, outline=OUT, ow=1.8, wob=0.35, tex=0.12, strokes_n=14, stroke_cols=[shade(body, 1.08), shade(body, 0.94)],
                light=(0.2, -1, 0.45), inner_shadow=0.35)
    # fenders over the tyres
    for side, cy in ((-1, 13.5), (1, 66.5)):
        paint_shape(img, SP(fender(38, cy, 24, 9.5, 0.35, 0.65, side)), shade(body, 0.92), seed + 4 + cy, outline=OUT,
                    ow=1.6, wob=0.3, tex=0.18, light=(0.3, -1, 0.5))
        paint_shape(img, SP(fender(140, cy, 33, 10, 0.75, 0.35, side)), shade(body, 0.92), seed + 6 + cy, outline=OUT,
                    ow=1.6, wob=0.3, tex=0.18, light=(0.3, -1, 0.5))
    # hood: louvres and the centre hinge strip
    d = ImageDraw.Draw(img)
    for x in range(124, 152, 4):
        for y0 in (25, 50):
            line(img, [(S(x), S(y0)), (S(x + 2), S(y0 + 5))], "#0c100e", 1.4 * SS, 220, blur=0.2)
    line(img, [(S(110), S(40)), (S(168), S(40))], CHROME, 1.4 * SS, 230, blur=0.2)
    # cabin roof with windscreen and rear window
    paint_shape(img, SP([(104, 22), (111, 26), (111, 54), (104, 58)]), "#2a3a48", seed + 8, outline=OUT, ow=1.2, wob=0.15, tex=0.1,
                light=(0, -1, 0.6))
    paint_shape(img, SP([(50, 24), (56, 21), (56, 59), (50, 56)]), "#2a3a48", seed + 9, outline=OUT, ow=1.0, wob=0.15, tex=0.1)
    paint_shape(img, SP(rrect_pts(55, 19.5, 104, 60.5, 7)), roof, seed + 10, outline=OUT, ow=1.6, wob=0.25, tex=0.1,
                strokes_n=10, stroke_cols=[shade(roof, 1.06), shade(roof, 0.95)], light=(0.1, -1, 0.5), inner_shadow=0.25)
    # side glass strips
    for y0, y1 in ((16.5, 19.5), (60.5, 63.5)):
        paint_shape(img, SP(rrect_pts(58, y0, 100, y1, 1)), "#2c3c4a", seed + 11, outline=None, wob=0.1, tex=0.1)
    # trunk lid line, spare tyre and bumpers
    line(img, [(S(34), S(22)), (S(34), S(58))], shade(body, 0.6), 1.2 * SS, 200)
    paint_shape(img, SP(rrect_pts(4, 27, 15, 53, 4)), TYRE, seed + 12, outline=OUT, ow=1, wob=0.15, tex=0.2)
    paint_shape(img, SP(rrect_pts(6.5, 33, 12.5, 47, 2)), CHROME, seed + 13, outline=None, wob=0.1, light=(0, -1, 0.4))
    chrome_bar(img, 1.5, 15, 5, 65, seed + 14)
    chrome_bar(img, 171, 13, 175, 67, seed + 15)
    # grille shell + radiator cap, headlamps, horns
    paint_shape(img, SP(rrect_pts(164, 31, 171, 49, 2.5)), CHROME, seed + 16, outline=OUT, ow=1, wob=0.1, light=(1, -1, 0.4))
    for y in range(33, 48, 2):
        d.line([(S(165.5), S(y)), (S(169.5), S(y))], fill=rgba("#3a3e40"), width=1)
    lamp(img, 162, 20, 4.2, seed + 17)
    lamp(img, 162, 60, 4.2, seed + 18)
    # tail lamps
    for y in (12, 68):
        paint_shape(img, SP(ellipse_pts(19, y, 2.4, 2)), "#8a1a16", seed + 19, outline=OUT, ow=0.8, wob=0.1)
    # door handles and the beltline chrome
    for x in (66, 92):
        d.line([(S(x), S(18)), (S(x + 3), S(18))], fill=rgba(CHROME), width=SS)
        d.line([(S(x), S(62)), (S(x + 3), S(62))], fill=rgba(CHROME), width=SS)
    # highlights on hood and roof (wet paint)
    sheen(img, [(114, 30), (160, 31), (160, 34), (114, 34)], 55, 1.6)
    sheen(img, [(62, 26), (98, 26), (98, 31), (62, 31)], 50, 2.2)
    return finish(grain(img, 3, seed), CW, CH)


def coupe(body="#e3d4ac", fend="#6a1d22", seat="#7b2420", seed=5):
    img = new(CW, CH)
    tyre_top(img, 22, 3.5, 46, 11, seed)
    tyre_top(img, 22, 69, 46, 76.5, seed + 1)
    for y0, y1 in ((10.5, 17), (63, 69.5)):
        paint_shape(img, SP(rrect_pts(48, y0, 120, y1, 2)), fend, seed + 2, outline=OUT, ow=1, wob=0.2, tex=0.25)
    # boat-tail body: long hood, short cockpit, tapering tail
    body_pts = [(4, 40), (8, 31), (18, 24), (40, 18), (60, 16), (100, 17), (112, 20.5), (162, 22), (169, 27),
                (171, 40), (169, 53), (162, 58), (112, 59.5), (100, 63), (60, 64), (40, 62), (18, 56), (8, 49)]
    paint_shape(img, SP(body_pts), body, seed + 3, outline=OUT, ow=1.8, wob=0.35, tex=0.1, strokes_n=14, stroke_cols=[shade(body, 1.06), shade(body, 0.95)],
                light=(0.2, -1, 0.4), inner_shadow=0.3)
    # tail centre strip
    line(img, [(S(6), S(40)), (S(58), S(40))], CHROME, 1.4 * SS, 230, blur=0.2)
    # cockpit: open, red leather bench, steering wheel, dash
    paint_shape(img, SP(rrect_pts(58, 21, 94, 59, 8)), "#2a1a14", seed + 4, outline=OUT, ow=1.4, wob=0.2, tex=0.2)
    paint_shape(img, SP(rrect_pts(60, 23, 76, 57, 6)), seat, seed + 5, outline=OUT, ow=1.0, wob=0.2, tex=0.25, light=(0, -1, 0.5))
    d = ImageDraw.Draw(img)
    for y in (30, 40, 50):
        d.line([(S(62), S(y)), (S(74), S(y))], fill=rgba(shade(seat, 0.65)), width=SS)
    paint_shape(img, SP(rrect_pts(88, 22, 93, 58, 2)), "#3a2418", seed + 6, outline=None, wob=0.1, tex=0.2)
    paint_shape(img, SP(ellipse_pts(84, 31, 2.2, 6.5)), "#141414", seed + 7, outline=None, wob=0.05)
    line(img, [(S(84), S(26)), (S(84), S(36))], "#141414", 1.2 * SS, 255)
    # folded tan top behind the seat
    paint_shape(img, SP(rrect_pts(50, 22, 59, 58, 3)), "#b49a72", seed + 8, outline=OUT, ow=1.0, wob=0.2, tex=0.25)
    # V windscreen
    line(img, [(S(96), S(22)), (S(100), S(40)), (S(96), S(58))], CHROME, 1.6 * SS, 240, blur=0.2)
    line(img, [(S(97.5), S(23)), (S(101.5), S(40)), (S(97.5), S(57))], "#9fb6c8", 1.2 * SS, 140, blur=0.3)
    # fenders (dark two-tone), long and swept
    for side, cy in ((-1, 13.5), (1, 66.5)):
        paint_shape(img, SP(fender(34, cy, 22, 9.5, 0.3, 0.7, side)), fend, seed + 9 + cy, outline=OUT, ow=1.6, wob=0.3,
                    tex=0.18, light=(0.3, -1, 0.5))
        paint_shape(img, SP(fender(140, cy, 34, 10, 0.8, 0.3, side)), fend, seed + 11 + cy, outline=OUT, ow=1.6, wob=0.3,
                    tex=0.18, light=(0.3, -1, 0.5))
        # side-mounted spare wheel sitting in the front fender
        sy = cy + (2.5 if side < 0 else -2.5)
        paint_shape(img, SP(ellipse_pts(114, sy, 7.5, 5.5)), TYRE, seed + 13 + cy, outline=OUT, ow=1, wob=0.1, tex=0.2)
        paint_shape(img, SP(ellipse_pts(114, sy, 4.6, 3.2)), "#ece6d6", seed + 15 + cy, outline=None, wob=0.05)
        paint_shape(img, SP(ellipse_pts(114, sy, 2.4, 1.8)), CHROME, seed + 17 + cy, outline=None, wob=0.05)
    # hood louvres and centre line
    for x in range(118, 156, 4):
        for y0 in (25.5, 49.5):
            line(img, [(S(x), S(y0)), (S(x + 2), S(y0 + 5))], shade(body, 0.55), 1.3 * SS, 220, blur=0.2)
    line(img, [(S(104), S(40)), (S(167), S(40))], CHROME, 1.3 * SS, 230, blur=0.2)
    chrome_bar(img, 170.5, 14, 174.5, 66, seed + 18)
    chrome_bar(img, 1.5, 30, 4.5, 50, seed + 19)
    paint_shape(img, SP(rrect_pts(163, 32, 170, 48, 3)), CHROME, seed + 20, outline=OUT, ow=1, wob=0.1, light=(1, -1, 0.4))
    for y in range(34, 47, 2):
        ImageDraw.Draw(img).line([(S(164.5), S(y)), (S(168.5), S(y))], fill=rgba("#3a3e40"), width=1)
    lamp(img, 161, 21, 5.2, seed + 21)
    lamp(img, 161, 59, 5.2, seed + 22)
    for y in (24, 56):
        paint_shape(img, SP(ellipse_pts(12, y, 2.2, 1.8)), "#8a1a16", seed + 23, outline=OUT, ow=0.8, wob=0.1)
    sheen(img, [(112, 30), (160, 31), (160, 34), (112, 34)], 70, 1.6)
    sheen(img, [(12, 33), (50, 30), (50, 33), (12, 36)], 45, 1.8)
    return finish(grain(img, 3, seed), CW, CH)


def wheel(seed=9):
    """Front tyre seen from above: whitewall sidewalls along both long edges, dark tread between."""
    W, H = 48, 20
    img = new(W, H)
    paint_shape(img, SP(rrect_pts(2, 2, 46, 18, 6)), "#e4dccb", seed, outline=OUT, ow=1.4, wob=0.15, tex=0.15,
                light=(0, -1, 0.3))
    paint_shape(img, SP(rrect_pts(4, 6, 44, 14, 3.5)), TYRE, seed + 1, outline=None, wob=0.1, tex=0.3)
    d = ImageDraw.Draw(img)
    for x in range(8, 42, 4):
        d.line([(S(x), S(6.8)), (S(x + 1.5), S(13.2))], fill=rgba("#323232"), width=SS)
    sheen(img, [(8, 3.5), (40, 3.5), (40, 5), (8, 5)], 70, 0.8)
    return finish(grain(img, 2, seed), W, H)


ASSETS = {
    "cars/wheel": lambda: wheel(9),
    "cars/sedan": lambda: sedan("#1d2b25", seed=1),
    "cars/sedan_b": lambda: sedan("#4a1b1e", roof="#2a1213", seed=2),
    "cars/coupe": lambda: coupe("#e3d4ac", "#6a1d22", "#7b2420", seed=5),
    "cars/coupe_b": lambda: coupe("#2e4a3a", "#1c1c1e", "#a0794a", seed=6),
}
