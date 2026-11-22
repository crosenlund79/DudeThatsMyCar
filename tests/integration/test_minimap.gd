extends "res://tests/support/city_test.gd"
## M004 the minimap in the game: it follows you on foot and in a car (centre
## and heading), shows the beat cop where he is and turns his badge when he
## hunts you, and sits in its corner without covering the clock, the place
## panel, prompts, the dialogue or the car and gun readouts.


func mm() -> Minimap:
	return main.hud.minimap


func test_it_follows_you_on_foot() -> void:
	await at_the_streetcar_stop()
	await hold(Vector2(1, 0), 60)
	await wait_process_frames(2)
	assert_lt(mm().centre.distance_to(walker().global_position), 3.0, "you are in the middle")
	assert_almost_eq(mm().heading, walker().model.facing, 0.01, "the arrow turns with you")
	assert_true(mm().visible)


func test_it_follows_the_car_and_zooms_out_with_speed() -> void:
	var c := car_of_type("sedan")
	await park(c, Vector2(400, 1500), PI)  # westbound on Pruitt Street
	await seat_in(c)
	await wait_process_frames(10)
	var slow := mm().zoom
	await hold(Vector2(0, -1), 120)
	await wait_process_frames(2)
	assert_lt(mm().centre.distance_to(c.global_position), 4.0)
	assert_almost_eq(absf(angle_difference(mm().heading, c.model.heading)), 0.0, 0.01, "pointing the way the car faces")
	assert_gt(mm().zoom, slow, "a wider view at speed")


func test_the_beat_cop_shows_where_he_is() -> void:
	await at_the_streetcar_stop()
	await wait_process_frames(2)
	assert_lt(mm().police.distance_to(main.officer.body.global_position), 4.0)
	assert_false(mm().police_hunting)
	main.officer.hear_gunshot(main.officer.body.global_position, 300.0)
	await wait_physics_frames(2)
	await wait_process_frames(2)
	assert_true(mm().police_hunting, "his badge flashes red while he is after you")


func test_it_covers_none_of_the_hud() -> void:
	var hud: Hud = main.hud
	main.rackets.bottles = 2
	await at_the_streetcar_stop()
	main.dialogue.start("augie")
	await wait_process_frames(3)
	var map_rect := Rect2(mm().position, Minimap.SIZE)
	for panel in [hud.clock_panel, hud.place_label.get_parent().get_parent(), hud.dialogue_panel, hud.prompt, hud.police_panel]:
		var r := Rect2((panel as Control).position, (panel as Control).size)
		assert_false(map_rect.intersects(r), "clear of %s" % (panel as Control).name)
	main.dialogue.end()
	var c := car_of_type("sedan")
	await seat_in(c)
	await wait_process_frames(3)
	assert_false(map_rect.intersects(Rect2(hud.car_panel.position, hud.car_panel.size)), "clear of the car readout")
	assert_lt(map_rect.end.y, hud.get_viewport().get_visible_rect().size.y, "inside the 1280 x 720 screen")
