class_name RiversideWard
extends RefCounted
## The first neighbourhood: a few blocks of a fictional Near North Side,
## Chicago, 1932, laid out by hand. North is up (-y), one world px is about
## 7 cm. Chicago-style grid: long blocks with an alley down the middle and
## narrow gangways between houses. The district is closed by things you can
## see: the railroad embankment (north), the river with its raised bascule
## bridge (east) and street-closed barricades (west, south). The city
## carries on visually beyond them.
##
## Landmarks: the Copper Owl supper club and Hotel Marlowe face each other on
## Marlowe Avenue (streetcar tracks); Doyle's Garage on Pruitt Street;
## Lakeshore Cold Storage on the river at Wharf Street.

const SW := 46.0
const ALLEY := 66.0
const DORSEY := 0.0
const KESSLER := 1650.0
const WHARF := 3300.0
const CALLOWAY := -300.0
const MARLOWE := 600.0
const PRUITT := 1500.0
const STREET_HALF := 85.0
const AVENUE_HALF := 115.0
const RIVER_X := 3900.0
const FAR_BANK_X := 4400.0
const EMBANKMENT_Y := -950.0
const WEST_EDGE := -800.0
const SOUTH_EDGE := 2150.0

var d := DistrictLayout.new()


static func create() -> DistrictLayout:
	var w := RiversideWard.new()
	w._build()
	return w.d


func _build() -> void:
	d.name = "Riverside Ward"
	d.bounds = Rect2(-1700, -1300, 6600, 4000)
	d.play_area = Rect2(WEST_EDGE, EMBANKMENT_Y, RIVER_X - WEST_EDGE, SOUTH_EDGE - EMBANKMENT_Y)
	_streets()
	_blocks_and_alleys()
	_river()
	_central_rows()
	_outer_rows()
	_landmarks()
	_furnish_roofs()
	_street_furniture()
	_lamps()
	_ground_details()
	RiversideInteriors.add_to(d)
	_cars_and_spawn()


# ------------------------------------------------------------------ streets

func _streets() -> void:
	var top := EMBANKMENT_Y
	var bottom := d.bounds.end.y
	for s in [["Dorsey Street", DORSEY], ["Kessler Street", KESSLER], ["Wharf Street", WHARF]]:
		d.streets.append({"name": s[0], "avenue": false, "rect": Rect2(s[1] - STREET_HALF, top, STREET_HALF * 2, bottom - top)})
	var left := d.bounds.position.x
	for s in [["Calloway Street", CALLOWAY, STREET_HALF, false], ["Marlowe Avenue", MARLOWE, AVENUE_HALF, true],
			["Pruitt Street", PRUITT, STREET_HALF, false]]:
		d.streets.append({"name": s[0], "avenue": s[3], "rect": Rect2(left, s[1] - s[2], RIVER_X - left, s[2] * 2)})
	# streetcar line down the middle of Marlowe Avenue (ends at the bridge gates)
	d.cobbles.append(Rect2(left, MARLOWE - 40, 3830 - left, 80))
	d.rails.append([Vector2(left, MARLOWE - 20), Vector2(3830, MARLOWE - 20)])
	d.rails.append([Vector2(left, MARLOWE + 20), Vector2(3830, MARLOWE + 20)])


const COLS := [[-1700.0, -85.0], [85.0, 1565.0], [1735.0, 3215.0], [3385.0, 3900.0]]
const ROWS := [[-950.0, -385.0], [-215.0, 485.0], [715.0, 1415.0], [1585.0, 2700.0]]


func _blocks_and_alleys() -> void:
	for c in COLS:
		for r in ROWS:
			d.blocks.append(Rect2(c[0], r[0], c[1] - c[0], r[1] - r[0]))
	var names := {135.0: "Alley between Calloway & Marlowe", 1065.0: "Alley between Marlowe & Pruitt"}
	for y in names:
		for c in [COLS[1], COLS[2]]:
			d.alleys.append({"name": names[y], "rect": Rect2(c[0], y - ALLEY / 2, c[1] - c[0], ALLEY)})


func _river() -> void:
	d.water.append(Rect2(RIVER_X, d.bounds.position.y, FAR_BANK_X - RIVER_X, d.bounds.size.y))
	# the far bank (out of reach): a quayside promenade and the avenue carrying on east
	var far_w := d.bounds.end.x - FAR_BANK_X
	d.lots.append({"rect": Rect2(FAR_BANK_X, d.bounds.position.y, far_w, MARLOWE - AVENUE_HALF - d.bounds.position.y), "kind": "concrete"})
	d.lots.append({"rect": Rect2(FAR_BANK_X, MARLOWE + AVENUE_HALF, far_w, d.bounds.end.y - MARLOWE - AVENUE_HALF), "kind": "concrete"})
	d.streets.append({"name": "Marlowe Avenue", "avenue": true, "rect": Rect2(FAR_BANK_X, MARLOWE - AVENUE_HALF, d.bounds.end.x - FAR_BANK_X, AVENUE_HALF * 2)})
	d.quays.append([Vector2(RIVER_X, d.bounds.position.y), Vector2(RIVER_X, MARLOWE - AVENUE_HALF)])
	d.quays.append([Vector2(RIVER_X, MARLOWE + AVENUE_HALF), Vector2(RIVER_X, d.bounds.end.y)])


# ------------------------------------------------------------------ buildings

## Adds a building; front = the side facing its street (ZERO: all sides alike).
func _building(rect: Rect2, storeys: int, facade: String, roof: String, front: Vector2, opts: Dictionary = {}) -> Dictionary:
	var b := {"rect": rect, "storeys": storeys, "facade": facade, "roof": roof, "front": front,
		"props": [], "signs": [], "name": opts.get("name", ""), "opts": opts}
	d.buildings.append(b)
	return b


## A row of buildings between x0 and the row's end, from the street edge
## (front_y) back towards the alley (back_y). Each spec is
## [width, storeys, facade, roof, opts] or [width] for a gangway, or
## [width, "lot", kind] for an open lot.
func _row(x0: float, front_y: float, back_y: float, specs: Array) -> void:
	var front := Vector2.UP if front_y < back_y else Vector2.DOWN
	var x := x0
	for s in specs:
		var wdt: float = s[0]
		if s.size() == 1:
			x += wdt
			continue
		if s[1] is String and s[1] == "lot":
			d.lots.append({"rect": _span_rect(x, wdt, front_y, back_y), "kind": s[2]})
			x += wdt
			continue
		var opts: Dictionary = s[4] if s.size() > 4 else {}
		var depth: float = opts.get("depth", absf(back_y - front_y))
		var far := front_y + depth * signf(back_y - front_y)
		_building(_span_rect(x, wdt, front_y, far), s[1], s[2], s[3], front, opts)
		x += wdt


func _span_rect(x: float, wdt: float, y_a: float, y_b: float) -> Rect2:
	return Rect2(x, minf(y_a, y_b), wdt, absf(y_b - y_a))


## A column of buildings facing a north-south street (front = LEFT or RIGHT).
func _column(x_front: float, x_back: float, y0: float, specs: Array) -> void:
	var front := Vector2.LEFT if x_front < x_back else Vector2.RIGHT
	var y := y0
	for s in specs:
		var h: float = s[0]
		if s.size() == 1:
			y += h
			continue
		_building(Rect2(minf(x_front, x_back), y, absf(x_back - x_front), h), s[1], s[2], s[3], front,
			s[4] if s.size() > 4 else {})
		y += h


func _central_rows() -> void:
	# Block interiors: x 131..1519 and 1781..3169; rows meet the alleys at
	# y 102 / 168 (north blocks) and 1032 / 1098 (south blocks).
	# North of the first alley, facing Calloway Street: flats with gangways.
	_row(131, -169, 102, [
		[210, 3, "greystone", "tar"], [26], [200, 3, "brick_red", "tar", {"depth": 200}], [24],
		[230, 3, "greystone", "gravel"], [180, 2, "brick_red", "tar", {"depth": 190}], [28],
		[250, 4, "brick_red", "tar"], [240, 3, "brick_brown", "tar", {"awning": "green"}]])
	_row(1781, -169, 102, [
		[240, 3, "brick_red", "tar"], [26], [220, 3, "greystone", "tar", {"depth": 210}],
		[280, 4, "brick_brown", "gravel", {"awning": "red"}], [30], [190, 2, "brick_red", "tar", {"depth": 200}],
		[402, 3, "brick_red", "tar"]])
	# Facing Marlowe Avenue from the north: shops, the Copper Owl.
	_row(131, 439, 168, [
		[260, 3, "brick_brown", "tar", {"awning": "red"}], [190, 2, "brick_brown", "gravel", {"awning": "green"}], [24],
		[300, 4, "brick_red", "tar"], [220, 2, "brick_brown", "tar", {"awning": "red", "name": "Sal's Barber Shop"}],
		[394, 3, "greystone", "gravel"]])
	_row(1781, 439, 168, [
		[200, 3, "brick_brown", "tar"], [170, 2, "brick_brown", "gravel", {"awning": "red"}],
		[280, 3, "club", "tar", {"name": "The Copper Owl", "marquee": true}], [24],
		[200, 3, "greystone", "tar", {"name": "Marlowe Flats"}], [514, 4, "brick_red", "tar"]])
	# Facing Marlowe Avenue from the south: Hotel Marlowe.
	_row(131, 761, 1032, [
		[300, 4, "brick_red", "tar"], [210, 2, "brick_brown", "gravel", {"awning": "red"}], [26],
		[260, 3, "greystone", "tar"], [230, 3, "brick_brown", "tar", {"awning": "green", "name": "Lindqvist Hardware"}],
		[362, 3, "brick_red", "gravel"]])
	_row(1781, 761, 1032, [
		[220, 3, "brick_brown", "tar", {"awning": "red", "name": "Novak's Grocery"}], [24], [300, 3, "greystone", "gravel"],
		[320, 6, "greystone", "gravel", {"name": "Hotel Marlowe"}], [260, 3, "brick_brown", "tar", {"awning": "green"}],
		[264, 2, "brick_red", "tar"]])
	# Facing Pruitt Street: flats, Doyle's Garage and its forecourt.
	_row(131, 1369, 1098, [
		[240, 2, "brick_red", "tar", {"depth": 200}], [26], [230, 3, "greystone", "tar", {"depth": 210}],
		[200, 2, "brick_red", "tar"], [270, "lot", "concrete"], [422, 2, "garage", "tin", {"name": "Doyle's Garage"}]])
	_row(1781, 1369, 1098, [
		[260, 3, "brick_red", "tar", {"depth": 210}], [28], [240, 2, "brick_red", "tar", {"depth": 190}],
		[300, 4, "warehouse", "tin"], [26], [534, 3, "greystone", "tar"]])


func _outer_rows() -> void:
	# North of Calloway, backing onto the railroad embankment (gangways dead-end there).
	_row(131, -431, EMBANKMENT_Y, [
		[300, 4, "brick_red", "tar", {"depth": 330}], [26], [260, 3, "greystone", "gravel", {"depth": 330}],
		[380, 5, "warehouse", "tin"], [24], [398, 3, "brick_red", "tar", {"depth": 330}]])
	_row(1781, -431, EMBANKMENT_Y, [
		[340, 4, "brick_brown", "tar", {"depth": 330}], [280, 3, "brick_red", "tar", {"depth": 330}], [26],
		[420, 5, "warehouse", "gravel"], [322, 3, "greystone", "tar", {"depth": 330}]])
	# West of Dorsey Street: unbroken frontages (the barricades close the streets at x -800).
	_row(-1700, -431, EMBANKMENT_Y, [[500, 4, "warehouse", "tin"], [520, 3, "brick_red", "tar"], [549, 4, "brick_brown", "gravel"]])
	_row(-1700, -169, 135, [[560, 3, "brick_red", "tar"], [480, 4, "greystone", "gravel"], [529, 3, "brick_brown", "tar"]])
	_row(-1700, 439, 135, [[600, 4, "warehouse", "tin"], [450, 3, "brick_red", "tar"], [519, 3, "brick_brown", "tar", {"awning": "red"}]])
	_row(-1700, 761, 1065, [[500, 3, "greystone", "tar"], [540, 4, "brick_red", "tar"], [529, 3, "brick_brown", "gravel", {"awning": "green"}]])
	_row(-1700, 1369, 1065, [[620, 4, "warehouse", "tin"], [500, 3, "brick_red", "tar"], [449, 2, "brick_brown", "tar"]])
	_row(-1700, 1631, 1960, [[560, 4, "brick_red", "tar"], [500, 3, "greystone", "gravel"], [509, 3, "brick_brown", "tar"]])
	_row(-1700, 2700, 1960, [[1569, 5, "warehouse", "tin"]])
	# South of Pruitt Street (the barricades close the side streets at y 2150).
	_row(131, 1631, 1950, [[280, 3, "brick_red", "tar"], [240, 3, "greystone", "gravel"], [300, 4, "brick_brown", "tar", {"awning": "red"}],
		[260, 3, "brick_red", "tar"], [308, 3, "greystone", "tar"]])
	_row(131, 2700, 1950, [[700, 4, "warehouse", "tin"], [688, 3, "brick_red", "tar"]])
	_row(1781, 1631, 1950, [[320, 4, "brick_brown", "tar", {"awning": "green"}], [260, 3, "brick_red", "tar"], [280, 3, "greystone", "gravel"],
		[240, 2, "brick_brown", "tar"], [288, 3, "brick_red", "tar"]])
	_row(1781, 2700, 1950, [[688, 5, "warehouse", "tin"], [700, 3, "greystone", "gravel"]])
	# Between Wharf Street and the river.
	_row(3431, -431, EMBANKMENT_Y, [[469, 4, "warehouse", "tin"]])
	_row(3431, 1631, 1980, [[469, 4, "warehouse", "tin"]])
	_row(3431, 2700, 1980, [[469, 3, "brick_red", "tar"]])
	# Far bank of the river (out of reach; lit windows across the water).
	_column(FAR_BANK_X + 40, 4900, -1300, [[600, 5, "warehouse", "tin"], [500, 4, "brick_red", "tar"], [500, 3, "brick_brown", "tar"],
		[180, 4, "greystone", "gravel"]])
	_column(FAR_BANK_X + 40, 4900, 715, [[485, 5, "brick_red", "tar"], [600, 4, "warehouse", "tin"], [900, 3, "greystone", "gravel"]])


func _landmarks() -> void:
	# Lakeshore Cold Storage on the river, with a loading apron along the quay.
	_building(Rect2(3431, -169, 359, 608), 4, "warehouse", "tin", Vector2.LEFT, {"name": "Lakeshore Cold Storage", "skylights": 4})
	d.lots.append({"rect": Rect2(3790, -169, RIVER_X - 3790, 608), "kind": "concrete"})
	# South of the avenue: the bridge tender's house and a chandlery.
	_building(Rect2(3431, 761, 269, 330), 3, "brick_brown", "tar", Vector2.LEFT, {"awning": "green"})
	_building(Rect2(3730, 761, 110, 110), 2, "brick_red", "tar", Vector2.UP, {"name": "Bridge tender"})
	d.lots.append({"rect": Rect2(3431, 1091, RIVER_X - 3431, 278), "kind": "lot"})
	# The bascule bridge across the river is raised for the night: both
	# leaves stand straight up over the water.
	_building(Rect2(3880, MARLOWE - 105, 60, 210), 6, "steel", "steel", Vector2.ZERO, {"name": "Marlowe Avenue Bridge", "bare": true})
	_building(Rect2(FAR_BANK_X - 40, MARLOWE - 105, 60, 210), 6, "steel", "steel", Vector2.ZERO, {"bare": true})
	# The railroad embankment closes the north end of every street.
	_building(Rect2(d.bounds.position.x, d.bounds.position.y, RIVER_X - d.bounds.position.x, EMBANKMENT_Y - d.bounds.position.y),
		2, "stone", "ballast", Vector2.ZERO, {"name": "Railroad embankment", "bare": true})


# ------------------------------------------------------------------ roofs

## Rooftop furniture for every building: chimneys and vents on flats, water
## tanks on the tall ones, skylights on shops and warehouses, a stair hut on
## anything of three storeys or more, washing on some flats. Deterministic.
func _furnish_roofs() -> void:
	for i in d.buildings.size():
		var b: Dictionary = d.buildings[i]
		if b.opts.get("bare", false):
			continue
		var rnd := RandomNumberGenerator.new()
		rnd.seed = 1932 + i * 7919
		var r: Rect2 = (b.rect as Rect2).grow(-16.0)
		var taken: Array[Rect2] = []
		var kinds: Array[String] = []
		if b.storeys >= 3:
			kinds.append("roof/stair_hut")
		if b.storeys >= 5 or (b.storeys == 4 and rnd.randf() < 0.5) or b.name == "Hotel Marlowe":
			kinds.append("roof/water_tank")
		var skylights: int = b.opts.get("skylights", 0)
		if b.facade in ["warehouse", "garage"] and skylights == 0:
			skylights = clampi(int(r.get_area() / 30000.0), 1, 4)
		elif b.facade in ["brick_brown", "club"] and rnd.randf() < 0.6:
			skylights = 1
		for k in skylights:
			kinds.append("roof/skylight")
		if b.facade in ["brick_red", "greystone"] and rnd.randf() < 0.35:
			kinds.append("roof/laundry")
		for k in clampi(int(r.size.x / 55.0), 2, 6):
			kinds.append("roof/chimney")
		for k in rnd.randi_range(2, 5):
			kinds.append("roof/vent")
		if b.facade in ["brick_red", "greystone"] and rnd.randf() < 0.5:
			kinds.append("roof/skylight")
		for kind in kinds:
			var size := AssetCatalog.display_size(kind) + Vector2(10, 10)
			for attempt in 24:
				var p := Vector2(rnd.randf_range(r.position.x + size.x / 2, r.end.x - size.x / 2),
					rnd.randf_range(r.position.y + size.y / 2, r.end.y - size.y / 2))
				if kind == "roof/chimney" and attempt < 16:  # chimneys sit near a side wall
					p.x = r.position.x + size.x / 2 if rnd.randf() < 0.5 else r.end.x - size.x / 2
				var box := Rect2(p - size / 2, size)
				if r.encloses(box) and not taken.any(func(t: Rect2) -> bool: return t.intersects(box)):
					taken.append(box)
					b.props.append({"kind": kind, "pos": p, "rot": 0.0 if kind != "roof/laundry" else rnd.randf_range(-0.3, 0.3)})
					break


func _sign(name: String, kind: String, lift: float, inset: float = 40.0) -> void:
	for b in d.buildings:
		if b.name == name:
			var r: Rect2 = b.rect
			var pos := r.get_center()
			var front: Vector2 = b.front
			if front != Vector2.ZERO:
				pos = r.get_center() + front * (absf(front.dot(r.size)) * 0.5 - inset)
			b.signs.append({"kind": kind, "pos": pos, "rot": 0.0, "lift": lift})
			# keep the sign clear of rooftop furniture
			var area := Rect2(pos - AssetCatalog.display_size(kind) / 2, AssetCatalog.display_size(kind)).grow(8.0)
			b.props = b.props.filter(func(p: Dictionary) -> bool: return not area.has_point(p.pos))


# ------------------------------------------------------------------ street level

func _prop(kind: String, pos: Vector2, rot: float = 0.0, solid: Variant = 0.0, height: float = 0.0) -> void:
	var p := {"kind": kind, "pos": pos, "rot": rot, "height": height}
	if solid is Vector2:
		p["box"] = solid
	elif float(solid) > 0.0:
		p["radius"] = float(solid)
	d.props.append(p)


func _street_furniture() -> void:
	_sign("The Copper Owl", "signs/copper_owl", 26.0, 44.0)
	_sign("Hotel Marlowe", "signs/hotel", 22.0, 30.0)
	_sign("Doyle's Garage", "signs/garage", 0.0, 60.0)
	_sign("Sal's Barber Shop", "signs/barber", 0.0, 34.0)
	_sign("Novak's Grocery", "signs/grocery", 0.0, 34.0)
	_sign("Lindqvist Hardware", "signs/hardware", 0.0, 34.0)
	_sign("Lakeshore Cold Storage", "signs/cold_storage", 0.0, 120.0)
	# Awnings and the club canopy hang over the sidewalk.
	for b in d.buildings:
		var front: Vector2 = b.front
		if front == Vector2.ZERO:
			continue
		var r: Rect2 = b.rect
		var edge_mid := r.get_center() + front * absf(front.dot(r.size)) * 0.5
		var rot := (-front).angle() + PI / 2
		var along := absf(front.orthogonal().dot(r.size))
		if b.opts.get("marquee", false):
			_prop("props/marquee", edge_mid + front * 25.0, rot, 0.0, 30.0)
		elif b.opts.has("awning"):
			var n := clampi(int(along / 150.0), 1, 3)
			for k in n:
				var t := (k + 0.5) / n - 0.5
				_prop("props/awning_" + b.opts.awning, edge_mid + front.orthogonal() * t * along + front * 18.0, rot, 0.0, 34.0)
	# Corners: hydrants, a mailbox, the newsstand.
	for p in [Vector2(97, -203), Vector2(1553, 473), Vector2(1747, -203), Vector2(97, 727), Vector2(3203, 727),
			Vector2(1553, 1403), Vector2(1747, 1403), Vector2(3203, -203), Vector2(-97, 473), Vector2(3397, 1403)]:
		_prop("props/hydrant", p, 0.0, 6.0)
	_prop("props/mailbox", Vector2(1530, 470), 0.0, Vector2(14, 14))
	_prop("props/newsstand", Vector2(1826, 462), 0.0, Vector2(44, 28))
	# Bootleg delivery behind the Copper Owl and outside the warehouse.
	_prop("props/crates", Vector2(2262, 146), 0.15, Vector2(40, 38))
	_prop("props/barrel", Vector2(2306, 156), 0.0, 9.0)
	_prop("props/barrel", Vector2(2326, 154), 0.0, 9.0)
	_prop("props/crate", Vector2(2200, 155), 0.3, Vector2(24, 24))
	for spec in [["props/crates", Vector2(3842, -100), 0.1, Vector2(40, 38)], ["props/crates", Vector2(3866, -30), -0.2, Vector2(40, 38)],
			["props/barrel", Vector2(3880, 40), 0.0, 9.0], ["props/barrel", Vector2(3858, 52), 0.0, 9.0],
			["props/crate", Vector2(3820, 380), 0.4, Vector2(24, 24)], ["props/barrel", Vector2(3880, 300), 0.0, 9.0]]:
		_prop(spec[0], spec[1], spec[2], spec[3])
	# Ash cans along the alleys.
	for p in [Vector2(600, 112), Vector2(618, 113), Vector2(2000, 112), Vector2(2900, 158), Vector2(520, 1043),
			Vector2(1300, 1088), Vector2(2150, 1042), Vector2(2168, 1043), Vector2(3000, 1088)]:
		_prop("props/trash_can", p, 0.0, 8.0)
	# Doyle's Garage forecourt: a pump.
	_prop("props/gas_pump", Vector2(870, 1340), 0.0, 9.0)
	# The police call box at the corner of the beat cop's round.
	_prop("props/call_box", Vector2(1890, 479), 0.0, 8.0)
	# Barricades with warning lanterns close the district's streets.
	_barricade_line(Vector2(WEST_EDGE, CALLOWAY), Vector2.DOWN, 3)
	_barricade_line(Vector2(WEST_EDGE, MARLOWE), Vector2.DOWN, 4)
	_barricade_line(Vector2(WEST_EDGE, PRUITT), Vector2.DOWN, 3)
	_barricade_line(Vector2(DORSEY, SOUTH_EDGE), Vector2.RIGHT, 3)
	_barricade_line(Vector2(KESSLER, SOUTH_EDGE), Vector2.RIGHT, 3)
	_barricade_line(Vector2(WHARF, SOUTH_EDGE), Vector2.RIGHT, 3)
	_barricade_line(Vector2(3830, MARLOWE), Vector2.DOWN, 3)


## n sawhorses side by side along `along`, centred on c, with lanterns at the ends.
func _barricade_line(c: Vector2, along: Vector2, n: int) -> void:
	var length := 96.0
	var rot := along.angle()
	for k in n:
		var t := (k - (n - 1) * 0.5) * (length - 8.0)
		_prop("props/barricade", c + along * t, rot, Vector2(length, 18))
	var half := (n * (length - 8.0)) * 0.5
	for s in [-1.0, 1.0, 0.0]:
		d.props.append({"kind": "props/lantern", "pos": c + along * (s * (half - 14.0)) + along.orthogonal() * 2.0,
			"rot": 0.0, "height": 0.0, "light": Color(1.0, 0.35, 0.2)})


func _lamps() -> void:
	var cross_x := [DORSEY, KESSLER, WHARF]
	var cross_y := [CALLOWAY, MARLOWE, PRUITT]
	var alley_y := [135.0, 1065.0]
	# East-west streets: lamps on both curbs, staggered; the avenue is brighter.
	for s in [[CALLOWAY, STREET_HALF, 340.0], [MARLOWE, AVENUE_HALF, 290.0], [PRUITT, STREET_HALF, 340.0]]:
		for side in [-1.0, 1.0]:
			var y: float = s[0] + side * (s[1] + 10.0)
			var x: float = -1550.0 + (0.0 if side < 0 else s[2] * 0.5)
			while x < RIVER_X - 80:
				var clear := cross_x.all(func(c: float) -> bool: return absf(x - c) > 150.0)
				if clear and absf(x - 2291.0) > 90.0:  # not under the Copper Owl canopy
					d.lamps.append(Vector2(x, y))
				x += s[2]
	# North-south streets.
	for c in cross_x:
		for side in [-1.0, 1.0]:
			var x2: float = c + side * (STREET_HALF + 10.0)
			var y2: float = -880.0 + (0.0 if side < 0 else 135.0)
			while y2 < 2600.0:
				var clear2 := cross_y.all(func(c2: float) -> bool: return absf(y2 - c2) > 160.0) \
					and alley_y.all(func(a: float) -> bool: return absf(y2 - a) > 60.0)
				if clear2 and not (c == WHARF and side > 0 and y2 > -170 and y2 < 440):
					d.lamps.append(Vector2(x2, y2))
				y2 += 330.0
	# Far bank of the river.
	var yf := -1200.0
	while yf < 2650.0:
		if absf(yf - MARLOWE) > 140.0:
			d.lamps.append(Vector2(FAR_BANK_X + 20, yf))
		yf += 300.0
	# Dim lamps over back doors in the alleys.
	for p in [Vector2(450, 108), Vector2(1100, 162), Vector2(2120, 108), Vector2(2800, 162),
			Vector2(500, 1038), Vector2(1150, 1092), Vector2(2200, 1038), Vector2(2900, 1092)]:
		d.alley_lamps.append(p)


func _ground_details() -> void:
	for p in [Vector2(800, 672), Vector2(2330, 672), Vector2(1650, 200), Vector2(1650, 1000), Vector2(0, 1100),
			Vector2(3300, 1100), Vector2(1100, -300), Vector2(2600, -300), Vector2(1000, 1500), Vector2(2900, 1500),
			Vector2(0, 300), Vector2(3300, -100), Vector2(-400, 530), Vector2(3600, 530)]:
		d.decals.append({"kind": "decals/manhole", "pos": p, "rot": 0.0, "scale": 1.0})
	for p in [Vector2(2330, 672), Vector2(1650, 1000), Vector2(1100, -300), Vector2(2900, 1500), Vector2(0, 300), Vector2(-400, 530)]:
		d.steam_vents.append(p)
	for spec in [[Vector2(400, 491), 0.0], [Vector2(1400, 709), 0.0], [Vector2(2000, 491), 0.0], [Vector2(2850, 709), 0.0],
			[Vector2(1571, 300), PI / 2], [Vector2(1729, 1250), PI / 2], [Vector2(91, -40), PI / 2], [Vector2(3209, 900), PI / 2],
			[Vector2(700, -221), 0.0], [Vector2(2400, 1421), 0.0]]:
		d.decals.append({"kind": "decals/drain", "pos": spec[0], "rot": spec[1], "scale": 1.0})
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 1932
	for p in [Vector2(600, 655), Vector2(2620, 662), Vector2(2050, 535), Vector2(1000, 540), Vector2(1665, 380),
			Vector2(1700, -262), Vector2(300, -330), Vector2(3020, 1462), Vector2(1200, 1545), Vector2(520, 138),
			Vector2(2700, 1066), Vector2(3330, 900), Vector2(40, 1800), Vector2(3850, 230), Vector2(2450, 548),
			Vector2(1655, 1700), Vector2(-500, 650), Vector2(3260, 400)]:
		d.decals.append({"kind": "decals/puddle", "pos": p, "rot": rnd.randf_range(-0.4, 0.4), "scale": rnd.randf_range(0.7, 1.25)})
	for p in [Vector2(1852, 474), Vector2(700, 122), Vector2(2500, 150), Vector2(1900, 1080), Vector2(800, 1052), Vector2(2478, 448)]:
		d.decals.append({"kind": "decals/litter", "pos": p, "rot": rnd.randf_range(-PI, PI), "scale": 1.0})
	for p in [Vector2(950, 1250), Vector2(1010, 1180), Vector2(1200, 140), Vector2(2300, 1070), Vector2(3840, 100), Vector2(2380, 505)]:
		d.decals.append({"kind": "decals/oil", "pos": p, "rot": rnd.randf_range(-PI, PI), "scale": rnd.randf_range(0.8, 1.2)})


func _cars_and_spawn() -> void:
	d.cars = [
		{"type": "coupe", "paint": 0, "pos": Vector2(2425, 694), "rot": 0.0},    # outside Hotel Marlowe
		{"type": "sedan", "paint": 0, "pos": Vector2(2150, 506), "rot": PI},     # outside the Copper Owl
		{"type": "sedan", "paint": 1, "pos": Vector2(700, -235), "rot": 0.0},     # Calloway Street
		{"type": "coupe", "paint": 1, "pos": Vector2(960, 1190), "rot": PI / 2},  # Doyle's forecourt
		{"type": "sedan", "paint": 0, "pos": Vector2(1040, 1250), "rot": -PI / 2},
		{"type": "sedan", "paint": 1, "pos": Vector2(3845, 150), "rot": PI / 2},  # warehouse apron
		{"type": "coupe", "paint": 0, "pos": Vector2(2600, 1435), "rot": PI},     # Pruitt Street
		{"type": "sedan", "paint": 1, "pos": Vector2(2585, 506), "rot": PI},     # M003: outside your flat
	]
	# The beat cop walks a short round on the north side of Marlowe Avenue by
	# the Kessler Street corner, past the newsstand and his call box.
	d.police_beat = PackedVector2Array([Vector2(1872, 457), Vector2(1995, 457)])
	# M003: every night begins at home, in the ground-floor flat next door to
	# the Copper Owl, by the bed (see RiversideInteriors.flat).
	d.spawn = Vector2(2522, 384)
	d.spawn_facing = PI * 0.5
