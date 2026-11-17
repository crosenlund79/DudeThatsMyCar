# Template sound generator

Synthesises the M002 `template_` sounds (Python 3 with numpy; deterministic):

```bash
python3 tools/template_audio/make_audio.py assets/audio
```

Writes `weapons/template_pistol_shot.wav`, `weapons/template_pistol_reload.wav`, `weapons/template_bullet_impact.wav` and `police/template_whistle.wav`. The engine, tyre and impact sounds are the HyperCars templates. Your own sounds go in `custom/audio/` instead (see `docs/ASSET_SPECS.md`).
