class_name InteriorPlan
extends RefCounted
## A room you can walk into, as plain data with its geometry rules (pure, no
## scene): the room inside a building's footprint, doors in its outer walls,
## inner walls with doorways, furniture (some of it solid), lamps, the people
## who work there and the spots where E does something. The rest of the
## building stays solid. InteriorView draws it; Interiors builds its walls.
## The same plan describes a supper club, a barbershop or a one-room flat.

## Thickness of every wall (px).
const WALL := 8.0

var id := ""
## Shown on the HUD while you are inside ("The Copper Owl").
var name := ""
## Index of the building in DistrictLayout.buildings.
var building := -1
var building_rect := Rect2()
## The walkable room, walls included (inside building_rect).
var room := Rect2()
## Floor tile (logical image name) and the colour of the closed rest of the house.
var floor := "interiors/floor_parquet"
## Doors in the room's outer walls: {side: Vector2 (outward: UP, DOWN, LEFT,
## RIGHT), at: float (x of the door's centre on an UP / DOWN wall, y on a
## LEFT / RIGHT wall), width: float}.
var doors: Array = []
## Inner walls along axis-aligned lines: {a: Vector2, b: Vector2, door_at:
## float (NAN = no doorway), door_width: float}.
var partitions: Array = []
## Furniture: {kind, pos, rot, box: Vector2 (solid) | radius: float (solid) | neither}.
var furniture: Array = []
## Lamps: {pos, color: Color, energy: float, radius: float}.
var lamps: Array = []
## People who are always here: {id, look (sheet logical name), pos, facing, name}.
var people: Array = []
## Places where E does something: {id, pos, radius, prompt}.
var spots: Array = []


func _init(p_id: String = "", p_name: String = "") -> void:
	id = p_id
	name = p_name


## True when p is inside the room (its walls included).
func contains(p: Vector2, margin: float = 0.0) -> bool:
	return room.grow(margin).has_point(p)


## Solid wall pieces: the room's outer walls with their door gaps, and the
## inner walls with their doorways.
func wall_boxes() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var r := room
	var edges := [
		[Vector2.UP, Rect2(r.position.x, r.position.y, r.size.x, WALL)],
		[Vector2.DOWN, Rect2(r.position.x, r.end.y - WALL, r.size.x, WALL)],
		[Vector2.LEFT, Rect2(r.position.x, r.position.y, WALL, r.size.y)],
		[Vector2.RIGHT, Rect2(r.end.x - WALL, r.position.y, WALL, r.size.y)],
	]
	for e in edges:
		var side: Vector2 = e[0]
		var gaps := []
		for d in doors:
			if d.side == side:
				gaps.append([float(d.at) - float(d.width) * 0.5, float(d.at) + float(d.width) * 0.5])
		out.append_array(_split(e[1], side.x == 0.0, gaps))
	for p in partitions:
		var a: Vector2 = p.a
		var b: Vector2 = p.b
		var horizontal := absf(a.y - b.y) < 0.01
		var box := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(WALL, WALL) * 0.5,
			(b - a).abs() + Vector2(WALL, WALL))
		var gaps2 := []
		var at: float = p.get("door_at", NAN)
		if not is_nan(at):
			var w: float = p.get("door_width", 28.0)
			gaps2.append([at - w * 0.5, at + w * 0.5])
		out.append_array(_split(box, horizontal, gaps2))
	return out


## Everything solid about the building: the house outside the room, the
## walls, and the solid furniture boxes (axis-aligned only; round and turned
## furniture is left to the caller).
func solid_boxes() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var b := building_rect
	var r := room
	if r.position.y > b.position.y:
		out.append(Rect2(b.position.x, b.position.y, b.size.x, r.position.y - b.position.y))
	if r.end.y < b.end.y:
		out.append(Rect2(b.position.x, r.end.y, b.size.x, b.end.y - r.end.y))
	if r.position.x > b.position.x:
		out.append(Rect2(b.position.x, r.position.y, r.position.x - b.position.x, r.size.y))
	if r.end.x < b.end.x:
		out.append(Rect2(r.end.x, r.position.y, b.end.x - r.end.x, r.size.y))
	out.append_array(wall_boxes())
	return out


## Centre of door i in its wall.
func door_centre(i: int) -> Vector2:
	var d: Dictionary = doors[i]
	var side: Vector2 = d.side
	match side:
		Vector2.UP:
			return Vector2(d.at, room.position.y + WALL * 0.5)
		Vector2.DOWN:
			return Vector2(d.at, room.end.y - WALL * 0.5)
		Vector2.LEFT:
			return Vector2(room.position.x + WALL * 0.5, d.at)
	return Vector2(room.end.x - WALL * 0.5, d.at)


## A point `dist` px outside door i (in the street, the alley...).
func outside_door(i: int, dist: float = 24.0) -> Vector2:
	return door_centre(i) + (doors[i].side as Vector2) * (WALL * 0.5 + dist)


## A point `dist` px inside door i.
func inside_door(i: int, dist: float = 24.0) -> Vector2:
	return door_centre(i) - (doors[i].side as Vector2) * (WALL * 0.5 + dist)


## The interaction spot nearest to p within its radius, or {}.
func spot_at(p: Vector2) -> Dictionary:
	var best := {}
	var best_d := INF
	for s in spots:
		var dist := p.distance_to(s.pos)
		if dist <= float(s.radius) and dist < best_d:
			best = s
			best_d = dist
	return best


func person(person_id: String) -> Dictionary:
	for p in people:
		if p.id == person_id:
			return p
	return {}


## Splits a wall box along its length round the gaps ([from, to] along x for
## a horizontal wall, along y for a vertical one).
static func _split(box: Rect2, horizontal: bool, gaps: Array) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var start := box.position.x if horizontal else box.position.y
	var end := box.end.x if horizontal else box.end.y
	gaps.sort_custom(func(g1: Array, g2: Array) -> bool: return g1[0] < g2[0])
	var cursor := start
	for g in gaps + [[end, end]]:
		var g0 := clampf(g[0], start, end)
		if g0 > cursor + 0.01:
			if horizontal:
				out.append(Rect2(cursor, box.position.y, g0 - cursor, box.size.y))
			else:
				out.append(Rect2(box.position.x, cursor, box.size.x, g0 - cursor))
		cursor = maxf(cursor, clampf(g[1], start, end))
	return out
