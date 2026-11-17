class_name WalkerModel
extends RefCounted
## Pure on-foot movement for a person seen from above (no scene): moves where
## the stick / WASD points, with a short speed-up and stop, independently of
## where the person faces (aim). Units: world px and seconds.

var walk_speed := 108.0
var acceleration := 900.0
var deceleration := 1300.0
var velocity := Vector2.ZERO
## Direction the person faces (radians, 0 = +X): towards the aim point.
var facing := 0.0


## move: desired direction (any length; clamped to 1). Returns the new velocity.
func update(delta: float, move: Vector2) -> Vector2:
	var target := move.limit_length(1.0) * walk_speed
	var rate := acceleration if target.length_squared() > 0.0 else deceleration
	velocity = velocity.move_toward(target, rate * delta)
	return velocity


## Faces a world point seen from `from` (no change when it is on top of us).
func aim_at(from: Vector2, point: Vector2) -> void:
	if from.distance_squared_to(point) > 4.0:
		facing = (point - from).angle()


func speed() -> float:
	return velocity.length()
