extends GutTest
## M015 (PokerShowdown, pure): the card table marks the community cards just
## dealt while their beat waits (the three of the flop, the turn, the river),
## and at the showdown every hand still in - never a folded one - with its best
## five cards and the hand's name: the winners' strongly (both in a split pot),
## a loser's subtly; a board card in a winner's five is a winner's mark.


func _game(stacks: Array, button: int) -> Holdem:
	var g := Holdem.new(5, 10, 5)
	var ids := ["danny", "irv", "red", "pete"]
	for i in stacks.size():
		g.sit("P%d" % i, stacks[i], {"id": ids[i]})
	g.button = (button - 1 + stacks.size()) % stacks.size()
	return g


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


## Everyone checks (or calls) to the river.
func _play_out(g: Holdem) -> void:
	for guard in 60:
		if not g.running():
			return
		var l := g.legal(g.to_act)
		g.act(g.to_act, "check" if l.check else "call")


func test_the_cards_just_dealt() -> void:
	assert_eq(PokerShowdown.fresh_board({"kind": "deal", "street": Holdem.FLOP, "cards": [1, 2, 3], "shown": 3}), [0, 1, 2] as Array[int], "the flop's three")
	assert_eq(PokerShowdown.fresh_board({"kind": "deal", "street": Holdem.TURN, "cards": [4], "shown": 4}), [3] as Array[int], "the turn")
	assert_eq(PokerShowdown.fresh_board({"kind": "deal", "street": Holdem.RIVER, "cards": [5], "shown": 5}), [4] as Array[int], "the river")
	assert_eq(PokerShowdown.fresh_board({"kind": "action", "seat": 1}), [] as Array[int], "nothing for an action")
	assert_eq(PokerShowdown.fresh_board({}), [] as Array[int])


func test_the_showdown_winner_loser_and_folded() -> void:
	var g := _game([1000, 1000, 1000], 0)
	g.start_hand(1)
	_rig(g, ["Ah Ad", "Kh Kd", "7c 2s"], "As 9c 8s 3d 4h")
	# seat 2 (7c 2s) folds at once; the others see the river
	for guard in 60:
		if not g.running():
			break
		var l := g.legal(g.to_act)
		if g.to_act == 2:
			g.act(2, "fold")
		else:
			g.act(g.to_act, "check" if l.check else "call")
	assert_true(g.shown, "a showdown")
	var h := PokerShowdown.hands(g)
	assert_eq(h.keys().size(), 2, "the two hands still in")
	assert_false(h.has(2), "a folded hand is never shown")
	assert_true(bool(h[0].winner), "three aces win")
	assert_eq(String(h[0].name), HandRank.describe(HandRank.score(Cards.parse_all("Ah Ad As 9c 8s 3d 4h"))))
	assert_string_contains(String(h[0].name), "three")
	assert_false(bool(h[1].winner))
	assert_eq((h[0].five as Array).size(), 5)
	# the winner's own cards and the board's ace: gold; the loser's kings: the fine line
	assert_eq(PokerShowdown.card_mark(Cards.parse_all("Ah")[0], h, 0), PokerShowdown.WIN)
	assert_eq(PokerShowdown.card_mark(Cards.parse_all("Kh")[0], h, 1), PokerShowdown.BEST)
	var marks := PokerShowdown.board_marks(g, h)
	assert_eq(marks[0], PokerShowdown.WIN, "the ace of spades plays for the winner")
	assert_eq(marks.size(), 5)
	for k in 5:
		var in_winner := g.board[k] in (h[0].five as Array)
		assert_eq(marks[k] == PokerShowdown.WIN, in_winner, "board card %d marked as the winner's only if it is in his five" % k)


func test_a_split_pot_marks_every_winner() -> void:
	var g := _game([1000, 1000, 1000], 0)
	g.start_hand(12)
	_rig(g, ["2c 3d", "2h 3s", "4c 5c"], "As Ks Qd Jc Td")
	_play_out(g)
	var h := PokerShowdown.hands(g)
	assert_eq(h.size(), 3)
	for i in 3:
		assert_true(bool(h[i].winner), "Broadway on the board: seat %d wins a share" % i)
	for m in PokerShowdown.board_marks(g, h):
		assert_eq(m, PokerShowdown.WIN, "the board is everyone's winning five")


func test_no_showdown_nothing_shown() -> void:
	var g := _game([1000, 1000], 0)
	g.start_hand(3)
	g.act(g.to_act, "fold")
	assert_false(g.running())
	assert_eq(PokerShowdown.hands(g), {}, "won without a showdown: no hands shown")
