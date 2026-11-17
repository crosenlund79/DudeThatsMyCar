class_name Perspective
extends RefCounted
## The top-down camera looks straight down from eye_height (world px) above
## the point it is centred on. Anything raised above the street (walls, roofs,
## lamp heads, awnings) is drawn where that camera would see it: pushed away
## from the screen centre the higher it is. Reflections on the wet street are
## the mirror image (negative height): pulled towards the centre.
## Pure maths, shared by every raised drawing and by tests.

## Highest drawable height as a share of the eye height (keeps the scale finite).
const MAX_HEIGHT_SHARE := 0.8


## Screen-plane position of world point p raised by height h.
static func project(p: Vector2, h: float, eye: Vector2, eye_height: float) -> Vector2:
	return eye + (p - eye) * scale_at(h, eye_height)


## Size multiplier of something drawn at height h.
static func scale_at(h: float, eye_height: float) -> float:
	return eye_height / (eye_height - minf(h, eye_height * MAX_HEIGHT_SHARE))
