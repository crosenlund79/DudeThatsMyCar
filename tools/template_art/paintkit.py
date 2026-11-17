"""Small painting toolkit for the Chicago, 1932 template art.

Everything is drawn procedurally with PIL + numpy in a soft, hand-painted
style: noise-modulated fills, translucent brush strokes, organic (slightly
wobbly) dark outlines and soft shading. Drawing happens at SS x the template
size and is downsampled at the end for smooth edges.
"""
import math
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SS = 2


def rgba(c, a=255):
    if isinstance(c, str):
        c = c.lstrip("#")
        return (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), a)
    if len(c) == 4:
        return tuple(int(v) for v in c)
    return (int(c[0]), int(c[1]), int(c[2]), a)


def mix(a, b, t):
    a = rgba(a)
    b = rgba(b)
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(4))


def shade(c, f):
    c = rgba(c)
    return (min(255, int(c[0] * f)), min(255, int(c[1] * f)), min(255, int(c[2] * f)), c[3])


def new(w, h, c=(0, 0, 0, 0)):
    return Image.new("RGBA", (w * SS, h * SS), rgba(c))


def finish(img, w, h):
    return img.resize((w, h), Image.LANCZOS)


def tnoise(w, h, cells, seed, octaves=4, persistence=0.5):
    """Tileable fractal value noise in 0..1 (h x w)."""
    r = np.random.default_rng(seed)
    acc = np.zeros((h, w), dtype=np.float32)
    amp = 1.0
    tot = 0.0
    for o in range(octaves):
        cw = max(1, cells * 2 ** o)
        ch = max(1, int(round(cells * 2 ** o * h / w)))
        g = r.random((ch, cw)).astype(np.float32)
        big = np.tile(g, (3, 3))
        im = Image.fromarray((big * 255).astype(np.uint8)).resize((w * 3, h * 3), Image.BICUBIC)
        a = np.asarray(im, dtype=np.float32)[h:2 * h, w:2 * w] / 255.0
        acc += a * amp
        tot += amp
        amp *= persistence
    acc /= tot
    lo, hi = acc.min(), acc.max()
    return (acc - lo) / max(1e-6, hi - lo)


def modulate(img, n, amount):
    """Multiplies RGB by 1 + amount * (n - 0.5)."""
    a = np.asarray(img, dtype=np.float32).copy()
    f = 1.0 + amount * (n - 0.5)
    a[..., :3] *= f[..., None]
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")


def ramp(n, colors):
    """Maps noise 0..1 through a list of colours (RGBA image)."""
    cols = np.array([rgba(c) for c in colors], dtype=np.float32)
    k = len(cols) - 1
    x = np.clip(n, 0, 1) * k
    i = np.clip(np.floor(x).astype(int), 0, k - 1)
    t = (x - i)[..., None]
    out = cols[i] * (1 - t) + cols[i + 1] * t
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA")


def strokes(img, n, colors, length, width, seed, angle=None, alpha=(18, 55), wrap=True, blur=0.7, area=None):
    """Translucent painterly brush strokes (wrapping for seamless tiles)."""
    rnd = random.Random(seed)
    W, H = img.size
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x0, y0, x1, y1 = area if area else (0, 0, W, H)
    for _ in range(n):
        x = rnd.uniform(x0, x1)
        y = rnd.uniform(y0, y1)
        a = angle if angle is not None else rnd.uniform(0, math.pi)
        a += rnd.uniform(-0.25, 0.25)
        L = rnd.uniform(0.5, 1.0) * length * SS
        c = rgba(rnd.choice(colors), rnd.randint(*alpha))
        wdt = max(1, int(rnd.uniform(0.6, 1.0) * width * SS))
        dx, dy = math.cos(a) * L, math.sin(a) * L
        offs = [(0, 0)]
        if wrap:
            offs = [(ox, oy) for ox in (-W, 0, W) for oy in (-H, 0, H)]
        for ox, oy in offs:
            d.line([(x + ox, y + oy), (x + dx + ox, y + dy + oy)], fill=c, width=wdt)
    if blur:
        layer = wrap_blur(layer, blur * SS) if wrap else layer.filter(ImageFilter.GaussianBlur(blur * SS))
    img.alpha_composite(layer)
    return img


def wrap_blur(img, radius):
    """Gaussian blur that stays seamless (blurs a 3x3 tiling, crops the centre)."""
    W, H = img.size
    big = Image.new(img.mode, (W * 3, H * 3))
    for i in range(3):
        for j in range(3):
            big.paste(img, (i * W, j * H))
    big = big.filter(ImageFilter.GaussianBlur(radius))
    return big.crop((W, H, 2 * W, 2 * H))


def wobble_poly(points, amount, seed, step=6):
    """Subdivides a closed polygon and jitters it smoothly: an organic outline."""
    rnd = random.Random(seed)
    pts = []
    n = len(points)
    phase = rnd.uniform(0, 10)
    for i in range(n):
        ax, ay = points[i]
        bx, by = points[(i + 1) % n]
        L = math.hypot(bx - ax, by - ay)
        k = max(1, int(L / (step * SS)))
        nx, ny = (-(by - ay) / max(L, 1e-6), (bx - ax) / max(L, 1e-6))
        for j in range(k):
            t = j / k
            j1 = math.sin(phase + (i * 7 + j) * 0.9) * 0.6 + rnd.uniform(-0.4, 0.4)
            px = ax + (bx - ax) * t + nx * j1 * amount * SS
            py = ay + (by - ay) * t + ny * j1 * amount * SS
            pts.append((px, py))
    return pts


def ellipse_pts(cx, cy, rx, ry, n=48, rot=0.0):
    out = []
    for i in range(n):
        a = 2 * math.pi * i / n
        x, y = math.cos(a) * rx, math.sin(a) * ry
        out.append((cx + x * math.cos(rot) - y * math.sin(rot), cy + x * math.sin(rot) + y * math.cos(rot)))
    return out


def rrect_pts(x0, y0, x1, y1, r, n=6):
    """Rounded rectangle polygon (pixel coordinates already scaled)."""
    r = min(r, (x1 - x0) / 2, (y1 - y0) / 2)
    pts = []
    for cx, cy, a0 in ((x1 - r, y0 + r, -90), (x1 - r, y1 - r, 0), (x0 + r, y1 - r, 90), (x0 + r, y0 + r, 180)):
        for i in range(n + 1):
            a = math.radians(a0 + 90 * i / n)
            pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts


def S(*v):
    """Scales template coordinates to drawing coordinates."""
    if len(v) == 1:
        return v[0] * SS
    return tuple(x * SS for x in v)


def SP(points):
    return [(x * SS, y * SS) for x, y in points]


def paint_shape(img, pts, color, seed, outline=(40, 30, 28), ow=1.6, wob=0.5, tex=0.18, strokes_n=0,
                stroke_cols=None, light=None, inner_shadow=0.0, blur_edge=0.6):
    """Fills a polygon (drawing coordinates) with a painted look:
    noise texture, optional strokes, a soft light gradient, and an organic outline."""
    W, H = img.size
    seed = int(round(seed * 7)) & 0x7FFFFFFF
    poly = wobble_poly(pts, wob, seed) if wob > 0 else pts
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(blur_edge * SS * 0.5))
    fill = Image.new("RGBA", img.size, rgba(color))
    if tex > 0:
        n = tnoise(W, H, 8, seed + 11, octaves=4)
        fill = modulate(fill, n, tex)
    if strokes_n:
        xs = [p[0] for p in poly]
        ys = [p[1] for p in poly]
        strokes(fill, strokes_n, stroke_cols or [shade(color, 1.15), shade(color, 0.85)], 10, 3, seed + 3,
                alpha=(25, 70), wrap=False, area=(min(xs), min(ys), max(xs), max(ys)))
    if light is not None:
        # light = (dx, dy, strength): brighter towards (dx, dy) direction of the shape's bbox
        dx, dy, st = light
        xs = [p[0] for p in poly]
        ys = [p[1] for p in poly]
        bx0, bx1, by0, by1 = min(xs), max(xs), min(ys), max(ys)
        yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
        u = (xx - (bx0 + bx1) / 2) / max(1, (bx1 - bx0) / 2)
        v = (yy - (by0 + by1) / 2) / max(1, (by1 - by0) / 2)
        g = np.clip(0.5 + 0.5 * (u * dx + v * dy), 0, 1)
        f = 1.0 + st * (g - 0.5) * 2
        a = np.asarray(fill, dtype=np.float32).copy()
        a[..., :3] *= f[..., None]
        fill = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    if inner_shadow > 0:
        edge = mask.filter(ImageFilter.GaussianBlur(3 * SS))
        e = np.asarray(edge, dtype=np.float32) / 255.0
        m = np.asarray(mask, dtype=np.float32) / 255.0
        dark = np.clip((m - e) * 2.5, 0, 1) * inner_shadow
        a = np.asarray(fill, dtype=np.float32).copy()
        a[..., :3] *= (1 - dark)[..., None]
        fill = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    layer.paste(fill, (0, 0), mask)
    img.alpha_composite(layer)
    if outline is not None and ow > 0:
        ol = Image.new("RGBA", img.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(ol)
        d.line(poly + [poly[0]], fill=rgba(outline, 220), width=max(1, int(ow * SS)), joint="curve")
        ol = ol.filter(ImageFilter.GaussianBlur(0.45 * SS))
        img.alpha_composite(ol)
    return img


def soft_blob(img, cx, cy, rx, ry, color, alpha, blur, rot=0.0):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).polygon(ellipse_pts(cx, cy, rx, ry, rot=rot), fill=rgba(color, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    img.alpha_composite(layer)


def line(img, pts, color, width, alpha=255, blur=0.4):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).line(pts, fill=rgba(color, alpha), width=max(1, int(width)), joint="curve")
    if blur:
        layer = layer.filter(ImageFilter.GaussianBlur(blur * SS))
    img.alpha_composite(layer)


def text(img, xy, s, size, color, font="/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf", anchor="mm",
         stroke=0, stroke_color=(0, 0, 0), spacing=0):
    f = ImageFont.truetype(font, int(size * SS))
    d = ImageDraw.Draw(img)
    if spacing:
        # manual letter spacing
        total = sum(d.textlength(ch, font=f) for ch in s) + spacing * SS * (len(s) - 1)
        x = xy[0] * SS - total / 2
        for ch in s:
            d.text((x, xy[1] * SS), ch, font=f, fill=rgba(color), anchor="lm", stroke_width=int(stroke * SS),
                   stroke_fill=rgba(stroke_color))
            x += d.textlength(ch, font=f) + spacing * SS
        return
    d.text((xy[0] * SS, xy[1] * SS), s, font=f, fill=rgba(color), anchor=anchor, stroke_width=int(stroke * SS),
           stroke_fill=rgba(stroke_color))


def grain(img, amount=10, seed=0):
    a = np.asarray(img, dtype=np.float32).copy()
    r = np.random.default_rng(seed)
    g = r.normal(0, amount, a.shape[:2]).astype(np.float32)
    a[..., :3] += g[..., None]
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")


def glow_from(img, radius, strength=1.0):
    """A soft halo from an emission image (adds a blurred copy underneath)."""
    halo = img.filter(ImageFilter.GaussianBlur(radius))
    a = np.asarray(halo, dtype=np.float32).copy()
    a[..., 3] *= strength
    halo = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.alpha_composite(halo)
    out.alpha_composite(img)
    return out
