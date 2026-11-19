"""M011: synthesises the gaming room's template_ sounds (numpy + ffmpeg, deterministic, original - no
recordings, no samples): python3 tools/template_audio/make_gaming.py assets/audio [logical name]
Uses the helpers of make_ambience.py. Loops are built on a circular buffer and repeat without a seam.

ambience/gaming_room      the back rooms' bed: smoky room tone, a few quiet voices talking over each
                          other (no words), a chip now and then (stereo loop, 24 s)
gaming/laugh              a short laugh across the room, muffled (no words)
gaming/chips_stack        a player stacking and riffling his chips
gaming/shuffle            a riffle shuffle and the bridge
gaming/glass              two glasses touching, one set down on the wood
gaming/chair              a chair pushed back on the boards, a creak
roulette/spin             the head set turning and the ball sent round the track (about 4 s, fading)
roulette/ball_drop        the ball off the track: over the deflectors and the frets, settling (about 2.6 s)
roulette/ball_rest        the last small knock of the ball into its pocket
roulette/chips            a chip set down on the felt
roulette/cue              the croupier's call bell (a single ring; no speech)
roulette/win              winnings pushed across the felt (a run of chips)
roulette/lose             the rake drawing the chips off the felt
slots/lever               the lever pulled: ratchet, spring, a heavy clunk at the bottom
slots/reels               the three reels running (a mechanical whirr with the detents' clicks; loop)
slots/stop                a reel stopping: a metallic clunk with a little ring
slots/coin                a coin dropping into the metal cup
slots/bell                the machine's win bell (a mechanical bell, rung by the payout)
poker/shuffle             the dealer's riffle at the card table
poker/pot                 the pot gathered and pushed to the winner
poker/reveal              hole cards turned over at the showdown"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_ambience import (RATE, band, click, coloured, echo, fade_ends, partials, peaks, periodic, place,  # noqa: E402
                           spectrum_filter, syllable, thump, write_ogg)

rng = np.random.default_rng(1932011)


def _t(n):
    return np.arange(n) / RATE


def clack(base, gain=1.0, dur=0.05):
    """One clay chip striking another."""
    c = partials(dur, [base, base * 1.6, base * 2.4], [0.012, 0.009, 0.006], [1.0, 0.5, 0.3], 0.01)
    c += band(rng.standard_normal(len(c)), 1500, 6000, circular=False) * np.exp(-np.arange(len(c)) / (0.006 * RATE)) * 0.6
    return c * gain


def card_tick(gain=1.0):
    n = int(0.008 * RATE)
    return band(rng.standard_normal(n), 2500, 8000, circular=False) * np.exp(-np.arange(n) / (0.0012 * RATE)) * gain


# ---------------------------------------------------------------- the room

def gaming_room():
    """The back rooms at night: low room air with a little smoke-thick warmth, four or five people
    talking quietly over each other somewhere in the room (murmurs, never words), a chip set down,
    a card snapped, someone shifting in a chair. Kept low: the game's own sounds sit over it."""
    secs = 24.0
    n = int(secs * RATE)
    out = [np.zeros(n), np.zeros(n)]
    vowels = [((600, 1.0), (1100, 0.6)), ((420, 1.0), (1900, 0.4)), ((320, 1.0), (900, 0.6)), ((520, 1.0), (1500, 0.5))]
    for v in range(5):
        f0 = rng.uniform(92, 125) if v != 2 else rng.uniform(180, 215)
        level = rng.uniform(0.35, 0.8)
        pan = rng.uniform(0.15, 0.85)
        track = np.zeros(n)
        at = rng.uniform(0, 3.0)
        while at < secs:
            for _ in range(int(rng.integers(3, 8))):
                d = rng.uniform(0.12, 0.28)
                syl = syllable(d, f0 * rng.uniform(0.92, 1.08), vowels[int(rng.integers(len(vowels)))], 0.4)
                place(track, syl * rng.uniform(0.5, 1.0), at * RATE)
                at += d * rng.uniform(0.8, 1.0)
            at += rng.uniform(1.4, 4.5)  # quieter than the club: long pauses, a hand being thought over
        out[0] += track * level * np.sqrt(1 - pan)
        out[1] += track * level * np.sqrt(pan)
    for c in range(2):
        out[c] = band(out[c], lo=110, hi=1800)  # across a smoky room, through the hats
        out[c] = echo(out[c], [(0.017, 0.35), (0.029, 0.25), (0.047, 0.15)], hi=1600)
    peak = max(np.max(np.abs(out[0])), np.max(np.abs(out[1])), 1e-6)
    air = band(coloured(n, 1.4), lo=60, hi=900)
    swell = 1.0 + periodic(n, [(2, 0.15), (5, 0.08)])
    for c in range(2):
        side = band(coloured(n, 1.4), lo=60, hi=900)
        out[c] += (air * 0.8 + side * 0.2) * swell * peak * 0.09
    # a chip set down, a card snapped, now and then
    for at, kind in ((2.1, "chip"), (5.6, "card"), (9.3, "chip"), (13.8, "chip"), (17.2, "card"), (21.0, "chip")):
        pan = rng.uniform(0.2, 0.8)
        if kind == "chip":
            s = clack(rng.uniform(2300, 3000), 0.35 * peak)
        else:
            s = card_tick(0.5 * peak)
        place(out[0], s * np.sqrt(1 - pan), at * RATE)
        place(out[1], s * np.sqrt(pan), at * RATE)
    return out


def laugh():
    """A short laugh from someone across the room: four breathy voiced 'ha's falling in pitch, muffled."""
    x = np.zeros(int(1.2 * RATE))
    f0 = rng.uniform(120, 150)
    at = 0.02
    for k in range(5):
        d = rng.uniform(0.09, 0.13)
        syl = syllable(d, f0 * (1.0 - 0.06 * k), ((700, 1.0), (1150, 0.7)), 0.9)
        place(x, syl * (1.0 - 0.13 * k), at * RATE, wrap=False)
        at += d + rng.uniform(0.05, 0.08)
    x = band(x, lo=150, hi=2200, circular=False)
    return fade_ends(echo(x, [(0.02, 0.3), (0.05, 0.15)], hi=1500, circular=False), fade_out=0.1)


def chips_stack():
    """A player stacking his chips and riffling a short stack between his fingers."""
    x = np.zeros(int(0.9 * RATE))
    at = 0.0
    for k in range(9):
        place(x, clack(rng.uniform(2200, 3100), 1.0 - k * 0.05), at * RATE, wrap=False)
        at += rng.uniform(0.04, 0.09) if k < 4 else rng.uniform(0.02, 0.035)
    return fade_ends(x, fade_out=0.08)


def riffle(dur=0.75):
    """A riffle shuffle: two halves let go a card at a time, then the bridge."""
    x = np.zeros(int((dur + 0.5) * RATE))
    at = 0.03
    for k in range(52):
        place(x, card_tick(rng.uniform(0.5, 1.0)), at * RATE, wrap=False)
        at += dur / 52 * rng.uniform(0.6, 1.4)
    n = int(0.35 * RATE)
    bridge = band(rng.standard_normal(n), 1200, 6000, circular=False) * np.exp(-((_t(n) - 0.15) / 0.08) ** 2) * 0.35
    place(x, bridge, (at + 0.05) * RATE, wrap=False)
    return fade_ends(x, fade_out=0.05)


def glass():
    """Two glasses touching, then one set down on the wood."""
    x = np.zeros(int(1.0 * RATE))
    base = rng.uniform(2700, 3300)
    ring = partials(0.6, [base, base * 1.51, base * 2.27, base * 2.9], [0.2, 0.13, 0.08, 0.05], [1.0, 0.6, 0.35, 0.2], 0.01)
    place(x, ring * 0.5, 0.02 * RATE, wrap=False)
    place(x, thump(0.12, 180, 0.02) * 0.5, 0.55 * RATE, wrap=False)
    place(x, click(0.02, 3000, 0.4), 0.55 * RATE, wrap=False)
    return fade_ends(x, fade_out=0.1)


def chair():
    """A chair pushed back on the boards: a juddering scrape, then a creak of bentwood."""
    n = int(0.55 * RATE)
    t = _t(n)
    judder = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * (38 + 10 * t) * t))
    scrape = band(rng.standard_normal(n), 200, 1600, circular=False) * judder * np.exp(-((t - 0.2) / 0.16) ** 2)
    m = int(0.4 * RATE)
    tm = _t(m)
    creak_src = np.sign(np.sin(2 * np.pi * (180 + 60 * tm) * tm)) * 0.4 + rng.standard_normal(m) * 0.2
    creak = spectrum_filter(creak_src, lambda f: peaks(f, [(900, 1.0), (1900, 0.6)], 140.0), circular=False) * np.hanning(m) * 0.35
    x = np.zeros(int(1.0 * RATE))
    place(x, scrape, 0, wrap=False)
    place(x, creak, 0.5 * RATE, wrap=False)
    return fade_ends(band(x, 120, 4000, circular=False), fade_out=0.08)


# ---------------------------------------------------------------- the wheel

def spin():
    """The head set turning and the ball sent round the track: the ball's rolling hum, its lap
    rhythm slowing as it loses speed, over the low rumble of the head; fading towards the drop."""
    dur = 4.2
    n = int(dur * RATE)
    t = _t(n)
    laps = 1.8 * np.exp(-t / 3.0)  # laps a second, slowing
    phase = 2 * np.pi * np.cumsum(laps) / RATE
    roll = band(rng.standard_normal(n), 1800, 6500, circular=False) * (0.65 + 0.35 * np.sin(phase * 3.0) ** 2)
    rumble = band(rng.standard_normal(n), 60, 400, circular=False) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.4 * t))
    shape = np.minimum(1.0, t / 0.08) * np.clip(1.0 - (t - 2.6) / 1.6, 0.0, 1.0) ** 0.7
    x = (roll * 0.6 + rumble * 0.4) * shape
    flick = click(0.02, 4000, 1.2)  # the croupier's flick of the ball
    place(x, flick, 0.0, wrap=False)
    return fade_ends(echo(x, [(0.015, 0.2)], hi=4000, circular=False), fade_out=0.3)


def ball_drop():
    """The ball off the track: a hard knock on a deflector, a few skittering bounces over the frets
    that come quicker and softer, then it rolls round in the pocket ring and stops."""
    x = np.zeros(int(2.8 * RATE))
    at = 0.0
    gap = 0.32
    amp = 1.0
    for k in range(13):
        base = rng.uniform(2600, 4200) if k else 1800
        tick = partials(0.06, [base, base * 1.7, base * 2.6], [0.012, 0.008, 0.005], [1.0, 0.5, 0.3], 0.02)
        place(x, tick * amp, at * RATE, wrap=False)
        at += gap
        gap *= rng.uniform(0.72, 0.86)
        amp *= 0.86
    n = int(0.7 * RATE)
    roll = band(rng.standard_normal(n), 2000, 6000, circular=False) * np.exp(-_t(n) / 0.25) * 0.25
    place(x, roll, at * RATE, wrap=False)
    return fade_ends(x, fade_out=0.15)


def ball_rest():
    """The ball's last knock into its pocket."""
    x = partials(0.15, [2100, 3500, 5200], [0.02, 0.012, 0.008], [1.0, 0.5, 0.25], 0.01)
    return fade_ends(x + thump(0.15, 240, 0.02) * 0.4, fade_out=0.04)


def felt_chip():
    """A chip set down on the felt: soft, two small clacks as it settles on another."""
    x = np.zeros(int(0.2 * RATE))
    place(x, clack(rng.uniform(2200, 2600), 0.8), 0, wrap=False)
    place(x, clack(rng.uniform(2600, 3000), 0.35), 0.035 * RATE, wrap=False)
    return fade_ends(band(x, 300, 7000, circular=False), fade_out=0.03)


def call_bell():
    """The croupier's call bell on the table rail: one bright ring (no voice)."""
    base = 2350.0
    x = partials(1.4, [base, base * 2.32, base * 4.1, base * 0.5], [0.7, 0.35, 0.18, 0.4], [1.0, 0.45, 0.2, 0.15], 0.002)
    return fade_ends(x, fade_out=0.3)


def pushed_chips(count=14):
    """A stack of chips pushed across the felt to the winner: a long run of clacks and a slide."""
    x = np.zeros(int(1.0 * RATE))
    at = 0.0
    for k in range(count):
        place(x, clack(rng.uniform(2200, 3100), rng.uniform(0.5, 1.0)), at * RATE, wrap=False)
        at += rng.uniform(0.018, 0.05)
    n = int(0.6 * RATE)
    slide = band(rng.standard_normal(n), 700, 3500, circular=False) * np.exp(-((_t(n) - 0.25) / 0.15) ** 2) * 0.25
    place(x, slide, 0.05 * RATE, wrap=False)
    return fade_ends(x, fade_out=0.1)


def rake():
    """The croupier's rake drawing the lost chips off the felt: a brushy sweep, a few clacks."""
    n = int(0.8 * RATE)
    t = _t(n)
    sweep = band(rng.standard_normal(n), 400, 2500, circular=False) * np.exp(-((t - 0.3) / 0.18) ** 2) * 0.6
    x = sweep.copy()
    for k in range(5):
        place(x, clack(rng.uniform(2000, 2800), 0.4), (0.25 + k * 0.05) * RATE, wrap=False)
    return fade_ends(x, fade_out=0.1)


# ---------------------------------------------------------------- the machines

def lever():
    """The lever pulled: the ratchet's teeth, the spring stretching, a heavy clunk at the bottom."""
    x = np.zeros(int(0.7 * RATE))
    at = 0.0
    for k in range(9):
        tooth = partials(0.03, [1700 + k * 40, 3100], [0.006, 0.004], [1.0, 0.4], 0.02)
        place(x, tooth * 0.6, at * RATE, wrap=False)
        at += 0.028
    n = int(0.3 * RATE)
    spring = np.sin(2 * np.pi * (300 + 900 * _t(n)) * _t(n)) * np.exp(-_t(n) / 0.12) * 0.15
    place(x, spring, 0.05 * RATE, wrap=False)
    place(x, thump(0.25, 95, 0.05) * 1.2, 0.27 * RATE, wrap=False)
    place(x, partials(0.3, [620, 1450, 2900], [0.08, 0.05, 0.03], [0.6, 0.35, 0.2], 0.01), 0.27 * RATE, wrap=False)
    return fade_ends(x, fade_out=0.08)


def reels():
    """The three reels running: a mechanical whirr with the detents clicking past (seamless loop)."""
    secs = 1.0
    n = int(secs * RATE)
    t = _t(n)
    whirr = band(coloured(n, 0.8), 300, 2600) * (0.7 + 0.3 * np.sin(2 * np.pi * 30 * t) ** 2)
    x = whirr * 0.35
    for rate, base in ((24, 2200), (27, 2500), (21, 1900)):  # each reel's detents, slightly apart
        for k in range(rate):
            tick = partials(0.02, [base, base * 1.8], [0.004, 0.003], [1.0, 0.4], 0.03)
            place(x, tick * 0.35, int((k / rate + rng.uniform(0, 0.01)) * n))
    return [x, np.roll(x, int(0.013 * RATE))]


def reel_stop():
    """A reel stopping: a metallic clunk with a short ring of the cast frame."""
    x = thump(0.3, 140, 0.035) * 1.0
    x += partials(0.3, [900, 2100, 3800], [0.09, 0.05, 0.03], [0.5, 0.3, 0.15], 0.01)
    return fade_ends(x, fade_out=0.06)


def coin():
    """A coin dropping into the metal payout cup: a bright clink and a little rattle."""
    x = np.zeros(int(0.35 * RATE))
    base = rng.uniform(4200, 5200)
    place(x, partials(0.3, [base, base * 1.38, base * 2.05], [0.08, 0.05, 0.03], [1.0, 0.6, 0.35], 0.02), 0, wrap=False)
    for k in range(3):
        place(x, partials(0.05, [base * 1.1], [0.01], [0.3 / (k + 1)], 0.05), (0.06 + k * 0.035) * RATE, wrap=False)
    return fade_ends(x, fade_out=0.05)


def win_bell():
    """The machine's bell rung by the payout mechanism: a quick run of strokes on a small gong bell."""
    x = np.zeros(int(1.8 * RATE))
    base = 1560.0
    for k in range(7):
        ring = partials(0.9, [base, base * 2.4, base * 3.9], [0.5, 0.25, 0.12], [1.0, 0.4, 0.2], 0.003)
        place(x, ring * (1.0 if k == 0 else 0.6), (k * 0.11) * RATE, wrap=False)
    return fade_ends(x, fade_out=0.4)


# ---------------------------------------------------------------- the card table

def reveal():
    """Hole cards turned over at the showdown: two quick flips onto the baize."""
    x = np.zeros(int(0.45 * RATE))
    for at in (0.0, 0.16):
        n = int(0.12 * RATE)
        flip = band(rng.standard_normal(n), 1500, 6000, circular=False) * np.exp(-_t(n) / 0.02)
        place(x, flip, at * RATE, wrap=False)
        place(x, card_tick(0.8), (at + 0.06) * RATE, wrap=False)
    return fade_ends(x, fade_out=0.05)


MAKERS = {
    "ambience/gaming_room": (gaming_room, 0.4),
    "gaming/laugh": (laugh, 0.5),
    "gaming/chips_stack": (chips_stack, 0.5),
    "gaming/shuffle": (lambda: riffle(0.7), 0.5),
    "gaming/glass": (glass, 0.45),
    "gaming/chair": (chair, 0.5),
    "roulette/spin": (spin, 0.55),
    "roulette/ball_drop": (ball_drop, 0.6),
    "roulette/ball_rest": (ball_rest, 0.55),
    "roulette/chips": (felt_chip, 0.55),
    "roulette/cue": (call_bell, 0.45),
    "roulette/win": (lambda: pushed_chips(16), 0.6),
    "roulette/lose": (rake, 0.5),
    "slots/lever": (lever, 0.65),
    "slots/reels": (reels, 0.45),
    "slots/stop": (reel_stop, 0.65),
    "slots/coin": (coin, 0.5),
    "slots/bell": (win_bell, 0.5),
    "poker/shuffle": (lambda: riffle(0.8), 0.5),
    "poker/pot": (lambda: pushed_chips(12), 0.55),
    "poker/reveal": (reveal, 0.5),
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
