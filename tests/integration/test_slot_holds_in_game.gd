extends "res://tests/support/city_test.gd"
## M013 hold-and-respin at the machines in the game, with the normal keys: a
## full pull that pays nothing lights the HOLD lamps (by the pull's own fair
## draw), 1-3 throw the brass latches (never all three), Space respins - the
## stake taken once, the held reels standing still, all three paid - then the
## holds come off and the next pull spins all three; S changes the stake (and
## puts lit lamps out); the lamps wait if he steps away; a save mid-pull counts
## the pull as paid, once, and loads with the reels, lamps, holds and stake.

var _save := ""


func before_each() -> void:
	await super()
	_save = OS.get_user_data_dir().path_join("test_slot_holds_%d.json" % Time.get_ticks_usec())


func after_each() -> void:
	super()
	if FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _view() -> SlotView:
	return main.hud.slot_view


func _key(code: Key, pressed: bool = true) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	main._unhandled_input(e)
	await wait_physics_frames(1)


func _step_up(i: int, money: int = 500) -> void:
	main.rackets.money = money
	walker().place(RiversideInteriors.SLOTS[i] + Vector2(0, 32), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	await press_e()
	assert_true(_view().is_open())


func _pull() -> void:
	await _key(KEY_SPACE)
	await _key(KEY_SPACE, false)


func _until_paid() -> void:
	for f in 600:
		if _view().phase == "paid":
			return
		await wait_physics_frames(1)


## Sets the game's draw so that the next full pull at machine `i` loses and lights the lamps.
func _next_pull_lights(i: int) -> void:
	var m: SlotMachine = main.slot_machines[i]
	for s in 200000:
		var r := RandomNumberGenerator.new()
		r.seed = s
		var probe := SlotMachine.new(m.rules)
		probe.stake = m.stake
		probe.pull(100000, r.randi())
		probe.collect()
		if probe.win == 0 and probe.hold_offered:
			main._slot_rng.seed = s
			return
	fail_test("no seed found")


func test_hold_two_reels_and_respin_the_third() -> void:
	await _step_up(0)
	var m: SlotMachine = main.slot_machines[0]
	_next_pull_lights(0)
	await _pull()
	await _until_paid()
	assert_eq(m.win, 0, "nothing on that pull")
	assert_true(m.hold_offered, "the HOLD lamps light")
	assert_string_contains(_view().message, "HOLD lamps light")
	var first := [m.stops[0], m.stops[1]]
	await _key(KEY_1)
	await _key(KEY_2)
	assert_eq(m.held, [true, true, false] as Array[bool], "two latches thrown")
	assert_string_contains(_view().message, "Holding")
	await _key(KEY_3)
	assert_false(m.held[2], "never all three")
	assert_string_contains(_view().message, "Two reels at most")
	var before: int = main.rackets.money
	await _pull()
	assert_eq(main.rackets.money, before - m.stake, "the stake taken once")
	assert_true(m.respin)
	var p0: float = _view()._positions[0]
	var p1: float = _view()._positions[1]
	var free_moved := false
	for f in 600:
		await wait_physics_frames(1)
		assert_eq(_view()._positions[0], p0, "reel 1 stands still")
		assert_eq(_view()._positions[1], p1, "reel 2 stands still")
		if _view()._positions[2] != float(m.stops[2]):
			free_moved = true
		if _view().phase == "paid":
			break
	assert_true(free_moved, "the third reel spun")
	assert_eq([m.stops[0], m.stops[1]], first, "the held reels' symbols kept")
	var won := SlotMachine.coins_for(m.rules, m.line()) * m.stake
	assert_eq(main.rackets.money, before - m.stake + won, "paid what the window shows, all three reels")
	assert_eq(m.held, [false, false, false] as Array[bool], "the holds come off")
	assert_false(m.hold_offered)
	await _key(KEY_1)
	assert_false(m.held[0], "the next pull spins all three")
	await _pull()
	assert_false(m.respin)
	await _until_paid()
	await _key(KEY_ESCAPE)


func test_the_stake_and_the_lamps() -> void:
	await _step_up(2, 1000)
	var m: SlotMachine = main.slot_machines[2]
	assert_eq(m.stake, 10, "the Star: a dime")
	await _key(KEY_S)
	assert_eq(m.stake, 20, "S: two dimes")
	_next_pull_lights(2)
	var before: int = main.rackets.money
	await _pull()
	assert_eq(main.rackets.money, before - 20)
	await _until_paid()
	assert_true(m.hold_offered)
	await _key(KEY_1)
	await _key(KEY_S)
	assert_eq(m.stake, 50)
	assert_false(m.hold_offered, "a new stake puts the lamps out")
	assert_eq(m.held_count(), 0)
	assert_string_contains(_view().message, "lamps go out")
	await _key(KEY_ESCAPE)


func test_the_lamps_wait_while_he_steps_away() -> void:
	await _step_up(1)
	var m: SlotMachine = main.slot_machines[1]
	_next_pull_lights(1)
	await _pull()
	await _until_paid()
	await _key(KEY_2)
	await _key(KEY_ESCAPE)
	assert_false(_view().is_open())
	await _step_up(1, main.rackets.money)
	assert_true(m.hold_offered, "still lit")
	assert_true(m.held[1], "the latch still thrown")
	assert_string_contains(_view().message, "HOLD lamps are still lit")
	await _key(KEY_ESCAPE)


func test_saved_mid_respin_and_loaded() -> void:
	main.save_path = _save
	await _step_up(0)
	var m: SlotMachine = main.slot_machines[0]
	_next_pull_lights(0)
	await _pull()
	await _until_paid()
	await _key(KEY_1)
	await _pull()  # the respin, under way
	var expect: int = main.rackets.money + m.win
	var stops := m.stops.duplicate()
	main.save_game()
	assert_eq(int(SaveGame.read(_save).rackets.money), expect, "the pull under way counted as paid")
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = false
	main.save_path = _save
	main.settings_path = ""
	main.quiet_streets = true
	add_child_autofree(main)
	await wait_physics_frames(3)
	assert_eq(main.rackets.money, expect, "once")
	var again: SlotMachine = main.slot_machines[0]
	assert_eq(again.stops, stops, "the reels as they stood")
	assert_false(again.hold_offered, "a respin lights no lamps")
	assert_false(again.pending)
	main.save_path = ""


func test_not_enough_for_the_respin() -> void:
	await _step_up(0, 500)
	var m: SlotMachine = main.slot_machines[0]
	_next_pull_lights(0)
	await _pull()
	await _until_paid()
	await _key(KEY_1)
	main.rackets.money = 3
	_view().set_money(3)
	await _pull()
	assert_eq(main.rackets.money, 3, "nothing taken")
	assert_string_contains(_view().message, "haven't")
	assert_true(m.held[0], "the hold waits for him")
	await _key(KEY_ESCAPE)
