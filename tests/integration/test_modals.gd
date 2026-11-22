extends "res://tests/support/city_test.gd"
## M014: what has the keys, in one order (Modals), and what each screen gives
## back when it closes - the world unpaused, the controls back, the click that
## closed it never a shot. Keys are sent the way the game gets them
## (main._unhandled_input).


func _action(action: String, pressed := true) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	main._unhandled_input(e)
	await wait_physics_frames(1)


func _key(code: Key) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	main._unhandled_input(e)
	await wait_physics_frames(1)


func test_the_street_the_menu_and_back() -> void:
	var m: Modals = main.modals
	assert_eq(m.top(), "", "Danny in the street")
	await _action(CityInput.MENU)
	assert_eq(m.top(), "menu")
	assert_true(get_tree().paused, "the world waits under the menu")
	assert_true(main.hud.game_menu.visible)
	main.player.fire_lock = false
	var e := InputEventAction.new()
	e.action = CityInput.MENU
	e.pressed = true
	main._unhandled_input(e)
	assert_true(main.player.fire_lock, "the click that closed it is not a shot (until the next tick)")
	await wait_physics_frames(1)
	assert_eq(m.top(), "")
	assert_false(get_tree().paused, "and runs again")


func test_the_map_and_the_status_screen_have_the_keys_while_open() -> void:
	var m: Modals = main.modals
	await _action(CityInput.MAP)
	assert_eq(m.top(), "map")
	assert_true(get_tree().paused)
	await _action(CityInput.STATUS)
	assert_false(m.status_open, "nothing else while the map is open")
	await _action(CityInput.MENU)
	assert_false(m.map_open, "Esc closes the map")
	assert_false(m.paused, "and does not open the menu under it")
	assert_false(get_tree().paused)
	await _action(CityInput.STATUS)
	assert_eq(m.top(), "status")
	await _action(CityInput.STATUS)
	assert_eq(m.top(), "")
	assert_false(get_tree().paused)


func test_a_talk_has_the_keys_and_esc_ends_it() -> void:
	var m: Modals = main.modals
	await talk_to("copper_owl", "augie")
	assert_eq(m.top(), "talk")
	await _action(CityInput.MAP)
	assert_false(m.map_open, "no map in the middle of a talk")
	main.player.fire_lock = false
	var e := InputEventAction.new()
	e.action = CityInput.MENU
	e.pressed = true
	main._unhandled_input(e)
	assert_true(main.player.fire_lock, "the key that ended it is not a shot (until the next tick)")
	await wait_physics_frames(1)
	assert_eq(m.top(), "", "Esc walks away")
	assert_false(m.paused, "and does not open the menu")


func test_at_a_table_only_the_tables_keys() -> void:
	var m: Modals = main.modals
	var back: InteriorPlan = main.interiors.view_of("back_room").plan
	walker().place(back.spots[0].pos, -PI / 2)
	await wait_physics_frames(3)
	await press_e()
	assert_eq(m.top(), "table")
	await _action(CityInput.MAP)
	assert_false(m.map_open, "the map waits")
	await _key(KEY_ESCAPE)
	assert_false(m.paused, "Esc is the table's: no menu")
	assert_false(main.hud.poker_view.is_open(), "it got him up from the table")
	assert_eq(m.top(), "")


func test_a_fight_takes_only_space() -> void:
	var m: Modals = main.modals
	var rival: Rival = main.rival
	walker().place(rival.body.global_position + Vector2(-42, 0), 0.0)
	await wait_physics_frames(3)
	assert_true(main.fights.start(rival.body, Rival.NAME, func(_w: bool, _r: Array) -> void: pass))
	assert_eq(m.top(), "fight")
	await _action(CityInput.MAP)
	await _action(CityInput.MENU)
	assert_false(m.map_open)
	assert_false(m.paused, "no map, no menu mid-fight")
	for i in 600:
		if not main.fights.fighting:
			break
		await wait_physics_frames(1)
	assert_eq(m.top(), "", "the street again when it is over")
	assert_true(main.player.is_physics_processing(), "Danny's controls back")


func test_a_film_takes_the_keys_and_gives_everything_back() -> void:
	var m: Modals = main.modals
	main.films.start_opening(main.game.ward_plan("copper_owl"))
	assert_eq(m.top(), "film")
	assert_false(main.hud.visible)
	await _action(CityInput.MAP)
	assert_false(m.map_open, "the film has the keys")
	await _action(CityInput.MENU)  # skips it
	for i in 600:
		if not main.films.playing():
			break
		await wait_physics_frames(1)
	assert_eq(m.top(), "")
	assert_true(main.hud.visible, "the HUD back")
	assert_true(main.player.is_physics_processing(), "the controls back")
	assert_eq(main.camera.target, walker(), "the camera back on Danny")
	assert_false(m.paused, "the Esc that skipped it opened no menu")
