extends "res://tests/support/city_test.gd"
## M008 the city map on M (it grew out of the M006 ward map): it opens and
## closes with M (Esc too) and the night waits under it; every district is on
## it in its true place, painted from its plan even when it is not built;
## Danny is where he really is, in any district; the mouse drags it round and
## the wheel zooms it in and out within limits, keeping the point under the
## cursor; R or the button brings it back to Danny; nothing moves while it is
## open. The minimap runs on across a border.


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func cmap() -> CityMap:
	return main.hud.city_map


func _open() -> void:
	main._unhandled_input(_key(CityInput.MAP))
	await wait_process_frames(2)


func _close() -> void:
	main._unhandled_input(_key(CityInput.MAP))


func _button(index: MouseButton, at: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = index
	e.position = at
	e.pressed = pressed
	cmap()._gui_input(e)


func _drag(from: Vector2, by: Vector2) -> void:
	_button(MOUSE_BUTTON_LEFT, from, true)
	var m := InputEventMouseMotion.new()
	m.position = from + by
	m.relative = by
	cmap()._gui_input(m)
	_button(MOUSE_BUTTON_LEFT, from + by, false)


func test_m_opens_and_closes_it() -> void:
	assert_false(cmap().visible)
	await _open()
	assert_true(main.map_open)
	assert_true(cmap().visible)
	assert_true(get_tree().paused, "the night waits")
	_close()
	assert_false(cmap().visible)
	assert_false(get_tree().paused)
	await _open()
	main._unhandled_input(_key(CityInput.MENU))
	assert_false(cmap().visible, "Esc closes it")
	assert_false(main.paused, "and does not open the pause screen")


func test_every_district_in_its_true_place() -> void:
	var m := cmap()
	assert_eq(m.minimap.districts.size(), 3, "the ward and both its neighbours")
	for id in main.world.order:
		var l: DistrictLayout = main.world.layouts[id]
		assert_true(m.city_rect.encloses(l.bounds), "%s on the map" % l.name)
	assert_false(main.world.is_ready("yards"), "painted from the plan, not built")
	await _open()
	var ward: DistrictLayout = main.world.layouts.riverside
	var square: DistrictLayout = main.world.layouts.halloran
	var yards: DistrictLayout = main.world.layouts.yards
	assert_almost_eq(m.to_screen(square.bounds.end).x, m.to_screen(Vector2(ward.bounds.position.x, 0)).x, 0.01,
		"Halloran Square's east edge is the ward's west edge")
	assert_almost_eq(m.to_screen(yards.bounds.position).y, m.to_screen(Vector2(0, ward.bounds.end.y)).y, 0.01,
		"the yards begin where the ward ends")
	assert_eq(m.minimap.colour_at(Vector2(1650, 3400)), Minimap.STREET, "Kessler Street runs on south")
	assert_eq(m.minimap.colour_at(Vector2(-2500, 600)), Minimap.STREET, "Marlowe Avenue runs on west")
	var labels: Array = m.landmarks.map(func(l: Dictionary) -> String: return l.label)
	for n in ["Doyle's Garage", "Hotel Marlowe", "The Morgue", "Great Lakes Tanning Co.", "North Branch Freight",
			"The Bijou", "St. Brendan's Church", "Halloran Park"]:  # M010: the square's middle is a park
		assert_has(labels, n)
	assert_eq(m.minimap.places.size(), 7, "the seven places he can walk into, with their badges (M011: the union hall)")
	_close()


func test_danny_where_he_really_is_in_any_district() -> void:
	await at_the_streetcar_stop()
	await _open()
	var m := cmap()
	assert_eq(m.danny, walker().global_position)
	assert_true(m.map_rect.has_point(m.to_screen(walker().global_position)), "it opens on him")
	assert_eq(m.car, main.fleet.my_car().global_position, "his car where it is")
	assert_has(m.officers, main.officer.body.global_position, "the beat cop where he is")
	_close()
	main.world.load_now("yards")
	walker().place(Vector2(2400, 3200), 0.0)
	await wait_physics_frames(3)
	await _open()
	assert_eq(m.danny, walker().global_position, "in the yards too")
	assert_true(m.map_rect.has_point(m.to_screen(walker().global_position)))
	assert_eq(m.officers.size(), 2, "both beat cops")
	_close()


func test_drag_to_look_round_and_the_wheel_zooms() -> void:
	await _open()
	var m := cmap()
	var mid := m.map_rect.get_center()
	var before := m.centre
	_drag(mid, Vector2(120, -40))
	assert_almost_eq((m.centre - before).x, -120.0 * m.scale_px, 0.01, "dragged right: the map moves with the mouse")
	assert_almost_eq((m.centre - before).y, 40.0 * m.scale_px, 0.01)
	# the wheel zooms about the cursor
	var at := mid + Vector2(150, 80)
	var under := m.to_world(at)
	var scale := m.scale_px
	_button(MOUSE_BUTTON_WHEEL_UP, at, true)
	assert_lt(m.scale_px, scale, "closer")
	assert_true(m.to_world(at).distance_to(under) < 0.5, "the point under the cursor stays put")
	for i in 30:
		_button(MOUSE_BUTTON_WHEEL_UP, at, true)
	assert_almost_eq(m.scale_px, CityMap.ZOOM_IN, 0.001, "no closer than this")
	for i in 40:
		_button(MOUSE_BUTTON_WHEEL_DOWN, at, true)
	assert_almost_eq(m.scale_px, m.zoom_out_limit, 0.001, "no farther than the whole city")
	assert_true(m.world.grow(m.scale_px * 2.0).encloses(m.city_rect) or m.world.size.x >= m.city_rect.size.x,
		"at the farthest the whole city fits")
	# dragging cannot lose the city
	for i in 30:
		_drag(mid, Vector2(400, 400))
	assert_true(m.city_rect.has_point(m.centre), "the middle of the map stays over the city")
	_close()


func test_back_to_danny_with_r_or_the_button() -> void:
	await _open()
	var m := cmap()
	var home := m.centre  # it opens on him (as near as the city's edge allows)
	assert_true(m.map_rect.has_point(m.to_screen(m.danny)))
	_drag(m.map_rect.get_center(), Vector2(300, 200))
	assert_ne(m.centre, home)
	main._unhandled_input(_key(CityInput.RECENTRE))
	assert_eq(m.centre, home, "R: back to Danny")
	assert_true(m.map_rect.has_point(m.to_screen(m.danny)))
	_drag(m.map_rect.get_center(), Vector2(-300, 100))
	m.queue_redraw()
	await wait_process_frames(2)
	assert_true(m.recentre_rect.has_area(), "the button in the key")
	_button(MOUSE_BUTTON_LEFT, m.recentre_rect.get_center(), true)
	assert_eq(m.centre, home, "the button: back to Danny")
	_close()


func test_a_neighbouring_district_looked_at_without_going_there() -> void:
	await at_the_streetcar_stop()
	await _open()
	var m := cmap()
	var yards: DistrictLayout = main.world.layouts.yards
	for i in 20:
		if m.world.intersects(yards.play_area.grow(-400.0)):
			break
		_drag(m.map_rect.get_center(), Vector2(0, -200))
	assert_true(m.world.intersects(yards.play_area), "the yards in view")
	assert_false(main.world.is_ready("yards"), "Danny has not moved; nothing was built")
	assert_eq(walker().global_position, Vector2(2350, 600))
	_close()


func test_nothing_moves_while_it_is_open() -> void:
	await at_the_streetcar_stop()
	await _open()
	var at := walker().global_position
	var rounds: int = walker().gun.ammo
	cmd = PlayerCommand.make(Vector2.RIGHT, false, false, at + Vector2(100, 0))
	_fire_pending = true
	await wait_physics_frames(30)
	assert_eq(walker().global_position, at, "no walking")
	assert_eq(walker().gun.ammo, rounds, "no shooting")
	_close()
	cmd = PlayerCommand.new()
	_fire_pending = false


func test_not_while_talking() -> void:
	await talk_to("copper_owl", "augie")
	main._unhandled_input(_key(CityInput.MAP))
	assert_false(main.map_open, "finish the talk first")


func test_the_minimap_runs_on_across_the_border() -> void:
	main.world.load_now("yards")
	walker().place(Vector2(1600, 2680), PI / 2)  # on the border, Kessler Street
	await wait_physics_frames(3)
	var mm: Minimap = main.hud.minimap
	assert_eq(mm.colour_at(Vector2(1650, 2600)), Minimap.STREET, "the ward's end of Kessler Street")
	assert_eq(mm.colour_at(Vector2(1650, 2800)), Minimap.STREET, "and the yards' end")
	assert_eq(mm.colour_at(Vector2(500, 2785)), Minimap.STREET, "Front Street")
	walker().place(Vector2(3300, 2900), 0.0)  # by the yards' beat cop
	await wait_physics_frames(3)
	assert_eq(mm.other_police.size(), 1, "the yards' beat cop on the minimap")
