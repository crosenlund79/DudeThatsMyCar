class_name RiverfrontYards
extends DistrictBuilder
## The Riverfront Yards (M008): the industrial riverfront south of the
## Riverside Ward, where the river carries on south past coal and freight
## docks. Drawn up in its own coordinates (its top-left corner at 0, 0) and
## placed at ORIGIN, straight below the ward: Dorsey, Kessler and Wharf Street
## run on south from the ward into it, Front Street runs along its top. Works
## and warehouses instead of shops and flats: the Great Lakes Tanning Co. and
## its smokestack, North Branch Freight's depot and loading bays, Brennan Coal
## & Ice on the river, a night lunch counter for the shift, and the railroad's
## sidings with boxcars behind a board fence. Sparse, dim lamps; few people.
## Closed by the railroad embankment (south), the river (east) and barricades
## (west), like the ward.

const ORIGIN := Vector2(-1700, 2700)
## Streets (local x of the north-south streets = the ward's + 1700).
const DORSEY := 1700.0
const KESSLER := 3350.0
const WHARF := 5000.0
const FRONT := 85.0
const FOUNDRY := 1300.0
const HALF := 85.0
const RIVER_X := 5600.0
const FAR_BANK_X := 6100.0
const WEST_EDGE := 900.0
const YARD_TOP := 2050.0
const EMBANKMENT_Y := 2450.0
const WIDTH := 6600.0
const HEIGHT := 2600.0
const COLS := [[0.0, 1615.0], [1785.0, 3265.0], [3435.0, 4915.0], [5085.0, 5600.0]]


static func create() -> DistrictLayout:
	var w := RiverfrontYards.new()
	w._build()
	return w.d.shift(ORIGIN)


func _build() -> void:
	d.id = "yards"
	d.name = "Riverfront Yards"
	d.bounds = Rect2(0, 0, WIDTH, HEIGHT)
	d.play_area = Rect2(WEST_EDGE, 0, RIVER_X - WEST_EDGE, EMBANKMENT_Y)
	d.lamp_energy = 0.78
	_streets()
	_blocks()
	_river()
	_works()
	_rail_yard()
	_outer()
	_furnish_roofs()
	_signs()
	_street_furniture()
	_lamps()
	_ground_details()
	_people_and_cars()
	_incident_spots()
	_contacts()
	# the ways north into the Riverside Ward (Dorsey Street is closed by the ward's own barricade)
	for x in [DORSEY, KESSLER, WHARF]:
		d.exits.append({"to": "riverside", "rect": Rect2(x - HALF - 46.0, 0, HALF * 2.0 + 92.0, 6)})


func _streets() -> void:
	for s in [["Dorsey Street", DORSEY], ["Kessler Street", KESSLER], ["Wharf Street", WHARF]]:
		d.streets.append({"name": s[0], "avenue": false, "rect": Rect2(s[1] - HALF, 0, HALF * 2, YARD_TOP)})
	d.streets.append({"name": "Front Street", "avenue": false, "rect": Rect2(0, FRONT - HALF, RIVER_X, HALF * 2)})
	d.streets.append({"name": "Foundry Street", "avenue": false, "rect": Rect2(0, FOUNDRY - HALF, RIVER_X, HALF * 2)})
	# granite setts on the yard approach and a spur line along Foundry Street to the coal dock
	d.cobbles.append(Rect2(WHARF - 60, FOUNDRY + HALF, 120, YARD_TOP - FOUNDRY - HALF))
	d.rails.append([Vector2(WEST_EDGE + 200, FOUNDRY - 18), Vector2(RIVER_X - 140, FOUNDRY - 18)])
	d.rails.append([Vector2(WEST_EDGE + 200, FOUNDRY + 18), Vector2(RIVER_X - 140, FOUNDRY + 18)])


func _blocks() -> void:
	for c in COLS:
		d.blocks.append(Rect2(c[0], FRONT + HALF, c[1] - c[0], FOUNDRY - HALF - FRONT - HALF))
		d.blocks.append(Rect2(c[0], FOUNDRY + HALF, c[1] - c[0], YARD_TOP - FOUNDRY - HALF))
	# a service lane behind the works in the middle blocks
	for c in [COLS[1], COLS[2]]:
		d.alleys.append({"name": "Lane behind the works", "rect": Rect2(c[0], 760 - 33, c[1] - c[0], 66)})


func _river() -> void:
	d.water.append(Rect2(RIVER_X, 0, FAR_BANK_X - RIVER_X, HEIGHT))
	d.quays.append([Vector2(RIVER_X, 0), Vector2(RIVER_X, HEIGHT)])
	d.lots.append({"rect": Rect2(FAR_BANK_X, 0, WIDTH - FAR_BANK_X, HEIGHT), "kind": "concrete"})
	# the far bank: more warehouses (out of reach)
	_column(FAR_BANK_X + 40, WIDTH, 0, [[700, 5, "warehouse", "tin"], [520, 4, "factory", "tin"], [640, 3, "brick_red", "tar"],
		[740, 5, "warehouse", "gravel"]])


func _works() -> void:
	# Between Dorsey and Kessler, along Front Street: the tannery, its yard and its stack.
	var front_y := FRONT + HALF + 46.0  # building line behind the sidewalk
	_building(Rect2(1831, front_y, 760, 470), 4, "factory", "tin", Vector2.UP, {"name": "Great Lakes Tanning Co.", "skylights": 4})
	_building(Rect2(2591, front_y, 628, 300), 3, "warehouse", "tin", Vector2.UP)
	d.lots.append({"rect": Rect2(2591, front_y + 300, 628, 727 - front_y - 300), "kind": "lot"})
	_building(Rect2(2620, 560, 46, 46), 8, "stack", "tar", Vector2.ZERO, {"name": "Tannery stack", "bare": true})
	d.smoke.append({"pos": Vector2(2643, 583), "height": 8 * DistrictLayout.STOREY + 26.0})
	d.fences.append([Vector2(2591, front_y + 300), Vector2(2591, 727)])
	d.fences.append([Vector2(3219, front_y + 300), Vector2(3219, 727)])
	# south of the lane: a cooperage and a boiler house facing Foundry Street
	_row(1831, FOUNDRY - HALF - 46.0, 793, [[420, 2, "warehouse", "tin"], [26], [380, 3, "factory", "gravel"], [24],
		[538, 2, "brick_brown", "tar", {"name": "Dutch's Night Lunch", "awning": "red", "depth": 140}]])
	# Between Kessler and Wharf: North Branch Freight's depot with its loading bays on Kessler.
	_building(Rect2(3481, front_y, 980, 420), 3, "warehouse", "tin", Vector2.UP, {"name": "North Branch Freight", "skylights": 4})
	d.lots.append({"rect": Rect2(4461, front_y, 408, 506), "kind": "concrete"})  # the loading yard
	_row(3481, FOUNDRY - HALF - 46.0, 793, [[520, 3, "warehouse", "tin"], [24], [430, 4, "factory", "tin"], [26], [388, 2, "brick_red", "tar"]])
	# Between Wharf and the river: Brennan Coal & Ice and its dock.
	_building(Rect2(5131, front_y, 330, 640), 4, "warehouse", "gravel", Vector2.LEFT, {"name": "Brennan Coal & Ice", "skylights": 3})
	d.lots.append({"rect": Rect2(5461, front_y, RIVER_X - 5461, 900), "kind": "concrete"})  # the coal dock apron
	_row(5131, FOUNDRY + HALF + 46.0, YARD_TOP - 46.0, [[420, 3, "factory", "tin"]])
	# South of Foundry Street, the other blocks: workshops and a pump house
	_row(1831, FOUNDRY + HALF + 46.0, YARD_TOP - 60.0, [[300, 2, "warehouse", "tin"], [24], [260, 2, "brick_red", "tar"],
		[400, 3, "factory", "gravel"], [28], [376, 2, "garage", "tin"]])
	_row(3481, FOUNDRY + HALF + 46.0, YARD_TOP - 60.0, [[460, 3, "warehouse", "tin"], [26], [300, 2, "brick_brown", "tar"],
		[24], [578, 3, "factory", "tin"]])


func _rail_yard() -> void:
	# The sidings: ballast ground, four tracks, boxcars waiting, a board fence with a gate on Wharf Street.
	d.lots.append({"rect": Rect2(WEST_EDGE, YARD_TOP, RIVER_X - WEST_EDGE, EMBANKMENT_Y - YARD_TOP), "kind": "lot"})
	for k in 4:
		var y := YARD_TOP + 90.0 + k * 85.0
		d.rails.append([Vector2(WEST_EDGE + 60, y - 20), Vector2(RIVER_X - 60, y - 20)])
		d.rails.append([Vector2(WEST_EDGE + 60, y + 20), Vector2(RIVER_X - 60, y + 20)])
	var cars := [[1300.0, 0], [1460.0, 0], [2400.0, 1], [2560.0, 1], [2720.0, 1], [3700.0, 2], [4300.0, 3], [4460.0, 3]]
	for c in cars:
		var y2 := YARD_TOP + 90.0 + float(c[1]) * 85.0
		_prop("props/boxcar", Vector2(c[0], y2), 0.0, Vector2(150, 44))
	d.fences.append([Vector2(WEST_EDGE, YARD_TOP), Vector2(WHARF - 70, YARD_TOP)])
	d.fences.append([Vector2(WHARF + 70, YARD_TOP), Vector2(RIVER_X, YARD_TOP)])
	# the railroad embankment closes the south
	_building(Rect2(0, EMBANKMENT_Y, RIVER_X, HEIGHT - EMBANKMENT_Y), 2, "stone", "ballast", Vector2.ZERO,
		{"name": "Railroad embankment", "bare": true})


func _outer() -> void:
	# West of Dorsey (the barricades close Front and Foundry Street at x 900): yards and sheds.
	_row(0, FRONT + HALF + 46.0, 700, [[600, 3, "warehouse", "tin"], [520, 4, "factory", "tin"], [449, 2, "brick_red", "tar"]])
	_row(0, FOUNDRY - HALF - 46.0, 730, [[820, 2, "brick_brown", "tar"], [749, 3, "warehouse", "gravel"]])
	_row(0, FOUNDRY + HALF + 46.0, YARD_TOP - 46.0, [[700, 3, "warehouse", "gravel"], [869, 2, "garage", "tin"]])


func _signs() -> void:
	_sign("Great Lakes Tanning Co.", "signs/tannery", 0.0, 60.0)
	_sign("North Branch Freight", "signs/freight", 0.0, 60.0)
	_sign("Brennan Coal & Ice", "signs/coal", 0.0, 120.0)
	_sign("Dutch's Night Lunch", "signs/lunch", 0.0, 34.0)
	for b in d.buildings:
		if b.name != "":
			d.landmarks.append({"pos": (b.rect as Rect2).get_center(), "label": b.name})
	d.landmarks = d.landmarks.filter(func(l: Dictionary) -> bool: return l.label != "Railroad embankment" and l.label != "Tannery stack")
	d.landmarks.append({"pos": Vector2(3000, YARD_TOP + 200), "label": "North Branch sidings"})


func _street_furniture() -> void:
	for b in d.buildings:
		var front: Vector2 = b.front
		if front == Vector2.ZERO or not b.opts.has("awning"):
			continue
		var r: Rect2 = b.rect
		var edge_mid := r.get_center() + front * absf(front.dot(r.size)) * 0.5
		_prop("props/awning_" + b.opts.awning, edge_mid + front * 18.0, (-front).angle() + PI / 2, 0.0, 34.0)
	# parked trucks at the loading bays and the coal dock (static, solid)
	for t in [[Vector2(4560, 330), PI / 2, "props/truck"], [Vector2(4700, 330), PI / 2, "props/truck_b"],
			[Vector2(4800, 560), PI / 2, "props/truck"], [Vector2(2700, 640), 0.0, "props/truck"]]:
		_prop(t[2], t[0], t[1], Vector2(104, 42))
	# crates, barrels and ash cans by the bays, the dock and the lunch counter
	for spec in [["props/crates", Vector2(4500, 610), 0.2, Vector2(40, 38)], ["props/crates", Vector2(5490, 720), -0.1, Vector2(40, 38)],
			["props/barrel", Vector2(5540, 760), 0.0, 9.0], ["props/barrel", Vector2(5560, 790), 0.0, 9.0],
			["props/crate", Vector2(4620, 640), 0.4, Vector2(24, 24)], ["props/barrel", Vector2(3240, 760), 0.0, 9.0],
			["props/trash_can", Vector2(2264, 1100), 0.0, 8.0], ["props/trash_can", Vector2(2264, 1080), 0.0, 8.0],
			["props/crates", Vector2(2000, 740), 0.3, Vector2(40, 38)]]:
		_prop(spec[0], spec[1], spec[2], spec[3])
	for p in [Vector2(DORSEY + 97, 197), Vector2(KESSLER + 97, 197), Vector2(WHARF - 97, FOUNDRY - HALF - 27), Vector2(DORSEY + 97, 1412)]:
		_prop("props/hydrant", p, 0.0, 6.0)
	_prop("props/call_box", Vector2(3470, 200), 0.0, 8.0)
	_barricade_line(Vector2(WEST_EDGE, FRONT), Vector2.DOWN, 3)
	_barricade_line(Vector2(WEST_EDGE, FOUNDRY), Vector2.DOWN, 3)


func _lamps() -> void:
	# fewer and dimmer than in the ward: a lamp at each corner and a few between
	for s in [[FRONT, 520.0], [FOUNDRY, 560.0]]:
		for side in ([1.0] if s[0] == FRONT else [-1.0, 1.0]):  # Front Street's north kerb is the ward's
			var y: float = s[0] + side * (HALF + 10.0)
			var x: float = WEST_EDGE + 150.0 + (0.0 if side < 0 else s[1] * 0.5)
			while x < RIVER_X - 100:
				if [DORSEY, KESSLER, WHARF].all(func(c: float) -> bool: return absf(x - c) > 150.0):
					d.lamps.append(Vector2(x, y))
				x += s[1]
	for c in [DORSEY, KESSLER, WHARF]:
		var y2 := 420.0
		while y2 < YARD_TOP - 100:
			if absf(y2 - FOUNDRY) > 160.0:
				d.lamps.append(Vector2(c + HALF + 10.0, y2))
			y2 += 620.0
	# far bank
	var yf := 150.0
	while yf < HEIGHT:
		d.lamps.append(Vector2(FAR_BANK_X + 20, yf))
		yf += 420.0
	# dim bulbs over the loading bays, the dock, the lunch counter and the yard gate
	for p in [Vector2(4470, 400), Vector2(4470, 600), Vector2(5475, 420), Vector2(5475, 760), Vector2(3060, 1170),
			Vector2(WHARF, YARD_TOP + 14), Vector2(2591, 600), Vector2(3800, 760)]:
		d.alley_lamps.append(p)


func _ground_details() -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 1932008
	for p in [Vector2(2500, 85), Vector2(4200, 85), Vector2(KESSLER, 600), Vector2(WHARF, 1600), Vector2(3000, FOUNDRY)]:
		d.decals.append({"kind": "decals/manhole", "pos": p, "rot": 0.0, "scale": 1.0})
	for p in [Vector2(4200, 85), Vector2(KESSLER, 600)]:
		d.steam_vents.append(p)
	for p in [Vector2(2000, 120), Vector2(3900, 60), Vector2(KESSLER + 30, 1000), Vector2(4700, 1290), Vector2(5300, 1260),
			Vector2(WHARF - 20, 1800), Vector2(4600, 450), Vector2(1900, 1320), Vector2(2900, 2200), Vector2(4100, 2300)]:
		d.decals.append({"kind": "decals/puddle", "pos": p, "rot": rnd.randf_range(-0.4, 0.4), "scale": rnd.randf_range(0.8, 1.4)})
	for p in [Vector2(4580, 420), Vector2(4750, 600), Vector2(5500, 600), Vector2(2650, 650), Vector2(3600, 1250), Vector2(5000, 2000)]:
		d.decals.append({"kind": "decals/oil", "pos": p, "rot": rnd.randf_range(-PI, PI), "scale": rnd.randf_range(0.9, 1.4)})
	for p in [Vector2(3080, 1180), Vector2(2200, 760), Vector2(5480, 700)]:
		d.decals.append({"kind": "decals/litter", "pos": p, "rot": rnd.randf_range(-PI, PI), "scale": 1.0})


## M009: Dutch out on the pavement in front of his night lunch (past the end of its
## awning, where he can be seen), his crate by the door.
func _contacts() -> void:
	d.contacts = [{"id": "dutch", "look": "characters/dutch", "pos": Vector2(3015, FOUNDRY - HALF - 26.0), "face": PI / 2}]
	d.errands = [{"id": "crate", "pos": Vector2(3090, FOUNDRY - HALF - 28.0)}]


## M009: where the yards' own small troubles happen; Dutch at the lunch counter notices.
func _incident_spots() -> void:
	d.incident_spots = [
		{"id": "depot_kerb", "kinds": ["argument"], "pos": Vector2(4300, 193), "along": Vector2.RIGHT, "local": "dutch",
			"place": "outside the freight depot"},
		{"id": "lunch_kerb", "kinds": ["argument"], "pos": Vector2(2860, 1192), "along": Vector2.RIGHT, "local": "dutch",
			"place": "outside Dutch's"},
		{"id": "works_lane", "kinds": ["exchange"], "pos": Vector2(2200, 760), "along": Vector2.RIGHT, "local": "",
			"place": "the lane behind the works"},
		{"id": "coal_dock", "kinds": ["exchange"], "pos": Vector2(5530, 860), "along": Vector2.DOWN, "local": "dutch",
			"place": "on the coal dock"},
		{"id": "front_stop", "kinds": ["stop"], "pos": Vector2(3900, 193), "along": Vector2.RIGHT, "local": "dutch",
			"place": "on Front Street"},
	]


func _people_and_cars() -> void:
	# a couple of night-shift men on Front Street, one by the lunch counter (M009: he turns
	# back short of Dutch, who stands out in front of it)
	d.walk_routes = [
		PackedVector2Array([Vector2(1900, 194), Vector2(3200, 194)]),
		PackedVector2Array([Vector2(2300, FOUNDRY - HALF - 24), Vector2(2915, FOUNDRY - HALF - 24)]),
	]
	d.walkers = [
		{"look": "characters/worker", "route": 0, "at": 0.3},
		{"look": "characters/worker", "route": 1, "at": 0.6},
	]
	var lane := 28.0
	d.drive_loops = [
		# round the freight block: east on Front, south on Wharf, west on Foundry, north on Kessler
		PackedVector2Array([Vector2(KESSLER + lane, FRONT + lane), Vector2(WHARF - lane, FRONT + lane),
			Vector2(WHARF - lane, FOUNDRY - lane), Vector2(KESSLER + lane, FOUNDRY - lane)]),
	]
	d.traffic = [{"type": "sedan", "paint": 1, "loop": 0, "segment": 1, "at": 0.4}]
	for x in [DORSEY, KESSLER, WHARF]:
		for y in [FRONT, FOUNDRY]:
			d.junctions.append(Rect2(x - HALF, y - HALF, HALF * 2.0, HALF * 2.0))
	d.cars = [
		{"type": "coupe", "paint": 1, "pos": Vector2(3000, 150), "rot": PI, "owner": "a clerk at North Branch Freight"},
		{"type": "sedan", "paint": 0, "pos": Vector2(2200, 150), "rot": 0.0, "owner": "the night foreman at the tannery"},
		# M009: Brennan's coal truck (drivable). M010: out of sight on the dock it was never found, so it
		# stands at the kerb of Wharf Street - the yards' road from the ward - outside Brennan Coal & Ice,
		# under a street lamp, nose north, clear of the traffic's lane
		{"type": "dump_truck", "paint": 0, "pos": Vector2(WHARF + 62.0, 470), "rot": -PI / 2, "owner": "Brennan Coal & Ice"},
	]
	# the beat cop walks Front Street by the Kessler Street corner, past the freight depot's gate
	d.police_beat = PackedVector2Array([Vector2(3460, 193), Vector2(3700, 193)])
	d.spawn = Vector2(3350, 600)
