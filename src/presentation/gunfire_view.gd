class_name GunfireView
extends Node2D
## Gunfire on screen and in the ears (presentation only): the muzzle flash
## with a brief burst of light on the street, bullet tracers, brick dust and
## sparks where rounds strike, and the shot, reload and impact sounds.

const FLASH_TIME := 0.07
const PUFF_TIME := 0.55

var resolver: AssetResolver
var bullets: BulletWorld
var _flash: Sprite2D
var _flash_light: PointLight2D
var _flash_left := 0.0
## The flash stays on screen for at least this many drawn frames (slow machines).
var _flash_frames := 0
var _tracer: Texture2D
var _tracer_size := Vector2.ZERO
## {node, age, kind}
var _puffs: Array = []
var _sounds: Array[AudioStreamPlayer2D] = []
var _next_sound := 0


func setup(p_resolver: AssetResolver, p_bullets: BulletWorld) -> void:
	resolver = p_resolver
	bullets = p_bullets
	name = "GunfireView"
	z_index = Layers.Z_STEAM + 1
	z_as_relative = false
	material = DrawLayer.glow_material()  # tracers are light
	_tracer = resolver.get_texture("fx/tracer")
	_tracer_size = AssetCatalog.display_size("fx/tracer")
	_flash = Sprite2D.new()
	_flash.texture = resolver.get_texture("fx/muzzle_flash")
	_flash.centered = false
	_flash.scale = AssetCatalog.scale_for(_flash.texture, AssetCatalog.display_size("fx/muzzle_flash"))
	_flash.offset = Vector2(0, -_flash.texture.get_height() * 0.5)
	_flash.material = DrawLayer.glow_material()
	_flash.visible = false
	add_child(_flash)
	_flash_light = PointLight2D.new()
	_flash_light.texture = LightTextures.radial()
	_flash_light.texture_scale = 380.0 / 256.0
	_flash_light.color = Color(1.0, 0.82, 0.5)
	_flash_light.energy = 0.0
	_flash_light.enabled = false
	_flash_light.range_item_cull_mask = Layers.LIGHT_STREET
	add_child(_flash_light)
	for i in 6:
		var p := AudioStreamPlayer2D.new()
		p.bus = "Effects" if AudioServer.get_bus_index("Effects") >= 0 else "Master"
		p.max_distance = 2200.0
		add_child(p)
		_sounds.append(p)


func play(logical: String, at: Vector2, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream := resolver.get_audio(logical)
	if stream == null:
		return
	var p := _sounds[_next_sound]
	_next_sound = (_next_sound + 1) % _sounds.size()
	p.stream = stream
	p.global_position = at
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


func on_fired(muzzle: Vector2, direction: Vector2, sound: String = "weapons/pistol_shot") -> void:
	_flash.global_position = muzzle
	_flash.rotation = direction.angle()
	_flash.visible = true
	_flash.modulate.a = 1.0
	_flash_light.global_position = muzzle + direction * 10.0
	_flash_light.enabled = true
	_flash_light.energy = 2.4
	_flash_left = FLASH_TIME
	_flash_frames = 2
	play(sound, muzzle, 0.0, randf_range(0.96, 1.04))


func on_gun_event(event: String, at: Vector2) -> void:
	if event == "reload":
		play("weapons/pistol_reload", at, -4.0)


func on_impact(pos: Vector2, normal: Vector2, collider: Object, _direction: Vector2) -> void:
	var hard := collider is Car
	_puff("fx/spark", pos + normal * 2.0, true, randf_range(0.0, TAU))
	if not hard:
		_puff("fx/impact_dust", pos + normal * 6.0, false, normal.angle())
		play("weapons/bullet_impact", pos, -3.0, randf_range(0.9, 1.15))
	else:
		play("vehicles/impact_car", pos, -9.0, randf_range(1.5, 1.8))


func _puff(logical: String, at: Vector2, light: bool, rot: float) -> void:
	var s := Sprite2D.new()
	s.texture = resolver.get_texture(logical)
	s.scale = AssetCatalog.scale_for(s.texture, AssetCatalog.display_size(logical))
	s.global_position = at
	s.rotation = rot
	s.z_index = Layers.Z_STEAM + 2
	s.z_as_relative = false
	s.material = DrawLayer.glow_material() if light else null
	s.light_mask = Layers.LIGHT_STREET
	add_child(s)
	_puffs.append({"node": s, "age": 0.0, "base": s.scale, "light": light})


func _process(delta: float) -> void:
	if _flash_left > 0.0 or _flash_frames > 0:
		_flash_left -= delta
		_flash_frames -= 1
		var k := maxf(clampf(_flash_left / FLASH_TIME, 0.0, 1.0), 0.6 if _flash_frames >= 0 else 0.0)
		_flash.modulate.a = k
		_flash_light.energy = 2.4 * k
		if _flash_left <= 0.0 and _flash_frames < 0:
			_flash.visible = false
			_flash_light.enabled = false
	var still: Array = []
	for p in _puffs:
		p.age += delta
		var life := 0.18 if p.light else PUFF_TIME
		var node: Sprite2D = p.node
		if p.age >= life:
			node.queue_free()
			continue
		var t: float = p.age / life
		node.modulate.a = 1.0 - t
		node.scale = p.base * (1.0 + t * (0.4 if p.light else 1.2))
		still.append(p)
	_puffs = still
	queue_redraw()


func _draw() -> void:
	if bullets == null:
		return
	for b in bullets.bullets:
		draw_set_transform(b.pos, (b.dir as Vector2).angle(), Vector2.ONE)
		draw_texture_rect(_tracer, Rect2(Vector2(-_tracer_size.x, -_tracer_size.y * 0.5), _tracer_size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
