extends "res://tests/support/city_test.gd"
## M010 the Copper Owl's back-room card game in the game: through the door in
## the club's west wall into the back room (three regulars at the table, no
## street badge for it), E at the empty chair sits Danny down and offers the
## buy-in, the hands are dealt and played with the table's keys while he
## cannot walk or shoot, he gets up with his chips (mid-hand he folds), the
## money adds up to the cent, a save mid-hand counts the hand for nothing, and
## the game breaks up at closing time.

const SAVE := "user://test_card_game_save.json"


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	return e


func _press(code: Key) -> void:
	main._unhandled_input(_key(code))
	await wait_physics_frames(1)


## Space pressed and let go (one beat on: a card player's action, a street, the result).
func _space() -> void:
	main._unhandled_input(_key(KEY_SPACE))
	var up := _key(KEY_SPACE)
	up.pressed = false
	main._unhandled_input(up)
	await wait_physics_frames(1)


## Presses Space through whatever is on show until it is Danny's turn (or `frames` run out).
func _until_dannys_turn(frames: int = 3000) -> void:
	for f in frames:
		var t: Holdem = main.back_rooms.poker.table
		if t != null and t.running() and t.to_act == main.back_rooms.poker.danny and not _view().pacing.waiting():
			return
		if _view().pacing.waiting():
			await _space()
		await wait_process_frames(1)


func _view() -> PokerView:
	return main.hud.poker_view


func _to_the_table() -> void:
	var plan: InteriorPlan = main.interiors.view_of("back_room").plan
	walker().place(plan.spots[0].pos, -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	_view().think = Vector2(0.05, 0.08)


## Plays on (Danny checks when he can, otherwise folds: a careful man) until
## `hands` more hands have been played to their result (it is on show, waiting
## for Space - the next hand is dealt the moment it is dismissed) or the table closes.
func _play_hands(hands: int, max_frames: int = 6000) -> void:
	var target: int = main.back_rooms.poker.hands + hands
	for f in max_frames:
		if not main.back_rooms.poker.seated() or _view().phase != "play":
			return
		if main.back_rooms.poker.hands >= target and _view().pacing.current.get("kind", "") == "result":
			return
		if _view().pacing.waiting():
			await _space()  # one beat at a time
		elif main.back_rooms.poker.table.running() and main.back_rooms.poker.table.to_act == main.back_rooms.poker.danny:
			await _press(KEY_2 if main.back_rooms.poker.table.legal(main.back_rooms.poker.danny).check else KEY_1)
		await wait_process_frames(1)


func test_through_the_door_to_the_back_room() -> void:
	var owl: InteriorPlan = main.interiors.view_of("copper_owl").plan
	var back: InteriorPlan = main.interiors.view_of("back_room").plan
	walker().place(owl.inside_door(2, 10.0), PI)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	assert_eq(main.interiors.current, owl)
	assert_string_contains(main.hud.prompt_label.text, "Through to The Copper Owl's Back Room")
	await press_e()
	await wait_physics_frames(3)
	assert_eq(main.interiors.current, back, "in the back room")
	var view: InteriorView = main.interiors.view_of("back_room")
	for id in ["irv", "red", "pete"]:
		assert_true((view.people[id] as Walker).visible, "%s at the table" % id)
	assert_false((view.people.moe as Walker).visible, "Moe comes in later, if a chair comes free")
	assert_true(main.markers.marker_of("back_room").is_empty(), "no badge on the street for a back room")
	walker().place(back.inside_door(0, 10.0), 0.0)
	await wait_physics_frames(3)
	assert_string_contains(main.hud.prompt_label.text, "Through to The Copper Owl")
	await press_e()
	await wait_physics_frames(3)
	assert_eq(main.interiors.current, owl, "and back into the club")


func test_sitting_in_playing_and_getting_up() -> void:
	main.rackets.money = 1200
	var books: int = main.rackets.money + main.back_rooms.poker.players_money()
	await _to_the_table()
	assert_string_contains(main.hud.prompt_label.text, "Sit in at the card game")
	await press_e()
	assert_true(_view().is_open())
	assert_eq(_view().phase, "buyin")
	assert_eq(_view().choices, [200, 500, 1000] as Array[int])
	assert_false(player().seat.is_empty(), "sitting at the table")
	await _press(KEY_2)  # $5
	assert_eq(main.rackets.money, 700, "five dollars on the table")
	assert_true(main.back_rooms.poker.seated())
	assert_eq(_view().phase, "play")
	# he cannot walk off or shoot while he plays
	var at := walker().global_position
	cmd = PlayerCommand.make(Vector2(1, 0), false, false, at + Vector2(100, 0), true)
	await wait_physics_frames(20)
	cmd = PlayerCommand.new()
	assert_lt(walker().global_position.distance_to(at), 1.0, "no walking at the table")
	assert_false(walker().gun.is_drawn(), "no gun at the table")
	assert_true(main._drowsy_held(), "no drowsy sway at the cards")
	await _play_hands(4)
	assert_gte(main.back_rooms.poker.hands, 4, "hands dealt and played")
	assert_eq(main.rackets.money + main.back_rooms.poker.danny_chips() + main.back_rooms.poker.players_money(), books, "the books balance at the table")
	await _press(KEY_ESCAPE)
	assert_false(_view().is_open())
	assert_false(main.back_rooms.poker.seated())
	assert_true(player().seat.is_empty(), "up from the table")
	assert_eq(main.rackets.money + main.back_rooms.poker.players_money(), books, "every cent accounted for")
	assert_string_contains(main.hud.notice_label.text, "You get up from the table")


func test_raising_with_the_keys() -> void:
	main.rackets.money = 1000
	await _to_the_table()
	await press_e()
	await _press(KEY_1)  # $2
	await _until_dannys_turn()
	var l: Dictionary = main.back_rooms.poker.table.legal(main.back_rooms.poker.danny)
	assert_true(l.raise or l.bet, "he may raise")
	await wait_process_frames(2)
	assert_eq(_view().raise_to, l.min_to, "the raise starts at the least allowed")
	await _press(KEY_UP)
	await _press(KEY_UP)
	assert_eq(_view().raise_to, mini(l.min_to + 20, l.max_to), "two steps of a big blind up")
	await _press(KEY_DOWN)
	var to: int = _view().raise_to
	await _press(KEY_3)
	var last: Dictionary = main.back_rooms.poker.table.events.filter(func(e: Dictionary) -> bool: return e.get("seat", -1) == main.back_rooms.poker.danny).back()
	assert_true(last.what == "raise" or last.what == "bet")
	assert_eq(last.to, to, "raised to what the table showed")


## M013: a save mid-hand counts the hand as folded (M010 counted it void,
## which let a save undo a losing hand): what he has put in is gone.
func test_a_save_mid_hand_counts_the_hand_as_folded() -> void:
	main.save_path = SAVE
	main.rackets.money = 1000
	await _to_the_table()
	await press_e()
	await _press(KEY_2)  # $5
	for f in 2000:
		if main.back_rooms.poker.table.running() and main.back_rooms.poker.danny_chips() < 500 and main.back_rooms.poker.table.seats[main.back_rooms.poker.danny].total > 0:
			break
		await wait_process_frames(1)
	assert_true(main.back_rooms.poker.table.running())
	var in_pot: int = main.back_rooms.poker.table.seats[main.back_rooms.poker.danny].total
	main.save_game()
	var saved := SaveGame.read(SAVE)
	assert_eq(int(saved.rackets.money), 500 + 500 - in_pot, "what he has in the pot is gone, as if he had folded")
	main.save_path = ""
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	await _press(KEY_ESCAPE)
	if main.hud.poker_view.is_open():
		await _press(KEY_ENTER)  # M013: yes, fold and leave


func test_closing_time() -> void:
	main.rackets.money = 1000
	await _to_the_table()
	await press_e()
	await _press(KEY_2)
	await _play_hands(1)
	main.clock.set_time(float(main.night_rules.home_minute) + 1.0)
	await wait_process_frames(2)
	await _play_hands(3)
	for f in 600:
		if _view().phase == "over":
			break
		if _view().pacing.waiting():
			await _space()
		elif main.back_rooms.poker.table.running() and main.back_rooms.poker.table.to_act == main.back_rooms.poker.danny:
			await _press(KEY_1)
		await wait_process_frames(1)
	assert_eq(_view().phase, "over", "the game breaks up after the hand")
	assert_string_contains(_view().over_text, "Four o'clock")
	await _press(KEY_E)
	assert_false(_view().is_open())
	await _to_the_table()
	await press_e()
	assert_eq(_view().over_text, "The game's breaking up for the night.", "no new game after closing")
	await _press(KEY_ESCAPE)
	assert_false(_view().is_open())
