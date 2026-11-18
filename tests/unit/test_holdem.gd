extends GutTest
## M010 No-Limit Texas Hold'em, the rules: blinds and who acts when (heads-up
## too), the button moving on, minimum bets and raises, the BB's option, what
## reopens the betting and what does not, nobody raising into all-ins, bets
## nobody called handed back, a pot taken without a showdown, main and side
## pots with several all-ins, split pots and the odd chip, short blinds,
## joining, leaving and busting - and never a chip made or lost.


func _game(stacks: Array, button: int = -1) -> Holdem:
	var g := Holdem.new(5, 10, 5)
	for i in stacks.size():
		g.sit("P%d" % i, stacks[i])
	if button >= 0:
		g.button = (button - 1 + stacks.size()) % stacks.size()  # start_hand moves it on to `button`
	return g


## Gives the players these hole cards and stacks the deck so the board comes
## out as given (burn cards in between).
func _rig(g: Holdem, holes: Array, board: String) -> void:
	for i in holes.size():
		if holes[i] != "":
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
	var order: Array[int] = [spare[0], b[0], b[1], b[2], spare[1], b[3], spare[2], b[4]]  # burn, flop, burn, turn, burn, river
	order.reverse()
	g.deck = order


func _total(g: Holdem) -> int:
	return g.total_chips()


func test_blinds_and_order_three_handed() -> void:
	var g := _game([1000, 1000, 1000], 0)
	assert_true(g.start_hand(1))
	assert_eq(g.button, 0)
	assert_eq(g.sb_seat, 1)
	assert_eq(g.bb_seat, 2)
	assert_eq(g.seats[1].bet, 5, "small blind")
	assert_eq(g.seats[2].bet, 10, "big blind")
	assert_eq(g.to_act, 0, "first to act: the button, three-handed (after the big blind)")
	for s in g.seats:
		assert_eq(s.hole.size(), 2)
	assert_true(g.act(0, "call"))
	assert_eq(g.to_act, 1)
	assert_true(g.act(1, "call"))
	assert_eq(g.to_act, 2, "the big blind has the option")
	var l := g.legal(2)
	assert_true(l.check, "he may check his option")
	assert_true(l.raise)
	assert_true(g.act(2, "check"))
	assert_eq(g.street, Holdem.FLOP)
	assert_eq(g.board.size(), 3)
	assert_eq(g.to_act, 1, "after the flop: the first player left of the button")
	assert_eq(g.pot_total(), 30)


func test_four_handed_under_the_gun() -> void:
	var g := _game([500, 500, 500, 500], 2)
	g.start_hand(3)
	assert_eq(g.sb_seat, 3)
	assert_eq(g.bb_seat, 0)
	assert_eq(g.to_act, 1, "under the gun: the player after the big blind")


func test_heads_up() -> void:
	var g := _game([1000, 1000], 0)
	g.start_hand(2)
	assert_eq(g.sb_seat, 0, "heads-up the button posts the small blind")
	assert_eq(g.bb_seat, 1)
	assert_eq(g.to_act, 0, "and acts first before the flop")
	g.act(0, "call")
	g.act(1, "check")
	assert_eq(g.street, Holdem.FLOP)
	assert_eq(g.to_act, 1, "the big blind acts first after it")
	g.act(1, "check")
	g.act(0, "check")
	assert_eq(g.street, Holdem.TURN)
	assert_eq(g.to_act, 1)


func test_the_button_moves_on_past_empty_seats() -> void:
	var g := _game([500, 500, 500, 500], 0)
	g.start_hand(1)  # SB 1, BB 2, seat 3 first
	g.act(3, "fold")
	g.act(0, "fold")
	g.act(1, "fold")
	assert_eq(g.street, Holdem.OVER)
	g.leave(1)
	g.start_hand(2)
	assert_eq(g.button, 2, "seat 1 has gone: the button passes over it")
	assert_eq(g.sb_seat, 3)
	assert_eq(g.bb_seat, 0)
	assert_false(g.seats[1].in_hand)


func test_minimum_bets_and_raises() -> void:
	var g := _game([1000, 1000, 1000], 0)
	g.start_hand(4)
	var l := g.legal(0)
	assert_false(l.check, "facing the big blind")
	assert_eq(l.call, 10)
	assert_eq(l.min_to, 20, "the least raise: by the big blind")
	assert_eq(l.max_to, 1000)
	assert_false(g.act(0, "raise", 15), "less than a full raise")
	assert_false(g.act(0, "raise", 23), "not a whole chip")
	assert_false(g.act(0, "check"), "cannot check a bet")
	assert_false(g.act(1, "call"), "not his turn")
	assert_true(g.act(0, "raise", 40))  # raised by 30
	l = g.legal(1)
	assert_eq(l.call, 35)
	assert_eq(l.min_to, 70, "a re-raise: by at least the last raise")
	assert_true(g.act(1, "raise", 100))  # by 60
	assert_eq(g.legal(2).min_to, 160)
	g.act(2, "fold")
	g.act(0, "call")
	assert_eq(g.street, Holdem.FLOP)
	l = g.legal(1)
	assert_true(l.bet, "nothing bet yet: a bet")
	assert_false(l.raise)
	assert_eq(l.min_to, 10, "the least bet: the big blind")
	assert_false(g.act(1, "call"), "nothing to call")
	assert_false(g.act(1, "bet", 5))
	assert_true(g.act(1, "bet", 10))
	assert_eq(g.legal(0).min_to, 20)


func test_a_short_all_in_does_not_reopen_the_betting() -> void:
	# A (seat 0) bets 100, B raises to 300, C goes all-in for 400 - 100 more, not a full raise
	var g := _game([2000, 2000, 410, 2000], 3)  # C has 400 left after the flop comes
	g.start_hand(5)  # button 3, SB 0, BB 1, C (2) first
	g.act(2, "call")
	g.act(3, "call")
	g.act(0, "call")
	g.act(1, "check")
	assert_eq(g.street, Holdem.FLOP)
	assert_eq(g.to_act, 0)
	g.act(0, "bet", 100)
	g.act(1, "raise", 300)
	assert_eq(g.min_raise, 200)
	assert_true(g.act(2, "all_in"))
	assert_eq(g.current_bet, 400)
	assert_eq(g.min_raise, 200, "the short all-in leaves the raise size alone")
	var l := g.legal(3)
	assert_true(l.raise, "D has not acted: he may raise")
	assert_eq(l.min_to, 600)
	g.act(3, "call")
	l = g.legal(0)
	assert_true(l.raise, "A acted at 100 and now faces 300 more - a full raise: he may raise")
	g.act(0, "call")
	l = g.legal(1)
	assert_eq(l.call, 100)
	assert_false(l.raise, "B raised to 300 and faces only 100 more: call or fold")
	assert_eq(l.all_in, 0, "and may not go all-in over it")
	assert_false(g.act(1, "raise", 600))
	assert_true(g.act(1, "call"))
	assert_eq(g.street, Holdem.TURN)


func test_short_all_ins_adding_up_to_a_full_raise_reopen_it() -> void:
	var g := _game([2000, 160, 220, 2000], 3)  # 150 and 210 left for the flop
	g.start_hand(6)  # button 3, SB 0, BB 1, seat 2 first
	g.act(2, "call")
	g.act(3, "call")
	g.act(0, "call")
	g.act(1, "check")
	g.act(0, "bet", 100)  # A bets 100
	g.act(1, "all_in")  # 140 more: to 150 - short of a full raise
	assert_eq(g.current_bet, 150)
	g.act(2, "all_in")  # to 210
	g.act(3, "call")
	var l := g.legal(0)
	assert_true(l.raise, "100 -> 210: 110 more, a full raise in all: A may raise again")
	var g2 := _game([2000, 160, 2000], 2)
	g2.start_hand(6)  # button 2, SB 0, BB 1, button first
	g2.act(2, "call")
	g2.act(0, "call")
	g2.act(1, "check")
	g2.act(0, "bet", 100)
	g2.act(1, "all_in")  # to 150: 50 more
	g2.act(2, "call")
	assert_false(g2.legal(0).raise, "only 50 more since he bet: call or fold")


func test_nobody_raises_into_all_ins() -> void:
	var g := _game([1000, 300], 0)
	g.start_hand(7)
	g.act(0, "raise", 40)
	g.act(1, "all_in")
	var l := g.legal(0)
	assert_eq(l.call, 260)
	assert_false(l.raise, "everyone else is all-in: no raising")
	g.act(0, "call")
	assert_eq(g.street, Holdem.OVER, "nobody left to bet: the board is dealt out")
	assert_eq(g.board.size(), 5)
	assert_true(g.shown)
	assert_eq(_total(g), 1300)


func test_a_bet_nobody_called_goes_back() -> void:
	var g := _game([1000, 1000, 1000], 0)
	g.start_hand(8)
	g.act(0, "raise", 60)
	g.act(1, "fold")
	g.act(2, "fold")
	assert_eq(g.street, Holdem.OVER)
	assert_false(g.shown, "taken without a showdown")
	assert_eq(g.seats[0].stack, 1015, "his raise back and the blinds won")
	assert_eq(g.seats[1].stack, 995)
	assert_eq(g.seats[2].stack, 990)
	assert_true(g.events.any(func(e: Dictionary) -> bool: return e.what == "returned" and e.amount == 50))
	assert_eq(_total(g), 3000)


func test_an_all_in_for_more_than_anyone_can_call() -> void:
	var g := _game([1000, 200], 0)
	g.start_hand(9)
	g.act(0, "all_in")
	g.act(1, "call")  # all-in for 200 in all
	assert_eq(g.street, Holdem.OVER)
	assert_true(g.events.any(func(e: Dictionary) -> bool: return e.what == "returned" and e.seat == 0 and e.amount == 800))
	assert_eq(_total(g), 1200)
	assert_true(g.seats[0].stack >= 800)


func test_side_pots_with_several_all_ins() -> void:
	# A 100, B 250, C 500 all-in; D covers them all
	var g := _game([100, 250, 500, 2000], 3)
	g.start_hand(10)  # button 3, SB 0 (A), BB 1 (B), C first
	# A the best hand, B the second best, C third, D worst
	_rig(g, ["Ah Ad", "Kh Kd", "Qh Qd", "7c 2s"], "As Kc Qs 3d 4h")
	g.act(2, "all_in")
	g.act(3, "call")
	g.act(0, "all_in")
	g.act(1, "all_in")
	assert_eq(g.street, Holdem.OVER)
	assert_eq(g.results.size(), 3, "a main pot and two side pots")
	assert_eq(g.results[0].amount, 400, "main: 100 from each of four")
	assert_eq(g.results[0].winners, [0])
	assert_eq(g.results[1].amount, 450, "first side pot: 150 from B, C and D")
	assert_eq(g.results[1].winners, [1])
	assert_eq(g.results[2].amount, 500, "second side pot: 250 from C and D")
	assert_eq(g.results[2].winners, [2])
	assert_eq(g.seats[0].stack, 400)
	assert_eq(g.seats[1].stack, 450)
	assert_eq(g.seats[2].stack, 500)
	assert_eq(g.seats[3].stack, 1500)
	assert_eq(_total(g), 2850)
	assert_true(g.results[0].hand.begins_with("three aces"))


func test_the_short_stack_wins_only_the_main_pot() -> void:
	var g := _game([100, 1000, 1000], 2)
	g.start_hand(11)  # button 2, SB 0, BB 1
	_rig(g, ["Ah Ad", "Kh Kd", "7c 2s"], "As 9c 8s 3d 4h")
	g.act(2, "raise", 300)
	g.act(0, "all_in")
	g.act(1, "call")
	assert_eq(g.street, Holdem.FLOP)
	g.act(1, "bet", 200)
	g.act(2, "fold")
	assert_eq(g.street, Holdem.OVER)
	assert_eq(g.seats[0].stack, 300, "the main pot: 100 x 3")
	assert_eq(g.seats[1].stack, 1000 - 300 + 400 + 0, "the side pot (200 + 200) and his last bet back")
	assert_eq(g.seats[2].stack, 700)
	assert_eq(_total(g), 2100)


func test_split_pot_and_the_odd_chip() -> void:
	# three in the pot, the board plays for two of them: 15 chips shared by two
	var g := _game([1000, 1000, 1000], 0)
	g.start_hand(12)  # button 0, SB 1, BB 2
	_rig(g, ["2c 3d", "2h 3s", "4c 5c"], "As Ks Qd Jc Td")
	g.act(0, "call")
	g.act(1, "call")
	g.act(2, "raise", 25)  # pot will be 25 x 3 = 75: 15 chips of 5
	g.act(0, "call")
	g.act(1, "call")
	for st in 3:
		g.act(g.to_act, "check")
		g.act(g.to_act, "check")
		g.act(g.to_act, "check")
	assert_eq(g.street, Holdem.OVER)
	assert_eq(g.results[0].winners.size(), 3, "Broadway on the board: everyone splits")
	assert_eq(g.seats[0].stack, 1000)
	var g2 := _game([1000, 1000, 1000], 2)
	g2.start_hand(13)  # button 2, SB 0, BB 1
	_rig(g2, ["Ah 3d", "Ad 4s", "7c 2s"], "Ks Kd 8c 8h 5c")
	g2.act(2, "call")
	g2.act(0, "call")
	g2.act(1, "raise", 25)
	g2.act(2, "call")
	g2.act(0, "call")
	for st in 3:
		g2.act(g2.to_act, "check")
		g2.act(g2.to_act, "check")
		g2.act(g2.to_act, "check")
	# 75 = 15 chips; two winners (seats 0 and 1, both ace-high two pair) get 7 chips each and one gets the odd chip
	assert_eq(g2.results[0].winners, [0, 1])
	assert_eq(g2.seats[0].stack, 1000 - 25 + 40, "the odd chip: first winner left of the button")
	assert_eq(g2.seats[1].stack, 1000 - 25 + 35)
	assert_eq(_total(g2), 3000)


func test_a_big_blind_short_of_the_blind() -> void:
	var g := _game([1000, 1000, 3], 0)
	g.start_hand(14)  # button 0, SB 1, BB 2 all-in for 3
	assert_true(g.seats[2].all_in)
	assert_eq(g.current_bet, 10, "the others still call the full big blind")
	assert_eq(g.legal(0).call, 10)
	g.act(0, "call")
	g.act(1, "call")
	assert_eq(g.street, Holdem.FLOP)
	var p := g.pots()
	assert_eq(p[0].amount, 9, "the main pot: 3 from each")
	assert_eq(p[1].amount, 14, "the rest between the other two")
	assert_eq(p[1].eligible, [0, 1])


func test_heads_up_short_blind_all_in() -> void:
	var g := _game([1000, 3], 0)
	g.start_hand(15)  # button 0 posts 5, BB all-in for 3
	assert_eq(g.street, Holdem.OVER, "nobody can bet: dealt out at once")
	assert_eq(_total(g), 1003)


func test_joining_leaving_and_busting() -> void:
	var g := _game([1000, 1000], 0)
	assert_eq(g.sit("Late", 500), 2, "a player joins between hands")
	g.start_hand(16)
	assert_eq(g.sit("Too late", 500), -1, "not in the middle of a hand")
	assert_eq(g.leave(0), 0, "nor does anyone leave with his chips mid-hand")
	g.fold_out(g.to_act)
	g.fold_out(g.to_act)
	assert_eq(g.street, Holdem.OVER, "two folded out: the third takes it")
	var g2 := _game([1000, 100], 0)
	g2.start_hand(17)
	_rig(g2, ["Ah Ad", "7c 2s"], "As 9c 8s 3d 4h")
	g2.act(0, "all_in")
	g2.act(1, "call")
	assert_true(g2.seats[1].busted, "out of chips: bust")
	assert_true(g2.seats[1].out)
	assert_false(g2.can_start(), "one player left: no game")
	assert_eq(g2.leave(0), 1100, "he cashes out everything")
	assert_eq(g2.total_chips(), 0)


func test_folding_out_of_turn_when_leaving() -> void:
	var g := _game([1000, 1000, 1000, 1000], 0)
	g.start_hand(18)  # button 0, SB 1, BB 2, seat 3 first
	g.fold_out(1)
	assert_eq(g.to_act, 3, "still seat 3's turn")
	g.act(3, "call")
	g.act(0, "call")
	assert_eq(g.to_act, 2)
	g.act(2, "check")
	assert_eq(g.street, Holdem.FLOP)
	assert_eq(g.contenders(), [0, 2, 3])
	assert_eq(_total(g), 4000)


func test_never_a_chip_made_or_lost() -> void:
	# hundreds of hands of random legal play: the chips always add up, nobody goes below zero, every hand ends
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var hands := 0
	for table in 30:
		var g := _game([500, 800, 300, 1200, 650].slice(0, 2 + table % 4))
		var start := _total(g)
		var played := 0
		while played < 25 and g.can_start():
			g.start_hand(rng.randi())
			played += 1
			hands += 1
			var steps := 0
			while g.running():
				steps += 1
				assert_lt(steps, 200, "the hand ends")
				if steps >= 200:
					return
				var i := g.to_act
				var l := g.legal(i)
				var r := rng.randf()
				var ok := false
				if r < 0.15:
					ok = g.act(i, "fold")
				elif r < 0.6:
					ok = g.act(i, "check") if l.check else g.act(i, "call")
				elif r < 0.95 and (l.bet or l.raise):
					var to := rng.randi_range(l.min_to / 5, mini(l.max_to, l.min_to * 3) / 5) * 5
					ok = g.act(i, "bet" if l.bet else "raise", maxi(to, l.min_to))
				else:
					ok = g.act(i, "all_in") if l.all_in > 0 else g.act(i, "fold")
				assert_true(ok, "a legal action is taken")
				assert_eq(_total(g), start, "chips conserved mid-hand")
			for s in g.seats:
				assert_true(s.stack >= 0)
				assert_eq(s.stack % 5, 0, "whole chips")
			assert_eq(_total(g), start, "chips conserved after the hand")
	assert_gt(hands, 300)
