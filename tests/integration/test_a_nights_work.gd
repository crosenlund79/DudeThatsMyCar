extends "res://tests/support/city_test.gd"
## M003 the whole night, played with the normal controls: wake at home, walk
## out to the car at the curb, drive down Marlowe Avenue to Sal's, buy the
## rye, drive back to the Copper Owl, sell it to Augie and collect his
## protection, walk home and sleep through to the next evening with the money.

const LIMIT := 60 * 40


func _walk_path(points: Array) -> void:
	for p in points:
		await walk_to(p, 6.0, 60 * 12)


func _stop_and_get_out(c: Car) -> void:
	for i in 120:
		cmd = PlayerCommand.make(Vector2(0, 1) if c.model.forward_speed() > 5.0 else Vector2.ZERO)
		await wait_physics_frames(1)
		if c.speed() < 5.0:
			break
	await press_e()


func test_a_nights_work() -> void:
	var start: int = main.rackets.money
	var home: InteriorPlan = main.interiors.view_of("home").plan
	var barber: InteriorPlan = main.interiors.view_of("barber_shop").plan
	var club: InteriorPlan = main.interiors.view_of("copper_owl").plan
	assert_eq(main.interiors.current, home, "evening: he wakes at home")
	# out of the door to the sedan at the curb
	await _walk_path([home.inside_door(0, 20.0), home.outside_door(0, 22.0)])
	assert_null(main.interiors.current, "out in the street")
	var car: Car = null
	for c in main.cars:
		if c.global_position.distance_to(Vector2(2585, 506)) < 5.0:
			car = c
	await walk_to(car.global_position + Vector2(0, -32), 4.0)
	await press_e()
	assert_eq(player().car, car, "in the car")
	# a three-point turn is not needed: pull out and head west to Sal's
	var ticks := await drive_route(car, [Vector2(2480, 560), Vector2(2200, 560), Vector2(1400, 560), Vector2(1120, 545)], 150.0, LIMIT)
	assert_lt(ticks, LIMIT, "drove down Marlowe Avenue")
	await _stop_and_get_out(car)
	assert_true(player().on_foot())
	# out on the street side: round the car's nose to the sidewalk
	var nose := car.global_position + Vector2.from_angle(car.model.heading) * 60.0
	await _walk_path([Vector2(nose.x, walker().global_position.y), Vector2(nose.x, 470.0), barber.outside_door(0, 22.0),
		barber.inside_door(0, 20.0), Vector2(1040, 380), Vector2(990, 368)])
	assert_string_contains(main.hud.prompt_label.text, "Talk to Sal")
	await press_e()
	await answer_with("buy_all")
	await answer_with("bye")
	assert_eq(main.rackets.bottles, 6, "six bottles of rye under his coat")
	# back to the car and east to the club
	await _walk_path([Vector2(1060, 400), barber.inside_door(0, 20.0), barber.outside_door(0, 22.0),
		Vector2(nose.x, 470.0), Vector2(nose.x, car.global_position.y + 34.0)])
	await walk_to(car.global_position + car.global_transform.y * -32.0, 4.0)
	await press_e()
	assert_eq(player().car, car)
	ticks = await drive_route(car, [Vector2(1400, 560), Vector2(2000, 560), Vector2(2240, 548)], 150.0, LIMIT)
	assert_lt(ticks, LIMIT, "drove back to the club")
	await _stop_and_get_out(car)
	await _walk_path([club.outside_door(0, 30.0), club.inside_door(0, 30.0), Vector2(2265, 330), Vector2(2240, 258)])
	assert_string_contains(main.hud.prompt_label.text, "Talk to Augie")
	await press_e()
	await answer_with("sell")
	assert_eq(main.rackets.bottles, 0)
	await answer_with("bye")
	await press_e()
	await answer_with("protection")
	await answer_with("ask")
	await answer_with("bye")
	var takings: int = main.rackets.money - start
	assert_eq(takings, 6 * (main.economy_rules.bar_price - main.economy_rules.barber_price) + main.rackets.club().protection,
		"a profit on the rye and the protection money")
	# home to bed
	await _walk_path([Vector2(2280, 330), club.inside_door(0, 30.0), club.outside_door(0, 30.0), Vector2(2380, 470),
		home.outside_door(0, 22.0), home.inside_door(0, 20.0), Vector2(2516, 352)])
	assert_eq(main.interiors.current, home)
	assert_string_contains(main.hud.prompt_label.text, "Go to bed")
	await press_e()
	await answer_with("sleep")
	assert_eq(main.rackets.night, 2, "the next evening")
	assert_eq(main.rackets.money, start + takings, "with the night's money")
