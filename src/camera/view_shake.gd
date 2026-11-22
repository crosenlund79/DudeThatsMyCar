class_name ViewShake
extends RefCounted
## M014 (from main): what jolts the view (M010) - the Thompson climbing with
## each round (`kick`) and the cafe's blast shaking the street (`shake`, 1 at
## the flash, dying away). The camera's offset for a frame, both together.

var kick := Vector2.ZERO
var shake := 0.0


## The view's offset this frame on top of `base` (the drowsy sway); the kick
## settles and the shake dies away as it is used.
func offset(base: Vector2, delta: float) -> Vector2:
	var out := base + kick
	kick = kick.move_toward(Vector2.ZERO, delta * 40.0).limit_length(8.0)
	if shake > 0.0:  # M010: the blast shakes the view
		shake = maxf(0.0, shake - delta * 0.9)
		out += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 14.0 * shake * shake
	return out
