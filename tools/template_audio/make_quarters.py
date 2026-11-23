"""M015: synthesises the new quarters' template_ sounds (numpy + ffmpeg, deterministic, original - no
recordings, no samples): python3 tools/template_audio/make_quarters.py assets/audio [logical name]
Uses the helpers of make_ambience.py.

fx/el_train   the El going over: a low steel roar and the deck's drumming, the wheels clattering over the
              rail joints two by two, now and then a squeal on the curve (stereo loop, 6 s; played from the
              train while it runs, by distance)
music/paradise_band  M015.12: the Paradise Ballroom's dance band - an original sixteen-bar foxtrot at 116 beats a
              minute (stride piano: bass on one and three, chords on two and four; brushes on the snare; a muted
              horn's tune made up from the chords; stereo loop, about 33 s; played from the bandstand)
places/cleaver M015.12: a cleaver into a block (a short wooden thunk; the market hall's butcher)
places/cup    M015.12: a cup set down on its saucer (the market hall's coffee, the Golden Lantern's tea)"""
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


def _note(freq, dur, harmonics, decay, attack=0.004):
    m = int(dur * RATE)
    tt = np.arange(m) / RATE
    env = np.minimum(tt / attack, 1.0) * np.exp(-tt / decay)
    tone = sum(a * np.sin(2 * np.pi * freq * k * tt) for k, a in harmonics)
    return tone * env


def paradise_band():
    bpm = 116.0
    beat = 60.0 / bpm
    bars = 16
    n = int(bars * 4 * beat * RATE)
    hz = lambda midi: 440.0 * 2 ** ((midi - 69) / 12.0)  # noqa: E731
    # an original changes: C, A minor, D minor, G7 - twice; F, F minor, C, G7 - twice (bars of four beats)
    changes = [(48, [60, 64, 67]), (45, [60, 64, 69]), (50, [62, 65, 69]), (43, [59, 65, 67])] * 2 \
        + [(41, [60, 65, 69]), (41, [60, 65, 68]), (48, [60, 64, 67]), (43, [59, 62, 65, 67])] * 2
    left = np.zeros(n)
    right = np.zeros(n)
    tune_rng = np.random.default_rng(1932012)
    piano = [(1, 1.0), (2, 0.45), (3, 0.2), (4, 0.1)]
    horn = [(1, 0.8), (2, 0.6), (3, 0.45), (4, 0.25), (5, 0.12)]
    last = 72
    for b, (root, chord) in enumerate(changes):
        t0 = b * 4 * beat
        for k in range(4):
            at = (t0 + k * beat) * RATE
            if k % 2 == 0:  # the stride bass: root, then the fifth
                bass = root if k == 0 else root + 7
                note = _note(hz(bass), beat * 0.95, [(1, 1.0), (2, 0.5), (3, 0.15)], 0.35)
                place(left, note * 0.5, at)
                place(right, note * 0.42, at)
            else:  # the chord on the off-beat
                for c in chord:
                    note = _note(hz(c), beat * 0.6, piano, 0.18)
                    place(left, note * 0.13, at)
                    place(right, note * 0.16, at)
            # brushes: a swish on every beat, a little accent on two and four
            m = int(beat * 0.5 * RATE)
            tt = np.arange(m) / RATE
            swish = band(tune_rng.standard_normal(m), lo=2500, hi=9000, circular=False) \
                * np.sin(np.pi * np.minimum(tt / (beat * 0.5), 1.0)) * (0.07 if k % 2 else 0.045)
            place(left, swish, at)
            place(right, swish * 0.8, at + 0.004 * RATE)
        # the horn: two to four notes a bar from the chord (and a passing note), never far from the last
        steps = tune_rng.choice([2, 3, 4], p=[0.3, 0.45, 0.25])
        times = sorted(tune_rng.choice(8, size=steps, replace=False))
        for i, half in enumerate(times):
            pool = [c + 12 for c in chord] + [c + 24 for c in chord if c + 24 <= 84]
            pool = sorted(pool, key=lambda x: abs(x - last))[:3]
            pitch = int(tune_rng.choice(pool))
            last = pitch
            end = times[i + 1] if i + 1 < len(times) else 8
            dur = max(0.25, (end - half) * beat / 2 * 0.92)
            m = int(dur * RATE)
            tt = np.arange(m) / RATE
            vib = np.sin(2 * np.pi * 5.2 * tt) * 0.004 * np.minimum(tt / 0.25, 1.0)
            phase = 2 * np.pi * hz(pitch) * np.cumsum(1.0 + vib) / RATE
            tone = sum(a * np.sin(k * phase) for k, a in horn)
            env = np.minimum(tt / 0.04, 1.0) * np.minimum((dur - tt) / 0.06, 1.0).clip(0, 1) * (0.85 + 0.15 * np.exp(-tt / 0.3))
            note = band(tone * env, lo=250, hi=2600, circular=False) * 0.2
            at = (t0 + half * beat / 2) * RATE
            place(left, note * 0.9, at)
            place(right, note, at)
    room = band(coloured(n, 1.0), lo=200, hi=1500) * 0.012  # the hall's air
    return [left + room, right + room]


def cleaver():
    m = int(0.35 * RATE)
    tt = np.arange(m) / RATE
    thunk = band(rng.standard_normal(m), lo=80, hi=900, circular=False) * np.exp(-tt / 0.03)
    thunk += np.sin(2 * np.pi * 95 * tt) * np.exp(-tt / 0.05) * 0.8
    ring = np.sin(2 * np.pi * 2300 * tt) * np.exp(-tt / 0.06) * 0.05
    return thunk + ring


def cup():
    m = int(0.4 * RATE)
    tt = np.arange(m) / RATE
    clink = sum(a * np.sin(2 * np.pi * f * tt) * np.exp(-tt / d) for f, a, d in ((2950, 0.5, 0.05), (4100, 0.3, 0.035),
                                                                              (5600, 0.15, 0.02)))
    tap = band(rng.standard_normal(m), lo=400, hi=3000, circular=False) * np.exp(-tt / 0.008) * 0.6
    return clink + tap


MAKERS = {
    "fx/el_train": (el_train, 0.6),
    "music/paradise_band": (paradise_band, 0.7),
    "places/cleaver": (cleaver, 0.7),
    "places/cup": (cup, 0.5),
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
