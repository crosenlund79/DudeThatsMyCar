class_name RiversideInteriors
extends RefCounted
## The rooms you can walk into in the Riverside Ward (data only; see
## InteriorPlan). Coordinates are world px; each room sits in an existing
## building of RiversideWard, which keeps its outside look.


static func add_to(d: DistrictLayout) -> void:
	d.interiors.append(copper_owl(d))
	d.interiors.append(barber_shop(d))
	d.interiors.append(grocery(d))
	d.interiors.append(hardware_store(d))
	d.interiors.append(flat(d))
	d.interiors.append(vet(d))
	# the barber's pole beside Sal's door
	d.props.append({"kind": "props/barber_pole", "pos": Vector2(1102, 444), "rot": 0.0, "height": 0.0, "radius": 4.0})


## The Copper Owl supper club: the bar along the back wall with Augie behind
## it, tables with white cloths, a baby grand on the bandstand, a back door to
## the alley where tonight's delivery stands. Rourke keeps the corner table
## by the door (M005): this is where Danny settles up. The Bird sings at the
## front of the bandstand, at her microphone in a spotlight (M006); the piano
## stands behind her.
static func copper_owl(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("copper_owl", "The Copper Owl")
	p.marker = "ui/marker_bar"
	p.building = d.building_named("The Copper Owl")
	p.building_rect = d.buildings[p.building].rect  # x 2151..2431, y 168..439
	p.room = p.building_rect
	p.floor = "interiors/floor_parquet"
	p.doors = [
		{"side": Vector2.DOWN, "at": 2291.0, "width": 30.0},  # under the canopy on Marlowe Avenue
		{"side": Vector2.UP, "at": 2400.0, "width": 26.0},  # back door to the alley
	]
	p.furniture = [
		{"kind": "interiors/back_bar", "pos": Vector2(2249, 186), "box": Vector2(180, 18)},
		{"kind": "interiors/bar_counter", "pos": Vector2(2249, 222), "box": Vector2(180, 24)},
		{"kind": "interiors/bandstand", "pos": Vector2(2393, 305)},
		{"kind": "interiors/piano", "pos": Vector2(2397, 276), "rot": PI, "box": Vector2(50, 34), "z": 1},
		{"kind": "interiors/microphone", "pos": Vector2(2366, 333), "z": 1},
		{"kind": "interiors/table_club", "pos": Vector2(2192, 305), "radius": 17.0},
		{"kind": "interiors/table_club", "pos": Vector2(2192, 392), "rot": 0.6, "radius": 17.0},
		{"kind": "interiors/table_club", "pos": Vector2(2318, 300), "rot": 1.2, "radius": 17.0},
		{"kind": "interiors/table_club", "pos": Vector2(2336, 392), "rot": 2.1, "radius": 17.0},
		{"kind": "interiors/palm", "pos": Vector2(2174, 416), "radius": 8.0},
		{"kind": "interiors/palm", "pos": Vector2(2410, 418), "radius": 8.0},
	]
	for x in [2180.0, 2210.0, 2240.0, 2270.0, 2300.0, 2330.0]:
		p.furniture.append({"kind": "interiors/stool", "pos": Vector2(x, 244)})
	p.lamps = [
		{"pos": Vector2(2249, 212), "color": Color(1.0, 0.78, 0.48), "energy": 1.25, "radius": 170.0},
		{"pos": Vector2(2200, 350), "color": Color(1.0, 0.74, 0.5), "energy": 1.05, "radius": 150.0},
		{"pos": Vector2(2325, 350), "color": Color(1.0, 0.74, 0.5), "energy": 1.05, "radius": 150.0},
		{"pos": Vector2(2392, 300), "color": Color(1.0, 0.62, 0.55), "energy": 1.0, "radius": 110.0},
		{"pos": Vector2(2380, 333), "color": Color(1.0, 0.86, 0.7), "energy": 1.1, "radius": 70.0},  # her spotlight
	]
	p.people = [
		{"id": "augie", "name": "Augie", "look": "characters/bartender", "pos": Vector2(2240, 202), "facing": PI / 2},
		{"id": "patron_a", "name": "", "look": "characters/patron_man", "pos": Vector2(2172, 300), "facing": 0.0},
		{"id": "patron_b", "name": "", "look": "characters/patron_woman", "pos": Vector2(2210, 291), "facing": PI},
		{"id": "rourke", "name": "Rourke", "look": "characters/boss", "pos": Vector2(2356, 400), "facing": PI + 0.4},
		{"id": "bird", "name": "The Bird", "look": "characters/singer", "pos": Vector2(2384, 333), "facing": PI},
	]
	p.spots = [
		{"id": "augie", "pos": Vector2(2240, 252), "radius": 34.0, "prompt": "Talk to Augie"},
		{"id": "rourke", "pos": Vector2(2302, 384), "radius": 26.0, "prompt": "Talk to Rourke"},
		{"id": "bird", "pos": Vector2(2343, 336), "radius": 22.0, "prompt": "Talk to the Bird"},
	]
	return p


## Sal's Barber Shop, a block west of the club on Marlowe Avenue: two chairs
## before the mirror, a waiting bench, and the cupboard where Sal keeps the
## bootleg rye the Copper Owl runs short of.
static func barber_shop(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("barber_shop", "Sal's Barber Shop")
	p.marker = "ui/marker_barber"
	p.building = d.building_named("Sal's Barber Shop")
	p.building_rect = d.buildings[p.building].rect  # x 905..1125, y 168..439
	p.room = Rect2(905, 279, 220, 160)  # the shop at the front; the back rooms stay shut
	p.floor = "interiors/floor_tile"
	p.doors = [{"side": Vector2.DOWN, "at": 1080.0, "width": 28.0}]
	p.furniture = [
		{"kind": "interiors/barber_counter", "pos": Vector2(990, 297), "box": Vector2(150, 16)},
		{"kind": "interiors/barber_chair", "pos": Vector2(955, 330), "rot": -PI / 2, "radius": 11.0},
		{"kind": "interiors/barber_chair", "pos": Vector2(1025, 330), "rot": -PI / 2, "radius": 11.0},
		{"kind": "interiors/bench", "pos": Vector2(923, 385), "rot": -PI / 2, "box": Vector2(70, 14)},
		{"kind": "interiors/cabinet", "pos": Vector2(1098, 301), "box": Vector2(30, 24)},
		{"kind": "interiors/coat_rack", "pos": Vector2(1105, 380), "radius": 6.0},
	]
	p.lamps = [
		{"pos": Vector2(990, 325), "color": Color(1.0, 0.84, 0.62), "energy": 0.95, "radius": 150.0},
		{"pos": Vector2(1060, 400), "color": Color(1.0, 0.8, 0.58), "energy": 0.8, "radius": 110.0},
	]
	p.people = [
		{"id": "sal", "name": "Sal", "look": "characters/barber", "pos": Vector2(990, 334), "facing": PI / 2},
	]
	p.spots = [
		{"id": "sal", "pos": Vector2(990, 366), "radius": 32.0, "prompt": "Talk to Sal"},
	]
	return p


## Novak's Grocery on the corner of Kessler Street, across from the beat
## cop's round: shelves of tins, crates of produce, the counter with the till.
## Mr. Novak pays for protection; push him too hard and he runs for the copper.
static func grocery(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("grocery", "Novak's Grocery")
	p.marker = "ui/marker_grocery"
	p.building = d.building_named("Novak's Grocery")
	p.building_rect = d.buildings[p.building].rect  # x 1781..2001, y 761..1032
	p.room = Rect2(1781, 761, 220, 165)
	p.floor = "interiors/floor_boards"
	p.doors = [{"side": Vector2.UP, "at": 1828.0, "width": 28.0}]
	p.furniture = [
		{"kind": "interiors/shelf_grocery", "pos": Vector2(1799, 850), "rot": -PI / 2, "box": Vector2(118, 16)},
		{"kind": "interiors/shelf_grocery", "pos": Vector2(1880, 908), "rot": PI, "box": Vector2(118, 16)},
		{"kind": "interiors/shop_counter", "pos": Vector2(1950, 838), "rot": PI / 2, "box": Vector2(96, 20)},
		{"kind": "interiors/produce", "pos": Vector2(1898, 785), "box": Vector2(60, 22)},
		{"kind": "interiors/sacks", "pos": Vector2(1977, 900), "radius": 11.0},
		{"kind": "props/barrel", "pos": Vector2(1872, 852), "radius": 9.0},
	]
	p.lamps = [
		{"pos": Vector2(1880, 840), "color": Color(1.0, 0.82, 0.56), "energy": 0.95, "radius": 150.0},
		{"pos": Vector2(1962, 830), "color": Color(1.0, 0.8, 0.55), "energy": 0.8, "radius": 110.0},
	]
	p.people = [
		{"id": "novak", "name": "Mr. Novak", "look": "characters/grocer", "pos": Vector2(1976, 838), "facing": PI},
	]
	p.spots = [
		{"id": "novak", "pos": Vector2(1921, 838), "radius": 30.0, "prompt": "Talk to Mr. Novak"},
	]
	return p


## Lindqvist Hardware, Marlowe Avenue: nails, paint and rope at the front
## counter, and through the door at the back, Eddie's card table and his
## crate of pistols and .45 rounds.
static func hardware_store(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("hardware", "Lindqvist Hardware")
	p.marker = "ui/marker_hardware"
	p.building = d.building_named("Lindqvist Hardware")
	p.building_rect = d.buildings[p.building].rect  # x 927..1157, y 761..1032
	p.room = Rect2(927, 761, 230, 250)
	p.floor = "interiors/floor_boards"
	p.doors = [{"side": Vector2.UP, "at": 975.0, "width": 28.0}]
	p.partitions = [{"a": Vector2(927, 900), "b": Vector2(1157, 900), "door_at": 1095.0, "door_width": 30.0}]
	p.furniture = [
		{"kind": "interiors/shelf_hardware", "pos": Vector2(945, 838), "rot": -PI / 2, "box": Vector2(118, 16)},
		{"kind": "interiors/shelf_hardware", "pos": Vector2(1139, 828), "rot": PI / 2, "box": Vector2(118, 16)},
		{"kind": "interiors/shop_counter", "pos": Vector2(1030, 862), "rot": PI, "box": Vector2(96, 20)},
		{"kind": "props/barrel", "pos": Vector2(1004, 798), "radius": 9.0},
		{"kind": "props/barrel", "pos": Vector2(1024, 788), "radius": 9.0},
		# the back room
		{"kind": "interiors/card_table", "pos": Vector2(1000, 955), "radius": 18.0},
		{"kind": "interiors/gun_crate", "pos": Vector2(1100, 985), "box": Vector2(50, 22)},
		{"kind": "props/crate", "pos": Vector2(1140, 930), "rot": 0.3, "box": Vector2(22, 22)},
	]
	p.lamps = [
		{"pos": Vector2(1040, 830), "color": Color(1.0, 0.84, 0.6), "energy": 0.95, "radius": 150.0},
		{"pos": Vector2(1005, 950), "color": Color(1.0, 0.68, 0.42), "energy": 0.95, "radius": 115.0},
	]
	p.people = [
		{"id": "lindqvist", "name": "Mr. Lindqvist", "look": "characters/clerk", "pos": Vector2(1030, 885), "facing": -PI / 2},
		{"id": "eddie", "name": "Eddie", "look": "characters/dealer", "pos": Vector2(982, 955), "facing": 0.0},
	]
	p.spots = [
		{"id": "lindqvist", "pos": Vector2(1030, 834), "radius": 28.0, "prompt": "Talk to Mr. Lindqvist"},
		{"id": "eddie", "pos": Vector2(1032, 952), "radius": 30.0, "prompt": "Talk to Eddie"},
	]
	return p


## Your flat: one room on the ground floor of the Marlowe Flats, next door to
## the Copper Owl. An iron bed, a rag rug, a table with yesterday's Tribune, a
## stove, a wardrobe and a radio. Every night starts here, and here you sleep.
static func flat(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("home", "Your Flat")
	p.marker = "ui/marker_home"
	p.is_home = true
	p.building = d.building_named("Marlowe Flats")
	p.building_rect = d.buildings[p.building].rect  # x 2455..2655, y 168..439
	p.room = Rect2(2455, 299, 170, 140)
	p.floor = "interiors/floor_boards"
	p.doors = [{"side": Vector2.DOWN, "at": 2478.0, "width": 28.0}]
	p.furniture = [
		{"kind": "interiors/rug", "pos": Vector2(2545, 384), "z": -1},
		{"kind": "interiors/bed", "pos": Vector2(2486, 340), "box": Vector2(32, 60)},
		{"kind": "interiors/radio", "pos": Vector2(2520, 316), "box": Vector2(16, 12)},
		{"kind": "interiors/cabinet", "pos": Vector2(2565, 320), "box": Vector2(30, 24)},
		{"kind": "interiors/flat_table", "pos": Vector2(2590, 362), "radius": 15.0},
		{"kind": "interiors/stove", "pos": Vector2(2603, 416), "box": Vector2(24, 22)},
	]
	p.lamps = [
		{"pos": Vector2(2540, 362), "color": Color(1.0, 0.84, 0.58), "energy": 0.85, "radius": 140.0},
	]
	p.spots = [
		{"id": "bed", "pos": Vector2(2516, 352), "radius": 28.0, "prompt": "Go to bed"},
	]
	return p


## M006: Pettibone Animal Hospital on Pruitt Street. Doc Pettibone treats dogs,
## cats, the odd dray horse - and, for cash and no questions, the ward's
## gangsters, who cannot go to County. A tiled surgery: the examining table
## under a bright lamp, the cabinet of brown bottles, a basset hound asleep in
## the kennel, a bench for the waiting room.
static func vet(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("vet", "Pettibone Animal Hospital")
	p.marker = "ui/marker_vet"
	p.building = d.building_named("Pettibone Animal Hospital")
	p.building_rect = d.buildings[p.building].rect  # x 2069..2309, y 1179..1369
	p.room = Rect2(2069, 1229, 240, 140)
	p.floor = "interiors/floor_tile"
	p.doors = [{"side": Vector2.DOWN, "at": 2189.0, "width": 30.0}]
	p.furniture = [
		{"kind": "interiors/medicine_cabinet", "pos": Vector2(2112, 1247), "box": Vector2(56, 20)},
		{"kind": "interiors/exam_table", "pos": Vector2(2200, 1292), "box": Vector2(62, 31)},
		{"kind": "interiors/kennel", "pos": Vector2(2280, 1256), "box": Vector2(38, 34)},
		{"kind": "interiors/bench", "pos": Vector2(2090, 1320), "rot": -PI / 2, "box": Vector2(70, 14)},
		{"kind": "interiors/coat_rack", "pos": Vector2(2290, 1350), "radius": 6.0},
	]
	p.lamps = [
		{"pos": Vector2(2200, 1290), "color": Color(0.92, 0.96, 1.0), "energy": 1.15, "radius": 150.0},
		{"pos": Vector2(2110, 1330), "color": Color(1.0, 0.82, 0.56), "energy": 0.7, "radius": 110.0},
	]
	p.people = [
		{"id": "pettibone", "name": "Doc Pettibone", "look": "characters/vet", "pos": Vector2(2200, 1262), "facing": PI * 0.75},
	]
	p.spots = [
		{"id": "pettibone", "pos": Vector2(2150, 1300), "radius": 24.0, "prompt": "Talk to Doc Pettibone"},
	]
	return p
