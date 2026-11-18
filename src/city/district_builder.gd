class_name DistrictBuilder
extends RefCounted
## What every hand-made district is drawn up with (M008: shared by the
## Riverside Ward and its neighbours): buildings in rows and columns, rooftop
## furniture, signs, street furniture and barricades, into a DistrictLayout `d`.

var d := DistrictLayout.new()


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
		if b.facade in ["brick_red", "greystone", "tenement"] and rnd.randf() < 0.35:
			kinds.append("roof/laundry")
		for k in clampi(int(r.size.x / 55.0), 2, 6):
			kinds.append("roof/chimney")
		for k in rnd.randi_range(2, 5):
			kinds.append("roof/vent")
		if b.facade in ["brick_red", "greystone", "tenement"] and rnd.randf() < 0.5:
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


func _prop(kind: String, pos: Vector2, rot: float = 0.0, solid: Variant = 0.0, height: float = 0.0) -> void:
	var p := {"kind": kind, "pos": pos, "rot": rot, "height": height}
	if solid is Vector2:
		p["box"] = solid
	elif float(solid) > 0.0:
		p["radius"] = float(solid)
	d.props.append(p)


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
