class_name InteriorView
extends Node2D
## Draws one InteriorPlan as a cut-away: while the player is inside, the host
## building (walls, roof, rooftop signs) fades out and the room shows from
## above: the floor, the closed rest of the house in shadow, walls with a soft
## shadow at their foot, furniture, swinging doors, the people who work there
## and warm lamps (lit only while you are inside). Outside, the building looks
## as it always did and the room is hidden. Presentation only.

## Seconds for the roof to fade out (and back in).
const FADE_TIME := 0.3
## Doors swing open when someone is this close (px).
const DOOR_REACH := 40.0
const CUT_COLOR := Color(0.085, 0.07, 0.065)
const WALL_COLOR := Color(0.17, 0.13, 0.11)
const WALL_EDGE := Color(0.42, 0.33, 0.26)

var plan: InteriorPlan
var host: BuildingView
## 0 = outside (building drawn), 1 = inside (cut-away shown).
var alpha := 0.0
var inside := false
var lights: Array[PointLight2D] = []
var people := {}  # id -> Walker
## Whoever may push the doors open (the player's body, set by the game).
var visitors: Array[Node2D] = []
var _doors: Array = []  # {node: Sprite2D, hinge_open: float, at: Vector2}
var _energy: Array[float] = []


func setup(p_plan: InteriorPlan, p_host: BuildingView, resolver: AssetResolver) -> void:
	plan = p_plan
	host = p_host
	name = "Interior_" + plan.id
	var floor_tex := resolver.get_texture(plan.floor)
	var base := DrawLayer.new(_draw_base, Layers.Z_DECAL)
	add_child(base)
	_floor(floor_tex)
	add_child(DrawLayer.new(_draw_wall_shadows, Layers.Z_DECAL + 2, false, 0))
	for f in plan.furniture:
		var s := _sprite(resolver, f.kind, f.pos, f.get("rot", 0.0), Layers.Z_PROP + int(f.get("z", 0)))
		s.name = String(f.kind).get_file()
	add_child(DrawLayer.new(_draw_walls, Layers.Z_PROP + 4))
	var door_tex := resolver.get_texture("interiors/door")
	for i in plan.doors.size():
		_add_door(door_tex, plan.door_centre(i), plan.doors[i].side, plan.doors[i].width)
	for p in plan.partitions:
		if not is_nan(float(p.get("door_at", NAN))):
			var a: Vector2 = p.a
			var b: Vector2 = p.b
			var horizontal := absf(a.y - b.y) < 0.01
			var at: float = p.door_at
			var centre := Vector2(at, a.y) if horizontal else Vector2(a.x, at)
			_add_door(door_tex, centre, Vector2.DOWN if horizontal else Vector2.RIGHT, p.get("door_width", 28.0))
	for l in plan.lamps:
		var light := PointLight2D.new()
		light.texture = LightTextures.radial()
		light.texture_scale = float(l.radius) * 2.0 / 256.0
		light.color = l.color
		light.energy = 0.0
		light.position = l.pos
		light.range_item_cull_mask = Layers.LIGHT_STREET
		add_child(light)
		lights.append(light)
		_energy.append(float(l.energy))
		var halo := _sprite(resolver, "fx/glow", l.pos, 0.0, Layers.Z_RAISED_GLOW)
		halo.material = DrawLayer.glow_material()
		halo.scale = AssetCatalog.scale_for(halo.texture, Vector2(70, 70))
		halo.modulate = Color(l.color, 0.35)
	for p in plan.people:
		var w := Walker.create(resolver, p.look, {"glow": false})
		w.name = String(p.id).capitalize().replace(" ", "")
		add_child(w)
		w.place(p.pos, p.facing)
		w.aim_point = p.pos + Vector2.from_angle(p.facing) * 50.0
		people[p.id] = w
	visible = false
	_apply()


## Turns a person to face a point (talking to the player).
func face(person_id: String, at: Vector2) -> void:
	var w: Walker = people.get(person_id)
	if w != null:
		w.aim_point = at


## Turns everyone back to their own place.
func face_home() -> void:
	for p in plan.people:
		var w: Walker = people.get(p.id)
		if w != null:
			w.aim_point = (p.pos as Vector2) + Vector2.from_angle(p.facing) * 50.0


func set_inside(on: bool, instant: bool = false) -> void:
	inside = on
	if instant:
		alpha = 1.0 if on else 0.0
		_apply()


func _process(delta: float) -> void:
	var target := 1.0 if inside else 0.0
	if alpha != target:
		alpha = move_toward(alpha, target, delta / FADE_TIME)
		_apply()
	if visible:
		_swing_doors(delta)


func _apply() -> void:
	visible = alpha > 0.0
	for w in people.values():
		(w as Walker).active = visible  # nobody to see them move while you are outside
	modulate = Color(1, 1, 1, alpha)
	if host != null:
		host.modulate = Color(1, 1, 1, 1.0 - alpha)
		host.visible = alpha < 1.0
	for i in lights.size():
		lights[i].energy = _energy[i] * alpha
		lights[i].enabled = alpha > 0.0


func _add_door(tex: Texture2D, centre: Vector2, side: Vector2, width: float) -> void:
	# the leaf hangs on the hinge at one end of the gap and swings inwards
	var along := side.orthogonal()
	var hinge := centre - along * width * 0.5
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	var size := Vector2(width, 5.0)
	s.scale = size / Vector2(tex.get_size())
	s.offset = Vector2(0, -tex.get_height() * 0.5)
	s.position = hinge
	s.rotation = along.angle()
	s.z_index = Layers.Z_PROP + 5
	s.light_mask = Layers.LIGHT_STREET
	add_child(s)
	# open, the leaf stands into the room
	var open := (-side).angle()
	_doors.append({"node": s, "closed": along.angle(), "open": open, "at": centre, "t": 0.0})


func _swing_doors(delta: float) -> void:
	for d in _doors:
		var near := false
		for v in visitors:
			if is_instance_valid(v) and v.visible and v.global_position.distance_to(d.at) <= DOOR_REACH:
				near = true
		for w in people.values():
			if (w as Walker).global_position.distance_to(d.at) <= DOOR_REACH * 0.6:
				near = true
		d.t = move_toward(d.t, 1.0 if near else 0.0, delta * 4.0)
		var e: float = d.t * d.t * (3.0 - 2.0 * d.t)
		(d.node as Sprite2D).rotation = lerp_angle(d.closed, d.open, e)


func _sprite(resolver: AssetResolver, logical: String, pos: Vector2, rot: float, z: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = resolver.get_texture(logical)
	s.scale = AssetCatalog.scale_for(s.texture, AssetCatalog.display_size(logical))
	s.position = pos
	s.rotation = rot
	s.z_index = z
	s.light_mask = Layers.LIGHT_STREET
	add_child(s)
	return s


## The floor, cut into squares so no piece takes more than a handful of lights.
func _floor(t: Texture2D) -> void:
	var inner := plan.room.grow(-InteriorPlan.WALL * 0.5)
	var uv_scale := AssetCatalog.uv_per_world_pixel(t, AssetCatalog.SPECS[plan.floor].tile_world_size)
	var chunk := 192.0
	var x := inner.position.x
	while x < inner.end.x - 0.01:
		var y := inner.position.y
		while y < inner.end.y - 0.01:
			var part := Rect2(x, y, minf(chunk, inner.end.x - x), minf(chunk, inner.end.y - y))
			var poly := Polygon2D.new()
			poly.polygon = City.rect_points(part)
			poly.texture = t
			poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			var uvs := PackedVector2Array()
			for v in poly.polygon:
				uvs.append(v * uv_scale)
			poly.uv = uvs
			poly.z_index = Layers.Z_DECAL + 1
			poly.light_mask = Layers.LIGHT_STREET
			add_child(poly)
			y += chunk
		x += chunk


## The closed rest of the house keeps its roof (drawn flat; you stand right
## under it), with a dark edge where the cut runs.
func _draw_base(ci: CanvasItem) -> void:
	var r := plan.building_rect
	if host == null or host.roof_tex == null:
		ci.draw_rect(r, CUT_COLOR)
		return
	var pts := City.rect_points(r)
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append(p / 256.0)
	var tint := host.roof_tint * Color(0.62, 0.62, 0.7)
	ci.draw_polygon(pts, PackedColorArray([tint]), uvs, host.roof_tex)
	ci.draw_rect(r.grow(-2.0), CUT_COLOR, false, 4.0)


## A soft shadow along the foot of every wall, so the walls read as standing up.
func _draw_wall_shadows(ci: CanvasItem) -> void:
	var dark := Color(0.0, 0.0, 0.0, 0.55)
	var clear := Color(0.0, 0.0, 0.0, 0.0)
	var w := 16.0
	for box in plan.wall_boxes():
		var c := City.rect_points(box)
		var o := City.rect_points(box.grow(w))
		for i in 4:
			var j := (i + 1) % 4
			ci.draw_polygon(PackedVector2Array([c[i], c[j], o[j], o[i]]), PackedColorArray([dark, dark, clear, clear]))


## Walls from above: dark tops with a lit edge.
func _draw_walls(ci: CanvasItem) -> void:
	for box in plan.wall_boxes():
		ci.draw_rect(box, WALL_COLOR)
		ci.draw_rect(box.grow(-1.0), WALL_EDGE, false, 1.0)
