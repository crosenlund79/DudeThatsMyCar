extends "res://tests/support/city_test.gd"
## M010 Rourke's job at Rosie's Café in the game: Rourke offers it ("not
## tonight" leaves it open), Eddie sells the parcel, the Packard stands at the
## kerb from ten, E slips the parcel under it, Danny sits on the bench across
## the avenue and lets the time pass - it slows before the moment - and the
## short film plays in the game (bars, captions, the camera to the café, the
## flash, back to Danny); the wreck burns, the scorch, the café's people out
## on the pavement, the square's copper comes to look but nobody knows it was
## Danny; Rourke pays once; the next night the wreck is still there and the
## job is never offered again. Too close, Danny is hurt; seen at the car by a
## copper, he is suspected.


func _halloran() -> DistrictLayout:
	return main.world.layouts.halloran


func _go(p: Vector2, rot: float = 0.0) -> void:
	walker().place(p, rot)
	main.camera.snap_to(walker())


func _take_the_job() -> void:
	main.rackets.money = 2000
	await talk_to("copper_owl", "rourke")
	await answer_with("cafe")
	await answer_with("cafe_later")
	assert_eq(main.rackets.cafe.stage, CafeJob.Stage.OFFERED, "not tonight: still on offer")
	await press_e()  # walk away
	await talk_to("copper_owl", "rourke")
	await answer_with("cafe")
	await answer_with("cafe_accept")
	await press_e()
	await talk_to("hardware", "eddie")
	await answer_with("wares")
	await answer_with("parcel")
	await press_e()
	assert_eq(main.rackets.parcels, 1)


func _at_the_car(offset: Vector2 = Vector2(0, -34)) -> void:
	var car: Vector2 = _halloran().cafe_point("car").pos
	_go(car + offset, PI / 2)
	main.world.load_now("halloran")
	main.clock.set_time(22 * 60.0 + 30.0)
	await wait_physics_frames(4)


func test_the_whole_job() -> void:
	await _take_the_job()
	await _at_the_car()
	assert_true(main.cafe_scene.near_car(walker().global_position), "the Packard at the kerb at half past ten")
	assert_string_contains(main.hud.prompt_label.text, "Slip the parcel under the Packard")
	await press_e()
	assert_eq(main.rackets.cafe.stage, CafeJob.Stage.PLANTED)
	assert_eq(main.rackets.parcels, 0)
	assert_false(main.rackets.cafe.seen, "no copper in sight")
	var due: float = main.rackets.cafe.due(main.rackets.night)
	assert_true(main.moments.has(due), "a moment the night must not skip")
	# across the avenue to the bench, and let the time pass
	var bench: Vector2 = _halloran().cafe_point("bench").pos
	var seats: Array = main._seats_near().filter(func(s: Dictionary) -> bool: return (s.pos as Vector2).distance_to(bench) < 4.0)
	assert_eq(seats.size(), 1, "the bench across the avenue")
	_go(seats[0].stand)
	await wait_physics_frames(2)
	await press_e()
	assert_false(player().seat.is_empty())
	cmd = PlayerCommand.make(Vector2.ZERO, false, true)  # Space held
	for i in 600:
		await wait_physics_frames(1)
		if main.cafe_film != null:
			break
	cmd = PlayerCommand.new()
	assert_not_null(main.cafe_film, "the film begins when it is due")
	assert_lt(main.clock.minute, due + 1.0, "the night slowed for it: nothing skipped")
	assert_false(main.hud.visible, "the bars and the captions, no HUD")
	assert_eq(main.camera.target, main.cafe_film.rig, "the camera leaves Danny")
	for i in 60 * 6:
		await wait_physics_frames(1)
	assert_eq(main.rackets.cafe.stage, CafeJob.Stage.DONE, "it went off")
	assert_true(main.cafe_scene.burning)
	assert_true(main.cafe_scene._wreck.visible)
	assert_false(main.cafe_scene._packard.visible)
	assert_true(main.cafe_scene._scorch.visible)
	main.cafe_film.skip()
	for i in 90:
		await wait_physics_frames(1)
	assert_null(main.cafe_film, "and back to Danny")
	assert_true(main.hud.visible)
	assert_eq(main.camera.target, player().body())
	assert_eq(main.cafe_scene.people.size(), 4, "the café's people out on the pavement")
	assert_eq(walker().condition.total(), 0, "watched from a safe distance")
	var cop: PoliceOfficer = main.police.officers().filter(func(o: PoliceOfficer) -> bool: return main.world.district_at(o.body.global_position) == "halloran")[0]
	assert_false(cop.duty.is_empty(), "the square's copper comes to look at it")
	assert_false(cop.brain.is_hunting(), "but nobody knows it was Danny")
	assert_true(main.rackets.rumours.items.any(func(x: Dictionary) -> bool: return x.kind == "cafe_blast"))
	# Rourke pays, once
	var before: int = main.rackets.money
	await talk_to("copper_owl", "rourke")
	await answer_with("cafe_report")
	assert_eq(main.rackets.money, before + CafeJob.REWARD)
	await press_e()
	await talk_to("copper_owl", "rourke")
	assert_false(main._page.options.any(func(o: Dictionary) -> bool: return String(o.id).begins_with("cafe")), "paid once")
	await press_e()
	# the next night: the wreck still at the kerb, no new Packard, no new job
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	main.clock.set_time(23 * 60.0)
	main._update_clock(0.0)
	assert_true(main.cafe_scene._wreck.visible, "the wreck stays")
	assert_false(main.cafe_scene._packard.visible)
	assert_false(main.cafe_scene.burning, "burnt out")


func test_too_close_is_hurt() -> void:
	await _take_the_job()
	await _at_the_car()
	await press_e()
	main.clock.set_time(main.rackets.cafe.due(main.rackets.night) - 0.05)
	for i in 30:
		await wait_physics_frames(1)
		if main.cafe_film != null:
			break
	assert_not_null(main.cafe_film)
	main.cafe_film.skip()
	await wait_physics_frames(3)
	assert_true(main.rackets.cafe.caught_in_it, "standing at the car when it went")
	assert_gt(walker().condition.total(), 0, "hurt")


func test_seen_at_the_car_by_a_copper() -> void:
	await _take_the_job()
	await _at_the_car()
	var cop: PoliceOfficer = main.police.officers().filter(func(o: PoliceOfficer) -> bool: return main.world.district_at(o.body.global_position) == "halloran")[0]
	cop.body.place(walker().global_position + Vector2(150, 0), PI)  # along the pavement, in plain sight
	await wait_physics_frames(2)
	await press_e()
	assert_true(main.rackets.cafe.seen, "the copper saw him at the car")
	_go(walker().global_position + Vector2(0, -2000))
	main.clock.set_time(main.rackets.cafe.due(main.rackets.night) + 0.1)
	await wait_physics_frames(3)
	assert_null(main.cafe_film, "too far off to watch it")
	assert_eq(main.rackets.cafe.stage, CafeJob.Stage.DONE, "it went off all the same")
	assert_true(main.rackets.rumours.items.any(func(x: Dictionary) -> bool: return x.kind == "cafe_seen"), "and the copper talks")
	assert_true(cop.brain.is_hunting(), "and he is after Danny")
