class_name CityCamera
extends Camera2D
## True top-down camera. Smoothly follows the player (on foot or in a car),
## looks ahead in the direction of travel, sits closer on foot and eases out
## as the car gathers speed, and stays inside the district. Its eye height
## drives the perspective of everything raised (see Perspective): zooming out
## lifts the eye, so buildings lean a little less.

## Eye height at zoom 1 (world px). Lower = stronger perspective.
const EYE_HEIGHT := 950.0

@export var foot_zoom := 1.2
@export var car_zoom_slow := 1.12
@export var car_zoom_fast := 0.9
## How quickly the camera catches up (1/s) and how far it looks ahead.
@export var follow_rate := 7.0
@export var lookahead_time := 0.32
@export var max_lookahead := 190.0
@export var zoom_rate := 1.6

var target: Node2D
## A zoom to hold instead of the usual one (the opening's slow shots); 0 = none.
var zoom_override := 0.0
var _look := Vector2.ZERO
var _zoom := 1.2


func _ready() -> void:
	ignore_rotation = true
	position_smoothing_enabled = false
	_zoom = foot_zoom
	zoom = Vector2(_zoom, _zoom)


func set_bounds(r: Rect2) -> void:
	limit_left = int(r.position.x)
	limit_top = int(r.position.y)
	limit_right = int(r.end.x)
	limit_bottom = int(r.end.y)


## Jumps straight to the target (start of play).
func snap_to(node: Node2D) -> void:
	target = node
	_look = Vector2.ZERO
	global_position = node.global_position
	reset_physics_interpolation()


func target_velocity() -> Vector2:
	if target is Car and (target as Car).model != null:
		return (target as Car).model.velocity
	if target is CharacterBody2D:
		return (target as CharacterBody2D).velocity
	return Vector2.ZERO


## Zoom wanted for the current target and speed (pure, for tests).
func desired_zoom() -> float:
	if zoom_override > 0.0:
		return zoom_override
	if target is Car and (target as Car).model != null:
		var c := target as Car
		var ratio := clampf(c.model.velocity.length() / c.model.params.max_speed, 0.0, 1.0)
		return lerpf(car_zoom_slow, car_zoom_fast, ratio)
	return foot_zoom


func update_camera(delta: float) -> void:
	if target == null:
		return
	var desired_look := (target_velocity() * lookahead_time).limit_length(max_lookahead)
	_look = _look.lerp(desired_look, 1.0 - exp(-delta * 2.2))
	var goal := target.global_position + _look
	global_position = global_position.lerp(goal, 1.0 - exp(-delta * follow_rate))
	_zoom = lerpf(_zoom, desired_zoom(), 1.0 - exp(-delta * zoom_rate))
	zoom = Vector2(_zoom, _zoom)


func eye() -> Vector2:
	return get_screen_center_position()


func eye_height() -> float:
	return EYE_HEIGHT / zoom.x


## The world rectangle on screen.
func view_rect() -> Rect2:
	var size := get_viewport_rect().size / zoom
	return Rect2(eye() - size * 0.5, size)
