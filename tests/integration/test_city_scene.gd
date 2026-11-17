extends "res://tests/support/city_test.gd"
## The game starts in the Riverside Ward at night, on foot, at home (M003)
## next door to the Copper Owl;
## the district is built from its layout (buildings solid, lamps lit, cars
## parked) and draws raised things in perspective round the camera.


func test_the_project_launches_into_the_city() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://src/main/main.tscn")
	assert_eq(ProjectSettings.get_setting("application/config/name"), "Chicago, 1932")


func test_starts_on_foot_at_home_off_marlowe_avenue_at_night() -> void:
	assert_true(player().on_foot())
	assert_true(walker().global_position.distance_to(main.layout.spawn) < 4.0)
	assert_eq(main.interiors.current.id, "home", "in his flat")
	var door: Vector2 = main.interiors.current.outside_door(0)
	assert_eq(main.layout.place_name(door), "Marlowe Avenue", "the door opens onto Marlowe Avenue")
	var tint: CanvasModulate = main.city.atmosphere.tint
	assert_lt(tint.color.get_luminance(), 0.45, "night")
	assert_true(main.camera.is_current())
	assert_eq(main.camera.target, walker())


func test_the_district_is_built_from_its_layout() -> void:
	var layout: DistrictLayout = main.layout
	assert_eq(main.city.buildings.size(), layout.buildings.size())
	assert_gte(main.city.solids.get_child_count(), layout.buildings.size() + layout.lamps.size())
	assert_eq(main.city.lamp_lights.size(), layout.lamps.size())
	assert_eq(main.cars.size(), layout.cars.size())
	assert_not_null(car_of_type("sedan"))
	assert_not_null(car_of_type("coupe"))
	for c in main.cars:
		assert_false(c.driven, "every car starts parked")


func test_buildings_away_from_the_centre_show_their_facades() -> void:
	main.city.update_view(Vector2(1650, 600), 900.0, Rect2(1000, 200, 1300, 800))
	var shown := 0
	for b in main.city.buildings:
		if not b.get_child(0).visible:
			continue
		var faces: Array = b.visible_faces()
		for f in faces:
			assert_gt(f.n.dot(Vector2(1650, 600) - (f.a + f.b) * 0.5), 0.0, "only walls that face the camera")
		shown += faces.size()
	assert_gt(shown, 10, "the crossing is lined with visible facades")


func test_far_buildings_are_not_drawn() -> void:
	main.city.update_view(Vector2(0, 0), 900.0, Rect2(-600, -400, 1200, 800))
	var hidden := 0
	for b in main.city.buildings:
		if not b.get_child(0).visible:
			hidden += 1
	assert_gt(hidden, main.city.buildings.size() / 2, "only what is near the view is redrawn")


func test_a_prompt_offers_the_nearby_car() -> void:
	await at_the_streetcar_stop()
	var c := roadster()
	await walk_to(c.global_position + Vector2(0, 40), 3.0)
	assert_eq(player().enterable_car(), c)
	await wait_process_frames(2)
	assert_true(main.hud.prompt.visible)
	assert_string_contains(main.hud.prompt_label.text, "Roadster")


func test_pause_stops_the_world_and_resumes() -> void:
	var e := InputEventAction.new()
	e.action = CityInput.MENU
	e.pressed = true
	main._unhandled_input(e)
	assert_true(get_tree().paused)
	var at := walker().global_position
	cmd = PlayerCommand.make(Vector2.RIGHT)
	await wait_physics_frames(10)
	assert_eq(walker().global_position, at, "nothing moves while paused")
	main._unhandled_input(e)
	assert_false(get_tree().paused)
	await wait_physics_frames(10)
	assert_gt(walker().global_position.x, at.x)


func test_the_gangster_faces_the_mouse_while_walking_elsewhere() -> void:
	var w := walker()
	var aim := w.global_position + Vector2(0, -200)  # up the screen
	for i in 20:
		cmd = PlayerCommand.make(Vector2.RIGHT, false, false, aim)
		await wait_physics_frames(1)
	cmd = PlayerCommand.new()
	assert_gt(w.velocity.x, 50.0, "walking right")
	assert_almost_eq(w.sprite.rotation, (aim - w.global_position).angle(), 0.15, "while facing the aim point")
	assert_true(main.hud.crosshair.visible, "the reticle shows on foot")
