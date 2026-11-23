"""1930s cars, top-down, nose pointing right (+X). Template 176 x 80 -> display 80 x 36."""
import math
import random

from PIL import Image, ImageDraw, ImageFilter

from paintkit import *
from paint_props import DECO

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


def mirror(pts):
    """The same outline on the other side of the car (y mirrored about the centre line)."""
    return [(x, CH - y) for x, y in reversed(pts)]


# Wing outlines for the top side of the car (template px); mirror() gives the other side.
# Front wings are teardrops that sweep forward and in to a point beside the radiator,
# rear wings are short and round: the nose reads narrow and pointed, the tail full.
FRONT_WING = [(104, 17.5), (110, 11), (122, 6), (136, 3.6), (150, 5.2), (161, 9.5), (168, 15), (170.5, 20.5),
              (166, 22), (156, 20.5), (140, 19), (122, 18.5)]
REAR_WING = [(64, 17.5), (58, 10), (48, 5.2), (36, 3.6), (24, 5), (15, 9), (11, 14.5), (12, 19), (22, 19.5), (44, 19)]


def wings(img, color, seed, front=FRONT_WING, rear=REAR_WING):
    for k, pts in enumerate((front, mirror(front), rear, mirror(rear))):
        paint_shape(img, SP(pts), color, seed + k, outline=OUT, ow=1.6, wob=0.25, tex=0.18, light=(0.3, -1, 0.5))
    # a crease of light along each front wing
    for pts in (front, mirror(front)):
        xs = [x for x, _ in pts]
        top = min(pts, key=lambda p: abs(p[0] - 140))
        sheen(img, [(118, top[1] + 3), (158, top[1] + 4), (158, top[1] + 5.5), (118, top[1] + 4.5)], 45, 1.0)


def radiator(img, seed, x0=160, half=10.5):
    """A narrow V-fronted radiator shell with vertical slats and a mascot on the cap (points forward, +X)."""
    shell = [(x0, 40 - half), (x0 + 6, 40 - half + 2.5), (x0 + 10.5, 40), (x0 + 6, 40 + half - 2.5), (x0, 40 + half)]
    paint_shape(img, SP(shell), CHROME, seed, outline=OUT, ow=1.1, wob=0.08, light=(1, -1, 0.45))
    d = ImageDraw.Draw(img)
    for y in range(int(40 - half + 3), int(40 + half - 2), 2):
        d.line([(S(x0 + 1.5), S(y)), (S(x0 + 5.5 - abs(y - 40) * 0.12), S(y))], fill=rgba("#3a3e40"), width=1)
    # the mascot on the radiator cap: a bright chrome teardrop pointing ahead
    paint_shape(img, SP([(x0 - 6, 37.8), (x0 + 1, 39), (x0 + 3.5, 40), (x0 + 1, 41), (x0 - 6, 42.2)]), "#eef0f1", seed + 1,
                outline=OUT, ow=0.6, wob=0.02, light=(1, -1, 0.5))


def front_bumper(img, seed, top=21.5, x=169.5):
    """A chrome bumper bowed forward in the middle, narrower than the wings."""
    pts = [(x - 1.5, top), (x + 2.6, 30), (x + 4.4, 40), (x + 2.6, 80 - 30), (x - 1.5, 80 - top),
           (x - 4.2, 80 - top), (x - 0.6, 80 - 30), (x + 1.2, 40), (x - 0.6, 30), (x - 4.2, top)]
    paint_shape(img, SP(pts), CHROME, seed, outline=OUT, ow=1.0, wob=0.05, light=(1, -1, 0.4))


def windscreen(img, x0, x1, top, seed, split=True):
    """A bright, slanted windscreen with a highlight: the brightest glass on the car, at the front of the cabin."""
    pts = [(x0, top), (x1, top + 3.5), (x1, 80 - top - 3.5), (x0, 80 - top)]
    paint_shape(img, SP(pts), "#6f97b2", seed, outline=OUT, ow=1.2, wob=0.1, tex=0.08, light=(1, -1, 0.6))
    line(img, [(S(x0 + 2.5), S(top + 4)), (S(x1 - 1.5), S(top + 9))], "#e6f2fa", 1.3 * SS, 190, blur=0.4)
    if split:
        line(img, [(S(x0 + 0.5), S(40)), (S(x1 - 0.5), S(40))], CHROME_DARK, 1.0 * SS, 230)


def sedan(body="#1d2b25", roof=None, seed=1):
    roof = roof or shade(body, 1.18)
    img = new(CW, CH)
    # rear tyres peeking from under the wings (the front ones are cars/wheel, turned by the steering)
    tyre_top(img, 26, 3.5, 50, 11, seed)
    tyre_top(img, 26, 69, 50, 76.5, seed + 1)
    # running boards
    for y0, y1 in ((11, 18), (62, 69)):
        paint_shape(img, SP(rrect_pts(56, y0, 116, y1, 2)), "#1b1b1c", seed + 2, outline=OUT, ow=1, wob=0.2, tex=0.3)
        ImageDraw.Draw(img).line([(S(58), S((y0 + y1) / 2)), (S(114), S((y0 + y1) / 2))], fill=rgba("#55585a"), width=SS)
    # body: a full, rounded trunk at the back, the cabin set back, a long hood narrowing to the radiator
    body_pts = [(8, 34), (10, 25), (17, 19), (30, 16), (56, 15.5), (100, 16), (110, 18.5), (132, 22), (150, 26), (161, 29.5),
                (161, 50.5), (150, 54), (132, 58), (110, 61.5), (100, 64), (56, 64.5), (30, 64), (17, 61), (10, 55), (8, 46)]
    paint_shape(img, SP(body_pts), body, seed + 3, outline=OUT, ow=1.8, wob=0.35, tex=0.12, strokes_n=14,
                stroke_cols=[shade(body, 1.08), shade(body, 0.94)], light=(0.2, -1, 0.45), inner_shadow=0.35)
    wings(img, shade(body, 0.9), seed + 4)
    # hood: louvres down both sides, the hinge strip along the middle
    for x in range(118, 150, 4):
        for y0 in (27, 48):
            line(img, [(S(x), S(y0)), (S(x + 2), S(y0 + 4.5))], "#0c100e", 1.3 * SS, 220, blur=0.2)
    line(img, [(S(110), S(40)), (S(158), S(40))], CHROME, 1.3 * SS, 230, blur=0.2)
    radiator(img, seed + 5)
    # the cabin: roof set back, a big bright windscreen at its front, a small rear window
    paint_shape(img, SP([(46, 27), (53, 24), (53, 56), (46, 53)]), "#22303a", seed + 9, outline=OUT, ow=1.0, wob=0.15, tex=0.1)
    paint_shape(img, SP(rrect_pts(52, 19, 100, 61, 7)), roof, seed + 10, outline=OUT, ow=1.6, wob=0.25, tex=0.1,
                strokes_n=10, stroke_cols=[shade(roof, 1.06), shade(roof, 0.95)], light=(0.1, -1, 0.5), inner_shadow=0.25)
    windscreen(img, 99, 109, 20.5, seed + 8)
    for y0, y1 in ((16.5, 19.5), (60.5, 63.5)):
        paint_shape(img, SP(rrect_pts(56, y0, 98, y1, 1)), "#2c3c4a", seed + 11, outline=None, wob=0.1, tex=0.1)
    # the back: trunk lid, the spare wheel under a painted cover, two dull bumperettes, red tail lamps
    # (all the bright chrome is at the nose, so the front reads even with the lamps off)
    line(img, [(S(30), S(23)), (S(30), S(57))], shade(body, 0.6), 1.2 * SS, 200)
    paint_shape(img, SP(rrect_pts(2, 27, 12, 53, 4)), shade(body, 0.8), seed + 12, outline=OUT, ow=1.1, wob=0.15, tex=0.2,
                light=(0.3, -1, 0.4))
    line(img, [(S(7), S(29)), (S(7), S(51))], shade(body, 0.55), 1.0 * SS, 200)
    for y0, y1 in ((15, 25), (55, 65)):
        paint_shape(img, SP(rrect_pts(2.5, y0, 5.5, y1, 1.5)), CHROME_DARK, seed + 14 + y0, outline=OUT, ow=0.9, wob=0.05)
    for y in (15, 65):
        paint_shape(img, SP(ellipse_pts(13.5, y, 3.4, 3.0)), "#b3221c", seed + 19, outline=OUT, ow=0.8, wob=0.1)
        soft_blob(img, S(13), S(y - 0.6), S(1.3), S(1.1), "#ffb0a0", 160, 0.4 * SS)
    # the front: big headlamps between the wings and the radiator, a bowed bumper narrower than the wings
    lamp(img, 157, 23.5, 4.8, seed + 17)
    lamp(img, 157, 56.5, 4.8, seed + 18)
    front_bumper(img, seed + 15)
    # door handles and the belt-line chrome
    d = ImageDraw.Draw(img)
    for x in (64, 90):
        d.line([(S(x), S(17.5)), (S(x + 3), S(17.5))], fill=rgba(CHROME), width=SS)
        d.line([(S(x), S(62.5)), (S(x + 3), S(62.5))], fill=rgba(CHROME), width=SS)
    # highlights on hood and roof (wet paint)
    sheen(img, [(114, 31), (152, 32), (152, 34.5), (114, 34)], 55, 1.6)
    sheen(img, [(60, 26), (96, 26), (96, 31), (60, 31)], 50, 2.2)
    return finish(grain(img, 3, seed), CW, CH)


def coupe(body="#e3d4ac", fend="#6a1d22", seat="#7b2420", seed=5):
    img = new(CW, CH)
    tyre_top(img, 22, 3.5, 46, 11, seed)
    tyre_top(img, 22, 69, 46, 76.5, seed + 1)
    for y0, y1 in ((11.5, 18), (62, 68.5)):
        paint_shape(img, SP(rrect_pts(50, y0, 118, y1, 2)), fend, seed + 2, outline=OUT, ow=1, wob=0.2, tex=0.25)
    # long hood narrowing to the radiator, a short cockpit set back, a rounded boat-tail deck
    body_pts = [(6, 36), (8, 29), (16, 23), (34, 18.5), (58, 16.5), (98, 17), (112, 20), (136, 23.5), (152, 27), (161, 30),
                (161, 50), (152, 53), (136, 56.5), (112, 60), (98, 63), (58, 63.5), (34, 61.5), (16, 57), (8, 51), (6, 44)]
    paint_shape(img, SP(body_pts), body, seed + 3, outline=OUT, ow=1.8, wob=0.35, tex=0.1, strokes_n=14,
                stroke_cols=[shade(body, 1.06), shade(body, 0.95)], light=(0.2, -1, 0.4), inner_shadow=0.3)
    front = [(100, 18.5), (108, 10.5), (122, 5.5), (140, 3.6), (154, 5.5), (164, 10), (171, 16.5), (172.5, 21.5),
             (167, 23), (156, 21.5), (140, 20), (118, 19.5)]
    rear = [(58, 17.5), (52, 10), (42, 5), (32, 3.6), (21, 5), (13, 9.5), (10, 15), (12, 19.5), (24, 20), (42, 19)]
    wings(img, fend, seed + 9, front, rear)
    # tail: the chrome strip down the deck, a fuel cap, round tail lamps
    line(img, [(S(14), S(40)), (S(48), S(40))], shade(body, 0.6), 1.3 * SS, 220, blur=0.2)
    paint_shape(img, SP(ellipse_pts(20, 40, 2.4, 2.4)), CHROME_DARK, seed + 30, outline=OUT, ow=0.6, wob=0.02)
    for y in (24, 56):
        paint_shape(img, SP(ellipse_pts(10, y, 3.0, 2.7)), "#b3221c", seed + 23, outline=OUT, ow=0.8, wob=0.1)
        soft_blob(img, S(9.6), S(y - 0.5), S(1.1), S(0.9), "#ffb0a0", 160, 0.4 * SS)
    # cockpit: open, red leather bench at the back of it, the steering wheel and dash at the front
    paint_shape(img, SP(rrect_pts(56, 21, 94, 59, 8)), "#2a1a14", seed + 4, outline=OUT, ow=1.4, wob=0.2, tex=0.2)
    paint_shape(img, SP(rrect_pts(58, 23, 73, 57, 6)), seat, seed + 5, outline=OUT, ow=1.0, wob=0.2, tex=0.25, light=(0, -1, 0.5))
    d = ImageDraw.Draw(img)
    for y in (30, 40, 50):
        d.line([(S(60), S(y)), (S(71), S(y))], fill=rgba(shade(seat, 0.65)), width=SS)
    paint_shape(img, SP(rrect_pts(88, 22, 93, 58, 2)), "#3a2418", seed + 6, outline=None, wob=0.1, tex=0.2)
    paint_shape(img, SP(ellipse_pts(83, 31, 2.2, 6.5)), "#141414", seed + 7, outline=None, wob=0.05)
    line(img, [(S(83), S(26)), (S(83), S(36))], "#141414", 1.2 * SS, 255)
    # folded tan top behind the seat
    paint_shape(img, SP(rrect_pts(47, 22, 57, 58, 3)), "#b49a72", seed + 8, outline=OUT, ow=1.0, wob=0.2, tex=0.25)
    # V windscreen in a chrome frame, pointing ahead
    line(img, [(S(95), S(22)), (S(100), S(40)), (S(95), S(58))], CHROME, 1.8 * SS, 240, blur=0.2)
    line(img, [(S(96.8), S(23)), (S(101.8), S(40)), (S(96.8), S(57))], "#9fc4dc", 1.5 * SS, 200, blur=0.3)
    # side-mounted spare wheels sitting in the front wings
    for sy in (14.5, 65.5):
        paint_shape(img, SP(ellipse_pts(116, sy, 7.5, 5.5)), TYRE, seed + 13 + sy, outline=OUT, ow=1, wob=0.1, tex=0.2)
        paint_shape(img, SP(ellipse_pts(116, sy, 4.6, 3.2)), "#ece6d6", seed + 15 + sy, outline=None, wob=0.05)
        paint_shape(img, SP(ellipse_pts(116, sy, 2.4, 1.8)), CHROME, seed + 17 + sy, outline=None, wob=0.05)
    # hood louvres and centre line
    for x in range(122, 152, 4):
        for y0 in (27, 48.5):
            line(img, [(S(x), S(y0)), (S(x + 2), S(y0 + 4.5))], shade(body, 0.55), 1.3 * SS, 220, blur=0.2)
    line(img, [(S(104), S(40)), (S(157), S(40))], CHROME, 1.3 * SS, 230, blur=0.2)
    radiator(img, seed + 20, x0=160, half=10)
    lamp(img, 158, 23, 5.4, seed + 21)
    lamp(img, 158, 57, 5.4, seed + 22)
    front_bumper(img, seed + 18, top=22.5, x=170)
    sheen(img, [(112, 31), (152, 32), (152, 34.5), (112, 34)], 70, 1.6)
    sheen(img, [(12, 33), (46, 30.5), (46, 33), (12, 36)], 45, 1.8)
    return finish(grain(img, 3, seed), CW, CH)


def lefty_speedster(seed=81):
    """M015: Lefty Moran's own car - a long-hooded black speedster with a closed cream roof, an ivory pinstripe,
    chrome exhaust pipes coming out of the hood sides, twin spotlights at the windscreen and a strapped trunk at
    the back: nothing else in the city looks like it. Nose right, front tyres left out (cars/wheel)."""
    body, fend, roof = "#17171b", "#232328", "#d8caa4"
    img = new(CW, CH)
    tyre_top(img, 22, 3.5, 46, 11, seed)
    tyre_top(img, 22, 69, 46, 76.5, seed + 1)
    for y0, y1 in ((11.5, 18), (62, 68.5)):  # running boards
        paint_shape(img, SP(rrect_pts(50, y0, 116, y1, 2)), "#2b2b30", seed + 2, outline=OUT, ow=1, wob=0.2, tex=0.25)
    body_pts = [(7, 33), (9, 27), (17, 22), (34, 18.5), (58, 16.5), (98, 17), (112, 19.5), (136, 23), (152, 26.5), (161, 30),
                (161, 50), (152, 53.5), (136, 57), (112, 60.5), (98, 63), (58, 63.5), (34, 61.5), (17, 58), (9, 53), (7, 47)]
    paint_shape(img, SP(body_pts), body, seed + 3, outline=OUT, ow=1.8, wob=0.3, tex=0.08, strokes_n=12,
                stroke_cols=[shade(body, 1.4), shade(body, 0.9)], light=(0.2, -1, 0.5), inner_shadow=0.3)
    front = [(100, 18.5), (108, 10.5), (122, 5.5), (140, 3.6), (154, 5.5), (164, 10), (171, 16.5), (172.5, 21.5),
             (167, 23), (156, 21.5), (140, 20), (118, 19.5)]
    rear = [(58, 17.5), (52, 10), (42, 5), (32, 3.6), (21, 5), (13, 9.5), (10, 15), (12, 19.5), (24, 20), (42, 19)]
    wings(img, fend, seed + 9, front, rear)
    # the ivory pinstripe along both sides of the body
    for y in (19.6, 60.4):
        line(img, [(S(20), S(y + (2 if y < 40 else -2))), (S(60), S(y)), (S(150), S(y + (6.8 if y < 40 else -6.8)))],
             "#e9dcb8", 0.9 * SS, 230, blur=0.1)
    # the strapped trunk on its rack at the back, the tail lamps either side
    paint_shape(img, SP(rrect_pts(2.5, 27, 12.5, 53, 2)), "#5a3a22", seed + 31, outline=OUT, ow=1.0, wob=0.15, tex=0.3,
                light=(0, -1, 0.4))
    for y in (32, 48):
        line(img, [(S(3), S(y)), (S(12), S(y))], CHROME_DARK, 1.2 * SS, 230)
    for y in (23.5, 56.5):
        paint_shape(img, SP(ellipse_pts(11, y, 2.8, 2.5)), "#b3221c", seed + 23, outline=OUT, ow=0.8, wob=0.1)
        soft_blob(img, S(10.6), S(y - 0.5), S(1.0), S(0.8), "#ffb0a0", 160, 0.4 * SS)
    # the closed cabin: a cream roof with a small back window, side windows dark
    paint_shape(img, SP(rrect_pts(52, 21.5, 92, 58.5, 7)), "#1e2a33", seed + 4, outline=OUT, ow=1.2, wob=0.15, tex=0.1)
    paint_shape(img, SP(rrect_pts(56, 24, 89, 56, 8)), roof, seed + 5, outline=OUT, ow=1.3, wob=0.2, tex=0.18,
                light=(0.2, -1, 0.6), inner_shadow=0.2)
    paint_shape(img, SP(rrect_pts(52.5, 32, 56.5, 48, 1.5)), "#3c5566", seed + 6, outline=None, wob=0.05)
    sheen(img, [(60, 27), (86, 27), (86, 29.5), (60, 29.5)], 70, 1.2)
    windscreen(img, 92, 99, 23.5, seed + 7, split=True)
    # twin spotlights on the windscreen posts
    for y in (22.5, 57.5):
        paint_shape(img, SP(ellipse_pts(97, y, 2.4, 2.1)), CHROME, seed + 40 + y, outline=OUT, ow=0.7, wob=0.05, light=(1, -1, 0.5))
    # three chrome exhaust pipes out of each side of the long hood, curving down into the wing
    for k in range(3):
        x = 124 + k * 7
        for top in (True, False):
            y0 = 25.5 if top else 54.5
            y1 = 19.0 if top else 61.0
            line(img, [(S(x), S(y0)), (S(x + 2.5), S((y0 + y1) / 2)), (S(x + 6), S(y1))], CHROME, 1.7 * SS, 250, blur=0.15)
            line(img, [(S(x + 0.6), S(y0)), (S(x + 3), S((y0 + y1) / 2))], "#ffffff", 0.6 * SS, 160, blur=0.2)
    line(img, [(S(100), S(40)), (S(157), S(40))], CHROME, 1.2 * SS, 230, blur=0.2)
    radiator(img, seed + 20, x0=160, half=10)
    lamp(img, 158, 23, 5.4, seed + 21)
    lamp(img, 158, 57, 5.4, seed + 22)
    front_bumper(img, seed + 18, top=22.5, x=170)
    sheen(img, [(108, 30.5), (152, 32), (152, 34), (108, 33)], 60, 1.6)
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


def police_car(seed=7):
    """The Chicago squad car: a black sedan with POLICE on the roof, a siren and a spotlight."""
    img = sedan("#16181c", roof="#1c1f24", seed=seed)
    big = img.resize((CW * SS, CH * SS), Image.LANCZOS)
    # white band and lettering across the roof (reads from above)
    paint_shape(big, SP(rrect_pts(60, 26, 99, 54, 3)), "#e8e4d8", seed + 1, outline=OUT, ow=1.0, wob=0.15, tex=0.1)
    layer = new(CW, CH)
    text(layer, (79.5, 40), "POLICE", 7.2, "#16181c", font="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf")
    big.alpha_composite(layer.rotate(0))
    # siren on the left front fender, spotlight on the windscreen pillar
    paint_shape(big, SP(ellipse_pts(150, 13, 4.5, 4.5)), "#c9ccce", seed + 2, outline=OUT, ow=0.9, wob=0.05, light=(0.4, -1, 0.5))
    paint_shape(big, SP(ellipse_pts(151, 13, 2.6, 2.6)), "#c02a22", seed + 3, outline=None, wob=0.05)
    paint_shape(big, SP(ellipse_pts(106, 22, 3.4, 2.6)), "#d6d9db", seed + 4, outline=OUT, ow=0.8, wob=0.05, light=(1, -1, 0.5))
    # a gold star on each front door
    for y in (17, 63):
        star = [(80 + math.cos(-math.pi / 2 + k * math.pi / 5) * (2.6 if k % 2 == 0 else 1.1),
                 y + math.sin(-math.pi / 2 + k * math.pi / 5) * (2.6 if k % 2 == 0 else 1.1)) for k in range(10)]
        paint_shape(big, SP(star), "#e2c068", seed + y, outline=None, wob=0.02)
    return finish(big, CW, CH)


# ---------------------------------------------------------------- M009: the heavy ones

def _wings_at(img, color, seed, pts, h):
    """A pair of front wings (top outline given, mirrored about the middle of an image h high)."""
    for k, ps in enumerate((pts, [(x, h - y) for x, y in reversed(pts)])):
        paint_shape(img, SP(ps), color, seed + k, outline=OUT, ow=1.6, wob=0.25, tex=0.18, light=(0.3, -1, 0.5))


def dump_truck(cab="#2f3d2c", bed="#6b2a20", seed=61):
    """M009: Brennan Coal & Ice's 1930s dump truck from above, nose right: a long
    bonnet between teardrop wings and a flat upright grille, a short cab with a
    bright windscreen, and behind it the steel dump bed heaped with coal, its
    headboard over the cab; big dual rear tyres under the bed. 280 x 110."""
    W, H = 280, 110
    img = new(W, H)
    soft_blob(img, S(140), S(57), S(132), S(50), "#000000", 60, 6 * SS)
    # dual rear tyres (one wide tread each side) and the chassis rails
    tyre_top(img, 44, 2.5, 88, 14, seed)
    tyre_top(img, 44, 96, 88, 107.5, seed + 1)
    for y0, y1 in ((38, 45), (65, 72)):
        paint_shape(img, SP(rrect_pts(8, y0, 252, y1, 1.5)), "#1c1c1d", seed + 2, outline=OUT, ow=0.8, wob=0.1, tex=0.2)
    # running boards under the cab
    for y0, y1 in ((11, 19), (91, 99)):
        paint_shape(img, SP(rrect_pts(168, y0, 214, y1, 2)), "#1b1b1c", seed + 3, outline=OUT, ow=1, wob=0.2, tex=0.3)
    # the bed: a steel box, ribbed sides, the tailgate at the back, coal heaped in it
    paint_shape(img, SP(rrect_pts(5, 9, 168, 101, 4)), bed, seed + 4, outline=OUT, ow=1.8, wob=0.2, tex=0.22,
                strokes_n=10, stroke_cols=[shade(bed, 1.1), shade(bed, 0.9)], light=(0.2, -1, 0.45))
    paint_shape(img, SP(rrect_pts(12, 16, 161, 94, 3)), "#24211f", seed + 5, outline=(40, 30, 26), ow=1.0, wob=0.2, tex=0.35)
    rnd = __import__("random").Random(seed)
    soft_blob(img, S(86), S(55), S(70), S(26), "#3a3836", 150, 6 * SS)  # the heap's crown, a little lighter
    for k in range(380):  # the coal: lumps catching a little light, heaped along the middle
        x = rnd.uniform(16, 157)
        y = 55 + rnd.gauss(0, 15)
        if 19 < y < 91:
            r = rnd.uniform(1.8, 4.2)
            c = rnd.choice(["#141414", "#1d1d1f", "#262628", "#303034"])
            paint_shape(img, SP(ellipse_pts(x, y, r, r * rnd.uniform(0.7, 1.0), n=12, rot=rnd.uniform(0, 3))), c, seed + 10 + k,
                        outline=None, wob=0.4, tex=0.3, light=(0.4, -1, 0.6))
            if rnd.random() < 0.35:
                soft_blob(img, S(x - r * 0.3), S(y - r * 0.4), S(r * 0.4), S(r * 0.25), "#8a8f99", 120, 0.3 * SS)
    d = ImageDraw.Draw(img)
    for x in range(22, 160, 23):  # stiffening ribs on the bed's sides
        for y0, y1 in ((9.5, 15.5), (94.5, 100.5)):
            d.line([(S(x), S(y0)), (S(x), S(y1))], fill=rgba(shade(bed, 0.6)), width=int(1.6 * SS))
    paint_shape(img, SP(rrect_pts(3, 12, 9, 98, 2)), shade(bed, 0.8), seed + 6, outline=OUT, ow=1.2, wob=0.1, tex=0.2)
    for y in (24, 86):  # tailgate hinges
        paint_shape(img, SP(rrect_pts(2, y - 3, 6, y + 3, 1)), CHROME_DARK, seed + 7 + y, outline=OUT, ow=0.6, wob=0.05)
    # the headboard over the cab
    paint_shape(img, SP(rrect_pts(160, 8, 174, 102, 3)), shade(bed, 0.85), seed + 8, outline=OUT, ow=1.4, wob=0.15, tex=0.2,
                light=(0.2, -1, 0.5))
    # red tail lamps on the back corners
    for y in (12, 98):
        paint_shape(img, SP(ellipse_pts(8, y, 3.6, 3.2)), "#b3221c", seed + 9, outline=OUT, ow=0.8, wob=0.1)
        soft_blob(img, S(7.6), S(y - 0.6), S(1.4), S(1.1), "#ffb0a0", 160, 0.4 * SS)
    # the bonnet, narrowing to the grille, louvres down both sides, the hinge strip along the middle
    hood = [(210, 26), (238, 28), (262, 32), (262, 78), (238, 82), (210, 84)]
    paint_shape(img, SP(hood), cab, seed + 20, outline=OUT, ow=1.6, wob=0.25, tex=0.14, strokes_n=8,
                stroke_cols=[shade(cab, 1.1), shade(cab, 0.92)], light=(0.2, -1, 0.45), inner_shadow=0.3)
    for x in range(218, 256, 4):
        for y0 in (32, 70):
            line(img, [(S(x), S(y0)), (S(x + 2), S(y0 + 6))], "#0c100e", 1.3 * SS, 220, blur=0.2)
    line(img, [(S(212), S(55)), (S(260), S(55))], CHROME, 1.3 * SS, 230, blur=0.2)
    # the front wings over the front wheels (the tyres are cars/wheel, turned by the steering)
    _wings_at(img, shade(cab, 0.88), seed + 22, [(212, 24), (220, 13), (234, 6), (250, 4.5), (263, 7.5), (271, 14), (274, 22),
                                                 (266, 25.5), (250, 24.5), (230, 24)], H)
    # the cab: roof, a bright windscreen at its front, the small rear window behind
    paint_shape(img, SP(rrect_pts(172, 16, 208, 94, 6)), shade(cab, 1.12), seed + 24, outline=OUT, ow=1.6, wob=0.2, tex=0.1,
                light=(0.1, -1, 0.5), inner_shadow=0.25)
    paint_shape(img, SP([(206, 19), (214, 23), (214, 87), (206, 91)]), "#6f97b2", seed + 25, outline=OUT, ow=1.2, wob=0.1,
                light=(1, -1, 0.6))
    line(img, [(S(208), S(24)), (S(212), S(34))], "#e6f2fa", 1.3 * SS, 190, blur=0.4)
    text(img, (190, 55), "BRENNAN", 6.2, "#e8dcb0", font=DECO)
    # the grille: flat and upright, bright chrome round dark slats; the bumper ahead of it; headlamps on the wings
    paint_shape(img, SP(rrect_pts(261, 33, 271, 77, 2)), CHROME, seed + 26, outline=OUT, ow=1.1, wob=0.08, light=(1, -1, 0.45))
    for y in range(37, 75, 3):
        d.line([(S(263), S(y)), (S(269), S(y))], fill=rgba("#2e3234"), width=SS)
    paint_shape(img, SP(rrect_pts(272, 22, 278, 88, 2.5)), CHROME, seed + 27, outline=OUT, ow=1.0, wob=0.05, light=(1, -1, 0.4))
    lamp(img, 260, 21, 5.6, seed + 28)
    lamp(img, 260, 89, 5.6, seed + 29)
    sheen(img, [(216, 38), (256, 39), (256, 41.5), (216, 41)], 50, 1.6)
    return finish(grain(img, 3, seed), W, H)


def school_bus(body="#e3a12c", seed=71):
    """M009: St. Brendan's parish school bus, early 1930s, from above, nose right:
    a long boxy body in school-bus chrome yellow with black rub rails, the
    window row along both sides, SCHOOL BUS in black on the roof, the
    emergency door at the back; a short bonnet between teardrop wings, a
    chrome radiator and headlamps at the front. 340 x 102."""
    W, H = 340, 102
    img = new(W, H)
    soft_blob(img, S(170), S(53), S(166), S(47), "#000000", 60, 6 * SS)
    tyre_top(img, 58, 3.5, 100, 12, seed)
    tyre_top(img, 58, 90, 100, 98.5, seed + 1)
    # the body: one long box, rounded at the corners
    paint_shape(img, SP(rrect_pts(4, 6, 294, 96, 10)), body, seed + 2, outline=OUT, ow=1.8, wob=0.25, tex=0.12, strokes_n=12,
                stroke_cols=[shade(body, 1.06), shade(body, 0.93)], light=(0.2, -1, 0.4), inner_shadow=0.3)
    # the window row down each side, cream frames between dark glass
    for y0, y1 in ((8.5, 15.5), (86.5, 93.5)):
        paint_shape(img, SP(rrect_pts(30, y0, 286, y1, 1.5)), "#e9dfc2", seed + 3, outline=OUT, ow=0.8, wob=0.05, tex=0.05)
        for x in range(33, 280, 21):
            paint_shape(img, SP(rrect_pts(x, y0 + 1.2, x + 17, y1 - 1.2, 1)), "#34495c", seed + 4 + x, outline=None, wob=0.05,
                        tex=0.1, light=(1, -1, 0.5))
    # the roof: lighter, ribbed, with SCHOOL BUS across it
    roof = shade(body, 1.1)
    paint_shape(img, SP(rrect_pts(12, 17, 284, 85, 8)), roof, seed + 5, outline=(70, 50, 20), ow=1.0, wob=0.15, tex=0.1,
                light=(0.1, -1, 0.5))
    d = ImageDraw.Draw(img)
    for x in range(30, 282, 22):
        d.line([(S(x), S(18.5)), (S(x), S(83.5))], fill=rgba(shade(body, 0.85), 150), width=SS)
    text(img, (150, 47), "SCHOOL BUS", 17, "#151515", font="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf")
    text(img, (150, 66), "ST. BRENDAN'S PARISH", 7.5, "#2a2014", font=DECO)
    for x in (48, 252):  # roof vents
        paint_shape(img, SP(rrect_pts(x - 5, 46, x + 5, 56, 2)), shade(body, 0.8), seed + 6 + x, outline=OUT, ow=0.8, wob=0.05)
    # black rub rails along both sides
    for y in (6.8, 95.2):
        line(img, [(S(10), S(y)), (S(290), S(y))], "#141414", 1.8 * SS, 235)
    # the back: the emergency door, tail lamps on the corners
    paint_shape(img, SP(rrect_pts(3, 30, 11, 72, 2)), shade(body, 0.82), seed + 7, outline=OUT, ow=1.2, wob=0.08)
    line(img, [(S(7), S(32)), (S(7), S(70))], "#2a2014", 1.0 * SS, 200)
    for y in (13, 89):
        paint_shape(img, SP(ellipse_pts(7.5, y, 3.6, 3.2)), "#b3221c", seed + 8, outline=OUT, ow=0.8, wob=0.1)
        soft_blob(img, S(7.1), S(y - 0.6), S(1.4), S(1.1), "#ffb0a0", 160, 0.4 * SS)
    # the front: windscreen across the front of the body, a short bonnet, wings, radiator, bumper, lamps
    paint_shape(img, SP([(286, 14), (295, 18), (295, 84), (286, 88)]), "#6f97b2", seed + 9, outline=OUT, ow=1.2, wob=0.1,
                light=(1, -1, 0.6))
    line(img, [(S(288), S(20)), (S(293), S(32))], "#e6f2fa", 1.3 * SS, 190, blur=0.4)
    hood = [(293, 26), (312, 28), (328, 32), (328, 70), (312, 74), (293, 76)]
    paint_shape(img, SP(hood), body, seed + 10, outline=OUT, ow=1.6, wob=0.2, tex=0.12, light=(0.2, -1, 0.45), inner_shadow=0.3)
    for x in range(298, 324, 4):
        for y0 in (30, 64):
            line(img, [(S(x), S(y0)), (S(x + 2), S(y0 + 5))], "#4a3410", 1.2 * SS, 220, blur=0.2)
    _wings_at(img, "#1c1c1e", seed + 12, [(292, 22), (299, 12), (311, 5.5), (324, 4), (333, 7), (339, 13), (340, 20),
                                          (333, 23.5), (318, 23), (300, 23)], H)
    radiator(img, seed + 14, x0=326, half=13)
    paint_shape(img, SP(rrect_pts(336.5, 20, 339.5, 82, 1.5)), CHROME, seed + 15, outline=OUT, ow=1.0, wob=0.05, light=(1, -1, 0.4))
    lamp(img, 327, 18.5, 5.2, seed + 16)
    lamp(img, 327, 83.5, 5.2, seed + 17)
    sheen(img, [(40, 24), (270, 24), (270, 29), (40, 29)], 40, 2.2)
    return finish(grain(img, 3, seed), W, H)


# ---------------------------------------------------------------- M015: traffic variety

def taxi(seed=11):
    """M015: a city cab - the sedan in cab yellow with a black roof, a band of
    black-and-white checks along each side, the roof lamp with TAXI on it."""
    img = sedan("#d6a52a", roof="#24221f", seed=seed)
    big = img.resize((CW * SS, CH * SS), Image.LANCZOS)
    for y0 in (14.6, 62.6):  # the checks along the belt line
        for k, x in enumerate(range(56, 100, 3)):
            col = "#141414" if k % 2 == 0 else "#efe9da"
            paint_shape(big, SP(rrect_pts(x, y0, x + 3, y0 + 2.8, 0.2)), col, seed + k, outline=None, wob=0.02, tex=0.05)
    paint_shape(big, SP(rrect_pts(70, 34, 86, 46, 2)), "#f2e8c8", seed + 3, outline=OUT, ow=0.9, wob=0.05, light=(0.4, -1, 0.6))
    layer = new(CW, CH)
    text(layer, (78, 40), "TAXI", 5.0, "#1a1a1a", font="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf")
    big.alpha_composite(layer)
    soft_blob(big, S(78), S(40), S(9), S(5), "#fff4c0", 60, 2 * SS)
    return finish(big, CW, CH)


VW, VH = 196, 84


def bakery_van(body="#2f4a3a", seed=13, plain=False):
    """M015: Kowalski's Bakery's panel van, early 1930s, from above, nose right:
    a tall square-backed body with KOWALSKI'S BAKERY on the roof in cream, a
    short cab with a bright windscreen, a louvred bonnet between teardrop
    wings, a chrome radiator and lamps; front tyres left out (cars/wheel)."""
    W, H = VW, VH
    img = new(W, H)
    soft_blob(img, S(98), S(43), S(92), S(37), "#000000", 60, 5 * SS)
    tyre_top(img, 26, 3.5, 52, 12, seed)
    tyre_top(img, 26, H - 12, 52, H - 3.5, seed + 1)
    for y0, y1 in ((11, 17), (H - 17, H - 11)):  # running boards
        paint_shape(img, SP(rrect_pts(120, y0, 150, y1, 2)), "#1b1b1c", seed + 2, outline=OUT, ow=1, wob=0.2, tex=0.3)
    # the box body: tall, square at the back, the roof with its lettering
    paint_shape(img, SP(rrect_pts(4, 11, 132, 73, 6)), body, seed + 3, outline=OUT, ow=1.8, wob=0.2, tex=0.12, strokes_n=10,
                stroke_cols=[shade(body, 1.08), shade(body, 0.92)], light=(0.2, -1, 0.42), inner_shadow=0.3)
    paint_shape(img, SP(rrect_pts(10, 17, 126, 67, 4)), shade(body, 1.12), seed + 4, outline=(30, 40, 34), ow=1.0, wob=0.15,
                tex=0.1, light=(0.1, -1, 0.5))
    if not plain:
        text(img, (68, 36), "KOWALSKI'S", 8.2, "#efe2b8", font=DECO)
        text(img, (68, 48), "BAKERY", 7.0, "#d9b25c", font=DECO)
    else:  # an unmarked van: a roof rack and a tarpaulin
        paint_shape(img, SP(rrect_pts(30, 26, 104, 58, 3)), "#5a5444", seed + 40, outline=OUT, ow=0.9, wob=0.3, tex=0.35,
                    light=(0.2, -1, 0.5))
        for x in range(34, 104, 10):
            line(img, [(S(x), S(26)), (S(x + 2), S(58))], "#3e3a30", 1.0 * SS, 180, blur=0.3)
    line(img, [(S(5), S(42)), (S(10), S(42))], shade(body, 0.6), 1.2 * SS, 220)  # the back doors
    for y in (15, H - 15):
        paint_shape(img, SP(ellipse_pts(9, y, 3.2, 2.8)), "#b3221c", seed + 5, outline=OUT, ow=0.8, wob=0.1)
        soft_blob(img, S(8.6), S(y - 0.5), S(1.2), S(1.0), "#ffb0a0", 160, 0.4 * SS)
    # the cab: its roof, the windscreen, the bonnet and wings, the radiator, lamps and bumper
    paint_shape(img, SP(rrect_pts(126, 18, 148, 66, 5)), shade(body, 1.15), seed + 6, outline=OUT, ow=1.5, wob=0.2, tex=0.1,
                light=(0.1, -1, 0.5), inner_shadow=0.25)
    paint_shape(img, SP([(146, 20), (154, 23), (154, 61), (146, 64)]), "#6f97b2", seed + 7, outline=OUT, ow=1.2, wob=0.1,
                light=(1, -1, 0.6))
    line(img, [(S(148), S(24)), (S(152.5), S(33))], "#e6f2fa", 1.3 * SS, 190, blur=0.4)
    hood = [(154, 25), (172, 27), (184, 31), (184, 53), (172, 57), (154, 59)]
    paint_shape(img, SP(hood), body, seed + 8, outline=OUT, ow=1.5, wob=0.2, tex=0.12, light=(0.2, -1, 0.45), inner_shadow=0.3)
    for x in range(158, 180, 4):
        for y0 in (29, 50):
            line(img, [(S(x), S(y0)), (S(x + 2), S(y0 + 4.5))], "#0c100e", 1.2 * SS, 220, blur=0.2)
    line(img, [(S(156), S(42)), (S(183), S(42))], CHROME, 1.2 * SS, 230, blur=0.2)
    _wings_at(img, shade(body, 0.85), seed + 9, [(150, 20), (156, 11), (168, 5), (180, 4), (189, 7), (193, 13), (194, 19),
                                                 (186, 21.5), (172, 21), (158, 20.5)], H)
    paint_shape(img, SP(rrect_pts(183, 30, 190, 54, 1.5)), CHROME, seed + 10, outline=OUT, ow=1.0, wob=0.06, light=(1, -1, 0.45))
    d = ImageDraw.Draw(img)
    for y in range(33, 53, 2):
        d.line([(S(184.5), S(y)), (S(188.5), S(y))], fill=rgba("#2e3234"), width=SS)
    paint_shape(img, SP(rrect_pts(191, 18, 195, 66, 1.8)), CHROME, seed + 11, outline=OUT, ow=0.9, wob=0.05, light=(1, -1, 0.4))
    lamp(img, 186, 17, 4.4, seed + 12)
    lamp(img, 186, H - 17, 4.4, seed + 13)
    sheen(img, [(18, 22), (118, 22), (118, 26), (18, 26)], 40, 2.0)
    return finish(grain(img, 3, seed), W, H)


ASSETS = {
    "cars/taxi": lambda: taxi(11),  # M015
    "cars/bakery_van": lambda: bakery_van("#2f4a3a", 13),  # M015
    "cars/van_plain": lambda: bakery_van("#4a3626", 14, plain=True),
    "cars/dump_truck": dump_truck,
    "cars/school_bus": school_bus,
    "cars/police": lambda: police_car(7),
    "cars/wheel": lambda: wheel(9),
    "cars/sedan": lambda: sedan("#1d2b25", seed=1),
    "cars/sedan_b": lambda: sedan("#4a1b1e", roof="#2a1213", seed=2),
    "cars/coupe": lambda: coupe("#e3d4ac", "#6a1d22", "#7b2420", seed=5),
    "cars/coupe_b": lambda: coupe("#2e4a3a", "#1c1c1e", "#a0794a", seed=6),
    "cars/lefty": lambda: lefty_speedster(81),  # M015
}
