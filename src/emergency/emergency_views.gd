class_name EmergencyViews
extends Node2D
## M010: the emergency on screen: the police car, the fire engine and the
## ambulance driving in along the street with their lamps winking (the siren,
## the fire engine's bell), stopping at their places near the scene; their
## crews get out and stand round it for the rest of the night - the coppers
## keeping people back, the firemen at the wreck, the ambulance men by their
## doors. Solid while they stand (people and cars go round them), never
## enterable: they are not Cars. Presentation of EmergencyResponse.

signal fire_out

const CREW_SPREAD := 34.0

var response: EmergencyResponse
## Where the crews stand: the scene (each unit's crew between its stop and the scene).
var scene := Vector2.ZERO
var bodies: Array[AnimatableBody2D] = []
var lamps: Array[PointLight2D] = []
var crews: Array[Walker] = []
var _resolver: AssetResolver
var _sounds: Array[AudioStreamPlayer2D] = []
var _t := 0.0
var _bell_left := 0.0


func setup(resolver: AssetResolver, p_response: EmergencyResponse) -> void:
	name = "Emergency"
	_resolver = resolver
	response = p_response


## Builds the three vehicles for a fresh dispatch (or a settled one).
func show_units(p_scene: Vector2) -> void:
	clear_units()
	scene = p_scene
	for i in response.units.size():
		var spec: Dictionary = EmergencyResponse.UNITS[i]
		var body := AnimatableBody2D.new()
		body.name = String(spec.id).capitalize()
		body.sync_to_physics = false
		body.collision_layer = Layers.WORLD
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = (spec.size as Vector2) - Vector2(6, 4)
		shape.shape = box
		body.add_child(shape)
		var sprite := Sprite2D.new()
		sprite.texture = _resolver.get_texture(spec.look)
		sprite.scale = AssetCatalog.scale_for(sprite.texture, spec.size)
		sprite.z_index = Layers.Z_PROP + 3
		sprite.z_as_relative = false
		sprite.light_mask = Layers.LIGHT_STREET
		body.add_child(sprite)
		var lamp := PointLight2D.new()
		lamp.texture = LightTextures.radial()
		lamp.texture_scale = 140.0 / 256.0
		lamp.color = Color(1.0, 0.25, 0.18)
		lamp.energy = 0.0
		lamp.position = Vector2((spec.size as Vector2).x * 0.3, 0)
		lamp.range_item_cull_mask = Layers.LIGHT_STREET
		body.add_child(lamp)
		var snd := AudioStreamPlayer2D.new()
		snd.stream = _resolver.get_audio(spec.sound)
		snd.max_distance = 2200.0
		snd.bus = "Effects" if AudioServer.get_bus_index("Effects") >= 0 else "Master"
		body.add_child(snd)
		add_child(body)
		bodies.append(body)
		lamps.append(lamp)
		_sounds.append(snd)
		_place(i)


func clear_units() -> void:
	for b in bodies:
		b.queue_free()
	for w in crews:
		if is_instance_valid(w):
			w.queue_free()
	bodies.clear()
	lamps.clear()
	crews.clear()
	_sounds.clear()


func _place(i: int) -> void:
	var p := response.pose(i)
	bodies[i].global_position = p.pos
	bodies[i].rotation = p.rot


## Every frame: moves them on, the lamps wink, the bell clangs while the engine drives.
func update(p_night: int, minute: float, delta: float) -> void:
	if not response.active(p_night):
		if not bodies.is_empty():
			clear_units()
		return
	if bodies.is_empty():
		show_units(response.at)
		for i in response.units.size():
			if response.units[i].state == "stopped":
				_crew_out(i, true)
	_t += delta
	for e in response.advance(minute, delta):
		var i := _index(e.id)
		match String(e.what):
			"set_off":
				if i >= 0 and _sounds[i].stream != null:
					_sounds[i].play()
			"stopped":
				_crew_out(i, false)
			"fire_out":
				fire_out.emit()
	for i in bodies.size():
		_place(i)
		var u: Dictionary = response.units[i]
		var on: bool = u.state != "waiting"
		lamps[i].enabled = on
		lamps[i].energy = (1.2 if fmod(_t * 2.2 + i * 0.37, 1.0) < 0.5 else 0.25) if on else 0.0
		bodies[i].visible = on
		(bodies[i].get_child(0) as CollisionShape2D).disabled = not on
	_bell_left -= delta
	var fire := response.unit("fire")
	if not fire.is_empty() and fire.state == "driving" and _bell_left <= 0.0:
		var k := _index("fire")
		if _sounds[k].stream != null and not _sounds[k].playing:
			_sounds[k].play()
		_bell_left = 2.8
	for w in crews:
		if not is_instance_valid(w) or w.down:
			continue
		var target: Vector2 = w.get_meta("target")
		var via: Vector2 = w.get_meta("via", target)
		if w.global_position.distance_to(via) > 6.0:
			target = via
		else:
			w.set_meta("via", w.get_meta("target"))
		var to := target - w.global_position
		w.move = to.normalized() * 0.55 if to.length() > 6.0 else Vector2.ZERO
		if to.length() <= 6.0:
			w.aim_point = w.get_meta("look")


func _index(id: String) -> int:
	for i in response.units.size():
		if response.units[i].id == id:
			return i
	return -1


## The crew get out of unit i and go to their places round the scene.
func _crew_out(i: int, at_once: bool) -> void:
	if i < 0:
		return
	var spec: Dictionary = EmergencyResponse.UNITS[i]
	var stop: Vector2 = bodies[i].global_position
	var side := Vector2.from_angle(bodies[i].rotation).orthogonal()
	var looks: Array = spec.crew
	for k in looks.size():
		var w := Walker.create(_resolver, looks[k], {"glow": false})
		w.name = "%s_crew_%d" % [spec.id, k]
		add_child(w)
		var target := _place_for(String(spec.id), k, stop)
		var start := stop + side * ((spec.size as Vector2).y * 0.5 + 10.0) + Vector2.from_angle(bodies[i].rotation) * (k * 14.0 - 10.0)
		w.place(target if at_once else start, (scene - target).angle())
		w.set_meta("target", target)
		w.set_meta("via", target if at_once else Vector2(target.x, start.y))  # along beside the vehicles first, then in
		w.set_meta("look", scene if spec.id != "ambulance" else stop)
		w.aim_point = scene
		w.rng.seed = 9100 + i * 10 + k
		crews.append(w)


## Where each of a unit's crew stands: the coppers on the pavement between the
## wreck and the onlookers, the firemen along the wreck's street side, the
## ambulance men by their own doors.
func _place_for(id: String, k: int, stop: Vector2) -> Vector2:
	match id:
		"police":
			return scene + (Vector2(-130, -24) if k == 0 else Vector2(100, -42))  # between the wreck and the onlookers
		"fire":
			return scene + Vector2(-46 + k * 46, 44)  # along the wreck's street side, hoses on it
	return stop + Vector2(-20 + k * CREW_SPREAD, 34)
