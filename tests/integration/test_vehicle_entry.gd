extends "res://tests/support/city_test.gd"
## Walking, getting in, driving (throttle, brake / reverse, steering,
## handbrake) and getting out beside the car: never into a wall, a car, the
## river or out of the district; when there is no room the player stays in.


func test_walk_to_the_roadster_and_get_in() -> void:
	var c := roadster()
	await walk_to(c.global_position + Vector2(0, 40), 3.0)
	await press_e()
	assert_false(player().on_foot())
	assert_eq(player().car, c)
	assert_true(c.driven)
	assert_false(walker().visible)
	assert_eq(main.camera.target, c, "the camera follows the car")
	assert_true((c.get_node("Lights") as VehicleLights).visible, "headlights on")


func test_e_does_nothing_far_from_cars() -> void:
	await press_e()
	assert_true(player().on_foot())


func test_drive_forward_reverse_and_steer() -> void:
	var c := roadster()
	await park(c, Vector2(1000, 1500), 0.0)  # middle of Pruitt Street
	await seat_in(c)
	await hold(Vector2(0, -1), 90)
	assert_gt(c.global_position.x, 1000.0 + 90.0, "W drives forward")
	assert_gt(c.model.forward_speed(), 150.0)
	await hold(Vector2(0, 1), 120)
	assert_lt(c.model.forward_speed(), -40.0, "S brakes, then reverses")
	var h := c.model.heading
	await hold(Vector2(1, -1), 40)
	assert_ne(c.model.heading, h, "A / D steer")


func test_handbrake_is_passed_to_the_car() -> void:
	var c := roadster()
	await park(c, Vector2(1000, 1500), 0.0)
	await seat_in(c)
	cmd = PlayerCommand.make(Vector2(0, -1), false, true)
	await wait_physics_frames(1)
	assert_true(c.handbrake)
	cmd = PlayerCommand.new()


func test_get_out_beside_the_car() -> void:
	var c := roadster()
	await park(c, Vector2(1000, 1500), 0.0)
	await seat_in(c)
	await press_e()
	assert_true(player().on_foot())
	assert_true(walker().visible)
	assert_false(c.driven, "parked again")
	var outside := PlayerController.distance_to_body(c, walker().global_position)
	assert_between(outside, 8.0, 30.0, "standing right beside it")
	assert_lt(walker().global_position.y, c.global_position.y, "out of the driver's door (left of a car heading east)")
	assert_eq(main.camera.target, walker())


func test_pressing_e_at_speed_stops_the_car_first() -> void:
	var c := roadster()
	await park(c, Vector2(400, 1500), 0.0)
	await seat_in(c)
	await hold(Vector2(0, -1), 110)
	assert_gt(c.speed(), 200.0)
	await press_e()
	assert_false(player().on_foot(), "nobody jumps out at speed")
	assert_true(player().leaving)
	for i in 120:
		if player().on_foot():
			break
		await wait_physics_frames(1)
	assert_true(player().on_foot(), "the car stopped and the driver got out")
	assert_lte(c.speed(), PlayerController.EXIT_SPEED + 1.0)


func test_a_wall_on_the_driver_side_means_the_other_door() -> void:
	var c := roadster()
	# against the front of the Copper Owl, heading east: the driver's side faces the wall
	await park(c, Vector2(2300, 439 + 20), 0.0)
	await seat_in(c)
	await press_e()
	assert_true(player().on_foot())
	assert_gt(walker().global_position.y, c.global_position.y, "out on the street side")
	assert_false(main.layout.is_in_building(walker().global_position, Walker.RADIUS))


func test_never_out_into_the_river() -> void:
	var c := car_of_type("sedan")
	# on the warehouse apron, heading south: the driver's side faces the river
	await park(c, Vector2(3878, 300), PI / 2)
	await seat_in(c)
	await press_e()
	assert_true(player().on_foot())
	assert_lt(walker().global_position.x, 3900.0, "on the quay, not in the water")
	assert_true(main.layout.is_open_ground(walker().global_position, Walker.RADIUS))


func test_no_room_to_get_out_keeps_the_player_in() -> void:
	var c := roadster()
	await park(c, Vector2(1000, 1500), 0.0)
	# a tight box round the car (a garage that fits it exactly)
	var box := StaticBody2D.new()
	box.collision_layer = Layers.WORLD
	for spec in [[Vector2(0, -26), Vector2(110, 8)], [Vector2(0, 26), Vector2(110, 8)], [Vector2(-48, 0), Vector2(8, 60)], [Vector2(48, 0), Vector2(8, 60)]]:
		var s := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = spec[1]
		s.shape = r
		s.position = Vector2(1000, 1500) + spec[0]
		box.add_child(s)
	main.add_child(box)
	await wait_physics_frames(2)
	await seat_in(c)
	watch_signals(player())
	await press_e()
	assert_false(player().on_foot(), "no clear spot: stays at the wheel")
	assert_signal_emitted_with_parameters(player(), "notice", ["No room to get out here."])
	box.queue_free()


func test_a_moving_car_cannot_be_entered() -> void:
	var c := roadster()
	walker().place(c.global_position + Vector2(0, -40), 0.0)
	await wait_physics_frames(1)
	assert_eq(player().enterable_car(), c)
	c.model.velocity = Vector2(200, 0)
	assert_null(player().enterable_car())
