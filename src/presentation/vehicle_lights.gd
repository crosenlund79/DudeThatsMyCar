class_name VehicleLights
extends Node2D
## A car's lamps at night: a headlight beam that lights the street ahead,
## glowing headlamps, and tail lamps that brighten when braking. On while
## someone drives the car, off when it is parked. Presentation only.

const BEAM_RANGE := 300.0

var car: Car
var beam: PointLight2D
var _lamps: Array[Sprite2D] = []
var _tails: Array[Sprite2D] = []
static var _cone: Texture2D


func setup(p_car: Car, glow: Texture2D) -> void:
	car = p_car
	name = "Lights"
	beam = PointLight2D.new()
	beam.texture = cone_texture()
	beam.texture_scale = BEAM_RANGE * 2.0 / 256.0
	beam.color = Color(1.0, 0.94, 0.8)
	beam.energy = 1.25
	beam.position = Vector2(car.vehicle.size.x * 0.42, 0.0)
	beam.range_item_cull_mask = Layers.LIGHT_STREET
	add_child(beam)
	for p in car.vehicle.headlights:
		_lamps.append(_glow(glow, p, Color(1.0, 0.95, 0.8, 0.95), 20.0))
	for p in car.vehicle.taillights:
		_tails.append(_glow(glow, p, Color(1.0, 0.15, 0.1, 0.7), 14.0))
	car.add_child(self)
	set_on(false)


func _glow(texture: Texture2D, at: Vector2, color: Color, size: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture
	s.scale = Vector2(size, size) / Vector2(texture.get_size())
	s.position = at
	s.modulate = color
	s.material = DrawLayer.glow_material()
	s.z_index = 1
	add_child(s)
	return s


func set_on(on: bool) -> void:
	visible = on
	beam.enabled = on


func _process(_delta: float) -> void:
	if not visible:
		return
	var braking := car.brake and car.model.forward_speed() > 5.0 or car.handbrake
	for t in _tails:
		t.modulate.a = 1.0 if braking else 0.55
		t.scale = Vector2.ONE * ((22.0 if braking else 14.0) / t.texture.get_width())


## Soft cone pointing along +X from the texture's centre (lighting, not art).
static func cone_texture() -> Texture2D:
	if _cone == null:
		var n := 256
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		var c := Vector2(n * 0.5, n * 0.5)
		for y in n:
			for x in n:
				var v := Vector2(x + 0.5, y + 0.5) - c
				var dist := v.length() / (n * 0.5)
				var a := 0.0
				if v.x > 0.0 and dist < 1.0:
					var ang := absf(v.angle())
					var spread := clampf(1.0 - ang / 0.5, 0.0, 1.0)
					a = spread * spread * (1.0 - dist) * clampf(dist * 6.0, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		_cone = ImageTexture.create_from_image(img)
	return _cone
