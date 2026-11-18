class_name CafeScene
extends Node2D
## M010: Rosie's Café on Marlowe Avenue, Halloran Square, as it is seen:
## Vince Duggan's green Packard at the kerb in the evening; when the parcel
## goes, a flash and a fireball, a heavy boom, debris and glass across the
## street; then the burnt-out wreck burning at the kerb, a column of smoke,
## the scorch on the road, and the café's people standing on the pavement
## staring at it (Duggan among them). The aftermath stays for the night (the
## wreck two nights, the scorch for good). Presentation only: CafeJob says
## what is so; the game asks for the blast and for the fire to be put out.
## Stylised, no gore: nobody is in the car.

signal blast_shown(at: Vector2)

const CAR_SIZE := Vector2(80, 36)
const FIRE_MINUTES := 120.0
## Where the café's people stand once they are out (offsets from the car, world px).
const GATHER := [Vector2(-70, -64), Vector2(-20, -74), Vector2(40, -70), Vector2(95, -60)]
const LOOKS := ["characters/patron_man", "characters/patron_woman", "characters/lady", "characters/clerk"]

var layout: DistrictLayout
var job: CafeJob
var car_pos := Vector2.ZERO
var car_rot := 0.0
var door := Vector2.ZERO
var bench := Vector2.ZERO
var burning := false
var smouldering := false
var people: Array[Walker] = []
var _resolver: AssetResolver
var _packard: Sprite2D
var _wreck: Sprite2D
var _scorch: Sprite2D
var _body: StaticBody2D
var _flames: Array[Sprite2D] = []
var _fire_light: PointLight2D
var _flash_light: PointLight2D
var _fireball: Sprite2D
var _smoke: CPUParticles2D
var _debris: Array = []  # {node: Sprite2D, vel: Vector2, spin: float}
var _fire_sound: AudioStreamPlayer2D
var _boom: AudioStreamPlayer2D
var _t := 0.0
var _ball := -1.0
var _people_out := -1.0


func setup(p_layout: DistrictLayout, resolver: AssetResolver, p_job: CafeJob) -> void:
	name = "CafeScene"
	layout = p_layout
	job = p_job
	_resolver = resolver
	for c in layout.cafe:
		match String(c.id):
			"car":
				car_pos = c.pos
				car_rot = float(c.get("rot", 0.0))
			"door":
				door = c.pos
			"bench":
				bench = c.pos
	_scorch = _sprite("decals/scorch", car_pos, 0.4, Layers.Z_DECAL + 3)
	_scorch.scale = AssetCatalog.scale_for(_scorch.texture, Vector2(150, 120))
	_packard = _sprite("props/packard", car_pos, car_rot, Layers.Z_PROP + 2)
	_packard.scale = AssetCatalog.scale_for(_packard.texture, CAR_SIZE)
	_wreck = _sprite("props/car_wreck", car_pos, car_rot + 0.05, Layers.Z_PROP + 2)
	_wreck.scale = AssetCatalog.scale_for(_wreck.texture, CAR_SIZE)
	_body = StaticBody2D.new()
	_body.collision_layer = Layers.WORLD
	_body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = CAR_SIZE - Vector2(4, 4)
	shape.shape = box
	_body.add_child(shape)
	_body.position = car_pos
	_body.rotation = car_rot
	add_child(_body)
	for k in 5:
		var f := _sprite("fx/flame", car_pos + Vector2(-26 + k * 13, -4 + (k % 2) * 6).rotated(car_rot), 0.0, Layers.Z_STEAM + 1)
		f.material = DrawLayer.glow_material()
		f.offset = Vector2(0, -f.texture.get_height() * 0.5)
		f.visible = false
		_flames.append(f)
	_fire_light = _light(car_pos, Color(1.0, 0.55, 0.22), 0.0, 520.0)
	_flash_light = _light(car_pos, Color(1.0, 0.85, 0.6), 0.0, 1400.0)
	_fireball = _sprite("fx/fireball", car_pos, 0.0, Layers.Z_SMOKE)
	_fireball.material = DrawLayer.glow_material()
	_fireball.visible = false
	_smoke = CPUParticles2D.new()
	_smoke.texture = resolver.get_texture("fx/smoke_plume")
	_smoke.amount = 26
	_smoke.lifetime = 7.0
	_smoke.preprocess = 0.0
	_smoke.emitting = false
	_smoke.direction = Vector2(0.4, -1.0)
	_smoke.spread = 18.0
	_smoke.gravity = Vector2(14, -6)
	_smoke.initial_velocity_min = 18.0
	_smoke.initial_velocity_max = 34.0
	_smoke.scale_amount_min = 0.5
	_smoke.scale_amount_max = 0.8
	var grow := Curve.new()
	grow.add_point(Vector2(0, 0.5))
	grow.add_point(Vector2(1, 2.4))
	_smoke.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.85))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	_smoke.color_ramp = fade
	_smoke.position = car_pos
	_smoke.z_index = Layers.Z_SMOKE - 1
	_smoke.z_as_relative = false
	add_child(_smoke)
	_fire_sound = AudioStreamPlayer2D.new()
	_fire_sound.stream = resolver.get_audio("fx/fire")
	_fire_sound.max_distance = 700.0
	_fire_sound.bus = "Effects" if AudioServer.get_bus_index("Effects") >= 0 else "Master"
	_fire_sound.position = car_pos
	add_child(_fire_sound)
	_boom = AudioStreamPlayer2D.new()
	_boom.stream = resolver.get_audio("fx/blast")
	_boom.max_distance = 3200.0
	_boom.attenuation = 0.6
	_boom.bus = _fire_sound.bus
	_boom.position = car_pos
	add_child(_boom)


func _sprite(logical: String, pos: Vector2, rot: float, z: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _resolver.get_texture(logical)
	s.scale = AssetCatalog.scale_for(s.texture, AssetCatalog.display_size(logical))
	s.position = pos
	s.rotation = rot
	s.z_index = z
	s.z_as_relative = false
	s.light_mask = Layers.LIGHT_STREET
	add_child(s)
	return s


func _light(pos: Vector2, colour: Color, energy: float, size: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = LightTextures.radial()
	l.texture_scale = size / 256.0
	l.color = colour
	l.energy = energy
	l.position = pos
	l.range_item_cull_mask = Layers.LIGHT_STREET
	l.enabled = energy > 0.0
	add_child(l)
	return l


func near_car(p: Vector2, reach: float = 46.0) -> bool:
	return _packard.visible and p.distance_to(car_pos) <= reach


## What should show tonight at this minute (cheap: every frame).
func refresh(night: int, minute: float) -> void:
	var car := job.car_there(night, minute)
	_packard.visible = car and _ball < 0.0
	_wreck.visible = job.wreck_there(night)
	_scorch.visible = job.scorched()
	_body.process_mode = Node.PROCESS_MODE_INHERIT
	(_body.get_child(0) as CollisionShape2D).disabled = not (_packard.visible or _wreck.visible)
	if job.blast_night == night and job.scorched() and _ball < 0.0 and not burning and not smouldering \
			and minute < job.blast_minute + FIRE_MINUTES and minute >= job.blast_minute:
		_set_fire(true)  # back in the district while it still burns
	if burning and job.blast_night == night and minute >= job.blast_minute + FIRE_MINUTES:
		extinguish()
	if job.blast_night != night and (burning or smouldering):
		_set_fire(false)
		smouldering = false
		_smoke.emitting = false
		for w in people:
			w.queue_free()
		people.clear()


## The moment: flash, fireball, boom, debris and the fire.
func play_blast() -> void:
	_ball = 0.0
	_packard.visible = false
	_wreck.visible = true
	_scorch.visible = true
	_flash_light.enabled = true
	_flash_light.energy = 6.0
	_fireball.visible = true
	_fireball.scale = Vector2(0.4, 0.4)
	_boom.play()
	_set_fire(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1932010
	var sheet := _resolver.get_texture("decals/grime")
	var fw := sheet.get_width() / 12.0
	for k in 16:
		var s := Sprite2D.new()
		s.texture = sheet
		s.region_enabled = true
		s.region_rect = Rect2(fw * [9, 10, 2, 5, 6, 9, 10, 4][k % 8], 0, fw, sheet.get_height())
		s.scale = Vector2(0.32, 0.32)
		s.position = car_pos
		s.z_index = Layers.Z_DECAL + 4
		s.z_as_relative = false
		s.light_mask = Layers.LIGHT_STREET
		add_child(s)
		var dir := Vector2.from_angle(rng.randf() * TAU)
		_debris.append({"node": s, "vel": dir * rng.randf_range(160, 420), "spin": rng.randf_range(-8, 8)})
	_people_out = 2.6
	blast_shown.emit(car_pos)


func _set_fire(on: bool) -> void:
	burning = on
	for f in _flames:
		f.visible = on
	_fire_light.enabled = on
	_fire_light.energy = 1.6 if on else 0.0
	_smoke.emitting = on or smouldering
	if on and not _fire_sound.playing:
		_fire_sound.play()
	elif not on:
		_fire_sound.stop()


## The firemen put it out: smoke without flames for the rest of the night.
func extinguish() -> void:
	if not burning:
		return
	_set_fire(false)
	smouldering = true
	_smoke.emitting = true
	_smoke.amount = 12


## The café's people out on the pavement, staring (tonight, after the blast).
func bring_people_out(at_once: bool = false) -> void:
	if not people.is_empty():
		return
	for i in GATHER.size():
		var w := Walker.create(_resolver, LOOKS[i], {"glow": false})
		w.name = "Onlooker%d" % i
		add_child(w)
		var target: Vector2 = car_pos + (GATHER[i] as Vector2).rotated(car_rot)
		w.place(target if at_once else door + Vector2(i * 8 - 12, 6), (car_pos - target).angle())
		w.aim_point = car_pos
		w.set_meta("target", target)
		w.rng.seed = 7700 + i
		people.append(w)


func _process(delta: float) -> void:
	_t += delta
	if burning:
		for i in _flames.size():
			var f := _flames[i]
			var flick := 0.75 + 0.25 * sin(_t * (9.0 + i * 1.7) + i) + 0.12 * sin(_t * 23.0 + i * 3.1)
			f.scale = AssetCatalog.scale_for(f.texture, Vector2(20, 30)) * Vector2(1.0, flick)
			f.modulate.a = 0.75 + 0.25 * flick
		_fire_light.energy = 1.4 + 0.35 * sin(_t * 11.0) + 0.2 * sin(_t * 27.0)
	if _ball >= 0.0:
		_ball += delta
		var k := clampf(_ball / 0.55, 0.0, 1.0)
		_fireball.scale = AssetCatalog.scale_for(_fireball.texture, Vector2(260, 260)) * (0.35 + 0.9 * sqrt(k))
		_fireball.modulate.a = clampf(1.0 - (_ball - 0.35) / 0.9, 0.0, 1.0)
		_flash_light.energy = 6.0 * clampf(1.0 - _ball / 1.6, 0.0, 1.0)
		if _ball > 1.6:
			_fireball.visible = false
			_flash_light.enabled = false
			_ball = -1.0
	for d in _debris:
		var v: Vector2 = d.vel
		if v.length() > 1.0:
			(d.node as Sprite2D).position += v * delta
			(d.node as Sprite2D).rotation += float(d.spin) * delta
			d.vel = v.move_toward(Vector2.ZERO, 520.0 * delta)
			d.spin = move_toward(float(d.spin), 0.0, 10.0 * delta)
	if _people_out >= 0.0:
		_people_out -= delta
		if _people_out < 0.0:
			bring_people_out()
	for w in people:
		if not is_instance_valid(w) or w.down:
			continue
		var target: Vector2 = w.get_meta("target")
		var to := target - w.global_position
		w.move = to.normalized() * 0.5 if to.length() > 6.0 else Vector2.ZERO
		if to.length() <= 6.0:
			w.aim_point = car_pos
