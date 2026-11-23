extends GutTest
## M011 the gaming room's nickel machines, without the scene: one reusable
## SlotMachine, three machines (the Owl, the Bell, the Star) differing only
## in their SlotRules - three reels of twenty period symbols, a paytable
## (first matching line pays); every stop on a strip drawn alike, whatever
## Danny has or has done; the line shown is what is paid, by the paytable on
## the front; the coin taken once, the win paid once; never below zero; a
## save mid-pull counts the decided win; machines keep their own state; each
## machine's exact return is modest and below even; and the reels on screen
## always stop on the drawn stops.

const MACHINES := ["res://src/gaming/slot_owl.tres", "res://src/gaming/slot_bell.tres", "res://src/gaming/slot_star.tres"]


func _machine(i: int) -> SlotMachine:
	return SlotMachine.new(load(MACHINES[i]) as SlotRules)


func test_three_machines_one_implementation_period_symbols() -> void:
	var titles := []
	for i in 3:
		var m := _machine(i)
		titles.append(m.rules.title)
		assert_eq(m.rules.strips.size(), 3, "%s: three reels" % m.rules.title)
		for r in 3:
			assert_eq(m.rules.strips[r].size(), 20, "%s: twenty stops a reel" % m.rules.title)
			for sym in m.rules.strips[r]:
				assert_true(sym in SlotMachine.SYMBOLS, "%s: %s is a period symbol" % [m.rules.title, sym])
		assert_gt(m.rules.pays.size(), 5, "a paytable on the front")
		for p in m.rules.pays:
			assert_eq((p.line as Array).size(), 3)
			assert_gt(int(p.coins), 0)
	assert_eq(titles, ["The Owl", "The Bell", "The Star"])


## M013: the paytables were rebalanced for hold-and-respin (no bar completing
## a pair any more); M015 again, for a hold after every losing pull (see
## test_slot_holds and tools/slot_odds/analyse.py).
func test_the_paytable_first_line_that_matches() -> void:
	var r: SlotRules = load(MACHINES[0])
	assert_eq(SlotMachine.coins_for(r, ["bar", "bar", "bar"]), 30)
	assert_eq(SlotMachine.coins_for(r, ["seven", "seven", "seven"]), 18)
	assert_eq(SlotMachine.coins_for(r, ["bell", "bell", "bell"]), 9)
	assert_eq(SlotMachine.coins_for(r, ["bell", "bell", "bar"]), 0, "M013: a bar no longer completes the bells")
	assert_eq(SlotMachine.coins_for(r, ["plum", "plum", "plum"]), 7)
	assert_eq(SlotMachine.coins_for(r, ["orange", "orange", "orange"]), 6)
	assert_eq(SlotMachine.coins_for(r, ["cherry", "cherry", "cherry"]), 8)
	assert_eq(SlotMachine.coins_for(r, ["cherry", "cherry", "lemon"]), 5)
	assert_eq(SlotMachine.coins_for(r, ["cherry", "plum", "bell"]), 3, "a cherry on the first reel")
	assert_eq(SlotMachine.coins_for(r, ["plum", "cherry", "cherry"]), 0, "cherries count from the left")
	assert_eq(SlotMachine.coins_for(r, ["lemon", "lemon", "lemon"]), 0, "lemons pay nothing")
	assert_eq(SlotMachine.coins_for(r, ["bar", "bell", "bell"]), 0)
	assert_eq(SlotMachine.pay_line(r, ["bell", "bell", "bell"]), 2)
	assert_eq(SlotMachine.pay_line(r, ["lemon", "plum", "bar"]), -1)


func test_each_machine_returns_a_modest_share() -> void:
	for i in 3:
		var m := _machine(i)
		var rtp := m.expected_return()
		gut.p("%s (%d cents): plain pulls return %.2f%% of what goes in" % [m.rules.title, m.rules.coin, rtp * 100.0])
		assert_gt(rtp, 0.75, "%s is not a swindle" % m.rules.title)
		assert_lt(rtp, 0.95, "%s keeps a little for the house, like any machine" % m.rules.title)
		var odds := m.line_odds()
		for k in odds.size():
			assert_gt(odds[k], 0.0, "%s: every line on the paytable can come up (%s)" % [m.rules.title, m.rules.pays[k].line])


func test_every_stop_comes_up_alike() -> void:
	var m := _machine(0)
	var counts := [{}, {}, {}]
	var n := 20000
	for i in n:
		m.pull(1000, hash([3, i]))
		m.collect()
		for r in 3:
			counts[r][m.stops[r]] = int(counts[r].get(m.stops[r], 0)) + 1
	for r in 3:
		assert_eq(counts[r].size(), 20, "reel %d: every stop comes up" % r)
		var chi := 0.0
		for s in 20:
			chi += pow(float(counts[r][s]) - n / 20.0, 2) / (n / 20.0)
		assert_lt(chi, 45.0, "reel %d: chi-square for 19 degrees of freedom well inside chance (%.1f)" % [r, chi])


func test_what_he_has_or_did_does_not_change_the_reels() -> void:
	var a := _machine(1)
	var b := _machine(1)
	for i in 50:
		a.pull(5, i * 7 + 1)  # a man down to his last nickel
		b.pull(100000, i * 7 + 1)  # and a rich one, the same seed
		assert_eq(a.stops, b.stops, "the same draw whatever is in his pocket")
		a.collect()
		b.collect()


func test_the_coin_taken_once_the_win_paid_once() -> void:
	var m := _machine(0)
	var money := 100
	var cost := m.pull(money, 42)
	assert_eq(cost, 5)
	money -= cost
	assert_eq(m.pull(money, 43), 0, "not while the reels turn")
	assert_eq(m.cannot_pull(money), "The reels are still turning.")
	var expect := SlotMachine.coins_for(m.rules, m.line()) * 5
	assert_eq(m.win, expect, "the line shown is what is paid")
	var paid := m.collect()
	assert_eq(paid, expect)
	assert_eq(m.collect(), 0, "never twice")
	money += paid
	assert_eq(money, 95 + expect)
	# play on: the books always balance
	var start := money
	for i in 300:
		if m.cannot_pull(money) != "":
			break
		money -= m.pull(money, 1000 + i)
		money += m.collect()
	assert_eq(money, start - (m.taken_total - 5) + (m.paid_total - expect), "every coin accounted for")


func test_never_below_zero() -> void:
	var m := _machine(2)  # a dime machine
	assert_eq(m.pull(5, 1), 0, "a nickel is not a dime")
	assert_string_contains(m.cannot_pull(5), "a dime")
	var money := 10
	money -= m.pull(money, 9)
	assert_eq(money, 0)
	money += m.collect()
	assert_gte(money, 0)


func test_a_save_mid_pull_counts_the_decided_win() -> void:
	var m := _machine(0)
	var money := 50
	money -= m.pull(money, 77)
	var w := m.win
	assert_eq(m.for_save(), w, "the reels are decided: their win counts")
	money += m.walk_away()
	assert_eq(money, 45 + w, "walking away mid-pull pays it at once")
	assert_eq(m.for_save(), 0)
	assert_eq(m.collect(), 0)


func test_machines_keep_their_own_state() -> void:
	var owl := _machine(0)
	var bell := _machine(1)
	var star := _machine(2)
	owl.pull(100, 5)
	assert_true(owl.pending)
	assert_false(bell.pending, "pulling one machine leaves the others alone")
	assert_eq(bell.stops, [0, 0, 0] as Array[int])
	assert_eq(bell.cannot_pull(100), "")
	bell.pull(100, 6)
	star.pull(100, 7)
	owl.collect()
	assert_true(bell.pending and star.pending)
	assert_eq(owl.pulls + bell.pulls + star.pulls, 3)


func test_the_reels_stop_on_the_drawn_stops() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var m := _machine(0)
	for k in 60:
		var from: Array[float] = [rng.randf_range(0, 20), rng.randf_range(0, 20), rng.randf_range(0, 20)]
		m.pull(100, k)
		var reels := SlotReels.new(from, m.stops, m.rules.stop_times, [20, 20, 20])
		var t := 0.0
		var last := [from[0], from[1], from[2]]
		while not reels.done(t):
			t += 1.0 / 60.0
			for r in 3:
				var p := reels.position(r, t)
				assert_lt(absf(p - float(last[r])), 0.7, "reel %d moves smoothly (under 42 stops a second)" % r)
				last[r] = p
		for r in 3:
			assert_eq(reels.on_line(r, t), m.stops[r], "reel %d shows the drawn stop" % r)
			assert_eq(m.symbol(r, reels.on_line(r, t)), m.line()[r])
		assert_true(reels.stopped(0, m.rules.stop_times[0]) and not reels.stopped(2, m.rules.stop_times[1]), "left first, right last")
		m.collect()
