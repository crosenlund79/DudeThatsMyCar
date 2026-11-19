extends "res://tests/support/city_test.gd"
## M011 the gaming room's wheel in the game: E at the rail brings up the
## layout (Danny cannot walk off or shoot meanwhile); clicks on the layout put
## chips down where they are clicked (the money goes at once), a right click
## takes one back, Backspace all of them; R puts the same bets down again; no
## money, no chip; no croupier or closing time, no game.
## M013: Leo runs the wheel. Rounds go on whether Danny bets or only watches;
## chips go down only while the bets are open (Space spins nothing); the call
## comes by itself - later while Danny is still putting chips down, never past
## the limit; the number is drawn at the call, the wheel in the room turns with
## the one on screen, the ball comes to rest in that number's pocket and the
## round is settled once, to the cent; the next round opens by itself; joining
## after the call means waiting for the next; walking away after the call is
## settled at once and never again; a save in any phase counts the chips
## right; at the hour to go home the round under way is played out and no
## other begins. The tests use shorter rounds (the same rules otherwise).

const SAVE := "user://test_the_wheel_save.json"


func before_each() -> void:
	await super()
	var quick: RouletteRules = main.roulette_rules.duplicate()
	quick.open_seconds = 4.0
	quick.ball_seconds = 3.0
	quick.drop_seconds = 2.0
	quick.result_seconds = 2.0
	quick.grace_seconds = 1.5
	quick.max_extension = 3.0
	quick.last_call_seconds = 1.0
	main.wheel.rules = quick


func after_each() -> void:
	super()
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _view() -> RouletteView:
	return main.hud.roulette_view


func _wheel() -> RouletteTable:
	return main.wheel


func _key(code: Key) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	main._unhandled_input(e)
	await wait_physics_frames(1)


func _click(key: String, right: bool = false) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_RIGHT if right else MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = _view()._from_layout(RouletteLayout.anchor(key))
	_view()._gui_input(e)
	await wait_physics_frames(1)


func _in_the_room() -> void:
	walker().place(RiversideInteriors.ROULETTE_SPOT, -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)


func _step_up(money: int = 1000) -> void:
	main.rackets.money = money
	await _in_the_room()
	assert_string_contains(main.hud.prompt_label.text, "Play the wheel")
	await press_e()
	assert_true(_view().is_open(), "the wheel's layout up")


## Until the table reaches `phase` (the next time, if it is there already and `fresh`).
func _until_phase(phase: int, fresh := false, max_frames: int = 2400) -> bool:
	if fresh:
		for i in max_frames:
			if _wheel().phase != phase:
				break
			await wait_physics_frames(1)
	for i in max_frames:
		if _wheel().phase == phase:
			return true
		await wait_physics_frames(1)
	return false


func _until_settled(max_frames: int = 2400) -> void:
	await _until_phase(RouletteTable.Phase.RESULT, false, max_frames)


func test_stepping_up_and_walking_away() -> void:
	await _step_up()
	assert_eq(_view().phase, "open")
	var at := walker().global_position
	cmd = PlayerCommand.make(Vector2(1, 0), false, false, at + Vector2(100, 0), true)
	await wait_physics_frames(20)
	cmd = PlayerCommand.new()
	assert_lt(walker().global_position.distance_to(at), 1.0, "no walking off while at the wheel")
	assert_false(walker().gun.is_drawn(), "no gun at the table")
	assert_false(main.hud.minimap.visible, "the table has the screen")
	await _key(KEY_ESCAPE)
	assert_false(_view().is_open())
	assert_eq(main.rackets.money, 1000, "nothing bet, nothing lost")
	assert_string_contains(main.hud.notice_label.text, "You step away from the wheel even")


func test_leo_calls_the_bets_and_settles_once() -> void:
	await _in_the_room()
	assert_true(await _until_phase(RouletteTable.Phase.OPEN, true), "a fresh round")
	await _step_up(2000)
	await _key(KEY_3)  # 25 cents
	await _click("straight:17")
	await _click("split:17-20")
	await _click("corner:0-1-2-3")
	await _key(KEY_4)  # a dollar
	await _click("red")
	await _click("dozen:2")
	await _key(KEY_1)  # a nickel
	await _click("line:16-17-18-19-20-21")
	await _click("column:3")
	var r: Roulette = main.roulette
	assert_eq(r.bets, {"straight:17": 25, "split:17-20": 25, "corner:0-1-2-3": 25, "red": 100, "dozen:2": 100,
		"line:16-17-18-19-20-21": 5, "column:3": 5}, "each chip on the bet clicked")
	assert_eq(main.rackets.money, 2000 - 285, "the chips taken at once")
	await _click("column:3", true)
	assert_false(r.bets.has("column:3"), "a right click took it back")
	assert_eq(main.rackets.money, 2000 - 280)
	var bets: Dictionary = r.bets.duplicate()
	var before: int = main.rackets.money
	await _key(KEY_SPACE)
	assert_true(_wheel().betting_open(), "Space spins nothing: Leo calls it")
	assert_eq(r.phase, Roulette.Phase.BETTING)
	assert_true(await _until_phase(RouletteTable.Phase.DROP), "the call comes by itself")
	assert_eq(r.phase, Roulette.Phase.SPINNING, "no more bets")
	var n := _wheel().number
	assert_true(n >= 0 and n <= 36)
	assert_eq(r.result, n, "his chips ride on the number drawn")
	await _click("black")
	assert_false(r.bets.has("black"), "nothing goes down after the call")
	assert_string_contains(_view().message, "No more bets")
	await wait_physics_frames(30)
	var rotor := main.interiors.view_of("gaming_room").get_node("roulette_rotor") as Sprite2D
	assert_almost_eq(rotor.rotation, _wheel().motion.rotor, 0.0001, "the wheel in the room turns as the one on screen")
	await _until_settled()
	assert_eq(r.phase, Roulette.Phase.SETTLED, "the ball came to rest")
	assert_eq(_wheel().motion.pocket_under(), n, "it rests in the pocket of the number drawn")
	var expect := 0
	for k in bets:
		expect += Roulette.returns(k, bets[k], n)
	assert_eq(main.rackets.money, before + expect, "settled to the cent")
	assert_eq(r.history[0], n)
	await wait_physics_frames(60)
	assert_eq(main.rackets.money, before + expect, "and only once")
	# the next round opens by itself; R puts the same bets down again
	assert_true(await _until_phase(RouletteTable.Phase.OPEN))
	assert_true(r.bets.is_empty(), "a clean layout")
	await _key(KEY_R)
	assert_eq(r.bets, bets, "the same again")
	assert_eq(main.rackets.money, before + expect - 280)
	await _key(KEY_BACKSPACE)
	assert_true(r.bets.is_empty())
	assert_eq(main.rackets.money, before + expect, "all taken back")
	await _key(KEY_ESCAPE)


func test_watching_without_a_chip_down() -> void:
	await _step_up(500)
	var board: int = main.roulette.history.size()
	var turned: float = _wheel().motion.rotor
	for i in 2:
		assert_true(await _until_phase(RouletteTable.Phase.RESULT, true))
		await wait_physics_frames(2)
	assert_eq(main.roulette.history.size(), board + 2, "two numbers on the board")
	assert_gt(_wheel().motion.rotor, turned, "the wheel never stops")
	assert_eq(main.rackets.money, 500, "watching costs nothing")
	await _key(KEY_ESCAPE)


func test_joining_after_the_call() -> void:
	await _in_the_room()  # in the room: Leo's rounds go on
	assert_true(await _until_phase(RouletteTable.Phase.DROP, true))
	await _step_up(500)
	assert_string_contains(_view().message, "No more bets")
	await _click("red")
	assert_true(main.roulette.bets.is_empty(), "too late for this one")
	assert_eq(main.rackets.money, 500)
	assert_true(await _until_phase(RouletteTable.Phase.OPEN))
	await _key(KEY_3)
	await _click("red")
	assert_eq(main.roulette.bets.get("red", 0), 25, "the next round takes it")
	await _key(KEY_ESCAPE)
	assert_eq(main.rackets.money, 500, "walking off before the call: the chip back")


func test_the_call_waits_while_he_is_still_betting() -> void:
	await _in_the_room()
	assert_true(await _until_phase(RouletteTable.Phase.OPEN, true))
	await _step_up(2000)
	var usual := _wheel().rules.open_seconds + _wheel().rules.ball_seconds
	while _wheel().round_time < usual - 0.4:
		await wait_physics_frames(1)
	await _key(KEY_1)
	var placed := 0
	while _wheel().betting_open():
		await _click("straight:%d" % (placed % 37))
		placed += 1
		await wait_physics_frames(12)
		if placed > 200:
			break
	assert_gt(_wheel().round_time, usual + 0.5, "Leo waited on him past the usual call")
	assert_lte(_wheel().close_time(), usual + _wheel().rules.max_extension + 0.001, "but not past the limit")
	assert_eq(main.roulette.phase, Roulette.Phase.SPINNING)
	assert_eq(main.rackets.money + main.roulette.total_staked(), 2000, "every chip accounted for")
	await _until_settled()
	await _key(KEY_ESCAPE)


func test_walking_away_after_the_call_settles_once() -> void:
	await _in_the_room()
	assert_true(await _until_phase(RouletteTable.Phase.OPEN, true))
	await _step_up(1000)
	await _key(KEY_4)
	await _click("even")
	await _key(KEY_2)
	await _click("straight:0")
	assert_true(await _until_phase(RouletteTable.Phase.DROP))
	var n: int = _wheel().number
	await wait_physics_frames(10)
	await _key(KEY_ESCAPE)
	assert_false(_view().is_open())
	var expect := 1000 - 110 + Roulette.returns("even", 100, n) + Roulette.returns("straight:0", 10, n)
	assert_eq(main.rackets.money, expect, "settled when he walked away")
	assert_eq(main.roulette.history[0], n, "the number on the board")
	var board: int = main.roulette.history.size()
	await _until_phase(RouletteTable.Phase.OPEN)
	assert_eq(main.rackets.money, expect, "never paid twice")
	assert_eq(main.roulette.history.size(), board, "nor put on the board twice when the ball came to rest")
	assert_eq(main.roulette.phase, Roulette.Phase.BETTING, "a fresh layout for next time")


func test_a_save_in_every_phase() -> void:
	main.save_path = SAVE
	await _in_the_room()
	assert_true(await _until_phase(RouletteTable.Phase.OPEN, true))
	await _step_up(1000)
	await _key(KEY_4)
	await _click("high")
	await _click("low")
	main.save_game()
	assert_eq(int(SaveGame.read(SAVE).rackets.money), 1000, "bets open: the chips on the layout are still his")
	assert_true(await _until_phase(RouletteTable.Phase.BALL))
	main.save_game()
	assert_eq(int(SaveGame.read(SAVE).rackets.money), 1000, "the ball going round, bets open: still his")
	assert_true(await _until_phase(RouletteTable.Phase.DROP))
	var n: int = _wheel().number
	main.save_game()
	var expect := 800 + Roulette.returns("high", 100, n) + Roulette.returns("low", 100, n)
	assert_eq(int(SaveGame.read(SAVE).rackets.money), expect, "after the call the number is decided: counted as settled")
	await _until_settled()
	assert_eq(main.rackets.money, expect, "the same in play")
	assert_eq(int(SaveGame.read(SAVE).rackets.money), expect, "saved again after it came to rest: the same")
	# loaded: a fresh round, the money right
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = false
	main.save_path = SAVE
	main.settings_path = ""
	main.quiet_streets = true
	add_child_autofree(main)
	await wait_physics_frames(3)
	assert_eq(main.rackets.money, expect)
	assert_true(main.roulette.bets.is_empty())
	assert_true(main.wheel.betting_open(), "Leo opens a fresh round")
	main.save_path = ""


func test_no_money_no_chip() -> void:
	await _in_the_room()
	assert_true(await _until_phase(RouletteTable.Phase.OPEN, true))
	await _step_up(30)
	await _key(KEY_4)
	await _click("red")
	assert_true(main.roulette.bets.is_empty(), "a dollar chip with thirty cents: refused")
	assert_string_contains(_view().message, "haven't the money")
	await _key(KEY_3)
	await _click("red")
	await _click("red")
	assert_eq(main.roulette.bets.get("red", 0), 25)
	assert_eq(main.rackets.money, 5)
	await _until_settled()
	assert_gte(main.rackets.money, 0)
	await _key(KEY_ESCAPE)


func test_no_croupier_or_closing_time_no_game() -> void:
	var view: InteriorView = main.interiors.view_of("gaming_room")
	view.out["croupier"] = true
	await _in_the_room()
	await press_e()
	assert_false(_view().is_open())
	assert_string_contains(main.hud.notice_label.text, "Nobody at the wheel")
	view.out.erase("croupier")
	main.wheel.begin_night()
	# four o'clock while he plays: the round under way is played out, then the cover goes on
	assert_true(await _until_phase(RouletteTable.Phase.OPEN, true))
	await _step_up(1000)
	await _key(KEY_3)
	await _click("odd")
	main.clock.set_time(float(main.night_rules.home_minute) + 1.0)
	assert_true(await _until_phase(RouletteTable.Phase.CLOSED), "the last spin of the night")
	assert_eq(main.roulette.history.size() > 0, true)
	assert_eq(main.rackets.money + main.roulette.for_save(), 975 + Roulette.returns("odd", 25, main.roulette.history[0]), "his chip resolved")
	await _click("red")
	assert_true(main.roulette.bets.is_empty(), "nothing goes down after closing")
	await _key(KEY_ESCAPE)
	await press_e()
	assert_false(_view().is_open())
	assert_string_contains(main.hud.notice_label.text, "That's all for tonight")


func test_the_wheel_rests_when_nobody_is_in_the_room() -> void:
	await _in_the_room()
	await wait_physics_frames(30)
	walker().place(STREETCAR_STOP, 0.0)
	await wait_physics_frames(5)
	var t: float = _wheel().round_time
	var r: int = _wheel().rounds
	await wait_physics_frames(120)
	assert_eq(_wheel().round_time, t, "no wheel turned for an empty room")
	assert_eq(_wheel().rounds, r)
