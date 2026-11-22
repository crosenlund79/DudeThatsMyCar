class_name CityLocations
extends RefCounted
## M014: the places the game refers to by name, across every district, by one
## kind of stable id - "<district>/<kind>/<name>" - instead of positions
## written into code. Built from the districts' layouts (plain data, in world
## coordinates once a district is placed), so it follows a district wherever it
## is placed and whatever is built: nothing here is a scene. Ids:
##   <d>/place/<name>          a district's named places (DistrictLayout.places)
##   <d>/spawn                 where a night begins (the ward: Danny's flat)
##   <d>/room/<room>           a room's middle (InteriorPlan.room)
##   <d>/door/<room>/<n>       just outside a room's door n (24 px out)
##   <d>/spot/<room>/<spot>    a room's E spot (talk, bed, table...)
##   <d>/contact/<id>          a contact in the street (M009)
##   <d>/errand/<id>           an errand's place (M009)
##   <d>/cafe/<id>             the cafe job's places (M010)
##   <d>/incident/<id>         an incident spot (M009)
##   <d>/parking/<n>           a parked car's place (its lasting name: Fleet)

var _at := {}
var _facing := {}


## The index of `layouts` (DistrictLayout, placed).
static func of(layouts: Array) -> CityLocations:
	var out := CityLocations.new()
	for l in layouts:
		out.add_district(l)
	return out


func add_district(l: DistrictLayout) -> void:
	var d := l.id
	for name in l.places:
		_put("%s/place/%s" % [d, name], l.places[name])
	_put(d + "/spawn", l.spawn, l.spawn_facing)
	for p in l.interiors:
		var plan: InteriorPlan = p
		_put("%s/room/%s" % [d, plan.id], plan.room.get_center())
		for i in plan.doors.size():
			_put("%s/door/%s/%d" % [d, plan.id, i], plan.outside_door(i))
		for s in plan.spots:
			_put("%s/spot/%s/%s" % [d, plan.id, s.id], s.pos)
	for c in l.contacts:
		_put("%s/contact/%s" % [d, c.id], c.pos, float(c.get("face", 0.0)))
	for e in l.errands:
		_put("%s/errand/%s" % [d, e.id], e.pos)
	for c in l.cafe:
		_put("%s/cafe/%s" % [d, c.id], c.pos, float(c.get("rot", 0.0)))
	for s in l.incident_spots:
		_put("%s/incident/%s" % [d, s.id], s.pos)
	for j in l.cars.size():
		_put("%s/parking/%d" % [d, j], l.cars[j].pos, float(l.cars[j].rot))


func _put(id: String, pos: Vector2, facing: float = 0.0) -> void:
	if _at.has(id):
		push_warning("CityLocations: two places with the id " + id)
		return  # the first one stands
	_at[id] = pos
	_facing[id] = facing


func has(id: String) -> bool:
	return _at.has(id)


## The world position of `id` (Vector2.INF when there is no such place).
func at(id: String) -> Vector2:
	return _at.get(id, Vector2.INF)


## Which way a place faces (a contact, a parked car, a spawn; 0 when it has no facing).
func facing(id: String) -> float:
	return float(_facing.get(id, 0.0))


## The district a place belongs to.
static func district_of(id: String) -> String:
	return id.get_slice("/", 0)


## Every id (optionally only those starting with `prefix`), sorted.
func ids(prefix: String = "") -> Array:
	var out := _at.keys().filter(func(k: String) -> bool: return k.begins_with(prefix))
	out.sort()
	return out
