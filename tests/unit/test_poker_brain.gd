extends GutTest
## M010 the card players' decisions: a fair estimate of their chances, always
## a legal action, strong hands bet and weak ones fold to a raise, the three
## styles play differently over many hands, the same seed decides the same,
## and a decision is cheap enough for the game.


func _rng(seed: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	return r


func test_equity() -> void:
	var aces := PokerBrain.equity(Cards.parse_all("Ah Ad"), [], 1, _rng(1), 400)
	assert_between(aces, 0.78, 0.92, "pocket aces against one hand: about 85%")
	var trash := PokerBrain.equity(Cards.parse_all("7c 2d"), [], 1, _rng(2), 400)
	assert_between(trash, 0.25, 0.42, "seven-deuce: about 35%")
	var nuts := PokerBrain.equity(Cards.parse_all("Ah Kh"), Cards.parse_all("Qh Jh Th 2c 3d"), 3, _rng(3), 100)
	assert_eq(nuts, 1.0, "a royal flush cannot lose")
	var dead := PokerBrain.equity(Cards.parse_all("7c 2d"), Cards.parse_all("Ah Ad Ac Ks Kd"), 1, _rng(4), 200)
	assert_between(dead, 0.4, 0.5, "the board's full house: he can only split (or lose to an ace)")


func test_always_legal_and_deterministic() -> void:
	var rng := _rng(11)
	for style in PokerBrain.STYLES:
		var g := Holdem.new()
		for i in 4:
			g.sit("P%d" % i, 600)
		var hands := 0
		while hands < 15 and g.can_start():
			g.start_hand(rng.randi())
			hands += 1
			var steps := 0
			while g.running() and steps < 100:
				steps += 1
				var d := PokerBrain.decide(g, g.to_act, style, rng)
				assert_true(g.act(g.to_act, d.kind, d.to), "%s plays legally: %s" % [style, d])
		assert_eq(g.total_chips(), 2400)
	var g1 := Holdem.new()
	g1.sit("A", 500)
	g1.sit("B", 500)
	g1.start_hand(5)
	assert_eq(PokerBrain.decide(g1, g1.to_act, "loose", _rng(9)), PokerBrain.decide(g1, g1.to_act, "loose", _rng(9)),
		"the same seed, the same decision")


func _facing_a_raise(hole: String, style: String, seed: int) -> String:
	var g := Holdem.new()
	g.sit("Raiser", 1000)
	g.sit("Thinker", 1000)
	g.sit("BB", 1000)
	g.button = 2
	g.start_hand(seed)  # button 0, SB 1, BB 2
	g.seats[1].hole = Cards.parse_all(hole)
	g.act(0, "raise", 60)
	return PokerBrain.decide(g, 1, style, _rng(seed)).kind


func test_strong_hands_bet_weak_ones_fold() -> void:
	for style in PokerBrain.STYLES:
		var kind := _facing_a_raise("Ah As", style, 21)
		assert_true(kind == "raise" or kind == "all_in", "%s re-raises with aces (%s)" % [style, kind])
	assert_eq(_facing_a_raise("7c 2d", "cautious", 22), "fold", "the cautious man folds seven-deuce to a raise")
	assert_eq(_facing_a_raise("8c 3d", "aggressive", 23), "fold", "so does the aggressive one, without a bluff")


func test_the_styles_play_differently() -> void:
	var played := {}
	var raised := {}
	for style in PokerBrain.STYLES:
		played[style] = 0
		raised[style] = 0
		var rng := _rng(77)
		for h in 120:
			var g := Holdem.new()
			for i in 4:
				g.sit("P%d" % i, 1000)
			g.button = 0
			g.start_hand(rng.randi())  # button 1, SB 2, BB 3: seat 0 under the gun
			var d := PokerBrain.decide(g, 0, style, rng)
			if d.kind != "fold":
				played[style] += 1
			if d.kind == "raise" or d.kind == "all_in":
				raised[style] += 1
	assert_gt(played.loose, played.cautious + 15, "the loose man plays far more hands (%s)" % [played])
	assert_gt(raised.aggressive, raised.cautious, "the aggressive man raises more (%s)" % [raised])
	assert_gt(raised.aggressive, raised.loose)
	assert_between(played.cautious, 10, 60, "the cautious man plays the few good ones")


func test_a_decision_is_cheap() -> void:
	var g := Holdem.new()
	for i in 4:
		g.sit("P%d" % i, 1000)
	g.start_hand(3)
	var rng := _rng(5)
	var t0 := Time.get_ticks_usec()
	for k in 10:
		PokerBrain.decide(g, g.to_act, "aggressive", rng)
	var ms := (Time.get_ticks_usec() - t0) / 10000.0
	gut.p("a four-handed pre-flop decision: %.2f ms" % ms)
	assert_lt(ms, 40.0, "well under a few frames (taken while he 'thinks')")
