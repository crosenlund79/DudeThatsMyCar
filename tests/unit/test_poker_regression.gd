extends GutTest
## M011.2 the back-room game kept as it was, with the Workshop's pacing
## (regression, without the scene): over many hands of the real card players
## (PokerNight, PokerBrain) and a Danny who plays at random, driven the way the
## card table drives them - nobody acts while a beat is on show - every card
## player's action is shown exactly once and in order (none missed, none
## twice), each street is turned once in order, each hand's result once at
## its end; all-ins and side pots come up and are settled; and not a chip is
## made or lost. A split pot's result names both winners and shares the pot
## to the chip.


## Danny's choice: any legal action, at random.
func _dannys_move(t: Holdem, i: int, rng: RandomNumberGenerator) -> void:
	var l := t.legal(i)
	var options := ["fold"]
	if l.check:
		options.append("check")
	if l.call > 0:
		options.append("call")
	if l.bet or l.raise:
		options.append("raise")
	if l.all_in > 0:
		options.append("all_in")
	var kind: String = options[rng.randi_range(0, options.size() - 1)]
	if kind == "raise":
		var to := rng.randi_range(l.min_to, l.max_to)
		to -= to % t.chip
		assert_true(t.act(i, "bet" if l.bet else "raise", maxi(to, l.min_to)), "Danny's raise is legal")
	else:
		assert_true(t.act(i, kind), "Danny's %s is legal" % kind)


func test_every_action_shown_once_in_order_over_many_hands() -> void:
	var rng := RandomNumberGenerator.new()
	var all_ins := 0
	var side_pots := 0
	var hands_played := 0
	for night_no in range(1, 7):
		rng.seed = night_no * 7919
		var night := PokerNight.new()
		night.begin_night(night_no)
		var books: int = night.players_money() + 1000
		assert_true(night.sit_down(1000, 1000))
		var p := PokerPacing.new()
		var shown: Array[Dictionary] = []
		for step in 20000:
			var t := night.table
			if p.waiting():
				shown.append(p.current)
				p.press_continue()
				continue
			if t.running():
				if night.ai_to_act():
					night.ai_turn()
				else:
					_dannys_move(t, night.danny, rng)
				if t.pots().size() > 1:
					side_pots += 1
				p.read(t, night.danny)
				continue
			# between hands: the last hand's beats all shown - check them against the table's log
			if t.hand_no > 0:
				_check_hand(t, night.danny, shown, 0)
				all_ins += t.events.filter(func(e: Dictionary) -> bool: return e.get("all_in", false)).size()
				assert_eq(night.danny_chips() + night.players_money(), books, "night %d, hand %d: the books balance" % [night_no, t.hand_no])
			shown.clear()
			if not night.next_hand():
				break
			hands_played += 1
			p.new_hand()
			p.read(t, night.danny)
		var chips := night.leave()
		assert_eq(chips + night.players_money(), books, "night %d: every cent home again" % night_no)
	assert_gt(hands_played, 60, "plenty of hands (%d)" % hands_played)
	assert_gt(all_ins, 5, "all-ins came up (%d)" % all_ins)
	assert_gt(side_pots, 0, "side pots came up")


## The hand's beats against the table's own log (Holdem keeps one hand's events, from `from`).
func _check_hand(t: Holdem, danny: int, shown: Array[Dictionary], from: int) -> void:
	var expected := []
	var streets := []
	for k in range(from, t.events.size()):
		var e: Dictionary = t.events[k]
		if String(e.what) in ["fold", "check", "call", "bet", "raise"] and int(e.seat) != danny:
			expected.append([int(e.seat), String(e.what)])
		if String(e.what) == "deal":
			streets.append(int(e.street))
	var actions := []
	var deals := []
	var results := 0
	for b in shown:
		match String(b.kind):
			"action":
				actions.append([int(b.seat), "call" if b.action == "all_in" and _was(t, from, b, "call") else
					("bet" if b.action == "all_in" and _was(t, from, b, "bet") else ("raise" if b.action == "all_in" else String(b.action)))])
				assert_eq(String(b.player), String(t.seats[b.seat].id), "the beat names the card player")
			"deal":
				deals.append(int(b.street))
			"result":
				results += 1
				assert_eq(b, shown.back(), "the result comes last")
	assert_eq(actions, expected, "hand %d: every card player's action, once, in order" % t.hand_no)
	assert_eq(deals, streets, "hand %d: each street once, in order" % t.hand_no)
	assert_eq(results, 1, "hand %d: the result once" % t.hand_no)


## Which kind of event an all-in beat came from (the seat's all-in event in this hand).
func _was(t: Holdem, from: int, b: Dictionary, kind: String) -> bool:
	for k in range(from, t.events.size()):
		var e: Dictionary = t.events[k]
		if int(e.get("seat", -1)) == int(b.seat) and e.get("all_in", false) and String(e.what) == kind:
			return true
	return false


func test_a_split_pot_shown_and_shared_to_the_chip() -> void:
	# three players, the board a straight nobody beats: the pot split three ways, the odd chip by the rules
	var g := Holdem.new(5, 10, 5)
	for i in 3:
		g.sit("P%d" % i, 1000, {"id": ["danny", "irv", "red"][i]})
	g.button = 2
	g.start_hand(9)
	var holes := ["2c 3d", "2h 4d", "3h 4c"]
	var board := Cards.parse_all("Ah Kd Qs Jc Td")
	for i in 3:
		g.seats[i].hole = Cards.parse_all(holes[i])
	var used := {}
	for s in g.seats:
		for c in s.hole:
			used[c] = true
	for c in board:
		used[c] = true
	var spare: Array[int] = []
	for c in 52:
		if not used.has(c):
			spare.append(c)
	var order: Array[int] = [spare[0], board[0], board[1], board[2], spare[1], board[3], spare[2], board[4]]
	order.reverse()
	g.deck = order
	var chips := g.total_chips()
	var p := PokerPacing.new()
	p.new_hand()
	while g.running():
		var i := g.to_act
		var l := g.legal(i)
		g.act(i, "check" if l.check else "call")
		p.read(g, 0)
		while p.waiting() and p.current.kind != "result":
			p.press_continue()
	assert_true(p.waiting())
	assert_eq(p.current.kind, "result")
	assert_string_contains(p.current.text, "split")
	assert_string_contains(p.current.text, "P0")
	assert_string_contains(p.current.text, "P2")
	assert_eq(g.total_chips(), chips, "no chip made or lost")
	assert_eq(g.seats[0].stack + g.seats[1].stack + g.seats[2].stack, 3000)
	for s in g.seats:
		assert_almost_eq(float(s.stack), 1000.0, 5.0, "each takes his share back (to the chip)")
