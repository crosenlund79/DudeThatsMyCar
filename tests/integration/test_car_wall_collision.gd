extends GutTest
## Car scene + physics wall: the car cannot pass through a wall, bounces per
## the model's response and reports the hit (driving <-> city contract).

const CAR_SCENE := preload("res://src/driving/car.tscn")

var _car: Car


func before_each() -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = Layers.WORLD
	var shape := ConcavePolygonShape2D.new()
	shape.segments = PackedVector2Array([Vector2(300, -500), Vector2(300, 500)])
	var cs := CollisionShape2D.new()
	cs.shape = shape
	wall.add_child(cs)
	add_child_autofree(wall)
	_car = CAR_SCENE.instantiate()
	add_child_autofree(_car)
	var vehicle: VehicleType = (load("res://src/driving/vehicles/sedan.tres") as VehicleType).duplicate()
	vehicle.params = vehicle.params.duplicate()
	vehicle.params.max_speed = 400.0
	vehicle.params.acceleration = 400.0
	_car.setup(vehicle, null)
	_car.place(Transform2D(0.0, Vector2.ZERO))
	_car.active = true
	_car.driven = true


func test_car_stops_at_wall_and_bounces_back() -> void:
	watch_signals(_car)
	_car.throttle = true
	await wait_physics_frames(120)
	assert_lt(_car.global_position.x, 300.0 - 38.0 + 1.0, "car front stays on the near side of the wall")
	assert_signal_emitted(_car, "wall_hit")


func test_glancing_hit_keeps_moving_along_wall() -> void:
	_car.place(Transform2D(0.0, Vector2(250, 0)))
	_car.model.velocity = Vector2(200, 300)
	_car.throttle = false
	await wait_physics_frames(10)
	assert_gt(_car.global_position.y, 20.0, "slides along the wall")
	assert_lt(_car.global_position.x, 300.0)


func test_inactive_car_does_not_move() -> void:
	_car.active = false
	_car.throttle = true
	await wait_physics_frames(10)
	assert_eq(_car.global_position, Vector2.ZERO)


func test_parked_car_shoved_into_motion_comes_to_rest() -> void:
	_car.driven = false
	_car.model.velocity = Vector2(-150, 40)
	await wait_physics_frames(30)
	assert_eq(_car.model.velocity, Vector2.ZERO, "handbrake on: it stops")
	var at := _car.global_position
	await wait_physics_frames(10)
	assert_eq(_car.global_position, at)
