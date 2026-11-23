"""M015: synthesises the new quarters' template_ sounds (numpy + ffmpeg, deterministic, original - no
recordings, no samples): python3 tools/template_audio/make_quarters.py assets/audio [logical name]
Uses the helpers of make_ambience.py.

fx/el_train   the El going over: a low steel roar and the deck's drumming, the wheels clattering over the
              rail joints two by two, now and then a squeal on the curve (stereo loop, 6 s; played from the
              train while it runs, by distance)"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_ambience import RATE, band, coloured, periodic, place, write_ogg  # noqa: E402

rng = np.random.default_rng(1932015)


def el_train():
    n = int(6.0 * RATE)
    out = []
    for side in range(2):
        roar = band(coloured(n, 1.8), lo=35, hi=260) * (0.9 + periodic(n, [(3, 0.15), (5, 0.08)], side)) * 0.9
        deck = band(coloured(n, 1.2), lo=120, hi=900) * (0.8 + periodic(n, [(6, 0.2)], side + 2)) * 0.35
        clack = np.zeros(n)
        at = 0.05 + 0.01 * side
        while at < 6.0:
            for k, gap in enumerate((0.0, 0.11)):  # a truck's two axles over the joint
                m = int(0.04 * RATE)
                tt = np.arange(m) / RATE
                hit = band(rng.standard_normal(m), lo=200, hi=3000, circular=False) * np.exp(-tt / 0.012)
                hit += np.sin(2 * np.pi * rng.uniform(110, 160) * tt) * np.exp(-tt / 0.02) * 0.6
                place(clack, hit * rng.uniform(0.5, 0.8), (at + gap) * RATE)
            at += 0.75
        squeal = np.zeros(n)
        m = int(1.2 * RATE)
        tt = np.arange(m) / RATE
        tone = np.sin(2 * np.pi * (2400 + 160 * np.sin(2 * np.pi * 3.1 * tt)) * tt) * np.sin(np.pi * tt / 1.2) ** 2 * 0.05
        place(squeal, tone, (2.4 + 0.1 * side) * RATE)
        out.append(roar + deck + band(clack, lo=150, hi=4000) + squeal)
    return out


MAKERS = {
    "fx/el_train": (el_train, 0.6),
}


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "assets/audio"
    only = sys.argv[2] if len(sys.argv) > 2 else ""
    for logical, (fn, peak) in MAKERS.items():
        if only and logical != only:
            continue
        made = fn()
        write_ogg(os.path.join(root, os.path.dirname(logical), "template_" + os.path.basename(logical) + ".ogg"),
                  made if isinstance(made, list) else [made], peak)


if __name__ == "__main__":
    main()
