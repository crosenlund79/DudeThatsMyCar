class_name CanalMarket
extends DistrictBuilder
## M015: Canal Market - the old market quarter south of Halloran Square and
## west of the Riverfront Yards, between the yards' Front Street and the
## drainage canal. Drawn up in its own coordinates and placed at ORIGIN:
## Halloran Avenue, Garrity and Ashby Street come down into it from the
## square, Front and Foundry Street run on west into it from the yards.
## Crowded, poor, loud and late: four-storey tenements over shops, the El
## running on its riveted deck over Market Street to its terminal at Ashby,
## the Canal Market Hall's brick arches and glass roof, St. Casimir's and its
## plaza round a fountain, the Golden Lantern's red-lacquered front and paper
## lanterns, A. Feld's pawnshop, the Canal Street Baths, shuttered stalls and
## pushcarts along the kerbs, coal barges tied up along the canal. Grimy, dim
## side streets, bright Market Street. Closed by the canal (south) and
## barricades (west).

const ORIGIN := Vector2(-4900, 2700)
const WIDTH := 3200.0
const HEIGHT := 2600.0
## Streets: Front and Foundry as in the yards (local y), the square's three
## avenues as in Halloran Square (local x).
const FRONT := 85.0
const MARKET := 760.0
const FOUNDRY := 1300.0
const CANAL_ST := 1840.0
const WENCESLAS := 560.0
const HALLORAN_AVE := 1400.0
const GARRITY := 2250.0
const ASHBY := 3115.0
const HALF := 85.0
const AVENUE_HALF := 115.0
const SW := 46.0
const ALLEY := 66.0
const WEST_EDGE := 300.0
const QUAY := 2010.0
const FAR_QUAY := 2300.0
## The El: the deck's middle line over the north half of Market Street, its terminal at Ashby.
const EL_Y := MARKET - 60.0
const EL_FROM := 120.0
const EL_TO := 3010.0

const MARKET_HALL := "Canal Market Hall"
const CASIMIR := "St. Casimir's Church"
const LANTERN := "Golden Lantern"
const PAWN := "A. Feld, Loans"
const BATHS := "Canal Street Baths"


static func create() -> DistrictLayout:
	var w := CanalMarket.new()
	w._build()
	return w.d.shift(ORIGIN)


func _build() -> void:
	d.id = "market"
	d.name = "Canal Market"
	d.bounds = Rect2(0, 0, WIDTH, HEIGHT)
	d.play_area = Rect2(WEST_EDGE, 0, WIDTH - WEST_EDGE, QUAY)
	d.lamp_energy = 0.95
	d.grime_level = 0.85  # market refuse, coal smoke from the barges
	_streets()
	_blocks()
	_canal()
	_rows()
	_plaza()
	_el()
	_furnish_roofs()
	_roof_landmarks()
	_signs()
	_street_furniture()
	_lamps()
	_ground_details()
	_people_and_cars()
	_incident_spots()
	# the ways north into Halloran Square and east into the Riverfront Yards
	for x in [HALLORAN_AVE, GARRITY, ASHBY]:
		d.exits.append({"to": "halloran", "rect": Rect2(x - HALF - SW, 0, (HALF + SW) * 2.0, 6)})
	d.exits.append({"to": "yards", "rect": Rect2(WIDTH - 6, 0, 6, FRONT + HALF + SW)})
	d.exits.append({"to": "yards", "rect": Rect2(WIDTH - 6, FOUNDRY - HALF - SW, 6, (HALF + SW) * 2.0)})


func _streets() -> void:
	for s in [["Wenceslas Street", WENCESLAS], ["Halloran Avenue", HALLORAN_AVE], ["Garrity Street", GARRITY], ["Ashby Street", ASHBY]]:
		d.streets.append({"name": s[0], "avenue": false, "rect": Rect2(s[1] - HALF, 0, HALF * 2, CANAL_ST + HALF)})
	for s in [["Front Street", FRONT, HALF, false], ["Market Street", MARKET, AVENUE_HALF, true], ["Foundry Street", FOUNDRY, HALF, false],
			["Canal Street", CANAL_ST, HALF, false]]:
		d.streets.append({"name": s[0], "avenue": s[3], "rect": Rect2(0, s[1] - s[2], WIDTH, s[2] * 2)})
	# granite setts down Market Street under the El, and along the quay
	d.cobbles.append(Rect2(0, MARKET - AVENUE_HALF + 10, WIDTH, AVENUE_HALF * 2 - 20))
	d.cobbles.append(Rect2(0, CANAL_ST + HALF + SW, WIDTH, QUAY - CANAL_ST - HALF - SW))


const COLS := [[0.0, WENCESLAS - HALF], [WENCESLAS + HALF, HALLORAN_AVE - HALF], [HALLORAN_AVE + HALF, GARRITY - HALF],
	[GARRITY + HALF, ASHBY - HALF]]
const ROWS := [[FRONT + HALF, MARKET - AVENUE_HALF], [MARKET + AVENUE_HALF, FOUNDRY - HALF], [FOUNDRY + HALF, CANAL_ST - HALF]]


func _blocks() -> void:
	for c in COLS:
		for r in ROWS:
			d.blocks.append(Rect2(c[0], r[0], c[1] - c[0], r[1] - r[0]))
	# the alley behind Front Street's tenements (not behind St. Casimir's), and behind Foundry Street's shops
	for c in COLS:
		if c != COLS[2]:
			d.alleys.append({"name": "Alley off Market Street", "rect": Rect2(c[0], 420.0 - ALLEY / 2, c[1] - c[0], ALLEY)})
		d.alleys.append({"name": "Alley off Canal Street", "rect": Rect2(c[0], 1590.0 - ALLEY / 2, c[1] - c[0], ALLEY)})
	# the quayside promenade between Canal Street and the water
	d.lots.append({"rect": Rect2(0, CANAL_ST + HALF + SW, WIDTH, QUAY - CANAL_ST - HALF - SW), "kind": "concrete"})


func _canal() -> void:
	d.water.append(Rect2(0, QUAY, WIDTH, FAR_QUAY - QUAY))
	d.quays.append([Vector2(0, QUAY), Vector2(WIDTH, QUAY)])
	d.lots.append({"rect": Rect2(0, FAR_QUAY, WIDTH, HEIGHT - FAR_QUAY), "kind": "concrete"})
	# the far side (out of reach): coal sheds and a gas works
	_row(0, FAR_QUAY + 40.0, HEIGHT, [[700, 3, "warehouse", "tin"], [600, 4, "factory", "tin"], [900, 2, "warehouse", "gravel"],
		[1000, 3, "brick_red", "tar"]])
	# coal barges tied up along the near quay
	for b in [[700.0, 0.0], [1650.0, PI], [2560.0, 0.0]]:
		_prop("props/barge", Vector2(b[0], QUAY + 46.0), b[1])


## Rows of buildings: tenements over shops on Front and Market Street, the
## market hall, workshops and the baths on Foundry and Canal Street.
func _rows() -> void:
	var front := FRONT + HALF + SW
	var mkt_n := MARKET - AVENUE_HALF - SW
	var mkt_s := MARKET + AVENUE_HALF + SW
	var fdy_n := FOUNDRY - HALF - SW
	var fdy_s := FOUNDRY + HALF + SW
	var cnl_n := CANAL_ST - HALF - SW
	var a1 := 420.0 - ALLEY / 2
	var a2 := 420.0 + ALLEY / 2
	var b1 := 1590.0 - ALLEY / 2
	var b2 := 1590.0 + ALLEY / 2
	# (every row starts behind the side street's pavement: a block's x + SW, its widths filling to the far pavement)
	var c1: float = COLS[1][0] + SW
	var c2: float = COLS[2][0] + SW
	var c3: float = COLS[3][0] + SW
	# west of Wenceslas (past the barricades): sheds and tenements
	_row(0, front, a1, [[429, 3, "tenement", "tar"]])
	_row(0, mkt_n, a2, [[429, 3, "brick_red", "tar"]])
	_row(0, mkt_s, fdy_n, [[429, 2, "warehouse", "tin"]])
	_row(0, fdy_s, b1, [[429, 3, "tenement", "tar"]])
	_row(0, cnl_n, b2, [[429, 2, "brick_brown", "tar"]])
	# Front Street: tenements, four and five storeys
	_row(c1, front, a1, [[240, 4, "tenement", "tar"], [24], [314, 4, "brick_red", "tar"]])
	# (St. Casimir's stands back from Front Street between two corner houses, its front to the plaza: _plaza)
	_row(c2, front, a1, [[110, 4, "tenement", "gravel"], [368], [110, 4, "brick_red", "tar"]])
	_row(c3, front, a1, [[260, 5, "tenement", "tar"], [343, 4, "brick_red", "tar"]])
	# Market Street, north side: shops under flats, the Golden Lantern
	_row(c1, mkt_n, a2, [[190, 3, "brick_brown", "tar", {"awning": "red", "name": "Rubin's Delicatessen"}],
		[198, 3, "tenement", "tar", {"awning": "green"}], [190, 3, "brick_brown", "tar", {"awning": "red", "name": "Novotny Hardware"}]])
	_row(c3, mkt_n, a2, [[280, 3, "lantern", "tar", {"name": LANTERN}], [323, 3, "brick_brown", "tar", {"awning": "green",
		"name": "Sokol Hall"}]])
	# Market Street, south side: the market hall fills its block; shops and a lodging house beyond
	_row(c1, mkt_s, fdy_n, [[578, 2, "market", "tin", {"name": MARKET_HALL, "skylights": 0}]])
	_row(c2, mkt_s, fdy_n, [[290, 3, "brick_brown", "tar", {"awning": "green", "name": "Dvorak's Bakery"}],
		[298, 4, "tenement", "tar"]])
	_row(c3, mkt_s, fdy_n, [[340, 4, "greystone", "tar", {"name": "Hotel Bohemia"}], [263, 3, "brick_red", "tar"]])
	# Foundry Street, south side: workshops, the pawnshop, the baths
	_row(c1, fdy_s, b1, [[290, 2, "warehouse", "tin"], [288, 2, "garage", "tin", {"name": "Market Street Garage"}]])
	_row(c2, fdy_s, b1, [[180, 3, "brick_brown", "tar", {"name": PAWN, "awning": "red"}], [408, 3, "tenement", "tar"]])
	_row(c3, fdy_s, b1, [[603, 2, "civic", "gravel", {"name": BATHS, "skylights": 3}]])
	# Canal Street: sheds and a cooperage facing the quay
	_row(c1, cnl_n, b2, [[578, 2, "warehouse", "tin"]])
	_row(c2, cnl_n, b2, [[260, 2, "brick_red", "tar"], [328, 3, "warehouse", "gravel", {"name": "Hradek Cooperage"}]])
	_row(c3, cnl_n, b2, [[603, 2, "warehouse", "tin"]])


## St. Casimir's and its plaza: the church set back from Market Street behind
## a paved plaza with the fountain in the middle, benches and lamps round it.
func _plaza() -> void:
	var x0: float = COLS[2][0] + SW
	var x1: float = COLS[2][1] - SW
	var plaza := Rect2(x0, 440.0, x1 - x0, MARKET - AVENUE_HALF - SW - 440.0)
	d.lots.append({"rect": plaza, "kind": "concrete"})
	# the church: between the corner houses, back on Front Street's pavement line, its front to the plaza
	var church := Rect2(x0 + 120.0, FRONT + HALF + SW + 20.0, 278.0, 440.0 - (FRONT + HALF + SW + 20.0))
	_building(church, 4, "greystone", "tar", Vector2.DOWN, {"name": CASIMIR})
	d.lots.append({"rect": Rect2(church.position.x, FRONT + HALF + SW, church.size.x, 20.0), "kind": "concrete"})
	_building(Rect2(church.end.x, church.end.y - 110.0, 70, 110), 8, "greystone", "steel", Vector2.DOWN,
		{"name": "St. Casimir's tower", "bare": true})
	var mid := plaza.get_center()
	_prop("props/fountain", mid, 0.0, 50.0)
	for p in [Vector2(-170, -20), Vector2(170, -20)]:
		_prop("interiors/bench", mid + p, PI / 2 if p.x < 0 else -PI / 2, Vector2(66, 14))
	for p in [Vector2(-250, 40), Vector2(250, 40)]:
		_prop("props/tree", mid + p, 0.6, 0.0, 64.0)
	for p in [Vector2(-110, -60), Vector2(110, -60), Vector2(-110, 60), Vector2(110, 60)]:
		d.lamps.append(mid + p)
	d.landmarks.append({"pos": mid, "label": "St. Casimir's Plaza"})


## The El over Market Street: the deck laid end to end, raised over the
## road; its columns at the north kerb and along the middle line (clear of
## both lanes); the terminal's platform canopies at Ashby.
func _el() -> void:
	var x := EL_FROM
	while x < EL_TO:
		_prop("props/el_deck", Vector2(x + 128.0, EL_Y), 0.0, 0.0, 58.0)
		x += 256.0
	var c := EL_FROM + 60.0
	while c < EL_TO:
		var near_cross := [WENCESLAS, HALLORAN_AVE, GARRITY, ASHBY].any(func(s: float) -> bool: return absf(c - s) < HALF + 20.0)
		if not near_cross:
			_prop("props/el_column", Vector2(c, MARKET - AVENUE_HALF + 8.0), 0.0, 7.0)
			_prop("props/el_column", Vector2(c, MARKET - 12.0), 0.0, 7.0)
		c += 256.0
	for k in 3:  # the terminal's platform canopies either side of the deck
		_prop("props/awning_green", Vector2(EL_TO - 300.0 + k * 90.0, EL_Y - 70.0), 0.0, 0.0, 66.0)
		_prop("props/awning_green", Vector2(EL_TO - 300.0 + k * 90.0, EL_Y + 70.0), PI, 0.0, 66.0)
	d.el_line = PackedVector2Array([Vector2(EL_FROM - 200.0, EL_Y), Vector2(EL_TO - 160.0, EL_Y)])
	d.landmarks.append({"pos": Vector2(EL_TO - 200.0, EL_Y), "label": "Market St. El terminal"})


## Roof furniture that makes the silhouettes: the market hall's glass ridges,
## the baths' skylights already there.
func _roof_landmarks() -> void:
	for b in d.buildings:
		if b.name == MARKET_HALL:
			var r: Rect2 = b.rect
			b.props = b.props.filter(func(p: Dictionary) -> bool: return String(p.kind) != "roof/skylight")
			for k in 5:
				var p := Vector2(r.position.x + 70.0 + k * (r.size.x - 140.0) / 4.0, r.get_center().y)
				b.props = b.props.filter(func(q: Dictionary) -> bool: return (q.pos as Vector2).distance_to(p) > 50.0)
				b.props.append({"kind": "roof/glass", "pos": p, "rot": PI / 2})


func _signs() -> void:
	_sign(MARKET_HALL, "signs/market_hall", 0.0, 50.0)
	_sign(LANTERN, "signs/lantern", 0.0, 40.0)
	_sign(PAWN, "signs/pawn", 0.0, 34.0)
	_sign(CASIMIR, "signs/casimir", 0.0, 50.0)
	_sign(BATHS, "signs/baths", 0.0, 46.0)
	for b in d.buildings:
		if b.name != "" and not b.name in ["St. Casimir's tower"]:
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
		if b.name == LANTERN:
			_prop("props/lanterns", edge_mid + front * 22.0, rot, 0.0, 40.0)
	# the market's frontage on Market Street's south pavement: shuttered stalls between the lamp posts, pushcarts
	# in the north gutter (clear of the crossings and of the El's columns)
	var k2 := 0
	var x := WEST_EDGE + 120.0 + 130.0 + 130.0  # midway between the south side's lamps
	while x < WIDTH - 120.0:
		var cross := [WENCESLAS, HALLORAN_AVE, GARRITY, ASHBY].any(func(s2: float) -> bool: return absf(x - s2) < HALF + 70.0)
		if not cross and x > 640.0:
			_prop("props/stall_a" if k2 % 2 == 0 else "props/stall_b", Vector2(x, MARKET + AVENUE_HALF + 24.0), PI, Vector2(70, 30))
			var cart := x + 70.0
			var column_x := fposmod(cart - (EL_FROM + 60.0), 256.0)
			if k2 % 3 == 1 and column_x > 40.0 and column_x < 216.0:
				_prop("props/pushcart", Vector2(cart, MARKET - AVENUE_HALF + 30.0), PI, Vector2(36, 22))
			k2 += 1
		x += 260.0
	for p in [Vector2(HALLORAN_AVE + 100, FRONT + 120), Vector2(GARRITY - 100, MARKET + 150), Vector2(ASHBY - 100, FOUNDRY - 120),
			Vector2(WENCESLAS + 100, CANAL_ST - 120)]:
		_prop("props/hydrant", p, 0.0, 6.0)
	_prop("props/call_box", Vector2(GARRITY + 100, MARKET - 150), 0.0, 8.0)
	_prop("props/newsstand", Vector2(HALLORAN_AVE + 150, MARKET + 150), 0.0, Vector2(44, 28))
	for p in [Vector2(900, 440), Vector2(918, 441), Vector2(2500, 1600), Vector2(2520, 1599), Vector2(1700, 1580), Vector2(1100, 1610)]:
		_prop("props/trash_can", p, 0.0, 8.0)
	for y in [FRONT, MARKET, FOUNDRY, CANAL_ST]:
		_barricade_line(Vector2(WEST_EDGE, y), Vector2.DOWN, 4 if y == MARKET else 3)


func _lamps() -> void:
	var cross_x := [WENCESLAS, HALLORAN_AVE, GARRITY, ASHBY]
	# Market Street bright and close; the side streets sparse and dim
	for s in [[FRONT, HALF, 380.0], [MARKET, AVENUE_HALF, 260.0], [FOUNDRY, HALF, 380.0], [CANAL_ST, HALF, 420.0]]:
		for side in [-1.0, 1.0]:
			if s[0] == FRONT and side < 0:
				continue  # (no north pavement on Front Street)
			var y: float = s[0] + side * (s[1] + 10.0)
			var x: float = WEST_EDGE + 120.0 + (0.0 if side < 0 else s[2] * 0.5)
			while x < WIDTH - 60:
				if cross_x.all(func(c: float) -> bool: return absf(x - c) > 150.0):
					d.lamps.append(Vector2(x, y))
				x += s[2]
	for c in cross_x:
		for side in [-1.0, 1.0]:
			var x2: float = c + side * (HALF + 10.0)
			var y2: float = 260.0 + (0.0 if side < 0 else 190.0)
			while y2 < CANAL_ST - 120:
				var clear := [MARKET, FOUNDRY].all(func(c2: float) -> bool: return absf(y2 - c2) > 190.0) \
					and [420.0, 1590.0].all(func(a: float) -> bool: return absf(y2 - a) > 60.0)
				if clear and not d.is_in_building(Vector2(x2, y2), 4.0):
					d.lamps.append(Vector2(x2, y2))
				y2 += 380.0
	for x in range(500, 3200, 420):  # along the quay
		d.lamps.append(Vector2(x, QUAY - 24.0))
	for p in [Vector2(800, 420), Vector2(2000, 1590), Vector2(2700, 420), Vector2(1200, 1590)]:
		d.alley_lamps.append(p)


func _ground_details() -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 1932015
	for p in [Vector2(1000, MARKET + 40), Vector2(2600, FOUNDRY), Vector2(GARRITY, 1100), Vector2(ASHBY, 400), Vector2(800, CANAL_ST)]:
		d.decals.append({"kind": "decals/manhole", "pos": p, "rot": 0.0, "scale": 1.0})
	for p in [Vector2(1000, MARKET + 40), Vector2(GARRITY, 1100), Vector2(800, CANAL_ST)]:
		d.steam_vents.append(p)
	for i in 12:
		d.decals.append({"kind": "decals/puddle", "pos": Vector2(rnd.randf_range(400, 3100), [FRONT, MARKET, FOUNDRY, CANAL_ST][i % 4]
			+ rnd.randf_range(-60, 60)), "rot": rnd.randf_range(-0.4, 0.4), "scale": rnd.randf_range(0.7, 1.3)})
	for i in 10:  # cabbage leaves and paper under the stalls
		d.decals.append({"kind": "decals/litter", "pos": Vector2(rnd.randf_range(700, 3000), MARKET + AVENUE_HALF + rnd.randf_range(4, 40)),
			"rot": rnd.randf_range(-PI, PI), "scale": 1.0})
	for p in [Vector2(1500, FOUNDRY + 40), Vector2(2900, CANAL_ST - 30)]:
		d.decals.append({"kind": "decals/oil", "pos": p, "rot": rnd.randf_range(-PI, PI), "scale": 1.0})


func _people_and_cars() -> void:
	var mkt_n := MARKET - AVENUE_HALF - 23.0
	var mkt_s := MARKET + AVENUE_HALF + 23.0
	# (the south pavement of Market Street is the market's stalls: nobody strolls along it)
	d.walk_routes = [
		PackedVector2Array([Vector2(700, mkt_n), Vector2(2290, mkt_n)]),  # Market Street, north side, to the plaza
		PackedVector2Array([Vector2(700, FOUNDRY + HALF + 23.0), Vector2(2950, FOUNDRY + HALF + 23.0)]),  # Foundry, south side
		PackedVector2Array([Vector2(GARRITY + HALF + 23.0, FRONT + HALF + 30.0), Vector2(GARRITY + HALF + 23.0, CANAL_ST - HALF - 30.0)]),
		PackedVector2Array([Vector2(500, CANAL_ST + HALF + 40.0), Vector2(3000, CANAL_ST + HALF + 40.0)]),  # the quay
		PackedVector2Array([Vector2(700, FOUNDRY - HALF - 23.0), Vector2(2950, FOUNDRY - HALF - 23.0)]),  # Foundry, north side
	]
	d.walkers = [
		{"look": "characters/worker", "route": 0, "at": 0.2},
		{"look": "characters/patron_woman", "route": 0, "at": 0.65},
		{"look": "characters/lady", "route": 1, "at": 0.4},
		{"look": "characters/worker", "route": 2, "at": 0.3},
		{"look": "characters/patron_man", "route": 3, "at": 0.5},
		{"look": "characters/worker", "route": 4, "at": 0.7},
	]
	d.locals = [
		# the night market's last traders
		{"look": "characters/worker", "kind": "stand", "pos": Vector2(1130, mkt_s + 8.0), "face": -PI * 0.5, "hours": [19 * 60 + 30, 23 * 60],
			"lines": ["Hot chestnuts! A nickel a bag!", "Chestnuts, roasted! Warm your hands, mister!"]},
		{"look": "characters/patron_woman", "kind": "stand", "pos": Vector2(2600, mkt_s + 8.0), "face": -PI * 0.5, "hours": [19 * 60 + 30, 22 * 60],
			"lines": ["Pickles! Two for a penny!", "Last of the cabbages, cheap, cheap!"]},
		# a knot outside the Golden Lantern
		{"look": "characters/patron_man", "kind": "stand", "pos": Vector2(2470, mkt_n - 8.0), "face": 0.3, "hours": [21 * 60, 27 * 60],
			"group": "lantern", "lines": ["Best egg foo young this side of the river.", "Mr. Wong don't ask questions. I like that."]},
		{"look": "characters/worker", "kind": "stand", "pos": Vector2(2496, mkt_n - 14.0), "face": 2.8, "hours": [21 * 60, 27 * 60],
			"group": "lantern", "lines": ["The El shakes my teeth loose, I swear.", "Chop suey at two in the morning. Civilization."]},
		# women on St. Casimir's steps after the evening service
		{"look": "characters/lady", "kind": "stand", "pos": Vector2(1800, 470), "face": -0.2, "hours": [19 * 60 + 30, 21 * 60],
			"group": "casimir", "lines": ["Father Wiśniewski preached a long one tonight.", "Pray for my Stanley, he's at the yards again."]},
		{"look": "characters/patron_woman", "kind": "stand", "pos": Vector2(1824, 466), "face": PI + 0.2, "hours": [19 * 60 + 30, 21 * 60],
			"group": "casimir", "lines": ["The fountain froze last winter. Imagine.", "Did you hear? The pawnbroker's got a gun in the window."]},
		# a drunk on the quay, late
		{"look": "characters/patron_man", "kind": "drunk", "route": 3, "at": 0.4, "hours": [23 * 60, 29 * 60],
			"lines": ["The canal goes all the way to the Mississippi, y'know. Hic.", "Sing it with me! ...no?"]},
		# a couple under the El
		{"look": "characters/patron_man", "kind": "stroll", "route": 0, "at": 0.35, "hours": [20 * 60, 24 * 60],
			"lines": ["Let's catch the El downtown Saturday.", "You and me, Rosie. One day."]},
		{"look": "characters/lady", "kind": "stroll", "route": 0, "at": 0.35, "hours": [20 * 60, 24 * 60], "with": 7},
		# a bargeman smoking on the quay
		{"look": "characters/worker", "kind": "stand", "pos": Vector2(1640, QUAY - 14.0), "face": PI * 0.5,
			"lines": ["Coal for the gas works. Every night.", "Canal's quieter than the river. Nobody asks."]},
	]
	d.deliveries = [
		{"vehicle": "bakery_van", "paint": 1, "pos": Vector2(980, FOUNDRY - HALF + 24.0), "rot": 0.0,
			"door": Vector2(900, FOUNDRY - HALF - SW + 10.0), "hours": [22 * 60, 23 * 60],
			"looks": ["characters/worker"], "lines": ["Herring for the hall, two barrels."]},
	]
	var lane := 28.0
	var e := MARKET + 45.0
	var w := MARKET - 45.0
	d.drive_loops = [
		# round the market hall's block: east on Market, south on Halloran Ave, west on Foundry, north on Wenceslas
		PackedVector2Array([Vector2(WENCESLAS + lane, e), Vector2(HALLORAN_AVE - lane, e), Vector2(HALLORAN_AVE - lane, FOUNDRY - lane),
			Vector2(WENCESLAS + lane, FOUNDRY - lane)]),
		# west on Market from Ashby, north on Garrity, east on Front, south on Ashby
		PackedVector2Array([Vector2(ASHBY - lane, w), Vector2(GARRITY + lane, w), Vector2(GARRITY + lane, FRONT + lane),
			Vector2(ASHBY - lane, FRONT + lane)]),
	]
	d.traffic = [
		{"type": "sedan", "paint": 1, "loop": 0, "segment": 0, "at": 0.4},
		{"type": "bakery_van", "paint": 1, "loop": 1, "segment": 0, "at": 0.5},
		{"type": "taxi", "paint": 0, "loop": 1, "segment": 2, "at": 0.3},
	]
	for x in [WENCESLAS, HALLORAN_AVE, GARRITY, ASHBY]:
		for s in [[FRONT, HALF], [MARKET, AVENUE_HALF], [FOUNDRY, HALF], [CANAL_ST, HALF]]:
			d.junctions.append(Rect2(x - HALF, s[0] - s[1], HALF * 2.0, s[1] * 2.0))
	d.cars = [
		{"type": "coupe", "paint": 1, "pos": Vector2(1600, FOUNDRY - 62), "rot": 0.0, "owner": "somebody on Foundry Street"},
		{"type": "bakery_van", "paint": 1, "pos": Vector2(2650, CANAL_ST - 62), "rot": PI, "owner": "the Hradek cooperage"},
		{"type": "sedan", "paint": 0, "pos": Vector2(2200, FRONT + 62), "rot": PI, "owner": "a lodger at the Hotel Bohemia"},
	]
	d.police_beat = PackedVector2Array([Vector2(1550, mkt_n), Vector2(2150, mkt_n)])
	d.police_posts = [{"pos": Vector2(1490, mkt_s), "face": Vector2(1420, MARKET), "from": 20 * 60, "until": 21 * 60,
		"line": "Pushcarts off the street by nine. City ordinance."}]
	d.spawn = Vector2(1800, MARKET + 40.0)


## Where the market's own small troubles happen.
func _incident_spots() -> void:
	d.incident_spots = [
		{"id": "lantern_kerb", "kinds": ["argument"], "pos": Vector2(2650, MARKET - AVENUE_HALF - 23.0), "along": Vector2.RIGHT,
			"local": "", "place": "outside the Golden Lantern"},
		{"id": "hall_kerb", "kinds": ["argument"], "pos": Vector2(1000, MARKET + AVENUE_HALF + 23.0), "along": Vector2.RIGHT,
			"local": "", "place": "outside the market hall"},
		{"id": "canal_alley", "kinds": ["exchange"], "pos": Vector2(1900, 1590), "along": Vector2.RIGHT, "local": "",
			"place": "the alley off Canal Street"},
		{"id": "quay", "kinds": ["exchange"], "pos": Vector2(2300, CANAL_ST + HALF + 40.0), "along": Vector2.RIGHT, "local": "",
			"place": "on the quay"},
		{"id": "market_stop", "kinds": ["stop"], "pos": Vector2(1350, MARKET + AVENUE_HALF + 23.0), "along": Vector2.RIGHT,
			"local": "", "place": "under the El"},
	]
