class_name NightAtmosphere
extends Node2D
## The night: a cool tint over everything that is not a light, steam rising
## from manholes, smoke from a few chimneys, a faint haze drifting through the
## lamplight and a soft vignette. Presentation only.

const NIGHT_TINT := Color(0.27, 0.3, 0.45)
const MIST_PATCHES := 4
const SMOKING_CHIMNEYS := 14

var city: City
var tint: CanvasModulate
var vignette: TextureRect
var _mist: Array[Sprite2D] = []
var _mist_offsets: Array[Vector2] = []
## Chimney smoke emitters: {node, pos, height}
var _smoke: Array = []
var _time := 0.0
var _eye := Vector2.ZERO


func setup(p_city: City) -> void:
	city = p_city
	tint = CanvasModulate.new()
	tint.color = NIGHT_TINT
	add_child(tint)
	# cool moonlight on the roofs (the street lamps only reach the street)
	var moon := DirectionalLight2D.new()
	moon.color = Color(0.62, 0.72, 1.0)
	moon.energy = 0.3
	moon.range_item_cull_mask = Layers.LIGHT_ROOF
	add_child(moon)
	var steam_tex := city.tex("fx/steam")
	for p in city.layout.steam_vents:
		add_child(_steam(p, steam_tex))
	var count := 0
	for b in city.layout.buildings:
		for item in b.props:
			if item.kind == "roof/chimney" and count < SMOKING_CHIMNEYS and int(item.pos.x * 7.0 + item.pos.y) % 4 == 0:
				var e := _smoke_emitter(steam_tex)
				add_child(e)
				_smoke.append({"node": e, "pos": item.pos, "height": city.layout.building_height(b) + 22.0})
				count += 1
	var haze_tex := city.tex("fx/glow")
	for k in MIST_PATCHES:
		var m := Sprite2D.new()
		m.texture = haze_tex
		m.z_index = Layers.Z_MIST
		m.z_as_relative = false
		m.light_mask = 0  # not lit per lamp: a big soft sprite costs too much fill on slow graphics
		m.scale = Vector2(7.0, 4.2) * (0.85 + 0.12 * k)
		m.modulate = Color(0.62, 0.68, 0.8, 0.16)
		add_child(m)
		_mist.append(m)
		_mist_offsets.append(Vector2(fmod(k * 523.0, 1600.0) - 800.0, fmod(k * 311.0, 900.0) - 450.0))
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	vignette = TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.02, 0.02, 0.06, 0.0))
	g.set_color(1, Color(0.02, 0.02, 0.06, 0.62))
	g.add_point(0.55, Color(0.02, 0.02, 0.06, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.05, 0.5)
	vignette.texture = gt
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(vignette)


func _ramp(alpha: float) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.0))
	g.set_color(1, Color(1, 1, 1, 0.0))
	g.add_point(0.2, Color(1, 1, 1, alpha))
	return g


func _growth() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.35))
	c.add_point(Vector2(1.0, 1.0))
	return c


func _steam(pos: Vector2, texture: Texture2D) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = texture
	p.position = pos
	p.z_index = Layers.Z_STEAM
	p.z_as_relative = false
	p.light_mask = Layers.LIGHT_STREET
	p.amount = 18
	p.lifetime = 4.5
	p.preprocess = 4.5
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 7.0
	p.direction = Vector2(1.0, -0.35)
	p.spread = 28.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 22.0
	p.angular_velocity_min = -12.0
	p.angular_velocity_max = 12.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.55
	p.scale_amount_curve = _growth()
	p.color = Color(0.86, 0.89, 0.94)
	p.color_ramp = _ramp(0.075)
	return p


func _smoke_emitter(texture: Texture2D) -> CPUParticles2D:
	var p := _steam(Vector2.ZERO, texture)
	p.z_index = Layers.Z_SMOKE
	p.light_mask = Layers.LIGHT_ROOF
	p.amount = 7
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.direction = Vector2(1.0, -0.2)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 9.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.5
	p.color = Color(0.5, 0.52, 0.58)
	p.color_ramp = _ramp(0.5)
	return p


func update_view(eye: Vector2, eye_height: float, view: Rect2) -> void:
	_eye = eye
	for s in _smoke:
		var node: CPUParticles2D = s.node
		var visible_now := view.grow(300.0).has_point(s.pos)
		node.emitting = visible_now
		node.visible = visible_now
		if visible_now:
			node.position = Perspective.project(s.pos, s.height, eye, eye_height)


func _process(delta: float) -> void:
	_time += delta
	for k in _mist.size():
		# patches hang in the world, drift slowly east and wrap round the view
		var w := _mist_offsets[k] + Vector2(_time * (9.0 + k), sin(_time * 0.05 + k) * 30.0)
		var rel := w - _eye
		rel.x = fposmod(rel.x + 900.0, 1800.0) - 900.0
		rel.y = fposmod(rel.y + 520.0, 1040.0) - 520.0
		_mist[k].position = _eye + rel
