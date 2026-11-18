extends "res://tests/support/city_test.gd"
## M010 in the game: Left Shift with WASD runs (the steps keep pace with the
## ground), letting go walks again; Shift does nothing at the wheel or in a
## talk. Towards dawn Danny's view grows heavy - the vignette, the drift -
## less at the wheel, kept out of the way of a talk, gone after sleeping.


func _run_cmd(move: Vector2, sprint: bool) -> void:
	cmd = PlayerCommand.make(move)
	cmd.sprint = sprint


func test_shift_runs_and_letting_go_walks() -> void:
	walker().place(Vector2(1200, 600), 0.0)
	_run_cmd(Vector2.RIGHT, false)
	await wait_physics_frames(30)
	var a := walker().global_position
	await wait_physics_frames(60)
	var walked := walker().global_position.distance_to(a)
	_run_cmd(Vector2.RIGHT, true)
	await wait_physics_frames(30)
	a = walker().global_position
	await wait_physics_frames(60)
	var ran := walker().global_position.distance_to(a)
	assert_gt(ran, walked * 1.6, "running (%.0f against %.0f px)" % [ran, walked])
	assert_true(walker().model.running)
	_run_cmd(Vector2.RIGHT, false)
	await wait_physics_frames(30)
	a = walker().global_position
	await wait_physics_frames(60)
	assert_almost_eq(walker().global_position.distance_to(a), walked, walked * 0.1, "walking again")
	assert_false(walker().model.running)
	cmd = PlayerCommand.new()


func test_shift_does_nothing_at_the_wheel() -> void:
	var c: Car = main.my_car()
	var start := Transform2D(PI, Vector2(1500, 640))
	await seat_in(c)
	var speeds := []
	for shift in [true, false]:
		cmd = PlayerCommand.new()
		await park(c, start.origin, start.get_rotation())
		await wait_physics_frames(60)  # the engine settles
		await park(c, start.origin, start.get_rotation())
		_run_cmd(Vector2(0, -1), shift)
		await wait_physics_frames(60)
		speeds.append(c.model.forward_speed())
		assert_false(c.handbrake, "Shift is not the handbrake")
	assert_almost_eq(speeds[0], speeds[1], 1.0, "the same car, the same pedal, Shift or not")
	cmd = PlayerCommand.new()


func test_heavy_eyes_towards_dawn() -> void:
	walker().place(Vector2(2350, 600), 0.0)
	await wait_physics_frames(5)
	assert_false(main.drowsy.rect.visible, "fresh at dusk")
	assert_eq(main.camera.offset, Vector2.ZERO)
	main.clock.set_time(float(main.night_rules.dawn_minute) - 10.0)
	var sway_foot := 0.0
	for i in 240:
		await wait_physics_frames(1)
		sway_foot = maxf(sway_foot, main.camera.offset.length())
	assert_true(main.drowsy.rect.visible, "the vignette closes in")
	assert_gt(main.drowsy.effect, 0.8)
	assert_gt(sway_foot, 3.0, "the view drifts")
	assert_lt(sway_foot, DrowsyView.SWAY_FOOT * 1.5, "but only a little")
	assert_gt(main.drowsy.layer, 3)
	assert_lt(main.drowsy.layer, main.hud.layer, "the HUD stays clear")
	# at the wheel: much steadier
	await seat_in(main.my_car())
	var sway_car := 0.0
	for i in 240:
		await wait_physics_frames(1)
		sway_car = maxf(sway_car, main.camera.offset.length())
	assert_lt(sway_car, sway_foot * 0.5, "steadier at the wheel")
	# talking: out of the way
	for i in 20:
		if player().on_foot():
			break
		await press_e()
	await talk_to("copper_owl", "augie")
	for i in 120:
		await wait_physics_frames(1)
	assert_lt(main.drowsy.effect, 0.05, "eased away for the talk")
	assert_lt(main.camera.offset.length(), 0.5)
	await press_e()
	# a night's sleep
	await talk_to("home", "bed")
	await answer_with("sleep")
	for i in 120:
		await wait_physics_frames(1)
	assert_eq(main.clock.drowsiness(), 0.0)
	assert_false(main.drowsy.rect.visible, "gone after sleeping")
