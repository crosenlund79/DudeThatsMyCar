extends "res://tests/support/city_test.gd"
## M006 Danny's own car and other people's: getting into his sedan is nothing;
## taking another car is a theft, which the beat cop investigates only if he
## could see it happen; getting back into a car already taken is not a new
## incident; shooting still brings him as before.


func cop() -> PoliceOfficer:
	return main.officer


func car_index(owner: String) -> int:
	for i in main.layout.cars.size():
		if main.layout.cars[i].owner == owner:
			return i
	return -1


func _get_in(c: Car) -> void:
	walker().place(c.global_position + c.global_transform.y * -38.0, 0.0)
	await wait_physics_frames(3)
	await press_e()


func test_his_own_car_is_nobodys_business() -> void:
	var c: Car = main.fleet.cars[car_index("danny")]
	walker().place(c.global_position + c.global_transform.y * -38.0, 0.0)
	await wait_physics_frames(3)
	assert_string_contains(main.hud.prompt_label.text, "your Sedan")
	await press_e()
	assert_eq(player().car, c)
	assert_eq(main.fleet.theft_incidents, 0)
	assert_false(cop().brain.is_hunting())


func test_taken_where_nobody_sees_it() -> void:
	var c: Car = main.fleet.cars[0]  # the roadster outside the Hotel Marlowe, round the corner from the beat
	assert_gt(c.global_position.distance_to(cop().body.global_position), CarThefts.WITNESS_RANGE)
	walker().place(c.global_position + c.global_transform.y * -38.0, 0.0)
	await wait_physics_frames(3)
	assert_string_contains(main.hud.prompt_label.text, "not yours")
	await press_e()
	assert_eq(player().car, c)
	assert_eq(main.fleet.theft_incidents, 1, "a theft")
	assert_eq(main.fleet.thefts_witnessed, 0, "that nobody saw")
	assert_false(cop().brain.is_hunting(), "so no police")
	assert_string_contains(main.hud.notice_label.text, "Nobody saw")


func test_taken_under_the_cops_nose() -> void:
	var c: Car = main.fleet.cars[0]
	await park(c, cop().body.global_position + Vector2(140, 70), 0.0)
	await _get_in(c)
	assert_eq(player().car, c)
	assert_eq(main.fleet.thefts_witnessed, 1, "he saw it")
	assert_true(cop().brain.is_hunting(), "and comes to see")
	assert_string_contains(main.hud.notice_label.text, "saw you")


func test_the_same_stolen_car_is_one_incident() -> void:
	var c: Car = main.fleet.cars[0]
	await _get_in(c)
	assert_eq(main.fleet.theft_incidents, 1)
	await press_e()
	await wait_physics_frames(10)
	assert_null(player().car, "out again")
	await _get_in(c)
	assert_eq(player().car, c)
	assert_eq(main.fleet.theft_incidents, 1, "back into the same car: no new theft")
	assert_string_contains(main.hud.notice_label.text, "Nobody saw", "and no new notice")


func test_a_dead_cop_sees_nothing() -> void:
	var c: Car = main.fleet.cars[0]
	await park(c, cop().body.global_position + Vector2(140, 70), 0.0)
	for i in 8:
		if cop().is_down():
			break
		cop().body.hit_by_bullet(cop().body.global_position, Vector2.RIGHT, walker())
	await _get_in(c)
	assert_eq(main.fleet.theft_incidents, 1)
	assert_eq(main.fleet.thefts_witnessed, 0)


func test_a_new_night_the_cars_are_back_with_their_owners() -> void:
	var c: Car = main.fleet.cars[0]
	await _get_in(c)
	main.night.sleep()
	await wait_physics_frames(3)
	assert_false(main.fleet.thefts.is_stolen(0))
