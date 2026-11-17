extends "res://tests/support/city_test.gd"
## The first police officer in the Riverside Ward: he is visible on his beat,
## ignores gunfire he cannot hear, reacts to nearby shots (whistle, "!",
## HUD line), chases you through the streets round the buildings, loses you
## when you get away (on foot out of sight, or in a car), searches, gives up
## and goes back to his beat.

const SIM_LIMIT := 60 * 40  # ticks


func cop() -> PoliceOfficer:
	return main.officer


func cop_pos() -> Vector2:
	return cop().body.global_position


func _until(cond: Callable, max_ticks: int = SIM_LIMIT) -> int:
	for t in max_ticks:
		if cond.call():
			return t
		await wait_physics_frames(1)
	return max_ticks


func _alert_from(spot: Vector2) -> void:
	walker().place(spot, 0.0)
	await wait_physics_frames(1)
	await click(spot + Vector2(0, -150))
	await aim_for(spot + Vector2(0, -150), 20)


func test_he_is_on_his_beat_and_in_view_at_the_start() -> void:
	var beat: PackedVector2Array = main.layout.police_beat
	assert_eq(cop().brain.state, OfficerBrain.State.PATROL)
	assert_true(main.camera.view_rect().has_point(cop_pos()), "you can see him from the streetcar stop")
	var start := cop_pos()
	await wait_physics_frames(240)
	assert_gt(cop_pos().distance_to(start), 20.0, "he walks his round")
	assert_between(cop_pos().x, beat[0].x - 10.0, beat[1].x + 10.0)
	assert_false(cop().icon.visible, "nothing over his cap while all is quiet")


func test_shots_out_of_earshot_are_ignored() -> void:
	await _alert_from(Vector2(800, 1500))  # Pruitt Street, far away
	await wait_physics_frames(30)
	assert_eq(cop().brain.state, OfficerBrain.State.PATROL)


func test_nearby_shots_bring_whistle_badge_and_a_chase() -> void:
	watch_signals(cop())
	await _alert_from(Vector2(2300, 600))
	assert_signal_emitted(cop(), "noticed_player")
	assert_true(cop().brain.is_hunting())
	assert_true(cop().icon.visible, "the '!' over his cap")
	assert_true(main.hud.police_panel.visible)
	assert_string_contains(main.hud.police_label.text, "COPPER")
	var d0 := cop_pos().distance_to(walker().global_position)
	var t := await _until(func() -> bool: return cop_pos().distance_to(walker().global_position) <= cop().rules.close_distance + 12.0, 60 * 15)
	assert_lt(t, 60 * 15, "he runs you down (from %d px)" % int(d0))
	assert_eq(cop().brain.state, OfficerBrain.State.CHASE)


func test_he_goes_round_the_block_to_the_alley_behind_the_club() -> void:
	# a shot in the back alley behind the Copper Owl: he has to go round by Kessler Street
	var spot := Vector2(2380, 135)
	await _alert_from(spot)
	assert_true(cop().brain.is_hunting())
	var inside := false
	var t := 0
	while t < 60 * 20:
		if main.layout.is_in_building(cop_pos(), -2.0):
			inside = true
		if cop_pos().distance_to(walker().global_position) <= 70.0:
			break
		await wait_physics_frames(1)
		t += 1
	assert_false(inside, "never through a building")
	assert_lt(t, 60 * 20, "reached the alley behind the club")


func test_out_of_sight_he_only_knows_the_last_place_he_saw_you() -> void:
	await _alert_from(Vector2(2300, 600))
	await wait_physics_frames(60)
	var hideout := Vector2(600, 1250)  # behind the buildings south of Marlowe
	walker().place(hideout, 0.0)
	await wait_physics_frames(5)
	assert_false(cop().can_see(hideout))
	assert_gt(cop().brain.last_known.distance_to(hideout), 400.0, "no magic knowledge of where you went")


func test_a_getaway_in_the_roadster_ends_the_pursuit() -> void:
	watch_signals(cop())
	await _alert_from(Vector2(2380, 640))
	await wait_physics_frames(60)
	assert_true(cop().brain.is_hunting())
	var c := roadster()
	await walk_to(c.global_position + Vector2(0, -36), 4.0)
	await press_e()
	assert_false(player().on_foot(), "in the car with the copper behind")
	# away east down Marlowe Avenue and round into Wharf Street
	await drive_route(c, [Vector2(2900, 650), Vector2(3200, 680), Vector2(3300, 900), Vector2(3300, 1300)], 260.0, 60 * 12)
	var t := await _until(func() -> bool: return cop().brain.state == OfficerBrain.State.RETURN or cop().brain.state == OfficerBrain.State.PATROL)
	assert_lt(t, SIM_LIMIT, "he gave up")
	assert_signal_emitted(cop(), "gave_up")
	assert_false(main.hud.police_panel.visible, "the pursuit line is gone")
	t = await _until(func() -> bool: return cop().brain.state == OfficerBrain.State.PATROL)
	assert_lt(t, SIM_LIMIT, "and walked back to his beat")
	assert_false(cop().icon.visible)


func test_slipping_away_on_foot_out_of_sight_ends_it_too() -> void:
	watch_signals(cop())
	await _alert_from(Vector2(2300, 600))
	await wait_physics_frames(60)
	walker().place(Vector2(600, 1250), 0.0)  # gone round the back
	var t := await _until(func() -> bool: return cop().brain.state == OfficerBrain.State.RETURN)
	assert_lt(t, SIM_LIMIT)
	assert_signal_emitted(cop(), "gave_up")
