extends GutTest
## M010 the back-room game's books: buy-in limits, every cent accounted for
## from sitting down to getting up (mid-hand too), players going bust and home,
## the late man taking a free chair once, closing time, an unfinished hand
## void in the save, and the same night playing out the same way.


func _night() -> PokerNight:
	var n := PokerNight.new()
	n.begin_night(1)
	return n


## Plays hands with Danny following the card players' own judgement (as a loose player).
func _play(n: PokerNight, money: Array, books: int, hands: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for h in hands:
		if not n.next_hand():
			return
		var guard := 0
		while n.table.running() and guard < 300:
			guard += 1
			if n.ai_to_act():
				n.ai_turn()
			else:
				var d := PokerBrain.decide(n.table, n.danny, "loose", rng)
				assert_true(n.danny_acts(d.kind, d.to))
			assert_eq(money[0] + n.danny_chips() + n.players_money(), books, "the books balance mid-hand")


func test_buy_in_limits() -> void:
	var n := _night()
	assert_eq(n.cannot_sit(150), "The game's a two-dollar buy-in. You haven't got it.")
	assert_eq(n.buy_in_choices(650), [200, 500] as Array[int])
	assert_false(n.sit_down(1500, 2000), "over the table limit")
	assert_false(n.sit_down(500, 300), "more than he has")
	assert_false(n.sit_down(203, 1000), "whole chips")
	assert_true(n.sit_down(500, 1200))
	assert_eq(n.table.seats.size(), 4, "Danny and the three regulars")
	assert_false(n.sit_down(200, 1200), "already sitting")


func test_every_cent_accounted_for() -> void:
	var n := _night()
	var money := [1200]
	var books: int = money[0] + n.players_money()
	assert_true(n.sit_down(500, money[0]))
	money[0] -= 500
	assert_eq(money[0] + n.danny_chips() + n.players_money(), books)
	_play(n, money, books, 25)
	money[0] += n.leave()
	assert_false(n.seated())
	assert_eq(money[0] + n.players_money(), books, "after he gets up: not a cent made or lost")
	assert_eq(n.net, money[0] - 1200, "his winnings remembered")


func test_leaving_mid_hand() -> void:
	var n := _night()
	var money := [1000]
	var books: int = money[0] + n.players_money()
	n.sit_down(1000, money[0])
	money[0] -= 1000
	assert_true(n.next_hand())
	while n.ai_to_act():
		n.ai_turn()
	assert_true(n.table.running())
	var in_pot: int = n.table.seats[n.danny].total
	var chips := n.leave()
	money[0] += chips
	assert_eq(chips, 1000 - in_pot, "he folds: what he put in stays in the pot")
	assert_eq(money[0] + n.players_money(), books, "the others play the hand out between them")


func test_saved_mid_hand_the_hand_is_void() -> void:
	var n := _night()
	n.sit_down(500, 1000)
	assert_eq(n.stake_for_save(), 500)
	n.next_hand()
	assert_true(n.table.running())
	assert_eq(n.stake_for_save(), 500, "an unfinished hand counts for nothing")
	while n.table.running():
		if n.ai_to_act():
			n.ai_turn()
		else:
			n.danny_acts("fold")
	assert_eq(n.stake_for_save(), n.table.seats[n.danny].stack, "between hands: what is in front of him")


func test_bust_the_late_man_and_closing_time() -> void:
	var n := _night()
	n.sit_down(1000, 1000)
	# Red loses everything to the table
	n.table.seats[2].stack = 0
	n.table.seats[2].out = true
	n.table.seats[2].busted = true
	n.table.seats[0].stack += 500
	assert_true(n.next_hand())
	assert_eq(n.gone.get("red", ""), "bust", "cleaned out: gone home")
	assert_true(n.late_joined, "a chair came free: Moe pulls it up")
	assert_eq(n.table.seats[2].id, "moe")
	assert_true(n.table.seats[2].in_hand)
	while n.table.running():
		if n.ai_to_act():
			n.ai_turn()
		else:
			n.danny_acts("fold")
	n.closing = true
	assert_false(n.next_hand(), "closing time: no more hands")
	n.leave()
	assert_eq(n.cannot_sit(5000), "The game's breaking up for the night.")
	n.begin_night(2)
	assert_eq(n.cannot_sit(5000), "", "the next night they are all back, with fresh money")
	assert_eq(n.purses.red, 500)


func test_danny_cleaned_out() -> void:
	var n := _night()
	var money := [200]
	n.sit_down(200, money[0])
	money[0] -= 200
	var books: int = money[0] + n.danny_chips() + n.players_money()
	var guard := 0
	while n.next_hand() and guard < 200:
		guard += 1
		while n.table.running():
			if n.ai_to_act():
				n.ai_turn()
			else:
				n.danny_acts("all_in") if n.table.legal(n.danny).all_in > 0 else n.danny_acts("call")
	assert_true(n.table.seats[n.danny].out or n.players_tonight().is_empty() or guard >= 200,
		"he shoves every hand until he is cleaned out (or cleans them out)")
	money[0] += n.leave()
	assert_eq(money[0] + n.players_money(), books)


func test_the_same_night_plays_the_same() -> void:
	var results := []
	for k in 2:
		var n := _night()
		var money := [1000]
		var books: int = money[0] + n.players_money()
		n.sit_down(500, 1000)
		money[0] -= 500
		_play(n, money, books, 6)
		results.append(n.danny_chips())
	assert_eq(results[0], results[1])
