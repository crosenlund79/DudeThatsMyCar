class_name RouteFollower
extends RefCounted
## Walks a Walker to a goal along CityNavigator routes (extracted from the
## M002 police officer so the M006 gangster walks the same way): re-plans
## every REPATH seconds or when the goal moves, cuts the corners it has
## passed, and sidesteps when something (a parked car, a lamp post) blocks it.

const REPATH := 0.45

var navigator: CityNavigator
var route := PackedVector2Array()
var _goal := Vector2.INF
var _repath := 0.0
var _stuck := 0.0
var _last_pos := Vector2.ZERO
var _sidestep := 0.0
var _sidestep_dir := Vector2.ZERO
var _sidestep_sign := 1.0


func _init(p_navigator: CityNavigator) -> void:
	navigator = p_navigator


func reset(at: Vector2) -> void:
	route = PackedVector2Array()
	_goal = Vector2.INF
	_stuck = 0.0
	_sidestep = 0.0
	_last_pos = at


## One tick: sets body.move towards `goal` at `speed` (stops when there or speed is 0).
func step(body: Walker, goal: Vector2, speed: float, dt: float) -> void:
	var me := body.global_position
	if speed <= 0.0 or me.distance_to(goal) < 6.0:
		body.move = Vector2.ZERO
		_stuck = 0.0
		_last_pos = me
		return
	body.model.walk_speed = speed
	_repath -= dt
	if _repath <= 0.0 or route.is_empty() or goal.distance_to(_goal) > 40.0:
		route = navigator.route(me, goal)
		_goal = goal
		_repath = REPATH
	while route.size() > 1 and me.distance_to(route[0]) < 14.0:
		route.remove_at(0)
	var next: Vector2 = route[0] if not route.is_empty() else goal
	var dir := (next - me).normalized()
	if _sidestep > 0.0:
		_sidestep -= dt
		dir = (_sidestep_dir + dir * 0.35).normalized()
	elif me.distance_to(_last_pos) < speed * dt * 0.25:
		_stuck += dt
		if _stuck > 0.5:  # blocked: step aside and try again
			_sidestep = 0.45
			_sidestep_sign = -_sidestep_sign
			_sidestep_dir = dir.orthogonal() * _sidestep_sign
			_stuck = 0.0
			_repath = 0.0
	else:
		_stuck = 0.0
	_last_pos = me
	body.move = dir
