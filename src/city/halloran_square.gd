class_name HalloranSquare
extends DistrictBuilder
## Halloran Square (M008): the residential and shopping quarter west of the
## Riverside Ward. Drawn up in its own coordinates and placed at ORIGIN, beside
## the ward: Calloway Street, Marlowe Avenue (with the streetcar line) and
## Pruitt Street run on west from the ward into it, and Ashby Street runs along
## its eastern edge. Dense flats of buff common brick and greystone, corner
## shops (Kowalski's bakery, Halloran Drugs), the Bijou picture house with its
## marquee on Marlowe Avenue, St. Brendan's church looking onto the square,
## and the square itself: gravel, plane trees, benches and lamps. Warm
## windows, quiet streets. Closed like the ward: the railroad embankment
## (north) and barricades (west and south).

const ORIGIN := Vector2(-4900, -1300)
## Streets (local y of the east-west streets = the ward's + 1300).
const CALLOWAY := 1000.0
const MARLOWE := 1900.0
const PRUITT := 2800.0
const HALLORAN_AVE := 1400.0
const GARRITY := 2250.0
const ASHBY := 3115.0
const HALF := 85.0
const AVENUE_HALF := 115.0
const EMBANKMENT_Y := 350.0
const WEST_EDGE := 400.0
const SOUTH_EDGE := 3450.0
const WIDTH := 3200.0
const HEIGHT := 4000.0
const SW := 46.0
const ALLEY := 66.0
const COLS := [[0.0, 1315.0], [1485.0, 2165.0], [2335.0, 3030.0]]
const ROWS := [[350.0, 915.0], [1085.0, 1785.0], [2015.0, 2715.0], [2885.0, 4000.0]]


static func create() -> DistrictLayout:
	var w := HalloranSquare.new()
	w._build()
	return w.d.shift(ORIGIN)


func _build() -> void:
	d.id = "halloran"
	d.name = "Halloran Square"
	d.bounds = Rect2(0, 0, WIDTH, HEIGHT)
	d.play_area = Rect2(WEST_EDGE, EMBANKMENT_Y, WIDTH - WEST_EDGE, SOUTH_EDGE - EMBANKMENT_Y)
	d.lamp_energy = 1.05
	d.grime_level = 0.4  # M010: a residential quarter, swept now and then
	_streets()
	_blocks_and_alleys()
	_square()
	_rows()
	_landmarks()
	_furnish_roofs()
	_signs()
	_street_furniture()
	_lamps()
	_ground_details()
	_people_and_cars()
	_incident_spots()
	_contacts()
	_cafe()
	_civic()
	HalloranInteriors.add_to(d)  # M012: the rooms behind its doors
	# the ways east into the Riverside Ward (Calloway Street ends at the ward's own barricade)
	d.exits.append({"to": "riverside", "rect": Rect2(WIDTH - 6, CALLOWAY - HALF - SW, 6, (HALF + SW) * 2.0)})
	d.exits.append({"to": "riverside", "rect": Rect2(WIDTH - 6, MARLOWE - AVENUE_HALF - SW, 6, (AVENUE_HALF + SW) * 2.0)})
	d.exits.append({"to": "riverside", "rect": Rect2(WIDTH - 6, PRUITT - HALF - SW, 6, (HALF + SW) * 2.0)})


func _streets() -> void:
	for s in [["Halloran Avenue", HALLORAN_AVE], ["Garrity Street", GARRITY], ["Ashby Street", ASHBY]]:
		d.streets.append({"name": s[0], "avenue": false, "rect": Rect2(s[1] - HALF, EMBANKMENT_Y, HALF * 2, HEIGHT - EMBANKMENT_Y)})
	for s in [["Calloway Street", CALLOWAY, HALF, false], ["Marlowe Avenue", MARLOWE, AVENUE_HALF, true],
			["Pruitt Street", PRUITT, HALF, false]]:
		d.streets.append({"name": s[0], "avenue": s[3], "rect": Rect2(0, s[1] - s[2], WIDTH, s[2] * 2)})
	# the streetcar line carries on west down the middle of Marlowe Avenue
	d.cobbles.append(Rect2(0, MARLOWE - 40, WIDTH, 80))
	d.rails.append([Vector2(0, MARLOWE - 20), Vector2(WIDTH, MARLOWE - 20)])
	d.rails.append([Vector2(0, MARLOWE + 20), Vector2(WIDTH, MARLOWE + 20)])


func _blocks_and_alleys() -> void:
	for c in COLS:
		for r in ROWS:
			d.blocks.append(Rect2(c[0], r[0], c[1] - c[0], r[1] - r[0]))
	# alleys behind the avenue's north side all along; south of it only east of the square
	# (St. Brendan's churchyard and the square take the rest)
	for c in COLS:
		d.alleys.append({"name": "Alley off Halloran Square", "rect": Rect2(c[0], 1435.0 - ALLEY / 2, c[1] - c[0], ALLEY)})
	d.alleys.append({"name": "Alley off Halloran Square", "rect": Rect2(COLS[2][0], 2365.0 - ALLEY / 2, COLS[2][1] - COLS[2][0], ALLEY)})


## The square: gravel walks under plane trees, benches, its own lamps.
## M010: made a small park, Halloran Park - four lawns between the paths with a
## gravel walk round them, flowerbeds and low hedges, a wrought-iron railing
## with a gate at each path's end, more benches (you can sit on them), and a
## footpath through it for the passers-by. The same place, the same trees.
const PARK_GATE := 40.0


func _square() -> void:
	var inner := Rect2(COLS[1][0] + SW, ROWS[2][0] + SW, COLS[1][1] - COLS[1][0] - SW * 2, ROWS[2][1] - ROWS[2][0] - SW * 2)
	d.lots.append({"rect": inner, "kind": "lot"})
	var mid := inner.get_center()
	var walk := 30.0
	var path := 22.0
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var x0: float = inner.position.x + walk if sx < 0 else mid.x + path + 12.0
			var x1: float = mid.x - path - 12.0 if sx < 0 else inner.end.x - walk
			var y0: float = inner.position.y + walk if sy < 0 else mid.y + path + 12.0
			var y1: float = mid.y - path - 12.0 if sy < 0 else inner.end.y - walk
			d.lots.append({"rect": Rect2(x0, y0, x1 - x0, y1 - y0), "kind": "grass"})
			_prop("props/flowerbed", mid + Vector2(sx * 98.0, sy * 98.0), sx * sy * 0.6)
			# low hedges along the lawns' outer sides
			var hx: float = x0 + 10.0 if sx < 0 else x1 - 10.0
			_prop("props/hedge", Vector2(hx, (y0 + y1) * 0.5), PI / 2)
	d.lots.append({"rect": Rect2(inner.position.x, mid.y - 22, inner.size.x, 44), "kind": "concrete"})
	d.lots.append({"rect": Rect2(mid.x - 22, inner.position.y, 44, inner.size.y), "kind": "concrete"})
	# the railing round it, a gate where each path comes out
	var c := [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]
	for i in 4:
		var a: Vector2 = c[i]
		var b: Vector2 = c[(i + 1) % 4]
		var gate: Vector2 = Vector2(mid.x, a.y) if absf(a.y - b.y) < 1.0 else Vector2(a.x, mid.y)
		var along := (b - a).normalized()
		d.fences.append([a, gate - along * PARK_GATE, "iron"])
		d.fences.append([gate + along * PARK_GATE, b, "iron"])
	for p in [Vector2(-48, 120), Vector2(48, -120)]:  # benches along the north-south path
		_prop("interiors/bench", mid + p, -PI / 2 if p.x < 0 else PI / 2, Vector2(66, 14))
	for p in [Vector2(-170, -190), Vector2(170, -190), Vector2(-170, 190), Vector2(170, 190), Vector2(-60, -230),
			Vector2(60, 230), Vector2(-230, 40), Vector2(230, -40)]:
		_prop("props/tree", mid + p, float(int(p.x * 3.0 + p.y) % 6) * 0.5, 0.0, 64.0)
	for p in [Vector2(-90, -40), Vector2(90, 40)]:
		_prop("interiors/bench", mid + p, 0.0 if p.x < 0 else PI, Vector2(66, 14))
	for p in [Vector2(-60, 60), Vector2(60, -60)]:
		d.lamps.append(mid + p)
	d.landmarks.append({"pos": mid, "label": "Halloran Park"})


func _rows() -> void:
	# North of Calloway Street, backing onto the embankment.
	_row(0, CALLOWAY - HALF - SW, 430, [[420, 4, "tenement", "tar"], [380, 3, "greystone", "gravel"], [24], [445, 4, "brick_red", "tar"]])
	_row(1531, CALLOWAY - HALF - SW, 430, [[300, 4, "tenement", "tar"], [288, 3, "brick_red", "tar"]])
	_row(2381, CALLOWAY - HALF - SW, 430, [[250, 3, "greystone", "tar"], [26], [327, 4, "tenement", "gravel"]])
	# Between Calloway and Marlowe: flats on Calloway, shops on the avenue.
	_row(0, CALLOWAY + HALF + SW, 1402, [[440, 3, "tenement", "tar"], [26], [380, 3, "greystone", "tar"], [423, 4, "tenement", "tar"]])
	_row(1531, CALLOWAY + HALF + SW, 1402, [[290, 3, "tenement", "gravel"], [298, 3, "brick_red", "tar"]])
	_row(2381, CALLOWAY + HALF + SW, 1402, [[300, 3, "tenement", "tar"], [24], [279, 3, "greystone", "gravel"]])
	_row(0, MARLOWE - AVENUE_HALF - SW, 1468, [[460, 3, "tenement", "tar"], [400, 2, "brick_brown", "tar", {"awning": "red", "name": "Rosie's Café"}],
		[409, 3, "brick_brown", "tar", {"awning": "green", "name": "Halloran Drugs"}]])
	_row(1531, MARLOWE - AVENUE_HALF - SW, 1468, [[300, 2, "brick_brown", "gravel", {"awning": "red", "name": DORAN}],
		[288, 3, "tenement", "tar"]])
	_row(2381, MARLOWE - AVENUE_HALF - SW, 1468, [[260, 3, "tenement", "tar"],
		[343, 3, "brick_brown", "tar", {"name": "The Bijou", "marquee": "props/marquee_bijou"}]])
	# Between Marlowe and Pruitt: shops on the avenue, flats on Pruitt (the square in the middle block).
	_row(2381, MARLOWE + AVENUE_HALF + SW, 2332, [[320, 2, "brick_brown", "tar", {"awning": "green", "name": "Kowalski Bakery"}],
		[24], [259, 3, "tenement", "gravel"]])
	_row(2381, PRUITT - HALF - SW, 2398, [[280, 3, "tenement", "tar"], [26], [297, 3, "greystone", "tar"]])
	_row(0, MARLOWE + AVENUE_HALF + SW, 2332, [[420, 3, "brick_red", "tar"],
		[470, 2, "brick_brown", "gravel", {"awning": "red", "name": REGULARS}]])
	_row(0, PRUITT - HALF - SW, 2398, [[460, 3, "tenement", "tar"], [24], [406, 3, "greystone", "gravel"]])
	# South of Pruitt Street (barricades close the side streets at y 3450).
	_row(0, PRUITT + HALF + SW, 3300, [[500, 3, "tenement", "tar"], [380, 3, "brick_red", "tar"], [389, 4, "greystone", "gravel"]])
	# M011: City Hall faces the park across Pruitt Street (see _civic)
	_row(1531, PRUITT + HALF + SW, 3300, [[588, 4, "civic", "gravel", {"name": CITY_HALL, "cupola": true, "skylights": 0}]])
	_row(2381, PRUITT + HALF + SW, 3300, [[300, 4, "tenement", "gravel"]])  # M011: and the mayor's house beside it (_civic)
	_row(0, HEIGHT, 3500, [[1269, 4, "brick_red", "tar"]])
	_row(1531, HEIGHT, 3500, [[588, 3, "greystone", "tar"]])
	_row(2381, HEIGHT, 3500, [[603, 4, "tenement", "tar"]])
	# the railroad embankment closes the north end of every street, as in the ward
	_building(Rect2(0, 0, WIDTH, EMBANKMENT_Y), 2, "stone", "ballast", Vector2.ZERO, {"name": "Railroad embankment", "bare": true})


func _landmarks() -> void:
	# St. Brendan's looks onto the square across Halloran Avenue, its tower on the corner.
	var x_front := HALLORAN_AVE - HALF - SW
	_building(Rect2(x_front - 70, MARLOWE + AVENUE_HALF + SW, 70, 70), 7, "greystone", "steel", Vector2.RIGHT,
		{"name": "St. Brendan's tower", "bare": true})
	_building(Rect2(x_front - 330, MARLOWE + AVENUE_HALF + SW + 70, 330, 300), 4, "greystone", "tar", Vector2.RIGHT,
		{"name": "St. Brendan's Church"})
	# the churchyard behind it and the forecourt round the tower
	d.lots.append({"rect": Rect2(x_front - 330, MARLOWE + AVENUE_HALF + SW + 370, 330, PRUITT - HALF - SW - (MARLOWE + AVENUE_HALF + SW + 370)), "kind": "lot"})
	d.lots.append({"rect": Rect2(890, MARLOWE + AVENUE_HALF + SW, x_front - 70 - 890, 70), "kind": "concrete"})


func _signs() -> void:
	_sign("The Bijou", "signs/bijou", 24.0, 40.0)
	_sign("Kowalski Bakery", "signs/bakery", 0.0, 34.0)
	_sign("Halloran Drugs", "signs/drugstore", 0.0, 34.0)
	_sign("Rosie's Café", "signs/cafe", 0.0, 34.0)  # M010
	_sign("St. Brendan's Church", "signs/church", 0.0, 60.0)
	_sign(CITY_HALL, "signs/city_hall", 0.0, 50.0)  # M011
	_sign(DORAN, "signs/doran", 0.0, 34.0)
	_sign(REGULARS, "signs/regulars", 0.0, 34.0)
	for b in d.buildings:
		if b.name != "" and not b.name in ["Railroad embankment", "St. Brendan's tower"]:
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
		if b.opts.has("marquee"):
			_prop(String(b.opts.marquee), edge_mid + front * 25.0, rot, 0.0, 30.0)
		elif b.opts.has("awning"):
			var n := clampi(int(along / 150.0), 1, 3)
			for k in n:
				var t := (k + 0.5) / n - 0.5
				_prop("props/awning_" + b.opts.awning, edge_mid + front.orthogonal() * t * along + front * 18.0, rot, 0.0, 34.0)
	for p in [Vector2(HALLORAN_AVE + 97, CALLOWAY + 118), Vector2(ASHBY - 97, MARLOWE - 148), Vector2(GARRITY + 97, PRUITT - 118),
			Vector2(HALLORAN_AVE - 97, PRUITT + 118), Vector2(GARRITY - 97, MARLOWE + 148)]:
		_prop("props/hydrant", p, 0.0, 6.0)
	_prop("props/mailbox", Vector2(GARRITY + 120, MARLOWE - 145), 0.0, Vector2(14, 14))
	_prop("props/newsstand", Vector2(ASHBY - 150, MARLOWE + 140), 0.0, Vector2(44, 28))
	_prop("props/call_box", Vector2(HALLORAN_AVE + 100, MARLOWE + 141), 0.0, 8.0)
	for p in [Vector2(600, 1446), Vector2(618, 1447), Vector2(2700, 2376), Vector2(2720, 2375), Vector2(1800, 1426)]:
		_prop("props/trash_can", p, 0.0, 8.0)
	for y in [CALLOWAY, MARLOWE, PRUITT]:
		_barricade_line(Vector2(WEST_EDGE, y), Vector2.DOWN, 4 if y == MARLOWE else 3)
	for x in [HALLORAN_AVE, GARRITY, ASHBY]:
		_barricade_line(Vector2(x, SOUTH_EDGE), Vector2.RIGHT, 3)


func _lamps() -> void:
	# warm and close together, as on Marlowe Avenue in the ward
	var cross_x := [HALLORAN_AVE, GARRITY, ASHBY]
	for s in [[CALLOWAY, HALF, 330.0], [MARLOWE, AVENUE_HALF, 290.0], [PRUITT, HALF, 330.0]]:
		for side in [-1.0, 1.0]:
			var y: float = s[0] + side * (s[1] + 10.0)
			var x: float = WEST_EDGE + 140.0 + (0.0 if side < 0 else s[2] * 0.5)
			while x < WIDTH - 60:
				var under_marquee: bool = side < 0 and s[0] == MARLOWE and absf(x - 2812.0) < 100.0
				if cross_x.all(func(c: float) -> bool: return absf(x - c) > 150.0) and not under_marquee:
					d.lamps.append(Vector2(x, y))
				x += s[2]
	for c in cross_x:
		for side in [-1.0, 1.0]:
			var x2: float = c + side * (HALF + 10.0)
			var y2: float = EMBANKMENT_Y + 80.0 + (0.0 if side < 0 else 160.0)
			while y2 < SOUTH_EDGE - 60:
				var clear := [CALLOWAY, MARLOWE, PRUITT].all(func(c2: float) -> bool: return absf(y2 - c2) > 170.0) \
					and [1435.0, 2365.0].all(func(a: float) -> bool: return absf(y2 - a) > 60.0)
				if clear and not d.is_in_building(Vector2(x2, y2), 4.0):
					d.lamps.append(Vector2(x2, y2))
				y2 += 330.0
	for p in [Vector2(500, 1408), Vector2(1100, 1462), Vector2(2600, 2338), Vector2(2900, 2392), Vector2(1700, 1408)]:
		d.alley_lamps.append(p)


func _ground_details() -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 1932009
	for p in [Vector2(900, MARLOWE), Vector2(2600, MARLOWE), Vector2(GARRITY, 1200), Vector2(ASHBY, 2500), Vector2(700, PRUITT)]:
		d.decals.append({"kind": "decals/manhole", "pos": p, "rot": 0.0, "scale": 1.0})
	for p in [Vector2(2600, MARLOWE), Vector2(GARRITY, 1200), Vector2(700, PRUITT)]:
		d.steam_vents.append(p)
	for p in [Vector2(1200, MARLOWE + 60), Vector2(2900, MARLOWE - 70), Vector2(GARRITY + 20, 2500), Vector2(800, CALLOWAY + 40),
			Vector2(2000, PRUITT - 30), Vector2(ASHBY + 10, 1300), Vector2(1600, 2200)]:
		d.decals.append({"kind": "decals/puddle", "pos": p, "rot": rnd.randf_range(-0.4, 0.4), "scale": rnd.randf_range(0.7, 1.2)})
	for p in [Vector2(2500, MARLOWE - 130), Vector2(1700, 1440), Vector2(2650, 2370), Vector2(1000, MARLOWE + 135)]:
		d.decals.append({"kind": "decals/litter", "pos": p, "rot": rnd.randf_range(-PI, PI), "scale": 1.0})
	for p in [Vector2(950, PRUITT + 40), Vector2(2400, CALLOWAY - 40)]:
		d.decals.append({"kind": "decals/oil", "pos": p, "rot": rnd.randf_range(-PI, PI), "scale": 1.0})


## M009: Mr. Feeney out on the pavement beside the Bijou's canopy, and the lost
## reel where the film exchange's boy set it down, in St. Brendan's churchyard.
## M010: Rosie's Café, where Vince Duggan takes his coffee every night with his
## Packard at the kerb outside, and a bench a few doors along, in front of
## Halloran Drugs, to watch it from.
func _cafe() -> void:
	var bench := Vector2(980, MARLOWE - AVENUE_HALF - 34.0)
	_prop("interiors/bench", bench, 0.0, Vector2(66, 14))
	d.cafe = [
		{"id": "car", "pos": Vector2(600, MARLOWE - 92.0), "rot": 0.0},
		{"id": "door", "pos": Vector2(660, MARLOWE - AVENUE_HALF - SW + 8.0)},
		{"id": "bench", "pos": bench},
		# M010: the emergency comes in along Marlowe Avenue from the ward and stops in a line at the kerb
		{"id": "approach", "pos": Vector2(WIDTH - 40.0, MARLOWE - 45.0)},
		{"id": "stop_police", "pos": Vector2(770, MARLOWE - 72.0)},
		{"id": "stop_fire", "pos": Vector2(945, MARLOWE - 64.0)},
		{"id": "stop_ambulance", "pos": Vector2(1115, MARLOWE - 68.0)},
	]


## M011: the city's powers, by name only (no politics to play): City Hall
## facing the park across Pruitt Street - limestone, a copper cupola, granite
## steps between two globe lamps, its doors locked at night with a light still
## burning in the mayor's office; the mayor's own house a few doors along, a
## clean greystone set back behind a railing and a little garden, its parlour
## lit; Alderman Doran's ward office across Marlowe Avenue from the park, and
## the Regulars' Club where the precinct men meet. M012: City Hall's night
## door, Doran's office and the club open on rooms (HalloranInteriors); the
## mayor's house stays private - the bell at its gate brings the housekeeper.
const CITY_HALL := "City Hall"
const MAYOR := "Mayor Dunleavy's Residence"
const DORAN := "Ald. Doran's Ward Office"
const REGULARS := "Halloran Square Regulars' Club"


func _civic() -> void:
	var front := PRUITT + HALF + SW  # City Hall's front, the sidewalk's back edge
	var steps := Rect2(1765, front - 38.0, 120, 38)
	d.lots.append({"rect": steps, "kind": "concrete"})
	d.lamps.append(Vector2(1752, front - 22.0))
	d.lamps.append(Vector2(1898, front - 22.0))
	# M012: the night door at the top of the steps is open (HalloranInteriors.city_hall)
	# the mayor's house: set back behind a garden and a railing, a gate in the middle, two lamps at it
	var house := Rect2(2681, front + 70.0, 303, 3300.0 - front - 70.0)
	_building(house, 3, "townhouse", "tar", Vector2.UP, {"name": MAYOR, "show_address": true})
	var garden := Rect2(2681, front, 303, 70)
	d.lots.append({"rect": garden, "kind": "grass"})
	var gate_x := garden.get_center().x
	d.fences.append([Vector2(garden.position.x, front + 4.0), Vector2(gate_x - 24.0, front + 4.0), "iron"])
	d.fences.append([Vector2(gate_x + 24.0, front + 4.0), Vector2(garden.end.x, front + 4.0), "iron"])
	d.lots.append({"rect": Rect2(gate_x - 22.0, front, 44, 70), "kind": "concrete"})  # the path to the door
	d.lamps.append(Vector2(gate_x - 34.0, front - 10.0))
	d.lamps.append(Vector2(gate_x + 34.0, front - 10.0))
	# M012: the mayor's house stays private: the bell at the gate brings his housekeeper down the path (a talk, not a room)
	d.locked_doors.append({"pos": Vector2(gate_x, front - 8.0), "prompt": "Ring the bell at the gate", "talk": "mayor_gate",
		"text": "The gate's chained. Warm lamps behind the parlour curtains - Mayor Dunleavy keeps late hours."})
	# the alderman's office and the precinct men's club
	# M012: Doran's ward office is open late (HalloranInteriors)
	# M012: the Regulars' Club lets Danny in (HalloranInteriors.regulars_club)


func _contacts() -> void:
	d.contacts = [{"id": "feeney", "look": "characters/feeney", "pos": Vector2(2915, MARLOWE - AVENUE_HALF - 30.0), "face": PI / 2}]
	d.errands = [{"id": "film_can", "pos": Vector2(1215, 2470)}]


## M009: where the square's own small troubles happen; Mr. Feeney at the Bijou notices.
func _incident_spots() -> void:
	d.incident_spots = [
		{"id": "bijou_kerb", "kinds": ["argument"], "pos": Vector2(2560, MARLOWE - AVENUE_HALF - 23.0), "along": Vector2.RIGHT,
			"local": "feeney", "place": "outside the Bijou"},
		{"id": "bakery_kerb", "kinds": ["argument"], "pos": Vector2(2500, MARLOWE + AVENUE_HALF + 23.0), "along": Vector2.RIGHT,
			"local": "feeney", "place": "outside Kowalski's bakery"},
		{"id": "square_alley", "kinds": ["exchange"], "pos": Vector2(2620, 2365), "along": Vector2.RIGHT, "local": "",
			"place": "the alley off the square"},
		{"id": "churchyard", "kinds": ["exchange"], "pos": Vector2(1100, 2560), "along": Vector2.RIGHT, "local": "feeney",
			"place": "behind St. Brendan's"},
		{"id": "square_stop", "kinds": ["stop"], "pos": Vector2(1960, MARLOWE + AVENUE_HALF + 23.0), "along": Vector2.RIGHT,
			"local": "feeney", "place": "by the square"},
	]


func _people_and_cars() -> void:
	var north := MARLOWE - AVENUE_HALF - 23.0
	var south := MARLOWE + AVENUE_HALF + 23.0
	d.walk_routes = [
		PackedVector2Array([Vector2(1520, north), Vector2(2150, north)]),  # Marlowe, north side by the square
		PackedVector2Array([Vector2(2370, north), Vector2(2855, north)]),  # Marlowe, north side: the Bijou (short of Mr. Feeney)
		PackedVector2Array([Vector2(2370, south), Vector2(3010, south)]),  # Marlowe, south side: the bakery
		PackedVector2Array([Vector2(1508, 2050), Vector2(1508, 2680)]),  # the square's west side
		PackedVector2Array([Vector2(440, south), Vector2(1290, south)]),  # Marlowe, south side, west of the church
		PackedVector2Array([Vector2(1825, 2038), Vector2(1825, 2692)]),  # M010: through the park, gate to gate
	]
	d.walkers = [
		{"look": "characters/lady", "route": 0, "at": 0.3},
		{"look": "characters/patron_man", "route": 1, "at": 0.5},
		{"look": "characters/patron_woman", "route": 1, "at": 0.2},
		{"look": "characters/worker", "route": 2, "at": 0.6},
		{"look": "characters/lady", "route": 3, "at": 0.5},
		{"look": "characters/worker", "route": 4, "at": 0.4},
		{"look": "characters/patron_woman", "route": 5, "at": 0.35},  # M010: a stroll through the park
	]
	# M015: the square's regulars, each out for their own hours of the night
	d.locals = [
		# the late show's crowd under the Bijou's marquee
		{"look": "characters/patron_man", "kind": "stand", "pos": Vector2(2672, north - 10.0), "face": 0.3, "hours": [22 * 60 + 15, 23 * 60 + 5],
			"group": "bijou", "lines": ["Is it the one with the gangsters in it?", "Two bits a ticket. Robbery.", "Shake a leg, Mabel."]},
		{"look": "characters/patron_woman", "kind": "stand", "pos": Vector2(2696, north - 12.0), "face": 2.8, "hours": [22 * 60 + 15, 23 * 60 + 5],
			"group": "bijou", "lines": ["I'll cry, I always cry.", "Hold my hand when it gets scary."]},
		{"look": "characters/lady", "kind": "stand", "pos": Vector2(2722, north - 8.0), "face": PI, "hours": [22 * 60 + 25, 23 * 60 + 5],
			"group": "bijou", "lines": ["The newsreel's the best part.", "Mr. Feeney's in a state again."]},
		# two of the alderman's men having words on City Hall's steps
		{"look": "characters/patron_man", "kind": "stand", "pos": Vector2(1882, 2908), "face": 0.2, "hours": [20 * 60, 23 * 60 + 30],
			"group": "hall", "lines": ["The alderman wants every vote counted. Twice, if need be.", "Not so loud. Walls have ears."]},
		{"look": "characters/clerk", "kind": "stand", "pos": Vector2(1906, 2914), "face": PI - 0.2, "hours": [20 * 60, 23 * 60 + 30],
			"group": "hall", "lines": ["The Mayor's lamp is still lit. He never sleeps.", "A paving contract, a little something for the ward."]},
		# a couple taking the air in the park
		{"look": "characters/patron_man", "kind": "stroll", "route": 5, "at": 0.6, "hours": [20 * 60 + 30, 24 * 60],
			"lines": ["Smell that? Lilacs.", "One day we'll have a place on this square."]},
		{"look": "characters/lady", "kind": "stroll", "route": 5, "at": 0.6, "hours": [20 * 60 + 30, 24 * 60], "with": 5},
		# a late drunk west of the church
		{"look": "characters/patron_man", "kind": "drunk", "route": 4, "at": 0.3, "hours": [23 * 60 + 30, 29 * 60],
			"lines": ["Father O'Malley's going to hear about this.", "Which way's Tuesday?"]},
	]
	# M015: Kowalski's van at the kerb before dawn, the bread carried in
	d.deliveries = [
		{"vehicle": "bakery_van", "paint": 0, "pos": Vector2(2560, MARLOWE + AVENUE_HALF - 22.0), "rot": 0.0,
			"door": Vector2(2520, MARLOWE + AVENUE_HALF + SW - 6.0), "hours": [26 * 60 + 30, 28 * 60 + 30],
			"looks": ["characters/worker", "characters/worker"], "lines": ["Rye, pumpernickel, twelve dozen rolls.", "Mind the step."]},
	]
	var lane := 28.0
	var e := MARLOWE + 45.0
	var w := MARLOWE - 45.0
	d.drive_loops = [
		# round the square: east on Marlowe, south on Garrity, west on Pruitt, north on Halloran Avenue
		PackedVector2Array([Vector2(HALLORAN_AVE + lane, e), Vector2(GARRITY - lane, e), Vector2(GARRITY - lane, PRUITT - lane),
			Vector2(HALLORAN_AVE + lane, PRUITT - lane)]),
		# the other block the other way: west on Marlowe, north on Garrity, east on Calloway, south on Ashby
		PackedVector2Array([Vector2(ASHBY - lane, w), Vector2(GARRITY + lane, w), Vector2(GARRITY + lane, CALLOWAY + lane),
			Vector2(ASHBY - lane, CALLOWAY + lane)]),
	]
	d.traffic = [
		{"type": "coupe", "paint": 0, "loop": 0, "segment": 0, "at": 0.5},
		{"type": "sedan", "paint": 0, "loop": 1, "segment": 2, "at": 0.3},
		{"type": "taxi", "paint": 0, "loop": 0, "segment": 2, "at": 0.5},  # M015: a cab cruising for fares
	]
	for x in [HALLORAN_AVE, GARRITY, ASHBY]:
		for s in [[CALLOWAY, HALF], [MARLOWE, AVENUE_HALF], [PRUITT, HALF]]:
			d.junctions.append(Rect2(x - HALF, s[0] - s[1], HALF * 2.0, s[1] * 2.0))
	d.cars = [
		{"type": "sedan", "paint": 1, "pos": Vector2(800, CALLOWAY + 62), "rot": 0.0, "owner": "somebody on Calloway Street"},
		{"type": "coupe", "paint": 0, "pos": Vector2(2700, PRUITT - 62), "rot": PI, "owner": "a family on Pruitt Street"},
		{"type": "sedan", "paint": 0, "pos": Vector2(2600, MARLOWE + 92), "rot": 0.0, "owner": "a picture-goer at the Bijou"},
		# M009: the parish school bus at the kerb beside St. Brendan's, facing down Halloran Avenue
		{"type": "school_bus", "paint": 0, "pos": Vector2(HALLORAN_AVE - 62.0, 2330), "rot": PI / 2, "owner": "St. Brendan's parish school"},
	]
	# the beat cop walks the avenue along the square's north side, by his call box
	d.police_beat = PackedVector2Array([Vector2(1560, MARLOWE + AVENUE_HALF + 23.0), Vector2(1800, MARLOWE + AVENUE_HALF + 23.0)])
	# M015: an hour at City Hall's door while the Mayor's lamp is lit
	d.police_posts = [{"pos": Vector2(1790, 2918), "face": Vector2(1825, 2880), "from": 21 * 60, "until": 22 * 60,
		"line": "Nobody goes up those steps after dark, Mac."}]
	d.spawn = Vector2(1800, MARLOWE)
