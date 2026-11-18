extends GutTest
## M010 poker hands: every ranking recognised and in order, kickers, the
## wheel and Broadway, no wrap-around, the best five of seven, suits never
## break a tie, the hand named as the table says it.


func _s(cards: String) -> int:
	return HandRank.score(Cards.parse_all(cards))


func _cat(cards: String) -> int:
	return HandRank.category(_s(cards))


func test_cards() -> void:
	assert_eq(Cards.code(Cards.parse("As")), "As")
	assert_eq(Cards.rank(Cards.parse("Td")), 8)
	assert_eq(Cards.suit(Cards.parse("Td")), 2)
	assert_eq(Cards.spoken(Cards.parse("Qh")), "the queen of hearts")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var deck := Cards.shuffled(rng)
	assert_eq(deck.size(), 52)
	var seen := {}
	for c in deck:
		seen[c] = true
	assert_eq(seen.size(), 52, "every card once")
	rng.seed = 7
	assert_eq(Cards.shuffled(rng), deck, "the same seed, the same deck")


func test_every_ranking() -> void:
	assert_eq(_cat("2c 7d 9h Js Kd 3c 4h"), HandRank.HIGH_CARD)
	assert_eq(_cat("2c 2d 9h Js Kd 3c 4h"), HandRank.PAIR)
	assert_eq(_cat("2c 2d 9h 9s Kd 3c 4h"), HandRank.TWO_PAIR)
	assert_eq(_cat("2c 2d 2h 9s Kd 3c 4h"), HandRank.TRIPS)
	assert_eq(_cat("5c 6d 7h 8s 9d Kc 2h"), HandRank.STRAIGHT)
	assert_eq(_cat("2h 7h 9h Jh Kh 3c 4d"), HandRank.FLUSH)
	assert_eq(_cat("2c 2d 2h 9s 9d 3c 4h"), HandRank.FULL_HOUSE)
	assert_eq(_cat("2c 2d 2h 2s 9d 3c 4h"), HandRank.QUADS)
	assert_eq(_cat("5h 6h 7h 8h 9h Kc 2d"), HandRank.STRAIGHT_FLUSH)
	var order := ["2c 7d 9h Js Kd 3c 4h", "2c 2d 9h Js Kd 3c 4h", "2c 2d 9h 9s Kd 3c 4h", "2c 2d 2h 9s Kd 3c 4h",
		"5c 6d 7h 8s 9d Kc 2h", "2h 7h 9h Jh Kh 3c 4d", "2c 2d 2h 9s 9d 3c 4h", "2c 2d 2h 2s 9d 3c 4h",
		"5h 6h 7h 8h 9h Kc 2d"]
	for i in order.size() - 1:
		assert_lt(_s(order[i]), _s(order[i + 1]), "%s beaten by %s" % [order[i], order[i + 1]])
	# the lowest of a category beats the highest of the one below
	assert_gt(_s("2c 2d 3h 4s 5d"), _s("Ac Kd Qh Js 9d"), "a pair of deuces beats ace high")
	assert_gt(_s("Ah 2h 3d 4c 5s"), _s("Ac Ad Ah Ks Qd"), "the wheel beats three aces")
	assert_gt(_s("2h 3h 4h 5h 7h"), _s("Tc Jd Qh Ks Ad"), "a seven-high flush beats Broadway")


func test_straights() -> void:
	assert_eq(HandRank.ranks_of(_s("Ah 2c 3d 4s 5h 9c Jd"))[0], 3, "the wheel is five-high")
	assert_lt(_s("Ah 2c 3d 4s 5h"), _s("2c 3d 4s 5h 6d"), "the wheel is the lowest straight")
	assert_eq(HandRank.ranks_of(_s("Tc Jd Qh Ks Ad"))[0], 12, "Broadway is ace-high")
	assert_eq(_cat("Qc Kd Ah 2s 3d"), HandRank.HIGH_CARD, "no wrapping round the ace")
	assert_eq(HandRank.ranks_of(_s("4c 5d 6h 7s 8d 9c Tc"))[0], 8, "the highest straight of seven")
	assert_eq(_s("Ah Kh Qh Jh Th 9h 8h"), _s("Ah Kh Qh Jh Th"))
	assert_eq(HandRank.describe(_s("Ah Kh Qh Jh Th")), "a royal flush")
	assert_eq(HandRank.describe(_s("Ad 2d 3d 4d 5d")), "a straight flush, five high")
	assert_eq(_cat("Ah 2h 3h 4h 5c 6c 9h"), HandRank.FLUSH, "a flush and a straight in different suits is a flush")


func test_kickers_and_the_best_five() -> void:
	assert_gt(_s("Ac Ad Kh 7s 3d"), _s("Ah As Qh Js Td"), "a pair of aces, king kicker")
	assert_gt(_s("Kc Kd 7h 7s 9d"), _s("Kh Ks 7d 7c 8d"), "two pair, the kicker decides")
	assert_gt(_s("Kc Kd 7h 7s 2d 2c 9d"), _s("Kh Ks 7d 7c 2h 2s 8d"), "the third pair counts only as a kicker")
	assert_eq(HandRank.ranks_of(_s("Kc Kd 7h 7s 2d 2c 9d")), [11, 5, 7, 0, 0])
	assert_gt(_s("9c 9d 9h As 2d"), _s("9s 9d 9h Ks Qd"), "trips: the kickers")
	assert_eq(HandRank.ranks_of(_s("Qc Qd Qh 2s 2d 2c 9d")).slice(0, 2), [10, 0], "two trips: queens full of deuces")
	assert_eq(HandRank.ranks_of(_s("Qc Qd Qh 2s 2d 9c 9d")).slice(0, 2), [10, 7], "queens full of the higher pair")
	assert_eq(HandRank.ranks_of(_s("8c 8d 8h 8s Ad Kc 2d")).slice(0, 2), [6, 12], "quads with the best kicker")
	assert_gt(_s("Ah 9h 7h 5h 3h"), _s("Kh Qh Jh 9h 7h"))
	assert_gt(_s("Ah 9h 7h 5h 4h"), _s("Ah 9h 7h 5h 3h"), "a flush: every card counts")
	# the board plays: two players tie whatever their low cards
	var board := "As Ks Qd Jc Td"
	assert_eq(_s(board + " 2c 3d"), _s(board + " 4h 5h"), "the board plays: a split")
	assert_eq(_s("Ah Kd 7c 5s 2d"), _s("As Kc 7d 5h 2c"), "suits never break a tie")


func test_seven_cards_are_the_best_of_twenty_one() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for deal in 250:
		var deck := Cards.shuffled(rng)
		var seven: Array[int] = []
		seven.assign(deck.slice(0, 7))
		var best := -1
		for a in 7:
			for b in range(a + 1, 7):
				var five: Array[int] = []
				for k in 7:
					if k != a and k != b:
						five.append(seven[k])
				best = maxi(best, HandRank.score(five))
		assert_eq(HandRank.score(seven), best)
		var used := HandRank.best_five(seven)
		assert_eq(used.size(), 5)
		assert_eq(HandRank.score(used), best, "the five cards shown make the hand")


func test_hands_named() -> void:
	assert_eq(HandRank.describe(_s("Jc Jd 9h 4s 2d")), "a pair of jacks")
	assert_eq(HandRank.describe(_s("Kc Kd 7h 7s 2d")), "two pair, kings and sevens")
	assert_eq(HandRank.describe(_s("6c 6d 6h Ks 2d")), "three sixes")
	assert_eq(HandRank.describe(_s("Ac 2d 3h 4s 5d")), "a straight, five high")
	assert_eq(HandRank.describe(_s("Ah 9h 7h 5h 3h")), "a flush, ace high")
	assert_eq(HandRank.describe(_s("Tc Td Th 4s 4d")), "a full house, tens over fours")
	assert_eq(HandRank.describe(_s("8c 8d 8h 8s 2d")), "four eights")
	assert_eq(HandRank.describe(_s("Ac Jd 9h 4s 2d")), "ace high")
