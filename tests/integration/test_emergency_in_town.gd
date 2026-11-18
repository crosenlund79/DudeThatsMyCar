extends "res://tests/support/city_test.gd"
## M010 the emergency in the game: after the blast at Rosie's the police car,
## the fire engine and the ambulance drive in along Marlowe Avenue one after
## the other, their lamps winking, and stop at the kerb near the wreck; their
## crews get out and stand round it; the firemen put the fire out; the
## vehicles are solid but nobody's to take; by the next night they have gone.


func _blast() -> void:
	main.rackets.money = 2000
	main.rackets.take_cafe_job()
	main.rackets.buy_parcel()
	var h: DistrictLayout = main.world.layouts.halloran
	walker().place(h.cafe_point("bench").pos + Vector2(0, 28), PI)
	main.camera.snap_to(walker())
	main.world.load_now("halloran")
	main.clock.set_time(22 * 60.0 + 30.0)
	await wait_physics_frames(3)
	assert_true(main.rackets.plant_parcel(main.clock.minute, false))
	main.clock.set_time(main.rackets.cafe.due(main.rackets.night) - 0.02)
	for i in 30:
		await wait_physics_frames(1)
		if main.cafe_film != null:
			break
	main.cafe_film.skip()
	await wait_physics_frames(3)


func test_they_come_and_stay() -> void:
	await _blast()
	assert_true(main.emergency.active(main.rackets.night), "sent for")
	var f0 := Engine.get_physics_frames()
	while Engine.get_physics_frames() - f0 < 60 * 30:
		await wait_physics_frames(1)
		if main.emergency.units.all(func(u: Dictionary) -> bool: return u.state == "stopped"):
			break
	var h: DistrictLayout = main.world.layouts.halloran
	for id in ["police", "fire", "ambulance"]:
		var u: Dictionary = main.emergency.unit(id)
		assert_eq(u.state, "stopped", "%s got there" % id)
	var views: EmergencyViews = main.emergency_views
	assert_eq(views.bodies.size(), 3)
	for i in 3:
		var stop: Vector2 = h.cafe_point("stop_" + String(main.emergency.units[i].id)).pos
		assert_lt(views.bodies[i].global_position.distance_to(stop), 1.0, "at its place at the kerb")
		assert_true(views.bodies[i].visible)
		assert_false((views.bodies[i].get_child(0) as CollisionShape2D).disabled, "solid: people go round it")
	assert_eq(views.crews.size(), 7, "two coppers, three firemen, two ambulance men")
	# the firemen put it out a while after the engine stops
	while Engine.get_physics_frames() - f0 < 60 * 45 and main.cafe_scene.burning:
		await wait_physics_frames(1)
	assert_false(main.cafe_scene.burning, "the fire is out")
	assert_true(main.cafe_scene.smouldering, "smoke for the rest of the night")
	# nobody's to take: E by the fire engine does not get Danny in
	walker().place(views.bodies[1].global_position + Vector2(0, -40), PI / 2)
	await wait_physics_frames(3)
	assert_null(player().enterable_car(), "not a car he can take")
	assert_false(main.hud.prompt_label.text.contains("Take"))
	# the next night they have gone
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	assert_false(main.emergency.active(main.rackets.night))
	assert_eq(views.bodies.size(), 0)
	assert_eq(views.crews.size(), 0)
