"""M010: Eddie's borrowed Thompson and the parcel.

weapons/thompson - a Thompson submachine gun seen from above, muzzle to the
                   right like the pistol: the walnut butt stock at the left,
                   the dark receiver, the vertical fore-grip, the finned barrel.
props/parcel     - the parcel, from above: a shoebox in brown paper and string
                   (an abstract item - nothing about it is shown or explained).
ui/item_parcel   - the same parcel as a little HUD badge."""
import math
import random

from PIL import Image

from paintkit import *

OUT = (22, 18, 16)
STEEL = "#33383f"
WALNUT = "#6a4224"


def thompson():
    w, h = 96, 24
    img = new(w, h)
    soft_blob(img, S(50), S(14), S(44), S(6), "#000000", 70, 1.6 * SS)
    # butt stock (left), tapering into the grip
    paint_shape(img, SP([(2, 7), (24, 9), (24, 15), (2, 17)]), WALNUT, 11, outline=OUT, ow=1.0, wob=0.15, tex=0.25,
                light=(0, -1, 0.5))
    line(img, [S(4, 9), S(22, 10.5)], "#8a5a34", 0.8 * SS, 200)
    # receiver
    paint_shape(img, SP(rrect_pts(23, 8, 54, 16, 1.5)), STEEL, 12, outline=OUT, ow=1.0, wob=0.08, tex=0.15,
                light=(0, -1, 0.7))
    line(img, [S(26, 9.5), S(52, 9.5)], "#8d96a3", 0.9 * SS, 220, blur=0.15)
    paint_shape(img, SP(ellipse_pts(36, 12, 2.0, 2.0)), "#1c1e22", 13, outline=None, wob=0.02)  # the cocking knob
    # the vertical fore-grip, a little ahead, in walnut
    paint_shape(img, SP(rrect_pts(56, 8.5, 64, 15.5, 2)), WALNUT, 14, outline=OUT, ow=0.9, wob=0.1, tex=0.2, light=(0, -1, 0.5))
    # finned barrel
    paint_shape(img, SP(rrect_pts(54, 9.5, 88, 14.5, 1)), "#2a2e34", 15, outline=OUT, ow=0.9, wob=0.05, tex=0.1, light=(0, -1, 0.6))
    for x in range(66, 82, 2):
        line(img, [S(x, 9.2), S(x, 14.8)], "#4a5058", 0.8 * SS, 230, blur=0.05)
    paint_shape(img, SP(rrect_pts(86, 10, 93, 14, 1)), STEEL, 16, outline=OUT, ow=0.8, wob=0.03)  # compensator
    paint_shape(img, SP(ellipse_pts(93.2, 12, 1.0, 1.3)), "#0b0b0d", 17, outline=None, wob=0.02)
    return finish(img, w, h)


def _parcel(img, cx, cy, sx, sy, seed):
    soft_blob(img, S(cx + 2), S(cy + 3), S(sx * 0.55), S(sy * 0.55), "#000000", 90, 2 * SS)
    paint_shape(img, SP(rrect_pts(cx - sx / 2, cy - sy / 2, cx + sx / 2, cy + sy / 2, 2)), "#a07a4e", seed, outline=OUT,
                ow=1.1, wob=0.3, tex=0.3, strokes_n=8, stroke_cols=["#b48c5c", "#8a643e"], light=(-0.4, -1, 0.35))
    rnd = random.Random(seed)
    for k in range(4):  # creases in the paper
        x0 = cx + rnd.uniform(-sx / 2.5, sx / 2.5)
        line(img, [S(x0, cy - sy / 2 + 2), S(x0 + rnd.uniform(-3, 3), cy + sy / 2 - 2)], "#7a5a36", 0.6 * SS, 120)
    # the string, both ways, and its knot
    line(img, [S(cx - sx / 2, cy), S(cx + sx / 2, cy)], "#e4dcc4", 1.1 * SS, 240)
    line(img, [S(cx, cy - sy / 2), S(cx, cy + sy / 2)], "#e4dcc4", 1.1 * SS, 240)
    paint_shape(img, SP(ellipse_pts(cx, cy, 2.2, 2.2)), "#e4dcc4", seed + 1, outline=(90, 80, 60), ow=0.5, wob=0.05)
    line(img, [S(cx, cy), S(cx + 5, cy + 4)], "#e4dcc4", 0.9 * SS, 230)
    line(img, [S(cx, cy), S(cx + 3, cy + 6)], "#e4dcc4", 0.9 * SS, 230)


def parcel():
    w, h = 48, 40
    img = new(w, h)
    _parcel(img, 24, 20, 36, 26, 21)
    return finish(img, w, h)


def item_parcel():
    w = h = 64
    img = new(w, h)
    paint_shape(img, SP(ellipse_pts(32, 32, 29, 29)), "#1a1410", 31, outline=(216, 160, 96), ow=1.6, wob=0.05, tex=0.1)
    _parcel(img, 32, 33, 38, 28, 32)
    return finish(img, w, h)


ASSETS = {
    "weapons/thompson": thompson,
    "props/parcel": parcel,
    "ui/item_parcel": item_parcel,
}
