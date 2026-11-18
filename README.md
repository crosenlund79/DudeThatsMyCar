# Chicago, 1932 (working title)

A top-down, hand-painted gangster sandbox set in Prohibition-era Chicago, built in Godot 4.7 (GL Compatibility). It grew out of a copy of the HyperCars racing game, whose driving physics it keeps; everything racing-specific has been retired. Design: `docs/chicago_1932_game_design_document.md`. Decisions and the current objective: `docs/PROJECT_BRIEF.md`.

You play a nighttime henchman: the whole game takes place at night. **Milestone 003 (A Night's Work):** the Riverside Ward is a small working criminal neighbourhood. You wake in your flat at 7:30 pm, buy bootleg rye from Sal the barber, sell it at the Copper Owl for more, lean on the bartender and the grocer for protection money, buy .45 rounds from Eddie in the back of the hardware store, and get home to bed before dawn. Walk into the shops (their roofs open up), talk to the people, watch the clock; a few cars and passers-by are out late, a squad car waits in an alley, and the beat cop still comes running when you shoot. The cars now drive like heavy 1930s road cars, and you can see their front wheels steer. **Milestone 004 (Street Smarts):** the cars show at a glance which way they face, a painted badge floats over the door of every place you can walk into (brighter as you come near, the flat in its own house-shaped badge), E goes in and out by any door, and a small map in the bottom-left corner shows the streets round you, those places and the beat cop. **Milestone 005 (The City Has Ears):** you are Danny "Dimes" Mercer, and the protection money you collect belongs to **Rourke**, who sits at his corner table in the Copper Owl and expects his cut. The ward lives on its own: the shops and the club have tills, stock, customers and bills, trade through the night and the day while you sleep, and run short when their tills run dry; prices follow what is on the shelves. Rourke knows only what he sees and hears, people remember how you treated them and talk to each other, and a shopkeeper short of money for his delivery is your problem or your opportunity. A new game opens with Danny's own voice over the ward at night, the Copper Owl's singer is heard through its walls and in full inside, and the night has a soundscape of its own. A guide to the district: `docs/RIVERSIDE_WARD.md`.

## Run it

Open the project in Godot 4.7.x and press Play (the run scene is `src/main/main.tscn`), or from a terminal:

```bash
godot --path .
```

A new game opens with Danny's monologue (about 23 seconds, with subtitles) while the camera drifts over the ward; any key (E, Space, Enter, Esc or a click) skips it. Then you are in your flat next door to the Copper Owl on Marlowe Avenue; your sedan is parked at the curb outside. A saved game, and every evening after sleeping, starts straight in the flat.

| On foot | | Driving | |
| --- | --- | --- | --- |
| W A S D | walk | W | accelerate |
| Mouse | aim | S | brake, then reverse |
| Left click | shoot (the first click draws the gun) | A / D | steer |
| E | talk / go to bed / go in or out by a door / get into the nearest parked car | Space | handbrake |
| 1 – 4 | answer when you talk to someone (or click) | E | get out (the car stops first) |
| E or Esc | walk away from a conversation | | |

F1 shows the controls card, Esc pauses (Q quits while paused). On the pause screen the arrow keys set the sound levels (Up / Down choose Master, Music, Engine, Effects, Voice or Ambience, Left / Right make it quieter or louder; kept in `user://settings.cfg`). Arrow keys mirror WASD.

### A night's work

Look for the badges over the doors (a cocktail glass, a barber's pole, an apple, a hammer, and the house-shaped badge of your flat) and on the minimap in the bottom-left corner; places off the map wait at its rim in their direction. At a door, E takes you in (or you just walk in).

1. Out of your door, turn west along Marlowe Avenue (on foot or in the sedan) to **Sal's Barber Shop** (red awning, barber's pole). Sal sells the rye his Cicero man brings him: about $1.50 a bottle, dearer when his cupboard is nearly bare, cheaper when it is full, a dime off once you are a regular; six is all you can carry.
2. Take it to **the Copper Owl** (the canopy next door to your flat) and sell it to **Augie** behind the bar: about $3 a bottle, more when his cellar has run dry, less when it is full, and only as many as his cellar has room for and his till can pay. You can also ask for his "insurance" once a night; lean on him and he pays more, remembers it, and pays less for your rye that night.
3. **Novak's Grocery** on the corner of Kessler Street, across from the beat cop: protection money, once a night, as much as his till allows (asked, he keeps back what tomorrow's truck costs; leaned on, he empties it and runs for the copper once you have gone). When his till runs short the truck brings less, his shelves empty and he has less to give; you can lend him money for the truck, and he pays it back with a quarter on top.
4. **Rourke** at the corner table in the Copper Owl: the protection money is his (the purse in the top-left corner shows how much of your money is Rourke's). Hand it over and he gives you your end; or tell him it was a thin night, make up a gap from your own pocket, add a little extra, keep some back, or ask for time. He expects what he believes the ward can pay, and he only knows what he sees from his table and what reaches him as talk — sometimes nights later. Short him too often and he cuts your end, then stops Augie buying your rye, then sends his boys to collect.
5. **Lindqvist Hardware** (south side of Marlowe, green awning): through the door at the back, **Eddie** sells boxes of .45 rounds while his crate lasts. The pistol only reloads from the rounds you carry.
6. The clock is at the top of the screen. From 4 am you are told to get home; at dawn the clock stops and waits. Go home and press E at your bed to sleep through to the next evening: money, bottles and rounds stay with you; while you sleep the shops trade, pay their bills and take their deliveries, and the talk goes round.

Progress is saved in `user://chicago1932_save.json` (on Linux `~/.local/share/godot/app_userdata/Chicago, 1932/`) after the opening, after every deal, on sleeping and on quitting; delete the file to start over (with the opening). Saves from before M005 load too: the ward and Rourke start fresh around your money and bottles.

## Sound

The Copper Owl's singer ("Leave the Lights Low") plays all night on one continuous track: through the club's walls it is quieter and muffled (the bass and the beat carry, the words do not), clearer as you come to the door, full and unfiltered inside, and it fades under the city as you walk or drive away; going in and out never restarts it. Under everything: the street's distant traffic (quieter after midnight), dripping alleys, the river and a factory across it, the club's crowd, now and then a far-off horn, a tug on the river or a lid in an alley, the engines of passing cars; doors, shop bells, tills and bottles when you deal; car doors. Indoors the street comes through dull. Danny's monologue and the song are the user's recordings; how the song was cleaned (its stray noise at the very end trimmed with FFmpeg) is in `assets/audio/README.md`.

## Replace the art and sound

Every image and sound is a `template_` file in `assets/` (or, for the song and the monologue, the user's recording under its own name) that you can override by dropping your own file into `custom/` (in the project while developing, or next to an exported Windows/Linux game, no rebuild needed; restart the game to see or hear it). Sounds can be OGG, WAV or MP3, e.g. `custom/audio/music/copper_owl_jazz.mp3`. The full list with sizes and override paths: `docs/ASSET_SPECS.md`; the rules: `assets/README.md`. The template art is generated by `tools/template_art/` and the template sounds by `tools/template_audio/` (Python with Pillow and numpy; ffmpeg for the M005 sounds). Car bodies leave out the front tyres: they are a separate image (`cars/wheel`) turned by the steering.

## Tests

```bash
godot --headless --path . --import
```

```bash
godot --headless --path . --fixed-fps 60 -s addons/gut/gut_cmdln.gd
```

GUT 9.7.1 is vendored in `addons/gut/`. More in `tests/README.md`; the manual checklists for look and feel are in `tests/manual/`.

## Layout

| Folder | What lives there |
| --- | --- |
| `src/driving/` | car model and car scene (from HyperCars; road-car steering since M003), the vehicle types |
| `src/city/` | the district layout, the city builder, buildings in perspective, night atmosphere |
| `src/actors/`, `src/player/` | people on foot; the player controller (walking, driving, getting in and out, shooting) |
| `src/weapons/`, `src/police/` | the handgun and bullets; the beat cop (decisions, navigation, body) |
| `src/interiors/` | rooms you can walk into: plans, the cut-away view, walls |
| `src/economy/`, `src/night/` | the ward's businesses, Rourke, memories and talk, money, deals and conversations, the save file; the night clock |
| `src/street/` | passers-by and traffic |
| `src/camera/`, `src/ui/`, `src/presentation/` | camera, HUD (dialogue, clock, money, minimap, sound levels), place markers, lights, wheels and sound of the car, the night's soundscape |
| `src/audio/`, `src/opening/` | sound settings and the soundscape's mixing rules; the opening narration |
| `src/assets/` | the override resolver and the asset catalogue |
| `src/main/` | the composition root (run scene) |
| `docs/` | brief, rules, design document, asset list, district guide; `docs/archive/hypercars/` keeps the racing game's documents |

Working rules for Claude Code: `CLAUDE.md` and `docs/GODOT_CLAUDE_GUIDELINES.md`.
