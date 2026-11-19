extends "res://tests/support/city_test.gd"
## M008 playthrough, the experience target with the normal controls: it's late;
## Danny leaves his flat, climbs into his sedan and drives down Kessler Street
## into the Riverfront Yards without a stop; he stops, opens the city map and
## looks round the districts; he gets into trouble - shoots a man where the
## yards' beat cop can see it - and the copper draws and shoots; Danny drives
## off back into the ward (the copper stays on his own ground), on along
## Marlowe Avenue, into the Copper Owl for a deal with Augie, home to bed; the
## next evening every district is as a night starts, and a saved game loads.

var _save := ""


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func _until(cond: Callable, frames: int) -> bool:
	for i in frames:
		if cond.call():
			return true
		await wait_physics_frames(1)
	return false


func test_a_night_beyond_the_ward() -> void:
	_save = OS.get_user_data_dir().path_join("test_beyond_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	var world: DistrictStreamer = main.world
	# out of the flat and into the sedan at the kerb
	var home: InteriorPlan = main._plan("home")
	walker().place(home.outside_door(0, 20.0), PI / 2)
	await wait_physics_frames(3)
	var sedan: Car = main.my_car()
	await walk_to(sedan.global_position + Vector2(0, -40), 8.0, 600)
	await press_e()
	assert_eq(player().car, sedan, "his own sedan")
	# down Kessler Street into the yards
	var worst := 0.0
	var last := sedan.global_position
	var steps := 0
	for leg in [[Vector2(2300, 650), Vector2(1700, 650), Vector2(1690, 1600)], [Vector2(1690, 2600), Vector2(1690, 3050)]]:
		steps += await drive_route(sedan, leg, 260.0, 900)
		worst = maxf(worst, sedan.global_position.distance_to(last))
	assert_gt(sedan.global_position.y, 2950.0, "in the Riverfront Yards")
	assert_eq(world.current, "yards")
	assert_eq(main.hud.district_label.text, "RIVERFRONT YARDS")
	assert_lte(world.loaded.size(), 2)
	cmd = PlayerCommand.make(Vector2(0, 1))
	await wait_physics_frames(60)
	cmd = PlayerCommand.new()
	# the city map: he looks round and finds the ward
	main._unhandled_input(_key(CityInput.MAP))
	var m: CityMap = main.hud.city_map
	assert_true(m.visible)
	assert_true(m.map_rect.has_point(m.to_screen(sedan.global_position)), "he is on it, in the yards")
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_WHEEL_DOWN
	e.pressed = true
	e.position = m.map_rect.get_center()
	m._gui_input(e)
	assert_true(m.world.intersects(main.layout.play_area), "the ward is there on the map, north of him")
	main._unhandled_input(_key(CityInput.MAP))
	# trouble: out of the car, a shot at a man in front of the yards' copper
	for i in 20:
		if player().on_foot():
			break
		await press_e()
	assert_true(player().on_foot())
	var cop: PoliceOfficer = main._districts.yards.officer
	var victim := Walker.create(main.resolver, "characters/worker", {"glow": false})
	main.add_child(victim)
	# along Front Street from the copper's corner (the works are behind him)
	victim.place(cop.body.global_position + Vector2(120, -60), 0.0)
	walker().place(cop.body.global_position + Vector2(300, -60), PI)
	await wait_physics_frames(3)
	await click(victim.global_position)
	await aim_for(victim.global_position, 20)
	assert_true(cop.brain.armed, "the yards' copper saw it")
	var shots := [0]
	cop.fired.connect(func(_m: Vector2, _d: Vector2) -> void: shots[0] += 1)
	assert_true(await _until(func() -> bool: return shots[0] > 0, 60 * 6), "he draws and shoots")
	# away in the sedan, back into the ward
	await seat_in(sedan)
	await park(sedan, Vector2(1690, 3000), -PI / 2)
	await drive_route(sedan, [Vector2(1690, 2400), Vector2(1690, 1600), Vector2(1700, 650), Vector2(2150, 650)], 280.0, 1200)
	assert_eq(world.current, "riverside", "back in the ward")
	assert_true(world.layouts.yards.play_area.grow(2.0).has_point(cop.body.global_position) if is_instance_valid(cop) else true,
		"the copper stayed on his own ground")
	cmd = PlayerCommand.make(Vector2(0, 1))
	await wait_physics_frames(60)
	cmd = PlayerCommand.new()
	for i in 20:
		if player().on_foot():
			break
		await press_e()
	# the Copper Owl as ever: a deal with Augie
	var money: int = main.rackets.money
	await talk_to("copper_owl", "augie")
	await answer_with("protection")
	await answer_with("ask")
	assert_gt(main.rackets.money + main.rackets.held, money, "business as usual")
	await press_e()
	# home to bed: the next evening
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(5)
	assert_eq(main.rackets.night, 2)
	assert_eq(sedan.global_position, main.car_specs[7].pos as Vector2, "his sedan back outside the flat")
	assert_false(main.officer.brain.armed, "a new night, nothing on the beat cop's mind")
	# saved and loaded
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
	assert_eq(main.rackets.night, 2)
	assert_eq(main.world.ready_ids(), ["riverside"] as Array[String])
	main.world.load_now("halloran")
	assert_true(main.world.is_ready("halloran"), "and the city carries on west as before")
	main.save_path = ""
