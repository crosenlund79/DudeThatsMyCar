extends GutTest
## Workshop (poker pacing), without the scene: what the table does is shown a
## beat at a time - each card player's action (who, what, how much), each
## street of the board (one at a time even when an all-in deals them all at
## once), the showdown - Danny's own actions are not held; one fresh press of
## Space moves on exactly one beat, a held key (its repeats, a second press
## before it is let go) never more; and the pacing touches no chip.


## A table: Danny in seat 0 against card players with ids.
func _game(stacks: Array, button: int) -> Holdem:
	var g := Holdem.new(5, 10, 5)
	var ids := ["danny", "irv", "red", "pete"]
	for i in stacks.size():
		g.sit("P%d" % i, stacks[i], {"id": ids[i]})
	g.button = (button - 1 + stacks.size()) % stacks.size()
	return g


## Gives the players these hole cards and stacks the deck so the board comes out as given.
func _rig(g: Holdem, holes: Array, board: String) -> void:
	for i in holes.size():
		g.seats[i].hole = Cards.parse_all(holes[i])
	var b := Cards.parse_all(board)
	var used := {}
	for s in g.seats:
		for c in s.hole:
			used[c] = true
	for c in b:
		used[c] = true
	var spare: Array[int] = []
	for c in 52:
		if not used.has(c):
			spare.append(c)
	var order: Array[int] = [spare[0], b[0], b[1], b[2], spare[1], b[3], spare[2], b[4]]
	order.reverse()
	g.deck = order


func test_an_action_is_shown_with_who_did_it() -> void:
	var g := _game([1000, 1000, 1000], 0)  # button Danny (0), SB 1, BB 2: Danny first
	g.start_hand(1)
	var p := PokerPacing.new()
	p.new_hand()
	assert_true(p.read(g, 0).is_empty(), "the blinds are not held")
	assert_false(p.waiting())
	g.act(0, "raise", 40)  # Danny's own
	assert_true(p.read(g, 0).is_empty(), "his own action is not held")
	g.act(1, "call")
	var beat := p.read(g, 0)
	assert_eq(beat.kind, "action")
	assert_eq(beat.player, "irv", "the card player is named, for a taunt one day")
	assert_eq(beat.action, "call")
	assert_eq(beat.amount, 35)
	assert_eq(beat.text, "Calls $0.35")
	assert_true(p.waiting(), "held until Space")
	g.act(2, "raise", 120)  # the table goes on (the game itself waits; here the log does)
	p.read(g, 0)
	assert_eq(p.current.player, "irv", "still the first beat on show")
	assert_eq(p.queue.size(), 1)
	assert_eq(p.press_continue().player, "red", "one press, one beat")
	assert_eq(p.current.action, "raise")
	assert_eq(p.current.amount, 120)
	assert_eq(p.current.text, "Raises to $1.20")
	assert_true(p.press_continue().is_empty(), "nothing more: play goes on")
	assert_false(p.waiting())


func test_space_moves_one_beat_and_a_held_key_no_more() -> void:
	var g := _game([1000, 1000, 1000, 1000], 1)  # button 1 (irv), SB 2 (red), BB 3 (pete); Danny (0) first
	g.start_hand(2)
	var p := PokerPacing.new()
	p.new_hand()
	g.act(0, "call")
	g.act(1, "call")
	g.act(2, "call")
	g.act(3, "check")  # the flop comes
	p.read(g, 0)
	assert_eq(p.current.player, "irv")
	assert_eq(p.queue.size(), 3, "red's call, pete's check, the flop - waiting their turn")
	assert_eq(p.space(true).player, "red", "a fresh press: one beat on")
	assert_true(p.space(true, true).is_empty(), "the key's auto-repeat does nothing")
	assert_true(p.space(true).is_empty(), "nor a second press before it is let go")
	assert_eq(p.current.player, "red")
	assert_eq(p.queue.size(), 2)
	p.space(false)
	assert_eq(p.space(true).player, "pete", "let go and pressed again: the next")
	assert_eq(p.current.text, "Checks")
	p.space(false)
	assert_eq(p.space(true).kind, "deal")
	assert_eq(p.revealed, 3, "the flop turned over")
	p.space(false)
	assert_true(p.space(true).is_empty(), "then play goes on")
	assert_false(p.waiting())
	p.space(false)
	assert_true(p.space(true).is_empty(), "Space with nothing on show does nothing")


func test_an_all_in_board_comes_out_a_street_at_a_time() -> void:
	var g := _game([1000, 1000], 0)  # heads-up: Danny the button, first
	g.start_hand(3)
	_rig(g, ["Ah Ad", "Kh Kd"], "2c 7s 9d Jh 3c")
	var p := PokerPacing.new()
	p.new_hand()
	g.act(0, "all_in")
	p.read(g, 0)
	g.act(1, "call")  # all in too: the engine deals the whole board at once
	assert_eq(g.board.size(), 5)
	assert_eq(g.street, Holdem.OVER)
	var beat := p.read(g, 0)
	assert_eq(beat.kind, "action")
	assert_true(beat.all_in)
	assert_eq(beat.action, "all_in")
	assert_eq(beat.text, "Calls $9.90 - all in!")
	assert_eq(p.revealed, 0, "no community cards shown yet")
	assert_false(p.hands_shown)
	var steps := []
	while p.waiting():
		steps.append([p.current.kind, p.revealed])
		p.space(true)
		p.space(false)
	assert_eq(steps, [["action", 0], ["deal", 3], ["deal", 4], ["deal", 5], ["result", 5]],
		"the flop, the turn, the river, the result: one press each")
	assert_true(p.hands_shown)


func test_side_pots_and_the_showdown_unchanged() -> void:
	# Danny (100) and two card players all in for different amounts: three pots
	var g := _game([100, 250, 500, 2000], 3)  # button 3, SB 0 (Danny), BB 1, seat 2 first
	g.start_hand(4)
	_rig(g, ["Ah Ad", "Kh Kd", "Qh Qd", "7c 2s"], "As Kc Qs 3d 4h")
	var p := PokerPacing.new()
	p.new_hand()
	var chips := g.total_chips()
	g.act(2, "all_in")
	p.read(g, 0)
	g.act(3, "call")
	p.read(g, 0)
	g.act(0, "all_in")
	p.read(g, 0)
	g.act(1, "all_in")
	p.read(g, 0)
	assert_eq(g.street, Holdem.OVER)
	var kinds := []
	var result := ""
	while p.waiting():
		kinds.append(p.current.kind)
		if p.current.kind == "result":
			result = p.current.text
		p.press_continue()
	assert_eq(kinds, ["action", "action", "action", "deal", "deal", "deal", "result"],
		"three card players' moves, three streets, the result (Danny's own move not held)")
	assert_string_contains(result, "P0 wins $4.00 with three aces")
	assert_string_contains(result, "P1 wins $4.50")
	assert_string_contains(result, "P2 wins $5.00")
	assert_eq(g.total_chips(), chips, "showing it touches no chip")
	assert_eq(g.seats[0].stack, 400)


func test_folds_to_an_uncontested_pot() -> void:
	var g := _game([1000, 1000, 1000], 2)  # button 2, SB 0 (Danny), BB 1, seat 2 first
	g.start_hand(5)
	var p := PokerPacing.new()
	p.new_hand()
	g.act(2, "raise", 60)
	p.read(g, 0)
	p.press_continue()
	g.act(0, "fold")
	p.read(g, 0)
	g.act(1, "fold")
	p.read(g, 0)
	assert_eq(p.current.text, "Folds")
	assert_eq(p.current.player, "irv")
	p.press_continue()
	assert_eq(p.current.kind, "result")
	assert_eq(p.current.text, "P2 takes $0.25")
	assert_false(p.hands_shown and g.shown, "no showdown: nobody's cards turned over")
