extends "res://tests/support/city_test.gd"
## M015 the developer tools in the game menu: off until switched on there (a
## preference); then a kind at a time (Left / Right), a tool at a time (Up /
## Down), Enter or a click to use it; a tool that throws something away asks
## first; each works through the game's own systems (the night's clock and
## what moves with it, the districts and rooms, the fleet, the guns, the jobs'
## models); every tool in the catalogue runs without an error.


func _key(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	main._unhandled_input(e)
	await wait_physics_frames(1)


func _menu() -> GameMenu:
	return main.hud.game_menu


## The menu open on the developer tools' page.
func _open_tools() -> void:
	await _key(CityInput.MENU)
	while _menu().current() != "cheats":
		await _key("ui_down")
	await _key("ui_accept")
	assert_eq(_menu().page, "cheats")


func _use(id: String) -> void:
	main.modals.menu_action("dev:" + id)
	await wait_physics_frames(2)


func test_off_until_switched_on() -> void:
	assert_false(main.game.prefs.get_pref("dev_tools"))
	await _open_tools()
	assert_false(_menu().dev_on, "switched off")
	await _key("ui_accept")
	assert_true(_menu().dev_on)
	assert_true(main.game.prefs.get_pref("dev_tools"), "a preference")
	assert_gt(_menu().dev_categories.size(), 10, "the kinds of tools")
	var first: String = _menu().dev_categories[0].name
	await _key("ui_right")
	assert_ne(_menu().dev_categories[_menu().dev_cat].name, first, "Right: the next kind")
	await _key("ui_left")
	assert_eq(_menu().dev_cat, 0)
	# Money: Enter on the first tool (Add $10)
	var money: int = main.rackets.money
	await _key("ui_accept")
	assert_eq(main.rackets.money, money + 1000)
	assert_string_contains(_menu().status, "Money")
	assert_true(main.modals.paused, "the menu stays open")


func test_a_tool_that_throws_something_away_asks_first() -> void:
	main.game.prefs.set_pref("dev_tools", true)
	await _open_tools()
	var cats: Array = _menu().dev_categories
	var ci := -1
	for i in cats.size():
		if cats[i].name == "Jobs and errands":
			ci = i
	assert_gte(ci, 0)
	_menu().dev_cat = ci
	_menu().dev_row = 0
	var job_before: RourkeJob = main.rackets.job
	assert_eq(_menu().dev_pick(0), "", "asks first")
	assert_string_contains(_menu().status, "Enter again")
	assert_same(main.rackets.job, job_before, "nothing done yet")
	var what := _menu().dev_pick(0)
	assert_eq(what, "dev:job_rourke_again")
	main.modals.menu_action(what)
	assert_ne(main.rackets.job, job_before, "the job started over")


func test_the_tools_work_through_the_game() -> void:
	# time: an hour later, the night's business with it
	var minute: float = main.clock.minute
	var done: float = main.rackets.town.night_done
	await _use("time_plus_60")
	assert_almost_eq(main.clock.minute, minute + 60.0, 0.1, "an hour on (and the two frames after)")
	assert_gt(main.rackets.town.night_done, done, "the ward's businesses went on with the clock")
	# weather
	await _use("weather_fog")
	assert_eq(main.weather.forced, "fog", "fog held all night")
	# a district and a room
	await _use("go_district_yards")
	assert_true(main.world.is_ready("yards"))
	assert_eq(main.world.district_at(walker().global_position), "yards")
	await _use("go_riverside/room/copper_owl")
	assert_eq(main.interiors.current.id, "copper_owl", "inside the Copper Owl")
	# Danny
	walker().condition.hurt("torso", 40)
	assert_true(walker().condition.is_hurt())
	await _use("danny_heal")
	assert_eq(walker().condition.worst(), BodyCondition.Level.FINE, "not a scratch")
	main.armoury.pistol.ammo = 0
	await _use("danny_ammo")
	assert_eq(main.armoury.pistol.ammo, main.armoury.pistol.rules.magazine)
	# his sedan beside him (out in the street)
	await _use("go_district_riverside")
	await _use("car_mine_here")
	assert_lt(main.fleet.my_car().global_position.distance_to(walker().global_position), 140.0)


func test_every_tool_runs() -> void:
	var ran := 0
	for cat in main.game.dev.catalogue():
		for t in cat.tools:
			if String(t.id) in ["time_new_night", "dev_off"]:
				continue  # (sleeping and switching off: their own tests)
			var out: Dictionary = main.game.dev.run(String(t.id))
			assert_true(out.has("text") and out.has("close"), String(t.id))
			ran += 1
			if main.modals.paused:
				main.modals.open_menu(false)
			await wait_physics_frames(1)
			if main.films.playing():
				main.films.current.skip()
				for f in 300:
					if not main.films.playing():
						break
					await wait_physics_frames(1)
	assert_gt(ran, 40, "the catalogue")


func test_sleep_from_the_tools() -> void:
	var night: int = main.rackets.night
	await _use("time_new_night")
	assert_eq(main.rackets.night, night + 1)
	assert_false(main.modals.paused, "the menu closed")
