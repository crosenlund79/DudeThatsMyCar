class_name InteractionHighlight
extends Node2D
## M012: what E would act on right now, picked out without fuss: a thin brass
## ring on the ground under a person, a thing to look at or a seat; a bright
## line across a doorway; a cold ring at a door that will not open; an
## outline round a car he can get into. One target at a time - the one the
## prompt names - drawn as a few lines on the ground (no shader over the
## world). The game chooses the target: only what is in reach and on Danny's
## side of the walls (the room he is in, or the street).

const WARM := Color(1.0, 0.8, 0.45)
const COLD := Color(0.62, 0.7, 0.82)

## The target: {} for none, else {kind: "ring" | "door" | "car", pos, radius,
## a, b (a doorway's ends), xform (a car's), size, cold: bool}.
var target := {}
var _t := 0.0


func setup() -> void:
	name = "InteractionHighlight"
	z_index = Layers.Z_PROP + 5  # over the furniture and a room's walls, under people and cars
	z_as_relative = false
	material = PlaceMarkers.unshaded()  # seen at night, whatever the street lamps do


func show_target(t: Dictionary) -> void:
	if t.is_empty() and target.is_empty():
		return
	target = t
	queue_redraw()


func _process(delta: float) -> void:
	if target.is_empty():
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	if target.is_empty():
		return
	var c: Color = COLD if target.get("cold", false) else WARM
	var pulse := 0.65 + 0.25 * sin(_t * 4.0)
	match String(target.kind):
		"ring":
			var r := float(target.get("radius", 14.0))
			var at: Vector2 = target.pos
			draw_set_transform(at, 0.0, Vector2(1.0, 0.72))  # an ellipse, lying on the ground
			draw_arc(Vector2.ZERO, r + 3.0, 0.0, TAU, 40, Color(c, 0.22 * pulse), 5.0, true)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(c, 0.85 * pulse), 1.6, true)
			draw_set_transform(Vector2.ZERO)
		"door":
			var a: Vector2 = target.a
			var b: Vector2 = target.b
			draw_line(a, b, Color(c, 0.25 * pulse), 7.0, true)
			draw_line(a, b, Color(c, 0.95 * pulse), 2.0, true)
		"car":
			var xf: Transform2D = target.xform
			var half: Vector2 = (target.size as Vector2) * 0.5 + Vector2(5, 5)
			var pts := PackedVector2Array([xf * Vector2(-half.x, -half.y), xf * Vector2(half.x, -half.y),
				xf * Vector2(half.x, half.y), xf * Vector2(-half.x, half.y), xf * Vector2(-half.x, -half.y)])
			draw_polyline(pts, Color(c, 0.22 * pulse), 5.0, true)
			draw_polyline(pts, Color(c, 0.8 * pulse), 1.5, true)
