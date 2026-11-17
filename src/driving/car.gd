class_name Car
extends CharacterBody2D
## Scene wrapper for CarModel: applies the driver's command each physics tick,
## moves the body with continuous collision and feeds wall contacts back into
## the model. Car-to-car contacts are resolved symmetrically through CarModel.
## Without a driver the car is parked: it only moves when shoved, and stops.

signal wall_hit(normal: Vector2, impact_speed: float)
signal car_hit(other: Car, impact_speed: float)

const MAX_SLIDES := 4
## Simulation step used for all driving maths, independent of engine timing.
## Matches the project's 60 physics ticks per second.
const FIXED_STEP := 1.0 / 60.0

var model: CarModel
var vehicle: VehicleType
## Logical image name of this car's paint scheme.
var paint := ""
## Driver command, set by whoever drives (the player controller, tests).
var steer := 0.0
var throttle := false
var brake := false
var handbrake := false
## Someone is at the wheel. Otherwise the car is parked.
var driven := false
var active := true

@onready var sprite: Sprite2D = $Sprite
@onready var shadow: Sprite2D = $Shadow


func setup(p_vehicle: VehicleType, texture: Texture2D, paint_name: String = "") -> void:
	vehicle = p_vehicle
	paint = paint_name
	model = CarModel.new(vehicle.params)
	model.position = global_position
	model.heading = global_rotation
	if texture != null:
		sprite.texture = texture
		sprite.scale = AssetCatalog.scale_for(texture, vehicle.size)
	var shadow_tex := SoftShadow.texture()
	shadow.texture = shadow_tex
	shadow.scale = (vehicle.size + Vector2(14, 12)) / Vector2(shadow_tex.get_size())
	var capsule := CapsuleShape2D.new()
	capsule.radius = vehicle.collision.y * 0.5
	capsule.height = vehicle.collision.x
	$Shape.shape = capsule


## Places the car at rest at the given transform.
func place(at: Transform2D) -> void:
	global_position = at.origin
	global_rotation = at.get_rotation()
	clear_command()
	if model != null:
		model.position = global_position
		model.heading = global_rotation
		model.velocity = Vector2.ZERO
		model.yaw_rate = 0.0


func clear_command() -> void:
	steer = 0.0
	throttle = false
	brake = false
	handbrake = false


func speed() -> float:
	return model.velocity.length() if model != null else 0.0


func _physics_process(_delta: float) -> void:
	if model == null or not active:
		return
	if driven:
		model.update(FIXED_STEP, steer, throttle, brake, handbrake)
	else:
		if model.velocity == Vector2.ZERO and model.yaw_rate == 0.0:
			return  # parked and still: nothing to simulate
		model.update_parked(FIXED_STEP)
	global_rotation = model.heading
	var motion := model.velocity * FIXED_STEP
	for i in MAX_SLIDES:
		var collision := move_and_collide(motion)
		if collision == null:
			break
		var normal := collision.get_normal()
		var other := collision.get_collider() as Car
		if other != null and other.model != null:
			var closing := -(model.velocity - other.model.velocity).dot(normal)
			CarModel.resolve_car_collision(model, other.model, normal, collision.get_position(), global_position, other.global_position)
			if closing > 0.0:
				car_hit.emit(other, closing)
			motion = collision.get_remainder().slide(normal)
		else:
			var impact := -model.velocity.dot(normal)
			var keep := model.apply_wall_collision(normal)
			if impact > 0.0:
				wall_hit.emit(normal, impact)
			global_rotation = model.heading
			motion = collision.get_remainder().slide(normal) * keep
		if motion.length_squared() < 0.0001:
			break
	model.position = global_position
