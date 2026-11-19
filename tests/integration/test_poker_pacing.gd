extends "res://tests/support/city_test.gd"
## Workshop (poker pacing) in the game: at the back-room table each card
## player's action stays on show - his plate says it, the line at the bottom
## names him - with a small "Space  Continue" prompt, and nothing moves until
## Space; one press moves on one action, a held Space (its repeats) no more;
## Space on Danny's own turn does nothing, and the betting keys wait while
## something is on show; the board turns a street per press, the showdown's
## result waits for Space before the next hand; holding Space at the table
## never speeds up the night; every cent still adds up.


func _key(code: Key, pressed: bool = true, echo: bool = false) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	e.echo = echo
	return e


func _send(e: InputEvent) -> void:
	main._unhandled_input(e)
	await wait_physics_frames(1)


func _space() -> void:
	await _send(_key(KEY_SPACE))
	await _send(_key(KEY_SPACE, false))


func _view() -> PokerView:
	return main.hud.poker_view


func _sit_in(cents: int = 1000) -> void:
	main.rackets.money = cents
	var plan: InteriorPlan = main.interiors.view_of("back_room").plan
	walker().place(plan.spots[0].pos, -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	await press_e()
	_view().think = Vector2(0.05, 0.08)
	await _send(_key(KEY_2))  # $5


## Waits (pressing nothing) until something is on show, or `frames` run out.
func _until_waiting(frames: int = 600) -> void:
	for f in frames:
		if _view().pacing.waiting():
			return
		var t: Holdem = main.poker.table
		if t.running() and t.to_act == main.poker.danny:
			await _send(_key(KEY_2 if t.legal(main.poker.danny).check else KEY_1))  # Danny plays on
		await wait_process_frames(1)


func test_each_action_waits_for_space() -> void:
	var shown := []
	_view().beat_shown.connect(func(b: Dictionary) -> void: shown.append(b))
	await _sit_in()
	await _until_waiting()
	assert_true(_view().pacing.waiting(), "something on show")
	var beat: Dictionary = _view().pacing.current
	if beat.kind == "action":
		assert_true(beat.player in ["irv", "red", "pete", "moe"], "the card player is identified (%s)" % beat.player)
		assert_eq(_view().said.get(beat.seat, ""), beat.text, "his plate says what he did")
	assert_true(_view()._buttons.any(func(b: Dictionary) -> bool: return b.id == "continue"), "the Space prompt")
	# nothing moves while it waits
	var events: int = main.poker.table.events.size()
	var hand: int = main.poker.hands
	for i in 120:
		await wait_process_frames(1)
	assert_eq(main.poker.table.events.size(), events, "no card player acts while it waits")
	assert_eq(main.poker.hands, hand)
	assert_eq(shown.back(), beat, "the hook names the beat on show")
	# one press: exactly one beat on
	var before := shown.size()
	await _space()
	for i in 60:
		await wait_process_frames(1)
		if shown.size() > before or (main.poker.table.running() and main.poker.table.to_act == main.poker.danny):
			break
	assert_lte(shown.size(), before + 1, "one press, at most one more beat")


func test_a_held_space_moves_one_beat_only() -> void:
	await _sit_in()
	await _until_waiting()
	# collect a few beats waiting at once: let the table run to Danny's turn behind the one on show
	var on_show: Dictionary = _view().pacing.current
	await _send(_key(KEY_SPACE))  # pressed and held
	for i in 30:
		await _send(_key(KEY_SPACE, true, true))  # the key's auto-repeat
		await wait_process_frames(2)
	var after_hold: Dictionary = _view().pacing.current
	await _send(_key(KEY_SPACE))  # still not let go: a stray second press
	assert_eq(_view().pacing.current, after_hold, "held: nothing more")
	assert_ne(after_hold, on_show, "the first press did move on")
	await _send(_key(KEY_SPACE, false))
	# while something is on show the betting keys wait
	await _until_waiting()
	var t: Holdem = main.poker.table
	var events := t.events.size()
	await _send(_key(KEY_1))
	await _send(_key(KEY_4))
	assert_eq(t.events.size(), events, "1-4 do nothing while a beat is on show")


func test_space_on_dannys_turn_does_nothing() -> void:
	await _sit_in()
	for f in 3000:
		var t: Holdem = main.poker.table
		if t.running() and t.to_act == main.poker.danny and not _view().pacing.waiting():
			break
		if _view().pacing.waiting():
			await _space()
		await wait_process_frames(1)
	var t: Holdem = main.poker.table
	assert_eq(t.to_act, main.poker.danny, "Danny's turn, nothing on show")
	var events := t.events.size()
	var chips: int = main.poker.danny_chips()
	await _space()
	await _space()
	assert_eq(t.events.size(), events, "Space does not act for him")
	assert_eq(t.to_act, main.poker.danny)
	assert_eq(main.poker.danny_chips(), chips)
	assert_true(_view()._buttons.any(func(b: Dictionary) -> bool: return b.id == "act1"), "his betting buttons are there")


func test_board_and_showdown_a_step_at_a_time() -> void:
	var books := 0
	await _sit_in(2000)
	books = main.rackets.money + main.poker.danny_chips() + main.poker.players_money()
	var revealed_seen := []
	var results := 0
	var hands_before: int = main.poker.hands
	for f in 8000:
		var p: PokerPacing = _view().pacing
		if p.waiting():
			var beat: Dictionary = p.current
			if beat.kind == "deal":
				revealed_seen.append(p.revealed)
				assert_lte(p.revealed, main.poker.table.board.size())
			if beat.kind == "result":
				results += 1
				assert_eq(_view().banner, beat.text, "the result read out")
				var hand: int = main.poker.hands
				for i in 30:
					await wait_process_frames(1)
				assert_eq(main.poker.hands, hand, "the next hand waits for Space")
				if results >= 3:
					break
			await _space()
		else:
			var t: Holdem = main.poker.table
			if t.running() and t.to_act == main.poker.danny:
				# Danny sees every hand through: checks or calls
				await _send(_key(KEY_2))
		await wait_process_frames(1)
	assert_gte(results, 3, "three hands played through to their results")
	assert_true(revealed_seen.has(3), "the flop shown on its own")
	assert_eq(main.rackets.money + main.poker.danny_chips() + main.poker.players_money(), books, "every cent accounted for")
	assert_gt(main.poker.hands, hands_before)


func test_holding_space_at_the_table_never_speeds_the_night() -> void:
	await _sit_in()
	cmd = PlayerCommand.make(Vector2.ZERO, false, true)  # Space held, as the controller reads it
	var before: float = main.clock.minute
	await wait_physics_frames(120)
	assert_almost_eq(main.clock.minute - before, 2.0, 0.3, "a minute a second, as ever")
	cmd = PlayerCommand.new()


## M011.2: getting up (Esc) while a card player's move is on show: he folds
## if a hand is under way, and every cent is where it should be. M013: in a
## hand he is still in, he is asked first (Enter: yes).
func test_getting_up_while_a_move_is_on_show() -> void:
	main.rackets.money = 1000
	var books: int = main.rackets.money + main.poker.players_money()
	await _sit_in(1000)
	await _until_waiting()
	assert_true(_view().pacing.waiting(), "a move on show")
	await _send(_key(KEY_ESCAPE))
	if not _view().confirm.is_empty():
		await _send(_key(KEY_ENTER))  # M013: fold and leave
	assert_false(_view().is_open(), "up from the table")
	assert_false(main.poker.seated())
	assert_true(player().seat.is_empty())
	assert_eq(main.rackets.money + main.poker.players_money(), books, "every cent accounted for")


## M011.2: a save while a move is on show loads without the table. M013: the
## hand under way counts as folded (stake_for_save: his chips in front of him).
func test_saving_while_a_move_is_on_show() -> void:
	var path := "user://test_poker_pacing_save.json"
	main.save_path = path
	await _sit_in(1000)
	await _until_waiting()
	assert_true(main.poker.table.running() or _view().pacing.waiting())
	var expect: int = main.rackets.money + main.poker.stake_for_save()
	main.save_game()
	var saved := SaveGame.read(path)
	assert_eq(int(saved.rackets.money), expect, "the hand under way counts as folded")
	main.save_path = ""
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	await _send(_key(KEY_ESCAPE))
	if not _view().confirm.is_empty():
		await _send(_key(KEY_ENTER))
