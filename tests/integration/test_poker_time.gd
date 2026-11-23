extends "res://tests/support/city_test.gd"
## M015 time at the card table: while Danny sits and plays, the night goes at
## a quarter of its pace (NightCycle.POKER_TIME); while a beat waits for Space
## it stands still; getting up gives the street its own pace back; and the
## game still breaks up at four.


func _key(code: Key, pressed: bool = true) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	main._unhandled_input(e)
	await wait_physics_frames(1)


func _view() -> PokerView:
	return main.hud.poker_view


func _sit_down() -> void:
	main.rackets.money = 5000
	var plan: InteriorPlan = main.interiors.view_of("back_room").plan
	walker().place(plan.spots[0].pos, -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	await press_e()
	_view().think = Vector2(0.3, 0.4)  # (thinking long enough to measure the clock between beats)
	await _key(KEY_1)  # the smallest buy-in
	assert_eq(_view().phase, "play")


## Game minutes the clock moves in a real second (the clock runs on the
## process frames: counted as such, 1/60 s each at the tests' fixed rate).
func _rate_over(frames: int) -> float:
	var before: float = main.clock.minute
	var p0 := Engine.get_process_frames()
	await wait_process_frames(frames)
	return (main.clock.minute - before) / (float(Engine.get_process_frames() - p0) / 60.0)


func test_slow_at_the_table_still_while_a_beat_waits() -> void:
	var normal := await _rate_over(60)
	assert_gt(normal, 0.0)
	await _sit_down()
	assert_true(main.back_rooms.playing_poker())
	# wait for a beat on show (a card player's move, a street)
	for f in 1200:
		if _view().pacing.waiting():
			break
		await wait_physics_frames(1)
	assert_true(_view().pacing.waiting(), "a beat on show")
	assert_almost_eq(await _rate_over(60), 0.0, 0.0001, "the night stands still while the beat waits for Space")
	# play on: Space through the beats, Danny checks or calls; the clock creeps
	var moved := 0.0
	var frames := 0
	for f in 600:
		var before: float = main.clock.minute
		var t: Holdem = main.back_rooms.poker.table
		if _view().pacing.waiting():
			await _key(KEY_SPACE)
			await _key(KEY_SPACE, false)
		elif t.running() and t.to_act == main.back_rooms.poker.danny:
			await _key(KEY_2)
		else:
			var p0 := Engine.get_process_frames()
			await wait_process_frames(1)
			if not _view().pacing.waiting() and _view().phase == "play":
				moved += main.clock.minute - before
				frames += Engine.get_process_frames() - p0
	assert_gt(frames, 10, "some play while nothing waited")
	assert_almost_eq((moved / (frames / 60.0)) / normal, NightCycle.POKER_TIME, 0.03, "a quarter of the street's pace while the hand plays")
	# getting up: the street's pace again
	await _key(KEY_ESCAPE)
	if not _view().confirm.is_empty():
		await _key(KEY_ENTER)
	await wait_physics_frames(3)
	assert_false(main.back_rooms.playing_poker())
	assert_almost_eq(await _rate_over(60), normal, normal * 0.05, "the night's own pace once he is up")


func test_the_game_still_breaks_up_at_four() -> void:
	main.clock.set_time(float(main.night_rules.home_minute) - 1.0)
	await _sit_down()
	main.clock.set_time(float(main.night_rules.home_minute) + 0.5)
	for f in 1200:
		if _view().phase != "play":
			break
		if _view().pacing.waiting():
			await _key(KEY_SPACE)
			await _key(KEY_SPACE, false)
		else:
			var t: Holdem = main.back_rooms.poker.table
			if t.running() and t.to_act == main.back_rooms.poker.danny:
				await _key(KEY_2)
			else:
				await wait_physics_frames(1)
	assert_ne(_view().phase, "play", "the game breaks up at the hour, slow clock or not")
