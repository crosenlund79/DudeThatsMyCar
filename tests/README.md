# Testing baseline (Godot 4)

Testing starts with the **first implemented module**, not with speculative starter-pack scaffolding.

- Pick **GUT or GdUnit4**, compatible with the pinned Godot 4.x minor version, once in `docs/PROJECT_BRIEF.md`.
- A **module** is an implemented component with one responsibility (usually `src/<module>/`). Give its essential logic headless automated tests where feasible.
- An **important interaction** is a contract between two or more modules that affects gameplay/state. Add automated integration tests for those contracts, updating them when either side changes.
- Visual, animation, audio and control **feel** also require a short, relevant **manual checklist**, since headless tests cannot establish quality of presentation.
- Document exact commands to run logic tests headlessly, and keep tests practical. Do not claim tests passed if Godot, the runner or dependencies are unavailable; state **not run and why**.
- Asset resolver tests must cover override precedence, missing/invalid fallback, supported formats and override-root selection, using an injected temporary folder (see `assets/README.md`). Exported-game verification follows guideline 4; if no export was approved, report it as pending.

## In this project

- **Run everything:** `godot --headless --path . --import` (once, and again after adding a `class_name` script), then `godot --headless --path . --fixed-fps 60 -s addons/gut/gut_cmdln.gd`. `--fixed-fps 60` runs physics at full speed regardless of real time.
- **Scene tests** (`tests/integration/`) start the real game scene with a scripted command source instead of the keyboard and mouse (`tests/support/city_test.gd`: `hold`, `press_e`, `walk_to`, `seat_in`, `park`; M003: `answer`, `answer_with`, `talk_to`, `at_the_streetcar_stop`; M004: `path_in_room` and `walk_in_to`, which walk into a room off the sidewalk and round its furniture with the normal movement). They never write the player's save file (`main.save_path = ""`) and run with the passers-by and traffic cleared unless the script sets `quiet_streets = false` (`test_street_life.gd`). The night begins at home since M003; street tests step out to the streetcar stop first. One test file (`test_input_mapping.gd`) drives the game through Godot's real input actions.
- **Screenshots** need a display: `xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -s tests/support/screenshot_tour.gd -- <output dir> [street walk drive garage river alley hotel wide ...]` (M003 shots: `home traffic steer club augie barber grocery eddie squad_car wake`; M004: `cars grocery_door grocery_marker drive_markers`; see the script's header).
- **Frame rate:** `xvfb-run -a godot --path . --rendering-driver opengl3 -s tests/support/perf_probe.gd` prints the frame rate at home, inside the Copper Owl, on Marlowe Avenue with traffic, driving, and with lamps, haze, vignette, ground and buildings switched off in turn.
- **Asset list:** `docs/ASSET_SPECS.md` is generated from the catalogue (`godot --headless --path . -s tests/support/asset_specs_writer.gd`); a unit test fails when it is out of date.
- **Skipped files:** GUT skips a test file that fails to parse and still reports "All tests passed". After adding or changing tests, check the script count in the summary (and the log for `Parse Error`).
- **Long scenarios** (police pursuit, driving routes) run in simulated time with `--fixed-fps 60`; helpers `drive_route` (a careful W / A / S / D driver), `click` and `aim_for` live in `tests/support/city_test.gd`.
