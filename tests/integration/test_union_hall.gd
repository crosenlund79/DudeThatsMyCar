extends "res://tests/support/city_test.gd"
## M011 the Dock & Freight Workers' hall, Local 9, in the game: at the corner
## of Wharf Street and Front Street, on the Riverfront Yards' doorstep; its
## badge over the door; walked into from Wharf Street with the normal
## movement - the roof opens, the HUD names it; the hall (benches, the
## noticeboard, the stove, the men waiting) and through the doorway the
## business agent's office; the desk and the cabinets are solid; the
## noticeboard reads but offers no work and moves no money; out again; on the
## city map by name. Nothing to join, no strikes, no new income.


func _plan() -> InteriorPlan:
	return main.interiors.view_of("union_hall").plan


func test_at_the_yards_doorstep_with_its_badge() -> void:
	var p := _plan()
	var yards: DistrictLayout = main.world.layouts.yards
	var door_out := p.outside_door(0, 20.0)
	assert_lt(SoundscapeMix.rect_distance(yards.bounds, door_out), 200.0, "a few steps from the yards")
	assert_eq(main.layout.streets.filter(func(s: Dictionary) -> bool: return (s.rect as Rect2).grow(50).has_point(door_out))
		.map(func(s: Dictionary) -> String: return s.name), ["Wharf Street"], "its door on Wharf Street")
	assert_false(main.markers.marker_of("union_hall").is_empty(), "a badge over the door")
	assert_eq(p.marker, "ui/marker_union")


func test_walk_in_look_round_and_out() -> void:
	var p := _plan()
	assert_true(await walk_in_to(p, "union_board"), "in from Wharf Street, up to the noticeboard")
	await wait_physics_frames(20)
	assert_eq(main.interiors.current, p)
	var view: InteriorView = main.interiors.view_of("union_hall")
	assert_almost_eq(view.alpha, 1.0, 0.01, "the roof open")
	assert_eq(main.hud.place_label.text, RiversideWard.UNION_HALL)
	for id in ["agent", "docker_a", "docker_b"]:
		assert_true((view.people[id] as Walker).visible)
	for kind in ["desk", "filing_cabinet", "safe", "noticeboard", "wall_map", "charter", "potbelly"]:
		assert_not_null(view.get_node_or_null(kind), "the %s" % kind)
	# the noticeboard: something to read, nothing more
	var money: int = main.rackets.money
	assert_string_contains(main.hud.prompt_label.text, "Read the noticeboard")
	await press_e()
	assert_string_contains(main.hud.line_label.text, "GENERAL MEETING")
	assert_eq(main.talking, "union_board")
	await press_e()  # walk away
	assert_eq(main.talking, "", "done reading")
	assert_eq(main.rackets.money, money, "no money moves")
	# through the doorway into the agent's office, round the desk
	var office := Vector2(2960, 2600)
	var path := path_in_room(p, walker().global_position, office, 8.0)
	assert_false(path.is_empty(), "a way through the doorway")
	for q in path:
		await walk_to(q, 4.0, 120)
	assert_lt(walker().global_position.distance_to(office), 14.0, "in the office")
	assert_lt(walker().global_position.x, 3000.0, "past the partition")
	# the desk is solid
	walker().place(Vector2(2915, 2570), -PI / 2)
	await wait_physics_frames(2)
	await hold(Vector2.UP, 60)
	assert_gt(walker().global_position.y, 2522.0 + 16.0 + Walker.RADIUS - 2.0, "stopped at the desk")
	# and out by the door
	walker().place(p.inside_door(0, 12.0), 0.0)
	await wait_physics_frames(3)
	assert_string_contains(main.hud.prompt_label.text, "Go out")
	await press_e()
	await wait_physics_frames(3)
	assert_null(main.interiors.current, "back on Wharf Street")


func test_on_the_city_map_by_name() -> void:
	var m := InputEventAction.new()
	m.action = CityInput.MAP
	m.pressed = true
	main._unhandled_input(m)
	assert_true(main.hud.city_map.building_labels.any(func(l: Dictionary) -> bool: return String(l.label) == RiversideWard.UNION_HALL),
		"named on the city map")
	main._unhandled_input(m)
