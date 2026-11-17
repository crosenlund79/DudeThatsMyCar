class_name CityNavigator
extends RefCounted
## Routes on foot through the district: a grid over the play area in which
## buildings, the river and the street barricades (grown by a person's
## clearance) are blocked; Godot's AStarGrid2D finds the way, then the route is
## straightened wherever a person could walk directly. Pure (no scene), built
## once from the DistrictLayout. Small street furniture (lamp posts, ash cans,
## crates) and parked cars are not in the grid: on a 20 px grid they would close
## alleys a person fits through, so whoever follows a route slides round them.

const CELL := 20.0

var layout: DistrictLayout
var clearance := 12.0
var grid := AStarGrid2D.new()


func _init(p_layout: DistrictLayout, p_clearance: float = 12.0) -> void:
	layout = p_layout
	clearance = p_clearance
	var play := layout.play_area
	grid.region = Rect2i(Vector2i(floori(play.position.x / CELL), floori(play.position.y / CELL)),
		Vector2i(ceili(play.size.x / CELL) + 1, ceili(play.size.y / CELL) + 1))
	grid.cell_size = Vector2(CELL, CELL)
	grid.offset = Vector2(CELL, CELL) * 0.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.update()
	for b in layout.buildings:
		_block((b.rect as Rect2).grow(clearance))
	for w in layout.water:
		_block((w as Rect2).grow(clearance))
	for p in layout.props:
		if p.kind == "props/barricade":
			var half: Vector2 = (p.box as Vector2).rotated(p.rot).abs() * 0.5
			_block(Rect2(p.pos - half, half * 2.0).grow(clearance))


func _block(r: Rect2) -> void:
	var from := cell_of(r.position)
	var to := cell_of(r.end)
	for x in range(from.x, to.x + 1):
		for y in range(from.y, to.y + 1):
			var c := Vector2i(x, y)
			if grid.is_in_boundsv(c) and r.has_point(centre_of(c)):
				grid.set_point_solid(c, true)


func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.y / CELL))


func centre_of(c: Vector2i) -> Vector2:
	return Vector2(c) * CELL + Vector2(CELL, CELL) * 0.5


func is_open(p: Vector2) -> bool:
	var c := cell_of(p)
	return grid.is_in_boundsv(c) and not grid.is_point_solid(c)


## The nearest open cell to p (spiralling outwards), or p's own cell.
func nearest_open(p: Vector2) -> Vector2i:
	var c := cell_of(p)
	if grid.is_in_boundsv(c) and not grid.is_point_solid(c):
		return c
	for r in range(1, 30):
		var best := Vector2i(-99999, -99999)
		var best_d := INF
		for dx in range(-r, r + 1):
			for dy in [-r, r]:
				for cand in [c + Vector2i(dx, dy), c + Vector2i(dy, dx)]:
					if grid.is_in_boundsv(cand) and not grid.is_point_solid(cand):
						var d := centre_of(cand).distance_squared_to(p)
						if d < best_d:
							best_d = d
							best = cand
		if best_d < INF:
			return best
	return c


## True when a person could walk straight from a to b (no blocked cell on the way).
func clear_line(a: Vector2, b: Vector2) -> bool:
	var steps := maxi(1, int(a.distance_to(b) / (CELL * 0.4)))
	for i in steps + 1:
		if not is_open(a.lerp(b, float(i) / steps)):
			return false
	return true


## True when a person fits at p (outside the buildings and the river, with a
## little less room than the grid keeps): a goal close to a wall is still
## reached exactly, even though its grid cell is closed.
func reachable(p: Vector2) -> bool:
	var margin := maxf(clearance - 4.0, 0.0)
	return layout.play_area.has_point(p) and not layout.is_in_building(p, margin) and not layout.is_in_water(p, margin)


## A walking route from `from` to `to`: corner points to head for, ending at
## `to` (or the nearest open point to it). Empty when there is no way.
func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := nearest_open(from)
	var b := nearest_open(to)
	var goal := to if is_open(to) or reachable(to) else centre_of(b)
	if clear_line(from, goal):
		return PackedVector2Array([goal])
	var cells := grid.get_id_path(a, b)
	if cells.is_empty():
		return PackedVector2Array()
	var raw := PackedVector2Array()
	for c in cells:
		raw.append(centre_of(c))
	raw[raw.size() - 1] = goal
	# straighten: from each corner, jump to the furthest point still in sight
	var out := PackedVector2Array()
	var here := from
	var i := 0
	while i < raw.size():
		var j := raw.size() - 1
		while j > i and not clear_line(here, raw[j]):
			j -= 1
		out.append(raw[j])
		here = raw[j]
		i = j + 1
	return out
