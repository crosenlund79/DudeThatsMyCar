"""M012: synthesises the heavy weather's template_ sounds (numpy + ffmpeg, deterministic, original - no
recordings, no samples): python3 tools/template_audio/make_weather.py assets/audio [logical name]
Uses the helpers of make_ambience.py.

weather/thunder_far   distant thunder: a long low roll that grumbles up and dies away over the roofs (about 7 s)
weather/thunder_near  thunder close by: a tearing crack, then a heavy roll and its echoes off the walls (about 6 s)
ambience/downpour     a downpour: the rain bed's hiss and rush much heavier, water sheeting off gutters and
                      awnings, drops drumming on tin (stereo loop, 12 s; played over the rain in heavy rain)"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_ambience import RATE, band, coloured, echo, periodic, place, write_ogg  # noqa: E402

rng = np.random.default_rng(1932012)


def _roll(n, seed_shift, rumbles):
    """Low noise shaped by a few overlapping swells (the roll of thunder across the sky)."""
    t = np.arange(n) / RATE
    body = band(coloured(n, 1.9), lo=22, hi=160, circular=False)
    envl = np.zeros(n)
    for at, rise, fall, gain in rumbles:
        e = np.where(t < at, 0.0, np.minimum(1.0, (t - at) / rise) * np.exp(-np.maximum(0.0, t - at - rise) / fall))
        envl += e * gain
    flutter = 1.0 + 0.35 * band(rng.standard_normal(n), hi=9, circular=False) / 0.05
    return body * envl * np.clip(flutter, 0.2, 2.0)


def thunder_far():
    n = int(7.5 * RATE)
    out = []
    for side in range(2):
        roll = _roll(n, side, [(0.15, 0.6, 1.4, 0.7), (1.1, 0.5, 1.8, 1.0), (2.6, 0.7, 1.6, 0.6), (4.0, 0.6, 1.5, 0.35)])
        tail = np.minimum(1.0, (n - np.arange(n)) / (0.8 * RATE))
        out.append(roll * tail)
    return out


def thunder_near():
    n = int(6.5 * RATE)
    t = np.arange(n) / RATE
    out = []
    for side in range(2):
        crack_n = int(0.35 * RATE)
        crack = band(rng.standard_normal(crack_n), lo=300, hi=6000, circular=False)
        crack *= np.exp(-np.arange(crack_n) / (0.07 * RATE)) * (1.0 + 0.6 * (rng.random(crack_n) > 0.985))
        y = np.zeros(n)
        place(y, crack * 0.8, int(0.02 * RATE), wrap=False)
        y += _roll(n, side, [(0.05, 0.12, 0.9, 1.0), (0.9, 0.4, 1.6, 0.8), (2.4, 0.5, 1.3, 0.45)]) * 1.4
        y = echo(y, [(0.11 + 0.02 * side, 0.35), (0.27, 0.2), (0.45, 0.12)], hi=1200, circular=False)
        y *= np.minimum(1.0, (n - np.arange(n)) / (0.6 * RATE))
        out.append(y)
    return out


def downpour():
    n = int(12.0 * RATE)
    out = []
    for side in range(2):
        hiss = band(coloured(n, 0.4), lo=900, hi=10000) * (1.0 + periodic(n, [(3, 0.12), (7, 0.06)], side)) * 0.34
        rush = band(coloured(n, 1.5), lo=60, hi=600) * (0.9 + periodic(n, [(2, 0.16)], side + 2)) * 0.5
        sheet = band(coloured(n, 1.0), lo=300, hi=2500) * (0.7 + periodic(n, [(1, 0.25), (4, 0.1)], side + 4)) * 0.22
        drums = np.zeros(n)
        at = rng.uniform(0, 0.02)
        while at < 12.0:
            k = int(0.025 * RATE)
            tt = np.arange(k) / RATE
            f0 = rng.uniform(700, 2600)
            drum = np.sin(2 * np.pi * f0 * tt) * np.exp(-tt / rng.uniform(0.002, 0.006)) * rng.uniform(0.03, 0.1)
            place(drums, drum, at * RATE)
            at += rng.exponential(0.012)
        out.append(hiss + rush + sheet + band(drums, lo=500, hi=7000))
    return out


MAKERS = {
    "weather/thunder_far": (thunder_far, 0.7),
    "weather/thunder_near": (thunder_near, 0.8),
    "ambience/downpour": (downpour, 0.5),
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
