extends "res://tests/support/city_test.gd"
## M011 the gaming room's three nickel machines in the game: each is its own
## place along the back wall (E there steps up to that machine; Danny cannot
## walk off or shoot meanwhile); Space pulls the lever - the coin goes at
## once, the reels run and stop on the drawn stops, and what the line shows
## is paid by the machine's paytable, once; a held Space pulls once; no
## nickel, no pull; walking away mid-pull pays it at once and leaves the
## other machines as they were; a save counts a pull under way as decided.

const SAVE := "user://test_the_machines_save.json"


func after_each() -> void:
	super()
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _view() -> SlotView:
	return main.hud.slot_view


func _key(code: Key, pressed: bool = true, echo: bool = false) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	e.echo = echo
	main._unhandled_input(e)
	await wait_physics_frames(1)


func _step_up(i: int, money: int = 200) -> void:
	main.rackets.money = money
	walker().place(RiversideInteriors.SLOTS[i] + Vector2(0, 32), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	assert_string_contains(main.hud.prompt_label.text, "Play the %s" % RiversideInteriors.SLOT_NAMES[i])
	await press_e()
	assert_true(_view().is_open(), "at the %s" % RiversideInteriors.SLOT_NAMES[i])


func _pull() -> void:
	await _key(KEY_SPACE)
	await _key(KEY_SPACE, false)


func _until_paid(max_frames: int = 400) -> void:
	for f in max_frames:
		if _view().phase == "paid":
			return
		await wait_physics_frames(1)


func test_each_machine_is_its_own_place() -> void:
	for i in 3:
		await _step_up(i)
		assert_eq(_view().title, main.slot_rules[i].title)
		assert_eq(_view().machine, main.back_rooms.slot_machines[i], "its own machine")
		var at := walker().global_position
		cmd = PlayerCommand.make(Vector2(0, 1), false, false, at + Vector2(0, 100), true)
		await wait_physics_frames(15)
		cmd = PlayerCommand.new()
		assert_lt(walker().global_position.distance_to(at), 1.0, "no walking off while at the machine")
		assert_false(walker().gun.is_drawn())
		await _key(KEY_ESCAPE)
		assert_false(_view().is_open())
		assert_eq(main.rackets.money, 200, "nothing played, nothing lost")


func test_a_pull_pays_what_the_line_shows_once() -> void:
	await _step_up(0, 100)
	var m: SlotMachine = main.back_rooms.slot_machines[0]
	await _key(KEY_SPACE)
	assert_eq(main.rackets.money, 95, "the nickel goes in at once")
	assert_eq(_view().phase, "spinning")
	for i in 20:
		await _key(KEY_SPACE, true, true)  # held: the key's repeats
	await _key(KEY_SPACE)  # a second press before it is let go
	assert_eq(m.pulls, 1, "a held key pulls once")
	await _key(KEY_SPACE, false)
	await _until_paid()
	assert_eq(_view().phase, "paid")
	var shown := []
	for r in 3:
		var stop := posmod(roundi(_view()._positions[r]), 20)
		assert_eq(stop, m.stops[r], "reel %d stopped on the drawn stop" % r)
		shown.append(m.symbol(r, stop))
	var win := SlotMachine.coins_for(m.rules, shown) * m.rules.coin
	assert_eq(main.rackets.money, 95 + win, "the line in the window, paid by the paytable")
	await wait_physics_frames(60)
	assert_eq(main.rackets.money, 95 + win, "and only once")
	# again
	var before: int = main.rackets.money
	await _pull()
	await _until_paid()
	assert_eq(m.pulls, 2)
	assert_eq(main.rackets.money, before - 5 + m.win)
	await _key(KEY_ESCAPE)


func test_walking_away_mid_pull_pays_at_once_and_leaves_the_others() -> void:
	await _step_up(1, 100)
	await _pull()
	var bell: SlotMachine = main.back_rooms.slot_machines[1]
	var w := bell.win
	await wait_physics_frames(20)
	await _key(KEY_ESCAPE)
	assert_eq(main.rackets.money, 95 + w, "paid when he stepped away")
	assert_false(bell.pending)
	await wait_physics_frames(200)
	assert_eq(main.rackets.money, 95 + w, "never twice")
	assert_eq(main.back_rooms.slot_machines[0].pulls, 0, "the Owl untouched")
	assert_eq(main.back_rooms.slot_machines[2].pulls, 0, "the Star untouched")


func test_a_save_during_and_after_a_pull() -> void:
	main.save_path = SAVE
	await _step_up(2, 100)
	await _pull()
	var star: SlotMachine = main.back_rooms.slot_machines[2]
	main.save_game()
	assert_eq(int(SaveGame.read(SAVE).rackets.money), 90 + star.win, "a pull under way is decided: counted")
	await _until_paid()
	main.save_game()
	assert_eq(int(SaveGame.read(SAVE).rackets.money), 90 + star.win, "after it is paid: the same")
	assert_eq(main.rackets.money, 90 + star.win)
	await _key(KEY_ESCAPE)
	main.save_path = ""


func test_no_coin_no_pull() -> void:
	await _step_up(0, 3)
	await _pull()
	assert_eq(main.back_rooms.slot_machines[0].pulls, 0)
	assert_string_contains(_view().message, "a nickel")
	assert_eq(main.rackets.money, 3)
	await _key(KEY_ESCAPE)
	await _step_up(2, 5)
	await _pull()
	assert_string_contains(_view().message, "a dime")
	assert_eq(main.rackets.money, 5)
	await _key(KEY_ESCAPE)
