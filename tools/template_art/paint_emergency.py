"""M010: the emergency's vehicles, from above, nose right like the cars. They
are never driven by the player (scenery that drives itself to the scene), so
every tyre is painted in.

cars/ambulance   - a 1930s ambulance: a long cream body on a car chassis, a
                   grey roof with a red lamp at the front, AMBULANCE along the
                   roof, chrome at the nose. 210 x 84.
cars/fire_engine - a red pumper: a long bonnet, an open cab, the brass bell,
                   a hose reel behind the seat and the ladder along the top.
                   300 x 104."""
import random

from PIL import ImageDraw

from paintkit import *
from paint_vehicles import lamp, tyre_top, sheen, CHROME, CHROME_DARK

OUT = (20, 16, 14)


def _wheels(img, xs, w, h, wide, seed):
    for k, x in enumerate(xs):
        tyre_top(img, x, 2.5, x + wide, 12, seed + k)
        tyre_top(img, x, h - 12, x + wide, h - 2.5, seed + 10 + k)


def ambulance(seed=81):
    W, H = 210, 84
    img = new(W, H)
    soft_blob(img, S(105), S(44), S(100), S(38), "#000000", 70, 5 * SS)
    _wheels(img, [28, 150], W, H, 24, seed)
    body = "#e4dcc4"
    paint_shape(img, SP([(6, 18), (12, 11), (150, 10), (170, 14), (194, 24), (200, 30), (200, 54), (194, 60),
                         (170, 70), (150, 74), (12, 73), (6, 66)]), body, seed + 1, outline=OUT, ow=1.8, wob=0.25,
                tex=0.12, strokes_n=12, light=(0.2, -1, 0.4), inner_shadow=0.3)
    # the bonnet: louvres, the hinge strip, the radiator, lamps and bumper
    for x in range(160, 188, 4):
        for y0 in (27, 50):
            line(img, [S(x, y0), S(x + 2, y0 + 4)], "#6a6250", 1.2 * SS, 200, blur=0.2)
    line(img, [S(152, 42), S(196, 42)], CHROME, 1.3 * SS, 230, blur=0.2)
    paint_shape(img, SP([(198, 31), (205, 34), (207, 42), (205, 50), (198, 53)]), CHROME, seed + 2, outline=OUT, ow=1.0, wob=0.05)
    lamp(img, 194, 23, 4.6, seed + 3)
    lamp(img, 194, 61, 4.6, seed + 4)
    # the cabin's windscreen and the long roof with its lettering and the red lamp
    paint_shape(img, SP([(140, 16), (150, 19), (150, 65), (140, 68)]), "#6f97b2", seed + 5, outline=OUT, ow=1.0, wob=0.1, tex=0.08,
                light=(1, -1, 0.6))
    paint_shape(img, SP(rrect_pts(14, 16, 140, 68, 6)), "#9a968c", seed + 6, outline=OUT, ow=1.5, wob=0.2, tex=0.15,
                light=(0.1, -1, 0.5), inner_shadow=0.25)
    text(img, (77, 42), "AMBULANCE", 9.5, "#7a1e1e", spacing=1.2)
    paint_shape(img, SP(ellipse_pts(130, 42, 4.2, 4.2)), "#c42820", seed + 7, outline=OUT, ow=0.9, wob=0.05)
    soft_blob(img, S(129), S(41), S(1.8), S(1.6), "#ffb0a0", 200, 0.5 * SS)
    # the back doors and the tail lamps
    line(img, [S(8, 42), S(13, 42)], "#7a7262", 1.2 * SS, 220)
    for y in (16, 68):
        paint_shape(img, SP(ellipse_pts(9, y, 3.0, 2.6)), "#b3221c", seed + 8, outline=OUT, ow=0.8, wob=0.1)
    sheen(img, [(30, 22), (130, 22), (130, 27), (30, 27)], 45, 2.0)
    return finish(grain(img, 3, seed), W, H)


def fire_engine(seed=91):
    W, H = 300, 104
    img = new(W, H)
    soft_blob(img, S(150), S(54), S(144), S(46), "#000000", 70, 6 * SS)
    _wheels(img, [40, 64, 226], W, H, 22, seed)
    red = "#b0261c"
    # the long body, the bonnet ahead of the cab
    paint_shape(img, SP([(4, 20), (10, 13), (210, 12), (248, 16), (282, 26), (290, 34), (290, 70), (282, 78), (248, 88),
                         (210, 92), (10, 91), (4, 84)]), red, seed + 1, outline=OUT, ow=2.0, wob=0.25, tex=0.15,
                strokes_n=16, light=(0.2, -1, 0.45), inner_shadow=0.3)
    for x in range(250, 278, 4):
        for y0 in (32, 66):
            line(img, [S(x, y0), S(x + 2, y0 + 5)], "#4a0c08", 1.3 * SS, 210, blur=0.2)
    paint_shape(img, SP([(288, 36), (296, 40), (298, 52), (296, 64), (288, 68)]), CHROME, seed + 2, outline=OUT, ow=1.0, wob=0.05)
    lamp(img, 284, 28, 5.2, seed + 3)
    lamp(img, 284, 76, 5.2, seed + 4)
    # the brass bell before the windscreen
    paint_shape(img, SP(ellipse_pts(250, 52, 6.0, 6.0)), "#d8b050", seed + 5, outline=OUT, ow=1.0, wob=0.05, light=(0.4, -1, 0.7))
    soft_blob(img, S(248), S(50), S(2.0), S(1.8), "#fff4c0", 200, 0.5 * SS)
    # the open cab: the seat and the windscreen
    paint_shape(img, SP([(232, 22), (240, 24), (240, 80), (232, 82)]), "#6f97b2", seed + 6, outline=OUT, ow=1.0, wob=0.1,
                light=(1, -1, 0.6))
    paint_shape(img, SP(rrect_pts(206, 24, 230, 80, 3)), "#3a2a20", seed + 7, outline=OUT, ow=1.0, wob=0.15, tex=0.3)
    # the hose reel (a drum of grey hose) behind the seat
    paint_shape(img, SP(rrect_pts(176, 26, 202, 78, 6)), "#6a6a64", seed + 8, outline=OUT, ow=1.0, wob=0.15, tex=0.3,
                light=(0.2, -1, 0.5))
    for y in range(30, 76, 4):
        line(img, [S(178, y), S(200, y)], "#4a4a46", 0.9 * SS, 200)
    # the ladder along the top: two wooden rails and the rungs
    for y in (34, 70):
        paint_shape(img, SP(rrect_pts(10, y - 3, 200, y + 3, 1)), "#c09a5a", seed + 9 + y, outline=OUT, ow=0.9, wob=0.1,
                    tex=0.25, light=(0.2, -1, 0.5))
    for x in range(16, 198, 9):
        line(img, [S(x, 37), S(x, 67)], "#a07a42", 1.6 * SS, 240)
    # chrome rails and the tail lamps
    for y in (15, 89):
        line(img, [S(14, y), S(204, y)], CHROME_DARK, 1.2 * SS, 220)
    for y in (18, 86):
        paint_shape(img, SP(ellipse_pts(8, y, 3.2, 2.8)), "#e04a2a", seed + 12, outline=OUT, ow=0.8, wob=0.1)
    sheen(img, [(246, 30), (282, 34), (282, 38), (246, 35)], 55, 1.6)
    return finish(grain(img, 3, seed), W, H)


ASSETS = {
    "cars/ambulance": ambulance,
    "cars/fire_engine": fire_engine,
}
