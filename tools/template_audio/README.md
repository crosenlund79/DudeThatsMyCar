# Template sound generator

Synthesises the M002 `template_` sounds (Python 3 with numpy; deterministic):

```bash
python3 tools/template_audio/make_audio.py assets/audio
```

Writes `weapons/template_pistol_shot.wav`, `weapons/template_pistol_reload.wav`, `weapons/template_bullet_impact.wav` and `police/template_whistle.wav`. The engine, tyre and impact sounds are the HyperCars templates. Your own sounds go in `custom/audio/` instead (see `docs/ASSET_SPECS.md`).

M005 adds the night's soundscape and the sounds of dealings (Python 3 with numpy, plus ffmpeg with libvorbis to write OGG):

```bash
python3 tools/template_audio/make_ambience.py assets/audio
```

Writes the stereo loops `ambience/template_street_night.ogg`, `template_alley.ogg`, `template_river.ogg` and `template_club_crowd.ogg` (built on a circular buffer, so they repeat without a seam) and the one-shots `ambience/template_horn.ogg`, `template_foghorn.ogg`, `template_clatter.ogg`, `places/template_door.ogg`, `template_shop_bell.ogg`, `template_register.ogg`, `template_bottles.ogg` and `vehicles/template_door.ogg`.

The Copper Owl's song and Danny's monologue are the user's recordings, not templates; how the shipped song was cleaned is recorded in `assets/audio/README.md`.

M011 adds the Copper Owl's back rooms - the room's bed and its odd sounds, the wheel, the nickel machines, and
a few more card-table sounds (numpy + ffmpeg, all synthesised, deterministic):

```bash
python3 tools/template_audio/make_gaming.py assets/audio
```

or one sound alone: `python3 tools/template_audio/make_gaming.py assets/audio slots/reels`. The list, lengths and
uses are in `assets/audio/README.md`.
