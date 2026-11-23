class_name WorkArrows
extends Control
## M015: for work Danny knows he has to do, somewhere out of view: a small
## brass chevron at the edge of the screen pointing the way, with a word of
## what is there - no more than a few at once, the nearest, and only within a
## couple of districts' reach. Suspected work gets none (its mark waits to be
## come upon). Presentation only; WorkMarkers draws the marks in the street.

## Arrows only for marks this near (world px), at most MAX of them.
const RANGE := 3200.0
const MAX := 3
## How far in from the screen's edge (px), and the size of a chevron.
const INSET := 30.0
const CHEVRON := 9.0
const BRASS := Color(0.93, 0.74, 0.42)
const INK := Color(0.08, 0.06, 0.04)

## [{pos, label, sure}] (world), set by the game.
var marks: Array = []
var shown := true
## Where Danny is (world).
var focus := Vector2.ZERO
## What is on screen now: [{at (screen), dir, label}] (tests read it).
var arrows: Array = []
var _font: Font


func setup(font: Font) -> void:
	name = "WorkArrows"
	_font = font
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	arrows = []
	if shown:
		arrows = place(marks, focus, get_viewport().get_canvas_transform(), get_viewport_rect().size)
	queue_redraw()


## The arrows for `marks` seen through `view` (world to screen) on a screen of `screen_size`.
static func place(p_marks: Array, p_focus: Vector2, view: Transform2D, screen_size: Vector2) -> Array:
	var near := []
	for m in p_marks:
		if not bool(m.sure):
			continue
		var d := p_focus.distance_to(m.pos)
		if d > RANGE:
			continue
		var s: Vector2 = view * (m.pos as Vector2)
		if Rect2(Vector2.ZERO, screen_size).grow(-INSET * 0.5).has_point(s):
			continue  # in view: its mark in the street says it
		near.append({"d": d, "screen": s, "label": m.label})
	near.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.d) < float(b.d))
	var out := []
	var centre := screen_size * 0.5
	for n in near.slice(0, MAX):
		var dir := ((n.screen as Vector2) - centre).normalized()
		var half := centre - Vector2(INSET, INSET)
		var t := minf(absf(half.x / dir.x) if dir.x != 0.0 else INF, absf(half.y / dir.y) if dir.y != 0.0 else INF)
		out.append({"at": centre + dir * t, "dir": dir, "label": n.label})
	return out


func _draw() -> void:
	for a in arrows:
		var at: Vector2 = a.at
		var dir: Vector2 = a.dir
		var side := dir.orthogonal() * CHEVRON * 0.75
		var tip := at + dir * CHEVRON
		var pts := PackedVector2Array([tip, at - dir * CHEVRON * 0.4 + side, at, at - dir * CHEVRON * 0.4 - side])
		draw_colored_polygon(pts, Color(BRASS, 0.75))
		pts.append(tip)
		draw_polyline(pts, Color(INK, 0.8), 1.2)
		if _font != null:
			var text := String(a.label)
			var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var at_text := at - dir * 22.0 - Vector2(w * 0.5, -4.0)
			at_text.x = clampf(at_text.x, 6.0, maxf(6.0, get_viewport_rect().size.x - w - 6.0))
			draw_string(_font, at_text + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(INK, 0.7))
			draw_string(_font, at_text, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(BRASS, 0.8))
