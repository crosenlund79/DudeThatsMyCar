extends "res://tests/support/city_test.gd"
## M012 rooms in a streamed district, with Alderman Doran's ward office in
## Halloran Square as the case: built with its district and not before, under
## the district's own node; walked into through the door with the normal
## controls, the roof opening and the walls holding; the district never let
## go while Danny is inside; let go with the district and built again exactly
## once; whoever was struck down there stays down tonight, unloaded or not; a
## game saved inside loads inside, at the same minute, and he can walk out.

var _save := ""


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _reload() -> void:
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = callouts  # M012: as in before_each
	main.save_path = _save
	main.settings_path = ""
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(3)


func _doran() -> InteriorPlan:
	return main.interiors.plan_named("doran_office")


func _halloran() -> DistrictLayout:
	return main.world.layouts.halloran


## Halloran Square built and Danny on the pavement outside Doran's door (so
## the streamer keeps it: it lets go of a district he is far from).
func _to_the_square() -> void:
	main.world.load_now("halloran")
	var plan: InteriorPlan = _halloran().interiors.filter(func(x: InteriorPlan) -> bool: return x.id == "doran_office")[0]
	walker().place(plan.outside_door(0, 40.0), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(2)


func test_built_with_its_district_and_not_before() -> void:
	var ward_rooms: int = main.interiors.plans.size()
	assert_null(_doran(), "not built while only the ward is")
	assert_eq(main.interiors.district_ids(), ["riverside"])
	await _to_the_square()
	var p := _doran()
	assert_not_null(p, "built with Halloran Square")
	assert_eq(main.interiors.plans.size(), ward_rooms + _halloran().interiors.size())
	assert_true(_halloran().bounds.encloses(p.room), "in the square's own place in the world")
	assert_true(p.building_rect.encloses(p.room), "inside its own building")
	assert_eq(_halloran().buildings[p.building].name, HalloranSquare.DORAN)
	assert_eq(main.interiors.district_of(p), "halloran")
	var v: InteriorView = main.interiors.view_of("doran_office")
	assert_true(main.world.loaded.halloran.node.is_ancestor_of(v), "under the district's node: it goes with it")
	assert_eq(_halloran().locked_door_at(p.outside_door(0, 10.0), 60.0), {}, "its door is a door now, not a locked one")


func test_walked_into_with_the_normal_controls() -> void:
	await _to_the_square()
	var p := _doran()
	var v: InteriorView = main.interiors.view_of("doran_office")
	assert_eq(v.alpha, 0.0, "from the street it looks as it always did")
	assert_true(await walk_in_to(p, "heeler"), "in at the door off Marlowe Avenue and up to the captain's desk")
	assert_eq(main.interiors.current, p)
	await wait_physics_frames(30)
	assert_eq(v.alpha, 1.0, "the cut-away shows")
	assert_false(v.host.visible, "the roof is off")
	assert_gt(v.lights[0].energy, 0.5, "the lamps are lit")
	assert_eq(main.hud.place_label.text, HalloranSquare.DORAN)
	assert_eq(main.world.current, "halloran")
	# the walls hold
	await hold(Vector2.LEFT, 150)
	assert_gt(walker().global_position.x, p.room.position.x + InteriorPlan.WALL, "the west wall holds")
	# the captain talks; the photographs and the desk are there to look at
	await talk_to("doran_office", "heeler")
	assert_eq(main.talking, "heeler")
	assert_string_contains(main.hud.line_label.text, "alderman")
	await answer_with("bye")
	await talk_to("doran_office", "doran_photos")
	assert_eq(main.talking, "doran_photos")
	assert_string_contains(main.hud.line_label.text, "Doran")
	await answer_with("bye")
	await talk_to("doran_office", "doran_desk")
	assert_string_contains(main.hud.line_label.text, "drawer")
	await answer_with("bye")
	# and out again by the door with E
	walker().place(p.inside_door(0, 14.0), PI / 2)
	await wait_physics_frames(3)
	assert_string_contains(main.hud.prompt_label.text, "Go out")
	await press_e()
	assert_null(main.interiors.current, "back in the street")
	await wait_physics_frames(30)
	assert_eq(v.alpha, 0.0)
	assert_true(v.host.visible, "the building is whole again")


func test_never_let_go_while_he_is_inside() -> void:
	await _to_the_square()
	var p := _doran()
	walker().place(p.inside_door(0, 30.0), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(120)
	assert_true(main.world.is_ready("halloran"), "the district he stands in stays")
	assert_eq(main.interiors.current, p)
	main.world.update(walker().global_position)
	assert_true(main.world.is_ready("halloran"))
	assert_not_null(_doran())


func test_let_go_and_built_again_once_with_who_went_down() -> void:
	var ward_rooms: int = main.interiors.plans.size()
	await _to_the_square()
	var v: InteriorView = main.interiors.view_of("doran_office")
	var heeler: Walker = v.people.heeler
	for i in 30:
		if heeler.down:
			break
		heeler.hit_by_bullet(heeler.global_position + Vector2(0, 4), Vector2.RIGHT, walker())
	assert_true(heeler.down, "the precinct captain is struck down")
	assert_true(main.ward_out.has("doran_office/heeler"), "remembered for tonight")
	# Danny goes home; the square is let go, rooms and all
	walker().place(main.layout.spawn, 0.0)
	main.camera.snap_to(walker())
	await wait_physics_frames(2)
	main.world.unload("halloran")
	await wait_physics_frames(2)
	assert_null(_doran(), "its rooms went with it")
	assert_null(main.interiors.view_of("doran_office"))
	assert_eq(main.interiors.plans.size(), ward_rooms)
	assert_eq(main.interiors.district_ids(), ["riverside"])
	# and built again when he goes back: once, with the captain still down
	await _to_the_square()
	assert_eq(main.interiors.plans.size(), ward_rooms + _halloran().interiors.size(), "no room twice")
	var again: InteriorView = main.interiors.view_of("doran_office")
	assert_ne(again, v, "a new view")
	assert_false(again.person_ok("heeler"), "the captain is not back tonight")
	assert_eq(main.interiors.views.filter(func(x: InteriorView) -> bool: return x.plan.id == "doran_office").size(), 1)
	# a new night: everybody back
	main.sleep()
	await wait_physics_frames(2)
	await _to_the_square()
	assert_true(main.interiors.view_of("doran_office").person_ok("heeler"), "back at his desk the next evening")


func test_saved_inside_loads_inside_and_he_walks_out() -> void:
	_save = OS.get_user_data_dir().path_join("test_streamed_rooms_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	await _to_the_square()
	var p := _doran()
	assert_true(await walk_in_to(p, "doran_desk"), "in the alderman's office")
	var at := walker().global_position
	main.clock.set_time(23 * 60 + 10)
	await _reload()
	assert_true(main.world.is_ready("halloran"), "the square is built at once")
	assert_eq(main.world.current, "halloran")
	assert_lt(walker().global_position.distance_to(at), 2.0, "where he was")
	assert_not_null(main.interiors.current, "inside")
	assert_eq(main.interiors.current.id, "doran_office")
	assert_almost_eq(main.clock.minute, 23.0 * 60.0 + 10.0, 0.6, "at the minute it was saved")
	assert_eq(main.interiors.view_of("doran_office").alpha, 1.0, "the room open at once")
	assert_eq(main.hud.place_label.text, HalloranSquare.DORAN)
	# out with the normal controls; nothing comes loose afterwards
	var plan := _doran()
	for q in path_in_room(plan, walker().global_position, plan.inside_door(0, 14.0), 6.0):
		await walk_to(q, 4.0, 120)
	await walk_to(plan.inside_door(0, 10.0), 4.0, 120)
	await press_e()
	assert_null(main.interiors.current, "out in Marlowe Avenue")
	await hold(Vector2.DOWN, 40)
	await wait_physics_frames(60)
	assert_null(main.interiors.current)
	assert_true(main.world.is_ready("halloran"))
	assert_gt(walker().global_position.y, plan.room.end.y, "on the pavement")


func test_saved_in_the_yards_street_loads_there() -> void:
	_save = OS.get_user_data_dir().path_join("test_streamed_rooms_yards_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	main.world.load_now("yards")
	var l: DistrictLayout = main.world.layouts.yards
	var at: Vector2 = l.police_beat[0] + Vector2(0, 60)
	walker().place(at, 0.0)
	await wait_physics_frames(3)
	await _reload()
	assert_true(main.world.is_ready("yards"))
	assert_lt(walker().global_position.distance_to(at), 2.0, "in the yards where he was")
	assert_null(main.interiors.current)


func test_a_new_night_begins_at_home() -> void:
	_save = OS.get_user_data_dir().path_join("test_streamed_rooms_night_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	await _to_the_square()
	walker().place(_doran().inside_door(0, 30.0), 0.0)
	await wait_physics_frames(3)
	main.save_game()
	main.sleep()
	await _reload()
	assert_eq(walker().global_position, main.layout.spawn, "the next evening starts at home")
	assert_eq(main.world.ready_ids(), ["riverside"] as Array[String])
	assert_almost_eq(main.clock.minute, float(main.clock.rules.start_minute), 0.6, "in the evening")
