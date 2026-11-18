class_name Shadows
extends RefCounted
## M010: the night's shadows, painted once and cheaply rather than cast by every
## light. One light for all of them - the moon, from the north-west, the way
## people and cars have always cast their soft shadows - so every shadow in the
## city falls the same way: buildings throw a soft band from the faces turned
## away from it, fences and street furniture a little one; a street lamp nearby
## fills a shadow in (it is lighter under the lamps). Pure maths, shared by the
## city's shadow layer, the people and the cars, and tests.

## Which way shadows fall (unit vector, screen space: right and down).
const DIR := Vector2(0.55, 0.835)
## A shadow's length per px of height, and the longest a building throws.
const PER_HEIGHT := 0.38
const MAX_LENGTH := 80.0
## How dark a cast shadow is at its foot (alpha), in the dark and right under a lamp.
const ALPHA := 0.5
const UNDER_LAMP := 0.45
## Within this of a street lamp a shadow is filled in.
const LAMP_FILL := 190.0
const CELL := 200.0


static func length_for(height: float) -> float:
	return minf(MAX_LENGTH, height * PER_HEIGHT)


## The quads a box standing on the ground casts: one for each face turned away
## from the light (DIR points right and down, so the right and bottom faces),
## each [foot a, foot b, tip b, tip a]; the two share the corner's edge.
static func cast_quads(r: Rect2, length: float) -> Array[PackedVector2Array]:
	var d := DIR * length
	var tr := Vector2(r.end.x, r.position.y)
	var br := r.end
	var bl := Vector2(r.position.x, r.end.y)
	return [PackedVector2Array([tr, br, br + d, tr + d]), PackedVector2Array([br, bl, bl + d, br + d])]


## The street lamps in buckets, for `fill`.
static func lamp_grid(lamps: Array) -> Dictionary:
	var grid := {}
	for p in lamps:
		var key := Vector2i(floori(p.x / CELL), floori(p.y / CELL))
		if not grid.has(key):
			grid[key] = []
		grid[key].append(p)
	return grid


## How much of a shadow is left at p: 1 in the dark, down to UNDER_LAMP right
## under a street lamp.
static func fill(p: Vector2, grid: Dictionary) -> float:
	var c := Vector2i(floori(p.x / CELL), floori(p.y / CELL))
	var nearest := INF
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			for q in grid.get(c + Vector2i(dx, dy), []):
				nearest = minf(nearest, p.distance_to(q))
	if nearest >= LAMP_FILL:
		return 1.0
	return lerpf(UNDER_LAMP, 1.0, nearest / LAMP_FILL)


## A district's ground shadows as triangles [vertices, colours], made once (at
## start-up, with the district's other data) and drawn as one mesh: the soft
## band round every building's foot, the shadows cast from the buildings' faces
## turned away from the light (not where they would only fall under the next
## building's roof, nor into a room you can walk into) and from the fences;
## each lighter near the street lamps.
static func ground(layout: DistrictLayout) -> Array:
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	var dark := Color(0.0, 0.0, 0.02, 0.55)
	var clear := Color(0.0, 0.0, 0.02, 0.0)
	for b in layout.buildings:
		var r: Rect2 = b.rect
		var c := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
		var g := r.grow(18.0)
		var o := [g.position, Vector2(g.end.x, g.position.y), g.end, Vector2(g.position.x, g.end.y)]
		for i in 4:
			var j := (i + 1) % 4
			_quad(verts, cols, [c[i], c[j], o[j], o[i]], [dark, dark, clear, clear])
	var lamps := lamp_grid(layout.lamps + layout.alley_lamps)
	var roofs := {}
	for b in layout.buildings:
		var r2: Rect2 = b.rect
		for x in range(floori(r2.position.x / CELL), floori(r2.end.x / CELL) + 1):
			for y in range(floori(r2.position.y / CELL), floori(r2.end.y / CELL) + 1):
				if not roofs.has(Vector2i(x, y)):
					roofs[Vector2i(x, y)] = []
				roofs[Vector2i(x, y)].append(r2)
	var rooms: Array[Rect2] = []
	for plan in layout.interiors:
		rooms.append(layout.buildings[(plan as InteriorPlan).building].rect)
	for b in layout.buildings:
		for q in cast_quads(b.rect, length_for(layout.building_height(b))):
			_band(verts, cols, q[0], q[1], q[3] - q[0], lamps, roofs, rooms, b.rect)
	for f in layout.fences:
		_band(verts, cols, f[0], f[1], DIR * 14.0, lamps, roofs, rooms, Rect2())
	return [verts, cols]


static func _band(verts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, out: Vector2, lamps: Dictionary,
		roofs: Dictionary, rooms: Array[Rect2], own: Rect2) -> void:
	var n := maxi(1, ceili(a.distance_to(b) / 80.0))
	var clear := Color(0, 0, 0.03, 0.0)
	for k in n:
		var p0 := a.lerp(b, float(k) / n)
		var p1 := a.lerp(b, float(k + 1) / n)
		var mid := (p0 + p1) * 0.5
		if _under_roof(mid + out.normalized() * 4.0, own, roofs) or rooms.any(func(r: Rect2) -> bool: return r.has_point(mid + out)):
			continue
		_quad(verts, cols, [p0, p1, p1 + out, p0 + out],
			[Color(0, 0, 0.03, ALPHA * fill(p0, lamps)), Color(0, 0, 0.03, ALPHA * fill(p1, lamps)), clear, clear])


static func _under_roof(p: Vector2, own: Rect2, roofs: Dictionary) -> bool:
	for r in roofs.get(Vector2i(floori(p.x / CELL), floori(p.y / CELL)), []):
		if r != own and (r as Rect2).has_point(p):
			return true
	return false


static func _quad(verts: PackedVector2Array, cols: PackedColorArray, p: Array, c: Array) -> void:
	for i in [0, 1, 2, 0, 2, 3]:
		verts.append(p[i])
		cols.append(c[i])


## The triangles as a mesh to draw in one call.
static func mesh_of(tris: Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if (tris[0] as PackedVector2Array).is_empty():
		return mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = tris[0]
	arrays[Mesh.ARRAY_COLOR] = tris[1]
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
