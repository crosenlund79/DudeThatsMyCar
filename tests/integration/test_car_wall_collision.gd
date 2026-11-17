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


func _real_car(vehicle_path: String) -> Car:
	var c: Car = CAR_SCENE.instantiate()
	c.position = Vector2(0, 200)
	add_child_autofree(c)
	c.setup(load(vehicle_path), null)
	c.active = true
	c.driven = true
	return c


func test_a_glancing_scrape_keeps_momentum_without_entering_the_wall() -> void:
	# a long horizontal wall along y = -600 (clear of the other test fixtures);
	# the sedan comes in at 12 degrees
	var wall := StaticBody2D.new()
	wall.collision_layer = Layers.WORLD
	var shape := ConcavePolygonShape2D.new()
	shape.segments = PackedVector2Array([Vector2(-3000, -600), Vector2(-200, -600)])
	var cs := CollisionShape2D.new()
	cs.shape = shape
	wall.add_child(cs)
	add_child_autofree(wall)
	_car.active = false
	var c := _real_car("res://src/driving/vehicles/sedan.tres")
	c.place(Transform2D(-deg_to_rad(12.0), Vector2(-2400, -460)))
	c.model.velocity = Vector2.from_angle(-deg_to_rad(12.0)) * 300.0
	c.model.drive_level = 1.0
	c.throttle = true
	watch_signals(c)
	var lowest := INF
	for i in 120:
		await wait_physics_frames(1)
		lowest = minf(lowest, c.global_position.y)
	assert_signal_emitted(c, "wall_hit")
	assert_gte(lowest, -600.0 + 14.0, "the body never pushed into the wall")
	assert_gt(c.model.velocity.length(), 300.0 * 0.6, "it scraped along and kept going")
	assert_lt(absf(angle_difference(c.model.heading, 0.0)), deg_to_rad(8.0), "now running along the wall")


func test_a_head_on_hit_still_stops_the_car() -> void:
	_car.active = false
	var c := _real_car("res://src/driving/vehicles/coupe.tres")
	c.place(Transform2D(0.0, Vector2(100, 0)))
	c.model.velocity = Vector2(300, 0)
	await wait_physics_frames(60)
	assert_lt(c.global_position.x, 300.0 - 37.0, "stopped short of the wall at x 300")
	assert_lt(c.model.velocity.x, 60.0, "and lost its speed")
