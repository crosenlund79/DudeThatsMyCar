class_name WardMap
extends Control
## The whole Riverside Ward on one sheet (M006, M key): the minimap's painted
## map of the district, fitted to the screen, with the same badges for the
## places you can walk into, the beat cop where he is, Danny's own car, the
## named landmarks, the street names, and Danny as the arrow. A key at the
## side says what the badges mean. Presentation only: the game is paused
## while it is open. M007: Rourke's job in a few words under the key, and a
## thin copper ring round the place it concerns now (no route, no arrows).

const PANEL := Color("1b1611", 0.94)
const INK := Color("f1e4c6")
const DIM := Color("f1e4c6", 0.6)
const COPPER := Color("d8a060")
const LANDMARK := Color("e8d6b0")
## Screen room kept round the map, and the width of the key at the right.
const MARGIN := 34.0
const KEY_WIDTH := 220.0
const ICON := 26.0

var minimap: Minimap
var layout: DistrictLayout
## World rect shown and how it maps to the screen (world px per screen px).
var world := Rect2()
var scale_px := 1.0
var map_rect := Rect2()
## What to show: Danny (world, heading), his car (Vector2.INF: none), the cop (INF: none).
var danny := Vector2.ZERO
var danny_heading := 0.0
var car := Vector2.INF
var car_heading := 0.0
var police := Vector2.INF
## Extra landmarks without a door of their own: {pos, label, tex (or null)}.
var landmarks: Array = []
## M007: what Rourke's job needs next ("" for nothing), the place it concerns
## (INF: none) and where Lefty Moran keeps his corner once Danny knows (INF).
var job_text := ""
var job_at := Vector2.INF
var lefty_at := Vector2.INF
var _font: Font


func setup(p_minimap: Minimap, font: Font) -> void:
	name = "WardMap"
	minimap = p_minimap
	layout = minimap.layout
	_font = font
	mouse_filter = Control.MOUSE_FILTER_STOP  # clicks stay on the map, never reach the game
	visible = false
	world = layout.play_area.grow(60.0)
	for b in layout.buildings:
		var label := String(b.get("name", ""))
		if label == "" or label in ["Railroad embankment", "Bridge tender"]:
			continue
		if _is_place(b.rect):
			continue
		landmarks.append({"pos": (b.rect as Rect2).get_center(), "label": label, "tex": null})


func _is_place(r: Rect2) -> bool:
	for pl in minimap.places:
		if r.grow(30.0).has_point(pl.pos):
			return true
	return false


## Adds a landmark with its own badge (the vet, the Morgue).
func add_landmark(pos: Vector2, label: String, tex: Texture2D) -> void:
	landmarks.append({"pos": pos, "label": label, "tex": tex})


func set_job(text: String, at: Vector2, lefty: Vector2) -> void:
	job_text = text
	job_at = at
	lefty_at = lefty
	queue_redraw()


func set_state(p_danny: Vector2, heading: float, p_car: Vector2, p_car_heading: float, p_police: Vector2) -> void:
	danny = p_danny
	danny_heading = heading
	car = p_car
	car_heading = p_car_heading
	police = p_police
	queue_redraw()


## Fits the ward into the screen left of the key.
func layout_for(screen: Vector2) -> void:
	position = Vector2.ZERO
	size = screen
	var room := screen - Vector2(MARGIN * 3.0 + KEY_WIDTH, MARGIN * 2.0)
	scale_px = maxf(world.size.x / room.x, world.size.y / room.y)
	var shown := world.size / scale_px
	map_rect = Rect2(Vector2(MARGIN + (room.x - shown.x) * 0.5, MARGIN + (room.y - shown.y) * 0.5), shown)


## Where a world point shows on screen.
func to_screen(p: Vector2) -> Vector2:
	return map_rect.position + (p - world.position) / scale_px


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PANEL)
	var origin := layout.bounds.position - Vector2(Minimap.MARGIN, Minimap.MARGIN)
	var src := Rect2((world.position - origin) / Minimap.IMAGE_SCALE, world.size / Minimap.IMAGE_SCALE)
	draw_texture_rect_region(minimap.map_texture, map_rect, src)
	draw_rect(map_rect.grow(3.0), COPPER, false, 2.0)
	_draw_street_names()
	for l in landmarks:
		var at := to_screen(l.pos)
		if l.tex != null:
			draw_texture_rect(l.tex, Rect2(at - Vector2(ICON * 0.81 * 0.5, ICON), Vector2(ICON * 0.81, ICON)), false)
		_label(at + Vector2(0, 14), l.label, 11, LANDMARK)
	for pl in minimap.places:
		var at := to_screen(pl.pos)
		draw_texture_rect(pl.tex, Rect2(at - Vector2(ICON * 0.81 * 0.5, ICON), Vector2(ICON * 0.81, ICON)), false)
	if lefty_at != Vector2.INF:
		var lp := to_screen(lefty_at)
		draw_circle(lp, 4.0, COPPER)
		draw_circle(lp, 4.0, Color("1b1611"), false, 1.0)
		_label(lp + Vector2(0, 16), "Lefty Moran", 11, LANDMARK)
	if job_at != Vector2.INF:
		var jp := to_screen(job_at)
		if job_at != lefty_at:
			jp -= Vector2(0, ICON * 0.4)  # round the badge, which stands above its door
		draw_arc(jp, 21.0, 0.0, TAU, 40, Color(COPPER, 0.9), 2.0)
		draw_arc(jp, 25.0, 0.0, TAU, 40, Color(COPPER, 0.35), 1.0)
	if car != Vector2.INF:
		var c := to_screen(car)
		draw_set_transform(c, car_heading, Vector2.ONE)
		draw_rect(Rect2(-7, -3.5, 14, 7), COPPER)
		draw_rect(Rect2(-7, -3.5, 14, 7), Color("1b1611"), false, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if police != Vector2.INF:
		var cp := to_screen(police)
		draw_texture_rect(minimap._police_tex, Rect2(cp - Vector2(9, 9), Vector2(18, 18)), false)
	draw_set_transform(to_screen(danny), danny_heading, Vector2.ONE)
	draw_texture_rect(minimap._player_tex, Rect2(-Vector2(11, 11), Vector2(22, 22)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_key()


func _draw_street_names() -> void:
	for s in layout.streets:
		var r: Rect2 = s.rect
		if not r.intersects(world) or r.position.x > layout.play_area.end.x:
			continue
		var label := String(s.name).to_upper()
		if r.size.x > r.size.y:
			var y := to_screen(Vector2(0, r.get_center().y)).y + 4.0
			_text(Vector2(map_rect.position.x + 12.0, y), label, 11, Minimap.LABEL)
		else:
			var x := to_screen(Vector2(r.get_center().x, 0)).x - 4.0
			draw_set_transform(Vector2(x, map_rect.position.y + 14.0), PI / 2, Vector2.ONE)
			_text(Vector2.ZERO, label, 11, Minimap.LABEL)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_key() -> void:
	var x := size.x - MARGIN - KEY_WIDTH
	var y := MARGIN + 6.0
	_text(Vector2(x, y + 14.0), "THE RIVERSIDE WARD", 18, COPPER)
	y += 44.0
	var rows: Array = []
	for pl in minimap.places:
		rows.append([pl.tex, _place_name(pl.id)])
	for l in landmarks:
		if l.tex != null:
			rows.append([l.tex, l.label])
	for row in rows:
		draw_texture_rect(row[0], Rect2(Vector2(x, y), Vector2(ICON * 0.81, ICON)), false)
		_text(Vector2(x + 30.0, y + 18.0), row[1], 14, INK)
		y += 32.0
	y += 6.0
	draw_set_transform(Vector2(x + 11.0, y + 11.0), 0.0, Vector2.ONE)
	draw_texture_rect(minimap._player_tex, Rect2(-Vector2(10, 10), Vector2(20, 20)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_text(Vector2(x + 30.0, y + 16.0), "You", 14, INK)
	y += 30.0
	draw_rect(Rect2(x + 4.0, y + 7.0, 14, 7), COPPER)
	_text(Vector2(x + 30.0, y + 16.0), "Your car", 14, INK)
	y += 30.0
	draw_texture_rect(minimap._police_tex, Rect2(Vector2(x + 2.0, y + 2.0), Vector2(18, 18)), false)
	_text(Vector2(x + 30.0, y + 16.0), "The beat cop", 14, INK)
	y += 46.0
	if job_text != "":
		_text(Vector2(x, y), "ROURKE'S JOB", 14, COPPER)
		y += 20.0
		for line in _wrap(job_text, 13, KEY_WIDTH):
			_text(Vector2(x, y), line, 13, INK)
			y += 17.0
		y += 16.0
	_text(Vector2(x, y), "M or Esc   close", 13, DIM)


## `s` broken into lines no wider than `width` at `px`.
func _wrap(s: String, px: int, width: float) -> Array:
	var lines := []
	var line := ""
	for word in s.split(" "):
		var next := word if line == "" else line + " " + word
		if _font != null and line != "" and _font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > width:
			lines.append(line)
			line = word
		else:
			line = next
	if line != "":
		lines.append(line)
	return lines


func _place_name(id: String) -> String:
	for plan in layout.interiors:
		if (plan as InteriorPlan).id == id:
			return "Your flat" if (plan as InteriorPlan).is_home else (plan as InteriorPlan).name
	return id


func _text(at: Vector2, s: String, px: int, col: Color) -> void:
	if _font != null:
		draw_string(_font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)


func _label(centre: Vector2, s: String, px: int, col: Color) -> void:
	if _font == null:
		return
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_string_outline(_font, centre - Vector2(w * 0.5, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 4, Color("1b1611"))
	draw_string(_font, centre - Vector2(w * 0.5, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)
