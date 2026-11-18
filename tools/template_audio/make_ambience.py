"""Synthesises the M005 template_ ambience and place sounds (numpy + ffmpeg, deterministic):
    python3 tools/template_audio/make_ambience.py assets/audio
Loops are built in the frequency domain on a circular buffer, so they repeat without a seam.
Writes OGG Vorbis (ffmpeg with libvorbis): ambience/template_street_night.ogg, ambience/template_alley.ogg,
ambience/template_river.ogg, ambience/template_club_crowd.ogg (stereo loops); ambience/template_horn.ogg,
ambience/template_foghorn.ogg, ambience/template_clatter.ogg, places/template_door.ogg,
places/template_shop_bell.ogg, places/template_register.ogg, places/template_bottles.ogg,
vehicles/template_door.ogg (mono one-shots); M006: music/template_record_scratch.ogg (its own seed;
`make_ambience.py assets/audio music/record_scratch` writes it alone).
Replace any of them by dropping an OGG / WAV / MP3 into custom/audio/<same logical name>."""
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np

RATE = 44100
rng = np.random.default_rng(1932005)


# ---------------------------------------------------------------- helpers

def spectrum_filter(x, mask_fn, circular=True):
    """Filters x through a magnitude mask given as a function of frequency (Hz).
    Circular: the result wraps (for loops); otherwise x is zero-padded first."""
    n = len(x)
    m = n if circular else int(2 ** np.ceil(np.log2(n * 2)))
    spec = np.fft.rfft(x, m)
    f = np.fft.rfftfreq(m, 1.0 / RATE)
    y = np.fft.irfft(spec * mask_fn(f), m)
    return y[:n]


def butter(f, lo=None, hi=None, order=2):
    g = np.ones_like(f)
    if hi is not None:
        g = g / np.sqrt(1 + (f / hi) ** (2 * order))
    if lo is not None:
        ff = np.maximum(f, 1e-3)
        g = g / np.sqrt(1 + (lo / ff) ** (2 * order))
    return g


def band(x, lo=None, hi=None, order=2, circular=True):
    return spectrum_filter(x, lambda f: butter(f, lo, hi, order), circular)


def coloured(n, slope):
    """Noise with power falling as 1/f**slope (0 white, 1 pink, 2 brown); circular."""
    spec = np.fft.rfft(rng.standard_normal(n))
    f = np.maximum(np.fft.rfftfreq(n, 1.0 / RATE), 20.0)
    y = np.fft.irfft(spec / f ** (slope / 2), n)
    return y / np.std(y)


def peaks(f, centres, width):
    """Resonant peaks (formants, body resonances) as a spectral mask."""
    g = np.full_like(f, 0.05)
    for c, gain in centres:
        g = g + gain / (1 + ((f - c) / width) ** 2)
    return g


def place(buf, snd, at, wrap=True):
    """Adds snd into buf starting at sample `at` (wrapping round the end for loops)."""
    n = len(buf)
    k = len(snd)
    at = int(at) % n if wrap else int(at)
    end = min(n, at + k)
    buf[at:end] += snd[:end - at]
    if wrap and at + k > n:
        buf[:at + k - n] += snd[n - at:]


def periodic(n, cycles_and_gains, phase_seed=0.0):
    """A slow modulation that repeats exactly over n samples."""
    t = np.arange(n) / n
    y = np.zeros(n)
    for i, (cycles, gain) in enumerate(cycles_and_gains):
        y += gain * np.sin(2 * np.pi * cycles * t + phase_seed + i * 1.7)
    return y


def env(n, attack, decay):
    t = np.arange(n) / RATE
    return np.minimum(1.0, t / max(attack, 1e-4)) * np.exp(-t / decay)


def partials(dur, freqs, decays, gains, detune=0.0):
    n = int(dur * RATE)
    t = np.arange(n) / RATE
    y = np.zeros(n)
    for f, d, g in zip(freqs, decays, gains):
        f = f * (1 + rng.uniform(-detune, detune))
        y += g * np.sin(2 * np.pi * f * t + rng.uniform(0, 2 * np.pi)) * np.exp(-t / d)
    return y * np.minimum(1.0, t / 0.0008)


def click(dur=0.012, bright=2500, gain=1.0):
    n = int(dur * RATE)
    burst = rng.standard_normal(n) * np.exp(-np.arange(n) / (0.0018 * RATE))
    return band(burst, lo=bright * 0.5, hi=bright * 2.5, circular=False) * gain


def thump(dur, freq, decay, gain=1.0):
    n = int(dur * RATE)
    t = np.arange(n) / RATE
    body = np.sin(2 * np.pi * (freq * (1 + 0.6 * np.exp(-t / 0.01))) * t) * np.exp(-t / decay)
    knock = band(rng.standard_normal(n), hi=freq * 4, circular=False) * np.exp(-t / (decay * 0.4)) * 0.4
    return (body + knock) * gain * np.minimum(1.0, t / 0.001)


def echo(x, taps, hi=3000.0, circular=True):
    """Early reflections: delayed, darker copies (wrapping for loops)."""
    out = x.copy()
    dark = band(x, hi=hi, circular=circular)
    for delay, gain in taps:
        d = int(delay * RATE)
        if circular:
            out += np.roll(dark, d) * gain
        elif d < len(x):
            out[d:] += dark[:-d] * gain
    return out


def tail(x, seconds):
    return np.concatenate([x, np.zeros(int(seconds * RATE))])


def fade_ends(x, fade_in=0.002, fade_out=0.03):
    n = len(x)
    i = np.arange(n)
    return x * np.minimum(1.0, i / max(1, fade_in * RATE)) * np.minimum(1.0, (n - 1 - i) / max(1, fade_out * RATE))


def write_ogg(path, channels, peak, quality=5):
    """Normalises to `peak` and encodes OGG Vorbis through ffmpeg (channels: list of arrays)."""
    data = np.stack(channels, axis=1)
    data = data / max(1e-9, np.max(np.abs(data))) * peak
    pcm = (np.clip(data, -1, 1) * 32767).astype(np.int16)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav_path = os.path.join(tmp, "in.wav")
        with wave.open(wav_path, "wb") as w:
            w.setnchannels(pcm.shape[1])
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(pcm.tobytes())
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav_path, "-c:a", "libvorbis", "-q:a", str(quality),
                        "-map_metadata", "-1", "-fflags", "+bitexact", path], check=True)
    print(path, f"{len(data) / RATE:.2f}s", f"{pcm.shape[1]}ch")


def stereo(common, left, right, width):
    """Two channels sharing `common` and differing by `width` of their own noise."""
    return [common * (1 - width) + left * width, common * (1 - width) + right * width]


# ---------------------------------------------------------------- loops

def street_night():
    """The city at night beyond the next corner: a low traffic rumble that
    swells and settles, a couple of far-off cars passing, the air of the street."""
    n = int(14.0 * RATE)
    swell = 1.0 + periodic(n, [(2, 0.22), (5, 0.12), (9, 0.06)])
    chans = []
    for side in range(2):
        rumble = band(coloured(n, 2.0), lo=35, hi=420) * swell
        air = band(coloured(n, 1.0), lo=1800, hi=6000) * 0.05
        chans.append((rumble, air))
    common = band(coloured(n, 1.6), lo=45, hi=700) * swell
    out = []
    for side, (rumble, air) in enumerate(chans):
        out.append(common * 0.6 + rumble * 0.5 + air)
    # two distant cars going by, panned across
    for start, dur, left_to_right in ((2.0, 4.5, True), (8.6, 4.0, False)):
        k = int(dur * RATE)
        t = np.arange(k) / k
        shape = np.sin(np.pi * t) ** 2
        motor = band(coloured(k, 1.5), lo=60, hi=500, circular=False)
        hum = np.sin(2 * np.pi * np.cumsum(70 + 18 * shape) / RATE) * 0.35
        car = (motor + hum) * shape * 0.55
        pan = t if left_to_right else 1 - t
        place(out[0], car * np.sqrt(1 - pan), start * RATE)
        place(out[1], car * np.sqrt(pan), start * RATE)
    return out


def alley():
    """A back alley: much quieter, the city a murmur behind the walls, water
    dripping from a fire escape into a puddle, slapping back off the brick."""
    n = int(12.0 * RATE)
    murmur = band(coloured(n, 2.0), lo=30, hi=260) * (1.0 + periodic(n, [(3, 0.15), (7, 0.08)])) * 0.35
    out = [murmur + band(coloured(n, 1.0), lo=900, hi=4000) * 0.015 for _ in range(2)]
    drip_times = [0.4, 1.55, 2.3, 3.9, 4.6, 5.95, 7.2, 7.75, 9.1, 10.4, 11.3]
    for i, at in enumerate(drip_times):
        k = int(0.09 * RATE)
        t = np.arange(k) / RATE
        f0 = rng.uniform(1100, 2300)
        freq = f0 * (1 + 1.2 * np.minimum(1.0, t / 0.012))  # the "plip" rises
        drop = np.sin(2 * np.pi * np.cumsum(freq) / RATE) * np.exp(-t / rng.uniform(0.012, 0.025))
        drop *= rng.uniform(0.25, 0.6)
        drop = echo(tail(drop, 0.2), [(0.045, 0.35), (0.09, 0.18), (0.16, 0.08)], hi=2500, circular=False)
        pan = rng.uniform(0.25, 0.75)
        place(out[0], drop * np.sqrt(1 - pan), at * RATE)
        place(out[1], drop * np.sqrt(pan), at * RATE)
    return out


def river():
    """The river at the quay: water slapping against the stone, a low gurgle,
    and a factory's drone from the far bank."""
    n = int(14.0 * RATE)
    out = []
    for side in range(2):
        water = band(coloured(n, 1.0), lo=180, hi=1400)
        laps = np.zeros(n)
        at = rng.uniform(0, 0.4)
        while at < 14.0:
            k = int(rng.uniform(0.35, 0.7) * RATE)
            bump = np.sin(np.pi * np.arange(k) / k) ** 3 * rng.uniform(0.4, 1.0)
            place(laps, bump, at * RATE)
            at += rng.uniform(0.55, 1.25)
        gurgle = band(coloured(n, 2.0), lo=60, hi=320) * (0.6 + periodic(n, [(4, 0.2), (11, 0.1)], side))
        out.append(water * (0.15 + laps) * 0.5 + gurgle * 0.4)
    # the drone from across the water: 50 Hz machinery, beating slowly
    t = np.arange(n) / RATE
    drone = (np.sin(2 * np.pi * 50 * t) + 0.6 * np.sin(2 * np.pi * (100 + 1 / 7.0) * t)
             + 0.35 * np.sin(2 * np.pi * (150 + 2 / 7.0) * t) + 0.2 * np.sin(2 * np.pi * 247 * t))
    drone = band(drone, hi=400) * (0.8 + periodic(n, [(1, 0.2)])) * 0.12
    return [out[0] + drone, out[1] + drone * 0.9]


def syllable(dur, f0, formants, breath):
    """One murmured syllable: a buzz at f0 and some breath through two formants."""
    k = int(dur * RATE)
    t = np.arange(k) / RATE
    buzz = np.sign(np.sin(2 * np.pi * f0 * (1 + 0.04 * np.sin(2 * np.pi * 3 * t)) * t)) * 0.5
    src = buzz + rng.standard_normal(k) * breath
    voiced = spectrum_filter(src, lambda f: peaks(f, formants, 110.0), circular=False)
    return voiced * np.hanning(k)


def club_crowd():
    """The Copper Owl's room: a dozen people talking under the band, glasses
    clinking at the bar, footsteps on the boards; the words never quite clear."""
    n = int(16.0 * RATE)
    out = [np.zeros(n), np.zeros(n)]
    vowels = [((700, 1.0), (1200, 0.7)), ((400, 1.0), (2000, 0.5)), ((300, 1.0), (900, 0.6)),
              ((550, 1.0), (1700, 0.6)), ((650, 1.0), (1000, 0.8)), ((350, 1.0), (2300, 0.4))]
    for v in range(12):
        f0 = rng.uniform(95, 135) if v % 3 else rng.uniform(170, 230)
        level = rng.uniform(0.35, 1.0)
        pan = rng.uniform(0.1, 0.9)
        track = np.zeros(n)
        at = rng.uniform(0, 1.5)
        while at < 16.0:
            # a phrase of a few syllables, then a pause (somebody else talks)
            for _ in range(int(rng.integers(3, 9))):
                d = rng.uniform(0.11, 0.26)
                syl = syllable(d, f0 * rng.uniform(0.92, 1.1), vowels[int(rng.integers(len(vowels)))], 0.35)
                place(track, syl * rng.uniform(0.6, 1.0), at * RATE)
                at += d * rng.uniform(0.75, 0.95)
            at += rng.uniform(0.5, 2.2)
        out[0] += track * level * np.sqrt(1 - pan)
        out[1] += track * level * np.sqrt(pan)
    for c in range(2):
        out[c] = band(out[c], lo=120, hi=3200)
        out[c] = echo(out[c], [(0.023, 0.3), (0.041, 0.22), (0.067, 0.15), (0.11, 0.08)], hi=2200)
        out[c] += band(coloured(n, 1.0), lo=200, hi=2500) * 0.02  # room air
    babble_peak = max(np.max(np.abs(out[0])), np.max(np.abs(out[1])))
    # glasses at the bar, now and then a toast
    for at, toast in ((1.2, False), (3.7, True), (6.1, False), (8.4, False), (10.9, True), (13.3, False), (15.1, False)):
        hits = [0.0, 0.07] if toast else [0.0]
        pan = rng.uniform(0.2, 0.8)
        for h in hits:
            base = rng.uniform(2600, 3400)
            clink = partials(0.5, [base, base * 1.51, base * 2.27, base * 2.9], [0.18, 0.12, 0.08, 0.05],
                             [1.0, 0.6, 0.35, 0.2], detune=0.01) * rng.uniform(0.15, 0.3) * babble_peak
            place(out[0], clink * np.sqrt(1 - pan), (at + h) * RATE)
            place(out[1], clink * np.sqrt(pan), (at + h) * RATE)
    # footsteps on the boards, someone crossing the room
    for start, steps, pan0 in ((2.5, 6, 0.2), (9.8, 5, 0.8)):
        for s in range(steps):
            step = thump(0.12, rng.uniform(85, 110), 0.025) * 0.12 * babble_peak
            pan = pan0 + (0.6 if pan0 < 0.5 else -0.6) * s / steps
            place(out[0], step * np.sqrt(1 - pan), (start + s * 0.52) * RATE)
            place(out[1], step * np.sqrt(pan), (start + s * 0.52) * RATE)
    return out


# ---------------------------------------------------------------- one-shots

def horn():
    """A car horn a few streets away: two blasts of a 1930s electric horn."""
    blasts = np.zeros(int(1.1 * RATE))
    for start, dur in ((0.0, 0.22), (0.34, 0.38)):
        k = int(dur * RATE)
        t = np.arange(k) / RATE
        f = 345 * (1 + 0.012 * np.sin(2 * np.pi * 31 * t))
        phase = 2 * np.pi * np.cumsum(f) / RATE
        tone = np.sign(np.sin(phase)) * 0.6 + np.sin(2 * phase) * 0.3 + np.sin(3.02 * phase) * 0.2
        tone *= np.minimum(1.0, t / 0.015) * np.minimum(1.0, (dur - t) / 0.03)
        place(blasts, tone, start * RATE, wrap=False)
    x = spectrum_filter(blasts, lambda f: butter(f, 250, 2200) * peaks(f, [(700, 1.0), (1500, 0.6)], 250.0), circular=False)
    x = echo(tail(x, 0.9), [(0.12, 0.35), (0.26, 0.2), (0.45, 0.1)], hi=1500, circular=False)
    return fade_ends(x)


def foghorn():
    """A tug's steam whistle down the river, low and long."""
    k = int(3.4 * RATE)
    t = np.arange(k) / RATE
    shape = np.minimum(1.0, t / 0.35) * np.clip((3.0 - t) / 0.9, 0.0, 1.0)
    x = np.zeros(k)
    for f, g in ((138, 1.0), (174, 0.7), (276, 0.35), (348, 0.25), (414, 0.12)):
        x += g * np.sin(2 * np.pi * f * (1 + 0.003 * np.sin(2 * np.pi * 0.7 * t)) * t)
    x += band(rng.standard_normal(k), lo=200, hi=900, circular=False) * 0.25
    x = band(x * shape, hi=900, circular=False)
    x = echo(tail(x, 1.5), [(0.35, 0.4), (0.7, 0.25), (1.1, 0.12)], hi=700, circular=False)
    return fade_ends(x, fade_out=0.3)


def clatter():
    """Somewhere down the alley a lid comes off a trash can and rattles to a stop."""
    x = np.zeros(int(1.3 * RATE))
    at = 0.0
    gap = 0.17
    level = 1.0
    while level > 0.06:
        hit = partials(0.25, [1180, 1930, 2870, 4110], [0.06, 0.05, 0.035, 0.025], [1.0, 0.7, 0.5, 0.3], detune=0.03)
        tick = click(0.01, 3000, 0.8)
        hit[:len(tick)] += tick
        place(x, hit * level, at * RATE, wrap=False)
        at += gap
        gap *= 0.72
        level *= 0.7
    x = band(x, hi=3500, circular=False)
    x = echo(tail(x, 0.6), [(0.05, 0.4), (0.11, 0.25), (0.2, 0.12)], hi=2000, circular=False)
    return fade_ends(x)


def door():
    """A shop or club door: the latch, a short creak of the hinges, and it falls to behind you."""
    x = np.zeros(int(1.0 * RATE))
    place(x, click(0.015, 2200, 1.0), 0, wrap=False)
    # creak: stick-slip pulses through the wood
    k = int(0.38 * RATE)
    t = np.arange(k) / RATE
    rate = 70 + 90 * t / t[-1]
    pulses = (np.diff(np.floor(np.cumsum(rate) / RATE), prepend=0) > 0).astype(float)
    creak = spectrum_filter(pulses, lambda f: peaks(f, [(650, 1.0), (1300, 0.6), (2400, 0.3)], 120.0), circular=False)
    creak *= np.sin(np.pi * t / t[-1]) * 0.6
    place(x, creak, 0.05 * RATE, wrap=False)
    place(x, thump(0.3, 95, 0.05, 1.2), 0.56 * RATE, wrap=False)
    place(x, click(0.012, 1800, 0.7), 0.575 * RATE, wrap=False)
    x = echo(x, [(0.02, 0.2), (0.045, 0.1)], hi=2500, circular=False)
    return fade_ends(x)


def shop_bell():
    """The little bell on a spring over a shop door."""
    x = np.zeros(int(1.3 * RATE))
    for at, g in ((0.0, 1.0), (0.085, 0.6), (0.19, 0.4), (0.31, 0.2)):
        ring = partials(0.95, [2350, 2350 * 2.32, 2350 * 4.25, 2350 * 5.4], [0.45, 0.25, 0.12, 0.08],
                        [1.0, 0.5, 0.25, 0.15], detune=0.004)
        place(x, ring * g, at * RATE, wrap=False)
    return fade_ends(x, fade_out=0.15)


def register():
    """A brass cash register: keys, the crank, the bell, the drawer shooting out."""
    x = np.zeros(int(1.5 * RATE))
    for at in (0.0, 0.08, 0.15):
        place(x, click(0.02, 1600, 0.8), at * RATE, wrap=False)
    for i in range(10):  # the mechanism
        place(x, click(0.008, 2600, 0.35), (0.24 + i * 0.022) * RATE, wrap=False)
    ching = partials(0.9, [3150, 3150 * 2.1, 3150 * 2.95, 4400], [0.35, 0.2, 0.12, 0.25], [1.0, 0.45, 0.25, 0.4], detune=0.003)
    place(x, ching * 1.4, 0.5 * RATE, wrap=False)
    k = int(0.18 * RATE)
    slide = band(rng.standard_normal(k), lo=800, hi=3000, circular=False) * np.linspace(0.1, 0.5, k)
    place(x, slide, 0.52 * RATE, wrap=False)
    place(x, thump(0.25, 120, 0.04, 1.0), 0.7 * RATE, wrap=False)
    return fade_ends(x, fade_out=0.1)


def bottles():
    """Bottles knocking together in a crate, and the rye sloshing."""
    x = np.zeros(int(0.9 * RATE))
    for at, g in ((0.0, 1.0), (0.1, 0.7), (0.16, 0.5), (0.33, 0.35)):
        base = rng.uniform(1700, 2300)
        glass = partials(0.4, [base, base * 1.73, base * 2.61, base * 3.9], [0.12, 0.08, 0.05, 0.03], [1.0, 0.6, 0.4, 0.2], 0.01)
        place(x, glass * g, at * RATE, wrap=False)
    k = int(0.5 * RATE)
    slosh = band(rng.standard_normal(k), lo=150, hi=900, circular=False)
    slosh *= np.abs(np.sin(2 * np.pi * 7 * np.arange(k) / RATE)) * np.hanning(k) * 0.25
    place(x, slosh, 0.05 * RATE, wrap=False)
    return fade_ends(x, fade_out=0.08)


def car_door():
    """A heavy 1930s car door: the handle, then the solid clunk of steel on steel."""
    x = np.zeros(int(0.9 * RATE))
    place(x, click(0.015, 2000, 0.7), 0, wrap=False)
    place(x, click(0.012, 1400, 0.5), 0.07 * RATE, wrap=False)
    clunk = thump(0.45, 72, 0.07, 1.4)
    clunk += partials(0.45, [240, 410, 1150, 2300], [0.05, 0.04, 0.02, 0.012], [0.5, 0.35, 0.2, 0.12])
    place(x, clunk, 0.32 * RATE, wrap=False)
    place(x, click(0.01, 2600, 0.6), 0.335 * RATE, wrap=False)
    return fade_ends(x, fade_out=0.08)


def record_scratch():
    """M006: the needle dragged across the record - the band's music grinding to a halt:
    a fast downward rip of the stopped music, a scrape of surface noise, a last thump."""
    srng = np.random.default_rng(1932006)
    n = int(0.75 * RATE)
    t = np.arange(n) / RATE
    # the music's pitch dragged down and back: a buzzy tone whose frequency swoops
    f = 900 * np.exp(-t / 0.09) + 140 + 420 * np.exp(-((t - 0.16) / 0.05) ** 2)
    phase = 2 * np.pi * np.cumsum(f) / RATE
    tone = (np.sign(np.sin(phase)) * 0.5 + np.sin(phase * 2) * 0.3) * np.exp(-t / 0.22)
    scrape = srng.standard_normal(n)
    scrape = spectrum_filter(scrape, lambda fr: butter(fr, 700, 5000), circular=False) * np.exp(-t / 0.18) * 0.8
    crackle = (srng.random(n) > 0.997).astype(float) * srng.uniform(-1, 1, n) * 0.6
    x = tone * 0.8 + scrape + crackle
    x[int(0.42 * RATE):int(0.42 * RATE) + len(thump(0.2, 70, 0.03))] += thump(0.2, 70, 0.03, 0.7)
    return fade_ends(band(x, 60, 7000, circular=False), fade_out=0.08)


def punch(landed):
    """M007: a fist in a fistfight. Landed: a hard slap of knuckles on a jaw with a body
    thump under it. Taken: a duller blow to the ribs with the breath knocked out (no voice)."""
    srng = np.random.default_rng(1932007 + (1 if landed else 2))
    n = int(0.45 * RATE)
    t = np.arange(n) / RATE
    noise = srng.standard_normal(n)
    if landed:
        slap = band(noise, 900, 5000, circular=False) * np.exp(-t / 0.012) * 1.2
        body = thump(0.45, 95, 0.05, 1.0)
        x = slap + body * 0.9
    else:
        body = thump(0.45, 70, 0.08, 1.2)
        cloth = band(noise, 300, 1800, circular=False) * np.exp(-t / 0.03) * 0.5
        breath = band(srng.standard_normal(n), 400, 2500, circular=False) * np.exp(-((t - 0.12) / 0.06) ** 2) * 0.25
        x = body + cloth + breath
    return fade_ends(echo(x, [(0.03, 0.15), (0.06, 0.08)], hi=2500, circular=False), fade_out=0.05)


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "assets/audio"
    only = sys.argv[2] if len(sys.argv) > 2 else ""
    if only:
        # one sound only (the rest stay as they are): python3 make_ambience.py assets/audio music/record_scratch
        makers = {"music/record_scratch": record_scratch, "fight/punch_landed": lambda: punch(True),
                  "fight/punch_taken": lambda: punch(False)}
        write_ogg(os.path.join(root, os.path.dirname(only), "template_" + os.path.basename(only) + ".ogg"),
                  [makers[only]()], 0.7)
        return
    write_ogg(os.path.join(root, "ambience/template_street_night.ogg"), street_night(), 0.5)
    write_ogg(os.path.join(root, "ambience/template_alley.ogg"), alley(), 0.5)
    write_ogg(os.path.join(root, "ambience/template_river.ogg"), river(), 0.5)
    write_ogg(os.path.join(root, "ambience/template_club_crowd.ogg"), club_crowd(), 0.5)
    write_ogg(os.path.join(root, "ambience/template_horn.ogg"), [horn()], 0.6)
    write_ogg(os.path.join(root, "ambience/template_foghorn.ogg"), [foghorn()], 0.6)
    write_ogg(os.path.join(root, "ambience/template_clatter.ogg"), [clatter()], 0.5)
    write_ogg(os.path.join(root, "places/template_door.ogg"), [door()], 0.6)
    write_ogg(os.path.join(root, "places/template_shop_bell.ogg"), [shop_bell()], 0.45)
    write_ogg(os.path.join(root, "places/template_register.ogg"), [register()], 0.55)
    write_ogg(os.path.join(root, "places/template_bottles.ogg"), [bottles()], 0.5)
    write_ogg(os.path.join(root, "vehicles/template_door.ogg"), [car_door()], 0.7)
    write_ogg(os.path.join(root, "music/template_record_scratch.ogg"), [record_scratch()], 0.7)
    write_ogg(os.path.join(root, "fight/template_punch_landed.ogg"), [punch(True)], 0.7)
    write_ogg(os.path.join(root, "fight/template_punch_taken.ogg"), [punch(False)], 0.7)


if __name__ == "__main__":
    main()
