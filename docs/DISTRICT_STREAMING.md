# Seamless district loading — feasibility assessment (M006, investigation only)

**Status: investigation.** Nothing here is implemented or approved. No second district and no
streaming framework were built in M006. This records what the current code does, the approach
recommended if the user approves a later milestone, its likely size, and the risks.

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
