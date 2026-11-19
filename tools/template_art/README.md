# Template art generator

Paints every `template_` image in `assets/graphics/` (Python 3 with Pillow and numpy; deterministic, so a re-run reproduces the files byte for byte):

```bash
python3 tools/template_art/make_all.py assets/graphics
```

Optional: a second argument writes 2x2 tiled previews (to check seams) to a folder; a third limits the run to logical names starting with a prefix (for example `facades`). Files: `paintkit.py` (painting helpers), `paint_ground.py` (ground, roof tiles, strips), `paint_buildings.py` (facades and window light), `paint_props.py` (street and rooftop furniture, signs, effects, UI), `paint_vehicles.py` (the cars, the squad car and the steerable front tyre), `paint_people.py` (the gangster, the officer and the people of the ward), `paint_interiors.py` (floors and furniture of the rooms you can enter); later milestones add `paint_districts.py`, `paint_grime.py`, `paint_poker.py`, `paint_items.py`, `paint_cafe.py`, `paint_emergency.py` and (M011) `paint_gaming.py` (the gaming room, the wheel and the machines on screen, the union hall's furniture). The game never runs these scripts; `tools/.gdignore` keeps Godot from importing them. Your own art goes in `custom/` instead (see `docs/ASSET_SPECS.md`).
