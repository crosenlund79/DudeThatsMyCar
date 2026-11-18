# Packaged audio — Chicago, 1932

The full catalogue (logical names, override paths, loops, buses) is generated in `docs/ASSET_SPECS.md`;
the override rules are in `assets/README.md`. Your own sounds go in `custom/audio/<logical name>.ogg`
(or `.wav` / `.mp3`), in the project or next to the exported game, and replace these after a restart.

## The user's recordings

The originals in `_inbox/` are never modified, and `_inbox/` is ignored by Godot (`.gdignore`), so the
old HyperCars recordings there are not imported or used by this game.

| Original in `_inbox/` | SHA-256 of the original | Shipped as | Logical name |
| --- | --- | --- | --- |
| `Danny Dimes Mercer - Opening Monologue.mp3` | `18d93b867f707cf5278b8a4fcc8ace44f4ec16b3c0b99a34f98ae261277d7b87` | `voice/danny_opening.mp3` — a byte-for-byte copy (same SHA-256), unaltered | `voice/danny_opening` |
| `Copper Owl Bird - Leave the lights low.mp3` | `db4654ab4afdb3d7e2f161f0e21bddc2a6257d2e1b6fa339222bafb445873933` | `music/copper_owl_jazz.ogg` — the cleaned version below | `music/copper_owl_jazz` |

### The people's voices (M006)

| Original in `_inbox/` | SHA-256 of the original | Shipped as (byte-for-byte copy) | Length | Loudness (EBU R128) / true peak | Gain at playback |
| --- | --- | --- | --- | --- | --- |
| `Augie Bartender - Greeting when first meeting.mp3` | `e62d1661f52a714b60f2ca65b646559f9627896a595df65e35a813e64c77298e` | `voice/augie_greeting.mp3` | 9.48 s | −18.9 LUFS / −3.8 dBFS | −0.1 dB |
| `Rourke The Boss - Greeting when first meeting.mp3` | `8ef37a018821a8539eb9fe5b97f83053e1351aa2be66dcce34dfbc94945c8cf9` | `voice/rourke_greeting.mp3` | 21.39 s | −17.4 LUFS / −1.6 dBFS | −1.6 dB |
| `Eddie Gun Dealer - Greeting when first meeting.mp3` | `c03f3f246bb1d23124ce4e4af2980ed90d6a41a5c09e4479031b24d825414877` | `voice/eddie_greeting.mp3` | 11.08 s | −18.0 LUFS / −2.9 dBFS | −1.0 dB |
| `Eddie Gun Dealer - Greeting when accessing his sales.mp3` | `90b3420fec7f38efeb952b09f0127c072930800b9dc8b5993de9dba88d9fac1d` | `voice/eddie_sales.mp3` | 4.52 s | −17.3 LUFS / −3.2 dBFS | −1.7 dB |
| `The Bird Singer - Greeting when first meeting.mp3` | `b1cdb6e917aa9eca92fb671cabbf4657acc98e0d6617c6ae0ea6cbbbf8daffea` | `voice/bird_greeting.mp3` | 12.43 s | −19.1 LUFS / −4.3 dBFS | +0.1 dB |
| `The Bird Singer - Interrupted on stage.mp3` | `8db95904c189030f98c8f9a8fb7b7675ce647dc4dc6aa0ae5f0fd2f510f12c28` | `voice/bird_interrupted.mp3` | 9.80 s | −19.6 LUFS / −3.6 dBFS | +0.6 dB |

All six are MP3, mono, 44.1 kHz, about 140 kbit/s, and start and end on the voice (no silence to trim).
They were already within 2.3 LU of each other, so they ship unaltered (no second lossy encoding) and
the game evens them out to about −19 LUFS with the small gain above (`VoiceLines.LINES[...].gain_db`).
Their transcripts (the dialogue text shown while they play) were made with faster-whisper `small.en` and
`medium.en`, which agreed word for word.

### Danny's monologue

MP3, mono, 44.1 kHz, 23.41 s. Shipped exactly as recorded. The opening's subtitles were transcribed from
it with two speech-recognition models (faster-whisper `small.en` and `medium.en`), which agreed word for
word; the cue times come from their word timestamps. They are shown only while the shipped recording
plays (an override in `custom/audio/voice/` plays without them).

### The Copper Owl's song: how it was cleaned

The original (MP3, stereo, 48 kHz, 320 kbit/s, 261.22 s) was inspected frame by frame (RMS and peak per
0.1–0.25 s, decoded with FFmpeg 6.1.1):

| Time in the original | What is there |
| --- | --- |
| 0.00–0.90 s | digital silence |
| ~0.90–1.05 s | the faint onset, then the first attack at ~1.05 s |
| 248.0 s | the final chord, decaying naturally |
| 253.25 s | the decay at about −32 dB RMS |
| 254.75 s | the decay at about −66 dB RMS (the music is over) |
| ~254.9–255.9 s | low hiss (−67 to −72 dB) |
| **256.0–256.9 s** | **a loud stray burst (about −15 to −20 dB RMS, peaks 0.48): the unwanted noise** |
| 257.0–261.2 s | near-silence, then digital silence |

The burst correlates strongly (0.82) with the song's own opening bars: a stray fragment, not part of the
performance. Cleaning trims it away completely, with a short fade over the end of the natural decay so
the cut is inaudible:

```bash
ffmpeg -i "assets/audio/_inbox/Copper Owl Bird - Leave the lights low.mp3" \
  -af "atrim=start=0.6:end=254.75,asetpts=PTS-STARTPTS,afade=t=out:st=253.15:d=1.0" \
  -ar 48000 -ac 2 -c:a libvorbis -q:a 8 -map_metadata -1 assets/audio/music/copper_owl_jazz.ogg
```

- **Trim at the start:** 0.60 s of digital silence removed (0.30 s of silence and the faint onset are
  kept before the first attack, a natural breath when the song comes round again).
- **Trim at the end:** everything after **254.75 s** of the original is removed: the hiss and the burst
  never play.
- **Fade-out:** linear, **1.0 s**, from **253.75 s to 254.75 s of the original** (253.15–254.15 s of the
  shipped file), over the last of the natural decay (−39 dB at its start).
- **Nothing else** is changed: no equalisation, compression, filtering or level change. The muffling
  heard outside the club is done live by the game (a low-pass on its own bus), not in the file.
- **Format:** OGG Vorbis, quality 8 (about 200 kbit/s), stereo, 48 kHz, **254.15 s**, 6.4 MB.

Checked after encoding: the last 0.4 s peak at 0.0027 (below −51 dBFS), falling to about −80 dB RMS at the very end; the
first 0.25 s are digital silence; the step between the last and the first sample (where the loop joins)
is 0.0000055 (about −105 dB), so the loop cannot click; peak level 0.993 (no clipping added). The game
loops the whole file; the join is the song ending in silence and starting again after a short breath.

## Templates

Everything else here is a Claude-made `template_` sound: the M002 effects (`tools/template_audio/make_audio.py`),
the HyperCars engine, tyre and impact sounds, and the M005 ambience and place sounds
(`tools/template_audio/make_ambience.py`). Replace any of them through `custom/audio/`.
