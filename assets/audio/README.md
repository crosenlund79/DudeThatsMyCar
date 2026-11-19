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

### The Copper Owl's back rooms (M011)

Synthesised in numpy by `tools/template_audio/make_gaming.py` (no recordings, no samples, nothing downloaded),
OGG Vorbis, 44.1 kHz. Each plays from its packaged `template_` file unless you put your own at the override
path: `custom/audio/<logical name>.ogg` (or `.wav` / `.mp3`), in the project folder while developing or next
to an exported Windows/Linux game; restart the game to hear it. A missing or unreadable override falls back
to the template. Loops repeat the whole file (make both ends meet); one-shots should start on the sound.

| Logical name (packaged file: `assets/audio/<dir>/template_<name>.ogg`) | Loop | Bus | Length (template / recommended) | Used for |
| --- | --- | --- | --- | --- |
| `ambience/gaming_room` | yes | Ambience | 24 s stereo / 15-60 s | The back rooms' bed (card room and gaming room): room tone, quiet voices (no words), a chip or card now and then. Only heard inside the back rooms. Keep it low and even. |
| `gaming/laugh` | no | Ambience | 1.2 s / under 2 s | A laugh across the room (no words), now and then at a spot in the room. |
| `gaming/chips_stack` | no | Ambience | 0.9 s / under 1.5 s | Somebody stacking chips. |
| `gaming/shuffle` | no | Ambience | 1.2 s / under 2 s | A riffle shuffle somewhere in the room. |
| `gaming/glass` | no | Ambience | 1.0 s / under 1.5 s | Glasses touching, one set down. |
| `gaming/chair` | no | Ambience | 1.0 s / under 1.5 s | A chair pushed back on the boards. |
| `roulette/spin` | no | Effects | 4.2 s / 3.5-4.5 s | The wheel spun, the ball round the track; fades out before the drop (at 62 % of the 6.5 s spin). |
| `roulette/ball_drop` | no | Effects | 2.8 s / 2-2.5 s | The ball off the track, bouncing over the frets, settling. |
| `roulette/ball_rest` | no | Effects | 0.15 s / under 0.3 s | The ball's last knock into its pocket. |
| `roulette/chips` | no | Effects | 0.2 s / under 0.3 s | A chip set down on the layout. |
| `roulette/cue` | no | Effects | 1.4 s / under 2 s | The croupier's call bell as the number is marked (no speech). |
| `roulette/win` | no | Effects | 1.0 s / about 1 s | Winnings pushed across the felt. |
| `roulette/lose` | no | Effects | 0.8 s / under 1 s | The rake drawing the lost chips off. |
| `slots/lever` | no | Effects | 0.7 s / under 1 s | A machine's lever: ratchet, spring, a clunk. |
| `slots/reels` | yes | Effects | 1.0 s stereo / 0.5-2 s | The reels running; stopped with the last reel (never doubled). |
| `slots/stop` | no | Effects | 0.3 s / under 0.4 s | One reel stopping (played for each). |
| `slots/coin` | no | Effects | 0.35 s / under 0.4 s | One coin into the payout cup (played for each coin). |
| `slots/bell` | no | Effects | 1.8 s / under 2.5 s | The machine's bell for a good payout (10 coins or more). |
| `poker/shuffle` | no | Effects | 1.3 s / under 1.5 s | The dealer's riffle before each hand at the card table. |
| `poker/pot` | no | Effects | 1.0 s / about 1 s | The pot pushed to the winner. |
| `poker/reveal` | no | Effects | 0.45 s / under 0.6 s | Hole cards turned over at a showdown. |

The mix (`SoundscapeMix`): in the card room and the gaming room the bed plays at −12 dB and the room's own
sounds come every few seconds (−15 to −10 dB, at a spot in the room); the Copper Owl's band comes through the
wall low-passed (two walls: at most 320 Hz, about −23 dB in the card room, fainter in the gaming room). Back in
the club the bed is silent and the band full again; outside, as before. The bed is one player started once and
only its level changes; speech and narration duck it like the rest of the night (−10 dB). Every level obeys the
Master, Music, Effects, Voice and Ambience sliders on the game menu's Sound page (M012; the pause screen before); the Master limiter prevents clipping.

### Heavy weather (M012)

Synthesised in numpy by `tools/template_audio/make_weather.py` (no recordings, no samples, nothing downloaded),
OGG Vorbis, 44.1 kHz; overridden the same way (`custom/audio/<logical name>.ogg|.wav|.mp3`, restart to hear it).

| Logical name (packaged file: `assets/audio/<dir>/template_<name>.ogg`) | Loop | Bus | Length (template / recommended) | Used for |
| --- | --- | --- | --- | --- |
| `ambience/downpour` | yes | Ambience (through the street's bus) | 12 s stereo / 10-30 s | A downpour over the rain bed: heavier hiss and rush, water off gutters and awnings, drumming on tin. Comes up with each downpour (at full −7 dB), duller and quieter indoors. |
| `weather/thunder_far` | no | Ambience (through the street's bus) | 7.5 s stereo / 5-9 s | Distant thunder rolling over the roofs, now and then in a downpour (−9 dB; −15 dB indoors, low-passed). Start on the sound. |
| `weather/thunder_near` | no | Ambience (through the street's bus) | 6.5 s stereo / 5-8 s | Thunder close by: a crack, a heavy roll, echoes off the walls; rarer (−4 dB; −10 dB indoors). |

The thunder plays on the street's bus, so a room's walls dull it like the rest of the street; one clap at a time,
whatever the clock's speed. The street is lit cold for a breath with each clap (dimmer from indoors).

The `_inbox/` originals are untouched; nothing here was made from them. M012 adds no voices: the established
recordings play as before, and the new characters' lines are text (their delivery notes for a future recording are
in `docs/M012_PERFORMANCE_SCRIPT.md`).
