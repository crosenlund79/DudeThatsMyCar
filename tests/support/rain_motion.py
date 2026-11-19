"""M013: how far the rain moved between two frames (pairs from rain_probe.gd).

    python3 tests/support/rain_motion.py <dir>

For each pair the streaks are isolated (the frame minus a blurred copy), then
cross-correlated: the strongest peaks are the drops' displacement in pixels
(+y is down the screen). Steady rain should move about +16..+24 px a frame (the
three depths), never up; panning adds the street's slide."""
import sys, os
import numpy as np
from PIL import Image

def streaks(path):
    a = np.asarray(Image.open(path).convert("L"), dtype=np.float64)
    k = 9
    pad = np.pad(a, k, mode="edge")
    c = np.cumsum(np.cumsum(pad, 0), 1)
    blur = (c[2 * k:, 2 * k:] - c[:-2 * k, 2 * k:] - c[2 * k:, :-2 * k] + c[:-2 * k, :-2 * k]) / (2 * k) ** 2
    hp = np.clip(a - blur[: a.shape[0], : a.shape[1]], 0, None)
    # the probe's lamps are still: their edges would match at zero, so they are left out
    for x, y in [(300, 200), (900, 500), (640, 360)]:
        hp[max(0, y - 75): y + 75, max(0, x - 75): x + 75] = 0.0
    return hp - hp.mean()

def shifts(a, b, top=3):
    fa, fb = np.fft.rfft2(a), np.fft.rfft2(b)
    corr = np.fft.irfft2(np.conj(fa) * fb, s=a.shape)
    h, w = a.shape
    out = []
    c = corr.copy()
    for _ in range(top):
        y, x = np.unravel_index(np.argmax(c), c.shape)
        dy = y if y < h // 2 else y - h
        dx = x if x < w // 2 else x - w
        out.append((int(dx), int(dy), float(c[y, x])))
        c[max(0, y - 4): y + 5, max(0, x - 4): x + 5] = -np.inf
    return out

d = sys.argv[1]
for case in ["steady", "swelling", "easing", "panning"]:
    pa, pb = os.path.join(d, "rain_%s_a.png" % case), os.path.join(d, "rain_%s_b.png" % case)
    if not os.path.exists(pa):
        continue
    a, b = streaks(pa), streaks(pb)
    peaks = shifts(a, b)
    best = peaks[0][2]
    print("%-9s %s" % (case, "  ".join("(dx %+d, dy %+d) %.0f%%" % (dx, dy, 100 * v / best) for dx, dy, v in peaks)))
