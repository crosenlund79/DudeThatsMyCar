class_name AssetCatalog
extends RefCounted
## Replacement contract for every graphic and sound the game uses
## (override rules: assets/README.md, generated list: docs/ASSET_SPECS.md).
## Overrides may use any resolution but must keep the template's aspect ratio,
## orientation and layout; the game scales each image to its size in the world.
##
## Kinds:
##   sprite - one image, scaled to display_size (world px).
##   sheet  - a horizontal strip of `frames` equal frames, each scaled to display_size.
##   tile   - seamless in both directions; one repeat covers tile_world_size world px.
##   strip  - seamless left-right, drawn along a line strip_width world px wide.
##   facade - seamless left-right building wall: top half = one upper storey,
##            bottom half = the ground storey; one repeat is 128 world px long.
##   light  - additive light (night glow): transparent where there is no light.

const FACADE_REPEAT := 128.0

const SPECS := {
	# Vehicles and people (nose / face pointing right, +X, centred).
	"cars/sedan": {"kind": "sprite", "template_size": Vector2i(176, 80), "display_size": Vector2(80, 36),
		"notes": "Sedan, top-down, nose right, centred, transparent background."},
	"cars/sedan_b": {"kind": "sprite", "template_size": Vector2i(176, 80), "display_size": Vector2(80, 36),
		"notes": "Sedan, second paint scheme; same contract."},
	"cars/coupe": {"kind": "sprite", "template_size": Vector2i(176, 80), "display_size": Vector2(80, 36),
		"notes": "Roadster, top-down, nose right, centred, transparent background."},
	"cars/coupe_b": {"kind": "sprite", "template_size": Vector2i(176, 80), "display_size": Vector2(80, 36),
		"notes": "Roadster, second paint scheme; same contract."},
	"cars/wheel": {"kind": "sprite", "template_size": Vector2i(48, 20), "display_size": Vector2(14, 6),
		"notes": "Front tyre (whitewall) from above, rolling direction left-right; drawn under the body on both sides and turned with the steering (car bodies leave the front tyres out)."},
	"characters/gangster": {"kind": "sheet", "frames": 5, "template_size": Vector2i(320, 64), "display_size": Vector2(44, 44),
		"notes": "Player on foot: 5 frames of 64x64 in a row (idle, step, passing, other step, passing), facing right, centred."},
	"characters/gangster_armed": {"kind": "sheet", "frames": 5, "template_size": Vector2i(320, 64), "display_size": Vector2(44, 44),
		"notes": "The player with the pistol drawn: same frames, right arm reaching forward (the pistol is drawn separately)."},
	"characters/police": {"kind": "sheet", "frames": 5, "template_size": Vector2i(320, 64), "display_size": Vector2(44, 44),
		"notes": "Police officer: 5 frames like the player's, facing right, centred."},
	"characters/bartender": {"kind": "sheet", "frames": 5, "template_size": Vector2i(320, 64), "display_size": Vector2(44, 44),
		"notes": "Augie the bartender: white sleeves, black vest, bow tie; frames like the player's."},
	"characters/patron_man": {"kind": "sheet", "frames": 5, "template_size": Vector2i(320, 64), "display_size": Vector2(44, 44),
		"notes": "A man in evening clothes (club guest, late passer-by)."},
	"characters/patron_woman": {"kind": "sheet", "frames": 5, "template_size": Vector2i(320, 64), "display_size": Vector2(44, 44),
		"notes": "A woman in an evening dress with a bob."},
	"characters/barber": {"kind": "sheet", "frames": 5, "template_size": Vector2i(320, 64), "display_size": Vector2(44, 44),
		"notes": "Sal the barber in his white coat."},
	"characters/grocer": {"kind": "sheet", "frames": 5, "template_size": Vector2i(320, 64), "display_size": Vector2(44, 44),
		"notes": "Mr. Novak the grocer: apron and flat cap."},
	"characters/clerk": {"kind": "sheet", "frames": 5, "template_size": Vector2i(320, 64), "display_size": Vector2(44, 44),
		"notes": "Lindqvist the hardware man in his dust coat."},
	"characters/dealer": {"kind": "sheet", "frames": 5, "template_size": Vector2i(320, 64), "display_size": Vector2(44, 44),
		"notes": "Eddie, the back-room gun dealer: dark green suit and fedora."},
	"weapons/pistol": {"kind": "sprite", "template_size": Vector2i(48, 20), "display_size": Vector2(15, 6),
		"notes": ".45 automatic from above, muzzle to the right; the left end sits in the hand."},
	# Ground.
	"city/asphalt": {"kind": "tile", "template_size": Vector2i(256, 256), "tile_world_size": 256.0, "notes": "Wet street asphalt."},
	"city/sidewalk": {"kind": "tile", "template_size": Vector2i(256, 256), "tile_world_size": 192.0, "notes": "Concrete sidewalk slabs."},
	"city/alley": {"kind": "tile", "template_size": Vector2i(256, 256), "tile_world_size": 160.0, "notes": "Brick alley paving."},
	"city/cobbles": {"kind": "tile", "template_size": Vector2i(256, 256), "tile_world_size": 112.0, "notes": "Granite setts (streetcar tracks)."},
	"city/lot": {"kind": "tile", "template_size": Vector2i(256, 256), "tile_world_size": 256.0, "notes": "Yards and lots: cinders, dirt, weeds."},
	"city/water": {"kind": "tile", "template_size": Vector2i(256, 256), "tile_world_size": 320.0, "notes": "River water."},
	"city/curb": {"kind": "strip", "template_size": Vector2i(128, 24), "strip_width": 8.0, "notes": "Stone curb; sidewalk side at the top."},
	"city/rails": {"kind": "strip", "template_size": Vector2i(128, 40), "strip_width": 22.0, "notes": "One streetcar track (two rails), transparent between."},
	"city/quay": {"kind": "strip", "template_size": Vector2i(128, 32), "strip_width": 16.0, "notes": "Stone river edge with railing; water side at the bottom."},
	"city/fence": {"kind": "strip", "template_size": Vector2i(128, 16), "strip_width": 8.0, "notes": "Wooden board fence."},
	# Buildings.
	"roofs/tar": {"kind": "tile", "template_size": Vector2i(256, 256), "tile_world_size": 256.0, "notes": "Tar-paper flat roof."},
	"roofs/gravel": {"kind": "tile", "template_size": Vector2i(256, 256), "tile_world_size": 256.0, "notes": "Gravel flat roof."},
	"roofs/tin": {"kind": "tile", "template_size": Vector2i(256, 256), "tile_world_size": 256.0, "notes": "Corrugated sheet roof."},
	"roofs/ballast": {"kind": "tile", "template_size": Vector2i(256, 256), "tile_world_size": 256.0, "notes": "Railroad ballast with two tracks (runs left-right)."},
	"roofs/steel": {"kind": "tile", "template_size": Vector2i(256, 256), "tile_world_size": 256.0, "notes": "Riveted steel deck (raised bridge)."},
	"roofs/parapet": {"kind": "strip", "template_size": Vector2i(128, 32), "strip_width": 8.0, "notes": "Roof edge: stone coping (outside, top) and brick."},
	"facades/brick_red": {"kind": "facade", "template_size": Vector2i(256, 192), "notes": "Red-brick apartments."},
	"facades/brick_red_lit": {"kind": "light", "template_size": Vector2i(256, 192), "notes": "Window light for brick_red."},
	"facades/brick_brown": {"kind": "facade", "template_size": Vector2i(256, 192), "notes": "Brown-brick shops (shopfronts below)."},
	"facades/brick_brown_lit": {"kind": "light", "template_size": Vector2i(256, 192), "notes": "Window light for brick_brown."},
	"facades/greystone": {"kind": "facade", "template_size": Vector2i(256, 192), "notes": "Limestone greystone flats."},
	"facades/greystone_lit": {"kind": "light", "template_size": Vector2i(256, 192), "notes": "Window light for greystone."},
	"facades/warehouse": {"kind": "facade", "template_size": Vector2i(256, 192), "notes": "Warehouse: steel windows, loading doors."},
	"facades/warehouse_lit": {"kind": "light", "template_size": Vector2i(256, 192), "notes": "Window light for warehouse."},
	"facades/club": {"kind": "facade", "template_size": Vector2i(256, 192), "notes": "The Copper Owl jazz club."},
	"facades/club_lit": {"kind": "light", "template_size": Vector2i(256, 192), "notes": "Window and bulb light for club."},
	"facades/garage": {"kind": "facade", "template_size": Vector2i(256, 192), "notes": "Doyle's Garage: painted brick, garage doors."},
	"facades/garage_lit": {"kind": "light", "template_size": Vector2i(256, 192), "notes": "Window light for garage."},
	"facades/party": {"kind": "facade", "template_size": Vector2i(256, 192), "notes": "Blank side wall between buildings."},
	"facades/rear": {"kind": "facade", "template_size": Vector2i(256, 192), "notes": "Alley side with fire escapes."},
	"facades/rear_lit": {"kind": "light", "template_size": Vector2i(256, 192), "notes": "Window and bulb light for rear."},
	"facades/steel": {"kind": "facade", "template_size": Vector2i(256, 192), "notes": "Steel truss (the raised bascule bridge)."},
	"facades/stone": {"kind": "facade", "template_size": Vector2i(256, 192), "notes": "Granite embankment wall."},
	# Rooftop furniture (drawn at roof height).
	"roof/chimney": {"kind": "sprite", "template_size": Vector2i(48, 48), "display_size": Vector2(27, 27), "notes": "Brick chimney stack."},
	"roof/vent": {"kind": "sprite", "template_size": Vector2i(32, 32), "display_size": Vector2(17, 17), "notes": "Mushroom vent."},
	"roof/skylight": {"kind": "sprite", "template_size": Vector2i(96, 64), "display_size": Vector2(54, 36), "notes": "Skylight."},
	"roof/skylight_lit": {"kind": "light", "template_size": Vector2i(96, 64), "display_size": Vector2(54, 36), "notes": "Skylight light."},
	"roof/stair_hut": {"kind": "sprite", "template_size": Vector2i(96, 96), "display_size": Vector2(50, 50), "notes": "Roof access stair hut, door on the right."},
	"roof/water_tank": {"kind": "sprite", "template_size": Vector2i(112, 112), "display_size": Vector2(58, 58), "notes": "Wooden water tank."},
	"roof/laundry": {"kind": "sprite", "template_size": Vector2i(128, 64), "display_size": Vector2(70, 35), "notes": "Washing lines."},
	"signs/copper_owl": {"kind": "sprite", "template_size": Vector2i(256, 128), "display_size": Vector2(150, 75), "notes": "Copper Owl rooftop sign."},
	"signs/copper_owl_lit": {"kind": "light", "template_size": Vector2i(256, 128), "display_size": Vector2(150, 75), "notes": "Copper Owl neon."},
	"signs/hotel": {"kind": "sprite", "template_size": Vector2i(256, 64), "display_size": Vector2(150, 38), "notes": "Hotel Marlowe rooftop letters."},
	"signs/hotel_lit": {"kind": "light", "template_size": Vector2i(256, 64), "display_size": Vector2(150, 38), "notes": "Hotel Marlowe bulbs."},
	"signs/barber": {"kind": "sprite", "template_size": Vector2i(256, 64), "display_size": Vector2(130, 33), "notes": "Painted roof lettering, transparent."},
	"signs/grocery": {"kind": "sprite", "template_size": Vector2i(256, 64), "display_size": Vector2(130, 33), "notes": "Painted roof lettering, transparent."},
	"signs/hardware": {"kind": "sprite", "template_size": Vector2i(256, 64), "display_size": Vector2(130, 33), "notes": "Painted roof lettering, transparent."},
	"signs/garage": {"kind": "sprite", "template_size": Vector2i(256, 64), "display_size": Vector2(150, 38), "notes": "Painted roof lettering, transparent."},
	"signs/cold_storage": {"kind": "sprite", "template_size": Vector2i(384, 64), "display_size": Vector2(220, 37), "notes": "Painted roof lettering, transparent."},
	# Street furniture.
	"props/lamp_head": {"kind": "sprite", "template_size": Vector2i(64, 64), "display_size": Vector2(22, 22), "notes": "Street lamp lantern seen from above."},
	"props/lamp_base": {"kind": "sprite", "template_size": Vector2i(32, 32), "display_size": Vector2(12, 12), "notes": "Street lamp base."},
	"props/hydrant": {"kind": "sprite", "template_size": Vector2i(40, 40), "display_size": Vector2(15, 15), "notes": "Fire hydrant."},
	"props/trash_can": {"kind": "sprite", "template_size": Vector2i(48, 48), "display_size": Vector2(18, 18), "notes": "Ash can."},
	"props/crate": {"kind": "sprite", "template_size": Vector2i(64, 64), "display_size": Vector2(26, 26), "notes": "Wooden crate."},
	"props/crates": {"kind": "sprite", "template_size": Vector2i(96, 96), "display_size": Vector2(44, 44), "notes": "Stack of crates."},
	"props/barrel": {"kind": "sprite", "template_size": Vector2i(48, 48), "display_size": Vector2(20, 20), "notes": "Barrel."},
	"props/barricade": {"kind": "sprite", "template_size": Vector2i(192, 64), "display_size": Vector2(96, 32), "notes": "Street-closed sawhorse."},
	"props/lantern": {"kind": "sprite", "template_size": Vector2i(32, 32), "display_size": Vector2(12, 12), "notes": "Red warning lantern."},
	"props/mailbox": {"kind": "sprite", "template_size": Vector2i(40, 40), "display_size": Vector2(16, 16), "notes": "Mailbox."},
	"props/gas_pump": {"kind": "sprite", "template_size": Vector2i(48, 48), "display_size": Vector2(22, 22), "notes": "Gas pump."},
	"props/newsstand": {"kind": "sprite", "template_size": Vector2i(96, 64), "display_size": Vector2(46, 30), "notes": "Newsstand."},
	"props/awning_red": {"kind": "sprite", "template_size": Vector2i(160, 64), "display_size": Vector2(84, 34), "notes": "Shop awning; wall side at the top."},
	"props/awning_green": {"kind": "sprite", "template_size": Vector2i(160, 64), "display_size": Vector2(84, 34), "notes": "Shop awning; wall side at the top."},
	"props/fire_escape": {"kind": "sprite", "template_size": Vector2i(128, 40), "display_size": Vector2(64, 20), "notes": "Iron fire-escape landing; wall side at the top."},
	"props/barber_pole": {"kind": "sprite", "template_size": Vector2i(32, 32), "display_size": Vector2(14, 14), "notes": "Barber's pole beside the shop door."},
	"props/call_box": {"kind": "sprite", "template_size": Vector2i(40, 40), "display_size": Vector2(18, 18), "notes": "Police call box on its post."},
	"props/marquee": {"kind": "sprite", "template_size": Vector2i(256, 96), "display_size": Vector2(140, 52), "notes": "Copper Owl canopy; wall side at the top."},
	"props/marquee_lit": {"kind": "light", "template_size": Vector2i(256, 96), "display_size": Vector2(140, 52), "notes": "Canopy bulbs and lettering."},
	"decals/manhole": {"kind": "sprite", "template_size": Vector2i(48, 48), "display_size": Vector2(24, 24), "notes": "Manhole cover."},
	"decals/drain": {"kind": "sprite", "template_size": Vector2i(48, 24), "display_size": Vector2(24, 12), "notes": "Storm drain grate."},
	"decals/puddle": {"kind": "sprite", "template_size": Vector2i(128, 80), "display_size": Vector2(96, 60), "notes": "Puddle (semi-transparent)."},
	"decals/litter": {"kind": "sprite", "template_size": Vector2i(48, 48), "display_size": Vector2(18, 18), "notes": "Newspaper litter."},
	"decals/oil": {"kind": "sprite", "template_size": Vector2i(96, 96), "display_size": Vector2(52, 52), "notes": "Oil stain."},
	# Interiors (seen from above; furniture with its wall side at the top unless noted).
	"interiors/floor_parquet": {"kind": "tile", "template_size": Vector2i(256, 256), "tile_world_size": 128.0, "notes": "Oak parquet (the Copper Owl)."},
	"interiors/bar_counter": {"kind": "sprite", "template_size": Vector2i(420, 56), "display_size": Vector2(180, 24), "notes": "The Copper Owl's bar; customers along the bottom edge."},
	"interiors/back_bar": {"kind": "sprite", "template_size": Vector2i(420, 42), "display_size": Vector2(180, 18), "notes": "Shelves of bottles behind the bar."},
	"interiors/stool": {"kind": "sprite", "template_size": Vector2i(36, 36), "display_size": Vector2(14, 14), "notes": "Bar stool."},
	"interiors/table_club": {"kind": "sprite", "template_size": Vector2i(128, 128), "display_size": Vector2(56, 56), "notes": "Round club table with lamp and three chairs, centred."},
	"interiors/piano": {"kind": "sprite", "template_size": Vector2i(128, 88), "display_size": Vector2(56, 38), "notes": "Baby grand, keyboard and bench at the left."},
	"interiors/bandstand": {"kind": "sprite", "template_size": Vector2i(128, 240), "display_size": Vector2(60, 112), "notes": "Bandstand along a wall (right edge), curved front to the left."},
	"interiors/palm": {"kind": "sprite", "template_size": Vector2i(72, 72), "display_size": Vector2(28, 28), "notes": "Potted palm."},
	"interiors/door": {"kind": "sprite", "template_size": Vector2i(64, 12), "display_size": Vector2(28, 5), "notes": "Door leaf from above; hinge at the left end (stretched to the doorway)."},
	"interiors/floor_tile": {"kind": "tile", "template_size": Vector2i(128, 128), "tile_world_size": 64.0, "notes": "Black-and-cream checkerboard tile (the barbershop)."},
	"interiors/barber_chair": {"kind": "sprite", "template_size": Vector2i(72, 56), "display_size": Vector2(32, 25), "notes": "Barber chair, the sitter facing right."},
	"interiors/barber_counter": {"kind": "sprite", "template_size": Vector2i(336, 44), "display_size": Vector2(150, 20), "notes": "Mirror and marble counter with tonics."},
	"interiors/bench": {"kind": "sprite", "template_size": Vector2i(160, 40), "display_size": Vector2(70, 18), "notes": "Waiting bench with a newspaper."},
	"interiors/cabinet": {"kind": "sprite", "template_size": Vector2i(64, 52), "display_size": Vector2(30, 24), "notes": "Tall cupboard (Sal keeps the rye in it)."},
	"interiors/coat_rack": {"kind": "sprite", "template_size": Vector2i(40, 40), "display_size": Vector2(18, 18), "notes": "Coat stand with two coats."},
	"interiors/floor_boards": {"kind": "tile", "template_size": Vector2i(256, 256), "tile_world_size": 128.0, "notes": "Worn pine floorboards (shops, the flat)."},
	"interiors/shop_counter": {"kind": "sprite", "template_size": Vector2i(220, 56), "display_size": Vector2(96, 24), "notes": "Shop counter with cash register and scale; the shopkeeper's side at the top."},
	"interiors/shelf_grocery": {"kind": "sprite", "template_size": Vector2i(260, 44), "display_size": Vector2(118, 20), "notes": "Wall shelves of tins and boxes."},
	"interiors/shelf_hardware": {"kind": "sprite", "template_size": Vector2i(260, 44), "display_size": Vector2(118, 20), "notes": "Wall shelves of paint, rope, nails and tools."},
	"interiors/produce": {"kind": "sprite", "template_size": Vector2i(132, 56), "display_size": Vector2(60, 25), "notes": "Three crates of apples, potatoes and cabbages."},
	"interiors/sacks": {"kind": "sprite", "template_size": Vector2i(64, 64), "display_size": Vector2(28, 28), "notes": "Flour and sugar sacks."},
	"interiors/card_table": {"kind": "sprite", "template_size": Vector2i(112, 112), "display_size": Vector2(50, 50), "notes": "Back-room card table with two chairs, centred."},
	"interiors/gun_crate": {"kind": "sprite", "template_size": Vector2i(112, 56), "display_size": Vector2(50, 25), "notes": "Open crate of wrapped pistols and boxes of rounds."},
	# Effects (lights and particles).
	"fx/steam": {"kind": "sprite", "template_size": Vector2i(64, 64), "display_size": Vector2(48, 48), "notes": "Steam / smoke puff."},
	"fx/muzzle_flash": {"kind": "light", "template_size": Vector2i(64, 40), "display_size": Vector2(34, 21), "notes": "Muzzle flash; the muzzle is at the left edge, middle."},
	"fx/tracer": {"kind": "light", "template_size": Vector2i(64, 8), "display_size": Vector2(48, 5), "notes": "Bullet streak; the bullet is at the right end."},
	"fx/impact_dust": {"kind": "sprite", "template_size": Vector2i(48, 48), "display_size": Vector2(22, 22), "notes": "Brick dust where a bullet strikes a wall."},
	"fx/spark": {"kind": "light", "template_size": Vector2i(32, 32), "display_size": Vector2(12, 12), "notes": "Spark where a bullet strikes."},
	"fx/glow": {"kind": "light", "template_size": Vector2i(128, 128), "display_size": Vector2(128, 128), "notes": "Round warm glow (lamp halos, light spill)."},
	"fx/reflection": {"kind": "light", "template_size": Vector2i(64, 192), "display_size": Vector2(22, 70), "notes": "Light reflected on wet ground; the light is at the top."},
	# Interface.
	"ui/alert": {"kind": "sprite", "template_size": Vector2i(48, 48), "display_size": Vector2(30, 30), "notes": "Over the officer: he has seen you."},
	"ui/search": {"kind": "sprite", "template_size": Vector2i(48, 48), "display_size": Vector2(30, 30), "notes": "Over the officer: he is looking for you."},
	"ui/crosshair": {"kind": "sprite", "template_size": Vector2i(64, 64), "display_size": Vector2(30, 30), "notes": "Mouse aim reticle (screen px)."},
	"ui/panel": {"kind": "sprite", "template_size": Vector2i(96, 96), "display_size": Vector2(96, 96), "notes": "Nine-patch panel, 24 px margins."},
}

## Audio: OGG, WAV or MP3 overrides in custom/audio/<logical name>.<ext>.
const AUDIO := {
	"vehicles/engine_loop": {"loop": true, "bus": "Engine", "notes": "Engine foundation loop (pitch follows speed)."},
	"vehicles/engine_load": {"loop": true, "bus": "Engine", "notes": "Engine load layer, louder while accelerating."},
	"vehicles/tire_squeal": {"loop": true, "bus": "Effects", "notes": "Tyre squeal while sliding."},
	"vehicles/impact_car": {"loop": false, "bus": "Effects", "notes": "Car hits car, under 1 s."},
	"weapons/pistol_shot": {"loop": false, "bus": "Effects", "notes": "A .45 shot in a brick street, about 1 s with its echo."},
	"weapons/pistol_reload": {"loop": false, "bus": "Effects", "notes": "Magazine out and in, slide racked."},
	"weapons/bullet_impact": {"loop": false, "bus": "Effects", "notes": "A bullet striking brick."},
	"police/whistle": {"loop": false, "bus": "Effects", "notes": "The officer's whistle when he spots you."},
	"vehicles/impact_wall": {"loop": false, "bus": "Effects", "notes": "Car hits a wall or kerb object, under 1 s."},
}


## Display size (world px) of a sprite, sheet frame or light.
static func display_size(logical: String) -> Vector2:
	return SPECS[logical].get("display_size", Vector2(SPECS[logical].template_size))


## Converts a world-space tile size to the UV scale for a texture of any resolution.
static func uv_per_world_pixel(texture: Texture2D, tile_world_size: float) -> Vector2:
	return Vector2(texture.get_width(), texture.get_height()) / tile_world_size


## Scale that maps a texture of any resolution onto its display size.
static func scale_for(texture: Texture2D, size: Vector2) -> Vector2:
	return size / Vector2(texture.get_width(), texture.get_height())
