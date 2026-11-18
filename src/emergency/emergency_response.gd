class_name EmergencyResponse
extends RefCounted
## M010: who comes when something serious happens in the street (the blast at
## Rosie's): a police car first, then the fire engine, then the ambulance,
## each setting off a little after the last, driving in along the street from
## the edge of the district to its own place near the scene, where it stops
## and its crew get out and stay for the rest of the night. No dispatch
## system: one scene, three vehicles, fixed delays, a path each. Pure and
## deterministic: where each vehicle is follows from the time since it set off.

const UNITS := [
	{"id": "police", "look": "cars/police", "size": Vector2(80, 36), "delay": 1.2, "sound": "emergency/siren",
		"crew": ["characters/police", "characters/police"]},
	{"id": "fire", "look": "cars/fire_engine", "size": Vector2(130, 45), "delay": 2.6, "sound": "emergency/bell",
		"crew": ["characters/fireman", "characters/fireman", "characters/fireman"]},
	{"id": "ambulance", "look": "cars/ambulance", "size": Vector2(92, 37), "delay": 3.8, "sound": "emergency/bell",
		"crew": ["characters/attendant", "characters/attendant"]},
]
## Driving speed (px a second), slower for the last stretch to the kerb.
const SPEED := 240.0
const CREEP := 70.0
const CREEP_DISTANCE := 90.0
## Game minutes after the fire engine stops before the fire is out.
const HOSE_MINUTES := 8.0

var night := -1
## The game minute it happened (the delays count from it).
var since := -1.0
var at := Vector2.ZERO
## One per unit: {id, route (PackedVector2Array), length, along, state ("waiting", "driving", "stopped")}.
var units: Array = []
var fire_out := false


func active(p_night: int) -> bool:
	return night == p_night and not units.is_empty()


## Sends them: `routes` id -> the path from the district's edge to its stop.
func dispatch(p_night: int, minute: float, p_at: Vector2, routes: Dictionary) -> void:
	night = p_night
	since = minute
	at = p_at
	fire_out = false
	units.clear()
	for u in UNITS:
		var route: PackedVector2Array = routes[u.id]
		units.append({"id": u.id, "route": route, "length": _length(route), "along": 0.0, "state": "waiting"})


## Advances them: game `minute` for who sets off, `dt` seconds of driving.
## Returns what happened: [{what: "set_off" | "stopped" | "fire_out", id}].
func advance(minute: float, dt: float) -> Array:
	var out := []
	for i in units.size():
		var u: Dictionary = units[i]
		var spec: Dictionary = UNITS[i]
		if u.state == "waiting" and minute >= since + float(spec.delay):
			u.state = "driving"
			out.append({"what": "set_off", "id": u.id})
		if u.state == "driving":
			var left: float = u.length - u.along
			var speed := CREEP if left < CREEP_DISTANCE else SPEED
			u.along = minf(u.length, u.along + speed * dt)
			if u.along >= u.length:
				u.state = "stopped"
				u["stopped_at"] = minute
				out.append({"what": "stopped", "id": u.id})
	var fire := unit("fire")
	if not fire_out and not fire.is_empty() and fire.state == "stopped" and minute >= float(fire.stopped_at) + HOSE_MINUTES:
		fire_out = true
		out.append({"what": "fire_out", "id": "fire"})
	return out


## Everybody already in place (a district built again later that night).
func settle(minute: float) -> void:
	for u in units:
		u.along = u.length
		u.state = "stopped"
		u["stopped_at"] = minute
	fire_out = true


func unit(id: String) -> Dictionary:
	for u in units:
		if u.id == id:
			return u
	return {}


## Where unit i is and which way it faces.
func pose(i: int) -> Dictionary:
	var u: Dictionary = units[i]
	var route: PackedVector2Array = u.route
	var d: float = u.along
	for k in range(1, route.size()):
		var seg := route[k].distance_to(route[k - 1])
		if d <= seg or k == route.size() - 1:
			var t := clampf(d / maxf(seg, 0.001), 0.0, 1.0)
			return {"pos": route[k - 1].lerp(route[k], t), "rot": (route[k] - route[k - 1]).angle()}
		d -= seg
	return {"pos": route[route.size() - 1], "rot": 0.0}


func clear() -> void:
	night = -1
	units.clear()
	fire_out = false


static func _length(route: PackedVector2Array) -> float:
	var t := 0.0
	for k in range(1, route.size()):
		t += route[k].distance_to(route[k - 1])
	return t


## The paths in along a district street: from `approach` (at the district's
## edge, in the lane) along the lane to just past each stop, then in to it.
static func routes_for(approach: Vector2, stops: Dictionary) -> Dictionary:
	var out := {}
	for id in stops:
		var stop: Vector2 = stops[id]
		var dir := signf(stop.x - approach.x)
		# along the lane, ease over to the kerb, and the last few yards straight (stopped square to the street)
		out[id] = PackedVector2Array([approach, Vector2(stop.x - dir * 120.0, approach.y),
			Vector2(stop.x - dir * 30.0, stop.y), stop])
	return out
