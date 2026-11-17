# Deferred observations — not approved tasks

Record only observations found during approved work. An item here is **not** permission to implement or add to the current objective. HyperCars-era observations are archived in `docs/archive/hypercars/BACKLOG.md`.

| Date | Observation | Context |
| --- | --- | --- |
| 2026-11-14 | Starter pack: no rule for vendored third-party addons (e.g. `addons/gut/`) — licence, version pinning, exclusion from reviews. | Framework (carried over) |
| 2026-11-14 | Starter pack: asset contract covers single files only; display size vs resolution, nine-patch margins, tiles, strips, sheets and facades are defined per asset in `src/assets/asset_catalog.gd`. | Framework (carried over) |
| 2026-11-14 | Starter pack: no guidance on third-party content licences for fonts or other bundled assets (Fredoka is SIL OFL 1.1; licence shipped next to the font). | Framework (carried over) |
| 2026-11-17 | Performance measured only under software OpenGL (llvmpipe, 4 CPU cores, 1280×720) at the start view: about 20 fps on foot and in the car, after cutting ground overdraw, unlit haze and smaller ground chunks (first version: 14 / 12 fps). Street-lamp lights cost about 6 fps, the vignette about 3. Not measured on a real GPU, where 2D of this size normally runs far above 60 fps. `tests/support/perf_probe.gd` prints the breakdown. | M001 performance |
| 2026-11-17 | True top-down perspective: walls next to the screen centre are edge-on, so facades show at a distance and towards the screen edges; standing against a building you mostly see its roof. The start was placed at the streetcar stop in the middle of Marlowe Avenue so both street walls are in view. A stronger lean (lower `CityCamera.EYE_HEIGHT`) shows more facade but hides more street behind buildings. | M001 visuals |
| 2026-11-17 | Draw-order simplifications in the perspective view: all walls draw below all roofs and window light above all walls, ordered by building height, not by distance. Where two buildings stand very close at the screen edge, a window glow or wall can show through a neighbour's roof edge for a few pixels. | M001 visuals |
| 2026-11-17 | Street lamps have no light occluders: a lamp's 215 px pool can reach a wall on the far side of a shallow building. Rare with the current building depths. | M001 lighting |
| 2026-11-17 | The raised bascule bridge is drawn as a tall steel block; from straight above it reads as a dark structure more than a lifted roadway. | M001 visuals |
| 2026-11-17 | City pedals: with separate W / S the coasting deceleration was set to 130–150 px/s² (HyperCars' fire-released braking was 200) so lifting off feels like rolling, not braking. Provisional, like all handling numbers. | M001 driving |
| 2026-11-17 | Getting in and out is instant (no door animation or walking round the car); a car moving faster than 40 px/s cannot be entered; pressing E at speed brakes the car to a stop first. | M001 player |
| 2026-11-17 | No gamepad support and no key remapping in M001 (HyperCars' remapping and pad support were retired with the racing UI; recoverable from commit `c6f7511`). | M001 controls |
| 2026-11-17 | Sound is the HyperCars engine, tyre and impact templates (procedurally synthesised, not period-specific); there is no ambient city sound or music yet. | M001 audio |
| 2026-11-17 | The HyperCars test suite (run once before the conversion) stalled in `test_net_lan_race.gd` (two-process LAN test) in this cloud container; the 57 files before it passed. That test was retired with networking. | Conversion |
| 2026-11-17 | After adding a script with a new `class_name`, run `godot --headless --path . --import` before running a `-s` script (the global class list is only refreshed by an import / editor scan). | Tooling |
