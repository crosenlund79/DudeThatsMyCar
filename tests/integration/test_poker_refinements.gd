extends "res://tests/support/city_test.gd"
## M013 the back-room table refined, with the normal keys: the stakes chosen
## on the buy-in (the left and right arrows), the table playing them and
## showing them, never changed while he sits; getting up during a hand he is
## still in asks first - Esc stays, Enter folds and goes, the books balance -
## and between hands it does not ask; the game saves after every hand (a save
## never undoes a loss); chips slide to the pot; the hook for recorded taunts
## picks a line and plays nothing when nobody has recorded it.

var _save := ""


func before_each() -> void:
	await super()
	_save = OS.get_user_data_dir().path_join("test_poker_refinements_%d.json" % Time.get_ticks_usec())


func after_each() -> void:
	super()
	if FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _key(code: Key, pressed: bool = true) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	return e


func _send(e: InputEvent) -> void:
	main._unhandled_input(e)
	await wait_physics_frames(1)


func _space() -> void:
	await _send(_key(KEY_SPACE))
	await _send(_key(KEY_SPACE, false))


func _view() -> PokerView:
	return main.hud.poker_view


func _to_the_table(cents: int) -> void:
	main.rackets.money = cents
	var plan: InteriorPlan = main.interiors.view_of("back_room").plan
	walker().place(plan.spots[0].pos, -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	await press_e()
	assert_eq(_view().phase, "buyin")
	_view().think = Vector2(0.05, 0.08)


## Until Danny is to act in a hand under way (pressing Space through the beats).
func _until_his_turn(frames: int = 3000) -> bool:
	for f in frames:
		var t: Holdem = main.back_rooms.poker.table
		if t != null and t.running() and t.to_act == main.back_rooms.poker.danny and not _view().pacing.waiting():
			return true
		if _view().pacing.waiting():
			await _space()
		await wait_process_frames(1)
	return false


func test_the_stakes_chosen_before_sitting_down() -> void:
	await _to_the_table(6000)
	assert_eq(main.back_rooms.poker.level, 0)
	await _send(_key(KEY_RIGHT))
	assert_eq(main.back_rooms.poker.level, 1, "right: dime and quarter")
	assert_eq(_view().choices, [500, 1000, 2500] as Array[int], "the buy-ins to match")
	await _send(_key(KEY_RIGHT))
	await _send(_key(KEY_RIGHT))
	assert_eq(main.back_rooms.poker.level, 2, "no further than quarter and half")
	await _send(_key(KEY_LEFT))
	await _send(_key(KEY_2))  # $10 at dime and quarter
	assert_eq(_view().phase, "play")
	assert_eq(main.rackets.money, 5000)
	assert_eq([main.back_rooms.poker.table.small_blind, main.back_rooms.poker.table.big_blind], [10, 25], "the table plays them")
	await _send(_key(KEY_RIGHT))
	assert_eq(main.back_rooms.poker.level, 1, "never changed while he sits")
	assert_false(main.back_rooms.poker.set_level(0))


func test_getting_up_mid_hand_asks_first() -> void:
	await _to_the_table(1000)
	var books: int = main.rackets.money + main.back_rooms.poker.players_money()
	await _send(_key(KEY_2))  # $5
	assert_true(await _until_his_turn(), "his turn in a hand")
	var in_pot: int = main.back_rooms.poker.table.seats[main.back_rooms.poker.danny].total
	await _send(_key(KEY_ESCAPE))
	assert_false(_view().confirm.is_empty(), "the question first")
	assert_eq(int(_view().confirm.in_pot), in_pot)
	assert_true(main.back_rooms.poker.seated(), "still at the table")
	var acted: int = main.back_rooms.poker.table.events.size()
	await wait_physics_frames(60)
	assert_eq(main.back_rooms.poker.table.events.size(), acted, "nothing moves while he makes up his mind")
	await _send(_key(KEY_SPACE))
	await _send(_key(KEY_1))
	assert_eq(main.back_rooms.poker.table.events.size(), acted, "Space and the betting keys wait for the answer")
	await _send(_key(KEY_ESCAPE))
	assert_true(_view().confirm.is_empty(), "Esc: he stays")
	assert_true(main.back_rooms.poker.seated())
	await _send(_key(KEY_ESCAPE))
	var takes := int(_view().confirm.takes)
	var pocket: int = main.rackets.money
	await _send(_key(KEY_ENTER))
	assert_false(_view().is_open(), "Enter: he folds and goes")
	assert_false(main.back_rooms.poker.seated())
	assert_eq(main.rackets.money, pocket + takes, "he takes home what the question said")
	assert_eq(main.rackets.money + main.back_rooms.poker.players_money(), books, "every cent accounted for")


func test_between_hands_he_just_goes() -> void:
	await _to_the_table(1000)
	await _send(_key(KEY_2))
	assert_true(await _until_his_turn())
	await _send(_key(KEY_1))  # he folds
	assert_false(main.back_rooms.poker.leave_terms().in_hand)
	await _send(_key(KEY_ESCAPE))
	assert_true(_view().confirm.is_empty(), "nothing at stake: no question")
	assert_false(_view().is_open())


func test_saved_after_every_hand() -> void:
	main.save_path = _save
	await _to_the_table(1000)
	await _send(_key(KEY_2))
	var results := [0]
	_view().hand_over.connect(func() -> void: results[0] += 1)
	for f in 6000:
		if results[0] >= 2:
			break
		var t: Holdem = main.back_rooms.poker.table
		if _view().pacing.waiting():
			await _space()
		elif t.running() and t.to_act == main.back_rooms.poker.danny:
			await _send(_key(KEY_2 if t.legal(main.back_rooms.poker.danny).check else KEY_1))
		await wait_process_frames(1)
	assert_gte(results[0], 2, "two hands played")
	var saved := SaveGame.read(_save)
	assert_eq(int(saved.rackets.money), main.rackets.money + main.back_rooms.poker.stake_for_save(), "the last hand's result in the save")
	main.save_path = ""
	await _send(_key(KEY_ESCAPE))
	if not _view().confirm.is_empty():
		await _send(_key(KEY_ENTER))


func test_chips_slide_and_the_taunt_hook() -> void:
	await _to_the_table(1000)
	await _send(_key(KEY_2))
	var slid := false
	var hooked := []
	_view().beat_shown.connect(func(b: Dictionary) -> void:
		if not _view()._moves.is_empty():
			hooked.append(b.kind))
	for f in 3000:
		if not _view()._moves.is_empty():
			slid = true
		if slid and hooked.size() > 0:
			break
		var t: Holdem = main.back_rooms.poker.table
		if _view().pacing.waiting():
			await _space()
		elif t.running() and t.to_act == main.back_rooms.poker.danny:
			await _send(_key(KEY_2 if t.legal(main.back_rooms.poker.danny).check else KEY_1))
		await wait_process_frames(1)
	assert_true(slid, "chips slide across the baize")
	# the hook: a raise by Red picks one of his lines, recorded or not; nothing plays without a recording
	var red := -1
	for i in main.back_rooms.poker.table.seats.size():
		if main.back_rooms.poker.table.seats[i].id == "red":
			red = i
	main.back_rooms.taunt_rng.seed = 1
	for k in 40:
		main.back_rooms.last_taunt = {}
		main.back_rooms.poker_taunt({"kind": "action", "seat": red, "player": "red", "action": "raise", "amount": 50})
		if not main.back_rooms.last_taunt.is_empty():
			break
	assert_eq(main.back_rooms.last_taunt.player, "red")
	assert_true(main.back_rooms.last_taunt.situation in ["raise", "bluff"])
	assert_has(PokerTaunts.LINES.red[main.back_rooms.last_taunt.situation], main.back_rooms.last_taunt.line)
	assert_false(main.back_rooms.last_taunt.recorded, "no recording ships: nothing said")
	await _send(_key(KEY_ESCAPE))
	if not _view().confirm.is_empty():
		await _send(_key(KEY_ENTER))
