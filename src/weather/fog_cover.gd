class_name FogCover
extends RefCounted
## M010: where street fog can lie - the district's open ground (streets,
## pavements, alleys, yards and lots), not the inside of its buildings - as
## triangles in world coordinates, made once at start-up. The fog is drawn only
## over these: it stays between the buildings (under their walls and roofs,
## never in a room), and a frame fills only the pixels that can show it.
## Rows of 48 px cells, merged into runs; a cell is open unless a building
## covers it entirely (fog under a wall's edge is hidden by the wall).

const CELL := 48.0


static func of(layout: DistrictLayout) -> PackedVector2Array:
	var tris := PackedVector2Array()
	var area := layout.play_area
	var grid := {}
	for b in layout.buildings:
		var r: Rect2 = b.rect
		for x in range(floori(r.position.x / 200.0), floori(r.end.x / 200.0) + 1):
			for y in range(floori(r.position.y / 200.0), floori(r.end.y / 200.0) + 1):
				if not grid.has(Vector2i(x, y)):
					grid[Vector2i(x, y)] = []
				grid[Vector2i(x, y)].append(r)
	var y := area.position.y
	while y < area.end.y:
		var run_start := NAN
		var x := area.position.x
		while x < area.end.x:
			var open := not _covered(Rect2(x, y, CELL, CELL), grid)
			if open and is_nan(run_start):
				run_start = x
			elif not open and not is_nan(run_start):
				_quad(tris, Rect2(run_start, y, x - run_start, CELL))
				run_start = NAN
			x += CELL
		if not is_nan(run_start):  # open to the district's edge
			_quad(tris, Rect2(run_start, y, x - run_start, CELL))
		y += CELL
	return tris


static func _covered(cell: Rect2, grid: Dictionary) -> bool:
	var c := cell.get_center()
	for r in grid.get(Vector2i(floori(c.x / 200.0), floori(c.y / 200.0)), []):
		if (r as Rect2).encloses(cell):
			return true
	return false


static func _quad(tris: PackedVector2Array, r: Rect2) -> void:
	var a := r.position
	var b := Vector2(r.end.x, r.position.y)
	var c := r.end
	var d := Vector2(r.position.x, r.end.y)
	tris.append_array(PackedVector2Array([a, b, c, a, c, d]))
