"""M010: Rourke's job at Rosie's Café, Halloran Square.

props/packard  - Vince Duggan's green Packard at the kerb, from above, nose
                 right like the cars (scenery: it is never driven).
props/car_wreck - the same car burnt out: blackened shell, the glass gone,
                 the paint blistered, embers still glowing here and there.
decals/scorch  - the black scorch on the road where it stood (flat, soft-edged).
fx/fireball    - the blast's flash of fire (additive light, round, ragged).
fx/flame       - one tongue of flame for the fire in the wreck (additive,
                 base at the bottom; the game flickers and stretches it).
fx/smoke_plume - a thick, dark puff of smoke (normal blend; the game drifts
                 and grows them into a column).
signs/cafe     - ROSIE'S CAFE painted on the roof, like the other shop signs."""
import math
import random

import numpy as np
from PIL import Image, ImageFilter

from paintkit import *
import paint_vehicles
from paint_props import painted_roof_sign

OUT = (20, 16, 14)


def packard():
    return paint_vehicles.sedan(body="#1f4a2e", roof="#d9cfb2", seed=41)


def car_wreck():
    img = paint_vehicles.sedan(body="#2b2420", roof="#231e1b", seed=43)
    w, h = img.size
    a = np.asarray(img, dtype=np.float32).copy()
    rng = np.random.default_rng(1932043)
    # char: most of the colour burnt out, blotches of soot, the odd rust-red blister
    n = tnoise(w, h, 6, 44, octaves=4)
    soot = 0.28 + 0.35 * n
    a[..., :3] *= soot[..., None]
    rust = np.clip((tnoise(w, h, 10, 45, octaves=3) - 0.66) * 3.0, 0, 1)
    a[..., 0] += rust * 45
    a[..., 1] += rust * 16
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    # the glass gone, the roof fallen in (the sedan comes back at its final size:
    # these are drawn in its own pixels)
    paint_shape(img, [(99, 20.5), (109, 24), (109, 56), (99, 59.5)], "#0a0807", 46, outline=None, wob=0.4, tex=0.3)
    paint_shape(img, rrect_pts(56, 22, 98, 58, 5), "#120f0d", 47, outline=(40, 30, 24), ow=0.5, wob=0.6, tex=0.4)
    rnd = random.Random(48)
    for k in range(9):  # embers
        x, y = rnd.uniform(20, 150), rnd.uniform(20, 60)
        soft_blob(img, x, y, rnd.uniform(1.0, 2.2), rnd.uniform(1.0, 2.0), "#ff7a2a", rnd.randint(120, 220), 0.8)
    return img


def scorch():
    w = h = 128
    img = new(w, h)
    rnd = random.Random(51)
    for k in range(16):
        a = rnd.uniform(0, 2 * math.pi)
        r = rnd.uniform(0, 26)
        soft_blob(img, S(64 + math.cos(a) * r), S(64 + math.sin(a) * r), S(rnd.uniform(16, 34)), S(rnd.uniform(10, 24)),
                  "#0c0907", rnd.randint(40, 90), 6 * SS, rot=rnd.uniform(0, math.pi))
    for k in range(10):  # flecks of burnt rubbish and glass
        x, y = rnd.uniform(20, 108), rnd.uniform(20, 108)
        soft_blob(img, S(x), S(y), S(rnd.uniform(0.8, 1.8)), S(rnd.uniform(0.8, 1.6)),
                  rnd.choice(["#2a2420", "#a8c0c8", "#3a2a20"]), rnd.randint(140, 220), 0.3 * SS)
    return finish(img, w, h)


def fireball():
    w = h = 128
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    r = np.hypot(xx - 64, yy - 64) / 64.0
    n = tnoise(w, h, 5, 61, octaves=4)
    edge = 0.62 + 0.38 * n
    v = np.clip(1.0 - r / edge, 0, 1)
    core = np.clip(1.0 - r / 0.45, 0, 1) ** 1.5
    out = np.zeros((h, w, 4), dtype=np.float32)
    out[..., 0] = 255
    out[..., 1] = 120 + 135 * core
    out[..., 2] = 30 + 200 * core ** 2
    out[..., 3] = np.clip(v ** 0.8 * 255, 0, 255)
    return Image.fromarray(out.astype(np.uint8), "RGBA")


def flame():
    w, h = 48, 64
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    u = (xx - w / 2) / (w / 2)
    v = 1.0 - yy / h  # 0 at the base, 1 at the tip
    n = tnoise(w, h, 4, 63, octaves=3)
    width = (0.85 - 0.7 * v) * (0.8 + 0.4 * n)
    body = np.clip(1.0 - np.abs(u) / np.maximum(width, 0.05), 0, 1) * np.clip(1.0 - v * 1.05, 0, 1)
    hot = np.clip(body * 1.6 - 0.6, 0, 1)
    out = np.zeros((h, w, 4), dtype=np.float32)
    out[..., 0] = 255
    out[..., 1] = 110 + 140 * hot
    out[..., 2] = 20 + 160 * hot ** 2
    out[..., 3] = np.clip(body ** 0.9 * 255, 0, 255)
    return Image.fromarray(out.astype(np.uint8), "RGBA")


def smoke_plume():
    w = h = 96
    img = new(w, h)
    rnd = random.Random(65)
    for k in range(12):
        a = rnd.uniform(0, 2 * math.pi)
        r = rnd.uniform(0, 18)
        soft_blob(img, S(48 + math.cos(a) * r), S(48 + math.sin(a) * r), S(rnd.uniform(14, 24)), S(rnd.uniform(12, 20)),
                  rnd.choice(["#2a2826", "#3a3734", "#1e1c1b"]), rnd.randint(60, 120), 5 * SS)
    return finish(img, w, h)


ASSETS = {
    "props/packard": packard,
    "props/car_wreck": car_wreck,
    "decals/scorch": scorch,
    "fx/fireball": fireball,
    "fx/flame": flame,
    "fx/smoke_plume": smoke_plume,
    "signs/cafe": lambda: painted_roof_sign("cafe", "ROSIE'S CAFE", 18, 256, 64),
}
