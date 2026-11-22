# Architecture

*Chicago, 1932* is one Godot scene (`src/main/main.tscn`) built in code at start-up. This document
describes how the code is organised. It was written at the start of M014 ("Under the Hood") as the
map of the M013 code and the plan for the refactor, and is updated as the work lands; the sections
marked **(plan)** describe intent, the others what is in the code.

## 1. As found at M013 (`29835b7`, tag `backup-20261122-m013`)

- 140 GDScript files, 28,652 lines, in 33 modules under `src/`; 157 test scripts (79 unit, 78
  integration), 922 tests, all passing in 750 s on one process.
- Pure models (`RefCounted`, no scene) hold the rules and the state: `Rackets` (money in cents,
  the ward's businesses, Rourke, memories, talk, and the state of every job), `Holdem`,
  `Roulette`, `SlotMachine`, `StreetIncidents`, `Weather`, `NightClock`, `CarThefts`, ...
  They are tested without the scene and are not changed by M014.
- Scene nodes draw and move things (`City`, `Interiors`, `Walker`, `Car`, `Hud`, `Soundscape`, ...).
- `src/main/main.gd` (3,078 lines, 283 declarations) is the composition root - and, after thirteen
  milestones, also the place where almost every feature's game-side behaviour was written.

### What `main.gd` does

| Lines | Responsibility |
| --- | --- |
| 1-235 | 120 fields: the services, and the per-feature state of every milestone |
| 237-496 | `_ready`: builds every module in a fixed order, ~90 signal connections |
| 498-608 | call-outs, routines, Leon at Dutch's (M012) |
| 610-650, 1102-1210 | the E spot: 13 kinds in a fixed priority, what E does, the ring under it |
| 652-676, 1909-1972 | rooms wired; people struck down; Danny hurt and down; who is out tonight |
| 678-788, 1035-1062, 1079-1100, 2553-2590 | cars: parking, lasting names, theft, cargo, putting away, the save |
| 790-842, 981-996, 2062-2073, 2273-2310 | beat cops in every district: gunfire heard, violence witnessed, a shopkeeper's report |
| 843-980, 2313-2336, 2591-2616 | a district's content when it is built or let go (street life, beat cop, cars, rooms, plates, seats) |
| 998-1033, 1812-1872, 2738-2826 | the opening, the café's film, the Bird's film: the camera handed to a film and back |
| 1236-1753 | the card table, the wheel, the machines, the gaming room's life |
| 1755-1907 | the Thompson, the parcel, the café job in the street |
| 1974-2096 | talk: its context, pages, answers, twelve kinds of effect, ending a talk |
| 2098-2188 | sleeping into the next evening; the clock and its reminders |
| 2190-2373 | the save written and read in pieces |
| 2220-2311 | the city's incidents: advance, notice, step in, break off |
| 2375-2491, 2913-2966 | input routing; the menu, the map, the status screen, the sound levels |
| 2494-2590, 2699-2884 | Dutch's crate and the Bijou's reel, the Bird's last song, the freight job, Lefty |
| 2656-2697, 2829-2911 | fistfights |
| 2968-3079 | `_process` / `_update_view`: the order of a frame |

### Couplings found

- Every system reaches every other through `main`'s fields; the per-feature state of jobs, tables
  and films sits beside the services in one namespace.
- Dialogue effects are applied by one function that knows every mission (`_apply`); ending a
  talk starts pending fights and releases the Bird's film by name.
- Input priority is one long chain of `if`s in `_unhandled_input`; the same modal questions
  ("is a table open? a film? the menu?") are asked again in `_converse`, `_drowsy_held`,
  `_people_update`, the minimap and the prompt.
- District content is half generic (`_districts` for the neighbours) and half special-cased for the
  ward (`officer`, `street`, `layout.id` checks).
- The save is assembled by `save_game` from twelve sources and read back in four places at
  different points of `_ready`; its `version` has been 1 since M003 whatever the content.

## 2. M014 (plan)

- **Conventions kept.** No Autoloads. `main.tscn` stays the composition root. Pure models stay
  as they are. Directors never define `_process`: `main._process` calls them in the M013 order.
  Initialization order and signal-connection order are kept. Scene nodes keep their places in the
  tree (cars stay children of the root, as before), so drawing order is unchanged.
- **`Game`.** One object with typed references to the running game's shared parts (the
  services and the directors). Main fills it as it builds the game; a director gets `game` in
  its constructor and never reaches into main. Main's own fields for the services remain (the
  tests and tools read them) and point at the same objects.
- **Directors.** Each owns one part of the game-side behaviour and its state:
  `BackRooms` (gaming), `Fleet` (cars), `PoliceForce`, `People`, `Districts`, `Dialogue`,
  `Fights`, `Films`, `Casualties`, `IncidentDirector`, `NightCycle`, `Interactions`, `Modals`.
- **Missions.** A small shared base for the game side of a job (`JobDirector`: hooks for a new
  night, the clock, a district built or let go, the save) and a registry that runs them in a
  fixed order; the pure job models keep their stories, dialogue and money.
- **Coordinates.** District-local data with explicit conversions, and stable location ids for
  the places code refers to by position.
- **Save.** Sections owned by the systems that write them, an explicit format version with
  migrations from every earlier format, validation, and one restoration order.
- **Tests.** A golden master recorded on the M013 code (`tests/golden/m013/`,
  `test_golden_master.gd`); tiered runs in `tools/test.sh`; architecture tests for
  lifecycle, cleanup, migrations, locations and mission invariants.
