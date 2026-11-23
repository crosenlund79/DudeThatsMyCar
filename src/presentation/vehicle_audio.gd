class_name VehicleAudio
extends Node
## Sound of the car the player drives (from HyperCars' engine sound): a deep
## engine loop whose pitch follows speed plus a load layer while accelerating,
## tyre squeal when sliding or on the handbrake, and knocks against walls and
## other cars. Silent when nobody drives. Presentation only.

const SQUEAL_SLIP := 70.0

var params: EngineSoundParams = preload("res://src/audio/default_engine_sound.tres")
var car: Car
var engine: AudioStreamPlayer
var load_layer: AudioStreamPlayer
var squeal: AudioStreamPlayer
var impact_wall: AudioStreamPlayer
var impact_car: AudioStreamPlayer
## M015: a person struck by the car (a dull thump: the fistfight's landed punch, lower).
var impact_person: AudioStreamPlayer
var _pitch := 0.78
var _load := 0.0
var _last_speed := 0.0
var _clock := 0.0


func setup(resolver: AssetResolver) -> void:
	name = "VehicleAudio"
	engine = _player(resolver.get_audio("vehicles/engine_loop", true), "Engine")
	load_layer = _player(resolver.get_audio("vehicles/engine_load", true), "Engine")
	squeal = _player(resolver.get_audio("vehicles/tire_squeal", true), "Effects")
	impact_wall = _player(resolver.get_audio("vehicles/impact_wall"), "Effects")
	impact_car = _player(resolver.get_audio("vehicles/impact_car"), "Effects")
	impact_person = _player(resolver.get_audio("fight/punch_landed"), "Effects")


func _player(stream: AudioStream, bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus if AudioServer.get_bus_index(bus) >= 0 else "Master"
	add_child(p)
	return p


## Start following a car (null: engine off).
func attach(p_car: Car) -> void:
	if car != null:
		if car.wall_hit.is_connected(_on_wall_hit):
			car.wall_hit.disconnect(_on_wall_hit)
			car.car_hit.disconnect(_on_car_hit)
			car.struck_person.disconnect(_on_struck_person)
	car = p_car
	for p in [engine, load_layer, squeal]:
		p.stop()
	if car == null:
		return
	car.wall_hit.connect(_on_wall_hit)
	car.car_hit.connect(_on_car_hit)
	car.struck_person.connect(_on_struck_person)
	_last_speed = 0.0
	_pitch = params.pitch_idle
	engine.volume_db = params.volume_idle_db
	engine.play()
	load_layer.volume_db = -60.0
	load_layer.play()


## Pitch and volumes of the engine for its state (pure; also used by tests).
## speed_ratio: forward speed / max speed. load: 0..1 how hard the engine
## works. brake: 0..1 braking. time: seconds, for the slow drift.
static func engine_targets(p: EngineSoundParams, speed_ratio: float, load: float, brake: float, time: float,
		phase: float = 0.0) -> Dictionary:
	var r := clampf(speed_ratio, 0.0, 1.0)
	var pitch := lerpf(p.pitch_idle, p.pitch_top, pow(r, p.pitch_curve))
	pitch += p.load_pitch * clampf(load, 0.0, 1.0) + p.brake_pitch * clampf(brake, 0.0, 1.0)
	pitch *= 1.0 + p.drift_amount * sin(TAU * p.drift_hz * time + phase)
	var base_db := lerpf(p.volume_idle_db, p.volume_top_db, r) - 2.0 * clampf(brake, 0.0, 1.0)
	var l := clampf(load, 0.0, 1.0)
	var load_db := p.load_volume_db + linear_to_db(maxf(l, 0.001))
	return {"pitch": pitch, "base_db": base_db, "load_db": load_db}


func _process(delta: float) -> void:
	if car == null or car.model == null or delta <= 0.0:
		return
	_clock += delta
	var speed := absf(car.model.forward_speed())
	var accel := (speed - _last_speed) / delta
	_last_speed = speed
	var working := 1.0 if car.throttle and not car.brake else 0.0
	var load_now := clampf(maxf(working * 0.6, accel / car.model.params.acceleration), 0.0, 1.0)
	_load = lerpf(_load, load_now, 1.0 - exp(-delta / params.load_smoothing))
	var braking := 1.0 if (car.brake and car.model.forward_speed() > 5.0) or car.handbrake else 0.0
	var t := engine_targets(params, speed / car.model.params.max_speed, _load, braking, _clock)
	_pitch = lerpf(_pitch, t.pitch * car.vehicle.engine_pitch, 1.0 - exp(-delta / params.pitch_smoothing))
	engine.pitch_scale = maxf(0.05, _pitch)
	load_layer.pitch_scale = maxf(0.05, _pitch)
	engine.volume_db = lerpf(engine.volume_db, t.base_db, 1.0 - exp(-delta / params.volume_smoothing))
	load_layer.volume_db = lerpf(load_layer.volume_db, t.load_db, 1.0 - exp(-delta / params.volume_smoothing))
	var slip := absf(car.model.slip)
	var sliding := slip > SQUEAL_SLIP or (car.handbrake and speed > 60.0)
	if sliding and not squeal.playing:
		squeal.play()
	elif not sliding and squeal.playing:
		squeal.stop()
	if squeal.playing:
		squeal.volume_db = linear_to_db(clampf(maxf(slip, speed * 0.5) / 300.0, 0.15, 0.8))


func _on_wall_hit(_normal: Vector2, impact_speed: float) -> void:
	_knock(impact_wall, impact_speed)


func _on_car_hit(_other: Car, impact_speed: float) -> void:
	_knock(impact_car, impact_speed)


func _on_struck_person(_person: Walker, impact_speed: float) -> void:
	_knock(impact_person, impact_speed + 60.0)
	if impact_person.stream != null:
		impact_person.pitch_scale = randf_range(0.62, 0.74)


func _knock(p: AudioStreamPlayer, impact_speed: float) -> void:
	if impact_speed < 40.0 or p.stream == null:
		return
	p.volume_db = linear_to_db(clampf(impact_speed / 350.0, 0.2, 1.0))
	p.pitch_scale = randf_range(0.92, 1.06)
	p.play()
