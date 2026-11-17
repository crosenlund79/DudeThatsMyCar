class_name PedestrianBrain
extends RefCounted
## One person out late (pure, deterministic for a seed): strolls along a
## sidewalk route and back, stops now and then, steps out of the way of a car
## coming at them and watches it go by, runs from gunfire, then wanders back
## to the route. Never knows more than what is in front of them.

enum State { WALK, PAUSE, DODGE, WATCH, FLEE, RETURN }

const STROLL := 46.0
const RUN := 125.0
## A car is a threat when it will pass closer than this (px) within LOOKAHEAD s.
const NEAR_MISS := 48.0
const LOOKAHEAD := 1.6
const THREAT_SPEED := 45.0
## Gunfire closer than this sends them running.
const SCARE_RANGE := 650.0

var route := PackedVector2Array()
## Next route point, and which way along the route they walk.
var index := 1
var dir := 1
var state := State.WALK
var timer := 0.0
## Dodge / flee direction and what they keep an eye on.
var away := Vector2.ZERO
var watch := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func _init(p_route: PackedVector2Array, seed: int = 0) -> void:
	route = p_route
	_rng.seed = seed
	index = mini(1, route.size() - 1)


## A shot at `at`; they run if it was close enough.
func hear_gunshot(me: Vector2, at: Vector2) -> bool:
	if me.distance_to(at) > SCARE_RANGE:
		return false
	state = State.FLEE
	away = (me - at).normalized() if me.distance_to(at) > 1.0 else Vector2.RIGHT
	watch = at
	timer = _rng.randf_range(2.5, 3.5)
	return true


## The car (pos, vel) most likely to run them down soon, as the point of
## closest approach relative to `me`; Vector2.INF when none.
static func threat(me: Vector2, cars: Array) -> Vector2:
	var best := Vector2.INF
	var best_t := INF
	for c in cars:
		var v: Vector2 = c.vel
		var speed2 := v.length_squared()
		if speed2 < THREAT_SPEED * THREAT_SPEED:
			continue
		var rel: Vector2 = me - (c.pos as Vector2)
		var t := rel.dot(v) / speed2
		if t <= 0.0 or t > LOOKAHEAD:
			continue
		var miss := rel - v * t
		if miss.length() < NEAR_MISS and t < best_t:
			best_t = t
			best = miss if miss.length() > 0.5 else v.orthogonal().normalized()
	return best


## One tick. cars: [{pos, vel}]. Returns {dir: Vector2 (unit or zero), speed, look: Vector2}.
func update(dt: float, me: Vector2, cars: Array) -> Dictionary:
	timer -= dt
	if state != State.FLEE and state != State.DODGE:
		var miss := threat(me, cars)
		if miss != Vector2.INF:
			state = State.DODGE
			away = miss.normalized()
			timer = 0.7
			for c in cars:
				if (c.vel as Vector2).length() >= THREAT_SPEED:
					watch = c.pos
	match state:
		State.DODGE:
			if timer <= 0.0:
				state = State.WATCH
				timer = 0.9
			return {"dir": away, "speed": RUN, "look": watch}
		State.WATCH:
			if timer <= 0.0:
				state = State.RETURN
			return {"dir": Vector2.ZERO, "speed": 0.0, "look": watch}
		State.FLEE:
			if timer <= 0.0:
				state = State.RETURN
			return {"dir": away, "speed": RUN, "look": me + away * 50.0}
		State.PAUSE:
			if timer <= 0.0:
				state = State.WALK
			return {"dir": Vector2.ZERO, "speed": 0.0, "look": watch}
		State.RETURN:
			var back := nearest_on_route(me)
			if me.distance_to(back) < 8.0:
				state = State.WALK
			else:
				return {"dir": (back - me).normalized(), "speed": STROLL, "look": back}
	return _walk(me)


func _walk(me: Vector2) -> Dictionary:
	if route.size() < 2:
		return {"dir": Vector2.ZERO, "speed": 0.0, "look": me}
	var target := route[index]
	if me.distance_to(target) < 6.0:
		var next := index + dir
		if next < 0 or next >= route.size():
			dir = -dir
			next = index + dir
			_pause(me, target + (target - route[next]) * 0.2, _rng.randf_range(1.0, 2.5))
		index = next
		target = route[index]
	elif _rng.randf() < 0.0015:  # now and then: a look in a shop window
		_pause(me, me + (target - me).orthogonal(), _rng.randf_range(1.5, 3.0))
	return {"dir": (target - me).normalized(), "speed": STROLL, "look": target}


func _pause(_me: Vector2, look_at: Vector2, seconds: float) -> void:
	state = State.PAUSE
	timer = seconds
	watch = look_at


## The closest point on the route to p (to walk back to); sets the next point.
func nearest_on_route(p: Vector2) -> Vector2:
	var best := route[0]
	var best_d := INF
	for i in range(route.size() - 1):
		var q := Geometry2D.get_closest_point_to_segment(p, route[i], route[i + 1])
		var dist := p.distance_to(q)
		if dist < best_d:
			best_d = dist
			best = q
			index = i + 1 if dir > 0 else i
	return best
