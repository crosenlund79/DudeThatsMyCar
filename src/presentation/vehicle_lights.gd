class_name VehicleLights
extends Node2D
## A car's lamps at night: headlight beams that light the street ahead,
## glowing headlamps, and tail lamps that brighten when braking. On while
## someone drives the car, off when it is parked. Presentation only.
## M006: the beams are two - one from each headlamp, distinct in front of the
## car, widening with distance and running together into one pool further
## out - but still one light per car (the two beams are one texture), so the
## cost is what it was.

const BEAM_RANGE := 300.0
## The twin-beam texture covers this much road ahead of the lamps and across (px).
const BEAM_AHEAD := 320.0
const BEAM_ACROSS := 320.0
## The headlamps' distance from the car's centre line (px; the cars' lamps sit at +-7 to +-7.6).
const LAMP_SPACING := 7.3
## Half the angle each beam spreads (radians).
const BEAM_HALF_ANGLE := 0.38

var car: Car
var beam: PointLight2D
var _lamps: Array[Sprite2D] = []
var _tails: Array[Sprite2D] = []
static var _cone: Texture2D


func setup(p_car: Car, glow: Texture2D) -> void:
	car = p_car
	name = "Lights"
	beam = PointLight2D.new()
	beam.name = "Beams"
	beam.texture = twin_beam_texture()
	beam.texture_scale = BEAM_AHEAD / float(beam.texture.get_width())
	beam.color = Color(1.0, 0.94, 0.8)
	beam.energy = 1.6
	# the texture is centred on the light: put its back edge at the lamps
	var lamps_x := car.vehicle.size.x * 0.4
	if not car.vehicle.headlights.is_empty():
		lamps_x = car.vehicle.headlights[0].x
	beam.position = Vector2(lamps_x + BEAM_AHEAD * 0.5, 0.0)
	beam.range_item_cull_mask = Layers.LIGHT_STREET
	add_child(beam)
	for p in car.vehicle.headlights:
		_lamps.append(_glow(glow, p, Color(1.0, 0.96, 0.84, 1.0), 13.0))  # small: two lamps, not one blur
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


## Two headlight beams along +X from the texture's left edge (lighting, not
## art): each starts at a lamp LAMP_SPACING px off the centre line, spreads
## by BEAM_HALF_ANGLE and fades with distance, so close in front of the car
## there are two pools of light and further on they merge.
static var _twin: Texture2D
const TWIN_SIZE := 384


static func twin_beam_texture() -> Texture2D:
	if _twin == null:
		_twin = ImageTexture.create_from_image(twin_beam_image(TWIN_SIZE))
	return _twin


static func twin_beam_image(n: int) -> Image:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for j in n:
		var y := (float(j) + 0.5) / n * BEAM_ACROSS - BEAM_ACROSS * 0.5
		for i in n:
			var x := (float(i) + 0.5) / n * BEAM_AHEAD
			img.set_pixel(i, j, Color(1, 1, 1, beam_at(x, y)))
	return img


## The beams' brightness (0..1) at x px ahead of the lamps, y px across.
static func beam_at(x: float, y: float) -> float:
	if x <= 0.0:
		return 0.0
	var d := x / BEAM_AHEAD
	var fall := pow(maxf(1.0 - d, 0.0), 1.3) * clampf(x / 14.0, 0.0, 1.0)
	var a := 0.0
	for lamp in [-LAMP_SPACING, LAMP_SPACING]:
		var ang := absf(atan2(y - lamp, x))
		var lobe := clampf(1.0 - ang / BEAM_HALF_ANGLE, 0.0, 1.0)
		a += lobe * lobe * fall
	return clampf(a * 1.1, 0.0, 1.0)


## Soft cone pointing along +X from the texture's centre (lighting, not art;
## the beat cop's torch).
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
