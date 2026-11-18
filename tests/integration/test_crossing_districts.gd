extends "res://tests/support/city_test.gd"
## M008 the Riverfront Yards in the game: not built at the start; built ahead
## of Danny as he drives south down Kessler Street and there, complete, before
## he reaches the border; driven into without a stop or a jump; walked into
## too; with its own beat cop, cars and name on the HUD; freed when he is far
## away and built again - with no car twice - when he comes back. Until it is
## ready, a frontier closes the way.


func yards_ready() -> bool:
	return main.world.is_ready("yards")


func _danny_car() -> Car:
	return main.cars[7]


## Drives `c` south down Kessler Street from `from_y` to `to_y` with the
## normal controls; returns the largest step the car made in one frame.
func _drive_south(c: Car, from_y: float, to_y: float) -> Dictionary:
	await park(c, Vector2(1650 + 28, from_y), PI / 2)
	await seat_in(c)
	var worst_step := 0.0
	var ready_at := INF
	var last := c.global_position
	for i in 60 * 20:
		cmd = PlayerCommand.make(Vector2(0, -1))  # W
		await wait_physics_frames(1)
		worst_step = maxf(worst_step, c.global_position.distance_to(last))
		last = c.global_position
		if ready_at == INF and yards_ready():
			ready_at = c.global_position.y
		if c.global_position.y > to_y:
			break
	cmd = PlayerCommand.new()
	return {"worst_step": worst_step, "ready_at": ready_at, "y": c.global_position.y}


func test_the_yards_are_not_built_at_the_start() -> void:
	assert_false(yards_ready(), "Danny wakes at home: only the ward is built")
	assert_eq(main.world.ready_ids(), ["riverside"] as Array[String])
	assert_eq(main.cars.size(), 9, "the ward's cars only")
	assert_false(main.camera.limit_bottom > 2700, "the camera stays in the ward")


func test_driving_down_kessler_street_into_the_yards() -> void:
	var out := await _drive_south(_danny_car(), 1250.0, 3200.0)
	assert_true(yards_ready())
	assert_lt(out.ready_at, 2700.0 - 400.0, "built and there before he reached the border")
	assert_gt(out.y, 3200.0, "he drove straight on into the yards")
	assert_lt(out.worst_step, 12.0, "no stop, no jump at the border")
	assert_eq(main.world.current, "yards")
	assert_eq(main.hud.district_label.text, "RIVERFRONT YARDS")
	assert_gte(main.camera.limit_bottom, 5300, "the camera may follow him in")
	assert_lte(main.world.loaded.size(), 2)
	var st: Dictionary = main.world.stats.yards
	gut.p("Riverfront Yards: built in %.1f ms of work over %d frames (worst frame %.1f ms, worst step %.1f ms), %.0f ms from start to finish" % [
		st.work_usec / 1000.0, st.frames, st.worst_frame_usec / 1000.0, st.worst_step_usec / 1000.0, st.last_build_usec / 1000.0])
	assert_lt(st.worst_frame_usec, 20000, "no frame of building takes long")


func test_walking_across_the_border() -> void:
	walker().place(Vector2(1580, 2400), PI / 2)
	await wait_physics_frames(2)
	for i in 600:
		if yards_ready():
			break
		await wait_physics_frames(1)
	assert_true(yards_ready())
	await walk_to(Vector2(1580, 2950), 6.0, 900)
	assert_gt(walker().global_position.y, 2900.0, "on the yards' sidewalk")
	assert_eq(main.world.current, "yards")
	assert_eq(main.hud.place_label.text, "Kessler Street")


func test_until_the_yards_are_built_the_way_is_closed() -> void:
	main.world.enabled = false  # nothing is streamed
	var out := await _drive_south(_danny_car(), 2300.0, 2800.0)
	assert_false(yards_ready())
	assert_lt(out.y, 2700.0, "stopped at the frontier: never off the edge of the world")


func test_its_own_beat_cop_people_and_cars() -> void:
	main.world.load_now("yards")
	assert_eq(main.cars.size(), 11, "the yards' two parked cars join the list")
	var cops: Array[PoliceOfficer] = main.officers()
	assert_eq(cops.size(), 2, "the ward's man and the yards' man")
	var yards_cop: PoliceOfficer = cops[1]
	assert_true(main.world.layouts.yards.play_area.has_point(yards_cop.body.global_position), "on his own beat")
	assert_eq(yards_cop.navigator, main.world.navigator_of("yards"))
	assert_true(main.thefts.owner(10).contains("tannery"), "whose car is whose, there too")


func test_freed_far_away_and_built_again_without_duplicates() -> void:
	var c := _danny_car()
	await _drive_south(c, 1250.0, 3150.0)
	cmd = PlayerCommand.new()
	for i in 20:  # E: he brakes to a stop and gets out
		if player().on_foot():
			break
		await press_e()
		await wait_physics_frames(10)
	assert_true(player().on_foot(), "he leaves the sedan in the yards")
	var parked_at := c.global_position
	# far away, at home: the yards are let go
	walker().place(main.layout.spawn, 0.0)
	for i in 300:
		if not yards_ready():
			break
		await wait_physics_frames(1)
	assert_false(yards_ready(), "let go once he is far away")
	assert_null(main.world.get_node_or_null("District_yards"), "its nodes are freed")
	assert_eq(main.officers().size(), 1)
	assert_false(c.visible, "his sedan is put away with the yards")
	assert_eq(c.global_position, parked_at, "where he left it")
	# back down Kessler: built again, the sedan where he left it, nothing twice
	walker().place(Vector2(1580, 2100), PI / 2)
	for i in 900:
		if yards_ready():
			break
		await wait_physics_frames(1)
	assert_true(yards_ready())
	assert_eq(main.world.stats.yards.builds, 2)
	assert_eq(main.cars.size(), 11, "no car made twice")
	assert_true(c.visible, "his sedan is back")
	assert_eq(c.global_position, parked_at)
	assert_eq(main.officers().size(), 2, "one beat cop, not two")
