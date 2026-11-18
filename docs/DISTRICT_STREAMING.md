# Seamless district loading — assessment (M006) and what was built (M008)

**Status: implemented in Milestone 008** (approved by the user, "M008: Beyond Riverside Ward"). The
M006 assessment below is kept as it was written; the section "What M008 built" at the end records
how the recommendation was followed, where it was changed and what was measured.

## What the game does today

Measured on the development container (Godot 4.7.2, headless, `RiversideWard`):

| Step | Time / size |
| --- | --- |
| `RiversideWard.create()` (the layout as data) | 5.5 ms |
| `City.build()` (ground, curbs, 96 buildings, 100 props, 132 lamps; 2 954 nodes) | 115 ms |
| `Interiors.build()` (six rooms, their people and lamps) | 27 ms |
| `CityNavigator` (the walking grid, `AStarGrid2D` over the play area at 20 px) | 14 ms |
| `Minimap.paint()` (the painted map image, 2150 × 1500 px) | 11 ms |
| Static memory of the whole game | about 65 MB |

So one district costs about **170 ms of main-thread work** to build - a visible hitch (10 frames
at 60 fps) if done in one frame, but small enough to spread over a second or two of driving.

How the current architecture is shaped:

- **One `DistrictLayout`, absolute coordinates.** `RiversideWard`, `RiversideInteriors`, the street
  life data, the beat cop's beat, Lefty's corner (`main.RIVAL_POST`), the spawn and many tests use
  absolute world positions. The ward spans about −1700..4900 × −1300..2700 px.
- **Built once at start-up.** `src/main/main.gd` builds the city, rooms, markers, cars, people and
  street life in `_ready()`; nothing is ever unloaded.
- **Single-district services.** `CityNavigator` (one grid), `StreetLife` (lane loops and sidewalk
  routes of this ward), `Soundscape` (alleys and water of this layout), `Minimap` / `WardMap` (one
  painted image), `PlaceMarkers`, the camera limits (`layout.bounds`) and `SaveGame` (one ward's
  state in `Rackets`, `ward`, `voices`) all assume a single layout.
- **Per-frame view work is already near the view.** `City.update_view` asks every `BuildingView` to
  re-project, and culls raised sprites and reflections to the view (+260 px). Building redraws are
  the main CPU cost; two districts' worth of buildings would need the same view culling applied to
  the buildings' redraws.
- **The edges are closed on purpose** (embankment, river with the raised bridge, barricades): there
  is no exit to stream through yet.

## Recommended approach (if approved later)

1. **One world coordinate space, districts placed at an origin.** Keep the Riverside Ward at
   (0, 0) so none of its coordinates, rooms or tests change; author each new district in its own
   local coordinates and place it at an offset (e.g. the far bank at x + 4400). Danny, his car, a
   pursuing officer and bullets keep moving in the same space - no teleport, no "loading
   position". Float precision is not a concern at these sizes (it would be beyond roughly
   10^5 px; origin rebasing can wait).
2. **A small `World` that owns districts.** A list of district definitions (id, origin, the
   `DistrictLayout` factory, the exits shared with neighbours). Each loaded district is one node
   tree (its `City`, rooms, markers, street life, navigator, map image), so unloading is freeing
   one node.
3. **Load ahead, at the exits.** An exit is a street that crosses a boundary (the lowered Marlowe
   Avenue Bridge, Pruitt Street west of the barricade). When Danny comes within about one and a half
   screens of an exit (more in a fast car), start building the neighbour **time-sliced**: the data
   on a `WorkerThreadPool` thread (layout, navigator grid, map image), the nodes on the main
   thread a few buildings per frame (keep each frame's share under ~4 ms). It will usually be
   ready before he reaches the boundary; if it is not, slow the hand-over rather than show a
   loading screen (the camera keeps its limits at the old district until the new one is ready).
4. **Keep two, drop the third.** At most the current district and the neighbour being approached
   (or just left) stay loaded; a district is unloaded only after Danny has been well inside
   another one for a while (hysteresis, so driving back and forth over a border does not thrash).
5. **District state is saved per district.** When a district unloads, its mutable state - bodies
   (Lefty), who is out tonight, stolen and moved cars, the beat cop, the street life's hour -
   goes into a per-district dictionary in the save; when it loads again, the same state is
   restored, so a revisited district is as Danny left it. Global state stays global: the clock,
   Danny (position, wounds, money, gun), his car, `Rackets` (the economy can grow per-district
   `Neighbourhood`s inside it), voices heard.
6. **Services become multi-district one at a time.**
   - Navigation: one grid per district plus "portal" cells at the exits; at first a pursuing
     officer gives up at the border (cheap and believable), later routes can stitch grids.
   - Street life: traffic loops and walkers stay inside their district at first.
   - Maps: the minimap and ward map draw whichever district images overlap the view; the ward map
     gains a district switch.
   - Camera limits and the soundscape use the union of loaded districts' bounds, alleys and water.
   - Place markers and rooms are already per layout; they move with their district's node.
7. **Tests to add with it:** crossing each exit on foot and by car without a stall; a hitch budget
   (no frame of the time-sliced build over a threshold); leaving and returning restores the
   district's state; saving at a border and loading; a chase across a border; memory stays flat
   over many crossings.

## Likely complexity

A milestone of its own, comparable to M006: roughly

- the `World` / district definition, origins, exits and the time-sliced builder (medium);
- per-district save state and restore (medium);
- making navigator, street life, soundscape, maps, markers and camera limits work with several
  loaded districts (medium to large, touching most `src/` modules lightly);
- opening the first exit and building a second district's layout and art (large: the art and
  design work dominates, not the streaming);
- tests and tuning (medium).

## Risks

- **Construction hitches.** 115 ms for `City.build` today; a denser district could be several
  times that. Time-slicing is required, and `BuildingView` setup must be divisible per building.
- **Rendering cost with two districts in view.** On the software renderer used in development the
  game runs at about 16-22 fps with one district (the M004 build measures the same on this machine
  today, so M005/M006 did not regress it); two districts' buildings near a border would cost more
  unless building redraws are culled to the view. On a real GPU this should be ample, but it has
  never been measured on one (see `docs/BACKLOG.md`).
- **Absolute coordinates.** Moving the Riverside Ward away from (0, 0) would touch hundreds of
  positions in code and tests; the recommendation avoids that by keeping it at the origin.
- **State that crosses borders.** Pursuits, traffic that would leave a district, bullets in flight,
  Lefty following Danny: each needs a rule (stop at the border, or hand over). Starting with
  "stops at the border" keeps it simple.
- **Save compatibility.** Today's saves hold one ward; a district-aware save needs a version field
  and a migration that files the current state under the Riverside Ward.
- **Godot specifics.** Building nodes must happen on the main thread (only data can be built on a
  worker thread); `ResourceLoader.load_threaded_request` helps only for packed scenes and
  resources, while this game builds districts from data at run time.

## Implications for the current map architecture

- Keep authoring districts as data (`DistrictLayout` factories) - it suits streaming well: data
  can be prepared off the main thread and the node tree built incrementally.
- Give `DistrictLayout` an `origin` (default zero) and an `exits` list before any second district
  is designed; nothing else needs to change for the Riverside Ward.
- Avoid adding new absolute positions outside the layout (like `main.RIVAL_POST`): put district
  people and places in the layout so they move with it.
- The closed edges (embankment, river, barricades) can stay as they are on every side that does
  not lead to a neighbour.

## What M008 built

Followed the recommendation, with these choices:

- **One world, districts at an origin.** The Riverside Ward stays at (0, 0) with every coordinate
  unchanged. `DistrictLayout` gained `id`, `origin`, `exits`, `landmarks`, `lamp_energy` and
  `smoke`; a district is drawn up in its own coordinates and placed with `shift(origin)`
  (`to_local` / `to_world` convert). The Riverfront Yards sit at (-1700, 2700), straight below the
  ward; Halloran Square at (-4900, -1300), beside it. Their streets continue the ward's lines and
  widths exactly. The ward's own drawing helpers moved into a `DistrictBuilder` base the
  neighbours share; the ward's layout is byte-for-byte unchanged apart from its opened exits.
- **`DistrictStreamer`** (`src/world/`, not an Autoload) holds every district's layout (data,
  about 2.5 ms each for the neighbours, made at start-up together with each one's map image, 2-4 ms) and builds a
  district's nodes only when Danny comes within 1300 px of its play area, about 4 ms a frame:
  `City.build` became a list of small ordered steps (ground by street and block, one building at a
  time, props and lamps in batches); the game adds steps for the district's street life and
  parked cars; its walking grid is built on a `WorkerThreadPool` thread; its graphics are
  prefetched with `ResourceLoader.load_threaded_request`. The district appears (and its frontier
  wall opens) only when complete. At most two districts are loaded; the ward is built at start-up
  and adopted as pinned, so with three districts it is always one of the two (every way between
  the neighbours runs through it). A district left 1900 px behind is let go: the game forgets its
  people at once, its node stops and vanishes and is taken apart about 2 ms a frame.
- **Entities across borders.** Cars are never freed: a district's parked cars join the game's car
  list the first time it is built, and any car standing in a district that is let go (the
  district's own, or one Danny left there) is put away exactly where it is and brought back with
  the district, so nothing is ever duplicated. Bullets in flight in a freed district are dropped.
  Each district has its own beat cop on its own walking grid; nobody routes off his own grid (a
  pursuing officer, or Lefty, stops at his district's edge, watches and gives up as usual).
- **State.** What a district keeps for the night (its beat cop shot down, and where) is held while
  it is unloaded and saved with the game; sleeping clears it (a new man on every beat). Cars go
  back to their owners each evening as before. A saved game still starts at home in the ward.
- **Services.** The camera's limits follow the loaded districts; getting out of a car asks the
  streamer for open ground; the minimap and the new city map draw every district from its own
  painted image; the soundscape listens to the district Danny is in; the HUD names it.

### Measured (development container, software OpenGL under xvfb, 1280 x 720)

From `tests/support/district_probe.gd` (driving across each border with the normal controls):

| | Riverfront Yards | Halloran Square |
| --- | --- | --- |
| Build: work, frames | 29.3 ms over 7 frames | 36.7 ms over 9 frames |
| Build: worst frame of building work | 5.4 ms | 5.8 ms |
| Build: start to finish | 0.39 s | 0.63 s |
| Rebuild (textures cached) | 29.1 ms over 6 frames | - |
| Frame time before / while building (mean) | 62.2 / 65.6 ms | 73.4 / 79.2 ms |
| Worst frame before / while building | 84.8 / 71.9 ms | 89.7 / 86.0 ms |
| Letting go | 1.6 ms, then taken apart over 18 frames (2 ms each) | - |
| Memory with the ward + it | +8.7 MB static, +1557 nodes | +7.6 MB, +1759 nodes |

One district (the ward): 87.1 MB static, 3476 nodes; after letting the yards go: 89.3 MB, 3502
nodes (their two cars put away and their textures kept). Before spreading the work, letting a
district go cost 15.7 ms in one frame and the first build's slowest step (loading its textures
from disk) 4.1 ms; both were fixed as above. Frame rate on the same machine at the same kind of
spot: the ward's Marlowe Avenue 13-16 fps, Halloran Square's 14.7-16.3 fps, the yards 19 fps
(fewer lamps); clearing a district's street life gains about 1 fps, its lamps about 3.5 fps. The
software renderer's frame times vary a lot between runs; a real GPU has still never been measured
(see `docs/BACKLOG.md`).

### M009: the city's incidents, Danny's own work and the heavy vehicles (same machine)

Nothing of M009 is simulated in a district that is not built: an incident there is a few numbers
on the night clock (`StreetIncidents`), and Dutch's and Mr. Feeney's errands are a state each
(`Opportunities`). People are made only for an incident near the camera in a built district, and
Dutch, Mr. Feeney, the crate and the film can are children of their district's node, built and
freed with it. Brennan's truck and the school bus are parked cars of their districts like any
other (made with the district, put away with it, never doubled).

From `tests/support/incident_probe.gd` and a re-run of `district_probe.gd`:

| | |
| --- | --- |
| A night of incidents as state, frame by frame (18 000 frames) | 34-47 ms all told (0.002-0.003 ms a frame); about 9 planned a night over the three districts |
| M009 work a frame, nothing going on (incident clock, views, contacts, the E check) | 0.09 ms mean, 0.13-0.34 ms worst |
| The same with two incidents in view (four people, two lines) | 0.21-0.23 ms mean, 0.5-4.5 ms worst (the frame their people are made) |
| Frame rate at the Copper Owl, nothing going on / two incidents in view (same spot) | 16.4 / 16.8 fps, 18.0 / 17.6 fps (no difference within noise) |
| The yards at Dutch's (truck on the dock) | 21.6-24.4 fps |
| Driving the school bus in Halloran Square | 18.7-19.7 fps |
| Build the yards (with Dutch, his crate and the truck) | 24.2 ms over 5 frames, worst 6.5 ms (M008: 29.3 ms over 7, worst 5.4) |
| Build Halloran Square (with Mr. Feeney, the can and the bus) | 26.2 ms over 6 frames, worst 5.2 ms (slowest step: its parked cars, 2.2 ms) |
| Memory with the ward + the yards | +8.8 MB static, +1573 nodes (M008: +8.7 MB, +1557) |

The traffic's obstacle list grows by four circles for each of the two long vehicles while their
district is built; no new per-frame scan of the whole city was added.
