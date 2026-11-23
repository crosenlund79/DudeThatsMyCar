"""The emergency's vehicles, from above, nose right like the cars. They are never
driven by the player (scenery that drives itself to the scene), so every tyre
is painted in. M015: redrawn as period vehicles with the anatomy of the other
cars - separate sweeping wings over the wheels, running boards, a narrow
louvred bonnet and an upright chrome grille - instead of capsule bodies.

cars/ambulance   - a long 1930s coach-built ambulance on a car chassis: a cream
                   body with black wings and running boards, the long roof with
                   AMBULANCE along it, a red lamp and a chrome siren at its front,
                   frosted side windows, a bright windscreen, a narrow louvred
                   bonnet and a tall V grille, the rear doors at the back. 210 x 84.
cars/fire_engine - a 1930s open-cab pumper in fire-engine red with gold
                   striping: long louvred bonnet between big wings, a chrome
                   grille and bumper, the brass bell on the cowl, a siren on a
                   wing, the open cab's leather bench and wheel, the pump's
                   chrome caps behind it, the hose bed of folded canvas, ladders
                   racked along both sides, black suction hose on the running
                   boards, the rear step. 300 x 104."""
from PIL import ImageDraw

from paintkit import *
from paint_props import DECO
from paint_vehicles import lamp, tyre_top, sheen, CHROME, CHROME_DARK

OUT = (20, 16, 14)
GLASS = "#6f97b2"


def _pair(img, pts, h, color, seed, **kw):
    """A shape on the top side and its mirror on the bottom (about the middle of an image h high)."""
    for k, ps in enumerate((pts, [(x, h - y) for x, y in reversed(pts)])):
        paint_shape(img, SP(ps), color, seed + k, **kw)


def _wing(x0, x1, y_out, y_in, nose=0.35):
    """A teardrop wing over a wheel, outer edge at y_out, inner edge at y_in (top side); `nose` how far forward the bulge sits."""
    import math
    pts = []
    n = 24
    for i in range(n + 1):
        t = i / n
        x = x0 + (x1 - x0) * t
        bulge = math.sin(math.pi * t) ** (0.7 if t < nose else 0.9)
        pts.append((x, y_in - (y_in - y_out) * bulge))
    pts.append((x1 - (x1 - x0) * 0.08, y_in + 1.0))
    pts.append((x0 + (x1 - x0) * 0.08, y_in + 1.0))
    return pts


def _grille(img, d, x0, x1, y0, y1, seed, slat="#2e3234"):
    """A tall upright chrome grille, slightly V-fronted, with dark horizontal slats."""
    mid = (y0 + y1) * 0.5
    paint_shape(img, SP([(x0, y0), (x1 - 2, y0 + 1.5), (x1, mid), (x1 - 2, y1 - 1.5), (x0, y1)]), CHROME, seed, outline=OUT,
                ow=1.1, wob=0.06, light=(1, -1, 0.45))
    for y in range(int(y0 + 3), int(y1 - 2), 2):
        d.line([(S(x0 + 1.5), S(y)), (S(x1 - 2.5), S(y))], fill=rgba(slat), width=SS)


def ambulance(seed=81):
    W, H = 210, 84
    img = new(W, H)
    d = ImageDraw.Draw(img)
    soft_blob(img, S(104), S(44), S(100), S(38), "#000000", 70, 5 * SS)
    black = "#1c1b1c"
    body = "#e6dec6"
    # every tyre painted in, under the wings
    for x in (36, 150):
        tyre_top(img, x, 2.5, x + 24, 12.5, seed + x)
        tyre_top(img, x, H - 12.5, x + 24, H - 2.5, seed + x + 1)
    # the running boards between the wings
    _pair(img, rrect_pts(62, 9, 152, 15.5, 2), H, black, seed + 2, outline=OUT, ow=1.0, wob=0.15, tex=0.3)
    for x in range(66, 150, 6):  # rubber treads on the boards
        for y in (12.2, H - 12.2):
            line(img, [(S(x), S(y)), (S(x + 3), S(y))], "#3a393a", 0.9 * SS, 200, blur=0.1)
    # the rear and front wings (black), the front ones sweeping forward to the lamps
    _pair(img, _wing(22, 74, 2.0, 17.5, 0.5), H, black, seed + 4, outline=OUT, ow=1.5, wob=0.2, tex=0.18, light=(0.3, -1, 0.5))
    _pair(img, _wing(132, 200, 1.5, 20.0, 0.62), H, black, seed + 6, outline=OUT, ow=1.5, wob=0.2, tex=0.18, light=(0.3, -1, 0.5))
    for y in (8.0, H - 8.0):
        sheen(img, [(146, y - 1.5), (190, y - 0.8), (190, y + 0.4), (146, y - 0.2)], 50, 0.8)
    # the coach body: long and square-backed, the roof inset with a seam, a red stripe along each side
    paint_shape(img, SP(rrect_pts(5, 14, 146, 70, 7)), body, seed + 8, outline=OUT, ow=1.8, wob=0.2, tex=0.1, strokes_n=12,
                stroke_cols=[shade(body, 1.04), shade(body, 0.93)], light=(0.2, -1, 0.4), inner_shadow=0.3)
    for y in (17.5, H - 17.5):
        line(img, [(S(9), S(y)), (S(140), S(y))], "#9c2a22", 1.3 * SS, 230, blur=0.2)
    # frosted side windows along the coach (seen edge-on from above as pale strips)
    for x0, x1 in ((62, 92), (96, 126)):
        for y0, y1 in ((14.5, 16.2), (H - 16.2, H - 14.5)):
            paint_shape(img, SP(rrect_pts(x0, y0, x1, y1, 0.8)), "#c9d6dc", seed + x0, outline=None, wob=0.05, tex=0.05)
    paint_shape(img, SP(rrect_pts(12, 21, 126, 63, 5)), "#ece6d2", seed + 9, outline=(110, 100, 84), ow=1.0, wob=0.15, tex=0.08,
                light=(0.1, -1, 0.5))
    text(img, (66, 42), "AMBULANCE", 9.0, "#8a1e1a", font=DECO)
    for x in (20, 112):  # roof ventilators
        paint_shape(img, SP(rrect_pts(x - 3, 38, x + 3, 46, 1.2)), "#bdb6a2", seed + x, outline=OUT, ow=0.7, wob=0.05)
    # the red lamp and the chrome siren at the front of the roof
    paint_shape(img, SP(ellipse_pts(132, 42, 4.6, 4.6)), "#c42820", seed + 10, outline=OUT, ow=0.9, wob=0.05, light=(0.4, -1, 0.6))
    soft_blob(img, S(131), S(41), S(1.9), S(1.7), "#ffc0b0", 220, 0.5 * SS)
    paint_shape(img, SP(rrect_pts(124, 33, 131, 37.5, 1.8)), CHROME, seed + 11, outline=OUT, ow=0.7, wob=0.05, light=(1, -1, 0.5))
    # the windscreen at the front of the coach (the brightest glass), the cowl ahead of it
    paint_shape(img, SP([(140, 17), (148, 20), (148, 64), (140, 67)]), GLASS, seed + 12, outline=OUT, ow=1.2, wob=0.1, tex=0.08,
                light=(1, -1, 0.6))
    line(img, [(S(142), S(21)), (S(146.5), S(30))], "#e6f2fa", 1.3 * SS, 190, blur=0.4)
    line(img, [(S(140.5), S(42)), (S(147.5), S(42))], CHROME_DARK, 1.0 * SS, 230)
    # the bonnet: narrow, cream, louvred, a chrome strip down the middle, narrowing to the grille
    hood = [(148, 24), (176, 26), (192, 30), (192, 54), (176, 58), (148, 60)]
    paint_shape(img, SP(hood), body, seed + 13, outline=OUT, ow=1.5, wob=0.2, tex=0.1, light=(0.2, -1, 0.45), inner_shadow=0.3)
    for x in range(154, 186, 4):
        for y0 in (28, 50):
            line(img, [(S(x), S(y0)), (S(x + 2), S(y0 + 5))], "#857a62", 1.2 * SS, 210, blur=0.2)
    line(img, [(S(150), S(42)), (S(191), S(42))], CHROME, 1.3 * SS, 230, blur=0.2)
    sheen(img, [(156, 33), (188, 34), (188, 36), (156, 35)], 55, 1.2)
    # the tall V grille, the bumper bowed forward, the headlamps on the wings, a spotlight by the screen
    _grille(img, d, 191, 199, 28, 56, seed + 14)
    paint_shape(img, SP([(199, 17), (203, 28), (205, 42), (203, 56), (199, 67), (196.5, 67), (200, 56), (202, 42), (200, 28),
                         (196.5, 17)]), CHROME, seed + 15, outline=OUT, ow=1.0, wob=0.05, light=(1, -1, 0.4))
    lamp(img, 192, 11.5, 4.6, seed + 16)
    lamp(img, 192, H - 11.5, 4.6, seed + 17)
    lamp(img, 146, 15.5, 2.4, seed + 18)
    # the back: the double doors' seam and handles, the red tail lamps on the rear wings
    line(img, [(S(5.5), S(42)), (S(14), S(42))], "#7a7262", 1.2 * SS, 220)
    for y in (38.5, 45.5):
        paint_shape(img, SP(rrect_pts(6, y - 1, 9.5, y + 1, 0.5)), CHROME, seed + 19, outline=None, wob=0.02)
    for y in (12, H - 12):
        paint_shape(img, SP(ellipse_pts(24, y, 3.0, 2.6)), "#b3221c", seed + 20, outline=OUT, ow=0.8, wob=0.1)
        soft_blob(img, S(23.6), S(y - 0.5), S(1.2), S(1.0), "#ffb0a0", 160, 0.4 * SS)
    sheen(img, [(30, 23), (122, 23), (122, 27), (30, 27)], 40, 2.0)
    return finish(grain(img, 3, seed), W, H)


def fire_engine(seed=91):
    W, H = 300, 104
    img = new(W, H)
    d = ImageDraw.Draw(img)
    soft_blob(img, S(150), S(54), S(144), S(46), "#000000", 70, 6 * SS)
    red = "#b3241a"
    gold = "#d6b25e"
    # every tyre painted in: big dual rears, the fronts under the wings
    for x0, x1 in ((44, 86), (222, 248)):
        tyre_top(img, x0, 2.0, x1, 13, seed + x0)
        tyre_top(img, x0, H - 13, x1, H - 2.0, seed + x0 + 1)
    # running boards with diamond plate, the black suction hose racked along them
    _pair(img, rrect_pts(88, 8, 222, 15, 2), H, "#8a8d90", seed + 2, outline=OUT, ow=1.0, wob=0.12, tex=0.35)
    for x in range(92, 220, 5):
        for y in (11.5, H - 11.5):
            line(img, [(S(x), S(y - 1.6)), (S(x + 2), S(y + 1.6))], "#5d6064", 0.8 * SS, 200, blur=0.1)
    for y in (6.5, H - 6.5):
        paint_shape(img, SP(rrect_pts(96, y - 3.2, 196, y + 3.2, 3.0)), "#191919", seed + 3, outline=OUT, ow=0.9, wob=0.1, tex=0.3)
        for x in range(99, 194, 3):  # its corrugations
            line(img, [(S(x), S(y - 2.6)), (S(x), S(y + 2.6))], "#353535", 0.9 * SS, 200, blur=0.1)
    # the rear wings and the big front wings, red with a gold pinstripe
    _pair(img, _wing(36, 94, 1.5, 19, 0.5), H, red, seed + 4, outline=OUT, ow=1.6, wob=0.2, tex=0.16, light=(0.3, -1, 0.5))
    _pair(img, _wing(200, 280, 1.0, 24, 0.62), H, red, seed + 6, outline=OUT, ow=1.6, wob=0.2, tex=0.16, light=(0.3, -1, 0.5))
    for y in (9.0, H - 9.0):
        line(img, [(S(214), S(y + (2 if y < 50 else -2))), (S(266), S(y))], gold, 0.9 * SS, 200, blur=0.2)
        sheen(img, [(214, y - 1.5), (266, y - 1.2), (266, y), (214, y - 0.2)], 45, 0.8)
    # the body behind the cab: red, square, gold striping round its edge
    paint_shape(img, SP(rrect_pts(6, 15, 178, 89, 5)), red, seed + 8, outline=OUT, ow=1.9, wob=0.2, tex=0.15, strokes_n=14,
                stroke_cols=[shade(red, 1.08), shade(red, 0.9)], light=(0.2, -1, 0.45), inner_shadow=0.3)
    for y in (18.5, H - 18.5):
        line(img, [(S(10), S(y)), (S(174), S(y))], gold, 0.9 * SS, 210, blur=0.2)
    # the hose bed: folded canvas hose, lying in long flakes along the body
    paint_shape(img, SP(rrect_pts(14, 30, 150, 74, 3)), "#3a1410", seed + 9, outline=OUT, ow=1.0, wob=0.1, tex=0.3)
    for k, y in enumerate(range(32, 74, 4)):
        flake = "#c4a874" if k % 2 == 0 else "#b39660"
        paint_shape(img, SP(rrect_pts(16 + (k % 3), y, 148 - (k % 2) * 2, y + 3.4, 1.6)), flake, seed + 30 + k, outline=(90, 70, 40),
                    ow=0.6, wob=0.2, tex=0.25, light=(0.2, -1, 0.5))
    for x in (40, 96):  # the brass couplings at the hose's folds
        paint_shape(img, SP(ellipse_pts(x, 52, 2.6, 2.6)), gold, seed + x, outline=OUT, ow=0.6, wob=0.02, light=(0.4, -1, 0.7))
    # ladders racked along both sides: two wooden rails and the rungs
    for yc in (24.0, H - 24.0):
        for yr in (yc - 3.4, yc + 3.4):
            paint_shape(img, SP(rrect_pts(8, yr - 1.4, 170, yr + 1.4, 0.8)), "#c79e5c", seed + int(yr), outline=OUT, ow=0.7, wob=0.08,
                        tex=0.25, light=(0.2, -1, 0.5))
        for x in range(13, 168, 7):
            line(img, [(S(x), S(yc - 2.2)), (S(x), S(yc + 2.2))], "#9a7440", 1.2 * SS, 240, blur=0.1)
    # the pump behind the seat: its housing and chrome caps
    paint_shape(img, SP(rrect_pts(152, 32, 178, 72, 3)), shade(red, 0.86), seed + 10, outline=OUT, ow=1.2, wob=0.1, tex=0.15)
    for y in (40, 52, 64):
        paint_shape(img, SP(ellipse_pts(165, y, 4.0, 4.0)), CHROME, seed + y, outline=OUT, ow=0.8, wob=0.03, light=(1, -1, 0.6))
        soft_blob(img, S(164), S(y - 1), S(1.4), S(1.2), "#ffffff", 200, 0.3 * SS)
    # the open cab: the black leather bench with its tufting, the steering wheel, the cowl and windscreen
    paint_shape(img, SP(rrect_pts(178, 17, 214, 87, 5)), red, seed + 11, outline=OUT, ow=1.6, wob=0.15, tex=0.14, light=(0.2, -1, 0.45))
    paint_shape(img, SP(rrect_pts(182, 21, 200, 83, 3)), "#1e1a18", seed + 12, outline=OUT, ow=1.0, wob=0.12, tex=0.3)
    for y in range(26, 80, 8):
        line(img, [(S(184), S(y)), (S(198), S(y))], "#3a322c", 1.0 * SS, 220, blur=0.2)
    d.ellipse([S(200), S(26), S(212), S(38)], outline=rgba("#1a1614"), width=int(1.6 * SS))  # the wheel, driver's side
    line(img, [(S(206), S(32)), (S(212), S(32))], "#1a1614", 1.2 * SS, 255, blur=0.1)
    paint_shape(img, SP([(212, 19), (220, 22), (220, 82), (212, 85)]), GLASS, seed + 13, outline=OUT, ow=1.2, wob=0.1, tex=0.08,
                light=(1, -1, 0.6))
    line(img, [(S(214), S(24)), (S(218.5), S(34))], "#e6f2fa", 1.3 * SS, 190, blur=0.4)
    # the bonnet: long, louvred, a gold strip down the middle, the brass bell on the cowl ahead of the screen
    hood = [(220, 28), (252, 30), (274, 34), (274, 70), (252, 74), (220, 76)]
    paint_shape(img, SP(hood), red, seed + 14, outline=OUT, ow=1.6, wob=0.2, tex=0.14, strokes_n=6,
                stroke_cols=[shade(red, 1.1), shade(red, 0.9)], light=(0.2, -1, 0.45), inner_shadow=0.3)
    for x in range(232, 270, 4):
        for y0 in (33, 64):
            line(img, [(S(x), S(y0)), (S(x + 2), S(y0 + 6))], "#4a0c08", 1.3 * SS, 210, blur=0.2)
    line(img, [(S(222), S(52)), (S(273), S(52))], gold, 1.2 * SS, 230, blur=0.2)
    text(img, (248, 44), "12", 7.0, gold, font=DECO)
    paint_shape(img, SP(ellipse_pts(227, 52, 6.4, 6.4)), "#d8b050", seed + 15, outline=OUT, ow=1.0, wob=0.04, light=(0.4, -1, 0.75))
    soft_blob(img, S(225.4), S(50.2), S(2.2), S(2.0), "#fff4c0", 210, 0.5 * SS)
    paint_shape(img, SP(ellipse_pts(227, 52, 1.6, 1.6)), "#7a5a20", seed + 16, outline=None, wob=0.02)
    sheen(img, [(236, 38), (270, 39), (270, 41), (236, 40)], 55, 1.4)
    # the grille, the bumper, the headlamps on the wings, a chrome siren on the near wing
    _grille(img, d, 273, 283, 32, 72, seed + 17)
    paint_shape(img, SP([(284, 20), (289, 34), (291, 52), (289, 70), (284, 84), (281.5, 84), (286, 70), (288, 52), (286, 34),
                         (281.5, 20)]), CHROME, seed + 18, outline=OUT, ow=1.0, wob=0.05, light=(1, -1, 0.4))
    lamp(img, 272, 14, 5.4, seed + 19)
    lamp(img, 272, H - 14, 5.4, seed + 20)
    paint_shape(img, SP(rrect_pts(252, 9, 263, 15, 2.6)), CHROME, seed + 21, outline=OUT, ow=0.8, wob=0.05, light=(1, -1, 0.5))
    soft_blob(img, S(261), S(12), S(1.2), S(1.6), "#2a2a2a", 220, 0.2 * SS)
    # the rear step (chrome plate) and red tail lamps on the rear wings
    paint_shape(img, SP(rrect_pts(1.5, 28, 8, 76, 1.5)), "#9a9da0", seed + 22, outline=OUT, ow=1.0, wob=0.05, tex=0.3)
    for y in (12, H - 12):
        paint_shape(img, SP(ellipse_pts(40, y, 3.2, 2.8)), "#e04a2a", seed + 23, outline=OUT, ow=0.8, wob=0.1)
        soft_blob(img, S(39.6), S(y - 0.5), S(1.2), S(1.0), "#ffc0a0", 170, 0.4 * SS)
    return finish(grain(img, 3, seed), W, H)


ASSETS = {
    "cars/ambulance": ambulance,
    "cars/fire_engine": fire_engine,
}
