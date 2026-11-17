class_name BuildingView
extends Node2D
## Draws one building for the true top-down camera (see Perspective): the
## walls facing the camera, one band per storey (ground storey and upper
## storeys from the facade image), their window light, then the roof with its
## parapet, rooftop furniture and signs. Four draw layers keep the order right
## across buildings: every wall < window light < every roof (lower roofs first).
## Presentation only; the building's solid footprint lives in City.

const PARAPET := 9.0
## Shadow cast by the parapet onto the roof (px).
const ROOF_SHADOW := 16.0
const WHITE := Color.WHITE

var rect: Rect2
var storeys := 1
var height := 0.0
## {a, b, n (outward normal), tex, lit (or null), u0}
var faces: Array = []
var roof_tex: Texture2D
var parapet_tex: Texture2D
## {tex, lit, pos, size, rot, lift}
var roof_items: Array = []
## Slight per-building colour of the roofing.
var roof_tint := Color.WHITE
var eye := Vector2.ZERO
var eye_height := 1500.0
var _layers: Array[DrawLayer] = []


func setup(p_rect: Rect2, p_storeys: int, p_faces: Array, p_roof: Texture2D, p_parapet: Texture2D, items: Array) -> void:
	rect = p_rect
	storeys = p_storeys
	height = storeys * DistrictLayout.STOREY
	faces = p_faces
	roof_tex = p_roof
	parapet_tex = p_parapet
	roof_items = items
	var has_lit := faces.any(func(f: Dictionary) -> bool: return f.lit != null) \
		or roof_items.any(func(i: Dictionary) -> bool: return i.lit != null)
	_layers.append(DrawLayer.new(_draw_walls, Layers.Z_WALL))
	if has_lit:
		_layers.append(DrawLayer.new(_draw_wall_light, Layers.Z_WALL_GLOW, true))
	var roof := DrawLayer.new(_draw_roof, Layers.Z_ROOF + storeys, false, Layers.LIGHT_ROOF)
	roof.self_modulate = Color(0.95, 0.95, 1.0)
	_layers.append(roof)
	if has_lit:
		_layers.append(DrawLayer.new(_draw_roof_light, Layers.Z_ROOF + storeys, true))
	for l in _layers:
		add_child(l)


## Footprint grown by how far the roof can lean out (for culling).
func reach() -> Rect2:
	return rect.grow(height * 0.6)


func set_view(p_eye: Vector2, p_eye_height: float, view: Rect2) -> void:
	var visible_now := view.intersects(reach())
	for l in _layers:
		l.visible = visible_now
	if not visible_now:
		return
	eye = p_eye
	eye_height = p_eye_height
	for l in _layers:
		l.queue_redraw()


func project(p: Vector2, h: float) -> Vector2:
	return Perspective.project(p, h, eye, eye_height)


func _corners() -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])


## Faces turned towards the camera.
func visible_faces() -> Array:
	return faces.filter(func(f: Dictionary) -> bool: return f.n.dot(eye - (f.a + f.b) * 0.5) > 0.0)


func _draw_walls(ci: CanvasItem) -> void:
	_walls(ci, false)


func _draw_wall_light(ci: CanvasItem) -> void:
	_walls(ci, true)


func _walls(ci: CanvasItem, light: bool) -> void:
	var st := DistrictLayout.STOREY
	for f in visible_faces():
		var tex: Texture2D = f.lit if light else f.tex
		if tex == null:
			continue
		var u0: float = f.u0
		var u1: float = u0 + (f.a as Vector2).distance_to(f.b) / AssetCatalog.FACADE_REPEAT
		# a little directional shading (walls facing up / sideways are in shade)
		var tone := 1.0
		if not light:
			tone = 0.78 if f.n.y < -0.5 else (0.88 if absf(f.n.x) > 0.5 else 1.0)
		for k in storeys:
			var h0 := k * st
			var h1 := h0 + st
			var v_bottom := 1.0 if k == 0 else 0.5
			var pts := PackedVector2Array([project(f.a, h0), project(f.b, h0), project(f.b, h1), project(f.a, h1)])
			var uvs := PackedVector2Array([Vector2(u0, v_bottom), Vector2(u1, v_bottom), Vector2(u1, v_bottom - 0.5), Vector2(u0, v_bottom - 0.5)])
			var cols: PackedColorArray
			if light:
				cols = PackedColorArray([WHITE])
			else:
				# darker towards the street (grime, shadow), lighter towards the cornice
				var b0 := tone * lerpf(0.62, 1.0, minf(1.0, h0 / (st * 1.5)))
				var b1 := tone * lerpf(0.62, 1.0, minf(1.0, h1 / (st * 1.5)))
				cols = PackedColorArray([Color(b0, b0, b0), Color(b0, b0, b0), Color(b1, b1, b1), Color(b1, b1, b1)])
			ci.draw_polygon(pts, cols, uvs, tex)


func _draw_roof(ci: CanvasItem) -> void:
	var c := _corners()
	var top := PackedVector2Array()
	var uvs := PackedVector2Array()
	var tile := 256.0
	for p in c:
		top.append(project(p, height))
		uvs.append(p / tile)
	ci.draw_polygon(top, PackedColorArray([roof_tint]), uvs, roof_tex)
	if parapet_tex != null:
		# the parapet's shadow on the roof, then the parapet itself
		var dark := Color(0.0, 0.0, 0.03, 0.5)
		var clear := Color(0.0, 0.0, 0.03, 0.0)
		var sh := Rect2(rect.position + Vector2(ROOF_SHADOW, ROOF_SHADOW), rect.size - Vector2(ROOF_SHADOW, ROOF_SHADOW) * 2)
		var sc := PackedVector2Array([sh.position, Vector2(sh.end.x, sh.position.y), sh.end, Vector2(sh.position.x, sh.end.y)])
		for i in 4:
			var j := (i + 1) % 4
			ci.draw_polygon(PackedVector2Array([project(c[i], height), project(c[j], height), project(sc[j], height), project(sc[i], height)]),
				PackedColorArray([dark, dark, clear, clear]))
		var inner := Rect2(rect.position + Vector2(PARAPET, PARAPET), rect.size - Vector2(PARAPET, PARAPET) * 2)
		var ic := PackedVector2Array([inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)])
		for i in 4:
			var j := (i + 1) % 4
			var length := (c[i] as Vector2).distance_to(c[j])
			var pts := PackedVector2Array([project(c[i], height), project(c[j], height), project(ic[j], height), project(ic[i], height)])
			var u := length / 64.0
			ci.draw_polygon(pts, PackedColorArray([WHITE]), PackedVector2Array([Vector2(0, 0), Vector2(u, 0), Vector2(u, 1), Vector2(0, 1)]), parapet_tex)
	for item in roof_items:
		_draw_item(ci, item, item.tex)


func _draw_roof_light(ci: CanvasItem) -> void:
	for item in roof_items:
		if item.lit != null:
			_draw_item(ci, item, item.lit)


func _draw_item(ci: CanvasItem, item: Dictionary, tex: Texture2D) -> void:
	var lift: float = height + item.lift
	var s := Perspective.scale_at(lift, eye_height)
	ci.draw_set_transform(project(item.pos, lift), item.rot, Vector2(s, s))
	var size: Vector2 = item.size
	ci.draw_texture_rect(tex, Rect2(-size * 0.5, size), false)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
