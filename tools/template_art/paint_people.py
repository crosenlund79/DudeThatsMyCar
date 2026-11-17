"""The gangster: top-down, facing right (+X). A horizontal strip of 64x64 frames:
0 idle, 1 step (left foot forward), 2 passing, 3 step (right foot forward), 4 passing.
Display size 30 x 30 world px per frame."""
import math

from PIL import Image, ImageDraw, ImageFilter

from paintkit import *

F = 64
FRAMES = 5
OUT = (24, 18, 16)
COAT = "#454a57"
COAT_LIGHT = "#59606f"
HAT = "#4b3a2c"
BAND = "#1b1512"
SKIN = "#d6a27c"
SHOE = "#1f1712"
TROUSER = "#2b2d33"


def frame(step):
    """step: -1..1 stride phase (+ = left foot forward / right arm forward), 0 = feet together."""
    img = new(F, F)
    cx, cy = 30, 32
    # feet and trouser legs (seen past the coat when striding)
    lf = 7 + 9 * step     # left foot (top side, y < cy) forward offset
    rf = 7 - 9 * step
    for fx, fy in ((cx + lf, cy - 6), (cx + rf, cy + 6)):
        paint_shape(img, SP(ellipse_pts(fx - 3, fy, 4.5, 3.4)), TROUSER, int(fx * 10), outline=OUT, ow=1.0, wob=0.15, tex=0.15)
        paint_shape(img, SP(ellipse_pts(fx + 1.5, fy, 4.2, 3.0)), SHOE, int(fx * 10 + 1), outline=OUT, ow=1.0, wob=0.15,
                    tex=0.1, light=(1, -1, 0.5))
    # arms swing opposite to the feet
    la = -8 * step  # left arm (top side) forward when the right foot leads
    ra = 8 * step
    for ax, ay, side in ((cx + la, cy - 14, -1), (cx + ra, cy + 14, 1)):
        paint_shape(img, SP(ellipse_pts((cx + ax) / 2 + 1, ay, 6.5, 3.8, rot=math.atan2(0, ax - cx))), COAT, int(ay * 7),
                    outline=OUT, ow=1.1, wob=0.2, tex=0.18, light=(0, -1, 0.4))
        paint_shape(img, SP(ellipse_pts(ax + 6, ay + side * 0.5, 2.6, 2.4)), SKIN, int(ay * 7 + 3), outline=OUT, ow=0.9,
                    wob=0.1, tex=0.1)
    # torso: overcoat with pinstripes, collar, white shirt V and red tie at the front
    torso = ellipse_pts(cx, cy, 10, 16)
    paint_shape(img, SP(torso), COAT, 3, outline=OUT, ow=1.5, wob=0.35, tex=0.18, strokes_n=20,
                stroke_cols=[COAT_LIGHT, "#30333b"], light=(0.3, -1, 0.45), inner_shadow=0.3)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for k in range(-12, 13, 3):
        d.line([(S(cx - 8), S(cy + k)), (S(cx + 8), S(cy + k))], fill=rgba("#7a7f8c", 60), width=1)
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(SP(torso), fill=255)
    stripes = Image.new("RGBA", img.size, (0, 0, 0, 0))
    stripes.paste(layer, (0, 0), mask)
    img.alpha_composite(stripes)
    paint_shape(img, SP([(cx + 5, cy - 5), (cx + 10, cy), (cx + 5, cy + 5), (cx + 7.5, cy)]), "#ece6d8", 5, outline=None, wob=0.1)
    paint_shape(img, SP([(cx + 6.5, cy - 1.4), (cx + 9.6, cy), (cx + 6.5, cy + 1.4)]), "#8f1e1e", 6, outline=None, wob=0.05)
    # head: fedora with a dark band and a pinched crown; the nose just visible at the front
    paint_shape(img, SP(ellipse_pts(cx + 9.5, cy, 2.0, 1.7)), SKIN, 7, outline=OUT, ow=0.8, wob=0.1, tex=0.1)
    paint_shape(img, SP(ellipse_pts(cx + 1, cy, 9.6, 9.2)), HAT, 8, outline=OUT, ow=1.5, wob=0.3, tex=0.2, strokes_n=14,
                light=(0.4, -1, 0.5), inner_shadow=0.2)
    paint_shape(img, SP(ellipse_pts(cx, cy, 6.4, 5.9)), BAND, 9, outline=None, wob=0.2, tex=0.1)
    paint_shape(img, SP(ellipse_pts(cx - 0.3, cy, 5.3, 4.8)), shade(HAT, 1.12), 10, outline=OUT, ow=1.0, wob=0.2, tex=0.2,
                light=(0.4, -1, 0.6))
    line(img, [(S(cx - 3.5), S(cy)), (S(cx + 3.5), S(cy))], shade(HAT, 0.6), 1.3 * SS, 210)
    soft_blob(img, S(cx + 2.5), S(cy - 2.5), S(2.5), S(1.6), "#ffffff", 45, 0.8 * SS)
    return finish(img, F, F)


def sheet():
    strip = Image.new("RGBA", (F * FRAMES, F), (0, 0, 0, 0))
    for i, st in enumerate((0.0, 1.0, 0.0, -1.0, 0.0)):
        fr = frame(st if i != 2 and i != 4 else (0.25 if i == 2 else -0.25))
        if i == 0:
            fr = frame(0.0)
        strip.alpha_composite(fr, (i * F, 0))
    return strip


ASSETS = {"characters/gangster": sheet}
