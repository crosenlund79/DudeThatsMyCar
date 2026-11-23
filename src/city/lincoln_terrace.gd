class_name LincolnTerrace
extends DistrictBuilder
## M015: Lincoln Terrace - the swells' quarter north of the railroad, through
## the Wharf Street underpass from the Riverside Ward. Drawn up in its own
## coordinates and placed at ORIGIN (its streets at the yards' and the ward's
## x: Dearing, Astor and Wharf Street). Wide, clean and bright: Lincoln
## Boulevard with its tree-lined parkways and the mansions behind their
## railings and gardens; the Belvedere Hotel's Art Deco tower with its lit
## canopy and doorman; the Paradise Ballroom's dome and starry marquee on
## Lake Street, under the tracks, where the nightlife is; the old water tower
## in its little plaza; the river promenade along the east side, with benches.
## Fewer people, all of them better dressed; a copper on point duty. Closed by
## Lincoln Park's railings (north), barricades (west) and the river (east).

const ORIGIN := Vector2(-1700, -4000)
const WIDTH := 6600.0
const HEIGHT := 2700.0
const DEARING := 1700.0
const ASTOR := 3350.0
const WHARF := 5000.0
const OAK := 700.0
const BLVD := 1500.0
const LAKE := 2560.0
const HALF := 85.0
const AVENUE_HALF := 115.0
const SW := 46.0
const RIVER_X := 5600.0
const FAR_BANK_X := 6100.0
const WEST_EDGE := 900.0
const PARK_EDGE := 520.0
const PROMENADE := 5480.0

const BELVEDERE := "The Belvedere Hotel"
const PARADISE := "Paradise Ballroom"
const TOWER := "The Old Water Tower"


static func create() -> DistrictLayout:
	var w := LincolnTerrace.new()
	w._build()
	return w.d.shift(ORIGIN)


func _build() -> void:
	d.id = "terrace"
	d.name = "Lincoln Terrace"
	d.bounds = Rect2(0, 0, WIDTH, HEIGHT)
	d.play_area = Rect2(WEST_EDGE, PARK_EDGE, RIVER_X - WEST_EDGE, HEIGHT - PARK_EDGE)
	d.lamp_energy = 1.15  # bright: the city spends its money here
	d.grime_level = 0.12
	_streets()
	_blocks()
	_river()
	_park()
	_rows()
	_landmarks()
	_furnish_roofs()
	_roof_landmarks()
	_signs()
	_street_furniture()
	_lamps()
	_ground_details()
	_people_and_cars()
	_incident_spots()
	TerraceInteriors.add_to(d)  # M015.12: the Belvedere's lobby, the Paradise Ballroom
	_clear_doorways()
	# the way south, under the tracks, into the Riverside Ward
	d.exits.append({"to": "riverside", "rect": Rect2(WHARF - HALF - SW, HEIGHT - 6, (HALF + SW) * 2.0, 6)})


func _streets() -> void:
	for s in [["Dearing Street", DEARING], ["Astor Street", ASTOR], ["Wharf Street", WHARF]]:
		d.streets.append({"name": s[0], "avenue": false, "rect": Rect2(s[1] - HALF, PARK_EDGE, HALF * 2, HEIGHT - PARK_EDGE)})
	for s in [["Oak Street", OAK, HALF, false], ["Lincoln Boulevard", BLVD, AVENUE_HALF, true], ["Lake Street", LAKE, HALF, false]]:
		d.streets.append({"name": s[0], "avenue": s[3], "rect": Rect2(0, s[1] - s[2], RIVER_X, s[2] * 2)})


const COLS := [[0.0, DEARING - HALF], [DEARING + HALF, ASTOR - HALF], [ASTOR + HALF, WHARF - HALF], [WHARF + HALF, PROMENADE]]
const ROWS := [[OAK + HALF, BLVD - AVENUE_HALF], [BLVD + AVENUE_HALF, LAKE - HALF]]


func _blocks() -> void:
	for c in COLS:
		for r in ROWS:
			d.blocks.append(Rect2(c[0], r[0], c[1] - c[0], r[1] - r[0]))
	# Lake Street's south pavement against the railroad's retaining wall, the park's edge on Oak Street
	d.lots.append({"rect": Rect2(0, LAKE + HALF, RIVER_X, HEIGHT - LAKE - HALF), "kind": "concrete"})
	d.lots.append({"rect": Rect2(0, OAK - HALF - SW, RIVER_X, SW), "kind": "concrete"})
	d.alleys.append({"name": "Alley behind Lincoln Boulevard", "rect": Rect2(COLS[2][0] + SW, 1140.0 - 33.0, 4205.0 - COLS[2][0] - SW, 66.0)})
	d.alleys.append({"name": "Alley behind Lake Street", "rect": Rect2(COLS[1][0], 2050.0 - 33.0, COLS[1][1] - COLS[1][0], 66.0)})


func _river() -> void:
	d.water.append(Rect2(RIVER_X, 0, FAR_BANK_X - RIVER_X, HEIGHT))
	d.quays.append([Vector2(RIVER_X, 0), Vector2(RIVER_X, HEIGHT)])
	d.lots.append({"rect": Rect2(FAR_BANK_X, 0, WIDTH - FAR_BANK_X, HEIGHT), "kind": "concrete"})
	_column(FAR_BANK_X + 40, WIDTH, 0, [[900, 9, "deco", "gravel"], [700, 6, "civic", "gravel"], [1100, 7, "greystone", "tar"]])
	# the river promenade along the west bank, its benches looking over the water
	d.lots.append({"rect": Rect2(PROMENADE, PARK_EDGE, RIVER_X - PROMENADE, LAKE - HALF - PARK_EDGE), "kind": "concrete"})
	for y in [900.0, 1300.0, 1800.0, 2200.0]:
		_prop("interiors/bench", Vector2(RIVER_X - 30.0, y), PI / 2, Vector2(66, 14))
	d.fences.append([Vector2(RIVER_X - 6.0, PARK_EDGE), Vector2(RIVER_X - 6.0, LAKE - HALF), "iron"])


## Lincoln Park beyond Oak Street (out of reach behind its railings): lawns and trees.
func _park() -> void:
	d.lots.append({"rect": Rect2(0, 0, RIVER_X, OAK - HALF - SW), "kind": "grass"})
	d.fences.append([Vector2(WEST_EDGE, OAK - HALF - SW + 4.0), Vector2(RIVER_X, OAK - HALF - SW + 4.0), "iron"])
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 1932016
	for i in 40:
		_prop("props/tree", Vector2(rnd.randf_range(200, RIVER_X - 100), rnd.randf_range(80, OAK - HALF - SW - 60)),
			rnd.randf_range(0, 3), 0.0, 64.0)
	d.landmarks.append({"pos": Vector2(3000, 300), "label": "Lincoln Park"})


func _rows() -> void:
	var oak_s := OAK + HALF + SW
	var blvd_n := BLVD - AVENUE_HALF - SW
	var blvd_s := BLVD + AVENUE_HALF + SW
	var lake_n := LAKE - HALF - SW
	# (every row starts behind the side street's pavement: a block's x + SW)
	var c1: float = COLS[1][0] + SW
	var c2: float = COLS[2][0] + SW
	var c3: float = COLS[3][0] + SW
	# west of Dearing (past the barricades): flats of the better sort
	_row(0, oak_s, blvd_n, [[1569, 5, "greystone", "gravel"]])
	_row(0, blvd_s, lake_n, [[1569, 4, "townhouse", "tar"]])
	# Oak Street, facing the park: grand apartment houses
	_row(c1, oak_s, 960.0, [[560, 7, "greystone", "gravel", {"name": "The Oak Park Arms"}], [24], [804, 6, "deco", "gravel"]])
	_row(c2, oak_s, 1107.0, [[560, 8, "greystone", "gravel"], [24], [160, 6, "townhouse", "gravel"]])
	# Lincoln Boulevard, north side between Astor and the Belvedere: apartment houses
	_row(c2, blvd_n, 1173.0, [[400, 6, "greystone", "gravel", {"name": "The Drake Arms"}], [24], [300, 7, "deco", "gravel"]])
	_row(c3, oak_s, 1300.0, [[349, 9, "deco", "gravel", {"name": "Riverside Towers"}]])
	# Lincoln Boulevard, north side: the mansions (_landmarks) and, at Wharf, the Belvedere (_landmarks)
	# Lincoln Boulevard, south side: more mansions, the water tower's plaza at Astor
	_row(c1, blvd_s, 2017.0, [[620, 4, "civic", "gravel", {"name": "Terrace Public Library"}], [24], [744, 3, "townhouse", "tar"]])
	_row(c2 + 354.0, blvd_s, 2017.0, [[1034, 4, "townhouse", "tar", {"name": "The Calumet Club"}]])
	_row(c3, blvd_s, 2017.0, [[349, 5, "greystone", "gravel", {"name": "Wharf Street Apartments"}]])
	# Lake Street, north side: the nightlife by the tracks - the Paradise and its neighbours
	_row(c1, lake_n, 2083.0, [[460, 3, "brick_brown", "tar", {"awning": "red", "name": "Chez Antoine"}],
		[24], [420, 3, "club", "tar", {"name": "The Silver Slipper"}], [24], [460, 3, "brick_brown", "tar", {"awning": "green"}]])
	_row(c2, lake_n, 2083.0, [[600, 2, "garage", "tin", {"name": "Terrace Motor Livery"}], [188], [600, 3, "civic", "tar",
		{"name": PARADISE, "skylights": 0}]])
	_row(c3, lake_n, 2083.0, [[349, 3, "brick_brown", "tar", {"awning": "red", "name": "Lakeside Florist"}]])


## The mansions behind their gardens and railings, the Belvedere Hotel's tower
## at Wharf and the Boulevard, and the old water tower in its plaza.
const MANSIONS := ["Ashford House", "Whitcombe House", "Van Doren House"]


func _landmarks() -> void:
	var blvd_n := BLVD - AVENUE_HALF - SW
	# the mansions: set back behind a garden and a railing with a gate, between Dearing and Astor
	var x: float = COLS[1][0] + SW
	for k in MANSIONS.size():
		var wdt := 440.0
		var house := Rect2(x + 30.0, 990.0, wdt - 60.0, blvd_n - 120.0 - 990.0)
		_building(house, 3, "townhouse", "tar", Vector2.DOWN, {"name": MANSIONS[k], "show_address": true})
		var garden := Rect2(x, house.end.y, wdt, blvd_n - house.end.y)
		d.lots.append({"rect": garden, "kind": "grass"})
		var gate := garden.get_center().x
		d.fences.append([Vector2(x, blvd_n - 4.0), Vector2(gate - 24.0, blvd_n - 4.0), "iron"])
		d.fences.append([Vector2(gate + 24.0, blvd_n - 4.0), Vector2(x + wdt, blvd_n - 4.0), "iron"])
		d.lots.append({"rect": Rect2(gate - 20.0, house.end.y, 40.0, garden.size.y), "kind": "concrete"})
		for t in [Vector2(x + 60.0, house.end.y + 50.0), Vector2(x + wdt - 60.0, house.end.y + 50.0)]:
			_prop("props/tree", t, float(k), 0.0, 64.0)
		_prop("props/flowerbed", Vector2(gate, house.end.y + 26.0), 0.0)
		d.lamps.append(Vector2(gate - 34.0, blvd_n - 10.0))
		d.lamps.append(Vector2(gate + 34.0, blvd_n - 10.0))
		d.locked_doors.append({"pos": Vector2(gate, blvd_n - 8.0), "prompt": "Try the gate",
			"text": "Chained, and a butler's lamp in the window. Money sleeps behind iron here."})
		x += wdt + 30.0
	# the Belvedere: eleven storeys of limestone at the corner of Wharf and the Boulevard
	var hotel := Rect2(COLS[2][1] - SW - 640.0, OAK + HALF + SW, 640.0, blvd_n - (OAK + HALF + SW))
	_building(hotel, 11, "deco", "gravel", Vector2.DOWN, {"name": BELVEDERE})
	# the water tower: a castellated stone shaft in a little paved plaza at Astor and the Boulevard
	var plaza := Rect2(ASTOR + HALF + SW, BLVD + AVENUE_HALF + SW, 340.0, 300.0)
	d.lots.append({"rect": plaza, "kind": "concrete"})
	var mid := plaza.get_center()
	_building(Rect2(mid - Vector2(44, 44), Vector2(88, 88)), 9, "stone", "tar", Vector2.ZERO, {"name": TOWER, "bare": true})
	for p in [Vector2(-120, -100), Vector2(120, -100), Vector2(-120, 100), Vector2(120, 100)]:
		d.lamps.append(mid + p)
	for p in [Vector2(-140, 0), Vector2(140, 0)]:
		_prop("interiors/bench", mid + p, PI / 2 if p.x < 0 else -PI / 2, Vector2(66, 14))
	d.landmarks.append({"pos": mid + Vector2(0, 90), "label": TOWER})


func _roof_landmarks() -> void:
	for b in d.buildings:
		var r: Rect2 = b.rect
		if b.name == TOWER:
			b.props.append({"kind": "roof/turret", "pos": r.get_center(), "rot": 0.0})
		elif b.name == PARADISE:
			b.props = b.props.filter(func(p: Dictionary) -> bool: return (p.pos as Vector2).distance_to(r.get_center()) > 80.0)
			b.props.append({"kind": "roof/dome", "pos": r.get_center(), "rot": 0.0})


func _signs() -> void:
	_sign(BELVEDERE, "signs/belvedere", 0.0, 60.0)
	_sign(PARADISE, "signs/paradise", 0.0, 46.0)
	for b in d.buildings:
		if b.name != "":
			d.landmarks.append({"pos": (b.rect as Rect2).get_center(), "label": b.name})


func _street_furniture() -> void:
	for b in d.buildings:
		var front: Vector2 = b.front
		if front == Vector2.ZERO:
			continue
		var r: Rect2 = b.rect
		var edge_mid := r.get_center() + front * absf(front.dot(r.size)) * 0.5
		var rot := (-front).angle() + PI / 2
		var along := absf(front.orthogonal().dot(r.size))
		if b.opts.has("awning"):
			var n := clampi(int(along / 150.0), 1, 3)
			for k in n:
				var t := (k + 0.5) / n - 0.5
				_prop("props/awning_" + b.opts.awning, edge_mid + front.orthogonal() * t * along + front * 18.0, rot, 0.0, 34.0)
		if b.name == BELVEDERE:
			_prop("props/porte_cochere", edge_mid + front * 40.0, rot, 0.0, 44.0)
		elif b.name == PARADISE:
			_prop("props/marquee_paradise", edge_mid + front * 26.0, rot, 0.0, 32.0)
		elif b.name == "The Silver Slipper":
			_prop("props/awning_red", edge_mid + front * 18.0, rot, 0.0, 34.0)
	# the Boulevard's parkways: trees between the kerb and the pavement
	for side in [-1.0, 1.0]:
		var y: float = BLVD + side * (AVENUE_HALF + 14.0)
		var x := WEST_EDGE + 200.0
		while x < PROMENADE - 100.0:
			if [DEARING, ASTOR, WHARF].all(func(c: float) -> bool: return absf(x - c) > HALF + 90.0):
				_prop("props/tree", Vector2(x, y), x * 0.01, 0.0, 64.0)
			x += 220.0
	for p in [Vector2(DEARING + 100, BLVD - 150), Vector2(ASTOR - 100, LAKE - 120), Vector2(WHARF + 100, OAK + 120)]:
		_prop("props/hydrant", p, 0.0, 6.0)
	_prop("props/call_box", Vector2(WHARF - 100, BLVD + 150), 0.0, 8.0)
	_prop("props/mailbox", Vector2(ASTOR + 120, BLVD - 150), 0.0, Vector2(14, 14))
	for y in [OAK, BLVD, LAKE]:
		_barricade_line(Vector2(WEST_EDGE, y), Vector2.DOWN, 4 if y == BLVD else 3)


func _lamps() -> void:
	var cross_x := [DEARING, ASTOR, WHARF]
	for s in [[OAK, HALF, 300.0], [BLVD, AVENUE_HALF, 220.0], [LAKE, HALF, 240.0]]:
		for side in [-1.0, 1.0]:
			var y: float = s[0] + side * (s[1] + 10.0)
			var x: float = WEST_EDGE + 120.0 + (0.0 if side < 0 else s[2] * 0.5)
			while x < PROMENADE - 40:
				if cross_x.all(func(c: float) -> bool: return absf(x - c) > 150.0) and not d.is_in_building(Vector2(x, y), 4.0):
					d.lamps.append(Vector2(x, y))
				x += s[2]
	for c in cross_x:
		for side in [-1.0, 1.0]:
			var x2: float = c + side * (HALF + 10.0)
			var y2: float = PARK_EDGE + 140.0
			while y2 < HEIGHT - 40:
				var clear := [OAK, BLVD, LAKE].all(func(c2: float) -> bool: return absf(y2 - c2) > 170.0)
				if clear and not d.is_in_building(Vector2(x2, y2), 4.0):
					d.lamps.append(Vector2(x2, y2))
				y2 += 300.0
	for y in range(700, 2400, 300):  # along the promenade
		d.lamps.append(Vector2(RIVER_X - 50.0, y))


func _ground_details() -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 1932017
	for p in [Vector2(2400, BLVD), Vector2(WHARF, 2000), Vector2(ASTOR, 1100), Vector2(4200, LAKE)]:
		d.decals.append({"kind": "decals/manhole", "pos": p, "rot": 0.0, "scale": 1.0})
	for p in [Vector2(4200, LAKE)]:
		d.steam_vents.append(p)
	for i in 6:
		d.decals.append({"kind": "decals/puddle", "pos": Vector2(rnd.randf_range(1200, 5300), [OAK, BLVD, LAKE][i % 3] + rnd.randf_range(-50, 50)),
			"rot": rnd.randf_range(-0.4, 0.4), "scale": rnd.randf_range(0.7, 1.1)})


func _people_and_cars() -> void:
	var blvd_n := BLVD - AVENUE_HALF - 23.0
	var blvd_s := BLVD + AVENUE_HALF + 23.0
	var lake_n := LAKE - HALF - 23.0
	d.walk_routes = [
		PackedVector2Array([Vector2(1200, blvd_s), Vector2(ASTOR - HALF - 30.0, blvd_s)]),  # the Boulevard, south side
		PackedVector2Array([Vector2(ASTOR + HALF + 30.0, blvd_n), Vector2(4230.0, blvd_n)]),  # the Boulevard, short of the Belvedere's door
		PackedVector2Array([Vector2(RIVER_X - 70.0, 800), Vector2(RIVER_X - 70.0, 2350)]),  # the promenade
		PackedVector2Array([Vector2(1900, lake_n), Vector2(3150, lake_n)]),  # Lake Street, the restaurants
	]
	d.walkers = [
		{"look": "characters/lady", "route": 0, "at": 0.3},
		{"look": "characters/patron_man", "route": 1, "at": 0.4},
		{"look": "characters/patron_woman", "route": 2, "at": 0.5},
		{"look": "characters/patron_man", "route": 3, "at": 0.6},
	]
	var hotel_front := Vector2(WHARF - HALF - SW - 320.0, BLVD - AVENUE_HALF - SW)
	d.locals = [
		# the Belvedere's doorman under the canopy, all night
		{"look": "characters/clerk", "kind": "stand", "pos": hotel_front + Vector2(-46, 20), "face": PI * 0.5,
			"lines": ["Good evening, sir. Taxi?", "The Starlight Room is on the twelfth floor, sir.", "No loitering, please."]},
		# the Paradise's crowd on Lake Street
		{"look": "characters/patron_woman", "kind": "stand", "pos": Vector2(4560, lake_n + 4.0), "face": 0.3, "hours": [21 * 60, 26 * 60],
			"group": "paradise", "lines": ["The band's from New York, they say.", "Did you see her dress? Paris, darling. Paris, Indiana."]},
		{"look": "characters/patron_man", "kind": "stand", "pos": Vector2(4586, lake_n - 2.0), "face": 2.9, "hours": [21 * 60, 26 * 60],
			"group": "paradise", "lines": ["One more foxtrot and I'm done for.", "The trains rattle the chandeliers. Adds atmosphere."]},
		{"look": "characters/lady", "kind": "stand", "pos": Vector2(4574, lake_n + 14.0), "face": -1.8, "hours": [22 * 60, 26 * 60],
			"group": "paradise", "lines": ["Who's that? He looks like trouble.", "Lake Street after midnight. Isn't it thrilling?"]},
		# a couple on the promenade
		{"look": "characters/patron_man", "kind": "stroll", "route": 2, "at": 0.3, "hours": [20 * 60, 25 * 60],
			"lines": ["Look at the lights on the water.", "Your father needn't know."]},
		{"look": "characters/patron_woman", "kind": "stroll", "route": 2, "at": 0.3, "hours": [20 * 60, 25 * 60], "with": 4},
		# a chauffeur waiting by the Calumet Club
		{"look": "characters/worker", "kind": "stand", "pos": Vector2(4300, blvd_s + 6.0), "face": -PI * 0.5, "hours": [20 * 60, 26 * 60],
			"lines": ["The senator likes his whisky and his privacy.", "I just drive, mister."]},
	]
	var lane := 28.0
	var e := BLVD + 45.0
	var w := BLVD - 45.0
	d.drive_loops = [
		# along the Boulevard and back by Lake Street: east on the Boulevard, south on Wharf, west on Lake, north on Astor
		PackedVector2Array([Vector2(ASTOR + lane, e), Vector2(WHARF - lane, e), Vector2(WHARF - lane, LAKE - lane), Vector2(ASTOR + lane, LAKE - lane)]),
		# west on the Boulevard, north on Dearing, east on Oak, south on Astor
		PackedVector2Array([Vector2(ASTOR - lane, w), Vector2(DEARING + lane, w), Vector2(DEARING + lane, OAK + lane), Vector2(ASTOR - lane, OAK + lane)]),
	]
	d.traffic = [
		{"type": "coupe", "paint": 0, "loop": 0, "segment": 0, "at": 0.3},
		{"type": "taxi", "paint": 0, "loop": 0, "segment": 2, "at": 0.6},
		{"type": "sedan", "paint": 1, "loop": 1, "segment": 0, "at": 0.4},
	]
	for x in [DEARING, ASTOR, WHARF]:
		for s in [[OAK, HALF], [BLVD, AVENUE_HALF], [LAKE, HALF]]:
			d.junctions.append(Rect2(x - HALF, s[0] - s[1], HALF * 2.0, s[1] * 2.0))
	d.cars = [
		{"type": "coupe", "paint": 0, "pos": Vector2(4100, LAKE - 62), "rot": 0.0, "owner": "a gentleman at the Paradise"},
		{"type": "taxi", "paint": 0, "pos": Vector2(WHARF - 62.0, 1900), "rot": -PI / 2, "owner": "the Yellow Line cab company"},
		{"type": "sedan", "paint": 1, "pos": Vector2(2500, BLVD + 92), "rot": PI, "owner": "the Whitcombe household"},
	]
	d.police_beat = PackedVector2Array([Vector2(3800, blvd_s), Vector2(4500, blvd_s)])
	d.police_posts = [{"pos": Vector2(WHARF - HALF - 20.0, BLVD + AVENUE_HALF + 20.0), "face": Vector2(WHARF, BLVD),
		"from": 19 * 60 + 30, "until": 23 * 60, "line": "Easy, now. This is a good neighbourhood."}]
	d.spawn = Vector2(WHARF, 2300)


func _incident_spots() -> void:
	d.incident_spots = [
		{"id": "paradise_kerb", "kinds": ["argument"], "pos": Vector2(4300, LAKE - HALF - 23.0), "along": Vector2.RIGHT, "local": "",
			"place": "outside the Paradise"},
		{"id": "belvedere_kerb", "kinds": ["stop"], "pos": Vector2(3900, BLVD + AVENUE_HALF + 23.0), "along": Vector2.RIGHT, "local": "",
			"place": "across from the Belvedere"},
		{"id": "lake_alley", "kinds": ["exchange"], "pos": Vector2(2600, 2050), "along": Vector2.RIGHT, "local": "",
			"place": "the alley behind Lake Street"},
		{"id": "promenade", "kinds": ["exchange"], "pos": Vector2(RIVER_X - 70.0, 2350), "along": Vector2.DOWN, "local": "",
			"place": "on the promenade"},
	]
