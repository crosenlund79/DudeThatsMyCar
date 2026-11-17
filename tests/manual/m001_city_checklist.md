# Manual checklist — Milestone 001: the Riverside Ward at night

Headless tests cannot judge look and feel. Play `src/main/main.tscn` (1280×720 and full screen) and tick each item; note anything that fails in `docs/BACKLOG.md` (not as a task).

## First impression (stand still for ten seconds)
- [ ] It is night: cool tint, warm lamplight, lit windows, the Copper Owl's neon and canopy bulbs, the hotel's lit windows across the avenue.
- [ ] Buildings read as buildings: facades with windows and fire escapes leaning away from the centre, flat roofs with chimneys, vents, skylights, stair huts, water tanks.
- [ ] Wet streets: dark puddles, lamp reflections streaking towards the centre of the screen; steam from a manhole; the streetcar tracks down Marlowe Avenue.
- [ ] Nothing looks like a debug shape; the art is consistent in style.
- [ ] The controls card (top right) fades after about 12 s; F1 brings it back.

## On foot
- [ ] WASD walks at a natural pace in eight directions; the gangster faces the mouse reticle while walking any way.
- [ ] He cannot walk through buildings, lamp posts, crates or parked cars; he slides along walls smoothly.
- [ ] He fits through the narrow gangways between houses (e.g. off Calloway Street) into the yards and alleys.
- [ ] The location line (top left) names the street, crossing or alley.
- [ ] Near a parked car the prompt "E  Get in the …" appears; E gets in.

## Driving (try both the Roadster and the Sedan)
- [ ] W accelerates, S brakes then reverses, A / D steer; the car does not turn on the spot and steers the other way in reverse.
- [ ] Space: handbrake turns into alleys and round corners; the tail slides and the tyres squeal.
- [ ] It still feels like HyperCars at speed: momentum, slide, bounce off walls.
- [ ] The roadster feels quicker and looser, the sedan heavier and more planted.
- [ ] Headlights light the street ahead; tail lamps brighten when braking; the engine note follows speed.
- [ ] Hitting a parked car shoves it a little; it stops on its handbrake.
- [ ] The camera follows smoothly, looks ahead and eases out a little at speed; no jitter, no excessive zoom; the car is never hidden by a roof.
- [ ] Cars cannot pass the barricades, the river railing, the raised bridge gates or the railroad embankment, and every one of those is visible (no invisible walls).

## Getting out
- [ ] E stops the car (if moving) and puts the gangster beside the driver's door.
- [ ] With the driver's door against a wall he gets out on the other side; parked tight between walls the notice "No room to get out here." appears and he stays in.
- [ ] He never ends up inside a wall, a car or the river.

## Pause and exit
- [ ] Esc pauses everything (Esc again resumes), Q quits while paused.

## Replaceable art (optional)
- [ ] Put a PNG at `custom/graphics/cars/coupe.png` (any resolution, 2.2:1, nose right), restart: the roadster uses it. Remove it: the template returns.
