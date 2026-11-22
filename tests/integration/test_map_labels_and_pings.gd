extends "res://tests/support/city_test.gd"
## M010 the city map names everything, by zoom: districts and landmarks from
## far out, businesses and streets nearer, every building's name or address
## close up - never one label on another. The minimap points out what Danny
## can notice of the city's incidents: a ring that spreads once where one is
## (in range), an arrow on the rim while one goes on out of range in this
## district, nothing for another district or a handoff he cannot see.


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func _skip(minutes: float) -> void:
	var end: float = main.clock.minute + minutes
	while main.clock.minute < end:
		main.clock.set_time(minf(main.clock.minute + 2.0, end))
		main.incident_director.advance()
		await wait_physics_frames(1)


func _go(p: Vector2) -> void:
	walker().place(p, 0.0)
	main.camera.snap_to(walker())


func test_labels_by_zoom() -> void:
	_go(Vector2(2300, 600))
	await wait_physics_frames(2)
	main._unhandled_input(_key(CityInput.MAP))
	var m: CityMap = main.hud.city_map
	assert_true(m.visible)
	assert_gt(m.building_labels.size(), 150, "every building of every district has its label")
	# far out: no building labels
	m.scale_px = 14.0
	m.centre = Vector2(2300, 600)
	m.queue_redraw()
	await wait_process_frames(2)
	assert_eq(m.drawn_labels.size(), 0, "zoomed out: districts and landmarks only")
	# close: names and addresses, none on another
	m.scale_px = 2.5
	m.queue_redraw()
	await wait_process_frames(2)
	assert_gt(m.drawn_labels.size(), 6, "close up: the buildings by name and address")
	for i in m.drawn_labels.size():
		for j in range(i + 1, m.drawn_labels.size()):
			assert_false(m.drawn_labels[i].intersects(m.drawn_labels[j]), "no label on another")
		assert_true(m.map_rect.encloses(m.drawn_labels[i]), "inside the map")
	main._unhandled_input(_key(CityInput.MAP))


func test_a_ping_where_an_argument_is_heard() -> void:
	_go(Vector2(1000, 1500))
	main.incidents.plan = [{"id": "p", "kind": "argument", "spot": "owl_kerb", "at": main.clock.minute + 1.0, "tries": 0}]
	await _skip(16.0)  # heated by now, with nobody near
	assert_true(main.hud.minimap.pings.is_empty(), "not noticed from across the ward")
	_go(Vector2(2120, 1030))  # 550 px off, on the minimap: the shouting carries
	await wait_physics_frames(3)
	assert_eq(main.hud.minimap.pings.size(), 1, "a ring where it is")
	for i in 60 * 3:
		await wait_physics_frames(1)
	assert_true(main.hud.minimap.pings.is_empty(), "and it fades: no lasting marker")
	assert_true(main.hud.minimap.arrows.is_empty(), "in range: no arrow")
	# he walks off: an arrow on the rim while it goes on
	_go(Vector2(2120, 2200))
	await wait_physics_frames(3)
	assert_eq(main.hud.minimap.arrows.size(), 1, "an arrow towards it")
	await _skip(20.0)
	await wait_physics_frames(2)
	assert_true(main.hud.minimap.arrows.is_empty(), "gone when it is over")


func test_no_ping_for_a_handoff_out_of_sight_or_another_district() -> void:
	_go(Vector2(2700, 700))  # 365 px from the alley behind the Hotel Marlowe
	main.incidents.plan = [{"id": "h", "kind": "exchange", "spot": "hotel_alley", "at": main.clock.minute + 1.0, "tries": 0}]
	_go(Vector2(1000, 1500))
	await _skip(14.0)
	_go(Vector2(2700, 700))
	await wait_physics_frames(3)
	assert_true(main.hud.minimap.pings.is_empty(), "a quiet handoff is not given away")
	assert_true(main.hud.minimap.arrows.is_empty())
	# in another district: nothing, however loud
	main.incidents.plan = [{"id": "y", "kind": "argument", "spot": "depot_kerb", "at": main.clock.minute + 1.0, "tries": 0}]
	await _skip(16.0)
	await wait_physics_frames(3)
	assert_false(main.incident_director.noticed.has("y"), "the yards' trouble is not shown from the ward")
