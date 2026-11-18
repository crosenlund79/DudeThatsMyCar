class_name Minimap
extends Control
## A small north-up map of the streets round the player (bottom-left of the
## HUD): the district painted once into an image (streets, sidewalks,
## buildings, alleys, yards, the river and the raised bridge), the places you
## can walk into with the same badges as their markers in the street (pinned
## to the rim when they are off the map, so you can head for them), the beat
## cop's badge, and you as an arrow in the middle that turns with you.
## Street names along the roads. Presentation only.
## M008: every district has its own painted image, placed where the district
## lies in the world, so the map runs on across a border; every loaded beat
## cop shows.

## Size on screen (px) and the frame round it.
const SIZE := Vector2(200, 200)
const BORDER := 10.0
## World px per pixel of the painted map images.
const IMAGE_SCALE := 4.0
## World px per screen px: on foot, and in a car at full speed.
const ZOOM_FOOT := 8.0
const ZOOM_FAST := 11.5
const ICON := 20.0
const PLAYER_ICON := 15.0
const POLICE_ICON := 13.0

const VOID := Color("17130f")
const BLOCK := Color("6a5b45")
const LOT := Color("594c3a")
const STREET := Color("cdbb92")
const ALLEY := Color("a08a62")
const BUILDING := Color("33291f")
const BUILDING_EDGE := Color("1d1712")
const PLACE := Color("6a3a24")
const WATER := Color("26404e")
const STEEL := Color("6b6e74")
const LABEL := Color("3a2a1a")

## The Riverside Ward (its rooms give the places), and every district's map:
## {layout, image, texture, rect (world)}.
var layout: DistrictLayout
var districts: Array = []
## World point at the middle of the map, how many world px a screen px is,
## and which way the player faces (radians, 0 = east).
var centre := Vector2.ZERO
var zoom := ZOOM_FOOT
var heading := 0.0
## Places: {pos (world), tex, home: bool}; the officer (Vector2.INF: none).
var places: Array = []
var police := Vector2.INF
var police_hunting := false
## M008: the other loaded districts' beat cops: [{pos, hunting}].
var other_police: Array = []
var _player_tex: Texture2D
var _police_tex: Texture2D
var _frame: StyleBoxTexture
var _font: Font
var _time := 0.0


func setup(p_layout: DistrictLayout, resolver: AssetResolver, frame: StyleBoxTexture, font: Font) -> void:
	layout = p_layout
	name = "Minimap"
	size = SIZE
	custom_minimum_size = SIZE
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_district(layout)
	_player_tex = resolver.get_texture("ui/map_player")
	_police_tex = resolver.get_texture("ui/map_police")
	_frame = frame.duplicate() as StyleBoxTexture
	_frame.draw_center = false
	# only the copper rim of the HUD frame: a thin edge, most of the map stays visible
	var t := _frame.texture.get_size() / 96.0
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_frame.set_texture_margin(side, 12.0 * t.x)
	_font = font
	for plan in layout.interiors:
		var p: InteriorPlan = plan
		if p.marker != "" and not p.doors.is_empty():
			places.append({"pos": p.outside_door(0, 10.0), "tex": resolver.get_texture(p.marker), "home": p.is_home,
				"id": p.id})


## M008: a district's map, painted once from its plan (it need not be built).
func add_district(d: DistrictLayout) -> void:
	var img := paint(d)
	districts.append({"layout": d, "image": img, "texture": ImageTexture.create_from_image(img), "rect": d.bounds})


## The district painted once: one image pixel per IMAGE_SCALE world px, its bounds exactly.
static func paint(d: DistrictLayout) -> Image:
	var origin := d.bounds.position
	var px := Vector2i((d.bounds.size / IMAGE_SCALE).ceil())
	var img := Image.create(px.x, px.y, false, Image.FORMAT_RGBA8)
	img.fill(VOID)
	var to_px := func(r: Rect2) -> Rect2i:
		var a := ((r.position - origin) / IMAGE_SCALE).floor()
		var b := ((r.end - origin) / IMAGE_SCALE).ceil()
		return Rect2i(Vector2i(a), Vector2i(b - a))
	for w in d.water:
		img.fill_rect(to_px.call(w), WATER)
	for b in d.blocks:
		img.fill_rect(to_px.call(b), BLOCK)
	for l in d.lots:
		img.fill_rect(to_px.call((l.rect as Rect2).grow(-1.0)), LOT)
	for s in d.streets:
		img.fill_rect(to_px.call(s.rect), STREET)
	for a in d.alleys:
		img.fill_rect(to_px.call(a.rect), ALLEY)
	var marked := {}
	for plan in d.interiors:
		if (plan as InteriorPlan).marker != "":
			marked[(plan as InteriorPlan).building] = true
	for i in d.buildings.size():
		var b: Dictionary = d.buildings[i]
		var r: Rect2i = to_px.call(b.rect)
		var fill := STEEL if b.facade == "steel" else (PLACE if marked.has(i) else BUILDING)
		img.fill_rect(r, BUILDING_EDGE)
		if r.size.x > 2 and r.size.y > 2:
			img.fill_rect(r.grow(-1), fill)
	return img


## The colour painted under a world point (for tests and for reading the map).
## M010: something worth a look nearby - a ring that spreads once and fades
## where it happens (on the map), or an arrow on the rim pointing towards it
## while it lasts (off the map, same district). Not a quest marker.
const PING_TIME := 2.4
const PING_COLOUR := Color("e8743c")
var pings: Array = []
var arrows: Array[Vector2] = []


func ping(world: Vector2) -> void:
	pings.append({"pos": world, "age": 0.0})


func set_arrows(world_points: Array[Vector2]) -> void:
	arrows = world_points


func colour_at(world: Vector2) -> Color:
	for dist in districts:
		var r: Rect2 = dist.rect
		if r.has_point(world):
			var img: Image = dist.image
			var p := ((world - r.position) / IMAGE_SCALE).floor().clamp(Vector2.ZERO, Vector2(img.get_size() - Vector2i.ONE))
			return img.get_pixelv(Vector2i(p))
	return VOID


## Where a world point shows on the map (local px; the player is in the middle).
func to_map(world: Vector2) -> Vector2:
	return SIZE * 0.5 + (world - centre) / zoom


## The map round the player: where he is, which way he faces, whether he
## drives (and how fast, 0..1), and where the beat cop is.
func set_view(p_centre: Vector2, p_heading: float, speed_ratio: float, p_police: Vector2, hunting: bool, delta: float) -> void:
	centre = p_centre
	heading = p_heading
	var want := lerpf(ZOOM_FOOT, ZOOM_FAST, clampf(speed_ratio, 0.0, 1.0))
	zoom = lerpf(zoom, want, 1.0 - exp(-delta * 2.0)) if delta > 0.0 else want
	police = p_police
	police_hunting = hunting
	_time += delta
	for pg in pings:
		pg.age = float(pg.age) + delta
	pings = pings.filter(func(pg: Dictionary) -> bool: return float(pg.age) < PING_TIME)
	queue_redraw()


## A place's position on the map, pulled in to the rim when it is off the map.
func place_on_map(world: Vector2) -> Dictionary:
	var p := to_map(world)
	var inner := Rect2(Vector2(BORDER + ICON * 0.5, BORDER + ICON * 0.8), SIZE - Vector2(BORDER * 2.0 + ICON, BORDER * 2.0 + ICON))
	if inner.has_point(p):
		return {"at": p, "on_map": true}
	var mid := SIZE * 0.5
	var dir := p - mid
	var t := 1.0
	if absf(dir.x) > 0.001:
		t = minf(t, absf((inner.size.x * 0.5) / dir.x))
	if absf(dir.y) > 0.001:
		t = minf(t, absf((inner.size.y * 0.5) / dir.y))
	return {"at": mid + dir * t, "on_map": false}


func _draw() -> void:
	if districts.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, SIZE), VOID)
	var view := Rect2(centre - SIZE * 0.5 * zoom, SIZE * zoom)
	for dist in districts:
		var r: Rect2 = dist.rect
		var part := r.intersection(view)
		if not part.has_area():
			continue
		var src := Rect2((part.position - r.position) / IMAGE_SCALE, part.size / IMAGE_SCALE)
		draw_texture_rect_region(dist.texture, Rect2(to_map(part.position), part.size / zoom), src)
	_draw_street_names()
	# the places, then the copper, then you on top
	for pl in places:
		var where := place_on_map(pl.pos)
		var tex: Texture2D = pl.tex
		var s := ICON if where.on_map else ICON * 0.8
		var sz := Vector2(s * 0.81, s)
		var col := Color(1, 1, 1, 1.0 if where.on_map else 0.7)
		draw_texture_rect(tex, Rect2((where.at as Vector2) - Vector2(sz.x * 0.5, sz.y), sz), false, col)
	var cops := other_police.duplicate()
	if police != Vector2.INF:
		cops.push_front({"pos": police, "hunting": police_hunting})
	for cop in cops:
		var cp := to_map(cop.pos)
		if Rect2(Vector2.ZERO, SIZE).grow(-BORDER).has_point(cp):
			var c := Color(1, 1, 1)
			if cop.hunting:
				c = Color(1.0, 0.45, 0.4) if fmod(_time, 0.6) < 0.3 else Color(1, 1, 1)
			draw_texture_rect(_police_tex, Rect2(cp - Vector2(POLICE_ICON, POLICE_ICON) * 0.5, Vector2(POLICE_ICON, POLICE_ICON)), false, c)
	for pg in pings:  # M010
		var t: float = float(pg.age) / PING_TIME
		var at := to_map(pg.pos)
		draw_arc(at, 3.0 + 15.0 * t, 0.0, TAU, 28, Color(PING_COLOUR, 1.0 - t), 2.0)
		draw_circle(at, 2.5, Color(PING_COLOUR, 1.0 - t))
	for ap in arrows:
		var rim: Dictionary = place_on_map(ap)
		if rim.on_map:
			continue
		var dir := ((rim.at as Vector2) - SIZE * 0.5).normalized()
		var tip: Vector2 = (rim.at as Vector2) + dir * 6.0
		var side := dir.orthogonal() * 5.0
		draw_colored_polygon(PackedVector2Array([tip, tip - dir * 10.0 + side, tip - dir * 10.0 - side]), PING_COLOUR)
		draw_polyline(PackedVector2Array([tip, tip - dir * 10.0 + side, tip - dir * 10.0 - side, tip]), Color("1d1712"), 1.0)
	draw_set_transform(SIZE * 0.5, heading, Vector2.ONE)
	draw_texture_rect(_player_tex, Rect2(-Vector2(PLAYER_ICON, PLAYER_ICON) * 0.5, Vector2(PLAYER_ICON, PLAYER_ICON)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the frame, and north on top of it
	draw_style_box(_frame, Rect2(Vector2.ZERO, SIZE))
	if _font != null:
		draw_circle(Vector2(SIZE.x * 0.5, 8.0), 7.0, Color("16130f"))
		draw_string(_font, Vector2(SIZE.x * 0.5 - 4.0, 12.5), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("d8a060"))


## Street names along the roads in view (east-west along them, north-south turned).
func _draw_street_names() -> void:
	if _font == null:
		return
	var view := Rect2(centre - SIZE * 0.5 * zoom, SIZE * zoom)
	var streets := []
	for dist in districts:
		var dl: DistrictLayout = dist.layout
		for s in dl.streets:
			var cut := (s.rect as Rect2).intersection(dl.play_area.grow(60.0))
			if cut.has_area():
				streets.append({"name": s.name, "rect": cut})
	for s in streets:
		var r: Rect2 = s.rect
		if not r.intersects(view):
			continue
		var label := DistrictLayout.short_name(s.name).to_upper()
		if r.size.x > r.size.y:
			var y := to_map(Vector2(0, r.get_center().y)).y + 4.0
			var x := clampf(to_map(Vector2(maxf(r.position.x, view.position.x), 0)).x + 16.0, BORDER + 6.0, SIZE.x - 90.0)
			if y > BORDER + 10.0 and y < SIZE.y - BORDER:
				draw_string(_font, Vector2(x, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LABEL)
		else:
			var x2 := to_map(Vector2(r.get_center().x, 0)).x - 4.0
			var y2 := clampf(to_map(Vector2(0, maxf(r.position.y, view.position.y))).y + 16.0, BORDER + 16.0, SIZE.y - 90.0)
			if x2 > BORDER and x2 < SIZE.x - BORDER - 10.0:
				draw_set_transform(Vector2(x2, y2), PI / 2, Vector2.ONE)
				draw_string(_font, Vector2.ZERO, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LABEL)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
