class_name WorkMarkers
extends Node2D
## M015: where Danny's work points, in the street (Casebook's marks, placed by
## the game). Quiet on purpose - a notebook's pencil mark, not a beacon: a
## small brass lozenge floating over the place, faint from a block away and
## clearer close by, the name under it only when he is near; work he only
## suspects is a pale, hollow one. Nothing for hidden work. The arrows at the
## edge of the view are WorkArrows (on the HUD). Presentation only.

## Seen from this far (px); full strength from NEAR in; the name from LABEL_NEAR.
const FAR := 900.0
const NEAR := 240.0
const LABEL_NEAR := 300.0
## Low, like a chalk mark by the door - under the place's own badge, which floats higher.
const LIFT := 16.0
const SIZE := 9.0
const BRASS := Color(0.93, 0.74, 0.42)
const PALE := Color(0.86, 0.83, 0.74)
const INK := Color(0.08, 0.06, 0.04)

## [{pos, label, sure}] (world), set by the game.
var marks: Array = []
## Shown at all (the player's preference).
var shown := true
var _eye := Vector2.ZERO
var _eye_height := 0.0
var _focus := Vector2.ZERO
var _time := 0.0
var _font: Font


func setup(font: Font) -> void:
	name = "WorkMarkers"
	_font = font
	z_index = Layers.Z_MIST + 3
	z_as_relative = false
	material = PlaceMarkers.unshaded()


## How strongly a mark shows for someone `d` px from it (0..1); a suspected one is fainter.
static func strength_at(d: float, sure: bool) -> float:
	return (1.0 - smoothstep(NEAR, FAR, d)) * (1.0 if sure else 0.6)


func update_marks(delta: float, eye: Vector2, eye_height: float, focus: Vector2) -> void:
	_time += delta
	_eye = eye
	_eye_height = eye_height
	_focus = focus
	visible = shown and not marks.is_empty()
	queue_redraw()


func _draw() -> void:
	for m in marks:
		var pos: Vector2 = m.pos
		var sure := bool(m.sure)
		var d := _focus.distance_to(pos)
		var s := strength_at(d, sure)
		if s <= 0.01:
			continue
		var at := Perspective.project(pos, LIFT, _eye, _eye_height) + Vector2(0, sin(_time * 1.8 + pos.x * 0.01) * 2.0 * s)
		var r := SIZE * lerpf(0.8, 1.1, s)
		var lozenge := PackedVector2Array([at + Vector2(0, -r * 1.35), at + Vector2(r, 0), at + Vector2(0, r * 1.35), at + Vector2(-r, 0)])
		var colour := BRASS if sure else PALE
		draw_colored_polygon(lozenge, Color(INK, 0.55 * s))  # a little shadow behind it
		if sure:
			draw_colored_polygon(lozenge, Color(colour, 0.9 * s))
			draw_line(at + Vector2(-r * 0.35, 0), at + Vector2(r * 0.35, 0), Color(INK, 0.7 * s), 1.5)  # a pencil stroke
		var outline := lozenge.duplicate()
		outline.append(lozenge[0])
		draw_polyline(outline, Color(colour if not sure else INK, 0.95 * s), 1.6 if sure else 1.3)
		if not sure and _font != null:
			draw_string(_font, at + Vector2(-3, 4), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(colour, 0.95 * s))
		if d < LABEL_NEAR and _font != null:
			var text := String(m.label)
			var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var a := (1.0 - smoothstep(LABEL_NEAR * 0.6, LABEL_NEAR, d)) * (1.0 if sure else 0.75)
			draw_string(_font, at + Vector2(-w * 0.5 + 1, r * 1.35 + 15), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(INK, 0.8 * a))
			draw_string(_font, at + Vector2(-w * 0.5, r * 1.35 + 14), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(colour, a))
