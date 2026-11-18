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


GANGSTER = {"coat": COAT, "coat_light": COAT_LIGHT, "trouser": TROUSER, "hat": "fedora", "hat_color": HAT,
            "stripes": True, "front": "tie"}
POLICE = {"coat": "#36508c", "coat_light": "#4d69ad", "trouser": "#24304f", "hat": "cap", "hat_color": "#2a3a66",
          "stripes": False, "front": "buttons"}
# M003: the people of the Riverside Ward. Optional keys: "arm" (sleeves, default the coat),
# "hat": "fedora" | "cap" | "hair" (bare head) | "bob" (bobbed hair) | "flatcap" | "cloche",
# "front": "tie" | "buttons" | "bowtie" | "pearls" | "apron" | "plain".
BARTENDER = {"coat": "#24211f", "coat_light": "#3a3633", "arm": "#e8e3d6", "trouser": "#1c1c1f", "hat": "hair",
             "hat_color": "#24170f", "stripes": False, "front": "bowtie"}
BARBER = {"coat": "#e9e5da", "coat_light": "#f7f4ec", "trouser": "#2c2a2a", "hat": "hair", "hat_color": "#8a8580",
          "stripes": False, "front": "plain"}
GROCER = {"coat": "#6b5a44", "coat_light": "#80705a", "arm": "#d9d2c0", "trouser": "#3a3530", "hat": "flatcap",
          "hat_color": "#5a5248", "stripes": False, "front": "apron"}
CLERK = {"coat": "#8a7a5a", "coat_light": "#9c8c6c", "trouser": "#3a3a3e", "hat": "hair", "hat_color": "#d8c48a",
         "stripes": False, "front": "tie"}
DEALER = {"coat": "#2e3a2e", "coat_light": "#3e4c3e", "trouser": "#1f2420", "hat": "fedora", "hat_color": "#2a2a26",
          "stripes": True, "front": "tie"}
WORKER = {"coat": "#5a4a3a", "coat_light": "#6e5c48", "trouser": "#33302c", "hat": "flatcap", "hat_color": "#4a4640",
          "stripes": False, "front": "plain"}
LADY = {"coat": "#4a5a6a", "coat_light": "#5e7082", "trouser": "#b89070", "hat": "cloche", "hat_color": "#7a2a3a",
        "stripes": False, "front": "plain"}
BOSS = {"coat": "#2a292f", "coat_light": "#3e3d46", "trouser": "#1c1b20", "hat": "fedora", "hat_color": "#6a6862",
        "stripes": False, "front": "tie", "cigar": True}
PATRON_MAN = {"coat": "#1b1b20", "coat_light": "#34343c", "trouser": "#16161a", "hat": "hair", "hat_color": "#6a4c32",
              "stripes": False, "front": "bowtie"}
PATRON_WOMAN = {"coat": "#7a1f30", "coat_light": "#a8384a", "arm": SKIN, "trouser": "#c79a7c", "hat": "bob",
                "hat_color": "#1d1410", "stripes": False, "front": "pearls"}


def frame(step, look=GANGSTER, armed=False):
    """step: -1..1 stride phase (+ = left foot forward / right arm forward), 0 = feet together.
    armed: the right arm reaches forward to hold a pistol (drawn separately)."""
    img = new(F, F)
    cx, cy = 30, 32
    COAT = look["coat"]
    COAT_LIGHT = look["coat_light"]
    TROUSER = look["trouser"]
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
    arms = [(cx + la, cy - 14, -1), (cx + ra, cy + 14, 1)]
    if armed:
        arms = arms[:1]
    for ax, ay, side in arms:
        paint_shape(img, SP(ellipse_pts((cx + ax) / 2 + 1, ay, 6.5, 3.8, rot=math.atan2(0, ax - cx))), look.get("arm", COAT), int(ay * 7),
                    outline=OUT, ow=1.1, wob=0.2, tex=0.18, light=(0, -1, 0.4))
        paint_shape(img, SP(ellipse_pts(ax + 6, ay + side * 0.5, 2.6, 2.4)), SKIN, int(ay * 7 + 3), outline=OUT, ow=0.9,
                    wob=0.1, tex=0.1)
    if armed:
        # right arm straight out towards the aim, hand ready for the pistol
        paint_shape(img, SP(ellipse_pts(cx + 8.5, cy + 9.5, 9.0, 3.6, rot=math.atan2(-6, 14))), look.get("arm", COAT), 77,
                    outline=OUT, ow=1.1, wob=0.2, tex=0.18, light=(0, -1, 0.4))
        paint_shape(img, SP(ellipse_pts(cx + 18, cy + 4.5, 2.7, 2.5)), SKIN, 78, outline=OUT, ow=0.9, wob=0.1, tex=0.1)
    # torso: overcoat with pinstripes, collar, white shirt V and red tie at the front
    torso = ellipse_pts(cx, cy, 10, 16)
    paint_shape(img, SP(torso), COAT, 3, outline=OUT, ow=1.5, wob=0.35, tex=0.18, strokes_n=20,
                stroke_cols=[COAT_LIGHT, "#30333b"], light=(0.3, -1, 0.45), inner_shadow=0.3)
    if not look["stripes"]:
        return _head_and_front(img, cx, cy, look)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for k in range(-12, 13, 3):
        d.line([(S(cx - 8), S(cy + k)), (S(cx + 8), S(cy + k))], fill=rgba("#7a7f8c", 60), width=1)
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(SP(torso), fill=255)
    stripes = Image.new("RGBA", img.size, (0, 0, 0, 0))
    stripes.paste(layer, (0, 0), mask)
    img.alpha_composite(stripes)
    return _head_and_front(img, cx, cy, look)


def _head_and_front(img, cx, cy, look):
    if look["front"] == "buttons":
        # a policeman's double row of brass buttons and his belt with the nightstick
        line(img, [(S(cx - 9), S(cy + 9)), (S(cx + 6), S(cy - 13))], "#4a3424", 2.2 * SS, 255)
        for bx in (cx + 3.5, cx + 7):
            for by in (cy - 6, cy, cy + 6):
                paint_shape(img, SP(ellipse_pts(bx, by, 1.1, 1.1)), "#d9b45a", int(bx * 9 + by), outline=None, wob=0.02)
        paint_shape(img, SP(rrect_pts(cx - 14, cy + 13, cx - 2, cy + 15.5, 1)), "#2a1a12", 79, outline=OUT, ow=0.8, wob=0.1)
        star = [(cx + 2 + math.cos(-math.pi / 2 + k * math.pi / 5) * (3.2 if k % 2 == 0 else 1.4),
                 cy - 9 + math.sin(-math.pi / 2 + k * math.pi / 5) * (3.2 if k % 2 == 0 else 1.4)) for k in range(10)]
        paint_shape(img, SP(star), "#f0cc66", 85, outline=OUT, ow=0.6, wob=0.02)
        return _hat(img, cx, cy, look)
    front = look["front"]
    if front == "pearls":
        for k in range(7):
            a = -0.9 + k * 0.3
            paint_shape(img, SP(ellipse_pts(cx + 3 + math.cos(a) * 6, cy + math.sin(a) * 6, 0.9, 0.9)), "#f4efe2", 90 + k,
                        outline=None, wob=0.02)
        return _hat(img, cx, cy, look)
    if front == "apron":
        paint_shape(img, SP(ellipse_pts(cx + 3.5, cy, 6.5, 12.5)), "#e9e4d6", 91, outline=OUT, ow=0.8, wob=0.2, tex=0.1)
        line(img, [(S(cx - 2), S(cy - 12)), (S(cx - 2), S(cy + 12))], "#d8d2c2", 1.0 * SS, 200)
        return _hat(img, cx, cy, look)
    if front == "plain":
        return _hat(img, cx, cy, look)
    paint_shape(img, SP([(cx + 5, cy - 5), (cx + 10, cy), (cx + 5, cy + 5), (cx + 7.5, cy)]), "#ece6d8", 5, outline=None, wob=0.1)
    if front == "bowtie":
        paint_shape(img, SP([(cx + 7.5, cy), (cx + 9.2, cy - 2.6), (cx + 9.2, cy + 2.6)]), "#111111", 6, outline=None, wob=0.02)
        paint_shape(img, SP([(cx + 7.5, cy), (cx + 5.8, cy - 2.6), (cx + 5.8, cy + 2.6)]), "#111111", 6, outline=None, wob=0.02)
        return _hat(img, cx, cy, look)
    paint_shape(img, SP([(cx + 6.5, cy - 1.4), (cx + 9.6, cy), (cx + 6.5, cy + 1.4)]), "#8f1e1e", 6, outline=None, wob=0.05)
    return _hat(img, cx, cy, look)


def _hat(img, cx, cy, look):
    HAT = look["hat_color"]
    if look["hat"] == "cap":
        # police peaked cap: round crown, black visor at the front, brass badge
        paint_shape(img, SP(ellipse_pts(cx + 9.5, cy, 2.0, 1.7)), SKIN, 7, outline=OUT, ow=0.8, wob=0.1, tex=0.1)
        paint_shape(img, SP(ellipse_pts(cx + 6, cy, 5.5, 7.2)), "#111318", 81, outline=OUT, ow=1.0, wob=0.15, tex=0.1,
                    light=(0.5, -1, 0.6))
        paint_shape(img, SP(ellipse_pts(cx, cy, 8.4, 8.6)), HAT, 82, outline=OUT, ow=1.4, wob=0.25, tex=0.2, strokes_n=10,
                    light=(0.4, -1, 0.5), inner_shadow=0.25)
        paint_shape(img, SP(ellipse_pts(cx + 0.5, cy, 5.2, 5.6)), shade(HAT, 1.18), 83, outline=None, wob=0.2, tex=0.2,
                    light=(0.4, -1, 0.6))
        paint_shape(img, SP(ellipse_pts(cx + 6.5, cy, 1.6, 2.0)), "#e2c068", 84, outline=OUT, ow=0.6, wob=0.05)
        soft_blob(img, S(cx + 1.5), S(cy - 2.5), S(2.2), S(1.4), "#ffffff", 40, 0.8 * SS)
        return finish(img, F, F)
    if look["hat"] == "cloche":
        # a close-fitting bell hat with a ribbon, the face just showing at the front
        paint_shape(img, SP(ellipse_pts(cx + 8.6, cy, 2.2, 2.6)), SKIN, 7, outline=OUT, ow=0.8, wob=0.1, tex=0.1)
        paint_shape(img, SP(ellipse_pts(cx, cy, 8.8, 8.6)), shade(HAT, 0.85), 88, outline=OUT, ow=1.3, wob=0.2, tex=0.2,
                    light=(0.4, -1, 0.5))
        paint_shape(img, SP(ellipse_pts(cx - 0.5, cy, 6.6, 6.4)), HAT, 89, outline=OUT, ow=1.0, wob=0.2, tex=0.2,
                    light=(0.4, -1, 0.6))
        line(img, [(S(cx + 2), S(cy - 5.6)), (S(cx + 4), S(cy - 2))], "#e8d8b0", 1.2 * SS, 230)
        soft_blob(img, S(cx + 1), S(cy - 3), S(2.4), S(1.4), "#ffffff", 40, 0.8 * SS)
        return finish(img, F, F)
    if look["hat"] == "flatcap":
        # a cloth flat cap: round crown, short brim at the front
        paint_shape(img, SP(ellipse_pts(cx + 9.5, cy, 2.0, 1.7)), SKIN, 7, outline=OUT, ow=0.8, wob=0.1, tex=0.1)
        paint_shape(img, SP(ellipse_pts(cx + 5.5, cy, 4.5, 6.8)), shade(HAT, 0.8), 86, outline=OUT, ow=1.0, wob=0.15, tex=0.15)
        paint_shape(img, SP(ellipse_pts(cx - 0.5, cy, 8.2, 8.0)), HAT, 87, outline=OUT, ow=1.3, wob=0.25, tex=0.3, strokes_n=10,
                    stroke_cols=[shade(HAT, 1.2), shade(HAT, 0.85)], light=(0.4, -1, 0.5))
        line(img, [(S(cx - 5), S(cy)), (S(cx + 3), S(cy))], shade(HAT, 0.7), 1.0 * SS, 200)
        soft_blob(img, S(cx + 1), S(cy - 3), S(2.4), S(1.4), "#ffffff", 40, 0.8 * SS)
        return finish(img, F, F)
    if look["hat"] in ("hair", "bob"):
        hair = look["hat_color"]
        bob = look["hat"] == "bob"
        # bare head: the face towards the front, hair combed back (or a glossy bob)
        paint_shape(img, SP(ellipse_pts(cx + 1.5, cy, 7.4, 7.0)), SKIN, 7, outline=OUT, ow=1.0, wob=0.15, tex=0.1,
                    light=(0.5, -1, 0.4))
        paint_shape(img, SP(ellipse_pts(cx + 8.4, cy, 1.8, 1.5)), SKIN, 71, outline=OUT, ow=0.7, wob=0.05, tex=0.1)
        hx, rx, ry = (cx - 0.5, 7.6, 8.4) if bob else (cx - 1.4, 6.6, 6.4)
        paint_shape(img, SP(ellipse_pts(hx, cy, rx, ry)), hair, 72, outline=OUT, ow=1.1, wob=0.2, tex=0.15, strokes_n=8,
                    stroke_cols=[shade(hair, 1.4), shade(hair, 0.8)], light=(0.4, -1, 0.6))
        if not bob:
            line(img, [(S(cx - 6), S(cy - 2)), (S(cx + 4), S(cy - 2.4))], shade(hair, 1.6), 0.9 * SS, 200)
        soft_blob(img, S(cx), S(cy - 3), S(2.6), S(1.4), "#ffffff", 50, 0.7 * SS)
        return finish(img, F, F)
    # head: fedora with a dark band and a pinched crown; the nose just visible at the front
    paint_shape(img, SP(ellipse_pts(cx + 9.5, cy, 2.0, 1.7)), SKIN, 7, outline=OUT, ow=0.8, wob=0.1, tex=0.1)
    paint_shape(img, SP(ellipse_pts(cx + 1, cy, 9.6, 9.2)), HAT, 8, outline=OUT, ow=1.5, wob=0.3, tex=0.2, strokes_n=14,
                light=(0.4, -1, 0.5), inner_shadow=0.2)
    paint_shape(img, SP(ellipse_pts(cx, cy, 6.4, 5.9)), BAND, 9, outline=None, wob=0.2, tex=0.1)
    paint_shape(img, SP(ellipse_pts(cx - 0.3, cy, 5.3, 4.8)), shade(HAT, 1.12), 10, outline=OUT, ow=1.0, wob=0.2, tex=0.2,
                light=(0.4, -1, 0.6))
    line(img, [(S(cx - 3.5), S(cy)), (S(cx + 3.5), S(cy))], shade(HAT, 0.6), 1.3 * SS, 210)
    soft_blob(img, S(cx + 2.5), S(cy - 2.5), S(2.5), S(1.6), "#ffffff", 45, 0.8 * SS)
    if look.get("cigar"):
        # a fat cigar from the corner of his mouth, its tip glowing
        line(img, [(S(cx + 9.5), S(cy + 1.5)), (S(cx + 15), S(cy + 3.2))], "#6a4426", 2.2 * SS, 255)
        soft_blob(img, S(cx + 15.2), S(cy + 3.3), S(1.3), S(1.3), "#ff8a3a", 230, 0.4 * SS)
    return finish(img, F, F)


def sheet(look=GANGSTER, armed=False):
    strip = Image.new("RGBA", (F * FRAMES, F), (0, 0, 0, 0))
    for i, st in enumerate((0.0, 1.0, 0.0, -1.0, 0.0)):
        fr = frame(st if i != 2 and i != 4 else (0.25 if i == 2 else -0.25), look, armed)
        if i == 0:
            fr = frame(0.0, look, armed)
        strip.alpha_composite(fr, (i * F, 0))
    return strip


ASSETS = {
    "characters/gangster": sheet,
    "characters/gangster_armed": lambda: sheet(GANGSTER, True),
    "characters/police": lambda: sheet(POLICE),
    "characters/bartender": lambda: sheet(BARTENDER),
    "characters/patron_man": lambda: sheet(PATRON_MAN),
    "characters/barber": lambda: sheet(BARBER),
    "characters/boss": lambda: sheet(BOSS),
    "characters/worker": lambda: sheet(WORKER),
    "characters/lady": lambda: sheet(LADY),
    "characters/grocer": lambda: sheet(GROCER),
    "characters/clerk": lambda: sheet(CLERK),
    "characters/dealer": lambda: sheet(DEALER),
    "characters/patron_woman": lambda: sheet(PATRON_WOMAN),
}
