class_name MarketInteriors
extends RefCounted
## M015: the rooms you can walk into in Canal Market (data only; see
## InteriorPlan), written in the market's own coordinates and moved with it.
## Each sits in a building of CanalMarket, which keeps its outside look.


static func add_to(d: DistrictLayout) -> void:
	d.interiors.append(market_hall(d))
	d.interiors.append(golden_lantern(d))
	d.interiors.append(pawnshop(d))


## The Canal Market Hall under its glass roof: two rows of stalls either side
## of a sawdust aisle, most of them shut for the night under their canvas,
## the night trade still going - Josef Hrabal's butcher's stall, Mrs.
## Dvorak's coffee urn at the far end, crates and sacks, the market's
## noticeboard by the door. The main door on Market Street, the back door
## onto Foundry Street where the barrels come in.
static func market_hall(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("market_hall", CanalMarket.MARKET_HALL)
	p.building = d.building_named(CanalMarket.MARKET_HALL)
	p.building_rect = d.buildings[p.building].rect  # x 691..1269, y 921..1169 (the front on Market Street)
	p.room = p.building_rect
	p.marker = "ui/marker_market"
	p.floor = "interiors/floor_concrete"
	p.doors = [{"side": Vector2.UP, "at": 980.0, "width": 44.0}, {"side": Vector2.DOWN, "at": 900.0, "width": 28.0}]
	p.furniture = [
		# the north row of stalls (the door's way kept clear)
		{"kind": "props/stall_a", "pos": Vector2(760, 960), "rot": PI, "box": Vector2(70, 34)},
		{"kind": "interiors/shop_counter", "pos": Vector2(870, 975), "box": Vector2(70, 20)},  # Hrabal's block
		{"kind": "props/stall_b", "pos": Vector2(1100, 960), "rot": PI, "box": Vector2(70, 34)},
		{"kind": "props/stall_a", "pos": Vector2(1200, 960), "rot": PI, "box": Vector2(70, 34)},
		# the south row (the back door's way kept clear)
		{"kind": "props/stall_b", "pos": Vector2(780, 1130), "box": Vector2(70, 34)},
		{"kind": "props/stall_a", "pos": Vector2(1030, 1130), "box": Vector2(70, 34)},
		{"kind": "props/stall_b", "pos": Vector2(1130, 1130), "box": Vector2(70, 34)},
		{"kind": "interiors/produce", "pos": Vector2(1215, 1125), "box": Vector2(30, 30)},
		# the coffee stand at the far end of the aisle
		{"kind": "interiors/clerk_counter", "pos": Vector2(1228, 1045), "rot": PI / 2, "box": Vector2(150, 20)},
		{"kind": "interiors/stool", "pos": Vector2(1196, 1028), "radius": 6.0},
		{"kind": "interiors/stool", "pos": Vector2(1196, 1062), "radius": 6.0},
		{"kind": "interiors/noticeboard", "pos": Vector2(702, 1045), "rot": -PI / 2},
		{"kind": "interiors/crate_stack", "pos": Vector2(712, 1000), "box": Vector2(28, 28)},
		{"kind": "interiors/sacks", "pos": Vector2(712, 1090), "box": Vector2(26, 26)},
		{"kind": "interiors/crate_stack", "pos": Vector2(960, 1150), "box": Vector2(28, 28)},
	]
	p.lamps = [
		{"pos": Vector2(800, 1045), "color": Color(1.0, 0.82, 0.55), "energy": 0.75, "radius": 170.0},
		{"pos": Vector2(1000, 1045), "color": Color(1.0, 0.82, 0.55), "energy": 0.75, "radius": 170.0},
		{"pos": Vector2(1200, 1045), "color": Color(1.0, 0.8, 0.5), "energy": 0.85, "radius": 150.0},  # over the coffee
		{"pos": Vector2(870, 975), "color": Color(1.0, 0.9, 0.7), "energy": 0.6, "radius": 80.0},  # the butcher's bulb
	]
	p.people = [
		{"id": "hrabal", "name": "Josef Hrabal", "look": "characters/dutch", "pos": Vector2(870, 950), "facing": PI / 2},
		{"id": "dvorak", "name": "Mrs. Dvorak", "look": "characters/patron_woman", "pos": Vector2(1252, 1045), "facing": PI},
		{"id": "shopper_a", "name": "", "look": "characters/lady", "pos": Vector2(900, 1012), "facing": -PI / 2},
		{"id": "shopper_b", "name": "", "look": "characters/worker", "pos": Vector2(1180, 1045), "facing": 0.0},
	]
	p.spots = [
		{"id": "hrabal", "pos": Vector2(870, 1008), "radius": 20.0, "prompt": "Talk to the butcher"},
		{"id": "dvorak", "pos": Vector2(1176, 1045), "radius": 20.0, "prompt": "Talk to the coffee woman"},
		{"id": "hall_board", "pos": Vector2(722, 1045), "radius": 18.0, "prompt": "Read the market noticeboard"},
	]
	return p


## The Golden Lantern: a narrow chop-suey house, red paper lanterns low over
## four tables, the counter at the back with the register and the till's
## brass bell, the kitchen's steam through the hatch. Henry Chu keeps it
## open until the El stops running and hears everything said at his tables.
static func golden_lantern(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("golden_lantern", CanalMarket.LANTERN)
	p.building = d.building_named(CanalMarket.LANTERN)
	p.building_rect = d.buildings[p.building].rect  # x 2381..2661, y 453..599 (the front on Market Street)
	p.room = p.building_rect
	p.marker = "ui/marker_eats"
	p.floor = "interiors/floor_tile"
	p.doors = [{"side": Vector2.DOWN, "at": 2500.0, "width": 28.0}]
	p.furniture = [
		{"kind": "interiors/shop_counter", "pos": Vector2(2590, 478), "box": Vector2(100, 20)},
		{"kind": "interiors/radio", "pos": Vector2(2640, 470), "box": Vector2(14, 12)},
		{"kind": "interiors/table_club", "pos": Vector2(2420, 500), "radius": 15.0},
		{"kind": "interiors/chair", "pos": Vector2(2420, 476)},
		{"kind": "interiors/chair", "pos": Vector2(2420, 524), "rot": PI},
		{"kind": "interiors/table_club", "pos": Vector2(2420, 560), "radius": 15.0},
		{"kind": "interiors/chair", "pos": Vector2(2444, 560), "rot": PI / 2},  # Kaz's
		{"kind": "interiors/table_club", "pos": Vector2(2580, 560), "radius": 15.0},
		{"kind": "interiors/chair", "pos": Vector2(2556, 560), "rot": -PI / 2},
		{"kind": "interiors/chair", "pos": Vector2(2604, 560), "rot": PI / 2},
		{"kind": "interiors/smoke", "pos": Vector2(2620, 470), "z": 11},
	]
	p.lamps = [
		{"pos": Vector2(2430, 530), "color": Color(1.0, 0.45, 0.3), "energy": 0.85, "radius": 110.0},
		{"pos": Vector2(2590, 540), "color": Color(1.0, 0.45, 0.3), "energy": 0.85, "radius": 110.0},
		{"pos": Vector2(2590, 478), "color": Color(1.0, 0.8, 0.5), "energy": 0.6, "radius": 80.0},
	]
	p.people = [
		{"id": "chu", "name": "Henry Chu", "look": "characters/clerk", "pos": Vector2(2590, 464), "facing": PI / 2},
		{"id": "diner_a", "name": "", "look": "characters/patron_man", "pos": Vector2(2420, 476), "facing": PI / 2},
		{"id": "diner_b", "name": "", "look": "characters/patron_woman", "pos": Vector2(2556, 560), "facing": 0.0},
		# M015.13: Kaz Wrobel at the corner table after his rounds (eleven to two)
		{"id": "kaz", "name": "Kaz Wrobel", "look": "characters/patron_man", "pos": Vector2(2444, 560), "facing": PI},
	]
	p.spots = [
		{"id": "chu", "pos": Vector2(2590, 505), "radius": 20.0, "prompt": "Talk to Mr. Chu"},
		{"id": "kaz", "pos": Vector2(2470, 530), "radius": 18.0, "prompt": "Talk to the man at the corner table"},
	]
	return p


## A. Feld, Loans: a pawnshop's front - the long counter with its brass
## grille, shelves to the ceiling of other people's things (clocks, horns,
## a saxophone, wedding rings in a tray), the safe, a rack of tickets. Abe
## Feld buys anything, sells most things and remembers everybody.
static func pawnshop(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("pawnshop", CanalMarket.PAWN)
	p.building = d.building_named(CanalMarket.PAWN)
	p.building_rect = d.buildings[p.building].rect  # x 1531..1711, y 1431..1557 (the front on Foundry Street)
	p.room = p.building_rect
	p.marker = "ui/marker_pawn"
	p.floor = "interiors/floor_boards"
	p.doors = [{"side": Vector2.UP, "at": 1620.0, "width": 28.0}]
	p.furniture = [
		{"kind": "interiors/shop_counter", "pos": Vector2(1620, 1505), "box": Vector2(130, 18)},
		{"kind": "interiors/shelf_hardware", "pos": Vector2(1580, 1546), "rot": PI, "box": Vector2(60, 14)},
		{"kind": "interiors/records_shelf", "pos": Vector2(1660, 1546), "rot": PI, "box": Vector2(60, 14)},
		{"kind": "interiors/safe", "pos": Vector2(1698, 1530), "box": Vector2(18, 18)},
		{"kind": "interiors/tall_clock", "pos": Vector2(1542, 1452), "radius": 7.0},
		{"kind": "interiors/wall_prints", "pos": Vector2(1660, 1440)},
		{"kind": "interiors/gun_crate", "pos": Vector2(1690, 1462), "box": Vector2(24, 18)},
	]
	p.lamps = [
		{"pos": Vector2(1620, 1505), "color": Color(1.0, 0.85, 0.6), "energy": 0.8, "radius": 110.0},
	]
	p.people = [
		{"id": "feld", "name": "Abe Feld", "look": "characters/feeney", "pos": Vector2(1620, 1526), "facing": -PI / 2},
	]
	p.spots = [
		{"id": "feld", "pos": Vector2(1620, 1482), "radius": 20.0, "prompt": "Talk to the pawnbroker"},
	]
	return p
