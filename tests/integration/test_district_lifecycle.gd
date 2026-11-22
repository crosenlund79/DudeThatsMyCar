extends "res://tests/support/city_test.gd"
## M014: a district's content as one lifecycle - built (its street life, beat
## cop, parked cars, rooms, plates and contacts registered with their owners),
## let go (each owner forgets it, its nodes freed, nothing left pointing at
## them), built again (registered once more, nothing duplicated). The ward is
## the first district like the others, and stays.


func _yards_door() -> Vector2:
	var yards: DistrictLayout = main.world.layouts.yards
	for p in yards.interiors:
		if (p as InteriorPlan).id == "dispatch_office":
			return (p as InteriorPlan).outside_door(0, 60.0)
	return Vector2.INF


func _go_yards() -> void:
	walker().place(_yards_door(), PI / 2)
	main.camera.snap_to(walker())
	main.world.load_now("yards")
	await wait_physics_frames(3)


func _let_yards_go() -> void:
	at_the_streetcar_stop()
	await wait_physics_frames(2)
	main.world.enabled = false  # (held still while the district is checked)
	main.world.unload("yards")
	for i in 240:
		await wait_physics_frames(1)
		if not main.world.is_freeing():
			break
	await wait_physics_frames(2)


func _cars_of(d: String) -> Array:
	return main.fleet.ids.filter(func(id: String) -> bool: return id.begins_with(d + "/"))


func test_built_let_go_and_built_again() -> void:
	var g: Game = main.game
	assert_eq(main.districts.streets().size(), 1, "the ward's street life")
	assert_eq(main.police.officers().size(), 1, "the ward's beat cop")
	var ward_cars := _cars_of("riverside").size()
	assert_eq(ward_cars, main.layout.cars.size(), "the ward's cars, made like any district's")
	# built
	await _go_yards()
	assert_true(main.world.is_ready("yards"))
	assert_eq(main.districts.streets().size(), 2)
	var cop: PoliceOfficer = main.police.district_officer("yards")
	assert_not_null(cop, "its beat cop registered")
	assert_eq(main.police.officers().size(), 2)
	assert_eq(main.police.officer_of("yards"), cop)
	var yards_cars := _cars_of("yards").size()
	assert_eq(yards_cars, (main.world.layouts.yards as DistrictLayout).cars.size(), "its parked cars, once")
	assert_not_null(main.interiors.view_of("dispatch_office"), "its rooms")
	assert_not_null(g.errands.views.contact("dutch"), "its contacts (the errands' job)")
	var cars_total: int = main.fleet.cars.size()
	# let go
	await _let_yards_go()
	assert_false(main.world.is_ready("yards"))
	assert_null(main.police.district_officer("yards"), "the beat cop forgotten")
	assert_eq(main.police.officers().size(), 1)
	assert_null(main.police.officer_of("yards"))
	assert_true(main.police.can_stop("yards"), "an unbuilt district's man is free in the abstract")
	assert_eq(main.districts.streets().size(), 1, "its street life gone")
	assert_false(is_instance_valid(cop), "its nodes freed")
	assert_null(main.interiors.view_of("dispatch_office"), "its rooms gone")
	assert_null(g.errands.views.contact("dutch"), "its contacts gone")
	for i in main.fleet.cars.size():
		if String(main.fleet.ids[i]).begins_with("yards/"):
			assert_true(main.fleet.cars[i].has_meta("away"), "its cars put away, not freed")
	assert_eq(main.fleet.cars.size(), cars_total)
	# built again
	main.world.enabled = true
	await _go_yards()
	assert_not_null(main.police.district_officer("yards"), "a beat cop again")
	assert_eq(main.police.officers().size(), 2, "one, not two")
	assert_eq(main.districts.streets().size(), 2)
	assert_eq(main.fleet.cars.size(), cars_total, "no car made twice")
	assert_eq(_cars_of("yards").size(), yards_cars)
	for i in main.fleet.cars.size():
		if String(main.fleet.ids[i]).begins_with("yards/"):
			assert_false(main.fleet.cars[i].has_meta("away"), "its cars back out")
	assert_not_null(main.interiors.view_of("dispatch_office"))
	assert_not_null(g.errands.views.contact("dutch"))


func test_a_shot_after_a_district_went_reaches_only_the_living() -> void:
	await _go_yards()
	var cop: PoliceOfficer = main.police.district_officer("yards")
	await _let_yards_go()
	assert_false(is_instance_valid(cop))
	# everything that reaches every beat cop or every street still works
	main.police.hear_gunshot(walker().global_position, 500.0)
	main.police.player_fired(walker().global_position, Vector2.RIGHT)
	for s in main.districts.streets():
		s.hear_gunshot(walker().global_position)
	assert_eq(main.police.officers().size(), 1)
	assert_true(main.police.officers().all(func(o: PoliceOfficer) -> bool: return is_instance_valid(o)))
