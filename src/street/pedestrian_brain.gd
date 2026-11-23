class_name PedestrianBrain
extends RefCounted
## One person out late (pure, deterministic for a seed): strolls along a
## sidewalk route and back, stops now and then, steps out of the way of a car
## coming at them and watches it go by, runs from gunfire, then wanders back
## to the route. Never knows more than what is in front of them. M015: a gun
## in Danny's hand makes them wary - they walk briskly away along their route,
## an eye on him - and they run if he comes too close with it (GunSight).
## M015: a car is seen coming sooner the faster it comes; they take a moment
## to react (so a sudden swerve can still catch somebody), then get out of its
## line sideways - towards the kerb if they can - and throw themselves clear
## at the last moment. A car that keeps coming for them (it turned after them)
## gets a cut back the other way, behind its turn, and then they run for it:
## nobody is run down in a straight line after a long chase.

enum State { WALK, PAUSE, DODGE, WATCH, FLEE, RETURN, WARY }

const STROLL := 46.0
const RUN := 125.0
## A car is a threat when it will pass closer than this (px) within LOOKAHEAD s.
## M015: both grow with the car's speed (look_ahead(), near_miss()).
const NEAR_MISS := 48.0
const LOOKAHEAD := 1.6
const THREAT_SPEED := 45.0
## M015: the lookahead at a crawl, how much more each px/s brings, and its most (s).
const LOOK_MIN := 1.1
const LOOK_PER_SPEED := 1.0 / 220.0
const LOOK_MAX := 2.8
## M015: how long it takes to see a car is coming at them before they move (s).
## (Tuned against a car steering straight at them: tests/unit/test_pedestrian_dodging.gd.)
const REACT := 0.15
## M015: within this many seconds of the car they throw themselves clear (DIVE px/s).
const DIVE_T := 0.7
const DIVE := 195.0
## M015: a car still coming for them this soon after they got out of its way is
## chasing them; within JUKE_T of it they cut back behind its turn.
const CHASE_MEMORY := 3.0
const JUKE_T := 0.5
## M015: a car that has turned this much after them while they got out of its way is chasing them (rad).
const CHASE_TURN := 0.12
## Gunfire closer than this sends them running.
const SCARE_RANGE := 650.0
## M015: the pace of someone keeping their distance from a gun.
const BRISK := 85.0

var route := PackedVector2Array()
## Next route point, and which way along the route they walk.
var index := 1
var dir := 1
var state := State.WALK
var timer := 0.0
## Dodge / flee direction and what they keep an eye on.
var away := Vector2.ZERO
var watch := Vector2.ZERO
## M015: how many times a car has come at them again since they got out of
## its way (0: once, by chance), which side of its line they are getting to
## (+1 / -1 of its velocity's orthogonal), whether they have cut back yet.
var chased := 0
var side := 0
var juked := false
var _seen := 0.0
var _since_dodge := INF
var _threat_vel := Vector2.ZERO
var _turned := 0.0
var _wall_turned := false
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


## M015: something frightening happened at `at` within `radius` (a car
## knocked somebody down): they run from it for `seconds` (a little longer each).
func scare(me: Vector2, at: Vector2, radius: float, seconds := 3.0) -> bool:
	if me.distance_to(at) > radius:
		return false
	state = State.FLEE
	away = (me - at).normalized() if me.distance_to(at) > 1.0 else Vector2.RIGHT
	watch = at
	timer = seconds + _rng.randf_range(0.0, 1.0)
	return true


## The car (pos, vel) most likely to run them down soon, as the point of
## closest approach relative to `me`; Vector2.INF when none.
static func threat(me: Vector2, cars: Array) -> Vector2:
	var d := danger(me, cars)
	if d.is_empty():
		return Vector2.INF
	var miss: Vector2 = d.miss
	return miss if miss.length() > 0.5 else (d.vel as Vector2).orthogonal().normalized()


## M015: how far ahead (s) a car going `speed` px/s is watched: a fast one is
## seen coming sooner.
static func look_ahead(speed: float) -> float:
	return clampf(LOOK_MIN + speed * LOOK_PER_SPEED, LOOK_MIN, LOOK_MAX)


## M015: how close a car going `speed` may pass before it is a threat.
static func near_miss(speed: float) -> float:
	return NEAR_MISS + speed * 0.05


## M015: the car most likely to run them down soon: {pos, vel, t (s to its
## closest approach), miss (that point relative to them)}; {} when none.
static func danger(me: Vector2, cars: Array) -> Dictionary:
	var best := {}
	var best_t := INF
	for c in cars:
		var v: Vector2 = c.vel
		var speed2 := v.length_squared()
		if speed2 < THREAT_SPEED * THREAT_SPEED:
			continue
		var speed := sqrt(speed2)
		var rel: Vector2 = me - (c.pos as Vector2)
		var t := rel.dot(v) / speed2
		if t <= 0.0 or t > look_ahead(speed):
			continue
		var miss := rel - v * t
		if miss.length() < near_miss(speed) and t < best_t:
			best_t = t
			best = {"pos": c.pos, "vel": v, "t": t, "miss": miss}
	return best


## One tick. cars: [{pos, vel}]; M015 `danny`: {pos, level} - the gun he has
## out where they can see it (level 0: none). Returns {dir: Vector2 (unit or
## zero), speed, look: Vector2}.
func update(dt: float, me: Vector2, cars: Array, danny: Dictionary = {}) -> Dictionary:
	timer -= dt
	var level := int(danny.get("level", 0))
	var dp: Vector2 = danny.get("pos", Vector2.INF)
	if level > 0 and state != State.FLEE and state != State.DODGE:
		match GunSight.passer(me.distance_to(dp), level):
			"flee":
				state = State.FLEE
				away = (me - dp).normalized() if me.distance_to(dp) > 1.0 else Vector2.RIGHT
				watch = dp
				timer = _rng.randf_range(2.0, 3.0)
			"wary":
				state = State.WARY
	_since_dodge += dt
	var d := danger(me, cars)
	_seen = _seen + dt if not d.is_empty() else 0.0
	if not d.is_empty() and (_seen >= REACT or state == State.DODGE):
		_dodge(me, d)
	match state:
		State.DODGE:
			if timer <= 0.0:
				_since_dodge = 0.0
				if chased > 0:  # it came after them: they run for it, away from the car
					state = State.FLEE
					away = (me - watch).normalized() if me.distance_to(watch) > 1.0 else away
					timer = _rng.randf_range(1.5, 2.2)
				else:
					state = State.WATCH
					timer = 0.9
			else:
				var dive := not d.is_empty() and float(d.t) < DIVE_T
				return {"dir": away, "speed": DIVE if dive else RUN, "look": watch}
		State.WATCH:
			if timer <= 0.0:
				state = State.RETURN
			return {"dir": Vector2.ZERO, "speed": 0.0, "look": watch}
		State.FLEE:
			if timer <= 0.0:
				state = State.RETURN
			return {"dir": away, "speed": RUN, "look": me + away * 50.0}
		State.WARY:
			if GunSight.passer(me.distance_to(dp), level) == "":
				state = State.RETURN
			else:
				return {"dir": _away_along_route(me, dp), "speed": BRISK, "look": dp}
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


## M015: out of the way of the car in `d`: sideways off its line - the side
## they are already on, or towards the kerb (their route) when it comes
## straight at them. A fresh dodge soon after the last means the car is after
## them; once it is close and still turning their way, they cut back the
## other way, behind its turn (once a dodge).
func _dodge(me: Vector2, d: Dictionary) -> void:
	var v: Vector2 = d.vel
	var perp := v.orthogonal().normalized()
	var miss: Vector2 = d.miss
	var on := 0
	if miss.length() > 6.0:
		on = 1 if perp.dot(miss) > 0.0 else -1
	if state != State.DODGE:
		chased = chased + 1 if _since_dodge < CHASE_MEMORY else 0
		side = on if on != 0 else _kerb_side(me, perp)
		juked = false
		_wall_turned = false
		_turned = 0.0
		_threat_vel = v
	else:
		# how far the car's course swung towards the way they are running (+) or away
		var after := absf(_threat_vel.angle_to(v)) * signf((v.normalized() - _threat_vel.normalized()).dot(away))
		_turned += after
		if _turned > CHASE_TURN and chased == 0:
			chased = 1  # it turned after them: this is a chase
		if chased > 0 and not juked and float(d.t) < JUKE_T and after > 0.0:
			side = -side  # still turning after them: back the other way, behind the turn
			juked = true
	_threat_vel = v
	state = State.DODGE
	away = perp * float(side)
	watch = d.pos
	timer = 0.45


## M015: a wall stands where they were getting to: the other way (once a dodge).
func blocked() -> void:
	if state == State.DODGE and not _wall_turned:
		_wall_turned = true
		side = -side
		away = -away


## Which side of a car's line (+1 / -1 along `perp`) their route - the kerb - is.
func _kerb_side(me: Vector2, perp: Vector2) -> int:
	if route.size() < 2:
		return 1 if _rng.randf() < 0.5 else -1
	var best := route[0]
	var best_d := INF
	for i in range(route.size() - 1):
		var q := Geometry2D.get_closest_point_to_segment(me, route[i], route[i + 1])
		if me.distance_to(q) < best_d:
			best_d = me.distance_to(q)
			best = q
	if best_d < 6.0:
		return 1 if _rng.randf() < 0.5 else -1
	return 1 if perp.dot(best - me) > 0.0 else -1


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


## M015: the way along their route that takes them away from `from` (straight
## away from it when the route leads towards it).
func _away_along_route(me: Vector2, from: Vector2) -> Vector2:
	if route.size() < 2:
		return (me - from).normalized()
	var other := clampi(index - dir, 0, route.size() - 1)
	if route[other].distance_to(from) > route[index].distance_to(from) + 10.0:
		dir = -dir
		index = other
	var go := (route[index] - me).normalized()
	if go.dot((me - from).normalized()) < -0.2:
		go = (me - from).normalized()
	return go


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
