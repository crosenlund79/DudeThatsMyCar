extends GutTest
## M011 the gaming room's wheel, without the scene: single-zero European
## roulette - the wheel's pockets in the standard order, every bet type and
## its standard payout, the zero (straight, splits, trios and the first four
## win on it; every outside bet loses), several bets at once, the table's
## limits, money that only moves once (placing takes, removing gives back,
## settling pays once, never below zero), a fair draw, saving and walking
## away mid-round; and the layout - every legal bet can be placed by clicking
## where its chips sit, and the clicks land on the bets a player expects.


func _all_bets() -> Array[String]:
	var out: Array[String] = []
	for n in 37:
		out.append("straight:%d" % n)
	for n in range(1, 37):
		if n % 3 != 0:
			out.append("split:%d-%d" % [n, n + 1])
		if n <= 33:
			out.append("split:%d-%d" % [n, n + 3])
	for n in [1, 2, 3]:
		out.append("split:0-%d" % n)
	for c in 12:
		out.append("street:%d-%d-%d" % [3 * c + 1, 3 * c + 2, 3 * c + 3])
	out.append("street:0-1-2")
	out.append("street:0-2-3")
	for n in range(1, 33):
		if n % 3 != 0:
			out.append("corner:%d-%d-%d-%d" % [n, n + 1, n + 3, n + 4])
	out.append("corner:0-1-2-3")
	for c in 11:
		var a := 3 * c + 1
		out.append("line:%d-%d-%d-%d-%d-%d" % [a, a + 1, a + 2, a + 3, a + 4, a + 5])
	for k in ["red", "black", "odd", "even", "low", "high", "dozen:1", "dozen:2", "dozen:3", "column:1", "column:2", "column:3"]:
		out.append(k)
	return out


func test_the_wheel_is_single_zero_in_the_standard_order() -> void:
	assert_eq(Roulette.WHEEL.size(), 37, "37 pockets: one zero, no double zero")
	var sorted := Roulette.WHEEL.duplicate()
	sorted.sort()
	assert_eq(sorted, range(37), "every number once")
	assert_eq(Roulette.WHEEL.slice(0, 6), [0, 32, 15, 19, 4, 21], "clockwise from the zero, the European order")
	assert_eq(Roulette.WHEEL.back(), 26)
	assert_eq(Roulette.REDS.size(), 18)
	assert_eq(Roulette.colour(0), "green")
	assert_eq(Roulette.colour(32), "red")
	assert_eq(Roulette.colour(15), "black")
	# the colours alternate round the wheel after the zero
	for i in range(1, 36):
		assert_ne(Roulette.colour(Roulette.WHEEL[i]), Roulette.colour(Roulette.WHEEL[i + 1]), "red and black alternate")


func test_every_bet_type_covers_and_pays_the_standard_way() -> void:
	var counts := {"straight": 37, "split": 60, "street": 14, "corner": 23, "line": 11}
	var seen := {}
	for k in _all_bets():
		assert_true(Roulette.valid(k), "%s is a bet" % k)
		var kind := Roulette.kind_of(k)
		seen[kind] = int(seen.get(kind, 0)) + 1
	for kind in counts:
		assert_eq(seen[kind], counts[kind], "every %s on the layout" % kind)
	var pays := {"straight:17": 35, "split:17-20": 17, "street:16-17-18": 11, "corner:16-17-19-20": 8,
		"line:16-17-18-19-20-21": 5, "dozen:2": 2, "column:3": 2, "red": 1, "black": 1, "odd": 1, "even": 1, "low": 1, "high": 1}
	for k in pays:
		assert_eq(Roulette.pays(k), pays[k], "%s pays %d to 1" % [k, pays[k]])
		var n: int = Roulette.covers(k)[0]
		assert_eq(Roulette.returns(k, 10, n), 10 * (pays[k] + 1), "%s: stake and winnings when it comes up" % k)
	# expected value is the same for every bet: 36 / 37 of the stake back
	for k in _all_bets():
		var back := 0
		for n in 37:
			back += Roulette.returns(k, 100, n)
		assert_eq(back, 3600, "%s: the zero is the house's only edge" % k)
	assert_eq(Roulette.covers("column:1"), [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31, 34] as Array[int])
	assert_eq(Roulette.covers("dozen:3").size(), 12)
	assert_eq(Roulette.covers("dozen:3")[0], 25)
	assert_eq(Roulette.covers("low").back(), 18)


func test_what_is_not_a_bet() -> void:
	for k in ["straight:37", "straight:-1", "split:3-4", "split:17-19", "split:0-4", "street:2-3-4", "street:0-1-3",
			"corner:3-4-6-7", "corner:1-2-3-4", "corner:33-34-36-37", "line:2-3-4-5-6-7", "line:34-35-36-37-38-39",
			"dozen:4", "column:0", "red:5", "green", "split:5-5", ""]:
		assert_false(Roulette.valid(k), "%s is no bet" % k)
	assert_eq(Roulette.normal("split:20-17"), "split:17-20", "numbers in any order")


func test_the_zero() -> void:
	for k in ["straight:0", "split:0-1", "split:0-2", "split:0-3", "street:0-1-2", "street:0-2-3", "corner:0-1-2-3"]:
		assert_true(Roulette.wins(k, 0), "%s wins on the zero" % k)
	for k in ["red", "black", "odd", "even", "low", "high", "dozen:1", "column:1", "column:2", "column:3"]:
		assert_false(Roulette.wins(k, 0), "%s loses on the zero" % k)
	assert_eq(Roulette.returns("straight:0", 10, 0), 360)
	assert_eq(Roulette.returns("corner:0-1-2-3", 10, 0), 90)
	assert_eq(Roulette.returns("street:0-2-3", 10, 3), 120)


func test_a_round_with_several_bets_settles_once() -> void:
	var r := Roulette.new()
	var money := 1000
	for b in [["straight:17", 25], ["split:17-20", 10], ["red", 100], ["odd", 25], ["dozen:2", 25], ["column:2", 10],
			["corner:16-17-19-20", 5], ["street:16-17-18", 5], ["line:16-17-18-19-20-21", 5]]:
		money -= r.place(b[0], b[1], money)
	assert_eq(money, 1000 - 210, "every chip taken once")
	assert_eq(r.total_staked(), 210)
	assert_eq(r.spin(0), r.result)
	r.result = 17  # the number fixed for the sum (the draw is tested on its own)
	assert_eq(r.place("black", 5, money), 0, "no more bets once it spins")
	assert_eq(r.remove("red", 100), 0, "nor taking one back")
	var paid := r.settle()
	# 17: a black, odd, 2nd-dozen, 2nd-column number (red loses)
	var expect := 25 * 36 + 10 * 18 + 0 + 25 * 2 + 25 * 3 + 10 * 3 + 5 * 9 + 5 * 12 + 5 * 6
	assert_eq(paid, expect, "every winning bet: stake and winnings")
	assert_eq(r.settle(), 0, "a second settling pays nothing")
	money += paid
	assert_eq(money, 1000 - 210 + expect)
	assert_eq(r.winning_bets().size(), 8, "all but red")
	assert_eq(r.history[0], 17)
	r.new_round()
	assert_eq(r.phase, Roulette.Phase.BETTING)
	assert_true(r.bets.is_empty())


func test_a_losing_spin_takes_only_the_stakes() -> void:
	var r := Roulette.new()
	var money := 500
	money -= r.place("red", 100, money)
	money -= r.place("straight:5", 25, money)
	r.spin(1)
	r.result = 0
	money += r.settle()
	assert_eq(money, 375, "lost on the zero: the stakes, nothing more")


func test_money_never_goes_below_zero() -> void:
	var r := Roulette.new()
	var money := 30
	money -= r.place("red", 25, money)
	assert_eq(money, 5)
	assert_eq(r.place("red", 25, money), 0, "a chip he cannot pay for is refused")
	assert_ne(r.refuse("red", 25, money), "")
	money -= r.place("red", 5, money)
	assert_eq(money, 0)
	assert_eq(r.place("black", 5, money), 0)
	assert_eq(r.place("red", 7, 1000), 0, "only the croupier's chips")
	assert_gte(money, 0)


func test_the_table_limits() -> void:
	var rules := RouletteRules.new()
	var r := Roulette.new(rules)
	var money := 100000
	for i in 2:
		money -= r.place("straight:9", 25, money)
	assert_eq(r.bets["straight:9"], 50)
	assert_eq(r.place("straight:9", 5, money), 0, "no more than the most on one number")
	assert_string_contains(r.refuse("straight:9", 5, money), "no more than")
	money -= r.place("split:8-9", 100, money)
	assert_eq(r.place("split:8-9", 5, money), 0, "the inside limit")
	for i in 5:
		money -= r.place("red", 100, money)
	assert_eq(r.place("red", 5, money), 0, "the outside limit")
	money -= r.place("black", 100, money)
	money -= r.place("odd", 100, money)
	money -= r.place("even", 100, money)
	assert_eq(r.total_staked(), 950)
	money -= r.place("low", 25, money)
	money -= r.place("low", 25, money)
	assert_eq(r.total_staked(), 1000)
	assert_eq(r.place("high", 5, money), 0, "the most a spin")
	assert_eq(money + r.total_staked(), 100000, "nothing made or lost")
	# under the table's minimum, the wheel will not be spun
	rules.min_bet = 10
	var r2 := Roulette.new(rules)
	r2.place("red", 5, 100)
	assert_ne(r2.cannot_spin(), "")
	assert_eq(r2.spin(3), -1)
	r2.place("red", 5, 100)
	assert_eq(r2.cannot_spin(), "")
	assert_ne(Roulette.new().cannot_spin(), "", "no bets, no spin")


func test_removing_and_clearing_give_back_exactly() -> void:
	var r := Roulette.new()
	var money := 400
	money -= r.place("straight:3", 25, money)
	money -= r.place("straight:3", 10, money)
	money -= r.place("even", 100, money)
	money += r.remove("straight:3", 25)
	assert_eq(r.bets["straight:3"], 10)
	money += r.remove("straight:3", 25)
	assert_false(r.bets.has("straight:3"), "taken off altogether")
	assert_eq(r.remove("straight:3", 25), 0, "nothing left to take")
	money += r.clear()
	assert_eq(money, 400)
	assert_true(r.bets.is_empty())


func test_the_draw_is_fair_and_repeatable() -> void:
	var r := Roulette.new()
	var counts := {}
	for i in 37000:
		r.place("red", 5, 100)
		var n := r.spin(hash([1, i]))
		assert_true(n >= 0 and n <= 36)
		counts[n] = int(counts.get(n, 0)) + 1
		r.settle()
		r.new_round()
	assert_eq(counts.size(), 37, "every pocket comes up")
	var chi := 0.0
	for n in 37:
		chi += pow(float(counts[n]) - 1000.0, 2) / 1000.0
	assert_lt(chi, 70.0, "chi-square for 36 degrees of freedom well inside chance (%.1f)" % chi)
	var a := Roulette.new()
	var b := Roulette.new()
	a.place("red", 5, 100)
	b.place("red", 5, 100)
	assert_eq(a.spin(12345), b.spin(12345), "the same seed, the same number")


func test_saving_and_walking_away_mid_round() -> void:
	var r := Roulette.new()
	var money := 300
	money -= r.place("red", 100, money)
	money -= r.place("straight:7", 10, money)
	assert_eq(r.for_save(), 110, "before the spin the chips are still his")
	r.spin(5)
	r.result = 7
	assert_eq(r.for_save(), 200 + 360, "once spun the number is decided: counted as settled")
	money += r.walk_away()
	assert_eq(money, 300 - 110 + 560, "walking away mid-spin settles it at once")
	assert_eq(r.settle(), 0, "and never again")
	assert_eq(r.for_save(), 0)
	assert_eq(r.phase, Roulette.Phase.BETTING)
	money -= r.place("black", 25, money)
	money += r.walk_away()
	assert_eq(money, 750, "before the spin the chips come back")


func test_every_bet_can_be_placed_where_its_chips_sit() -> void:
	for k in _all_bets():
		var at := RouletteLayout.anchor(k)
		assert_eq(RouletteLayout.bet_at(at), k, "a click on %s's chips (%s) is that bet" % [k, at])


func test_clicks_land_on_the_expected_bets() -> void:
	var W := RouletteLayout.W
	var H := RouletteLayout.H
	var Z := RouletteLayout.ZERO
	assert_eq(RouletteLayout.bet_at(Vector2(Z + 0.5 * W, 0.5 * H)), "straight:3", "3 at the top of the first column")
	assert_eq(RouletteLayout.bet_at(Vector2(Z + 0.5 * W, 2.5 * H)), "straight:1")
	assert_eq(RouletteLayout.bet_at(Vector2(Z + 11.5 * W, 0.5 * H)), "straight:36")
	assert_eq(RouletteLayout.bet_at(Vector2(Z * 0.3, 1.5 * H)), "straight:0")
	assert_eq(RouletteLayout.bet_at(Vector2(Z + 5.5 * W, 1.02 * H)), "split:17-18", "on the line between 17 and 18")
	assert_eq(RouletteLayout.bet_at(Vector2(Z + 6.02 * W, 1.5 * H)), "split:17-20")
	assert_eq(RouletteLayout.bet_at(Vector2(Z + 6.0 * W, 2.0 * H)), "corner:16-17-19-20")
	assert_eq(RouletteLayout.bet_at(Vector2(Z + 5.5 * W, 3.0 * H)), "street:16-17-18", "under the column")
	assert_eq(RouletteLayout.bet_at(Vector2(Z + 6.0 * W, 3.0 * H)), "line:16-17-18-19-20-21")
	assert_eq(RouletteLayout.bet_at(Vector2(Z + 12.5 * W, 0.5 * H)), "column:3")
	assert_eq(RouletteLayout.bet_at(Vector2(Z + 12.5 * W, 2.5 * H)), "column:1")
	assert_eq(RouletteLayout.bet_at(Vector2(Z + 5.0 * W, 3.0 * H + 20)), "dozen:2")
	assert_eq(RouletteLayout.bet_at(Vector2(Z + 4.5 * W, 3.0 * H + 54)), "red")
	assert_eq(RouletteLayout.bet_at(Vector2(Z + 11.0 * W, 3.0 * H + 54)), "high")
	assert_eq(RouletteLayout.bet_at(Vector2(-5, 10)), "")
	assert_eq(RouletteLayout.bet_at(Vector2(Z + 12.5 * W, 3.0 * H + 54)), "")
	for n in 37:
		assert_eq(RouletteLayout.bet_at(RouletteLayout.cell(n).get_center()), "straight:%d" % n, "%d's box" % n)


func test_the_ball_comes_to_rest_where_the_rules_say() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for n in 37:
		for k in 4:
			var spin := RouletteSpin.new(n, rng.randf_range(-PI, PI), rng.randf_range(-PI, PI), rng.randf_range(5.0, 8.0))
			assert_eq(spin.pocket_under(spin.duration), n, "the ball rests in %d's pocket" % n)
			assert_eq(spin.pocket_under(spin.duration + 4.0), n, "and stays there as the head turns on")
			assert_almost_eq(spin.ball_radius(spin.duration), RouletteSpin.POCKET, 0.0001)
			var dt := 1.0 / 60.0
			var biggest := 0.0
			var t := 0.0
			while t < spin.duration + 0.5:
				biggest = maxf(biggest, absf(spin.ball_angle(t + dt) - spin.ball_angle(t)))
				var r := spin.ball_radius(t)
				assert_true(r >= RouletteSpin.POCKET - 0.001 and r <= RouletteSpin.TRACK + 0.07, "the ball stays in the bowl")
				t += dt
			assert_lt(biggest, 0.4, "no jumps: the ball moves smoothly (%.2f rad a frame at most)" % biggest)
	# the pockets are where the head's art has them: the zero at the top, 32 next clockwise
	assert_eq(RouletteSpin.pocket_at(-PI / 2.0), 0)
	assert_eq(RouletteSpin.pocket_at(-PI / 2.0 + TAU / 37.0), 32)
	assert_eq(RouletteSpin.pocket_at(-PI / 2.0 - TAU / 37.0), 26)
