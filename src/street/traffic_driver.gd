class_name TrafficDriver
extends RefCounted
## A careful late-night driver going round a block (pure decisions; the Car
## does the driving): keeps to the right-hand lane of a closed loop of lane
## points, slows for corners, waits at a crossing while another car is in it,
## and brakes for anything standing or moving in its path (cars, people).
## It never plans a way round; it waits.

## Cruising and cornering speeds (px/s: about 26 and 12 mph).
const CRUISE := 155.0
const TURN_SPEED := 72.0
## Starts slowing this far before a corner (px).
const CORNER_SLOWDOWN := 150.0
## Braking it plans with (px/s^2), gentler than the car can do.
const PLAN_BRAKE := 170.0
## Half the width of the path it keeps clear (px), and the gap it stops short.
const CLEARANCE := 21.0
const STOP_GAP := 26.0

var route := PackedVector2Array()
## Index of the lane point it is heading for.
var next := 1
## Set while it waits for a crossing to clear or for something in its path.
var waiting := false


func _init(p_route: PackedVector2Array, start_segment: int = 0) -> void:
	route = p_route
	next = (start_segment + 1) % route.size()


func _seg_from() -> Vector2:
	return route[(next - 1 + route.size()) % route.size()]


## A point `ahead` px further along the loop from the projection of p.
func lookahead(p: Vector2, ahead: float) -> Vector2:
	var a := _seg_from()
	var b := route[next]
	var q := Geometry2D.get_closest_point_to_segment(p, a, b)
	var left := ahead
	var i := next
	var from := q
	for k in route.size() + 1:
		var to := route[i]
		var d := from.distance_to(to)
		if d >= left:
			return from + (to - from).normalized() * left
		left -= d
		from = to
		i = (i + 1) % route.size()
	return from


## Moves on to the next lane point once it is close or passed.
func _advance(p: Vector2) -> void:
	var a := _seg_from()
	var b := route[next]
	var seg := b - a
	var t := (p - a).dot(seg) / maxf(seg.length_squared(), 1.0)
	if t >= 1.0 or p.distance_to(b) < 46.0:
		next = (next + 1) % route.size()


## Speed it wants for the corner ahead (slower the closer it gets).
func corner_speed(p: Vector2) -> float:
	var d := p.distance_to(route[next])
	if d >= CORNER_SLOWDOWN:
		return CRUISE
	return lerpf(TURN_SPEED, CRUISE, d / CORNER_SLOWDOWN)


## Highest speed that still stops short of the nearest thing in its path.
## obstacles: [{pos, radius}] (other cars as a few circles, people).
static func clear_speed(p: Vector2, heading: float, speed: float, obstacles: Array) -> float:
	var fwd := Vector2.from_angle(heading)
	var side := fwd.orthogonal()
	var look := 40.0 + speed * speed / (2.0 * PLAN_BRAKE) + 50.0
	var best := INF
	for o in obstacles:
		var rel: Vector2 = (o.pos as Vector2) - p
		var along := rel.dot(fwd)
		if along <= 0.0 or along > look:
			continue
		if absf(rel.dot(side)) > float(o.radius) + CLEARANCE:
			continue
		var room := along - float(o.radius) - STOP_GAP - 38.0  # 38: from the car's centre to its nose
		best = minf(best, sqrt(maxf(0.0, 2.0 * PLAN_BRAKE * room)))
	return best


## The command for this tick: {steer, throttle, brake}.
## junction_ahead: a crossing ahead (Rect2, or an empty Rect2 when none) and
## whether someone else is in it.
func decide(p: Vector2, heading: float, speed: float, obstacles: Array, crossing_busy: bool) -> Dictionary:
	_advance(p)
	var target := lookahead(p, 55.0 + speed * 0.3)
	var diff := angle_difference(heading, (target - p).angle())
	var steer := clampf(diff * 2.6, -1.0, 1.0)
	var want := minf(corner_speed(p), clear_speed(p, heading, speed, obstacles))
	if crossing_busy:
		want = 0.0
	waiting = want < 5.0
	var throttle := speed < want - 8.0
	var brake := speed > want + 12.0 or (want < 5.0 and speed > 1.0)
	return {"steer": steer, "throttle": throttle, "brake": brake}
