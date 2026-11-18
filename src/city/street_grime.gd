class_name StreetGrime
extends RefCounted
## M010: the rubbish of a lived-in city, scattered once per district from its
## own streets: newspapers and scraps in the gutters and along the kerbs,
## boxes, bottles, a loose board or a little rubble in the alleys, coal dust,
## soot and debris round the works and on the lots. Industrial districts are
## dirtier (DistrictLayout.grime_level). Visual only - every item is a frame of
## one painted sheet (`decals/grime`) drawn flat on the ground; nothing is
## solid. Kept off doorways, props, lamps, the people Danny can talk to and
## other litter, never inside a building or the river. Pure and deterministic
## (the same district always has the same rubbish).

const SHEET := "decals/grime"
const FRAMES := 12
## Frames: 0 newspaper, 1 folded newspaper, 2 scraps, 3 bottle, 4 broken bottle,
## 5 flattened box, 6 burst box, 7 coal dust, 8 soot, 9 loose board, 10 rubble, 11 stain.
const STREET := [0, 0, 1, 1, 2, 2, 3, 5, 11]
const ALLEY := [2, 3, 4, 5, 6, 6, 9, 10, 11]
const WORKS := [5, 6, 7, 7, 8, 8, 9, 10, 11]
const SPREAD := [7, 8, 11]
## Base size on the ground (world px) of one frame.
const SIZE := 30.0
const GAP := 16.0
## How often (px of kerb, alley or works frontage per item, at grime level 1).
const STREET_EVERY := 72.0
const ALLEY_EVERY := 55.0
const WORKS_EVERY := 60.0
const LOT_AREA := 30000.0
const INDUSTRIAL := ["warehouse", "factory", "stack", "garage"]


## Every item: {frame, pos, rot, scale}.
static func scatter(layout: DistrictLayout) -> Array:
	var level := layout.grime_level
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("grime:" + layout.id) & 0x7fffffff
	var g := _Grid.new(layout)
	var out := []
	# along every street: the gutter and the pavement beside it
	for st in layout.streets:
		var r: Rect2 = st.rect
		var horizontal := r.size.x >= r.size.y
		var length := r.size.x if horizontal else r.size.y
		for side in [-1.0, 1.0]:
			var n := int(length / STREET_EVERY * level)
			for k in n:
				var t := rng.randf_range(0.0, length)
				var out_by := rng.randf_range(-12.0, 40.0)  # negative: in the gutter, positive: on the pavement
				var p: Vector2
				if horizontal:
					var edge := r.position.y if side < 0.0 else r.end.y
					p = Vector2(r.position.x + t, edge + side * out_by)
				else:
					var edge2 := r.position.x if side < 0.0 else r.end.x
					p = Vector2(edge2 + side * out_by, r.position.y + t)
				_try(out, g, rng, p, STREET)
	# in the alleys
	for a in layout.alleys:
		var ar: Rect2 = a.rect
		var horizontal2 := ar.size.x >= ar.size.y
		var length2 := ar.size.x if horizontal2 else ar.size.y
		for k in int(length2 / ALLEY_EVERY * level):
			var t2 := rng.randf_range(0.0, length2)
			var across := rng.randf_range(0.12, 0.88)
			var p2 := Vector2(ar.position.x + t2, ar.position.y + across * ar.size.y) if horizontal2 \
				else Vector2(ar.position.x + across * ar.size.x, ar.position.y + t2)
			_try(out, g, rng, p2, ALLEY)
	# round the works: along their walls
	for b in layout.buildings:
		if not String(b.get("facade", "")) in INDUSTRIAL:
			continue
		var br: Rect2 = b.rect
		var perimeter := (br.size.x + br.size.y) * 2.0
		for k in int(perimeter / WORKS_EVERY * level):
			var t3 := rng.randf_range(0.0, perimeter)
			var p3 := _around(br, t3, rng.randf_range(8.0, 34.0))
			_try(out, g, rng, p3, WORKS)
	# on the yards' lots and forecourts
	for l in layout.lots:
		var lr: Rect2 = l.rect
		if lr.size.x > 2000.0 or lr.size.y > 2000.0:
			continue  # the far bank and other backdrops
		for k in int(lr.get_area() / LOT_AREA * level):
			var p4 := lr.position + Vector2(rng.randf() * lr.size.x, rng.randf() * lr.size.y)
			_try(out, g, rng, p4, WORKS)
	return out


static func _try(out: Array, g: _Grid, rng: RandomNumberGenerator, p: Vector2, frames: Array) -> void:
	var frame: int = frames[rng.randi_range(0, frames.size() - 1)]
	var spread := SPREAD.has(frame)
	var scale := rng.randf_range(1.3, 1.9) if spread else rng.randf_range(0.75, 1.15)
	if not g.is_clear(p, GAP):
		return
	out.append({"frame": frame, "pos": p, "rot": rng.randf_range(-PI, PI), "scale": scale})
	g.taken(p)


## A point `out_by` outside rectangle r, `t` px round its perimeter.
static func _around(r: Rect2, t: float, out_by: float) -> Vector2:
	if t < r.size.x:
		return Vector2(r.position.x + t, r.position.y - out_by)
	t -= r.size.x
	if t < r.size.y:
		return Vector2(r.end.x + out_by, r.position.y + t)
	t -= r.size.y
	if t < r.size.x:
		return Vector2(r.end.x - t, r.end.y + out_by)
	t -= r.size.x
	return Vector2(r.position.x - out_by, r.end.y - t)


## Where litter may not go, in buckets (so the scatter stays well under a millisecond).
class _Grid:
	const CELL := 200.0
	var buildings := {}
	var points := {}
	var bounds: Rect2
	var water: Array

	func _init(layout: DistrictLayout) -> void:
		bounds = layout.play_area
		water = layout.water
		for b in layout.buildings:
			_add_rect(b.rect, (b.rect as Rect2).grow(4.0))
		# keep clear: doorways, street furniture, lamps, the people to talk to and their errands
		for plan in layout.interiors:
			for i in (plan as InteriorPlan).doors.size():
				_block((plan as InteriorPlan).door_centre(i), 34.0)
		for pr in layout.props:
			var reach := 24.0
			if pr.has("box"):
				reach = maxf(reach, (pr.box as Vector2).length() * 0.5 + 8.0)
			elif float(pr.get("radius", 0.0)) > 0.0:
				reach = maxf(reach, float(pr.radius) + 10.0)
			_block(pr.pos, reach)
		for f in layout.fences:  # never on a fence line
			var fa: Vector2 = f[0]
			var fb: Vector2 = f[1]
			var n := maxi(1, ceili(fa.distance_to(fb) / 16.0))
			for k in n + 1:
				_block(fa.lerp(fb, float(k) / n), 14.0)
		for lp in layout.lamps + layout.alley_lamps:
			_block(lp, 14.0)
		for c in layout.contacts + layout.errands:
			_block(c.pos, 36.0)

	func _key(p: Vector2) -> Vector2i:
		return Vector2i(floori(p.x / CELL), floori(p.y / CELL))

	func _add_rect(r: Rect2, grown: Rect2) -> void:
		for x in range(floori(grown.position.x / CELL), floori(grown.end.x / CELL) + 1):
			for y in range(floori(grown.position.y / CELL), floori(grown.end.y / CELL) + 1):
				var k := Vector2i(x, y)
				if not buildings.has(k):
					buildings[k] = []
				buildings[k].append(grown)

	func _block(p: Vector2, radius: float) -> void:
		var k := _key(p)
		if not points.has(k):
			points[k] = []
		points[k].append([p, radius])

	func taken(p: Vector2) -> void:
		_block(p, 0.0)

	func is_clear(p: Vector2, gap: float) -> bool:
		if not bounds.has_point(p):
			return false
		var k := _key(p)
		for r in buildings.get(k, []):
			if (r as Rect2).has_point(p):
				return false
		for w in water:
			if (w as Rect2).grow(6.0).has_point(p):
				return false
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				for e in points.get(k + Vector2i(dx, dy), []):
					if p.distance_to(e[0]) < maxf(gap, float(e[1])):
						return false
		return true
