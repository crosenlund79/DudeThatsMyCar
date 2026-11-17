extends "res://tests/support/city_test.gd"
## M003 walking into the Copper Owl: the roof opens as you step in and closes
## behind you, the walls and furniture are solid, the lamps are lit only while
## you are inside, the bartender is there, E at the bar talks to him, and
## nothing on four wheels comes through the door.


func club() -> InteriorView:
	return main.interiors.view_of("copper_owl")


func _walk_in() -> void:
	walker().place(Vector2(2291, 500), -PI / 2)
	await wait_physics_frames(2)
	await walk_to(Vector2(2291, 380), 6.0, 240)
	await wait_physics_frames(30)


func test_stepping_in_opens_the_roof_and_stepping_out_closes_it() -> void:
	assert_eq(club().alpha, 0.0, "outside, the club looks as it always did")
	assert_false(club().visible)
	assert_eq(club().lights[0].energy, 0.0, "its lamps are off")
	await _walk_in()
	assert_eq(main.interiors.current, club().plan, "inside the Copper Owl")
	assert_eq(club().alpha, 1.0, "the cut-away shows")
	assert_false(club().host.visible, "the roof and walls are gone")
	assert_gt(club().lights[0].energy, 0.5, "the lamps are lit")
	assert_eq(main.hud.place_label.text, "The Copper Owl")
	assert_not_null(club().people.get("augie"), "Augie is behind the bar")
	await walk_to(Vector2(2291, 520), 6.0, 240)
	await wait_physics_frames(30)
	assert_null(main.interiors.current)
	assert_eq(club().alpha, 0.0)
	assert_true(club().host.visible, "the building is whole again")


func test_walls_and_furniture_are_solid() -> void:
	await _walk_in()
	await hold(Vector2(-1, 0), 150)
	assert_gt(walker().global_position.x, 2151.0 + InteriorPlan.WALL, "the west wall holds")
	walker().place(Vector2(2250, 300), 0.0)
	await hold(Vector2(0, -1), 120)
	assert_gt(walker().global_position.y, 222.0 + 12.0, "the bar counter stops you")


func test_e_at_the_bar_talks_to_augie() -> void:
	await _walk_in()
	await walk_to(Vector2(2240, 258), 4.0, 300)
	await wait_physics_frames(2)
	assert_string_contains(main.hud.prompt_label.text, "Talk to Augie")
	await press_e()
	assert_true(player().on_foot())


func test_no_car_comes_through_the_door() -> void:
	var c := car_of_type("sedan")
	await park(c, Vector2(2291, 560), -PI / 2)  # nose to the club door, on the avenue
	await seat_in(c)
	await hold(Vector2(0, -1), 180)
	assert_gt(c.global_position.y, 439.0, "the car stays outside")


func test_shots_inside_stop_at_the_walls() -> void:
	await _walk_in()
	watch_signals(main.bullets)
	await click(Vector2(2420, 380))
	await aim_for(Vector2(2420, 380), 40)
	assert_signal_emitted(main.bullets, "impact")
	var at: Vector2 = get_signal_parameters(main.bullets, "impact")[0]
	assert_lt(at.x, 2431.0 + 1.0, "the bullet stayed inside the club")
