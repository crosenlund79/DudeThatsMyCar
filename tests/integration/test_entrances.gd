extends "res://tests/support/city_test.gd"
## M004 every place you can go into works with the normal controls: walk in
## off the sidewalk through its door, find your way round the furniture to
## whoever is there (or the bed), and E does what the prompt says. Then walk
## back out into the street and the roof closes behind you.


func _check(plan_id: String, spot_id: String, prompt: String) -> void:
	var plan: InteriorPlan = main.interiors.view_of(plan_id).plan
	var ok: bool = await walk_in_to(plan, spot_id)
	assert_true(ok, "%s: walked in to %s (at %s)" % [plan_id, spot_id, walker().global_position])
	assert_eq(main.interiors.current, plan, "%s: inside" % plan_id)
	assert_eq(main.interiors.view_of(plan_id).alpha, 1.0, "%s: the roof is open" % plan_id)
	assert_string_contains(main.hud.prompt_label.text, prompt)
	await press_e()
	assert_eq(main.talking, spot_id, "%s: E works" % plan_id)
	await press_e()
	assert_eq(main.talking, "", "and E walks away")
	var back := path_in_room(plan, walker().global_position, plan.inside_door(0, 14.0), 8.0)
	for p in back:
		await walk_to(p, 4.0, 120)
	await walk_to(plan.outside_door(0, 30.0), 4.0, 240)
	await wait_physics_frames(30)
	assert_null(main.interiors.current, "%s: back out in the street" % plan_id)
	assert_true(main.interiors.view_of(plan_id).host.visible, "%s: the building is whole again" % plan_id)


func test_novaks_grocery() -> void:
	await _check("grocery", "novak", "Talk to Mr. Novak")


func test_the_copper_owl() -> void:
	await _check("copper_owl", "augie", "Talk to Augie")


func test_sals_barber_shop() -> void:
	await _check("barber_shop", "sal", "Talk to Sal")


func test_lindqvist_hardware_and_eddies_back_room() -> void:
	await _check("hardware", "lindqvist", "Talk to Mr. Lindqvist")
	await _check("hardware", "eddie", "Talk to Eddie")


func test_your_flat() -> void:
	await _check("home", "bed", "Go to bed")


func test_novak_protection_through_the_front_door() -> void:
	var plan: InteriorPlan = main.interiors.view_of("grocery").plan
	var start: int = main.rackets.money
	assert_true(await walk_in_to(plan, "novak"))
	await press_e()
	await answer_with("protection")
	await answer_with("ask")
	assert_eq(main.rackets.money, start + main.economy_rules.grocer_protection)
	await press_e()
	await press_e()
	var ids: Array = main._page.options.map(func(o: Dictionary) -> String: return o.id)
	assert_false(ids.has("protection"), "once a night")


func test_e_at_any_door_goes_in_and_out() -> void:
	for plan in main.layout.interiors:
		var p: InteriorPlan = plan
		for i in p.doors.size():
			walker().place(p.outside_door(i, 14.0), 0.0)
			main.interiors.update_player(walker().global_position)
			await wait_physics_frames(3)
			assert_string_contains(main.hud.prompt_label.text, "Enter %s" % p.name, "%s door %d" % [p.id, i])
			await press_e()
			await wait_physics_frames(2)
			assert_eq(main.interiors.current, p, "%s: E took him in through door %d" % [p.id, i])
			assert_true(p.contains(walker().global_position, -Walker.RADIUS), "standing clear inside")
			await hold(Vector2(0, 0.0001), 2)
			assert_string_contains(main.hud.prompt_label.text, "Go out")
			await press_e()
			await wait_physics_frames(2)
			assert_null(main.interiors.current, "%s: and out again" % p.id)
			assert_true(main.layout.is_open_ground(walker().global_position, Walker.RADIUS), "onto open ground")
