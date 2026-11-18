extends "res://tests/support/city_test.gd"
## Streets, buildings and cars collide sensibly: cars and people cannot pass
## through buildings, people cannot walk through cars, a person fits through a
## gangway where a car does not, and every way out of the district is closed
## by something visible (barricades, the river railing, the embankment).


func test_a_car_cannot_drive_through_a_building() -> void:
	var c := roadster()
	await park(c, Vector2(2720, 600), -PI / 2)  # heading north at the row east of the Copper Owl
	await seat_in(c)
	watch_signals(c)
	await hold(Vector2(0, -1), 180)
	assert_gt(c.global_position.y, 439.0 + 30.0, "stopped by the front wall at y 439")
	assert_signal_emitted(c, "wall_hit")


func test_a_person_cannot_walk_into_a_building() -> void:
	walker().place(Vector2(2720, 470), -PI / 2)
	await hold(Vector2(0, -1), 120)
	assert_gte(walker().global_position.y, 439.0 + Walker.RADIUS - 1.0)


func test_a_person_cannot_walk_through_a_parked_car() -> void:
	var c := roadster()
	walker().place(c.global_position + Vector2(0, -50), PI / 2)
	await hold(Vector2(0, 1), 120)
	assert_gt(PlayerController.distance_to_body(c, walker().global_position), 0.0, "still outside the car")
	assert_lt(walker().global_position.y, c.global_position.y)


func test_a_gangway_fits_a_person_but_not_a_car() -> void:
	# the 26 px gangway between the first two houses on Calloway Street (x 341..367)
	walker().place(Vector2(354, -200), PI / 2)
	await hold(Vector2(0, 1), 240)
	assert_gt(walker().global_position.y, 40.0, "walked through to the yards behind")
	var c := roadster()
	await park(c, Vector2(354, -260), PI / 2)
	await seat_in(c)
	await hold(Vector2(0, -1), 120)
	assert_lt(c.global_position.y, -169.0 + 10.0, "the car does not fit")


func _drive_until_stopped(c: Car, ticks: int) -> void:
	cmd = PlayerCommand.make(Vector2(0, -1))
	await wait_physics_frames(ticks)
	cmd = PlayerCommand.new()


## M008: Marlowe Avenue and Pruitt Street now run on west into Halloran Square;
## Calloway Street is still closed.
func test_the_west_end_of_calloway_street_is_barricaded() -> void:
	var c := roadster()
	await park(c, Vector2(-300, -260), PI)
	await seat_in(c)
	await _drive_until_stopped(c, 240)
	assert_gt(c.global_position.x, RiversideWard.WEST_EDGE, "stopped by the street-closed barricades")


func test_the_river_railing_stops_cars() -> void:
	var c := roadster()
	await park(c, Vector2(3500, -300), 0.0)  # Calloway Street, heading for the river
	await seat_in(c)
	await _drive_until_stopped(c, 240)
	assert_lt(c.global_position.x, RiversideWard.RIVER_X)


func test_the_raised_bridge_and_gates_stop_cars() -> void:
	var c := roadster()
	await park(c, Vector2(3500, 640), 0.0)
	await seat_in(c)
	await _drive_until_stopped(c, 240)
	assert_lt(c.global_position.x, 3830.0, "held at the bridge gates")


func test_the_railroad_embankment_closes_the_north_end() -> void:
	var c := roadster()
	await park(c, Vector2(1650, -500), -PI / 2)  # Kessler Street, heading north
	await seat_in(c)
	await _drive_until_stopped(c, 240)
	assert_gt(c.global_position.y, RiversideWard.EMBANKMENT_Y)


## M008: Kessler and Wharf Street now run on south into the Riverfront Yards;
## Dorsey Street is still closed.
func test_the_south_end_of_dorsey_street_is_barricaded() -> void:
	var c := roadster()
	await park(c, Vector2(0, 1800), PI / 2)  # Dorsey Street, heading south
	await seat_in(c)
	await _drive_until_stopped(c, 240)
	assert_lt(c.global_position.y, RiversideWard.SOUTH_EDGE)
