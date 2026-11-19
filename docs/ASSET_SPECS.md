# Replaceable assets — Chicago, 1932

Generated from `src/assets/asset_catalog.gd` (the authoritative contract) by
`tests/support/asset_specs_writer.gd`. Override rules: `assets/README.md`.

Put your file at the **override path** inside `custom/` (the project folder while developing;
next to the executable in an exported Windows/Linux game). Restart the game to see it. Any
resolution works if you keep the template's **aspect ratio, orientation and layout**; a
missing or invalid file falls back to the packaged `template_` image. A facade's `_lit`
image is its window light at night and is replaced separately. Cars and people face
**right** (+X). Facades repeat every 128 world px along a wall.

## Graphics (PNG)

| Logical name | Override path | Template px | Kind | In the world | Notes |
| --- | --- | --- | --- | --- | --- |
| `cars/ambulance` | `custom/graphics/cars/ambulance.png` | 210x84 | sprite (image, scaled to its display size) | 92x37 | M010: a 1930s ambulance from above, nose right, every tyre painted in (it drives itself to the scene; never the player's). |
| `cars/coupe` | `custom/graphics/cars/coupe.png` | 176x80 | sprite (image, scaled to its display size) | 80x36 | Roadster, top-down, nose right, centred, transparent background; front tyres left out. Headlamps at (32, +-7.6), tail lamps at (-35.5, +-7.2) display px. |
| `cars/coupe_b` | `custom/graphics/cars/coupe_b.png` | 176x80 | sprite (image, scaled to its display size) | 80x36 | Roadster, second paint scheme; same contract. |
| `cars/dump_truck` | `custom/graphics/cars/dump_truck.png` | 280x110 | sprite (image, scaled to its display size) | 112x44 | M009: Brennan Coal & Ice's 1930s dump truck, top-down, nose right, centred, transparent background; front tyres left out (cars/wheel, drawn larger). Long bonnet, upright grille and headlamps (48, +-13) at the right; coal bed and red tail lamps (-53, +-17) at the left; dual rear tyres painted under the bed. |
| `cars/fire_engine` | `custom/graphics/cars/fire_engine.png` | 300x104 | sprite (image, scaled to its display size) | 130x45 | M010: a red pumper from above, nose right: bonnet, bell, open cab, hose reel, the ladder along the top; every tyre painted in. |
| `cars/police` | `custom/graphics/cars/police.png` | 176x80 | sprite (image, scaled to its display size) | 80x36 | Police squad car (sedan body): black, POLICE across the roof, siren, spotlight. |
| `cars/school_bus` | `custom/graphics/cars/school_bus.png` | 340x102 | sprite (image, scaled to its display size) | 140x42 | M009: St. Brendan's parish school bus, early 1930s, top-down, nose right, centred, transparent background; front tyres left out (cars/wheel, drawn larger). Short bonnet, radiator and headlamps (65, +-13) at the right, emergency door and red tail lamps (-67, +-16) at the left; SCHOOL BUS on the roof. |
| `cars/sedan` | `custom/graphics/cars/sedan.png` | 176x80 | sprite (image, scaled to its display size) | 80x36 | Sedan, top-down, nose right, centred, transparent background; front tyres left out (cars/wheel). Keep the nose recognisable: radiator, headlamps (31, +-7 display px from the centre) and windscreen at the right, red tail lamps (-34, +-11) at the left. |
| `cars/sedan_b` | `custom/graphics/cars/sedan_b.png` | 176x80 | sprite (image, scaled to its display size) | 80x36 | Sedan, second paint scheme; same contract. |
| `cars/wheel` | `custom/graphics/cars/wheel.png` | 48x20 | sprite (image, scaled to its display size) | 14x6 | Front tyre (whitewall) from above, rolling direction left-right; drawn under the body on both sides and turned with the steering (car bodies leave the front tyres out). |
| `characters/attendant` | `custom/graphics/characters/attendant.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | M010: an ambulance attendant: white jacket, white peaked cap. |
| `characters/barber` | `custom/graphics/characters/barber.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | Sal the barber in his white coat. |
| `characters/bartender` | `custom/graphics/characters/bartender.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | Augie the bartender: white sleeves, black vest, bow tie; frames like the player's. |
| `characters/boss` | `custom/graphics/characters/boss.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | Rourke, the boss: charcoal overcoat, grey homburg, a lit cigar. |
| `characters/clerk` | `custom/graphics/characters/clerk.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | Lindqvist the hardware man in his dust coat. |
| `characters/croupier` | `custom/graphics/characters/croupier.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | M011 the gaming room's croupier: shirt sleeves, black waistcoat, bow tie, a green eyeshade; frames like the player's. |
| `characters/dealer` | `custom/graphics/characters/dealer.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | Eddie, the back-room gun dealer: dark green suit and fedora. |
| `characters/dutch` | `custom/graphics/characters/dutch.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | M009: Dutch, who keeps the night lunch counter in the Riverfront Yards: rolled sleeves, white apron, fair hair. |
| `characters/feeney` | `custom/graphics/characters/feeney.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | M009: Mr. Feeney, who manages the Bijou in Halloran Square: midnight-blue dinner jacket, bow tie, sandy red hair. |
| `characters/fireman` | `custom/graphics/characters/fireman.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | M010: a fireman at the scene: black rubber coat with brass clasps, a leather fire helmet with a brass shield. |
| `characters/gangster` | `custom/graphics/characters/gangster.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | Player on foot: 5 frames of 64x64 in a row (idle, step, passing, other step, passing), facing right, centred. |
| `characters/gangster_armed` | `custom/graphics/characters/gangster_armed.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | The player with the pistol drawn: same frames, right arm reaching forward (the pistol is drawn separately). |
| `characters/grocer` | `custom/graphics/characters/grocer.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | Mr. Novak the grocer: apron and flat cap. |
| `characters/lady` | `custom/graphics/characters/lady.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | A woman in a coat and cloche hat (passer-by). |
| `characters/patron_man` | `custom/graphics/characters/patron_man.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | A man in evening clothes (club guest, late passer-by). |
| `characters/patron_woman` | `custom/graphics/characters/patron_woman.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | A woman in an evening dress with a bob. |
| `characters/police` | `custom/graphics/characters/police.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | Police officer: 5 frames like the player's, facing right, centred. |
| `characters/police_armed` | `custom/graphics/characters/police_armed.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | M008: the police officer with his revolver drawn (right arm forward; the gun is drawn separately). |
| `characters/rival` | `custom/graphics/characters/rival.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | M006: Lefty Moran, a North Side gangster (camel overcoat, white fedora, cigar); same frames as the gangster. |
| `characters/rival_armed` | `custom/graphics/characters/rival_armed.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | M006: Lefty Moran with his pistol drawn (right arm forward). |
| `characters/singer` | `custom/graphics/characters/singer.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | M006: the Bird, the Copper Owl's singer, facing right (towards the room). Her frames are gestures, not steps: 0 hands at the microphone, 1 left arm out, 2 arms open, 3 right arm out, 4 a hand to her heart. |
| `characters/vet` | `custom/graphics/characters/vet.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | M006: Doc Pettibone, the veterinarian who patches up gangsters (white coat, bow tie). |
| `characters/worker` | `custom/graphics/characters/worker.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | A working man in a flat cap (passer-by). |
| `city/alley` | `custom/graphics/city/alley.png` | 256x256 | tile (seamless in both directions) | 160 px per repeat | Brick alley paving. |
| `city/asphalt` | `custom/graphics/city/asphalt.png` | 256x256 | tile (seamless in both directions) | 256 px per repeat | Wet street asphalt. |
| `city/cobbles` | `custom/graphics/city/cobbles.png` | 256x256 | tile (seamless in both directions) | 112 px per repeat | Granite setts (streetcar tracks). |
| `city/curb` | `custom/graphics/city/curb.png` | 128x24 | strip (seamless left-right, drawn along a line) | 8 px wide | Stone curb; sidewalk side at the top. |
| `city/fence` | `custom/graphics/city/fence.png` | 128x16 | strip (seamless left-right, drawn along a line) | 8 px wide | Wooden board fence. |
| `city/grass` | `custom/graphics/city/grass.png` | 256x256 | tile (seamless in both directions) | 256 px per repeat | M010: a park lawn at night (Halloran Park): dark mown grass, a few fallen leaves; seamless. |
| `city/lot` | `custom/graphics/city/lot.png` | 256x256 | tile (seamless in both directions) | 256 px per repeat | Yards and lots: cinders, dirt, weeds. |
| `city/quay` | `custom/graphics/city/quay.png` | 128x32 | strip (seamless left-right, drawn along a line) | 16 px wide | Stone river edge with railing; water side at the bottom. |
| `city/rails` | `custom/graphics/city/rails.png` | 128x40 | strip (seamless left-right, drawn along a line) | 22 px wide | One streetcar track (two rails), transparent between. |
| `city/sidewalk` | `custom/graphics/city/sidewalk.png` | 256x256 | tile (seamless in both directions) | 192 px per repeat | Concrete sidewalk slabs. |
| `city/water` | `custom/graphics/city/water.png` | 256x256 | tile (seamless in both directions) | 320 px per repeat | River water. |
| `decals/drain` | `custom/graphics/decals/drain.png` | 48x24 | sprite (image, scaled to its display size) | 24x12 | Storm drain grate. |
| `decals/grime` | `custom/graphics/decals/grime.png` | 768x64 | sheet (horizontal strip of equal frames) | 12 frames, each 26x26 | M010: the street's rubbish, flat on the ground (never solid), one 64x64 frame each: 0 open newspaper, 1 folded newspaper, 2 paper scraps, 3 bottle, 4 broken bottle, 5 flattened box, 6 burst box, 7 coal dust, 8 soot stain, 9 loose board, 10 brick rubble, 11 worn wet stain; drawn at 0.75-1.9 times the display size, any rotation. |
| `decals/litter` | `custom/graphics/decals/litter.png` | 48x48 | sprite (image, scaled to its display size) | 18x18 | Newspaper litter. |
| `decals/manhole` | `custom/graphics/decals/manhole.png` | 48x48 | sprite (image, scaled to its display size) | 24x24 | Manhole cover. |
| `decals/oil` | `custom/graphics/decals/oil.png` | 96x96 | sprite (image, scaled to its display size) | 52x52 | Oil stain. |
| `decals/puddle` | `custom/graphics/decals/puddle.png` | 128x80 | sprite (image, scaled to its display size) | 96x60 | Puddle (semi-transparent). |
| `decals/scorch` | `custom/graphics/decals/scorch.png` | 128x128 | sprite (image, scaled to its display size) | 150x120 | M010 the black scorch on the road where the Packard burned (flat, soft-edged). |
| `facades/brick_brown` | `custom/graphics/facades/brick_brown.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Brown-brick shops (shopfronts below). |
| `facades/brick_brown_lit` | `custom/graphics/facades/brick_brown_lit.png` | 256x192 | light (additive night light; transparent where dark) | matches its facade | Window light for brick_brown. |
| `facades/brick_red` | `custom/graphics/facades/brick_red.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Red-brick apartments. |
| `facades/brick_red_lit` | `custom/graphics/facades/brick_red_lit.png` | 256x192 | light (additive night light; transparent where dark) | matches its facade | Window light for brick_red. |
| `facades/club` | `custom/graphics/facades/club.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | The Copper Owl jazz club. |
| `facades/club_lit` | `custom/graphics/facades/club_lit.png` | 256x192 | light (additive night light; transparent where dark) | matches its facade | Window and bulb light for club. |
| `facades/factory` | `custom/graphics/facades/factory.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | M008: works building: sooty brick between pilasters, tall steel-framed windows, a sliding freight door. |
| `facades/factory_lit` | `custom/graphics/facades/factory_lit.png` | 256x192 | light (additive night light; transparent where dark) | matches its facade | Window light for factory. |
| `facades/garage` | `custom/graphics/facades/garage.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Doyle's Garage: painted brick, garage doors. |
| `facades/garage_lit` | `custom/graphics/facades/garage_lit.png` | 256x192 | light (additive night light; transparent where dark) | matches its facade | Window light for garage. |
| `facades/greystone` | `custom/graphics/facades/greystone.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Limestone greystone flats. |
| `facades/greystone_lit` | `custom/graphics/facades/greystone_lit.png` | 256x192 | light (additive night light; transparent where dark) | matches its facade | Window light for greystone. |
| `facades/party` | `custom/graphics/facades/party.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Blank side wall between buildings. |
| `facades/rear` | `custom/graphics/facades/rear.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Alley side with fire escapes. |
| `facades/rear_lit` | `custom/graphics/facades/rear_lit.png` | 256x192 | light (additive night light; transparent where dark) | matches its facade | Window and bulb light for rear. |
| `facades/stack` | `custom/graphics/facades/stack.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | M008: a works smokestack's walls: small dark brick, iron bands, soot (no windows). |
| `facades/steel` | `custom/graphics/facades/steel.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Steel truss (the raised bascule bridge). |
| `facades/stone` | `custom/graphics/facades/stone.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Granite embankment wall. |
| `facades/tenement` | `custom/graphics/facades/tenement.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | M008: buff common-brick flats, paired sash windows, a stoop door. |
| `facades/tenement_lit` | `custom/graphics/facades/tenement_lit.png` | 256x192 | light (additive night light; transparent where dark) | matches its facade | Window light for tenement (more windows lit than elsewhere). |
| `facades/warehouse` | `custom/graphics/facades/warehouse.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Warehouse: steel windows, loading doors. |
| `facades/warehouse_lit` | `custom/graphics/facades/warehouse_lit.png` | 256x192 | light (additive night light; transparent where dark) | matches its facade | Window light for warehouse. |
| `fences/boards` | `custom/graphics/fences/boards.png` | 128x48 | fence (seamless left-right fence face, drawn upright along a fence line (ground at the bottom edge)) | 64 px per repeat, 24 px high | M010: a weathered board fence standing up, seen face on: seamless left-right, ground at the bottom edge, a lit top edge. |
| `fences/chain` | `custom/graphics/fences/chain.png` | 128x48 | fence (seamless left-right fence face, drawn upright along a fence line (ground at the bottom edge)) | 64 px per repeat, 24 px high | M010: chain-link between pipe posts (the mesh semi-transparent), a top pipe and barbed wire; seamless left-right. |
| `fences/iron` | `custom/graphics/fences/iron.png` | 128x48 | fence (seamless left-right fence face, drawn upright along a fence line (ground at the bottom edge)) | 64 px per repeat, 24 px high | M010: a wrought-iron railing with spear tops between stone-capped posts; transparent between the bars; seamless left-right. |
| `fx/fireball` | `custom/graphics/fx/fireball.png` | 128x128 | light (additive night light; transparent where dark) | 260x260 | M010 the blast's ball of fire (additive; grown and faded by the game). |
| `fx/flame` | `custom/graphics/fx/flame.png` | 48x64 | light (additive night light; transparent where dark) | 20x30 | M010 one tongue of flame, base at the bottom (additive; flickered and stretched by the game). |
| `fx/fog` | `custom/graphics/fx/fog.png` | 256x256 | tile (seamless in both directions) | 900 px per repeat | M010: the street fog's banks - soft grey clouds (lighter = thicker), seamless both ways; drifted twice over the streets at different scales. |
| `fx/glow` | `custom/graphics/fx/glow.png` | 128x128 | light (additive night light; transparent where dark) | 128x128 | Round warm glow (lamp halos, light spill). |
| `fx/impact_dust` | `custom/graphics/fx/impact_dust.png` | 48x48 | sprite (image, scaled to its display size) | 22x22 | Brick dust where a bullet strikes a wall. |
| `fx/muzzle_flash` | `custom/graphics/fx/muzzle_flash.png` | 64x40 | light (additive night light; transparent where dark) | 34x21 | Muzzle flash; the muzzle is at the left edge, middle. |
| `fx/reflection` | `custom/graphics/fx/reflection.png` | 64x192 | light (additive night light; transparent where dark) | 22x70 | Light reflected on wet ground; the light is at the top. |
| `fx/smoke_plume` | `custom/graphics/fx/smoke_plume.png` | 96x96 | sprite (image, scaled to its display size) | 60x60 | M010 a thick dark puff of smoke (the game drifts and grows them into a column). |
| `fx/spark` | `custom/graphics/fx/spark.png` | 32x32 | light (additive night light; transparent where dark) | 12x12 | Spark where a bullet strikes. |
| `fx/steam` | `custom/graphics/fx/steam.png` | 64x64 | sprite (image, scaled to its display size) | 48x48 | Steam / smoke puff. |
| `fx/tracer` | `custom/graphics/fx/tracer.png` | 64x8 | light (additive night light; transparent where dark) | 48x5 | Bullet streak; the bullet is at the right end. |
| `interiors/back_bar` | `custom/graphics/interiors/back_bar.png` | 420x42 | sprite (image, scaled to its display size) | 180x18 | Shelves of bottles behind the bar. |
| `interiors/bandstand` | `custom/graphics/interiors/bandstand.png` | 128x240 | sprite (image, scaled to its display size) | 60x112 | Bandstand along a wall (right edge), curved front to the left. |
| `interiors/bar_counter` | `custom/graphics/interiors/bar_counter.png` | 420x56 | sprite (image, scaled to its display size) | 180x24 | The Copper Owl's bar; customers along the bottom edge. |
| `interiors/barber_chair` | `custom/graphics/interiors/barber_chair.png` | 72x56 | sprite (image, scaled to its display size) | 32x25 | Barber chair, the sitter facing right. |
| `interiors/barber_counter` | `custom/graphics/interiors/barber_counter.png` | 336x44 | sprite (image, scaled to its display size) | 150x20 | Mirror and marble counter with tonics. |
| `interiors/bed` | `custom/graphics/interiors/bed.png` | 76x136 | sprite (image, scaled to its display size) | 34x62 | Iron bed, headboard at the top. |
| `interiors/bench` | `custom/graphics/interiors/bench.png` | 160x40 | sprite (image, scaled to its display size) | 70x18 | Waiting bench with a newspaper. |
| `interiors/cabinet` | `custom/graphics/interiors/cabinet.png` | 64x52 | sprite (image, scaled to its display size) | 30x24 | Tall cupboard (Sal keeps the rye in it). |
| `interiors/card_table` | `custom/graphics/interiors/card_table.png` | 112x112 | sprite (image, scaled to its display size) | 50x50 | Back-room card table with two chairs, centred. |
| `interiors/chair` | `custom/graphics/interiors/chair.png` | 36x36 | sprite (image, scaled to its display size) | 16x16 | M010 a bentwood chair, its back at the top (turned by the game). |
| `interiors/coat_rack` | `custom/graphics/interiors/coat_rack.png` | 40x40 | sprite (image, scaled to its display size) | 18x18 | Coat stand with two coats. |
| `interiors/door` | `custom/graphics/interiors/door.png` | 64x12 | sprite (image, scaled to its display size) | 28x5 | Door leaf from above; hinge at the left end (stretched to the doorway). |
| `interiors/exam_table` | `custom/graphics/interiors/exam_table.png` | 128x64 | sprite (image, scaled to its display size) | 62x31 | M006: the vet's steel examining table with a sheet and a strap. |
| `interiors/flat_table` | `custom/graphics/interiors/flat_table.png` | 112x112 | sprite (image, scaled to its display size) | 50x50 | Kitchen table with two chairs, centred. |
| `interiors/floor_boards` | `custom/graphics/interiors/floor_boards.png` | 256x256 | tile (seamless in both directions) | 128 px per repeat | Worn pine floorboards (shops, the flat). |
| `interiors/floor_carpet` | `custom/graphics/interiors/floor_carpet.png` | 256x256 | tile (seamless in both directions) | 128 px per repeat | M010 worn wine-red carpet with a faded diamond lattice (the back room). |
| `interiors/floor_gaming` | `custom/graphics/interiors/floor_gaming.png` | 256x256 | tile (seamless in both directions) | 128 px per repeat | M011 dark stained oak boards, scuffed and burnt (the gaming room). |
| `interiors/floor_parquet` | `custom/graphics/interiors/floor_parquet.png` | 256x256 | tile (seamless in both directions) | 128 px per repeat | Oak parquet (the Copper Owl). |
| `interiors/floor_tile` | `custom/graphics/interiors/floor_tile.png` | 128x128 | tile (seamless in both directions) | 64 px per repeat | Black-and-cream checkerboard tile (the barbershop). |
| `interiors/gun_crate` | `custom/graphics/interiors/gun_crate.png` | 112x56 | sprite (image, scaled to its display size) | 50x25 | Open crate of wrapped pistols and boxes of rounds. |
| `interiors/kennel` | `custom/graphics/interiors/kennel.png` | 80x72 | sprite (image, scaled to its display size) | 38x34 | M006: a wire kennel with a sleeping basset hound. |
| `interiors/medicine_cabinet` | `custom/graphics/interiors/medicine_cabinet.png` | 112x40 | sprite (image, scaled to its display size) | 56x20 | M006: the vet's cabinet of bottles, wall side at the top. |
| `interiors/microphone` | `custom/graphics/interiors/microphone.png` | 48x48 | sprite (image, scaled to its display size) | 20x20 | M006: the Bird's ribbon microphone on its stand, from above; the grille faces the singer (right). |
| `interiors/palm` | `custom/graphics/interiors/palm.png` | 72x72 | sprite (image, scaled to its display size) | 28x28 | Potted palm. |
| `interiors/piano` | `custom/graphics/interiors/piano.png` | 128x88 | sprite (image, scaled to its display size) | 56x38 | Baby grand, keyboard and bench at the left. |
| `interiors/poker_table` | `custom/graphics/interiors/poker_table.png` | 160x160 | sprite (image, scaled to its display size) | 72x72 | M010 the Copper Owl's back-room poker table: baize, rail, chips, cards, an ashtray (the chairs are separate), centred. |
| `interiors/produce` | `custom/graphics/interiors/produce.png` | 132x56 | sprite (image, scaled to its display size) | 60x25 | Three crates of apples, potatoes and cabbages. |
| `interiors/radio` | `custom/graphics/interiors/radio.png` | 44x34 | sprite (image, scaled to its display size) | 18x14 | Cathedral radio, grille towards the bottom. |
| `interiors/roulette_rotor` | `custom/graphics/interiors/roulette_rotor.png` | 96x96 | sprite (image, scaled to its display size) | 32x32 | M011 the wheel head from above, drawn over the table's bowl and turned by the game while it spins: 37 pockets in the European order clockwise from the zero at the top, the brass turret. |
| `interiors/roulette_table` | `custom/graphics/interiors/roulette_table.png` | 288x136 | sprite (image, scaled to its display size) | 128x60 | M011 the gaming room's wheel table from above: rail, green baize, the wheel's bowl at the left end (centre 58 px in from the left of the template, middle), the single-zero layout to the right. |
| `interiors/rug` | `custom/graphics/interiors/rug.png` | 160x100 | sprite (image, scaled to its display size) | 72x45 | Oval rag rug (flat on the floor). |
| `interiors/sacks` | `custom/graphics/interiors/sacks.png` | 64x64 | sprite (image, scaled to its display size) | 28x28 | Flour and sugar sacks. |
| `interiors/shelf_grocery` | `custom/graphics/interiors/shelf_grocery.png` | 260x44 | sprite (image, scaled to its display size) | 118x20 | Wall shelves of tins and boxes. |
| `interiors/shelf_hardware` | `custom/graphics/interiors/shelf_hardware.png` | 260x44 | sprite (image, scaled to its display size) | 118x20 | Wall shelves of paint, rope, nails and tools. |
| `interiors/shop_counter` | `custom/graphics/interiors/shop_counter.png` | 220x56 | sprite (image, scaled to its display size) | 96x24 | Shop counter with cash register and scale; the shopkeeper's side at the top. |
| `interiors/side_table` | `custom/graphics/interiors/side_table.png` | 72x72 | sprite (image, scaled to its display size) | 30x30 | M011 a small round marble-topped table: two glasses, an ashtray, a cigarette burning (chairs are separate), centred. |
| `interiors/sideboard` | `custom/graphics/interiors/sideboard.png` | 112x40 | sprite (image, scaled to its display size) | 56x20 | M010 a sideboard of bottles, glasses and a cigar box, wall side at the top. |
| `interiors/slot_machine_bell` | `custom/graphics/interiors/slot_machine_bell.png` | 64x76 | sprite (image, scaled to its display size) | 28x34 | M011 the Bell, a nickel machine like the Owl (red and gold). |
| `interiors/slot_machine_owl` | `custom/graphics/interiors/slot_machine_owl.png` | 64x76 | sprite (image, scaled to its display size) | 28x34 | M011 the Owl, a nickel machine against the wall (wall at the top): cast cabinet with its crest, the reel window and the payout cup at the front (bottom), the lever on the right. |
| `interiors/slot_machine_star` | `custom/graphics/interiors/slot_machine_star.png` | 64x76 | sprite (image, scaled to its display size) | 28x34 | M011 the Star, a nickel machine like the Owl (green and silver). |
| `interiors/smoke` | `custom/graphics/interiors/smoke.png` | 128x128 | sprite (image, scaled to its display size) | 110x110 | M010 a soft drift of cigar smoke hanging over the card table (mostly transparent). |
| `interiors/spittoon` | `custom/graphics/interiors/spittoon.png` | 24x24 | sprite (image, scaled to its display size) | 9x9 | M011 a dented brass spittoon. |
| `interiors/stool` | `custom/graphics/interiors/stool.png` | 36x36 | sprite (image, scaled to its display size) | 14x14 | Bar stool. |
| `interiors/stove` | `custom/graphics/interiors/stove.png` | 60x56 | sprite (image, scaled to its display size) | 26x24 | Small kitchen range with a kettle. |
| `interiors/table_club` | `custom/graphics/interiors/table_club.png` | 128x128 | sprite (image, scaled to its display size) | 56x56 | Round club table with lamp and three chairs, centred. |
| `interiors/tall_clock` | `custom/graphics/interiors/tall_clock.png` | 40x32 | sprite (image, scaled to its display size) | 18x14 | M011 a tall-case clock against the wall (wall at the top). |
| `interiors/wall_prints` | `custom/graphics/interiors/wall_prints.png` | 140x26 | sprite (image, scaled to its display size) | 64x12 | M011 three framed prints hanging on a wall (racehorses, a prize fighter); the wall at the top. |
| `props/awning_green` | `custom/graphics/props/awning_green.png` | 160x64 | sprite (image, scaled to its display size) | 84x34 | Shop awning; wall side at the top. |
| `props/awning_red` | `custom/graphics/props/awning_red.png` | 160x64 | sprite (image, scaled to its display size) | 84x34 | Shop awning; wall side at the top. |
| `props/barber_pole` | `custom/graphics/props/barber_pole.png` | 32x32 | sprite (image, scaled to its display size) | 14x14 | Barber's pole beside the shop door. |
| `props/barrel` | `custom/graphics/props/barrel.png` | 48x48 | sprite (image, scaled to its display size) | 20x20 | Barrel. |
| `props/barricade` | `custom/graphics/props/barricade.png` | 192x64 | sprite (image, scaled to its display size) | 96x32 | Street-closed sawhorse. |
| `props/boxcar` | `custom/graphics/props/boxcar.png` | 320x96 | sprite (image, scaled to its display size) | 150x46 | M008: a freight boxcar on the sidings from above, long axis along X. |
| `props/call_box` | `custom/graphics/props/call_box.png` | 40x40 | sprite (image, scaled to its display size) | 18x18 | Police call box on its post. |
| `props/car_wreck` | `custom/graphics/props/car_wreck.png` | 176x80 | sprite (image, scaled to its display size) | 80x36 | M010 the Packard burnt out: blackened shell, the glass gone, embers (nose right). |
| `props/crate` | `custom/graphics/props/crate.png` | 64x64 | sprite (image, scaled to its display size) | 26x26 | Wooden crate. |
| `props/crates` | `custom/graphics/props/crates.png` | 96x96 | sprite (image, scaled to its display size) | 44x44 | Stack of crates. |
| `props/film_can` | `custom/graphics/props/film_can.png` | 48x48 | sprite (image, scaled to its display size) | 15x15 | M009: the Bijou's lost reel - a flat round tin film can from above. |
| `props/fire_escape` | `custom/graphics/props/fire_escape.png` | 128x40 | sprite (image, scaled to its display size) | 64x20 | Iron fire-escape landing; wall side at the top. |
| `props/flowerbed` | `custom/graphics/props/flowerbed.png` | 96x96 | sprite (image, scaled to its display size) | 54x54 | M010: a round stone-edged flowerbed in Halloran Park (low: not solid). |
| `props/gas_pump` | `custom/graphics/props/gas_pump.png` | 48x48 | sprite (image, scaled to its display size) | 22x22 | Gas pump. |
| `props/hedge` | `custom/graphics/props/hedge.png` | 160x36 | sprite (image, scaled to its display size) | 110x24 | M010: a low clipped hedge from above, long along +X (not solid). |
| `props/hydrant` | `custom/graphics/props/hydrant.png` | 40x40 | sprite (image, scaled to its display size) | 15x15 | Fire hydrant. |
| `props/lamp_base` | `custom/graphics/props/lamp_base.png` | 32x32 | sprite (image, scaled to its display size) | 12x12 | Street lamp base. |
| `props/lamp_head` | `custom/graphics/props/lamp_head.png` | 64x64 | sprite (image, scaled to its display size) | 22x22 | Street lamp lantern seen from above. |
| `props/lantern` | `custom/graphics/props/lantern.png` | 32x32 | sprite (image, scaled to its display size) | 12x12 | Red warning lantern. |
| `props/mailbox` | `custom/graphics/props/mailbox.png` | 40x40 | sprite (image, scaled to its display size) | 16x16 | Mailbox. |
| `props/marquee` | `custom/graphics/props/marquee.png` | 256x96 | sprite (image, scaled to its display size) | 140x52 | Copper Owl canopy; wall side at the top. |
| `props/marquee_bijou` | `custom/graphics/props/marquee_bijou.png` | 256x96 | sprite (image, scaled to its display size) | 140x52 | M008: the Bijou picture house's canopy (Halloran Square); wall side at the top. |
| `props/marquee_bijou_lit` | `custom/graphics/props/marquee_bijou_lit.png` | 256x96 | light (additive night light; transparent where dark) | 140x52 | M008: the Bijou canopy's bulbs and lettering. |
| `props/marquee_lit` | `custom/graphics/props/marquee_lit.png` | 256x96 | light (additive night light; transparent where dark) | 140x52 | Canopy bulbs and lettering. |
| `props/newsstand` | `custom/graphics/props/newsstand.png` | 96x64 | sprite (image, scaled to its display size) | 46x30 | Newsstand. |
| `props/packard` | `custom/graphics/props/packard.png` | 176x80 | sprite (image, scaled to its display size) | 80x36 | M010 Vince Duggan's green Packard at the kerb outside Rosie's Café (scenery, never driven), nose right like the cars. |
| `props/parcel` | `custom/graphics/props/parcel.png` | 48x40 | sprite (image, scaled to its display size) | 16x13 | M010 the parcel from above: a shoebox in brown paper and string (an abstract item). |
| `props/trash_can` | `custom/graphics/props/trash_can.png` | 48x48 | sprite (image, scaled to its display size) | 18x18 | Ash can. |
| `props/tree` | `custom/graphics/props/tree.png` | 192x192 | sprite (image, scaled to its display size) | 96x96 | M008: a plane tree's crown from above (raised: its trunk is hidden beneath). |
| `props/truck` | `custom/graphics/props/truck.png` | 224x96 | sprite (image, scaled to its display size) | 104x44 | M008: a parked 1930s stake truck from above, nose right (+X); static and solid (not drivable). |
| `props/truck_b` | `custom/graphics/props/truck_b.png` | 224x96 | sprite (image, scaled to its display size) | 104x44 | M008: the same truck in another colour. |
| `roof/chimney` | `custom/graphics/roof/chimney.png` | 48x48 | sprite (image, scaled to its display size) | 27x27 | Brick chimney stack. |
| `roof/laundry` | `custom/graphics/roof/laundry.png` | 128x64 | sprite (image, scaled to its display size) | 70x35 | Washing lines. |
| `roof/skylight` | `custom/graphics/roof/skylight.png` | 96x64 | sprite (image, scaled to its display size) | 54x36 | Skylight. |
| `roof/skylight_lit` | `custom/graphics/roof/skylight_lit.png` | 96x64 | light (additive night light; transparent where dark) | 54x36 | Skylight light. |
| `roof/stair_hut` | `custom/graphics/roof/stair_hut.png` | 96x96 | sprite (image, scaled to its display size) | 50x50 | Roof access stair hut, door on the right. |
| `roof/vent` | `custom/graphics/roof/vent.png` | 32x32 | sprite (image, scaled to its display size) | 17x17 | Mushroom vent. |
| `roof/water_tank` | `custom/graphics/roof/water_tank.png` | 112x112 | sprite (image, scaled to its display size) | 58x58 | Wooden water tank. |
| `roofs/ballast` | `custom/graphics/roofs/ballast.png` | 256x256 | tile (seamless in both directions) | 256 px per repeat | Railroad ballast with two tracks (runs left-right). |
| `roofs/gravel` | `custom/graphics/roofs/gravel.png` | 256x256 | tile (seamless in both directions) | 256 px per repeat | Gravel flat roof. |
| `roofs/parapet` | `custom/graphics/roofs/parapet.png` | 128x32 | strip (seamless left-right, drawn along a line) | 8 px wide | Roof edge: stone coping (outside, top) and brick. |
| `roofs/steel` | `custom/graphics/roofs/steel.png` | 256x256 | tile (seamless in both directions) | 256 px per repeat | Riveted steel deck (raised bridge). |
| `roofs/tar` | `custom/graphics/roofs/tar.png` | 256x256 | tile (seamless in both directions) | 256 px per repeat | Tar-paper flat roof. |
| `roofs/tin` | `custom/graphics/roofs/tin.png` | 256x256 | tile (seamless in both directions) | 256 px per repeat | Corrugated sheet roof. |
| `signs/bakery` | `custom/graphics/signs/bakery.png` | 256x64 | sprite (image, scaled to its display size) | 150x38 | M008: Kowalski Bakery, painted roof lettering, transparent. |
| `signs/barber` | `custom/graphics/signs/barber.png` | 256x64 | sprite (image, scaled to its display size) | 130x33 | Painted roof lettering, transparent. |
| `signs/bijou` | `custom/graphics/signs/bijou.png` | 256x64 | sprite (image, scaled to its display size) | 150x38 | M008: The Bijou picture house, painted roof lettering, transparent. |
| `signs/cafe` | `custom/graphics/signs/cafe.png` | 256x64 | sprite (image, scaled to its display size) | 150x38 | M010: Rosie's Café, painted roof lettering, transparent. |
| `signs/church` | `custom/graphics/signs/church.png` | 256x64 | sprite (image, scaled to its display size) | 150x38 | M008: St. Brendan's, painted roof lettering, transparent. |
| `signs/coal` | `custom/graphics/signs/coal.png` | 384x64 | sprite (image, scaled to its display size) | 210x35 | M008: Brennan Coal & Ice, painted roof lettering, transparent. |
| `signs/cold_storage` | `custom/graphics/signs/cold_storage.png` | 384x64 | sprite (image, scaled to its display size) | 220x37 | Painted roof lettering, transparent. |
| `signs/copper_owl` | `custom/graphics/signs/copper_owl.png` | 256x128 | sprite (image, scaled to its display size) | 150x75 | Copper Owl rooftop sign. |
| `signs/copper_owl_lit` | `custom/graphics/signs/copper_owl_lit.png` | 256x128 | light (additive night light; transparent where dark) | 150x75 | Copper Owl neon. |
| `signs/drugstore` | `custom/graphics/signs/drugstore.png` | 256x64 | sprite (image, scaled to its display size) | 150x38 | M008: Halloran Drugs, painted roof lettering, transparent. |
| `signs/freight` | `custom/graphics/signs/freight.png` | 384x64 | sprite (image, scaled to its display size) | 230x38 | M008: North Branch Freight, painted roof lettering, transparent. |
| `signs/garage` | `custom/graphics/signs/garage.png` | 256x64 | sprite (image, scaled to its display size) | 150x38 | Painted roof lettering, transparent. |
| `signs/grocery` | `custom/graphics/signs/grocery.png` | 256x64 | sprite (image, scaled to its display size) | 130x33 | Painted roof lettering, transparent. |
| `signs/hardware` | `custom/graphics/signs/hardware.png` | 256x64 | sprite (image, scaled to its display size) | 130x33 | Painted roof lettering, transparent. |
| `signs/hotel` | `custom/graphics/signs/hotel.png` | 256x64 | sprite (image, scaled to its display size) | 150x38 | Hotel Marlowe rooftop letters. |
| `signs/hotel_lit` | `custom/graphics/signs/hotel_lit.png` | 256x64 | light (additive night light; transparent where dark) | 150x38 | Hotel Marlowe bulbs. |
| `signs/lunch` | `custom/graphics/signs/lunch.png` | 256x64 | sprite (image, scaled to its display size) | 150x38 | M008: Dutch's Night Lunch, painted roof lettering, transparent. |
| `signs/morgue` | `custom/graphics/signs/morgue.png` | 256x64 | sprite (image, scaled to its display size) | 150x38 | M006: The Morgue, painted roof lettering, transparent. |
| `signs/tannery` | `custom/graphics/signs/tannery.png` | 384x64 | sprite (image, scaled to its display size) | 230x38 | M008: Great Lakes Tanning Co., painted roof lettering, transparent. |
| `signs/vet` | `custom/graphics/signs/vet.png` | 384x64 | sprite (image, scaled to its display size) | 200x33 | M006: Pettibone Animal Hospital, painted roof lettering, transparent. |
| `ui/alert` | `custom/graphics/ui/alert.png` | 48x48 | sprite (image, scaled to its display size) | 30x30 | Over the officer: he has seen you. |
| `ui/card_back` | `custom/graphics/ui/card_back.png` | 72x100 | sprite (image, scaled to its display size) | 50x70 | M010 the back of the Copper Owl's deck (screen px). |
| `ui/card_face` | `custom/graphics/ui/card_face.png` | 72x100 | sprite (image, scaled to its display size) | 50x70 | M010 a blank card face (screen px), aged cream with a thin border; the game prints the rank and pips. |
| `ui/crosshair` | `custom/graphics/ui/crosshair.png` | 64x64 | sprite (image, scaled to its display size) | 30x30 | Mouse aim reticle (screen px). |
| `ui/dealer_button` | `custom/graphics/ui/dealer_button.png` | 48x48 | sprite (image, scaled to its display size) | 24x24 | M010 the dealer's button. |
| `ui/fight_dial` | `custom/graphics/ui/fight_dial.png` | 256x256 | sprite (image, scaled to its display size) | 210x210 | M007 fistfight dial (screen px): worn brass ring, copper bevel, cream ticks; the zone is lit by the game on the dark track at 92-104 px from the middle; top = where the needle starts. |
| `ui/fight_needle` | `custom/graphics/ui/fight_needle.png` | 256x256 | sprite (image, scaled to its display size) | 210x210 | M007 the dial's needle, pointing up from the middle of the same 256 x 256 frame (it turns about the centre). |
| `ui/item_parcel` | `custom/graphics/ui/item_parcel.png` | 64x64 | sprite (image, scaled to its display size) | 26x26 | M010 the parcel as a HUD badge beside the purse, while Danny carries it. |
| `ui/map_player` | `custom/graphics/ui/map_player.png` | 32x32 | sprite (image, scaled to its display size) | 14x14 | Minimap: you, an arrowhead pointing right (screen px). |
| `ui/map_police` | `custom/graphics/ui/map_police.png` | 32x32 | sprite (image, scaled to its display size) | 12x12 | Minimap: the beat cop (screen px). |
| `ui/marker_bar` | `custom/graphics/ui/marker_bar.png` | 64x80 | sprite (image, scaled to its display size) | 30x37 | Place marker (world and minimap): the Copper Owl. Badge on top, the pin's point at the bottom middle. |
| `ui/marker_barber` | `custom/graphics/ui/marker_barber.png` | 64x80 | sprite (image, scaled to its display size) | 30x37 | Place marker: Sal's Barber Shop. |
| `ui/marker_grocery` | `custom/graphics/ui/marker_grocery.png` | 64x80 | sprite (image, scaled to its display size) | 30x37 | Place marker: Novak's Grocery. |
| `ui/marker_hardware` | `custom/graphics/ui/marker_hardware.png` | 64x80 | sprite (image, scaled to its display size) | 30x37 | Place marker: Lindqvist Hardware. |
| `ui/marker_home` | `custom/graphics/ui/marker_home.png` | 64x80 | sprite (image, scaled to its display size) | 30x37 | Place marker: your flat (house-shaped, unlike the businesses). |
| `ui/marker_morgue` | `custom/graphics/ui/marker_morgue.png` | 64x80 | sprite (image, scaled to its display size) | 30x37 | M006 landmark badge: The Morgue (slate grey: a landmark, not a business; ward map only). |
| `ui/marker_vet` | `custom/graphics/ui/marker_vet.png` | 64x80 | sprite (image, scaled to its display size) | 30x37 | M006 place marker: Pettibone Animal Hospital (a paw print). |
| `ui/panel` | `custom/graphics/ui/panel.png` | 96x96 | sprite (image, scaled to its display size) | 96x96 | Nine-patch panel, 24 px margins. |
| `ui/poker_chip` | `custom/graphics/ui/poker_chip.png` | 48x48 | sprite (image, scaled to its display size) | 20x20 | M010 a clay chip from above, light grey (tinted by the game for its value). |
| `ui/poker_felt` | `custom/graphics/ui/poker_felt.png` | 960x440 | sprite (image, scaled to its display size) | 880x400 | M010 the card table on screen: green baize in an oval padded rail (screen px). |
| `ui/roulette_ball` | `custom/graphics/ui/roulette_ball.png` | 32x32 | sprite (image, scaled to its display size) | 13x13 | M011 the ivory ball. |
| `ui/roulette_bowl` | `custom/graphics/ui/roulette_bowl.png` | 512x512 | sprite (image, scaled to its display size) | 330x330 | M011 the wheel's wooden bowl from above: rim, ball track (out to 0.95 of the radius), eight brass deflectors, the dark gap inside 0.785 where the head turns. |
| `ui/roulette_dolly` | `custom/graphics/ui/roulette_dolly.png` | 48x48 | sprite (image, scaled to its display size) | 26x26 | M011 the croupier's brass marker on the winning number. |
| `ui/roulette_felt` | `custom/graphics/ui/roulette_felt.png` | 720x320 | sprite (image, scaled to its display size) | 1080x480 | M011 the wheel table on screen: green baize in a dark wooden rail with a brass inlay (the game draws the wheel and the layout on it). |
| `ui/roulette_rotor` | `custom/graphics/ui/roulette_rotor.png` | 512x512 | sprite (image, scaled to its display size) | 258x258 | M011 the wheel head on screen (0.78 of the bowl), turned by the game: the zero at the top, the 37 pockets clockwise in the European order (0 32 15 19 4 21 2 25 17 34 6 27 13 36 11 30 8 23 10 5 24 16 33 1 20 14 31 9 22 18 29 7 28 12 35 3 26), numbers outside 0.86 of its radius, the pockets 0.66-0.86 (the ball rests at 0.76). Keep the order and the zero at the top or the ball will seem to land on the wrong number. |
| `ui/search` | `custom/graphics/ui/search.png` | 48x48 | sprite (image, scaled to its display size) | 30x30 | Over the officer: he is looking for you. |
| `ui/slot_bar` | `custom/graphics/ui/slot_bar.png` | 96x96 | sprite (image, scaled to its display size) | 80x80 | M011 a reel symbol: the black BAR, centred, nothing behind it (the reel's paper is drawn by the game). |
| `ui/slot_bell` | `custom/graphics/ui/slot_bell.png` | 96x96 | sprite (image, scaled to its display size) | 80x80 | M011 a reel symbol: a gold bell, centred, nothing behind it (the reel's paper is drawn by the game). |
| `ui/slot_cherry` | `custom/graphics/ui/slot_cherry.png` | 96x96 | sprite (image, scaled to its display size) | 80x80 | M011 a reel symbol: two cherries on a stem, centred, nothing behind it (the reel's paper is drawn by the game). |
| `ui/slot_coin` | `custom/graphics/ui/slot_coin.png` | 40x40 | sprite (image, scaled to its display size) | 24x24 | M011 a worn coin dropping into the payout cup. |
| `ui/slot_front_bell` | `custom/graphics/ui/slot_front_bell.png` | 440x600 | sprite (image, scaled to its display size) | 440x600 | M011 the Bell machine's cast front on screen (red and gold, a bell on the crest): the reel windows are holes (transparent) at x 75-165, 175-265, 275-365, y 150-270 of the 440 x 600 front, the pay line at y 210; the cream paytable plate at x 60-380, y 304-470 is left blank (the game prints the machine's own lines); the payout cup at the bottom middle (x 164-276, y 532-578). Keep the windows where they are. |
| `ui/slot_front_owl` | `custom/graphics/ui/slot_front_owl.png` | 440x600 | sprite (image, scaled to its display size) | 440x600 | M011 the Owl machine's cast front on screen (copper and brass, an owl on the crest): the reel windows are holes (transparent) at x 75-165, 175-265, 275-365, y 150-270 of the 440 x 600 front, the pay line at y 210; the cream paytable plate at x 60-380, y 304-470 is left blank (the game prints the machine's own lines); the payout cup at the bottom middle (x 164-276, y 532-578). Keep the windows where they are. |
| `ui/slot_front_star` | `custom/graphics/ui/slot_front_star.png` | 440x600 | sprite (image, scaled to its display size) | 440x600 | M011 the Star machine's cast front on screen (green and silver, a star on the crest): the reel windows are holes (transparent) at x 75-165, 175-265, 275-365, y 150-270 of the 440 x 600 front, the pay line at y 210; the cream paytable plate at x 60-380, y 304-470 is left blank (the game prints the machine's own lines); the payout cup at the bottom middle (x 164-276, y 532-578). Keep the windows where they are. |
| `ui/slot_lemon` | `custom/graphics/ui/slot_lemon.png` | 96x96 | sprite (image, scaled to its display size) | 80x80 | M011 a reel symbol: a lemon, centred, nothing behind it (the reel's paper is drawn by the game). |
| `ui/slot_lever` | `custom/graphics/ui/slot_lever.png` | 40x200 | sprite (image, scaled to its display size) | 34x170 | M011 the machine's lever, upright, its pivot at the bottom middle (the game swings it). |
| `ui/slot_orange` | `custom/graphics/ui/slot_orange.png` | 96x96 | sprite (image, scaled to its display size) | 80x80 | M011 a reel symbol: an orange with a leaf, centred, nothing behind it (the reel's paper is drawn by the game). |
| `ui/slot_plum` | `custom/graphics/ui/slot_plum.png` | 96x96 | sprite (image, scaled to its display size) | 80x80 | M011 a reel symbol: a plum, centred, nothing behind it (the reel's paper is drawn by the game). |
| `ui/slot_seven` | `custom/graphics/ui/slot_seven.png` | 96x96 | sprite (image, scaled to its display size) | 80x80 | M011 a reel symbol: a red seven, centred, nothing behind it (the reel's paper is drawn by the game). |
| `ui/status_head` | `custom/graphics/ui/status_head.png` | 160x320 | sprite (image, scaled to its display size) | 160x320 | M006 status screen: Danny from the front, his head and hat only (all six pieces line up on one canvas; light grey, tinted by the game). |
| `ui/status_left_arm` | `custom/graphics/ui/status_left_arm.png` | 160x320 | sprite (image, scaled to its display size) | 160x320 | M006 status screen: his left arm (on the viewer's right). |
| `ui/status_left_leg` | `custom/graphics/ui/status_left_leg.png` | 160x320 | sprite (image, scaled to its display size) | 160x320 | M006 status screen: his left leg. |
| `ui/status_right_arm` | `custom/graphics/ui/status_right_arm.png` | 160x320 | sprite (image, scaled to its display size) | 160x320 | M006 status screen: his right arm, the gun arm (viewer's left). |
| `ui/status_right_leg` | `custom/graphics/ui/status_right_leg.png` | 160x320 | sprite (image, scaled to its display size) | 160x320 | M006 status screen: his right leg. |
| `ui/status_torso` | `custom/graphics/ui/status_torso.png` | 160x320 | sprite (image, scaled to its display size) | 160x320 | M006 status screen: his body. |
| `ui/suit_clubs` | `custom/graphics/ui/suit_clubs.png` | 48x48 | sprite (image, scaled to its display size) | 18x18 | M010 a club pip. |
| `ui/suit_diamonds` | `custom/graphics/ui/suit_diamonds.png` | 48x48 | sprite (image, scaled to its display size) | 18x18 | M010 a diamond pip. |
| `ui/suit_hearts` | `custom/graphics/ui/suit_hearts.png` | 48x48 | sprite (image, scaled to its display size) | 18x18 | M010 a heart pip. |
| `ui/suit_spades` | `custom/graphics/ui/suit_spades.png` | 48x48 | sprite (image, scaled to its display size) | 18x18 | M010 a spade pip (screen px, scaled by the game). |
| `weapons/pistol` | `custom/graphics/weapons/pistol.png` | 48x20 | sprite (image, scaled to its display size) | 15x6 | .45 automatic from above, muzzle to the right; the left end sits in the hand. |
| `weapons/thompson` | `custom/graphics/weapons/thompson.png` | 96x24 | sprite (image, scaled to its display size) | 31x8 | M010 Eddie's Thompson in the hand, from above, muzzle to the right (the stock at the left end sits at the shoulder). |

## Audio (OGG, WAV or MP3)

Loops repeat over the whole file, so keep a loop's two ends matching (or both quiet). The defaults are
Claude-made `template_` sounds, except the Copper Owl's song and Danny's monologue: the user's recordings,
shipped under their own names (originals untouched in `assets/audio/_inbox/`).

| Logical name | Override path | Default | Loops | Bus | Notes |
| --- | --- | --- | --- | --- | --- |
| `ambience/alley` | `custom/audio/ambience/alley.ogg` (or .wav / .mp3) | `template_alley.ogg` | yes | Ambience | Back alleys: dripping water, the city a murmur behind the walls. |
| `ambience/clatter` | `custom/audio/ambience/clatter.ogg` (or .wav / .mp3) | `template_clatter.ogg` | no | Ambience | A lid or a can clattering somewhere down an alley. |
| `ambience/club_crowd` | `custom/audio/ambience/club_crowd.ogg` (or .wav / .mp3) | `template_club_crowd.ogg` | yes | Ambience | The Copper Owl's room: chatter, glasses, footsteps. Muffled with the music outside. |
| `ambience/foghorn` | `custom/audio/ambience/foghorn.ogg` (or .wav / .mp3) | `template_foghorn.ogg` | no | Ambience | A tug's whistle out on the river (heard near the water). |
| `ambience/horn` | `custom/audio/ambience/horn.ogg` (or .wav / .mp3) | `template_horn.ogg` | no | Ambience | A car horn a few streets away (now and then; rarer late at night). |
| `ambience/rain` | `custom/audio/ambience/rain.ogg` (or .wav / .mp3) | `template_rain.ogg` | yes | Ambience | M010: steady rain on the street: a hiss, the gutters' rush, drops ticking on tin and puddles. Louder with the rain, dull indoors. |
| `ambience/river` | `custom/audio/ambience/river.ogg` (or .wav / .mp3) | `template_river.ogg` | yes | Ambience | By the river: water against the quay, a factory's drone across it. |
| `ambience/street_night` | `custom/audio/ambience/street_night.ogg` (or .wav / .mp3) | `template_street_night.ogg` | yes | Ambience | The street's bed at night: distant traffic, the city beyond the corner. Quieter after midnight; dull indoors. |
| `emergency/bell` | `custom/audio/emergency/bell.ogg` (or .wav / .mp3) | `template_bell.ogg` | no | Effects | M010: a fire engine's brass bell clanged by hand (one-shot, about 2.6 s). |
| `emergency/siren` | `custom/audio/emergency/siren.ogg` (or .wav / .mp3) | `template_siren.ogg` | no | Effects | M010: a police car's hand-cranked siren rising and falling (one-shot, about 3.6 s). |
| `fight/punch_landed` | `custom/audio/fight/punch_landed.ogg` (or .wav / .mp3) | `template_punch_landed.ogg` | no | Effects | M007: Danny's punch lands in a fistfight (under 0.5 s). |
| `fight/punch_taken` | `custom/audio/fight/punch_taken.ogg` (or .wav / .mp3) | `template_punch_taken.ogg` | no | Effects | M007: Danny takes a punch (under 0.5 s; no voice). |
| `fx/blast` | `custom/audio/fx/blast.ogg` (or .wav / .mp3) | `template_blast.ogg` | no | Effects | M010: the parcel going off under a parked car: crack, a rolling boom, glass and debris falling (about 4.5 s). |
| `fx/fire` | `custom/audio/fx/fire.ogg` (or .wav / .mp3) | `template_fire.ogg` | yes | Effects | M010: a car burning at the kerb: flame roar and crackle (seamless loop). |
| `music/copper_owl_jazz` | `custom/audio/music/copper_owl_jazz.ogg` (or .wav / .mp3) | `copper_owl_jazz.ogg` | yes | Music | The Copper Owl's singer, "Leave the Lights Low" (the user's recording, cleaned). One continuous player: full inside the club, low-passed and quieter through its walls outside. Loops whole; keep both ends quiet. |
| `music/record_scratch` | `custom/audio/music/record_scratch.ogg` (or .wav / .mp3) | `template_record_scratch.ogg` | no | Music | M006: the needle dragged off the record when Danny interrupts the Bird (under 1 s). Heard through the club's walls like the song. |
| `places/bottles` | `custom/audio/places/bottles.ogg` (or .wav / .mp3) | `template_bottles.ogg` | no | Effects | Bottles of rye changing hands. |
| `places/door` | `custom/audio/places/door.ogg` (or .wav / .mp3) | `template_door.ogg` | no | Effects | Going in or out by a door: latch, hinges, the door falling to. |
| `places/register` | `custom/audio/places/register.ogg` (or .wav / .mp3) | `template_register.ogg` | no | Effects | A shop's till when money changes hands. |
| `places/shop_bell` | `custom/audio/places/shop_bell.ogg` (or .wav / .mp3) | `template_shop_bell.ogg` | no | Effects | The bell over a shop door (barber, grocer, hardware). |
| `poker/cards` | `custom/audio/poker/cards.ogg` (or .wav / .mp3) | `template_cards.ogg` | no | Effects | M010: a card dealt across the baize (a flick and a slide). |
| `poker/chips` | `custom/audio/poker/chips.ogg` (or .wav / .mp3) | `template_chips.ogg` | no | Effects | M010: chips pushed into the pot at the back-room card table (under 0.5 s). |
| `police/whistle` | `custom/audio/police/whistle.ogg` (or .wav / .mp3) | `template_whistle.wav` | no | Effects | The officer's whistle when he spots you. |
| `vehicles/door` | `custom/audio/vehicles/door.ogg` (or .wav / .mp3) | `template_door.ogg` | no | Effects | Getting into or out of a car: the handle and a heavy door shutting. |
| `vehicles/engine_load` | `custom/audio/vehicles/engine_load.ogg` (or .wav / .mp3) | `template_engine_load.wav` | yes | Engine | Engine load layer, louder while accelerating. |
| `vehicles/engine_loop` | `custom/audio/vehicles/engine_loop.ogg` (or .wav / .mp3) | `template_engine_loop.wav` | yes | Engine | Engine foundation loop (pitch follows speed). |
| `vehicles/impact_car` | `custom/audio/vehicles/impact_car.ogg` (or .wav / .mp3) | `template_impact_car.ogg` | no | Effects | Car hits car, under 1 s. |
| `vehicles/impact_wall` | `custom/audio/vehicles/impact_wall.ogg` (or .wav / .mp3) | `template_impact_wall.ogg` | no | Effects | Car hits a wall or kerb object, under 1 s. |
| `vehicles/tire_squeal` | `custom/audio/vehicles/tire_squeal.ogg` (or .wav / .mp3) | `template_tire_squeal.wav` | yes | Effects | Tyre squeal while sliding. |
| `voice/augie_greeting` | `custom/audio/voice/augie_greeting.ogg` (or .wav / .mp3) | `augie_greeting.mp3` | no | Voice | Augie, the first time Danny talks to him (about 9.5 s). |
| `voice/bird_greeting` | `custom/audio/voice/bird_greeting.ogg` (or .wav / .mp3) | `bird_greeting.mp3` | no | Voice | The Bird introducing herself, the first time Danny talks to her (about 12 s). |
| `voice/bird_interrupted` | `custom/audio/voice/bird_interrupted.ogg` (or .wav / .mp3) | `bird_interrupted.mp3` | no | Voice | The Bird, every time Danny interrupts her song (about 10 s). |
| `voice/danny_opening` | `custom/audio/voice/danny_opening.ogg` (or .wav / .mp3) | `danny_opening.mp3` | no | Voice | Danny's opening monologue on a new game (the user's recording, unaltered; about 23 s). The subtitles follow the shipped recording. |
| `voice/eddie_greeting` | `custom/audio/voice/eddie_greeting.ogg` (or .wav / .mp3) | `eddie_greeting.mp3` | no | Voice | Eddie, the first time Danny talks to him (about 11 s). |
| `voice/eddie_sales` | `custom/audio/voice/eddie_sales.ogg` (or .wav / .mp3) | `eddie_sales.mp3` | no | Voice | Eddie, the first time Danny asks to see what he sells (about 4.5 s). |
| `voice/rourke_greeting` | `custom/audio/voice/rourke_greeting.ogg` (or .wav / .mp3) | `rourke_greeting.mp3` | no | Voice | Rourke, the first time Danny sits down with him after years away (about 21 s). |
| `weapons/bullet_impact` | `custom/audio/weapons/bullet_impact.ogg` (or .wav / .mp3) | `template_bullet_impact.wav` | no | Effects | A bullet striking brick. |
| `weapons/pistol_reload` | `custom/audio/weapons/pistol_reload.ogg` (or .wav / .mp3) | `template_pistol_reload.wav` | no | Effects | Magazine out and in, slide racked. |
| `weapons/pistol_shot` | `custom/audio/weapons/pistol_shot.ogg` (or .wav / .mp3) | `template_pistol_shot.wav` | no | Effects | A .45 shot in a brick street, about 1 s with its echo. |
| `weapons/thompson_shot` | `custom/audio/weapons/thompson_shot.ogg` (or .wav / .mp3) | `template_thompson_shot.wav` | no | Effects | M010: one round from the Thompson, played for every round of a burst (short tail, under 0.5 s). |
