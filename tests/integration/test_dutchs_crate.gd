extends "res://tests/support/city_test.gd"
## M009.4 Danny's own work in the Riverfront Yards: Dutch stands outside his
## night lunch with a crate for Novak; Danny takes it on, brings a car up to
## the kerb and heaves the crate into its boot, drives it to Novak's Grocery
## and is paid at the door - his own money, nothing to do with Rourke. Left
## alone, Dutch finds another way; taken and not delivered by two, it is a
## broken promise.


func _go(p: Vector2, rot: float = 0.0) -> void:
	walker().place(p, rot)
	main.camera.snap_to(player().body())


## Danny out front of Dutch's, the yards built round him.
func _yards() -> DistrictLayout:
	var l: DistrictLayout = main.world.layouts.yards
	_go(_contact_pos(l) + Vector2(-200, 60))
	main.world.load_now("yards")
	return l


func _contact_pos(l: DistrictLayout) -> Vector2:
	return l.contacts[0].pos


func _crate_pos(l: DistrictLayout) -> Vector2:
	return l.errands[0].pos


func _set_minute(m: float) -> void:
	main.clock.set_time(m)
	main._update_clock(0.0)


func test_dutch_and_his_crate() -> void:
	var l := _yards()
	await wait_physics_frames(2)
	var dutch: Walker = main.opportunity_views.contact("dutch")
	assert_not_null(dutch, "Dutch is out front of his lunch counter")
	assert_lt(dutch.global_position.distance_to(_contact_pos(l)), 2.0)
	var crate: Sprite2D = main.opportunity_views.errand("crate")
	assert_true(crate.visible, "his crate by the door")
	# talk: he offers it; Danny takes it on
	_go(_contact_pos(l) + Vector2(0, 30), -PI / 2)
	await wait_physics_frames(2)
	assert_string_contains(main.hud.prompt_label.text, "Talk to Dutch")
	await press_e()
	assert_eq(main.dialogue.talking, "dutch")
	assert_string_contains(main.hud.line_label.text, "Novak")
	await answer_with("take")
	assert_eq(main.rackets.opportunities.crate, "taken")
	await press_e()
	# at the crate on foot with no car about: too heavy
	var sedan: Car = main.fleet.my_car()
	_go(_crate_pos(l) + Vector2(0, 22), -PI / 2)
	await wait_physics_frames(2)
	assert_string_contains(main.hud.prompt_label.text, "Load the crate")
	await press_e()
	assert_eq(main.rackets.opportunities.crate, "taken", "not without a car")
	# the sedan up at the kerb: into the boot
	await park(sedan, _crate_pos(l) + Vector2(0, 72), 0.0)
	_go(_crate_pos(l) + Vector2(0, 22), -PI / 2)
	await wait_physics_frames(2)
	await press_e()
	assert_eq(main.rackets.opportunities.crate, "loaded")
	assert_true(sedan.has_meta("cargo"), "in the sedan's boot")
	assert_not_null(sedan.get_node_or_null("Cargo"), "strapped on behind, where you can see it")
	await wait_physics_frames(2)
	assert_false(crate.visible, "gone from Dutch's door")
	# up to Novak's: the sedan at the kerb out front, Danny inside
	var door: Vector2 = main._novak_door()
	await park(sedan, Vector2(door.x, door.y - 70.0), 0.0)
	var money: int = main.rackets.money
	var held: int = main.rackets.held
	var expected: int = main.rackets.boss.expected
	await talk_to("grocery", "novak")
	await answer_with("crate")
	assert_eq(main.rackets.money - money, Opportunities.CRATE_PAY, "four dollars from Novak")
	assert_eq(main.rackets.held, held, "his own: nothing set aside for Rourke")
	assert_eq(main.rackets.boss.expected, expected, "and Rourke expects no more for it")
	assert_eq(main.rackets.opportunities.crate, "delivered")
	assert_false(sedan.has_meta("cargo"))
	await press_e()
	await wait_physics_frames(2)
	assert_null(sedan.get_node_or_null("Cargo"))


func test_novak_wants_it_out_front_not_across_town() -> void:
	main.rackets.opportunities.take_crate()
	main.rackets.opportunities.load_crate()
	var sedan: Car = main.fleet.my_car()
	main.fleet.set_cargo(sedan, true)
	await park(sedan, Vector2(1000, 600), 0.0)  # down the avenue
	await talk_to("grocery", "novak")
	assert_false(main.dialogue.page.options.any(func(o: Dictionary) -> bool: return o.id == "crate"), "he sees no crate")


func test_left_alone_dutch_finds_another_way() -> void:
	var l := _yards()
	await wait_physics_frames(2)
	_set_minute(Opportunities.CRATE_UNTIL)
	assert_eq(main.rackets.opportunities.crate, "gone")
	await wait_physics_frames(2)
	assert_false(main.opportunity_views.errand("crate").visible, "his nephew took it")
	_go(_contact_pos(l) + Vector2(0, 30), -PI / 2)
	await wait_physics_frames(2)
	await press_e()
	assert_string_contains(main.hud.line_label.text, "Too late")
	assert_eq(main.rackets.memory.recent("dutch", "broken_promise", main.rackets.night), 0, "Danny promised nothing")


func test_taken_and_not_delivered_by_two() -> void:
	main.rackets.opportunities.take_crate()
	main.rackets.opportunities.load_crate()
	var sedan: Car = main.fleet.my_car()
	main.fleet.set_cargo(sedan, true)
	_set_minute(Opportunities.CRATE_DELIVER_BY)
	assert_eq(main.rackets.opportunities.crate, "dropped")
	assert_false(sedan.has_meta("cargo"), "fetched out of the boot")
	assert_eq(main.rackets.memory.recent("dutch", "broken_promise", main.rackets.night), 1, "Dutch remembers")
	assert_string_contains(main.hud.notice_label.text, "Two o'clock")


func test_dutch_is_freed_with_the_yards() -> void:
	_yards()
	await wait_physics_frames(2)
	assert_not_null(main.opportunity_views.contact("dutch"))
	_go(main.layout.spawn)
	main.world.unload("yards")
	await wait_physics_frames(3)
	assert_null(main.opportunity_views.contact("dutch"), "gone with the district")
	_yards()
	await wait_physics_frames(2)
	assert_not_null(main.opportunity_views.contact("dutch"), "and back with it")
	assert_eq(get_tree().root.find_children("Contact_dutch", "", true, false).size(), 1, "one Dutch, never two")
