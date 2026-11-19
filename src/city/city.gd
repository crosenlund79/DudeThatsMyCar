class_name City
extends Node2D
## Builds a district from its DistrictLayout: the ground (streets, sidewalks,
## curbs, alleys, yards, the streetcar tracks, the river), the solid footprint
## of every building and obstacle, the buildings themselves (BuildingView),
## street furniture, street lamps and the night atmosphere. Every frame the
## camera tells it where the eye is (update_view) so everything raised above
## the street is drawn in perspective.

## Ground is cut into squares this size: a canvas item takes at most ~15 lights.
const CHUNK := 256.0
const LAMP_HEIGHT := 72.0
const LAMP_RADIUS := 215.0
const LAMP_COLOR := Color(1.0, 0.79, 0.5)
const CURB_RADIUS := 26.0
## Sidewalk width inside every block.
const SIDEWALK := 46.0
## Facades whose ground floor is lit shop windows (light spills onto the pavement).
const SHOPFRONTS := ["brick_brown", "club", "garage"]

var layout: DistrictLayout
var resolver: AssetResolver
var solids: StaticBody2D
var buildings: Array[BuildingView] = []
var lamp_lights: Array[PointLight2D] = []
var atmosphere: NightAtmosphere
var eye := Vector2.ZERO
var eye_height := 1500.0
## Raised sprites (lamp heads, awnings, canopy, halos): {node, pos, height, scale}
var _raised: Array = []
## Wet-street reflections of lamps: {node, pos, height}
var _reflections: Array = []
var _ground: Node2D
## M010: fences standing up (their faces drawn in perspective like the walls).
const FENCE_HEIGHT := 32.0  # a little taller than life, so its face reads from above
const FENCE_REPEAT := 64.0
const FENCE_ART := {"boards": "fences/boards", "chain": "fences/chain", "iron": "fences/iron"}
var _fence_faces: Array = []
var _fence_layer: DrawLayer
var _view := Rect2()
var _props: Node2D
var _lights: Node2D
## Layout index of each entry in `buildings` (they are built lowest first).
var _building_order: Array[int] = []


## Builds the whole district at once (the Riverside Ward at start-up).
## `primary`: this city owns the night's screen-wide effects (the tint, the
## moonlight, the haze, the vignette); a neighbouring district streamed in
## beside it brings only its own steam and smoke (M008).
func build(p_layout: DistrictLayout, p_resolver: AssetResolver, primary: bool = true) -> void:
	for step in build_steps(p_layout, p_resolver, primary):
		step.call()


## M008: the same work cut into small steps, to be called in order - a
## district streamed in while Danny drives builds a few of them a frame.
func build_steps(p_layout: DistrictLayout, p_resolver: AssetResolver, primary: bool = true) -> Array[Callable]:
	var steps: Array[Callable] = [_begin.bind(p_layout, p_resolver)]
	for i in p_layout.streets.size():
		steps.append(_ground_street.bind(i))
	steps.append(_ground_cobbles)
	for i in p_layout.blocks.size():
		steps.append(_ground_block.bind(i))
	steps.append(_ground_lots_and_water)
	steps.append(_ground_edges)
	steps.append(_ground_details)
	steps.append(_begin_buildings)
	var order := range(p_layout.buildings.size())
	order.sort_custom(func(a: int, b: int) -> bool: return p_layout.buildings[a].storeys < p_layout.buildings[b].storeys)
	for i in order:
		steps.append(_build_building.bind(i))
	for k in range(0, p_layout.props.size(), 16):
		steps.append(_build_props_range.bind(k, mini(k + 16, p_layout.props.size())))
	steps.append(_build_quays_fences_and_spill)
	for k in range(0, p_layout.lamps.size(), 8):
		steps.append(_build_lamps_range.bind(k, mini(k + 8, p_layout.lamps.size())))
	steps.append(_build_alley_lamps)
	steps.append(_build_atmosphere.bind(primary))
	return steps


func _begin(p_layout: DistrictLayout, p_resolver: AssetResolver) -> void:
	layout = p_layout
	resolver = p_resolver
	for child in get_children():
		child.free()
	buildings.clear()
	_building_order.clear()
	lamp_lights.clear()
	_raised.clear()
	_reflections.clear()
	_ground = _child("Ground")
	_props = _child("Props")
	_lights = _child("Lights")
	solids = StaticBody2D.new()
	solids.name = "Solids"
	solids.collision_layer = Layers.WORLD
	solids.collision_mask = 0
	add_child(solids)


func _build_atmosphere(primary: bool) -> void:
	atmosphere = NightAtmosphere.new()
	atmosphere.name = "Atmosphere"
	add_child(atmosphere)
	atmosphere.setup(self, primary)


func _child(n: String) -> Node2D:
	var node := Node2D.new()
	node.name = n
	add_child(node)
	return node


func tex(logical: String) -> Texture2D:
	return resolver.get_texture(logical)


# ------------------------------------------------------------------ ground

# Each patch of ground is drawn once where it shows: asphalt on the streets,
# a ring of sidewalk round each block, yard ground only where no building
# stands (overdraw is what costs most on slow graphics).
func _ground_street(i: int) -> void:
	_fill_rect((layout.streets[i].rect as Rect2).intersection(layout.bounds), "city/asphalt", Layers.Z_GROUND)


func _ground_cobbles() -> void:
	for c in layout.cobbles:
		_fill_rect(c, "city/cobbles", Layers.Z_GROUND + 1, Color(0.72, 0.72, 0.76))


func _ground_block(i: int) -> void:
	var r: Rect2 = layout.blocks[i]
	for part in sidewalk_ring(r, CURB_RADIUS, SIDEWALK):
		_fill_poly(part, "city/sidewalk", Layers.Z_GROUND + 2)
	for yard in _open_ground(r.grow(-SIDEWALK)):
		_fill_poly(yard, "city/lot", Layers.Z_GROUND + 3)


func _ground_lots_and_water() -> void:
	for l in layout.lots:
		_fill_rect(l.rect, {"concrete": "city/sidewalk", "grass": "city/grass"}.get(String(l.kind), "city/lot"), Layers.Z_GROUND + 4)
	for w in layout.water:
		_fill_rect(w, "city/water", Layers.Z_GROUND + 5, Color.WHITE, Layers.LIGHT_STREET | Layers.LIGHT_ROOF)


func _ground_edges() -> void:
	for b in layout.blocks:
		var r2: Rect2 = b
		if layout.water.any(func(w: Rect2) -> bool: return w.intersects(r2.grow(1))):
			continue  # the river side has a quay, not a curb
		_strip(rounded_rect(r2, CURB_RADIUS), "city/curb", Layers.Z_CURB, true)
	for a in layout.alleys:
		_fill_rect(a.rect, "city/alley", Layers.Z_CURB + 1)
	for r3 in layout.rails:
		_strip(PackedVector2Array([r3[0], r3[1]]), "city/rails", Layers.Z_GROUND_DETAIL, false)
	for q in layout.quays:
		_strip(PackedVector2Array([q[0], q[1]]), "city/quay", Layers.Z_CURB, false)
	for w in layout.water:
		var far: Rect2 = w
		_strip(PackedVector2Array([Vector2(far.end.x, far.end.y), Vector2(far.end.x, far.position.y)]), "city/quay", Layers.Z_CURB, false)


func _ground_details() -> void:
	for dcl in layout.decals:
		var s := _sprite(dcl.kind, dcl.pos, dcl.rot, Layers.Z_DECAL, _ground)
		s.scale *= float(dcl.get("scale", 1.0))
		if dcl.kind == "decals/puddle":
			s.modulate = Color(1, 1, 1, 0.85)
	_shadow_mesh = Shadows.mesh_of(layout.ground_shadows())
	var ao := DrawLayer.new(_draw_building_shadows, Layers.Z_SHADOW, false, 0)
	ao.name = "BuildingShadows"
	_ground.add_child(ao)
	# M010: the street's rubbish, all of it one layer drawn once from one sheet (no collision;
	# scattered at start-up with the district's other data)
	var grime := DrawLayer.new(_draw_grime, Layers.Z_DECAL + 1)
	grime.name = "Grime"
	_ground.add_child(grime)


## Rounded rectangle outline (clockwise on screen).
static func rounded_rect(r: Rect2, radius: float, steps: int = 6) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var rad := minf(radius, minf(r.size.x, r.size.y) * 0.5)
	var centres := [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	var start := [-90.0, 0.0, 90.0, 180.0]
	for k in 4:
		for i in steps + 1:
			var a := deg_to_rad(start[k] + 90.0 * i / steps)
			pts.append(centres[k] + Vector2(cos(a), sin(a)) * rad)
	return pts


## The sidewalk of a block as four hole-free pieces between the rounded curb
## and the square inner edge.
static func sidewalk_ring(r: Rect2, radius: float, width: float, steps: int = 6) -> Array[PackedVector2Array]:
	var outer := rounded_rect(r, radius, steps)
	var inner := rect_points(r.grow(-width))
	# outer arcs start at the top-right corner; inner corners in the same order
	var inner_order := [inner[1], inner[2], inner[3], inner[0]]
	var per_arc := steps + 1
	var mid := steps / 2
	var out: Array[PackedVector2Array] = []
	for k in 4:
		var piece := PackedVector2Array()
		var i := k * per_arc + mid
		var stop := ((k + 1) % 4) * per_arc + mid
		while true:
			piece.append(outer[i])
			if i == stop:
				break
			i = (i + 1) % outer.size()
		piece.append(inner_order[(k + 1) % 4])
		piece.append(inner_order[k])
		out.append(piece)
	return out


## Parts of a rectangle not covered by any building footprint.
func _open_ground(r: Rect2) -> Array[PackedVector2Array]:
	var parts: Array[PackedVector2Array] = [rect_points(r)]
	for b in layout.buildings:
		var br: Rect2 = b.rect
		if not br.intersects(r):
			continue
		var next: Array[PackedVector2Array] = []
		for p in parts:
			for c in Geometry2D.clip_polygons(p, rect_points(br)):
				next.append(c)
		parts = next
	return parts


static func rect_points(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


func _ground_poly(points: PackedVector2Array, texture: Texture2D, uv_scale: Vector2, z: int, tint: Color = Color.WHITE,
		mask: int = Layers.LIGHT_STREET) -> void:
	var p := Polygon2D.new()
	p.color = tint
	p.polygon = points
	p.texture = texture
	p.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var uvs := PackedVector2Array()
	for v in points:
		uvs.append(v * uv_scale)
	p.uv = uvs
	p.z_index = z
	p.light_mask = mask
	_ground.add_child(p)


func _cells(area: Rect2) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var x0 := floorf(area.position.x / CHUNK)
	var y0 := floorf(area.position.y / CHUNK)
	var x1 := ceilf(area.end.x / CHUNK)
	var y1 := ceilf(area.end.y / CHUNK)
	for cx in range(int(x0), int(x1)):
		for cy in range(int(y0), int(y1)):
			out.append(Rect2(cx * CHUNK, cy * CHUNK, CHUNK, CHUNK))
	return out


func _fill_rect(r: Rect2, logical: String, z: int, tint: Color = Color.WHITE, mask: int = Layers.LIGHT_STREET) -> void:
	var t := tex(logical)
	var uv_scale := AssetCatalog.uv_per_world_pixel(t, AssetCatalog.SPECS[logical].tile_world_size)
	for cell in _cells(r):
		var part := r.intersection(cell)
		if part.has_area():
			_ground_poly(rect_points(part), t, uv_scale, z, tint, mask)


func _fill_poly(poly: PackedVector2Array, logical: String, z: int) -> void:
	var t := tex(logical)
	var uv_scale := AssetCatalog.uv_per_world_pixel(t, AssetCatalog.SPECS[logical].tile_world_size)
	var bb := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		bb = bb.expand(p)
	for cell in _cells(bb):
		for part in Geometry2D.intersect_polygons(poly, rect_points(cell)):
			if part.size() >= 3:
				_ground_poly(part, t, uv_scale, z)


## A textured strip along a line (curbs, rails, quays), cut into short pieces.
func _strip(points: PackedVector2Array, logical: String, z: int, closed: bool) -> void:
	var t := tex(logical)
	var pts := PackedVector2Array(points)
	if closed:
		pts.append(points[0])
	var piece := PackedVector2Array([pts[0]])
	var run := 0.0
	for i in range(1, pts.size()):
		var a := pts[i - 1]
		var b := pts[i]
		var seg := a.distance_to(b)
		var done := 0.0
		while run + (seg - done) > CHUNK:
			var cut := a.lerp(b, (done + CHUNK - run) / seg)
			piece.append(cut)
			_line(piece, t, logical, z)
			piece = PackedVector2Array([cut])
			done += CHUNK - run
			run = 0.0
		piece.append(b)
		run += seg - done
	if piece.size() >= 2:
		_line(piece, t, logical, z)


func _line(points: PackedVector2Array, t: Texture2D, logical: String, z: int) -> void:
	var line := Line2D.new()
	line.points = points
	line.width = AssetCatalog.SPECS[logical].strip_width
	line.texture = t
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.z_index = z
	line.light_mask = Layers.LIGHT_STREET
	_ground.add_child(line)


## Soft dark band round every building's foot (contact shadow / grime).
## M010: and the shadows cast the way every shadow falls (Shadows.DIR) from the
## buildings and the fences - one mesh, made with the district's data - and soft
## shadows under the solid street furniture.
func _draw_building_shadows(ci: CanvasItem) -> void:
	if _shadow_mesh == null:
		_shadow_mesh = Shadows.mesh_of(layout.ground_shadows())
	ci.draw_mesh(_shadow_mesh, null)
	var grid := Shadows.lamp_grid(layout.lamps + layout.alley_lamps)
	var blob := SoftShadow.texture()
	for pr in layout.props:
		var size := Vector2.ZERO
		if pr.has("box"):
			size = pr.box
		elif float(pr.get("radius", 0.0)) > 0.0:
			size = Vector2.ONE * float(pr.radius) * 2.0
		if size == Vector2.ZERO or float(pr.get("height", 0.0)) > 0.0:
			continue
		var at: Vector2 = pr.pos + Shadows.DIR * (minf(size.x, size.y) * 0.3 + 3.0)
		ci.draw_set_transform(at, float(pr.get("rot", 0.0)), Vector2.ONE)
		var s2 := size * 1.2 + Vector2(6, 6)
		ci.draw_texture_rect(blob, Rect2(-s2 * 0.5, s2), false, Color(1, 1, 1, 0.75 * Shadows.fill(pr.pos, grid)))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


var _shadow_mesh: ArrayMesh


static func _plain_mesh(tris: PackedVector2Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if tris.is_empty():
		return mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = tris
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
## M010: the weather on this district: fog gathered at the buildings' feet, and
## how wet the street looks (the lamps' reflections brighter in the rain).
var _fog_feet: DrawLayer
var _fog_mesh: ArrayMesh
## M010: the street fog itself, over this district's open ground (FogCover).
var fog_layer: DrawLayer
var _wet := -1.0


func set_weather(rain: float, fog: float, fog_color: Color, fog_material: Material = null, feet_material: Material = null) -> void:
	if _fog_feet == null and fog > 0.0:
		_fog_mesh = Shadows.mesh_of(layout.fog_feet())
		_fog_feet = DrawLayer.new(func(ci: CanvasItem) -> void: ci.draw_mesh(_fog_mesh, null), Layers.Z_STEAM + 1)
		_fog_feet.name = "FogFeet"
		_fog_feet.material = feet_material  # M012: kept out of an open room
		_props.add_child(_fog_feet)
		if fog_material != null:
			var cover := layout.fog_cover()
			var cover_mesh := _plain_mesh(cover)
			fog_layer = DrawLayer.new(func(ci: CanvasItem) -> void: ci.draw_mesh(cover_mesh, null), Layers.Z_STEAM + 1)
			fog_layer.name = "Fog"
			fog_layer.material = fog_material
			_props.add_child(fog_layer)
	if _fog_feet != null:
		_fog_feet.visible = fog > 0.01
		_fog_feet.modulate = Color(fog_color.r, fog_color.g, fog_color.b, fog * 0.9)
	if fog_layer != null:
		fog_layer.visible = fog > 0.01
	if absf(rain - _wet) > 0.01:
		_wet = rain
		for r in _reflections:
			(r.node as Sprite2D).modulate.a = 0.5 + 0.35 * rain




## M010: the street's rubbish (StreetGrime), each item a frame of one sheet.
func _draw_grime(ci: CanvasItem) -> void:
	var sheet := tex(StreetGrime.SHEET)
	if sheet == null:
		return
	var fw := sheet.get_width() / float(StreetGrime.FRAMES)
	var fh := float(sheet.get_height())
	for it in layout.grime_items():
		var size := StreetGrime.SIZE * float(it.scale)
		ci.draw_set_transform(it.pos, it.rot, Vector2.ONE)
		ci.draw_texture_rect_region(sheet, Rect2(-size * 0.5, -size * 0.5, size, size), Rect2(int(it.frame) * fw, 0, fw, fh),
			Color(0.95, 0.93, 0.9))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## M010: a fence as seen from above, where the camera looks straight down on it: a dark
## base, a lit top rail and posts at intervals, in its own materials - so you can see
## where it stands (drawn once).
func _draw_fence_tops(ci: CanvasItem) -> void:
	for f in _fence_faces:
		var a: Vector2 = f.a
		var b: Vector2 = f.b
		var along := (b - a).normalized()
		var length := a.distance_to(b)
		match String(f.kind):
			"chain":
				ci.draw_line(a, b, Color(0.05, 0.05, 0.06, 0.8), 9.0)
				ci.draw_line(a, b, Color(0.62, 0.66, 0.68, 0.6), 5.0)  # the mesh
				ci.draw_line(a, b, Color(0.86, 0.89, 0.9), 2.0)  # the top pipe
				_posts(ci, a, along, length, 48.0, 3.8, Color(0.9, 0.92, 0.94), true)
			"iron":
				ci.draw_line(a, b, Color(0.04, 0.04, 0.05, 0.85), 6.0)
				ci.draw_line(a, b, Color(0.32, 0.34, 0.38), 2.2)
				_posts(ci, a, along, length, 64.0, 4.0, Color(0.66, 0.64, 0.6), false)
			_:
				ci.draw_line(a, b, Color(0.05, 0.035, 0.025, 0.9), 14.0)
				ci.draw_line(a, b, Color(0.42, 0.32, 0.22), 7.0)  # the planks' tops
				ci.draw_line(a - along.orthogonal() * 3.0, b - along.orthogonal() * 3.0, Color(0.86, 0.72, 0.52), 1.8)  # the lit edge
				_posts(ci, a, along, length, 32.0, 5.0, Color(0.6, 0.47, 0.33), false)


func _posts(ci: CanvasItem, a: Vector2, along: Vector2, length: float, every: float, half: float, col: Color, round: bool) -> void:
	var t := 0.0
	while t <= length + 0.5:
		var p := a + along * minf(t, length)
		if round:
			ci.draw_circle(p, half, col)
		else:
			ci.draw_rect(Rect2(p - Vector2(half, half), Vector2(half, half) * 2.0), col)
			ci.draw_rect(Rect2(p - Vector2(half, half), Vector2(half, half) * 2.0), Color(0.08, 0.06, 0.05), false, 1.0)
		t += every


## M010: the fences' upright faces, in perspective (redrawn as the camera moves, only when near).
func _draw_fence_faces(ci: CanvasItem) -> void:
	for f in _fence_faces:
		if not _view.grow(260.0).intersects(f.rect):
			continue
		var a: Vector2 = f.a
		var b: Vector2 = f.b
		var pts := PackedVector2Array([a, b, Perspective.project(b, FENCE_HEIGHT, eye, eye_height),
			Perspective.project(a, FENCE_HEIGHT, eye, eye_height)])
		if absf(BuildingView._area(pts)) < 1.0:
			continue  # seen edge-on: its foot on the ground shows it
		var u := a.distance_to(b) / FENCE_REPEAT
		var uvs := PackedVector2Array([Vector2(0, 1), Vector2(u, 1), Vector2(u, 0), Vector2(0, 0)])
		var foot := Color(0.78, 0.78, 0.8)
		var top := Color(1.12, 1.1, 1.08)
		ci.draw_polygon(pts, PackedColorArray([foot, foot, top, top]), uvs, f.tex)


# ------------------------------------------------------------------ buildings

func _begin_buildings() -> void:
	_child("Buildings")


## Building i (they are built lowest first: see build_steps).
func _build_building(i: int) -> void:
	var holder := get_node("Buildings")
	if true:
		var b: Dictionary = layout.buildings[i]
		var r: Rect2 = b.rect
		if layout.interior_of(i) == null:  # rooms you can enter get their walls from Interiors
			var shape := CollisionShape2D.new()
			var box := RectangleShape2D.new()
			box.size = r.size
			shape.shape = box
			shape.position = r.get_center()
			solids.add_child(shape)
		var view := BuildingView.new()
		view.name = "Building%d" % i
		view.setup(r, b.storeys, _faces(i), tex("roofs/" + b.roof), tex("roofs/parapet") if not b.opts.get("bare", false) else null,
			_roof_items(b))
		view.fire_escape_tex = tex("props/fire_escape")
		var shade := 0.9 + 0.2 * float((i * 53) % 11) / 10.0
		view.roof_tint = Color(shade, shade * (0.97 + 0.03 * float(i % 3)), shade * (0.95 + 0.05 * float(i % 2)))
		holder.add_child(view)
		buildings.append(view)
		_building_order.append(i)


## Wall styles: the street front uses the building's facade, the alley side
## the rear (fire escapes), walls against or close to a neighbour are blank.
func _faces(index: int) -> Array:
	var b: Dictionary = layout.buildings[index]
	var r: Rect2 = b.rect
	var front: Vector2 = b.front
	var c := rect_points(r)
	var normals := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var out := []
	for i in 4:
		var a: Vector2 = c[i]
		var e: Vector2 = c[(i + 1) % 4]
		var n: Vector2 = normals[i]
		var style: String = b.facade
		if front != Vector2.ZERO and n != front:
			var probe := (a + e) * 0.5 + n * 6.0
			if _building_near(probe, index, 0.0):
				style = "party"
			elif n == -front:
				style = "rear" if b.facade in ["brick_red", "greystone", "brick_brown"] else b.facade
			elif _building_near(probe + n * 30.0, index, 12.0):
				style = "party"
		var lit_name := "facades/%s_lit" % style
		var escapes := []
		var length := a.distance_to(e)
		if b.storeys >= 2 and length >= 120.0 and (style == "rear" or (style == "brick_red" and b.storeys >= 3 and index % 2 == 0)):
			for k in clampi(int(length / 230.0), 1, 3):
				escapes.append((k + 0.5) / clampi(int(length / 230.0), 1, 3))
		out.append({"a": a, "b": e, "n": n, "tex": tex("facades/" + style), "escapes": escapes,
			"lit": tex(lit_name) if AssetCatalog.SPECS.has(lit_name) else null,
			"u0": float((index * 37 + i * 11) % 16) / 16.0})
	return out


func _building_near(p: Vector2, except: int, margin: float) -> bool:
	for j in layout.buildings.size():
		if j != except and (layout.buildings[j].rect as Rect2).grow(margin).has_point(p):
			return true
	return false


func _roof_items(b: Dictionary) -> Array:
	var items := []
	for p in b.props:
		var lit_name: String = p.kind + "_lit"
		items.append({"tex": tex(p.kind), "lit": tex(lit_name) if AssetCatalog.SPECS.has(lit_name) else null,
			"pos": p.pos, "size": AssetCatalog.display_size(p.kind), "rot": p.rot, "lift": _prop_lift(p.kind)})
	for s in b.signs:
		var lit_name2: String = s.kind + "_lit"
		items.append({"tex": tex(s.kind), "lit": tex(lit_name2) if AssetCatalog.SPECS.has(lit_name2) else null,
			"pos": s.pos, "size": AssetCatalog.display_size(s.kind), "rot": s.rot, "lift": s.lift})
	return items


static func _prop_lift(kind: String) -> float:
	match kind:
		"roof/water_tank": return 30.0
		"roof/stair_hut": return 18.0
		"roof/chimney": return 14.0
		"roof/laundry": return 8.0
	return 3.0


## Position in `buildings` of the view for layout building i.
func building_index(layout_index: int) -> int:
	return _building_order.find(layout_index)


# ------------------------------------------------------------------ street furniture

func _sprite(logical: String, pos: Vector2, rot: float, z: int, parent: Node, light: bool = false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex(logical)
	s.scale = AssetCatalog.scale_for(s.texture, AssetCatalog.display_size(logical))
	s.position = pos
	s.rotation = rot
	s.z_index = z
	s.light_mask = Layers.LIGHT_STREET
	if light:
		s.material = DrawLayer.glow_material()
	parent.add_child(s)
	return s


func _raise(s: Sprite2D, pos: Vector2, height: float) -> void:
	_raised.append({"node": s, "pos": pos, "height": height, "scale": s.scale})


func _solid_circle(pos: Vector2, radius: float) -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	shape.position = pos
	solids.add_child(shape)


func _solid_box(pos: Vector2, size: Vector2, rot: float) -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	shape.shape = box
	shape.position = pos
	shape.rotation = rot
	solids.add_child(shape)


func _build_props_range(from: int, to: int) -> void:
	for idx in range(from, to):
		var p: Dictionary = layout.props[idx]
		var raised: bool = p.height > 0.0
		var s := _sprite(p.kind, p.pos, p.rot, Layers.Z_RAISED if raised else Layers.Z_PROP, _props)
		if raised:
			_raise(s, p.pos, p.height)
			var lit_name: String = p.kind + "_lit"
			if AssetCatalog.SPECS.has(lit_name):
				var g := _sprite(lit_name, p.pos, p.rot, Layers.Z_RAISED_GLOW, _props, true)
				_raise(g, p.pos, p.height)
		if p.has("box"):
			_solid_box(p.pos, p.box, p.rot)
		elif p.has("radius"):
			_solid_circle(p.pos, p.radius)
		if p.has("light"):
			var halo := _sprite("fx/glow", p.pos, 0.0, Layers.Z_RAISED_GLOW, _props, true)
			halo.scale = AssetCatalog.scale_for(halo.texture, Vector2(46, 46))
			halo.modulate = p.light
			_point_light(p.pos, p.light, 0.9, 110.0)


func _build_quays_fences_and_spill() -> void:
	for q in layout.quays:
		var a: Vector2 = q[0]
		var b: Vector2 = q[1]
		_solid_box((a + b) * 0.5, Vector2(a.distance_to(b), 6.0), (b - a).angle())
	# M008: board fences round the yards (solid). M010: standing up where you can see them -
	# boards, chain-link or iron railings - their faces drawn in perspective like the walls,
	# along the same line as the collision
	for f in layout.fences:
		var fa: Vector2 = f[0]
		var fb: Vector2 = f[1]
		var kind: String = f[2] if (f as Array).size() > 2 else "boards"
		if kind == "boards":
			_strip(PackedVector2Array([fa, fb]), "city/fence", Layers.Z_PROP, false)
		_solid_box((fa + fb) * 0.5, Vector2(fa.distance_to(fb), 8.0), (fb - fa).angle())
		_fence_faces.append({"a": fa, "b": fb, "kind": kind, "tex": tex(FENCE_ART.get(kind, "fences/boards")),
			"rect": Rect2(fa, Vector2.ZERO).expand(fb).grow(FENCE_HEIGHT)})
	if not _fence_faces.is_empty():
		_fence_layer = DrawLayer.new(_draw_fence_faces, Layers.Z_WALL)
		_fence_layer.name = "FenceFaces"
		_props.add_child(_fence_layer)
		var tops := DrawLayer.new(_draw_fence_tops, Layers.Z_PROP + 1)
		tops.name = "FenceTops"
		_props.add_child(tops)
	# warm light from shop windows on the pavement
	for b in layout.buildings:
		if not b.facade in SHOPFRONTS or b.front == Vector2.ZERO:
			continue
		var r: Rect2 = b.rect
		var front: Vector2 = b.front
		var along := front.orthogonal()
		var length := absf(along.dot(r.size))
		var mid := r.get_center() + front * absf(front.dot(r.size)) * 0.5
		var n := maxi(1, int(length / 110.0))
		for k in n:
			var t := ((k + 0.5) / n - 0.5) * length
			var pool := _sprite("fx/glow", mid + along * t + front * 15.0, along.angle(), Layers.Z_LIGHT_POOL, _ground, true)
			pool.scale = AssetCatalog.scale_for(pool.texture, Vector2(length / n * 1.15, 50))
			pool.modulate = Color(1.0, 0.75, 0.45, 0.55 if b.facade == "club" else 0.36)


func _point_light(pos: Vector2, color: Color, energy: float, radius: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = LightTextures.radial()
	l.texture_scale = radius * 2.0 / 256.0
	l.color = color
	l.energy = energy
	l.position = pos
	l.range_item_cull_mask = Layers.LIGHT_STREET
	_lights.add_child(l)
	return l


func _build_lamps_range(from: int, to: int) -> void:
	for idx in range(from, to):
		var p: Vector2 = layout.lamps[idx]
		_sprite("props/lamp_base", p, 0.0, Layers.Z_PROP, _props)
		_solid_circle(p, 5.0)
		var head := _sprite("props/lamp_head", p, 0.0, Layers.Z_RAISED, _props)
		_raise(head, p, LAMP_HEIGHT)
		var halo := _sprite("fx/glow", p, 0.0, Layers.Z_RAISED_GLOW, _props, true)
		halo.scale = AssetCatalog.scale_for(halo.texture, Vector2(84, 84))
		halo.modulate = Color(1.0, 0.85, 0.6, 0.6)
		_raise(halo, p, LAMP_HEIGHT + 1.0)
		var core := _sprite("fx/glow", p, 0.0, Layers.Z_RAISED_GLOW, _props, true)
		core.scale = AssetCatalog.scale_for(core.texture, Vector2(26, 26))
		core.modulate = Color(1.0, 0.95, 0.8, 1.0)
		_raise(core, p, LAMP_HEIGHT + 2.0)
		var refl := _sprite("fx/reflection", p, 0.0, Layers.Z_REFLECTION, _ground, true)
		refl.centered = false
		refl.offset = Vector2(-refl.texture.get_width() * 0.5, 0.0)
		refl.modulate = Color(1.0, 0.8, 0.55, 0.5)
		_reflections.append({"node": refl, "pos": p, "height": LAMP_HEIGHT})
		lamp_lights.append(_point_light(p, LAMP_COLOR, layout.lamp_energy, LAMP_RADIUS))


func _build_alley_lamps() -> void:
	for p in layout.alley_lamps:
		var bulb := _sprite("fx/glow", p, 0.0, Layers.Z_RAISED_GLOW, _props, true)
		bulb.scale = AssetCatalog.scale_for(bulb.texture, Vector2(34, 34))
		bulb.modulate = Color(1.0, 0.92, 0.75, 0.9)
		_raise(bulb, p, 46.0)
		_point_light(p, Color(1.0, 0.88, 0.68), 1.0, 150.0)


# ------------------------------------------------------------------ view

## Called every frame by the game with the camera's centre and eye height.
func update_view(p_eye: Vector2, p_eye_height: float, view: Rect2) -> void:
	eye = p_eye
	eye_height = p_eye_height
	_view = view
	if _fence_layer != null and _fence_faces.any(func(f: Dictionary) -> bool: return view.grow(260.0).intersects(f.rect)):
		_fence_layer.queue_redraw()
	for b in buildings:
		b.set_view(eye, eye_height, view)
	var near := view.grow(260.0)
	for r in _raised:
		var node: Sprite2D = r.node
		if not near.has_point(r.pos):
			node.visible = false
			continue
		node.visible = true
		node.position = Perspective.project(r.pos, r.height, eye, eye_height)
		node.scale = r.scale * Perspective.scale_at(r.height, eye_height)
	for r in _reflections:
		var node2: Sprite2D = r.node
		if not near.has_point(r.pos):
			node2.visible = false
			continue
		# the mirror image of the lamp lies towards the screen centre; the wet
		# street smears it into a streak from the lamp's foot towards it
		var mirror := Perspective.project(r.pos, -r.height * 2.2, eye, eye_height)
		var span := (r.pos as Vector2).distance_to(mirror)
		node2.visible = span > 4.0
		node2.position = r.pos
		node2.rotation = (mirror - r.pos).angle() - PI / 2
		node2.scale = Vector2(0.42, maxf(span + 26.0, 30.0) / node2.texture.get_height())
	if atmosphere != null:
		atmosphere.update_view(eye, eye_height, view)


## Solid footprints only (no physics query): true when a circle of `radius`
## at p is clear of buildings and outside the river, inside the play area.
func is_open_ground(p: Vector2, radius: float) -> bool:
	return layout.is_open_ground(p, radius)
