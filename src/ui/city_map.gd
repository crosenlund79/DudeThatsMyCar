class_name CityMap
extends Control
## The map of the city (M008, M key; it grew out of the M006 ward map): every
## district in its true place, painted like the minimap - streets, alleys,
## blocks, the river and its bridges - with the district borders and names,
## the street names, the landmarks, the places Danny can walk into (the same
## badges as in the street and on the minimap), his car, the beat cops and
## Danny as the arrow. Drag with the mouse to look round, the wheel zooms in
## and out (within limits), R - or the button in the key - brings it back to
## Danny. Neighbouring districts can be looked at without going there (their
## maps are painted from their plans at start-up). A key at the side says what
## the badges mean, and what Rourke's job needs next. Presentation only: the
## game is paused while it is open; no routes, no arrows.

const PANEL := Color("1b1611", 0.96)
const INK := Color("f1e4c6")
const DIM := Color("f1e4c6", 0.6)
const COPPER := Color("d8a060")
const LANDMARK := Color("e8d6b0")
const BORDER := Color("d8a060", 0.55)
const DISTRICT := Color("f1e4c6", 0.22)
## Screen room kept round the map, and the width of the key at the right.
const MARGIN := 34.0
const KEY_WIDTH := 236.0
const ICON := 24.0
## World px per screen px at the closest zoom; how much one wheel notch zooms.
const ZOOM_IN := 2.4
const ZOOM_STEP := 1.2
## Labels show only when the map is close enough to read them.
const STREETS_BELOW := 9.0
const LANDMARKS_BELOW := 12.0

var minimap: Minimap
## The map's area on the screen, the world point at its middle and the scale
## (world px per screen px), and the farthest it may zoom out (the whole city).
var map_rect := Rect2()
var centre := Vector2.ZERO
var scale_px := 6.0
var zoom_out_limit := 24.0
## The whole city (every district's bounds together).
var city_rect := Rect2()
## What to show: Danny (world, heading), his car (INF: none), the beat cops.
var danny := Vector2.ZERO
var danny_heading := 0.0
var car := Vector2.INF
var car_heading := 0.0
var officers: Array = []
## Landmarks: {pos, label, tex (or null)}.
var landmarks: Array = []
## M007: what Rourke's job needs next, the place it concerns and Lefty's corner (INF: none).
var job_text := ""
var job_at := Vector2.INF
var lefty_at := Vector2.INF
## The "back to Danny" button in the key.
var recentre_rect := Rect2()
var dragging := false
var _font: Font


func setup(p_minimap: Minimap, font: Font) -> void:
	name = "CityMap"
	minimap = p_minimap
	_font = font
	mouse_filter = Control.MOUSE_FILTER_STOP  # clicks stay on the map, never reach the game
	process_mode = Node.PROCESS_MODE_ALWAYS  # dragged and zoomed while the world waits
	visible = false
	refresh_districts()


## The districts on the map (call again when the minimap gains one).
func refresh_districts() -> void:
	city_rect = Rect2()
	var named := {}
	for l in landmarks:
		named[l.label] = true
	var first := true
	for dist in minimap.districts:
		var layout: DistrictLayout = dist.layout
		city_rect = layout.bounds if first else city_rect.merge(layout.bounds)
		first = false
		for b in layout.buildings:
			var label := String(b.get("name", ""))
			if label == "" or named.has(label) or label in ["Railroad embankment", "Bridge tender", "Tannery stack", "St. Brendan's tower"]:
				continue
			if _is_place(b.rect):
				continue
			named[label] = true
			landmarks.append({"pos": (b.rect as Rect2).get_center(), "label": label, "tex": null})
		for l in layout.landmarks:
			if not named.has(l.label):
				named[l.label] = true
				landmarks.append({"pos": l.pos, "label": l.label, "tex": null})


func _is_place(r: Rect2) -> bool:
	for pl in minimap.places:
		if r.grow(30.0).has_point(pl.pos):
			return true
	return false


## Adds a landmark with its own badge (the vet, the Morgue).
func add_landmark(pos: Vector2, label: String, tex: Texture2D) -> void:
	for l in landmarks:
		if l.label == label:
			l.pos = pos
			l.tex = tex
			return
	landmarks.append({"pos": pos, "label": label, "tex": tex})


func set_job(text: String, at: Vector2, lefty: Vector2) -> void:
	job_text = text
	job_at = at
	lefty_at = lefty
	queue_redraw()


## Where Danny, his car and the beat cops are (`p_officers`: world positions).
func set_state(p_danny: Vector2, heading: float, p_car: Vector2, p_car_heading: float, p_officers: Array) -> void:
	danny = p_danny
	danny_heading = heading
	car = p_car
	car_heading = p_car_heading
	officers = p_officers
	queue_redraw()


## Fits the map into the screen left of the key.
func layout_for(screen: Vector2) -> void:
	position = Vector2.ZERO
	size = screen
	map_rect = Rect2(MARGIN, MARGIN, screen.x - MARGIN * 3.0 - KEY_WIDTH, screen.y - MARGIN * 2.0)
	zoom_out_limit = maxf(city_rect.size.x / map_rect.size.x, city_rect.size.y / map_rect.size.y) * 1.05
	scale_px = clampf(scale_px, ZOOM_IN, zoom_out_limit)
	_clamp_centre()


## Opens on Danny, at a scale that shows about a district round him.
func open_on(p: Vector2, district: Rect2) -> void:
	danny = p
	scale_px = clampf(maxf(district.size.x / map_rect.size.x, district.size.y / map_rect.size.y), ZOOM_IN, zoom_out_limit)
	centre = p
	_clamp_centre()
	queue_redraw()


## The world rect on show.
var world: Rect2:
	get:
		return Rect2(centre - map_rect.size * 0.5 * scale_px, map_rect.size * scale_px)


func to_screen(p: Vector2) -> Vector2:
	return map_rect.get_center() + (p - centre) / scale_px


func to_world(s: Vector2) -> Vector2:
	return centre + (s - map_rect.get_center()) * scale_px


## Moves the map by a drag of `screen_delta` px.
func pan(screen_delta: Vector2) -> void:
	centre -= screen_delta * scale_px
	_clamp_centre()
	queue_redraw()


## Zooms by `factor` (above 1 = out) keeping the world point under `screen_point` where it is.
func zoom_at(screen_point: Vector2, factor: float) -> void:
	var w := to_world(screen_point)
	scale_px = clampf(scale_px * factor, ZOOM_IN, zoom_out_limit)
	centre = w - (screen_point - map_rect.get_center()) * scale_px
	_clamp_centre()
	queue_redraw()


func recentre() -> void:
	centre = danny
	_clamp_centre()
	queue_redraw()


## The map stays over the city: no dragging off into the dark (when the
## whole city fits, it sits in the middle).
func _clamp_centre() -> void:
	if not city_rect.has_area():
		return
	var half := map_rect.size * 0.5 * scale_px
	var c := city_rect.get_center()
	centre.x = c.x if half.x * 2.0 >= city_rect.size.x else clampf(centre.x, city_rect.position.x + half.x, city_rect.end.x - half.x)
	centre.y = c.y if half.y * 2.0 >= city_rect.size.y else clampf(centre.y, city_rect.position.y + half.y, city_rect.end.y - half.y)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and recentre_rect.has_point(mb.position):
				recentre()
			else:
				dragging = mb.pressed and map_rect.has_point(mb.position)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at(mb.position, 1.0 / ZOOM_STEP)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at(mb.position, ZOOM_STEP)
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		pan((event as InputEventMouseMotion).relative)
		accept_event()


# ------------------------------------------------------------------ drawing

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PANEL)
	draw_rect(map_rect, Minimap.VOID)
	var view := world
	for dist in minimap.districts:
		var r: Rect2 = dist.rect
		var part := r.intersection(view)
		if not part.has_area():
			continue
		var src := Rect2((part.position - r.position) / Minimap.IMAGE_SCALE, part.size / Minimap.IMAGE_SCALE)
		draw_texture_rect_region(dist.texture, Rect2(to_screen(part.position), part.size / scale_px), src)
	_draw_borders(view)
	if scale_px < STREETS_BELOW:
		_draw_street_names(view)
	for l in landmarks:
		var at := to_screen(l.pos)
		if not map_rect.has_point(at):
			continue
		if l.tex != null:
			draw_texture_rect(l.tex, Rect2(at - Vector2(ICON * 0.81 * 0.5, ICON), Vector2(ICON * 0.81, ICON)), false)
		if scale_px < LANDMARKS_BELOW or l.tex != null:
			_label(at + Vector2(0, 14), l.label, 11, LANDMARK)
	for pl in minimap.places:
		var at2 := to_screen(pl.pos)
		if map_rect.has_point(at2):
			draw_texture_rect(pl.tex, Rect2(at2 - Vector2(ICON * 0.81 * 0.5, ICON), Vector2(ICON * 0.81, ICON)), false)
	if lefty_at != Vector2.INF and map_rect.has_point(to_screen(lefty_at)):
		var lp := to_screen(lefty_at)
		draw_circle(lp, 4.0, COPPER)
		draw_circle(lp, 4.0, Color("1b1611"), false, 1.0)
		_label(lp + Vector2(0, 16), "Lefty Moran", 11, LANDMARK)
	if job_at != Vector2.INF and map_rect.has_point(to_screen(job_at)):
		var jp := to_screen(job_at)
		if job_at != lefty_at:
			jp -= Vector2(0, ICON * 0.4)
		draw_arc(jp, 21.0, 0.0, TAU, 40, Color(COPPER, 0.9), 2.0)
		draw_arc(jp, 25.0, 0.0, TAU, 40, Color(COPPER, 0.35), 1.0)
	if car != Vector2.INF and map_rect.has_point(to_screen(car)):
		draw_set_transform(to_screen(car), car_heading, Vector2.ONE)
		draw_rect(Rect2(-7, -3.5, 14, 7), COPPER)
		draw_rect(Rect2(-7, -3.5, 14, 7), Color("1b1611"), false, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for o in officers:
		var cp := to_screen(o)
		if map_rect.has_point(cp):
			draw_texture_rect(minimap._police_tex, Rect2(cp - Vector2(9, 9), Vector2(18, 18)), false)
	if map_rect.has_point(to_screen(danny)):
		draw_set_transform(to_screen(danny), danny_heading, Vector2.ONE)
		draw_texture_rect(minimap._player_tex, Rect2(-Vector2(11, 11), Vector2(22, 22)), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# whatever was drawn past the map's edge is covered by the panel round it
	draw_rect(Rect2(0, 0, size.x, map_rect.position.y), PANEL)
	draw_rect(Rect2(0, map_rect.end.y, size.x, size.y - map_rect.end.y), PANEL)
	draw_rect(Rect2(0, 0, map_rect.position.x, size.y), PANEL)
	draw_rect(Rect2(map_rect.end.x, 0, size.x - map_rect.end.x, size.y), PANEL)
	draw_rect(map_rect.grow(3.0), COPPER, false, 2.0)
	_draw_key()


## Each district's edge as a dashed copper line, and its name across it.
func _draw_borders(view: Rect2) -> void:
	for dist in minimap.districts:
		var layout: DistrictLayout = dist.layout
		var r: Rect2 = layout.bounds
		if not r.intersects(view):
			continue
		var c := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
		for i in 4:
			_dashed(to_screen(c[i]), to_screen(c[(i + 1) % 4]), BORDER)
		var name_at := to_screen(Vector2(layout.play_area.get_center().x, layout.bounds.position.y)) + Vector2(0, 28)
		var px := 18 if scale_px < 10.0 else 15
		var label := layout.name.to_upper()
		var w := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x if _font != null else 0.0
		_text(name_at + Vector2(-w * 0.5 + 1.5, 1.5), label, px, Color("1b1611", 0.9))
		_text(name_at - Vector2(w * 0.5, 0), label, px, COPPER)


func _dashed(a: Vector2, b: Vector2, col: Color, clip: bool = true) -> void:
	var length := a.distance_to(b)
	var dir := (b - a) / maxf(length, 0.001)
	var t := 0.0
	while t < length:
		var p := a + dir * t
		var q := a + dir * minf(t + 9.0, length)
		var seg := Rect2(p, Vector2.ZERO).expand(q)
		if not clip or map_rect.grow(2.0).intersects(seg.grow(1.0)):
			draw_line(p, q, col, 2.0)
		t += 15.0


func _draw_street_names(view: Rect2) -> void:
	var seen := {}
	for dist in minimap.districts:
		var layout: DistrictLayout = dist.layout
		for s in layout.streets:
			var r: Rect2 = (s.rect as Rect2).intersection(layout.play_area.grow(60.0))
			if not r.has_area() or not r.intersects(view):
				continue
			var label := String(s.name).to_upper()
			var key := "%s@%d" % [label, roundi(r.get_center().y if r.size.x > r.size.y else r.get_center().x)]
			if r.size.x > r.size.y:
				var y := to_screen(Vector2(0, r.get_center().y)).y + 4.0
				var x := maxf(to_screen(r.position).x, map_rect.position.x) + 12.0
				if not seen.has(key + str(int(x / 600.0))):
					seen[key + str(int(x / 600.0))] = true
					_text(Vector2(x, y), label, 11, Minimap.LABEL)
			else:
				var x2 := to_screen(Vector2(r.get_center().x, 0)).x - 4.0
				var y2 := maxf(to_screen(r.position).y, map_rect.position.y) + 14.0
				draw_set_transform(Vector2(x2, y2), PI / 2, Vector2.ONE)
				_text(Vector2.ZERO, label, 11, Minimap.LABEL)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_key() -> void:
	var x := size.x - MARGIN - KEY_WIDTH
	var y := MARGIN + 4.0
	_text(Vector2(x, y + 14.0), "THE CITY", 18, COPPER)
	y += 34.0
	var rows: Array = []
	for pl in minimap.places:
		rows.append([pl.tex, _place_name(pl.id)])
	for l in landmarks:
		if l.tex != null:
			rows.append([l.tex, l.label])
	for row in rows:
		draw_texture_rect(row[0], Rect2(Vector2(x, y), Vector2(ICON * 0.81, ICON)), false)
		_text(Vector2(x + 28.0, y + 17.0), row[1], 13, INK)
		y += 27.0
	y += 4.0
	draw_set_transform(Vector2(x + 10.0, y + 10.0), 0.0, Vector2.ONE)
	draw_texture_rect(minimap._player_tex, Rect2(-Vector2(9, 9), Vector2(18, 18)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_text(Vector2(x + 28.0, y + 15.0), "You", 13, INK)
	y += 25.0
	draw_rect(Rect2(x + 3.0, y + 6.0, 14, 7), COPPER)
	_text(Vector2(x + 28.0, y + 15.0), "Your car", 13, INK)
	y += 25.0
	draw_texture_rect(minimap._police_tex, Rect2(Vector2(x + 1.0, y + 1.0), Vector2(17, 17)), false)
	_text(Vector2(x + 28.0, y + 15.0), "A beat cop", 13, INK)
	y += 25.0
	_dashed(Vector2(x, y + 10.0), Vector2(x + 24.0, y + 10.0), BORDER, false)
	_text(Vector2(x + 28.0, y + 15.0), "District border", 13, INK)
	y += 34.0
	if job_text != "":
		_text(Vector2(x, y), "ROURKE'S JOB", 13, COPPER)
		y += 18.0
		for line in _wrap(job_text, 12, KEY_WIDTH):
			_text(Vector2(x, y), line, 12, INK)
			y += 16.0
		y += 12.0
	recentre_rect = Rect2(x, y, KEY_WIDTH - 10.0, 26.0)
	draw_rect(recentre_rect, Color(COPPER, 0.18))
	draw_rect(recentre_rect, COPPER, false, 1.5)
	_text(Vector2(x + 10.0, y + 18.0), "R   Back to you", 13, INK)
	y += 40.0
	for line in ["Drag   look round", "Wheel   closer / farther", "M or Esc   close"]:
		_text(Vector2(x, y), line, 12, DIM)
		y += 17.0


func _place_name(id: String) -> String:
	for dist in minimap.districts:
		for plan in (dist.layout as DistrictLayout).interiors:
			if (plan as InteriorPlan).id == id:
				return "Your flat" if (plan as InteriorPlan).is_home else (plan as InteriorPlan).name
	return id


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


func _text(at: Vector2, s: String, px: int, col: Color) -> void:
	if _font != null:
		draw_string(_font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)


func _label(centre_at: Vector2, s: String, px: int, col: Color) -> void:
	if _font == null:
		return
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_string_outline(_font, centre_at - Vector2(w * 0.5, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 4, Color("1b1611"))
	draw_string(_font, centre_at - Vector2(w * 0.5, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)
