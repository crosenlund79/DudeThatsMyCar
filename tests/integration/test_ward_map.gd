extends "res://tests/support/city_test.gd"
## M006 the map of the whole ward (M): it opens and closes with M (Esc closes
## it too), shows the whole ward with Danny, the places, his car and the beat
## cop where they really are, and while it is open nothing moves - no walking,
## driving or shooting.


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func wmap() -> WardMap:
	return main.hud.ward_map


func test_m_opens_and_closes_it() -> void:
	assert_false(wmap().visible)
	main._unhandled_input(_key(CityInput.MAP))
	assert_true(main.map_open)
	assert_true(wmap().visible)
	assert_true(get_tree().paused, "the night waits")
	main._unhandled_input(_key(CityInput.MAP))
	assert_false(wmap().visible)
	assert_false(get_tree().paused)
	main._unhandled_input(_key(CityInput.MAP))
	main._unhandled_input(_key(CityInput.MENU))
	assert_false(wmap().visible, "Esc closes it")
	assert_false(main.paused, "and does not open the pause screen")


func test_it_shows_the_whole_ward_where_things_really_are() -> void:
	await at_the_streetcar_stop()
	main._unhandled_input(_key(CityInput.MAP))
	await wait_frames(2)
	var m := wmap()
	assert_true(m.world.encloses(main.layout.play_area), "the whole ward")
	assert_true(Rect2(Vector2.ZERO, m.size).encloses(m.map_rect), "on the screen")
	assert_lt(m.map_rect.end.x, m.size.x - WardMap.KEY_WIDTH, "beside the key, not under it")
	assert_eq(m.danny, walker().global_position, "Danny where he is")
	assert_eq(m.car, main.my_car().global_position, "his car where it is")
	assert_eq(m.police, main.officer.body.global_position, "the beat cop where he is")
	assert_eq(m.minimap.places.size(), 5, "the five places he can walk into")
	var screen := m.to_screen(walker().global_position)
	assert_true(m.map_rect.has_point(screen))
	var labels: Array = m.landmarks.map(func(l: Dictionary) -> String: return l.label)
	assert_has(labels, "Doyle's Garage")
	assert_has(labels, "Hotel Marlowe")
	main._unhandled_input(_key(CityInput.MAP))


func test_nothing_moves_while_it_is_open() -> void:
	await at_the_streetcar_stop()
	main._unhandled_input(_key(CityInput.MAP))
	var at := walker().global_position
	var rounds: int = walker().gun.ammo
	cmd = PlayerCommand.make(Vector2.RIGHT, false, false, at + Vector2(100, 0))
	_fire_pending = true
	await wait_physics_frames(30)
	assert_eq(walker().global_position, at, "no walking")
	assert_eq(walker().gun.ammo, rounds, "no shooting")
	main._unhandled_input(_key(CityInput.MAP))
	cmd = PlayerCommand.new()
	_fire_pending = false


func test_not_while_talking() -> void:
	await talk_to("copper_owl", "augie")
	main._unhandled_input(_key(CityInput.MAP))
	assert_false(main.map_open, "finish the talk first")
