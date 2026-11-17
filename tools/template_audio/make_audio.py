"""Synthesises the template_ sound effects added in M002 (numpy, deterministic):
    python3 tools/template_audio/make_audio.py assets/audio
Writes 16-bit mono WAVs: weapons/template_pistol_shot.wav, weapons/template_pistol_reload.wav,
weapons/template_bullet_impact.wav, police/template_whistle.wav.
Replace any of them by dropping an OGG / WAV / MP3 into custom/audio/<same logical name>."""
import os
import sys
import wave

import numpy as np

RATE = 44100
rng = np.random.default_rng(1932)


def lowpass(x, cutoff):
    """One-pole low-pass filter."""
    a = np.exp(-2 * np.pi * cutoff / RATE)
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def env(n, attack, decay):
    t = np.arange(n) / RATE
    e = np.minimum(1.0, t / max(attack, 1e-4)) * np.exp(-t / decay)
    return e


def write(path, x, peak=0.89):
    x = x / max(1e-9, np.max(np.abs(x))) * peak
    data = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print(path, f"{len(x) / RATE:.2f}s")


def pistol_shot():
    """A .45 automatic in a brick street: sharp crack, chesty boom, slapback off the walls, tail."""
    n = int(0.9 * RATE)
    t = np.arange(n) / RATE
    noise = rng.standard_normal(n)
    crack = highpass(noise, 1800) * env(n, 0.0002, 0.006) * 1.6
    body = lowpass(noise, 900) * env(n, 0.001, 0.045) * 2.2
    thump = np.sin(2 * np.pi * (95 - 40 * t) * t) * env(n, 0.001, 0.07) * 0.9
    tail = lowpass(noise, 1400) * env(n, 0.02, 0.28) * 0.35
    dry = crack + body + thump + tail
    out = dry.copy()
    for delay, gain in ((0.085, 0.38), (0.16, 0.2), (0.27, 0.1)):  # slapback from the street walls
        d = int(delay * RATE)
        out[d:] += lowpass(dry[:-d], 2500) * gain
    return out * np.minimum(1.0, (n - np.arange(n)) / (0.05 * RATE))


def click(n, at, freq, length=0.012, gain=1.0):
    s = int(at * RATE)
    k = int(length * RATE)
    burst = rng.standard_normal(k) * np.exp(-np.arange(k) / (0.0025 * RATE))
    ring = np.sin(2 * np.pi * freq * np.arange(k) / RATE) * np.exp(-np.arange(k) / (0.004 * RATE))
    x = np.zeros(n)
    x[s:s + k] += (highpass(burst, 1200) * 0.8 + ring * 0.5) * gain
    return x


def pistol_reload():
    """Magazine out, magazine in, slide racked."""
    n = int(0.75 * RATE)
    x = click(n, 0.02, 2300, gain=0.6) + click(n, 0.05, 1800, gain=0.4)      # release, mag drops
    x += click(n, 0.33, 1500, length=0.02, gain=1.0)                          # mag seated
    x += click(n, 0.55, 2600, gain=0.7) + click(n, 0.6, 2100, length=0.02, gain=1.0)  # slide back and home
    return x


def bullet_impact():
    """A round smacking into brick: thud, crumble of grit."""
    n = int(0.35 * RATE)
    noise = rng.standard_normal(n)
    thud = lowpass(noise, 700) * env(n, 0.0005, 0.03) * 2.0
    snap = highpass(noise, 3000) * env(n, 0.0002, 0.004)
    grit = np.zeros(n)
    for k in range(18):
        at = int(rng.uniform(0.01, 0.25) * RATE)
        ln = int(0.006 * RATE)
        if at + ln < n:
            grit[at:at + ln] += highpass(rng.standard_normal(ln), 2000) * rng.uniform(0.05, 0.25) * np.exp(-np.arange(ln) / (0.0015 * RATE))
    return thud + snap + grit


def whistle():
    """A beat cop's pea whistle: two shrill, trilling blasts."""
    n = int(1.15 * RATE)
    t = np.arange(n) / RATE
    x = np.zeros(n)
    for start, length in ((0.0, 0.42), (0.55, 0.55)):
        s, e = int(start * RATE), int((start + length) * RATE)
        tt = t[s:e] - start
        flutter = 1.0 + 0.035 * np.sign(np.sin(2 * np.pi * 26 * tt)) * 0.5 + 0.02 * np.sin(2 * np.pi * 26 * tt)
        freq = 2850 * flutter
        phase = 2 * np.pi * np.cumsum(freq) / RATE
        tone = np.sin(phase) + 0.25 * np.sin(2 * phase) + 0.08 * rng.standard_normal(len(tt))
        amp = np.minimum(1.0, tt / 0.03) * np.minimum(1.0, (length - tt) / 0.05) * (0.8 + 0.2 * np.sin(2 * np.pi * 26 * tt))
        x[s:e] += tone * amp
    return lowpass(x, 6000)


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "assets/audio"
    write(os.path.join(root, "weapons/template_pistol_shot.wav"), pistol_shot())
    write(os.path.join(root, "weapons/template_pistol_reload.wav"), pistol_reload(), 0.6)
    write(os.path.join(root, "weapons/template_bullet_impact.wav"), bullet_impact(), 0.7)
    write(os.path.join(root, "police/template_whistle.wav"), whistle(), 0.55)


if __name__ == "__main__":
    main()
