# Architecture

*Chicago, 1932* is one Godot scene (`src/main/main.tscn`) built in code at start-up. This
document describes how the code is organised **as it is after M014 ("Under the Hood")** and why.
Rules for working on the project are in `docs/GODOT_CLAUDE_GUIDELINES.md`; tests in `tests/README.md`.

## 1. The shape of the code

- **Pure models** (`RefCounted`, no scene) hold the rules and the state and are tested on their
  own: `Rackets` (money in cents, the ward's businesses, Rourke, memories, talk, and every job's
  state), `RourkeJob`, `CafeJob`, `FreightJob`, `Opportunities`, `Holdem`, `PokerNight`, `Roulette`,
  `RouletteTable`, `SlotMachine`, `StreetIncidents`, `Weather`, `NightClock`, `CarThefts`,
  `BodyCondition`, `Callouts`, `DistrictLayout` ... M014 did not change them (two small additions:
  `DistrictLayout.places`, and `SaveGame` keeping an unreadable file aside).
- **Scene nodes** draw, move and collide: `City`, `Interiors`, `Walker`, `Car`, `Hud`,
  `Soundscape`, `DistrictStreamer`, the views (`IncidentViews`, `OpportunityViews`, `CafeScene`, ...).
- **Directors** (M014) run one part of the game - the game-side behaviour that used to live in
  `main.gd` - and own that part's state. Most are `RefCounted`; `BackRooms` is a `Node2D` because
  it owns the gaming room's line and life nodes.
- **`Game`** (`src/main/game.gd`) is a plain object with typed references to the running game's
  shared parts: the rules, the services and the directors. Main makes one in `_init` and fills it as
  it builds; it makes each director with `game.make(&"fleet", Fleet)`, which constructs it on the
  game and keeps it in that field. A director reads `game.clock`, calls `game.dialogue.end()`, asks
  `game.police.officers()` - it never reaches into main. When the scene is freed main calls
  `game.release()`: the directors and the Game refer to each other and would otherwise stay in
  memory (`test_scene_cleanup`).
- **`main.gd`** (648 lines; 3,078 at M013) is the composition root: it builds everything in a fixed
  order, connects the signals, runs the frame in a fixed order (`_process` / `_update_view`), hands
  every unhandled key to `Modals`, and saves on quitting. Its fields for the services read and write
  `game`'s (one reference; tests and tools use them).
- No Autoloads. A second scene builds a second, independent `Game` (`test_game_parts`).

## 2. Module responsibility map

| Module | Owns | Lines |
| --- | --- | --- |
| `src/main/main.gd` | the build order, the wiring, the frame order, the place in the save (where and when) | 648 |
| `src/main/game.gd` `Game` | references to the shared parts; `make()`, `release()`, `save()`, `show_purse()`, `mouse()`, `ward_plan()`, `weather_override()` | 148 |
| `src/gaming/back_rooms.gd` `BackRooms` | the card table, Leo's wheel and its regulars, the three machines, the gaming room's evening; their money moves and save | 716 |
| `src/driving/fleet.gd` `Fleet` | every parked car: lasting names, owners and thefts, put away and back, cargo, getting in and out, the cars in the save | 296 |
| `src/police/police_force.gd` `PoliceForce` | the beat cops of every built district: hearing, witnessing, armed or not, free for a stop, a shopkeeper's report | 184 |
| `src/people/people.gd` `People` | routines (Quilty, Leon) and call-outs | 181 |
| `src/world/districts.gd` `Districts` | what a district holds while it is built (street life, beat cop, cars, rooms, plates, the jobs' parts) and keeps while it is not; seats, works trucks | 199 |
| `src/world/city_locations.gd` `CityLocations` | every named place, door, room, spot, contact, errand and parking place by a stable id | 86 |
| `src/talk/dialogue.gd` `Dialogue` | who Danny is talking to, the page, answers, the talk's context; a page's effects handed to their owners in a fixed order; end-of-talk hooks | 153 |
| `src/fight/fights.gd` `Fights` | a fistfight in the game; a fight agreed in a talk started when it ends | 110 |
| `src/health/casualties.gd` `Casualties` | Danny hit and down, people struck down in rooms, who is out tonight, the vet's patch-up | 134 |
| `src/incidents/incident_director.gd` `IncidentDirector` | the city's incidents on the clock, stepping in, broken off by gunfire, noticed on the minimap | 110 |
| `src/presentation/films.gd` `Films` | one film at a time: the screen, controls and camera handed over and back, skipping; the opening | 102 |
| `src/club/club.gd` `Club` | the Bird's microphone; the band counting her back in | 47 |
| `src/weapons/armoury.gd` `Armoury` | the .45, Eddie's Thompson on loan, their notices and save | 99 |
| `src/night/night_cycle.gd` `NightCycle` | the clock and what moves with it, reminders, fast time and its moments, sleeping into the next evening | 113 |
| `src/player/interactions.gd` `Interactions` | the E spot (13 kinds in a fixed priority), what E does, the prompt, the ring under the target | 194 |
| `src/ui/modals.gd` `Modals` | what has the keys (fight, table, film, map, status, talk, menu); the menu, map, status and sound pages; the pause | 204 |
| `src/camera/view_shake.gd` `ViewShake` | the Thompson's climb and the blast's shake | 19 |
| `src/jobs/job_director.gd` `JobDirector` | the game side of one authored job: hooks (below) | 90 |
| `src/jobs/missions.gd` `Missions` | every job, added once in order; their effects, fights and hooks | 95 |
| `src/jobs/rourke_job_director.gd`, `cafe_job_director.gd`, `freight_job_director.gd`, `src/opportunities/errands.gd`, `src/club/last_song.gd` | Rourke's Lindqvist job (Lefty), Rosie's Cafe, Freight Doesn't Walk, Dutch's crate and the Bijou's reel, After the Last Song | 78-205 each |
| `src/save/save_schema.gd` `SaveSchema` | the format version, sections and owners, migrations, checks | 92 |
| `src/save/saves.gd` `Saves` | the save read once, handed out by section, written by asking each owner | 73 |

## 3. How the parts depend on each other

- Every director depends on `Game` and, through it, on the services (rackets, clock, hud, world,
  walker, player, interiors, soundscape) and on the directors it talks to. The references are
  explicit fields, typed, listed in one file.
- **Dialogue knows no mission.** A page's effects (`incident`, `opportunity`, `fight`,
  `bird_scene`, `freight`, `job`, `heal`, `rounds`, `thompson`, `parcel`, `cafe`, `police`) are
  applied in that fixed order (`Dialogue.EFFECTS`, the M003-M012 order) by the one handler each
  owner registered; a talk's end calls hooks in registration order (the pending fight, the
  band, the Bird's question). Extra context keys come from registered parts (Dutch's crate).
- **Main knows no job.** `Missions` registers the jobs' effects and fights and calls their hooks.
- **Districts know their content's owners**, not their details: a district built calls `Fleet`,
  `Missions`, `Interiors`, `EntrancePlates`, `PoliceForce`; a district let go calls the same to
  forget it, in the M008-M012 order.
- **Modals** is the only place that decides who gets a key; directors open and close their own
  screens (`BackRooms`, `Films`, `Fights`).
- The pure models never depend on directors or scenes.
- **Two rules that keep the memory as it was at M013.** `Game` and the directors refer to each
  other (a circle of typed references). Godot 4.7 copes with that, but two things make it analyse
  the whole circle over again and keep the result, about 42 MB more memory at start-up (measured in
  M014; `test_architecture_wiring` guards both): (1) `main.gd` calling a director's `.new()` itself -
  so main makes them through `game.make`; (2) a base class inside the circle - so `JobDirector`
  names no `Game`, and each job declares its own `var game: Game` and `_init(p_game)`.

## 4. Order (kept exactly from M013)

- **Build (`main._ready`):** rules into `Game`; settings and assets; `Rackets`, `NightClock`,
  `Conversations`; `Saves`, `Modals`, then the directors that need no scene (Dialogue, People,
  Fights, Casualties, Districts, IncidentDirector, Films, Club, Armoury, NightCycle, Interactions,
  Missions and its five jobs); the save read (books and voices first); the ward, its rooms,
  markers, plates, highlight, overhead lines; the streamer and the location index; incidents and
  weather; the card game's books; the cars; Danny; the camera; the player; guns; bullets and their
  sounds; the navigator and the ward's beat cop; the street life; Lefty; `Missions.setup()`; rooms'
  casualties; sound; voices; the Bird; the ward's state from the save; the HUD; the incident views;
  drowsiness; weather view; the cafe's scene; the errands' views; the maps; the dialogue wiring; the
  back rooms; the place in the save; the opening.
- **Frame (`main._process`):** the tables, the band, the clock (and through it the incidents, the
  weather and the jobs), the people (routines, the Bird's last song, call-outs), the streamer, the
  view (camera, weather, incident and errand views, minimap, E prompt, markers, HUD, map, sound
  listener), the shopkeeper's report.
- **Save sections** are written in `SaveSchema.SECTIONS` order and restored in
  `SaveSchema.RESTORE_ORDER` (each when its owner exists in the build).

## 5. Coordinates and places

- **District-local, then placed.** Every district - the ward included since M014
  (`RiversideWard.ORIGIN`, zero) - is written in its own coordinates and placed in the one world by
  `DistrictLayout.shift(origin)`, which moves everything it holds: streets, buildings, rooms,
  routes, parked cars, contacts, spots, named places. After that, a layout's data is in world
  coordinates. `layout.to_world(local)` / `to_local(world)` convert at the boundary.
- **Named places** (`DistrictLayout.places`): points the game refers to by name - Lefty's corner
  (`lefty_post`, `lefty_post_east`), the Bird's seat (`bird_seat`), Leon at Dutch's counter
  (`leon_at_dutch`) - written with the district's own data, not as numbers in code.
- **Stable ids** (`CityLocations`, `game.locations`): `<district>/place/<name>`, `<d>/spawn`,
  `<d>/room/<room>`, `<d>/door/<room>/<n>`, `<d>/spot/<room>/<spot>`, `<d>/contact/<id>`,
  `<d>/errand/<id>`, `<d>/cafe/<id>`, `<d>/incident/<id>`, `<d>/parking/<n>` (the same as a car's
  lasting name in `Fleet`). Built from the layouts, so it follows a district wherever it is placed.
- **Still ward-local by design:** the back rooms' furniture constants (`RiversideInteriors.TABLE`,
  `WHEEL_TABLE`, `SLOTS`, `ROOM_SPOTS`, the gaming room's walking graph) - `BackRooms` converts
  the ones it uses with `layout.to_world`; `GamingRoomLife` uses its graph as written (the ward is
  at zero). Tests use absolute positions freely (they test the city as it is).
- **The city is unchanged:** `test_layout_fingerprint` compares every layout and room plan with
  the M013 recording to a hundredth of a pixel.

## 6. Districts and streaming

- `DistrictStreamer` builds a neighbour a slice a frame as Danny nears it, keeps at most
  `MAX_LOADED` built, and frees what is let go a slice a frame. The ward is built at start-up and
  adopted pinned. Which districts are near is a matter of geometry (`wanted`), not of a list of
  neighbours of the ward: M015's Canal Market joins Halloran Square and the yards, not the ward,
  and is built the same way. `MAX_LOADED` went from 2 to 3 in M015 so that the pinned ward, the
  district Danny is in and the one he is nearing can all be built.
- `Districts` keeps each built district's street life (the ward's first, in the same list),
  registers its beat cop with `PoliceForce` and its contacts with the jobs (`Missions`), and on
  letting it go has every owner forget it. `test_district_lifecycle` builds, lets go and rebuilds
  the yards: each owner registers and forgets it, its nodes are freed, nothing is duplicated.

## 7. Missions

A job is a **pure model** (its stages, money and save, in `Rackets`) plus a **director**:

```gdscript
class_name MyJobDirector
extends JobDirector

var game: Game                                   # each job's own (see section 3)
func _init(p_game: Game) -> void: game = p_game

func id() -> String: return "my_job"
func effects() -> Dictionary: return {"my_effect": func(v, _e): ...}  # add "my_effect" to Dialogue.EFFECTS
func fights() -> Dictionary: return {"someone": _start_fight}
func spot(at: Vector2) -> Dictionary: ...      # an E spot (Interactions asks it at its place in the order)
func use(spot: Dictionary) -> void: ...
func clock(minute: float, delta: float) -> void: ...
func district_ready(id, layout, node) -> void: ... # make what it has in a district
func district_unloading(id) -> void: ...
func rooms_built() -> void: ...
func new_night() -> void: ...
func restored() -> void: ...                    # after a saved game is put back
func busy() -> bool: ...                         # a scene of its own under way
```

a field in `Game` (`var my_job: MyJobDirector`) and one line in `main._ready`:
`my_job = missions.add(game.make(&"my_job", MyJobDirector))`. One-time payments and
"once per game" stay in the pure model, as they always were (`test_job_payouts` checks each job
pays once, also across a save written and read back through the format). A film goes through
`game.films.hand_over(kind, film, follow_rate)` / `take_back(target)`. Lines and choices stay in
`Conversations` / `JobLines`; there is no generic story format.

**M015: the new quarters (`src/quarters/`).** The rooms of Canal Market and Lincoln Terrace follow
the same split. `Quarters` (pure, in `Rackets` as `quarters`) holds Danny's priced, once-a-night
dealings there and `QuarterLeads` the three pieces of business that start there (stall insurance,
the State's Attorney's man, the bandleader's card). `QuarterTalk` writes their pages:
`Conversations._say` hands it the new people (`QuarterTalk.handles`) and any `lead_` step, and
`Conversations.open` lets it add the leads' words to Rourke's and the Bird's first page. It keeps
only a **weak** reference back to `Conversations` - the two refer to each other, and a strong pair
kept a freed scene's game alive (`test_scene_cleanup`). `QuarterLife` is a `JobDirector`: the
`quarter` effect (a coffee, a dance passing four minutes, a tune), Kaz Wrobel's fight and hours,
and the Paradise's band and dancers, made in `district_ready` and dropped in `district_unloading`.
The case sheets for the leads are three more functions in `Casebook`; the work marks follow.

## 8. The save

- One JSON file (`user://chicago1932_save.json`); written after deals, hands, films, on sleeping and
  on quitting; no slots (unchanged).
- **Format version 2** (`SaveSchema.VERSION`). Every save from M003 to M013 wrote `"version": 1`
  while sections came and went; they are version 1. Migration 1 -> 2 writes down what M006 did at
  load time (a game from before the voices counts Augie, Rourke and Eddie as met); every other
  section is read as it always was (each owner's `from_dict` fills in what an older save lacks).
- **Checks** before use: a section of the wrong kind, a place or cars without their night, or
  money that is not a number is dropped (that part starts afresh) and listed in `Saves.problems`.
  A file that cannot be read at all is kept beside it (`<name>.unreadable.json`).
- **Sections and owners:** `rackets` (Rackets), `voices` (VoiceLines), `poker` and `slots`
  (BackRooms), `danny` (his BodyCondition), `ward` (Casualties and Rival), `gun` (Armoury),
  `districts` (Districts), `cars` (Fleet), `place` (main), `incidents` (StreetIncidents).
- **Adding state to the save:** add it to its owner's `to_dict`/`from_dict` (or a new section in
  `SaveSchema.SECTIONS` and `Saves.collect`), give old saves a default in `from_dict` or a
  migration step (raise `VERSION`), and add a case to `test_save_schema`; never rename a key
  without a migration. `tests/fixtures/saves/` holds a real save from every milestone.

## 9. Testing

`tools/test.sh` (tiers: `only`, `unit`, `golden`, `playthrough`, `integration`, `full`, `serial`) -
see `tests/README.md`. The golden master (`tests/golden/m013/`) was recorded on the M013 code before
any refactoring and every M014 build reproduces it.

## 10. Known remaining technical debt (not M014 scope)

- `main._ready` is still one long function (~280 lines): it is the build order, and splitting it
  would hide the order that matters; `_update_view` (~70 lines) still assembles the HUD's frame.
- `BackRooms` (716 lines) holds three games' game sides; a split per table would be natural if they grow.
- `Rackets` holds every job's state and much of the economy (a large pure class); the jobs' state
  could move into a jobs section of the save with a migration.
- The ward stays pinned and `MAX_LOADED` is 3 (M015); keeping two districts plus the ward when
  Danny is far from it would need the ward to become unloadable (its rooms, music and people per
  district).
- Ward-local constants in `RiversideInteriors` / `GamingRoomLife` (section 5).
- The scene tests reach into many directors' fields directly (they are the game's test surface);
  a narrower test API would make future refactors cheaper.
- `RourkeJob.report()` has no guard of its own against a second call (the page is the guard).

## 11. Notes for contributors

- New behaviour goes into the director that owns it, or a new director made in `main._ready` with
  `game.make` and named in `Game` - not into `main.gd`. A director that extends another class keeps
  that base free of `Game` (section 3).
- Keep the orders (build, frame, effects, E spots, keys): when two things overlap, the first wins,
  and tests rely on it.
- A difference in the golden master is a change in the game: find out why before anything else.
- Pure first: rules and state in a `RefCounted` with unit tests; the director only connects it to
  the scene.

## Appendix: as found at M013 (`29835b7`, tag `backup-20261122-m013`, local)

140 GDScript files, 28,652 lines, 33 modules; 157 test scripts, 922 tests (750 s in one process).
`main.gd` was 3,078 lines with 120 fields and the game-side behaviour of every milestone: call-outs
and routines, the E spot chain, casualties, cars, beat cops, district content, three films, the
card table, the wheel and the machines, the guns, the cafe job, talk and its twelve effects, the
night and sleeping, the save, incidents, input and menus, Danny's own work, the Bird's scene, the
freight job, Lefty, fistfights, and the frame. Every system reached every other through main's
fields; dialogue effects were applied by one function that knew every mission; the save's
`version` was 1 whatever it held.
