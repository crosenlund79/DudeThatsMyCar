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
| `cars/coupe` | `custom/graphics/cars/coupe.png` | 176x80 | sprite (image, scaled to its display size) | 80x36 | Roadster, top-down, nose right, centred, transparent background. |
| `cars/coupe_b` | `custom/graphics/cars/coupe_b.png` | 176x80 | sprite (image, scaled to its display size) | 80x36 | Roadster, second paint scheme; same contract. |
| `cars/sedan` | `custom/graphics/cars/sedan.png` | 176x80 | sprite (image, scaled to its display size) | 80x36 | Sedan, top-down, nose right, centred, transparent background. |
| `cars/sedan_b` | `custom/graphics/cars/sedan_b.png` | 176x80 | sprite (image, scaled to its display size) | 80x36 | Sedan, second paint scheme; same contract. |
| `characters/gangster` | `custom/graphics/characters/gangster.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | Player on foot: 5 frames of 64x64 in a row (idle, step, passing, other step, passing), facing right, centred. |
| `characters/gangster_armed` | `custom/graphics/characters/gangster_armed.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | The player with the pistol drawn: same frames, right arm reaching forward (the pistol is drawn separately). |
| `characters/police` | `custom/graphics/characters/police.png` | 320x64 | sheet (horizontal strip of equal frames) | 5 frames, each 44x44 | Police officer: 5 frames like the player's, facing right, centred. |
| `city/alley` | `custom/graphics/city/alley.png` | 256x256 | tile (seamless in both directions) | 160 px per repeat | Brick alley paving. |
| `city/asphalt` | `custom/graphics/city/asphalt.png` | 256x256 | tile (seamless in both directions) | 256 px per repeat | Wet street asphalt. |
| `city/cobbles` | `custom/graphics/city/cobbles.png` | 256x256 | tile (seamless in both directions) | 112 px per repeat | Granite setts (streetcar tracks). |
| `city/curb` | `custom/graphics/city/curb.png` | 128x24 | strip (seamless left-right, drawn along a line) | 8 px wide | Stone curb; sidewalk side at the top. |
| `city/fence` | `custom/graphics/city/fence.png` | 128x16 | strip (seamless left-right, drawn along a line) | 8 px wide | Wooden board fence. |
| `city/lot` | `custom/graphics/city/lot.png` | 256x256 | tile (seamless in both directions) | 256 px per repeat | Yards and lots: cinders, dirt, weeds. |
| `city/quay` | `custom/graphics/city/quay.png` | 128x32 | strip (seamless left-right, drawn along a line) | 16 px wide | Stone river edge with railing; water side at the bottom. |
| `city/rails` | `custom/graphics/city/rails.png` | 128x40 | strip (seamless left-right, drawn along a line) | 22 px wide | One streetcar track (two rails), transparent between. |
| `city/sidewalk` | `custom/graphics/city/sidewalk.png` | 256x256 | tile (seamless in both directions) | 192 px per repeat | Concrete sidewalk slabs. |
| `city/water` | `custom/graphics/city/water.png` | 256x256 | tile (seamless in both directions) | 320 px per repeat | River water. |
| `decals/drain` | `custom/graphics/decals/drain.png` | 48x24 | sprite (image, scaled to its display size) | 24x12 | Storm drain grate. |
| `decals/litter` | `custom/graphics/decals/litter.png` | 48x48 | sprite (image, scaled to its display size) | 18x18 | Newspaper litter. |
| `decals/manhole` | `custom/graphics/decals/manhole.png` | 48x48 | sprite (image, scaled to its display size) | 24x24 | Manhole cover. |
| `decals/oil` | `custom/graphics/decals/oil.png` | 96x96 | sprite (image, scaled to its display size) | 52x52 | Oil stain. |
| `decals/puddle` | `custom/graphics/decals/puddle.png` | 128x80 | sprite (image, scaled to its display size) | 96x60 | Puddle (semi-transparent). |
| `facades/brick_brown` | `custom/graphics/facades/brick_brown.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Brown-brick shops (shopfronts below). |
| `facades/brick_brown_lit` | `custom/graphics/facades/brick_brown_lit.png` | 256x192 | light (additive night light; transparent where dark) | matches its facade | Window light for brick_brown. |
| `facades/brick_red` | `custom/graphics/facades/brick_red.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Red-brick apartments. |
| `facades/brick_red_lit` | `custom/graphics/facades/brick_red_lit.png` | 256x192 | light (additive night light; transparent where dark) | matches its facade | Window light for brick_red. |
| `facades/club` | `custom/graphics/facades/club.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | The Copper Owl jazz club. |
| `facades/club_lit` | `custom/graphics/facades/club_lit.png` | 256x192 | light (additive night light; transparent where dark) | matches its facade | Window and bulb light for club. |
| `facades/garage` | `custom/graphics/facades/garage.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Doyle's Garage: painted brick, garage doors. |
| `facades/garage_lit` | `custom/graphics/facades/garage_lit.png` | 256x192 | light (additive night light; transparent where dark) | matches its facade | Window light for garage. |
| `facades/greystone` | `custom/graphics/facades/greystone.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Limestone greystone flats. |
| `facades/greystone_lit` | `custom/graphics/facades/greystone_lit.png` | 256x192 | light (additive night light; transparent where dark) | matches its facade | Window light for greystone. |
| `facades/party` | `custom/graphics/facades/party.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Blank side wall between buildings. |
| `facades/rear` | `custom/graphics/facades/rear.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Alley side with fire escapes. |
| `facades/rear_lit` | `custom/graphics/facades/rear_lit.png` | 256x192 | light (additive night light; transparent where dark) | matches its facade | Window and bulb light for rear. |
| `facades/steel` | `custom/graphics/facades/steel.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Steel truss (the raised bascule bridge). |
| `facades/stone` | `custom/graphics/facades/stone.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Granite embankment wall. |
| `facades/warehouse` | `custom/graphics/facades/warehouse.png` | 256x192 | facade (seamless left-right wall: top half one upper storey, bottom half the ground storey) | 128 px per repeat | Warehouse: steel windows, loading doors. |
| `facades/warehouse_lit` | `custom/graphics/facades/warehouse_lit.png` | 256x192 | light (additive night light; transparent where dark) | matches its facade | Window light for warehouse. |
| `fx/glow` | `custom/graphics/fx/glow.png` | 128x128 | light (additive night light; transparent where dark) | 128x128 | Round warm glow (lamp halos, light spill). |
| `fx/impact_dust` | `custom/graphics/fx/impact_dust.png` | 48x48 | sprite (image, scaled to its display size) | 22x22 | Brick dust where a bullet strikes a wall. |
| `fx/muzzle_flash` | `custom/graphics/fx/muzzle_flash.png` | 64x40 | light (additive night light; transparent where dark) | 34x21 | Muzzle flash; the muzzle is at the left edge, middle. |
| `fx/reflection` | `custom/graphics/fx/reflection.png` | 64x192 | light (additive night light; transparent where dark) | 22x70 | Light reflected on wet ground; the light is at the top. |
| `fx/spark` | `custom/graphics/fx/spark.png` | 32x32 | light (additive night light; transparent where dark) | 12x12 | Spark where a bullet strikes. |
| `fx/steam` | `custom/graphics/fx/steam.png` | 64x64 | sprite (image, scaled to its display size) | 48x48 | Steam / smoke puff. |
| `fx/tracer` | `custom/graphics/fx/tracer.png` | 64x8 | light (additive night light; transparent where dark) | 48x5 | Bullet streak; the bullet is at the right end. |
| `props/awning_green` | `custom/graphics/props/awning_green.png` | 160x64 | sprite (image, scaled to its display size) | 84x34 | Shop awning; wall side at the top. |
| `props/awning_red` | `custom/graphics/props/awning_red.png` | 160x64 | sprite (image, scaled to its display size) | 84x34 | Shop awning; wall side at the top. |
| `props/barrel` | `custom/graphics/props/barrel.png` | 48x48 | sprite (image, scaled to its display size) | 20x20 | Barrel. |
| `props/barricade` | `custom/graphics/props/barricade.png` | 192x64 | sprite (image, scaled to its display size) | 96x32 | Street-closed sawhorse. |
| `props/call_box` | `custom/graphics/props/call_box.png` | 40x40 | sprite (image, scaled to its display size) | 18x18 | Police call box on its post. |
| `props/crate` | `custom/graphics/props/crate.png` | 64x64 | sprite (image, scaled to its display size) | 26x26 | Wooden crate. |
| `props/crates` | `custom/graphics/props/crates.png` | 96x96 | sprite (image, scaled to its display size) | 44x44 | Stack of crates. |
| `props/fire_escape` | `custom/graphics/props/fire_escape.png` | 128x40 | sprite (image, scaled to its display size) | 64x20 | Iron fire-escape landing; wall side at the top. |
| `props/gas_pump` | `custom/graphics/props/gas_pump.png` | 48x48 | sprite (image, scaled to its display size) | 22x22 | Gas pump. |
| `props/hydrant` | `custom/graphics/props/hydrant.png` | 40x40 | sprite (image, scaled to its display size) | 15x15 | Fire hydrant. |
| `props/lamp_base` | `custom/graphics/props/lamp_base.png` | 32x32 | sprite (image, scaled to its display size) | 12x12 | Street lamp base. |
| `props/lamp_head` | `custom/graphics/props/lamp_head.png` | 64x64 | sprite (image, scaled to its display size) | 22x22 | Street lamp lantern seen from above. |
| `props/lantern` | `custom/graphics/props/lantern.png` | 32x32 | sprite (image, scaled to its display size) | 12x12 | Red warning lantern. |
| `props/mailbox` | `custom/graphics/props/mailbox.png` | 40x40 | sprite (image, scaled to its display size) | 16x16 | Mailbox. |
| `props/marquee` | `custom/graphics/props/marquee.png` | 256x96 | sprite (image, scaled to its display size) | 140x52 | Copper Owl canopy; wall side at the top. |
| `props/marquee_lit` | `custom/graphics/props/marquee_lit.png` | 256x96 | light (additive night light; transparent where dark) | 140x52 | Canopy bulbs and lettering. |
| `props/newsstand` | `custom/graphics/props/newsstand.png` | 96x64 | sprite (image, scaled to its display size) | 46x30 | Newsstand. |
| `props/trash_can` | `custom/graphics/props/trash_can.png` | 48x48 | sprite (image, scaled to its display size) | 18x18 | Ash can. |
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
| `signs/cold_storage` | `custom/graphics/signs/cold_storage.png` | 384x64 | sprite (image, scaled to its display size) | 220x37 | Painted roof lettering, transparent. |
| `signs/copper_owl` | `custom/graphics/signs/copper_owl.png` | 256x128 | sprite (image, scaled to its display size) | 150x75 | Copper Owl rooftop sign. |
| `signs/copper_owl_lit` | `custom/graphics/signs/copper_owl_lit.png` | 256x128 | light (additive night light; transparent where dark) | 150x75 | Copper Owl neon. |
| `signs/garage` | `custom/graphics/signs/garage.png` | 256x64 | sprite (image, scaled to its display size) | 150x38 | Painted roof lettering, transparent. |
| `signs/hotel` | `custom/graphics/signs/hotel.png` | 256x64 | sprite (image, scaled to its display size) | 150x38 | Hotel Marlowe rooftop letters. |
| `signs/hotel_lit` | `custom/graphics/signs/hotel_lit.png` | 256x64 | light (additive night light; transparent where dark) | 150x38 | Hotel Marlowe bulbs. |
| `ui/alert` | `custom/graphics/ui/alert.png` | 48x48 | sprite (image, scaled to its display size) | 30x30 | Over the officer: he has seen you. |
| `ui/crosshair` | `custom/graphics/ui/crosshair.png` | 64x64 | sprite (image, scaled to its display size) | 30x30 | Mouse aim reticle (screen px). |
| `ui/panel` | `custom/graphics/ui/panel.png` | 96x96 | sprite (image, scaled to its display size) | 96x96 | Nine-patch panel, 24 px margins. |
| `ui/search` | `custom/graphics/ui/search.png` | 48x48 | sprite (image, scaled to its display size) | 30x30 | Over the officer: he is looking for you. |
| `weapons/pistol` | `custom/graphics/weapons/pistol.png` | 48x20 | sprite (image, scaled to its display size) | 15x6 | .45 automatic from above, muzzle to the right; the left end sits in the hand. |

## Audio (OGG, WAV or MP3)

| Logical name | Override path | Loops | Bus | Notes |
| --- | --- | --- | --- | --- |
| `police/whistle` | `custom/audio/police/whistle.ogg` (or .wav / .mp3) | no | Effects | The officer's whistle when he spots you. |
| `vehicles/engine_load` | `custom/audio/vehicles/engine_load.ogg` (or .wav / .mp3) | yes | Engine | Engine load layer, louder while accelerating. |
| `vehicles/engine_loop` | `custom/audio/vehicles/engine_loop.ogg` (or .wav / .mp3) | yes | Engine | Engine foundation loop (pitch follows speed). |
| `vehicles/impact_car` | `custom/audio/vehicles/impact_car.ogg` (or .wav / .mp3) | no | Effects | Car hits car, under 1 s. |
| `vehicles/impact_wall` | `custom/audio/vehicles/impact_wall.ogg` (or .wav / .mp3) | no | Effects | Car hits a wall or kerb object, under 1 s. |
| `vehicles/tire_squeal` | `custom/audio/vehicles/tire_squeal.ogg` (or .wav / .mp3) | yes | Effects | Tyre squeal while sliding. |
| `weapons/bullet_impact` | `custom/audio/weapons/bullet_impact.ogg` (or .wav / .mp3) | no | Effects | A bullet striking brick. |
| `weapons/pistol_reload` | `custom/audio/weapons/pistol_reload.ogg` (or .wav / .mp3) | no | Effects | Magazine out and in, slide racked. |
| `weapons/pistol_shot` | `custom/audio/weapons/pistol_shot.ogg` (or .wav / .mp3) | no | Effects | A .45 shot in a brick street, about 1 s with its echo. |
