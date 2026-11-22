extends "res://tests/support/city_test.gd"
## M009.5 a neighbourhood problem in Halloran Square: the Bijou's late-show
## reel never came. Mr. Feeney, under the marquee, asks Danny to find it;
## the can lies in St. Brendan's churchyard; brought back before eleven, the
## show goes on and Feeney pays. Ignored, the show is cancelled at eleven all
## the same, and the square talks about it. It never touches Rourke's job.


func _go(p: Vector2, rot: float = 0.0) -> void:
	walker().place(p, rot)
	main.camera.snap_to(player().body())


func _square() -> DistrictLayout:
	var l: DistrictLayout = main.world.layouts.halloran
	_go(l.contacts[0].pos + Vector2(-200, 60))
	main.world.load_now("halloran")
	return l


func _set_minute(m: float) -> void:
	main.clock.set_time(m)
	main._update_clock(0.0)


func test_feeney_s_reel_found_and_returned() -> void:
	var l := _square()
	await wait_physics_frames(2)
	var feeney: Walker = main.errands.views.contact("feeney")
	assert_not_null(feeney, "Mr. Feeney outside the Bijou")
	var can: Sprite2D = main.errands.views.errand("film_can")
	assert_true(can.visible)
	assert_true(main.world.is_open_ground(can.global_position, 12.0), "the can lies where Danny can walk")
	_go(feeney.global_position + Vector2(0, 30), -PI / 2)
	await wait_physics_frames(2)
	assert_string_contains(main.hud.prompt_label.text, "Mr. Feeney")
	await press_e()
	assert_string_contains(main.hud.line_label.text, "St. Brendan's")
	await answer_with("take")
	assert_eq(main.rackets.opportunities.reel, "looking")
	await press_e()
	# behind the church: walk up to the can and pick it up
	_go(can.global_position + Vector2(0, 40), -PI / 2)
	await walk_to(can.global_position + Vector2(0, 16), 6.0, 200)
	assert_string_contains(main.hud.prompt_label.text, "film can")
	await press_e()
	assert_eq(main.rackets.opportunities.reel, "found")
	await wait_physics_frames(2)
	assert_false(can.visible, "in Danny's coat")
	# back to the Bijou before eleven
	var money: int = main.rackets.money
	var job_state: Dictionary = main.rackets.job.to_dict()
	_go(feeney.global_position + Vector2(0, 30), -PI / 2)
	await wait_physics_frames(2)
	await press_e()
	await answer_with("give")
	assert_eq(main.rackets.money - money, Opportunities.REEL_PAY)
	assert_eq(main.rackets.opportunities.reel, "returned")
	assert_eq(main.rackets.job.to_dict(), job_state, "Rourke's job untouched")
	await press_e()
	_set_minute(Opportunities.REEL_SHOW + 1.0)
	assert_eq(main.rackets.opportunities.reel, "returned", "the show went on")


func test_ignored_the_show_is_cancelled() -> void:
	var l := _square()
	await wait_physics_frames(2)
	_set_minute(Opportunities.REEL_SHOW)
	assert_eq(main.rackets.opportunities.reel, "cancelled", "eleven o'clock, no reel")
	await wait_physics_frames(2)
	assert_false(main.errands.views.errand("film_can").visible, "the boy found it in the morning")
	assert_true(main.rackets.rumours.items.any(func(r: Dictionary) -> bool: return r.kind == "reel_cancelled" and r.origin == "feeney"))
	assert_eq(main.rackets.memory.recent("feeney", "broken_promise", main.rackets.night), 0)
	_go(l.contacts[0].pos + Vector2(0, 30), -PI / 2)
	await wait_physics_frames(2)
	await press_e()
	assert_string_contains(main.hud.line_label.text, "No reel, no late show")
	# Sal shaves Mr. Feeney: by the next night the ward has heard
	await press_e()
	main.night.sleep()
	await wait_physics_frames(3)
	assert_true(main.rackets.rumours.known_to("sal", "reel_cancelled").size() > 0, "Sal heard it in the chair")


func test_a_promise_not_kept() -> void:
	_square()
	await wait_physics_frames(2)
	main.rackets.opportunities.take_reel()
	_set_minute(Opportunities.REEL_SHOW)
	assert_eq(main.rackets.memory.recent("feeney", "broken_promise", main.rackets.night), 1)
	assert_string_contains(main.hud.notice_label.text, "late show's off")


func test_no_reel_trouble_on_other_nights() -> void:
	main.night.sleep()  # night 2
	await wait_physics_frames(3)
	assert_eq(main.rackets.opportunities.reel, "none")
	var l := _square()
	await wait_physics_frames(2)
	assert_false(main.errands.views.errand("film_can").visible, "no can behind the church")
	_go(l.contacts[0].pos + Vector2(0, 30), -PI / 2)
	await wait_physics_frames(2)
	await press_e()
	assert_string_contains(main.hud.line_label.text, "Fifteen cents")
