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

### M010: grit, shadows, weather and the later features (same machine)

What M010 adds to a district is data made once at start-up with its layout (`CityPlan.layouts`):
its litter (`StreetGrime`, 6-11 ms a district), its ground shadows as one mesh (`Shadows.ground`,
7.5-16 ms a district), the fog's banks at the buildings' feet and its open-ground cover
(`FogCover`, 48 px cells). Altogether about +50 ms at start-up; a district's build only adds the
nodes that draw them (the ground-shadow layer's first draw went from 8.4 ms to 0.5 ms once it
became one mesh). The weather, the poker table, the Thompson, the café and the emergency are not
simulated in a district that is not built (the café job and the weather are a few numbers on the
night clock; the café's scene and the emergency are drawn from those numbers when Danny is there).

From `tests/support/district_probe.gd` (re-run) and `tests/support/m010_probe.gd`:

| | |
| --- | --- |
| One district (the ward) | 94.3 MB static, 3575 nodes (M008: 87.1 MB, 3476: M010's art, the back room, the park) |
| Build the yards | 28.9 ms of work over 7 frames, worst 4.6 ms; rebuilt 24.0 ms over 6 (M009: 24.2 ms over 5) |
| Build Halloran Square (with the park and the café) | 31.8 ms over 7 frames, worst 6.8 ms (M009: 26.2 ms over 6) |
| Memory with the ward + the yards | +8.9 MB static, +1582 nodes (M009: +8.8 MB, +1573) |
| Marlowe Avenue by the Copper Owl: clear / rain / fog / rain and fog | 20.0 / 18.4 / 12.8 / 11.6 fps (worst frames 66 / 63 / 95 / 117 ms) |
| The weather's own work a frame (rain and fog) | 0.055 ms |
| The back room with the card table open, a hand being played | 15.2 fps (the table redraws every frame over a dimmed screen) |
| A card player's decision (four-handed, before the flop, 90 deals) | about 2.8 ms, once per action while he "thinks" |
| Marlowe Avenue with the Thompson held down | 19.3 fps |
| Rosie's Café: the film / the burning wreck and the emergency driving in / the emergency at the kerb | 15.8 / 14.8 / 13.6 fps |
| The café scene's and the emergency's own updates a frame | 0.12 ms |
| The yards on foot / Halloran Square on foot | 19.2 / 13.6 fps (M008: 19 / 14.7-16.3) |

The fog is the expensive part under software OpenGL (fill rate: it is drawn over every open cell of
the district in view); everything else costs within the run-to-run noise of this renderer or a
few fps. A real GPU has still not been measured.

## M011: the back rooms, the union hall and City Hall

M011 adds no streaming: the gaming room and the union hall are rooms of the ward (built at start-up
with its other rooms; the ward is always loaded), and City Hall, the mayor's house and the aldermen's
offices are ordinary buildings of Halloran Square and the ward (two new facades, a cupola on a roof,
roof lettering, a few lamps, locked doors as data). The games are simulated only while Danny plays
them: the wheel's and the machines' models are a handful of numbers, the view moves the wheel and the
reels only while they turn (the wheel on a layer of its own, so the table is not drawn again each
frame), and Leo's spins for the other players turn the room's wheel sprite only while Danny is in the
gaming room. The back rooms' sound is one looping player started at start-up (silent outside) and at
most one short sound every few seconds inside.

From `tests/support/m011_probe.gd` (software OpenGL, 1280 x 720, clear weather unless said):

| | |
| --- | --- |
| The scene up / rooms built at start-up | 577-643 ms / 9 (the gaming room and the union hall among them) |
| The Copper Owl / the card room / the gaming room, idle | 18.8-19.2 / 20.0-21.2 / 19.2-19.6 fps |
| The soundscape's update a frame in the gaming room | 0.16 ms |
| At the wheel between spins / spinning (the table on screen, dimmed room) | 15.6 / 16.2 fps |
| At a machine, idle / the reels running | 19.6 / 17.0 fps |
| The wheel's and a machine's own updates a frame | 0.01-0.04 ms |
| At the card table, a hand under way | 18.0-18.8 fps |
| In the union hall | 21.6-22.4 fps |
| Halloran Square built at once (with City Hall and the mayor's house) | 29.5-35.9 ms (M010: 31.8 ms over 7 frames when streamed) |
| In front of City Hall, clear / fog | 22.4-24.0 / 13.2-13.6 fps |
| Memory, the ward with Halloran Square loaded | 111.6 MB static, 5644 nodes |

The wheel's table is the costliest new screen under software OpenGL - fill rate for the dimmed
screen, the baize and the wheel's large textures, not the game: spinning costs nothing over the
table standing still once the wheel was drawn on its own layer (before: 15.2 fps spinning). A real
GPU has still not been measured.

## Milestone 012: rooms in every district, the weather kept outside

M012 builds a streamed district's rooms with the district: when the streamer reports a district ready,
`Interiors.add_district` makes its rooms' walls, door glows and cut-away views under the district's own
node (so they are freed with it) and adds them to the game's lists; when it lets a district go, the
rooms leave the lists first (`remove_district`). The streamer never lets go of the district Danny
stands in, so a room never disappears under him. Room plans are written in each district's own
coordinates and moved with it (`InteriorPlan.shift`). What must outlast a room's nodes - who was struck
down there tonight, the freight shed's emptied corner - lives in the game's state (`ward_out`,
`FreightJob.crates_out`) and is put back on the rebuilt room. A saved game now resumes where and when it
was saved: the district it was saved in is built at once (`load_now`) before the first frame.

The weather is kept out of the room Danny is in: the rain overlay, the street fog and the fog at the
buildings' feet each take one rectangle (the open room's building) where they draw nothing - a
uniform, no new pass; the fog's feet got a four-line shader of their own for it. Downpours, wind and
thunder are a few numbers on the night clock.

From `tests/support/m012_probe.gd` (software OpenGL, 1280 x 720; two runs, the range shown):

| | |
| --- | --- |
| Marlowe Avenue: clear / rain / a downpour | 16.0-17.2 / 15.2-17.2 / 15.2-16.8 fps |
| Marlowe Avenue: fog / rain and fog | 10.8-12.0 / 9.6-10.8 fps |
| The weather view's own update a frame (rain and fog) | 0.07-0.08 ms |
| In Quilty's office with rain and fog outside | 10.0-11.2 fps |
| At the ward's border with Halloran Square in fog, both built | 11.2-13.2 fps |
| Halloran Square streamed in with its three rooms | 31.2 ms of work over 7 frames, worst slice 2.4 ms (M010 without rooms: 31.8 ms over 7) |
| The yards with their two rooms built at once (load_now) | 46.1-69.1 ms |
| In City Hall / the freight shed / the shed with rain and fog outside | 14.4-16.8 / 23.6-28.0 / 16.4-18.8 fps |
| Call-outs and routines a frame (in the Copper Owl) | 0.08 ms |
| The Bird's film / the game menu open | 14.2 / 15.6-24.8 fps |
| Memory, ward + yards loaded | 104.1-109.3 MB static, 3904-5547 nodes |

Rain, downpours and thunder cost next to nothing; the street fog stays the costliest effect (as in
M010-M011), and it still covers the street outside a room's walls while Danny is inside (its hole is
the room's building only). Nothing was optimised further: the fog's cost is fill rate under software
rendering, and a real GPU has still not been measured.

## Milestone 013: cars across saves, the rain rebuilt, a living gaming room

Cars keep their place across saves by a lasting name (`<district>/<n>`: the district whose layout
parks the car and its index there - the same whichever district was built first). A save lists the
cars moved from their parking places (place, heading, cargo), the ones taken tonight and the one Danny
sits in. On loading, a neighbouring district named in the save has its cars made at once (put away
until the district is built, as when it is unloaded); the district the car stands in is built with
`load_now` before the first frame and Danny is put back in the seat. Nothing new streams.

The rain is still one screen-wide shader, now with its fall integrated on the CPU (three depths, a
handful of uniforms a frame) and one copy of the screen it reads to catch the light. The gaming room's
regulars and Leo's wheel run only while Danny is in that room (the schedule is pure: walking in, it
is read at that minute).

From `tests/support/m013_probe.gd` (software OpenGL - Mesa llvmpipe, no GPU - at 1280 x 720; one run):

| | |
| --- | --- |
| Marlowe Avenue: clear / rain / a downpour | 18.8 / 15.6 / 16.0 fps |
| Marlowe Avenue: fog / rain and fog | 12.4 / 11.2 fps |
| The rain's fall and parameters a frame (`WeatherView.refresh`) | 0.06 ms |
| The gaming room near midnight, all five regulars about | 19.6 fps |
| ... the regulars' life a frame (`GamingRoomLife.update`) / Leo's wheel a frame (`RouletteTable.advance`) | 0.16 ms / 0.03 ms |
| The gaming room with rain and fog outside | 9.6 fps |
| At the wheel: bets open, the regulars' chips going down / the ball dropping and paid | 12.5 / 15.0 fps |
| At the Owl, its reels running / at the card table (dime and quarter), a hand under way | 18.0 / 18.0 fps |
| Loading a game saved at the wheel in Halloran Square (the scene, the square, the car, Danny in it) | 423 ms; then 12.0 fps driving there in the rain |
| Memory after the run | 112.0 MB static, 5895 nodes |

The new work a frame is small (well under a millisecond together). The rain costs about as much as
M012's (15.2-17.2 fps then, 15.6-16.0 now, against 16.0-18.8 clear); the street fog stays the costliest
effect, and it still covers the street outside the gaming room's walls (9.6 fps inside with rain and
fog out). The wheel's screen is the heaviest table screen under software rendering (the wheel is
redrawn every frame now, since it always turns, and the table once a second for its count). Nothing
was optimised further; a real GPU has still not been measured.

## Milestone 014: under the hood (the same game, measured against M013)

M014 changed the code's organisation only, so everything here is compared with the M013 code (`29835b7`)
on the same machine, run back to back (software OpenGL - Mesa llvmpipe, no GPU - at 1280 x 720).
Nothing streams differently: the streamer is unchanged, and a district's content is now registered
and forgotten by its owners (`Districts`) in the M008-M012 order. The district build's slowest step
is now called `district_cars` (it was `_district_cars` in main).

`tests/support/m013_probe.gd`, M013 then M014:

| | M013 | M014 |
| --- | --- | --- |
| Marlowe Avenue: clear / rain / a downpour | 19.2 / 15.6 / 14.4 fps | 17.2 / 14.4 / 14.8 fps |
| Marlowe Avenue: fog / rain and fog | 12.8 / 10.4 fps | 11.6 / 10.4 fps |
| The rain's fall a frame / the regulars' life / Leo's wheel | 0.084 / 0.180 / 0.042 ms | 0.093 / 0.185 / 0.044 ms |
| The gaming room, regulars about / with rain and fog outside | 17.6 / 10.8 fps | 17.6 / 9.6 fps |
| At the wheel (bets open / ball dropping), the Owl, the card table | 15.2 / 13.8, 17.0, 17.3 fps | 14.0 / 14.8, 17.5, 17.7 fps |
| Loading a game saved at the wheel in Halloran Square | 342 ms, then 10.8 fps | 341 ms, then 10.8 fps |
| Memory after the run | 112.0 MB static, 5895 nodes | 114.5 MB static, 5896 nodes |

Under software rendering the same scene varies by 1-2 fps from run to run (clear weather measured
19.6 and 19.2 on M013, 19.2, 18.4 and 17.2 on M014 over five runs); no figure moved beyond that
spread in both directions. The script side, measured headless in the street in the rain (process
and physics time a frame over 900 frames, three runs each), is 4.6-5.5 / 3.9-6.0 ms on M013 and
4.4-4.7 / 2.7-3.0 ms on M014, with the same nodes processing. `tests/support/district_probe.gd`
gives the same building work (the yards 20.0 ms over 5 frames, M013 20.5; Halloran Square 27.6 ms
over 6, M013 27.2) and the same frame times at the borders within noise.

Memory: the first refactoring step had raised the static memory at start-up by about 42 MB, a
Godot 4.7 effect of how `main.gd` made the directors (see `docs/ARCHITECTURE.md`, section 3). After
the fix: scripts compiled 47.6 MB (M013 45.4), one scene 124.2 MB (M013 121.9), the scene freed
54.0 MB (M013 60.7); each district adds the same as at M013 (the yards +9.6 MB). The rest of the
difference is the 27 new scripts.

Screenshots (`tests/support/screenshot_tour.gd`, 27 shots): two runs of the M013 code differ from each
other by a mean of 0.0-18.7 levels a pixel (rain, traffic, the camera's easing and the wheel's
unseeded draw are not frame-exact). Each M014 shot differs from the nearer M013 run by at most about
1.2 times what the two M013 runs differ by (the club: 14.5 against 12.6; the wheel: 1.06 against
0.88), and `city_map` and `job_map` match the second M013 run exactly. Side by side, the shots that
differ most show the same scene - the same people, lines, clock, money and cars - with the rain, the
traffic, the camera's last few pixels or the wheel's last number apart. A few M014 shots are in
`docs/screenshots/m014/`.

