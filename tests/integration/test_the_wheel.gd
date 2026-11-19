extends "res://tests/support/city_test.gd"
## M011 the gaming room's wheel in the game: E at the rail brings up the
## layout (Danny cannot walk off or shoot meanwhile); clicks on the layout put
## chips down where they are clicked (the money goes at once), a right click
## takes one back, Backspace all of them; Space spins - the number is decided
## then, the wheel in the room turns with the one on screen, the ball comes to
## rest in that number's pocket and the round is settled once, to the cent; a
## chip put down after a spin starts the next round, R puts the same bets down
## again; walking away mid-spin settles it at once and never again; a save
## counts chips on the layout as Danny's and a spin under way as settled; no
## money, no chip; no croupier or closing time, no game.

const SAVE := "user://test_the_wheel_save.json"


func after_each() -> void:
	super()
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _view() -> RouletteView:
	return main.hud.roulette_view


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


func _step_up(money: int = 1000) -> void:
	main.rackets.money = money
	walker().place(RiversideInteriors.ROULETTE_SPOT, -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	assert_string_contains(main.hud.prompt_label.text, "Play the wheel")
	await press_e()
	assert_true(_view().is_open(), "the wheel's layout up")


func _until_settled(max_frames: int = 900) -> void:
	for i in max_frames:
		if main.roulette.phase == Roulette.Phase.SETTLED:
			return
		await wait_physics_frames(1)


func test_stepping_up_and_walking_away() -> void:
	await _step_up()
	assert_eq(_view().phase, "betting")
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


func test_bets_a_spin_and_one_settling() -> void:
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
	assert_eq(r.phase, Roulette.Phase.SPINNING, "no more bets")
	var n := r.result
	assert_true(n >= 0 and n <= 36)
	await _click("black")
	assert_false(r.bets.has("black"), "nothing goes down while it spins")
	await wait_physics_frames(60)
	var rotor := main.interiors.view_of("gaming_room").get_node("roulette_rotor") as Sprite2D
	assert_ne(rotor.rotation, 0.0, "the wheel in the room turns too")
	await _until_settled()
	assert_eq(r.phase, Roulette.Phase.SETTLED, "the ball came to rest")
	assert_eq(_view().spin.pocket_under(_view().spin_t), n, "it rests in the pocket of the number the rules gave")
	var expect := 0
	for k in bets:
		expect += Roulette.returns(k, bets[k], n)
	assert_eq(main.rackets.money, before + expect, "settled to the cent")
	assert_eq(r.history[0], n)
	assert_eq(_view().phase, "result")
	await wait_physics_frames(120)
	assert_eq(main.rackets.money, before + expect, "and only once")
	# the next round: a chip put down starts it; R puts the same bets down again
	await _key(KEY_BACKSPACE)
	await _key(KEY_R)
	assert_eq(r.bets, bets, "the same again")
	assert_eq(main.rackets.money, before + expect - 280)
	await _key(KEY_BACKSPACE)
	assert_true(r.bets.is_empty())
	assert_eq(main.rackets.money, before + expect, "all taken back")
	await _key(KEY_ESCAPE)


func test_walking_away_mid_spin_settles_once() -> void:
	await _step_up(1000)
	await _key(KEY_4)
	await _click("even")
	await _key(KEY_2)
	await _click("straight:0")
	await _key(KEY_SPACE)
	var n: int = main.roulette.result
	await wait_physics_frames(30)
	await _key(KEY_ESCAPE)
	assert_false(_view().is_open())
	var expect := 1000 - 110 + Roulette.returns("even", 100, n) + Roulette.returns("straight:0", 10, n)
	assert_eq(main.rackets.money, expect, "settled when he walked away")
	await wait_physics_frames(500)
	assert_eq(main.rackets.money, expect, "never paid twice")
	assert_eq(main.roulette.phase, Roulette.Phase.BETTING, "a fresh layout for next time")


func test_a_save_counts_the_layout_and_the_spin() -> void:
	main.save_path = SAVE
	await _step_up(1000)
	await _key(KEY_4)
	await _click("high")
	await _click("low")
	main.save_game()
	assert_eq(int(SaveGame.read(SAVE).rackets.money), 1000, "chips on the layout are still his")
	await _key(KEY_SPACE)
	var n: int = main.roulette.result
	main.save_game()
	var expect := 800 + Roulette.returns("high", 100, n) + Roulette.returns("low", 100, n)
	assert_eq(int(SaveGame.read(SAVE).rackets.money), expect, "a spin under way counts as settled")
	await _until_settled()
	assert_eq(main.rackets.money, expect, "the same in play")
	assert_eq(int(SaveGame.read(SAVE).rackets.money), expect, "saved again after settling: the same")
	await _key(KEY_ESCAPE)
	main.save_path = ""


func test_no_money_no_chip() -> void:
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
	await _key(KEY_SPACE)
	await _until_settled()
	assert_gte(main.rackets.money, 0)
	await _key(KEY_ESCAPE)


func test_no_croupier_or_closing_time_no_game() -> void:
	var view: InteriorView = main.interiors.view_of("gaming_room")
	view.out["croupier"] = true
	walker().place(RiversideInteriors.ROULETTE_SPOT, -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	await press_e()
	assert_false(_view().is_open())
	assert_string_contains(main.hud.notice_label.text, "Nobody at the wheel")
	view.out.erase("croupier")
	main.clock.set_time(float(main.night_rules.home_minute) + 5.0)
	await wait_physics_frames(2)
	await press_e()
	assert_false(_view().is_open())
	assert_string_contains(main.hud.notice_label.text, "That's all for tonight")
