extends GutTest
## M013 Leo's wheel (RouletteTable, pure): rounds run on their own - bets
## open, the ball sent round with bets still open, "last bets", "no more
## bets" (the number drawn then, fairly, once), the ball at rest and Danny paid
## once, a pause, the next round; the call waits while Danny is still putting
## chips down, but never past a fixed limit; a man may only watch; walking
## away, saving and the night's end never pay twice or lose a cent; the
## number does not depend on Danny's bets, his timing or the animation.

var rules := RouletteRules.new()


func _table(seed := 1) -> RouletteTable:
	return RouletteTable.new(rules, Roulette.new(rules), seed)


func _round_length() -> float:
	return rules.open_seconds + rules.ball_seconds + rules.drop_seconds + rules.result_seconds


## Runs the table frame by frame for `seconds`; returns its events.
func _run(t: RouletteTable, seconds: float, dt := 1.0 / 60.0) -> Array:
	var out := []
	var left := seconds
	while left > 0.0:
		out += t.advance(minf(dt, left))
		left -= dt
	return out


func _names(events: Array) -> Array:
	return events.map(func(e: Dictionary) -> String: return e.event)


func test_rounds_run_on_their_own() -> void:
	var t := _table()
	assert_eq(t.phase, RouletteTable.Phase.OPEN, "bets open as the table starts")
	assert_true(t.betting_open())
	var events := _run(t, _round_length() * 3 + 0.5)
	assert_eq(_names(events).slice(0, 7), ["ball", "last_call", "no_more_bets", "rest", "round_over", "open", "ball"],
		"a round's course, then the next")
	assert_eq(_names(events).count("rest"), 3, "three rounds, each to rest once")
	assert_eq(t.rounds, 4)
	assert_eq(t.danny.history.size(), 3, "every number on the board, though nobody bet")
	for e in events:
		if e.event == "rest":
			assert_false(e.played)
			assert_eq(e.paid, 0)


func test_bets_only_while_open() -> void:
	var t := _table()
	_run(t, rules.open_seconds + 1.0)
	assert_eq(t.phase, RouletteTable.Phase.BALL)
	assert_true(t.betting_open(), "still open with the ball going round")
	_run(t, rules.ball_seconds)
	assert_eq(t.phase, RouletteTable.Phase.DROP)
	assert_false(t.betting_open(), "no more bets")
	_run(t, rules.drop_seconds)
	assert_eq(t.phase, RouletteTable.Phase.RESULT)
	assert_false(t.betting_open())


func test_the_number_is_drawn_at_the_call_and_not_before() -> void:
	var t := _table(5)
	_run(t, rules.open_seconds + rules.ball_seconds - 0.1)
	assert_eq(t.number, -1, "nothing decided while bets are open")
	_run(t, 0.2)
	assert_between(t.number, 0, 36, "drawn at the call")
	var n := t.number
	_run(t, rules.drop_seconds + 0.1)
	assert_eq(t.motion.pocket_under(), n, "the ball rests in that pocket")
	assert_eq(t.danny.history[0], n)


func test_the_call_waits_on_danny_but_not_for_ever() -> void:
	var usual := rules.open_seconds + rules.ball_seconds
	# no chips touched: the usual moment
	var t := _table()
	_run(t, usual - 0.05)
	assert_true(t.betting_open())
	_run(t, 0.1)
	assert_false(t.betting_open(), "called on time")
	# a chip early in the round: no waiting
	t = _table()
	_run(t, 2.0)
	t.touch()
	assert_eq(t.close_time(), usual)
	# a chip just before the call: Leo waits until Danny has left it alone a while
	t = _table()
	_run(t, usual - 0.5)
	t.touch()
	assert_almost_eq(t.close_time(), usual - 0.5 + rules.grace_seconds, 0.01)
	_run(t, rules.grace_seconds - 0.2)
	assert_true(t.betting_open(), "still open: he was busy at the layout")
	_run(t, 0.4)
	assert_false(t.betting_open(), "called once he stopped")
	# chips put down again and again: never past the limit
	t = _table()
	_run(t, usual - 0.5)
	var events := []
	for i in 40:
		if not t.betting_open():
			break
		t.touch()
		events += _run(t, 0.5)
	assert_false(t.betting_open())
	assert_eq(t.phase, RouletteTable.Phase.DROP)
	assert_lte(t.close_time(), usual + rules.max_extension + 0.001, "a fixed limit")
	assert_almost_eq(t.close_time(), usual + rules.max_extension, 0.01, "called at the limit though he kept at it")
	assert_almost_eq(t.round_time, usual + rules.max_extension, 0.5)
	assert_eq(_names(events).count("no_more_bets"), 1)


func test_last_bets_are_called_before_no_more_bets() -> void:
	var t := _table()
	var events := _run(t, rules.open_seconds + rules.ball_seconds + 0.5)
	var names := _names(events)
	assert_lt(names.find("last_call"), names.find("no_more_bets"))


func test_danny_paid_once_to_the_cent() -> void:
	var t := _table(11)
	var money := 1000
	money -= t.danny.place("red", 100, money)
	money -= t.danny.place("straight:17", 25, money)
	money -= t.danny.place("dozen:1", 25, money)
	money -= t.danny.place("dozen:1", 25, money)
	t.touch()
	var events := _run(t, _round_length() + 0.2)
	var rests := events.filter(func(e: Dictionary) -> bool: return e.event == "rest")
	assert_eq(rests.size(), 1)
	var n: int = rests[0].number
	var expect := Roulette.returns("red", 100, n) + Roulette.returns("straight:17", 25, n) + Roulette.returns("dozen:1", 50, n)
	assert_eq(money, 1000 - 175, "every chip taken once")
	assert_true(rests[0].played)
	assert_eq(rests[0].paid, expect, "exactly what the number pays")
	money += int(rests[0].paid)
	assert_eq(t.danny.settle(), 0, "never a second time")
	assert_eq(money, 1000 - 175 + expect)
	assert_true(t.danny.bets.is_empty(), "the layout cleared for the next round")
	assert_eq(t.danny.phase, Roulette.Phase.BETTING)


func test_watching_without_betting() -> void:
	var t := _table(3)
	var events := _run(t, _round_length() * 5)
	for e in events.filter(func(x: Dictionary) -> bool: return x.event == "rest"):
		assert_false(e.played, "a man may watch")
		assert_eq(e.paid, 0)
	assert_eq(t.danny.history.size(), 5)


func test_the_number_owes_nothing_to_danny_or_the_timing() -> void:
	# two tables from the same draw: one Danny plays hard at, putting the call
	# off every round; the other nobody touches - the same numbers come up
	var a := _table(42)
	var b := _table(42)
	var numbers_a := []
	var numbers_b := []
	var money := 100000
	for r in 30:
		money -= a.danny.place("straight:%d" % (r % 37), 50, money)
		money -= a.danny.place("red" if r % 2 else "black", 500, money)
		var guard := 0
		while a.betting_open() and guard < 2000:
			if a.round_time > a.rules.open_seconds + a.rules.ball_seconds - 1.0:
				a.touch()
			for e in a.advance(1.0 / 30.0):
				if e.event == "rest":
					numbers_a.append(e.number)
			guard += 1
		for e in _run(a, rules.drop_seconds + rules.result_seconds + 0.1, 1.0 / 30.0):
			if e.event == "rest":
				numbers_a.append(e.number)
				money += int(e.paid)
	for e in _run(b, _round_length() * 30 + 1.0, 1.0 / 45.0):
		if e.event == "rest":
			numbers_b.append(e.number)
	assert_eq(numbers_a.size(), 30)
	assert_eq(numbers_a, numbers_b.slice(0, 30), "the same draw, whatever Danny did or when the call came")


func test_the_draw_is_fair() -> void:
	var counts := {}
	var t := _table(2024)
	# whole rounds at a time (the round's length makes no difference to the draw)
	for e in _run(t, _round_length() * 7400 + 1.0, 2.0):
		if e.event == "rest":
			counts[e.number] = int(counts.get(e.number, 0)) + 1
	var total := 0
	for n in counts:
		total += int(counts[n])
	assert_eq(counts.size(), 37, "every pocket comes up")
	var chi := 0.0
	var expect := total / 37.0
	for n in 37:
		chi += pow(float(counts.get(n, 0)) - expect, 2) / expect
	assert_lt(chi, 70.0, "chi-square for 36 degrees of freedom well inside chance (%.1f over %d spins)" % [chi, total])


func test_the_zero_takes_the_outside_bets() -> void:
	var seed := 0
	while true:  # a draw whose first number is the zero
		var probe := RandomNumberGenerator.new()
		probe.seed = seed
		if probe.randi_range(0, 36) == 0:
			break
		seed += 1
	var t := _table(seed)
	var money := 1000
	for k in ["red", "black", "odd", "even", "low", "high", "dozen:1", "column:3"]:
		money -= t.danny.place(k, 25, money)
	money -= t.danny.place("straight:0", 10, money)
	var rest: Dictionary = _run(t, _round_length()).filter(func(e: Dictionary) -> bool: return e.event == "rest")[0]
	assert_eq(rest.number, 0)
	assert_eq(rest.paid, 360, "only the zero itself pays (35 to 1); every outside bet is lost")


func test_saving_in_every_phase() -> void:
	var t := _table(9)
	var money := 500
	money -= t.danny.place("red", 100, money)
	assert_eq(money + t.danny.for_save(), 500, "bets open: the chips are still his")
	_run(t, rules.open_seconds + 1.0)
	assert_eq(money + t.danny.for_save(), 500, "the ball going round, bets open: still his")
	_run(t, rules.ball_seconds)
	assert_eq(t.phase, RouletteTable.Phase.DROP)
	var won := Roulette.returns("red", 100, t.number)
	assert_eq(money + t.danny.for_save(), 400 + won, "no more bets: the number is decided, counted as settled")
	var events := _run(t, rules.drop_seconds + 0.1)
	money += int(events.filter(func(e: Dictionary) -> bool: return e.event == "rest")[0].paid)
	assert_eq(money + t.danny.for_save(), 400 + won, "at rest: paid, nothing more owed")
	_run(t, rules.result_seconds)
	assert_eq(money + t.danny.for_save(), 400 + won, "a new round, nothing on it")


func test_walking_away_mid_drop_is_settled_once() -> void:
	var t := _table(13)
	var money := 300
	money -= t.danny.place("black", 100, money)
	_run(t, rules.open_seconds + rules.ball_seconds + 0.5)
	assert_eq(t.phase, RouletteTable.Phase.DROP)
	var n := t.number
	var owed := Roulette.returns("black", 100, n)
	money += t.danny.walk_away()
	t.left()
	assert_eq(money, 200 + owed, "settled as he walks away")
	var events := _run(t, rules.drop_seconds + rules.result_seconds)
	var rest: Dictionary = events.filter(func(e: Dictionary) -> bool: return e.event == "rest")[0]
	assert_false(rest.played, "nothing of his left on it")
	assert_eq(rest.paid, 0, "and nothing paid twice")
	assert_eq(rest.number, n)
	assert_eq(t.danny.history[0], n)
	assert_eq(t.danny.history.size(), 1, "the number on the board once")


func test_walking_away_with_bets_open_gives_the_chips_back() -> void:
	var t := _table()
	var money := 300
	money -= t.danny.place("odd", 25, money)
	t.touch()
	money += t.danny.walk_away()
	t.left()
	assert_eq(money, 300)
	assert_eq(t.close_time(), rules.open_seconds + rules.ball_seconds, "Leo no longer waits on him")


func test_the_last_round_of_the_night() -> void:
	var t := _table(4)
	var money := 200
	_run(t, 2.0)
	money -= t.danny.place("even", 25, money)
	money -= t.danny.place("even", 25, money)
	t.closing = true  # four o'clock strikes mid-round
	var events := _run(t, _round_length() * 3)
	var names := _names(events)
	assert_eq(names.count("rest"), 1, "the round under way is played out")
	assert_eq(names.count("open"), 0, "no new round")
	assert_has(names, "closed")
	assert_eq(t.phase, RouletteTable.Phase.CLOSED)
	var last: Dictionary = events.filter(func(e: Dictionary) -> bool: return e.event == "rest")[0]
	money += int(last.paid)
	assert_eq(money + t.danny.for_save(), 150 + Roulette.returns("even", 50, int(last.number)), "his wager resolved")
	assert_true(_run(t, 60.0).is_empty(), "the cover stays on")
	assert_false(t.betting_open())
	assert_eq(t.begin_night(), 0)
	assert_eq(t.phase, RouletteTable.Phase.OPEN, "the next night it opens again")


func test_the_croupier_gone() -> void:
	var t := _table(8)
	var money := 300
	money -= t.danny.place("low", 100, money)
	money += t.halt()
	assert_eq(money, 300, "bets open: the chips come back")
	assert_eq(t.phase, RouletteTable.Phase.CLOSED)
	t.begin_night()
	money -= t.danny.place("high", 100, money)
	_run(t, rules.open_seconds + rules.ball_seconds + 0.2)
	var owed := Roulette.returns("high", 100, t.number)
	money += t.halt()
	assert_eq(money, 200 + owed, "a number drawn: settled at once")
	assert_true(_run(t, 30.0).is_empty())


func test_a_long_frame_misses_nothing() -> void:
	var t := _table(6)
	var events := t.advance(_round_length() * 2 + 1.0)  # a hitch of most of a minute
	assert_eq(_names(events).count("rest"), 2)
	assert_eq(_names(events).count("no_more_bets"), 2)
	assert_eq(t.danny.history.size(), 2)
