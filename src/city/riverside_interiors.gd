class_name RiversideInteriors
extends RefCounted
## The rooms you can walk into in the Riverside Ward (data only; see
## InteriorPlan). Coordinates are world px; each room sits in an existing
## building of RiversideWard, which keeps its outside look.


static func add_to(d: DistrictLayout) -> void:
	d.interiors.append(copper_owl(d))
	d.interiors.append(back_room(d))
	d.interiors.append(gaming_room(d))
	d.interiors.append(barber_shop(d))
	d.interiors.append(grocery(d))
	d.interiors.append(hardware_store(d))
	d.interiors.append(flat(d))
	d.interiors.append(vet(d))
	d.interiors.append(union_hall(d))
	d.interiors.append(quilty_office(d))
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
		{"side": Vector2.LEFT, "at": 269.0, "width": 26.0, "inner": true},  # M010: through to the back room
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


## M010: the Copper Owl's back room, through the door in the club's west wall
## (in the back of the building next door, which keeps its outside look):
## worn carpet, one green-shaded lamp low over the card table, a sideboard of
## bottles, cigar smoke. Three regulars play No-Limit Hold'em here every night
## (PokerNight); the empty chair facing the door is for whoever sits in. A
## fourth man takes a chair that comes free, once a night.
static func back_room(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("back_room", "The Copper Owl's Back Room")
	p.building = d.building_at(Vector2(2066, 300))
	p.building_rect = d.buildings[p.building].rect  # x 1981..2151, y 168..439
	p.room = Rect2(1981, 168, 170, 150)  # the back of the house; the front stays shut
	p.floor = "interiors/floor_carpet"
	p.doors = [
		{"side": Vector2.RIGHT, "at": 269.0, "width": 26.0, "inner": true},
		{"side": Vector2.LEFT, "at": GAMING_DOOR, "width": 26.0, "inner": true},  # M011: through to the gaming room
	]
	var t := TABLE
	p.furniture = [
		{"kind": "interiors/poker_table", "pos": t, "radius": 28.0},
		{"kind": "interiors/chair", "pos": t + Vector2(0, 44), "rot": PI},  # Danny's, facing the door's side
		{"kind": "interiors/chair", "pos": t + Vector2(-44, 0), "rot": -PI / 2},
		{"kind": "interiors/chair", "pos": t + Vector2(0, -44)},
		{"kind": "interiors/chair", "pos": t + Vector2(44, 0), "rot": PI / 2},
		{"kind": "interiors/sideboard", "pos": Vector2(1995, 214), "rot": -PI / 2, "box": Vector2(56, 20)},
		{"kind": "interiors/coat_rack", "pos": Vector2(2136, 186), "radius": 6.0},
		{"kind": "interiors/palm", "pos": Vector2(1998, 296), "radius": 8.0},
		{"kind": "interiors/smoke", "pos": t + Vector2(6, -4), "z": 11},
	]
	p.lamps = [
		{"pos": t, "color": Color(0.86, 1.0, 0.72), "energy": 1.2, "radius": 120.0},  # the green-shaded lamp
		{"pos": Vector2(2000, 214), "color": Color(1.0, 0.68, 0.42), "energy": 0.45, "radius": 70.0},
	]
	p.people = [
		{"id": "irv", "name": "Irv Feldman", "look": "characters/clerk", "pos": t + Vector2(-44, 0), "facing": 0.0},
		{"id": "red", "name": "Red Gallagher", "look": "characters/worker", "pos": t + Vector2(0, -44), "facing": PI / 2},
		{"id": "pete", "name": "Lucky Pete", "look": "characters/patron_man", "pos": t + Vector2(44, 0), "facing": PI},
		{"id": "moe", "name": "Moe Brandt", "look": "characters/barber", "pos": t + Vector2(0, -44), "facing": PI / 2},
	]
	p.spots = [
		{"id": "poker", "pos": t + Vector2(0, 54), "radius": 24.0, "prompt": "Sit in at the card game"},
	]
	return p


## The back room's card table; the chairs stand round it 44 px out (Danny's to the south).
const TABLE := Vector2(2062, 243)
## M011: the door between the card room and the gaming room (y in the shared wall at x 1981).
const GAMING_DOOR := 268.0


## M011: the rest of the Copper Owl's back rooms - the gaming room, through the
## door in the card room's west wall, on the ground floor of the house next
## door (which keeps its outside look: flats above, the shop front shuttered).
## Dark boards, a long shaded lamp low over the wheel, three nickel machines
## along the back wall, a couple of small tables with drinks and ashtrays, old
## prints and a clock on the walls, smoke under the ceiling; the croupier at
## the wheel and a few players. Each game has its own place: the wheel's rail
## (RouletteTable), each machine (SlotMachine); E there plays.
static func gaming_room(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("gaming_room", "The Copper Owl's Gaming Room")
	p.building = d.building_at(Vector2(1880, 300))
	p.building_rect = d.buildings[p.building].rect  # x 1781..1981, y 168..439
	p.room = p.building_rect
	p.floor = "interiors/floor_gaming"
	p.doors = [{"side": Vector2.RIGHT, "at": GAMING_DOOR, "width": 26.0, "inner": true}]
	var w := WHEEL_TABLE
	p.furniture = [
		{"kind": "interiors/roulette_table", "pos": w, "box": Vector2(124, 56)},
		{"kind": "interiors/roulette_rotor", "pos": wheel_centre(), "z": 1},
		{"kind": "interiors/slot_machine_owl", "pos": SLOTS[0], "box": Vector2(26, 28)},
		{"kind": "interiors/slot_machine_bell", "pos": SLOTS[1], "box": Vector2(26, 28)},
		{"kind": "interiors/slot_machine_star", "pos": SLOTS[2], "box": Vector2(26, 28)},
		{"kind": "interiors/wall_prints", "pos": Vector2(1935, 183)},
		{"kind": "interiors/tall_clock", "pos": Vector2(1797, 240), "rot": -PI / 2, "box": Vector2(18, 14)},
		{"kind": "interiors/sideboard", "pos": Vector2(1799, 394), "rot": -PI / 2, "box": Vector2(56, 20)},
		{"kind": "interiors/coat_rack", "pos": Vector2(1962, 226), "radius": 6.0},
		{"kind": "interiors/side_table", "pos": Vector2(1846, 408), "radius": 13.0},
		{"kind": "interiors/chair", "pos": Vector2(1846 - 22, 408), "rot": -PI / 2},
		{"kind": "interiors/chair", "pos": Vector2(1846 + 22, 408), "rot": PI / 2},
		{"kind": "interiors/side_table", "pos": Vector2(1946, 404), "radius": 13.0},
		{"kind": "interiors/chair", "pos": Vector2(1946 - 22, 404), "rot": -PI / 2},
		{"kind": "interiors/spittoon", "pos": Vector2(1964, 356)},
		{"kind": "interiors/smoke", "pos": w + Vector2(10, -6), "z": 11},
		{"kind": "interiors/smoke", "pos": Vector2(1900, 404), "rot": 1.4, "z": 11},
	]
	p.lamps = [
		{"pos": w, "color": Color(1.0, 0.8, 0.52), "energy": 1.15, "radius": 150.0},  # the long shade over the wheel
		{"pos": Vector2(1850, 206), "color": Color(1.0, 0.7, 0.45), "energy": 0.6, "radius": 90.0},  # over the machines
		{"pos": Vector2(1846, 408), "color": Color(1.0, 0.66, 0.4), "energy": 0.45, "radius": 70.0},
		{"pos": Vector2(1946, 404), "color": Color(1.0, 0.66, 0.4), "energy": 0.45, "radius": 70.0},
	]
	p.people = [
		{"id": "croupier", "name": "Leo Varga", "look": "characters/croupier", "pos": CROUPIER, "facing": PI / 2},
		# M013: the regulars (Patrons.ROSTER): Mrs. Halloway and Big Stan at the rail, Bertie with his drink
		{"id": "edna", "name": "", "look": "characters/lady", "pos": Vector2(1858, 372), "facing": -PI / 2},
		{"id": "stan", "name": "", "look": "characters/patron_man", "pos": Vector2(1914, 278), "facing": PI / 2},
		{"id": "bertie", "name": "", "look": "characters/clerk", "pos": Vector2(1822, 410), "facing": 0.0},
		{"id": "dolly", "name": "", "look": "characters/patron_woman", "pos": Vector2(1870, 410), "facing": PI},
		{"id": "mick", "name": "", "look": "characters/worker", "pos": Vector2(1922, 406), "facing": 0.0},
	]
	p.spots = [
		{"id": "roulette", "pos": ROULETTE_SPOT, "radius": 22.0, "prompt": "Play the wheel"},
	]
	for i in SLOTS.size():
		p.spots.append({"id": "slot_%d" % i, "pos": SLOTS[i] + Vector2(0, 32), "radius": 15.0,
			"prompt": "Play the %s" % SLOT_NAMES[i]})
	return p


## M011: the gaming room's wheel table (its wheel at the left end), where the
## croupier stands and where Danny steps up to bet.
const WHEEL_TABLE := Vector2(1874, 322)
const CROUPIER := Vector2(1850, 276)
const ROULETTE_SPOT := Vector2(1892, 372)
## M011: the three machines along the back wall, left to right, and their names.
const SLOTS: Array[Vector2] = [Vector2(1816, 194), Vector2(1850, 194), Vector2(1884, 194)]
const SLOT_NAMES: Array[String] = ["Owl", "Bell", "Star"]


## M013: where the gaming room's regulars stand, sit and play (each place
## kept for one of them - Patrons / GamingRoom - so nobody shares, and the
## Bell is left for Danny): spot -> [where, facing]; and the floor's walking
## graph (waypoints and the straight, clear legs between them) they cross the
## room by, in at the door from the card room and out again.
const ROOM_SPOTS := {
	"rail_edna": [Vector2(1858, 372), -PI / 2], "sideboard": [Vector2(1830, 366), PI],
	"rail_stan": [Vector2(1914, 278), PI / 2], "watch_ne": [Vector2(1944, 238), 2.5],
	"rail_east": [Vector2(1954, 322), PI], "table1_l": [Vector2(1822, 410), 0.0],
	"slot_0": [Vector2(1816, 228), -PI / 2], "table1_r": [Vector2(1870, 410), PI],
	"slot_2": [Vector2(1884, 228), -PI / 2], "table2": [Vector2(1922, 406), 0.0],
}
const ROOM_NODES := {
	"door": Vector2(1964, 268), "aisle_n": Vector2(1930, 252), "aisle_nw": Vector2(1868, 250),
	"aisle_e": Vector2(1962, 320), "aisle_se": Vector2(1960, 380), "aisle_s": Vector2(1903, 392),
	"aisle_sw": Vector2(1846, 381), "t1_west": Vector2(1822, 388), "t1_east": Vector2(1870, 388),
}
## Legs: node - node, and node - spot (a spot is reached from one node).
const ROOM_LINKS := [["door", "aisle_n"], ["door", "aisle_e"], ["aisle_n", "aisle_nw"], ["aisle_e", "aisle_se"],
	["aisle_se", "aisle_s"], ["aisle_s", "aisle_sw"], ["aisle_sw", "t1_west"], ["aisle_sw", "t1_east"],
	["aisle_n", "rail_stan"], ["aisle_n", "watch_ne"], ["aisle_e", "rail_east"], ["aisle_nw", "slot_0"],
	["aisle_nw", "slot_2"], ["aisle_sw", "rail_edna"], ["t1_west", "sideboard"], ["t1_west", "table1_l"],
	["t1_east", "table1_r"], ["aisle_s", "table2"]]


## Where the wheel turns in the table (its bowl at the table's left end).
static func wheel_centre() -> Vector2:
	return WHEEL_TABLE + Vector2(-64.0 + 58.0 * 128.0 / 288.0, 0.0)


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


## M011: the Dock & Freight Workers' hall, Local 9, at the corner of Wharf
## Street and Front Street where the yards begin: the door off Wharf Street
## into the hall - benches for the men waiting on the shape-up, the
## noticeboard, a stove; through a doorway the business agent's office - his
## desk under a green lamp, filing cabinets, the safe, a map of the docks and
## the yards, the local's charter. The lights burn late. A place to look
## round, not a job: nobody here has work for Danny.
static func union_hall(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("union_hall", RiversideWard.UNION_HALL)
	p.marker = "ui/marker_union"
	p.building = d.building_named(RiversideWard.UNION_HALL)
	p.building_rect = d.buildings[p.building].rect  # x 2831..3169, y 2370..2700
	p.room = Rect2(2831, 2440, 338, 260)  # the front of the house; the stairs and the meeting hall above stay shut
	p.floor = "interiors/floor_boards"
	p.doors = [{"side": Vector2.RIGHT, "at": 2560.0, "width": 28.0}]  # off Wharf Street
	p.partitions = [{"a": Vector2(3000, 2440), "b": Vector2(3000, 2700), "door_at": 2648.0, "door_width": 28.0}]
	p.furniture = [
		# the hall
		{"kind": "interiors/bench", "pos": Vector2(3058, 2458), "box": Vector2(70, 14)},
		{"kind": "interiors/noticeboard", "pos": Vector2(3124, 2451)},
		{"kind": "interiors/bench", "pos": Vector2(3154, 2660), "rot": PI / 2, "box": Vector2(70, 14)},
		{"kind": "interiors/potbelly", "pos": Vector2(3024, 2560), "radius": 11.0},
		{"kind": "interiors/spittoon", "pos": Vector2(3046, 2600)},
		{"kind": "interiors/coat_rack", "pos": Vector2(3156, 2486), "radius": 6.0},
		# the business agent's office
		{"kind": "interiors/desk", "pos": Vector2(2915, 2522), "box": Vector2(70, 32)},
		{"kind": "interiors/chair", "pos": Vector2(2915, 2496)},
		{"kind": "interiors/chair", "pos": Vector2(2898, 2554), "rot": PI},
		{"kind": "interiors/chair", "pos": Vector2(2934, 2554), "rot": PI},
		{"kind": "interiors/filing_cabinet", "pos": Vector2(2848, 2510), "rot": -PI / 2, "box": Vector2(22, 18)},
		{"kind": "interiors/filing_cabinet", "pos": Vector2(2848, 2534), "rot": -PI / 2, "box": Vector2(22, 18)},
		{"kind": "interiors/filing_cabinet", "pos": Vector2(2848, 2558), "rot": -PI / 2, "box": Vector2(22, 18)},
		{"kind": "interiors/safe", "pos": Vector2(2852, 2676), "box": Vector2(18, 18)},
		{"kind": "interiors/wall_map", "pos": Vector2(2905, 2450)},
		{"kind": "interiors/charter", "pos": Vector2(2968, 2450)},
		{"kind": "interiors/smoke", "pos": Vector2(3080, 2520), "z": 11},
	]
	p.lamps = [
		{"pos": Vector2(2915, 2522), "color": Color(0.9, 1.0, 0.76), "energy": 1.0, "radius": 120.0},  # the green desk lamp
		{"pos": Vector2(3085, 2560), "color": Color(1.0, 0.78, 0.52), "energy": 0.85, "radius": 150.0},  # the hall's bulb
		{"pos": Vector2(3024, 2560), "color": Color(1.0, 0.55, 0.3), "energy": 0.35, "radius": 50.0},  # the stove's glow
	]
	p.people = [
		{"id": "agent", "name": "", "look": "characters/clerk", "pos": Vector2(2915, 2496), "facing": PI / 2},
		{"id": "docker_a", "name": "", "look": "characters/worker", "pos": Vector2(3046, 2476), "facing": PI / 2},
		{"id": "docker_b", "name": "", "look": "characters/worker", "pos": Vector2(3112, 2478), "facing": -PI / 2},
	]
	p.spots = [
		{"id": "union_board", "pos": Vector2(3134, 2486), "radius": 18.0, "prompt": "Read the noticeboard"},
	]
	return p


## M012: Alderman Patrick J. Quilty's ward office on Marlowe Avenue, between
## the corner shop and the flats: one modest room behind the gold letters on
## the glass - his desk under a green lamp with the visitors' chairs before it,
## the ward map, a filing cabinet, the flag, a stove, a coat rack and the
## handbills from the last campaign stacked in a corner. Office hours are ten
## till four; the alderman is often in long after.
static func quilty_office(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("quilty_office", RiversideWard.QUILTY)
	p.building = d.building_named(RiversideWard.QUILTY)
	p.building_rect = d.buildings[p.building].rect  # x 391..581, y 168..439 (the front on Marlowe Avenue)
	p.room = Rect2(391, 289, 190, 150)
	p.floor = "interiors/floor_boards"
	p.doors = [{"side": Vector2.DOWN, "at": 486.0, "width": 28.0}]
	p.furniture = [
		{"kind": "interiors/wall_map", "pos": Vector2(440, 297)},
		{"kind": "interiors/photo_wall", "pos": Vector2(530, 297)},
		{"kind": "interiors/desk", "pos": Vector2(486, 334), "box": Vector2(70, 32)},
		{"kind": "interiors/chair", "pos": Vector2(486, 310)},
		{"kind": "interiors/chair", "pos": Vector2(470, 366), "rot": PI},
		{"kind": "interiors/chair", "pos": Vector2(502, 366), "rot": PI},
		{"kind": "interiors/flag_stand", "pos": Vector2(410, 312), "radius": 6.0},
		{"kind": "interiors/filing_cabinet", "pos": Vector2(570, 340), "rot": PI / 2, "box": Vector2(22, 18)},
		{"kind": "interiors/potbelly", "pos": Vector2(412, 408), "radius": 11.0},
		{"kind": "interiors/crate_stack", "pos": Vector2(558, 408), "box": Vector2(28, 28)},  # last campaign's handbills
		{"kind": "interiors/coat_rack", "pos": Vector2(440, 426), "radius": 6.0},
	]
	p.lamps = [
		{"pos": Vector2(486, 334), "color": Color(0.9, 1.0, 0.76), "energy": 1.0, "radius": 110.0},  # the green desk lamp
		{"pos": Vector2(486, 395), "color": Color(1.0, 0.78, 0.52), "energy": 0.55, "radius": 110.0},
		{"pos": Vector2(412, 408), "color": Color(1.0, 0.55, 0.3), "energy": 0.3, "radius": 45.0},
	]
	p.people = [
		{"id": "quilty", "name": "Ald. Quilty", "look": "characters/alderman", "pos": Vector2(486, 310), "facing": PI / 2},
	]
	p.spots = [
		{"id": "quilty", "pos": Vector2(486, 376), "radius": 20.0, "prompt": "Talk to Alderman Quilty"},
		{"id": "quilty_map", "pos": Vector2(440, 318), "radius": 16.0, "prompt": "Look at the ward map"},
	]
	return p
