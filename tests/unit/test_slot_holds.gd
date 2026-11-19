extends GutTest
## M013 hold-and-respin (SlotMachine, SlotReels, pure). After a full pull that
## pays nothing the HOLD lamps may light (a fair draw with the pull: the same
## chance every time, nothing to do with money); then one or two reels - never
## three - may be held; the next pull takes the stake once, keeps the held
## reels' symbols (they stand still), spins the others and pays the line; the
## holds are released and the pull after that is a full spin. Stakes of one,
## two or five coins pay in proportion and cannot be changed under lit lamps
## without putting them out. The returns are exact: plain pulls about 85%, the
## best possible hold play about 94-95% - below what goes in. Saving keeps the
## reels, lamps, holds and stake, and a pull under way counts as paid, once.

const MACHINES := ["res://src/gaming/slot_owl.tres", "res://src/gaming/slot_bell.tres", "res://src/gaming/slot_star.tres"]
## The exact returns (tools/slot_odds/analyse.py prints the same).
const PLAIN := [0.8574, 0.8544, 0.8497]
const BEST := [0.9432, 0.9522, 0.9499]


func _machine(i: int) -> SlotMachine:
	return SlotMachine.new(load(MACHINES[i]) as SlotRules)


## A seed whose full pull loses and lights the lamps (or, `lit` false, loses without).
func _losing_seed(m: SlotMachine, lit := true, from := 0) -> int:
	var probe := SlotMachine.new(m.rules)
	probe.stake = m.stake
	for s in range(from, from + 100000):
		probe.pull(100000, s)
		probe.collect()
		if probe.win == 0 and probe.hold_offered == lit:
			return s
	return -1


func test_returns_exact_and_below_what_goes_in() -> void:
	for i in 3:
		var m := _machine(i)
		var plain := m.expected_return()
		var best := m.best_hold_return()
		gut.p("%s: plain %.2f%%, the best holds %.2f%% (lamps one losing pull in %d)" % [m.rules.title, plain * 100, best * 100,
			roundi(1.0 / m.rules.hold_chance)])
		assert_almost_eq(plain, PLAIN[i], 0.0001, "%s plain" % m.rules.title)
		assert_almost_eq(best, BEST[i], 0.0001, "%s with the best holds" % m.rules.title)
		assert_lt(best, 1.0, "however well he holds, the house keeps a little")
		assert_gt(best, plain, "holding well is worth something")


func test_a_full_spin_then_the_lamps() -> void:
	var m := _machine(0)
	var money := 1000
	assert_false(m.hold_offered, "no lamps before a pull")
	assert_ne(m.toggle_hold(0), "", "nothing to hold yet")
	var s := _losing_seed(m)
	money -= m.pull(money, s)
	assert_false(m.respin, "a full spin")
	assert_eq(m.spun_held, [false, false, false] as Array[bool])
	assert_false(m.hold_offered, "not while the reels turn")
	money += m.collect()
	assert_eq(m.win, 0)
	assert_true(m.hold_offered, "a losing pull: the lamps light")


func test_the_lamps_never_light_after_a_win() -> void:
	var m := _machine(1)
	for s in 3000:
		m.pull(100000, s)
		m.collect()
		if m.win > 0:
			assert_false(m.hold_offered, "a win never lights the lamps")


func test_the_lamp_is_a_fair_chance() -> void:
	for i in 3:
		var m := _machine(i)
		var losing := 0
		var lit := 0
		for s in 20000:
			m.pull(100000, s)
			m.collect()
			if m.win == 0:
				losing += 1
				if m.hold_offered:
					lit += 1
			m.set_stake(m.stake)  # (keeps it full spins: nothing held)
			m.hold_offered = false
		var share := float(lit) / float(losing)
		assert_almost_eq(share, m.rules.hold_chance, 0.02, "%s: the lamps light about one losing pull in %d (%.3f)" % [
			m.rules.title, roundi(1.0 / m.rules.hold_chance), share])


func test_one_reel_held() -> void:
	var m := _machine(0)
	var money := 1000
	money -= m.pull(money, _losing_seed(m))
	money += m.collect()
	var keep := m.stops[0]
	var sym := m.symbol(0, keep)
	assert_eq(m.toggle_hold(0), "")
	assert_true(m.held[0])
	var before := money
	money -= m.pull(money, 4242)
	assert_eq(before - money, m.stake, "the stake taken once")
	assert_true(m.respin)
	assert_eq(m.spun_held, [true, false, false] as Array[bool])
	assert_eq(m.stops[0], keep, "the held reel keeps its stop")
	assert_eq(m.symbol(0, m.stops[0]), sym)
	assert_eq(m.held, [false, false, false] as Array[bool], "the holds go with the pull")
	var paid := m.collect()
	assert_eq(paid, SlotMachine.coins_for(m.rules, m.line()) * m.stake, "all three reels paid as any line (cents)")
	assert_false(m.hold_offered, "after a respin: no lamps, whatever it paid")
	assert_ne(m.toggle_hold(1), "", "the next pull spins all three")


func test_two_reels_held_never_three() -> void:
	var m := _machine(2)
	m.pull(100000, _losing_seed(m))
	m.collect()
	var a := m.stops[0]
	var c := m.stops[2]
	assert_eq(m.toggle_hold(0), "")
	assert_eq(m.toggle_hold(2), "")
	assert_string_contains(m.toggle_hold(1), "Two reels at most", "never all three")
	assert_false(m.held[1])
	m.pull(100000, 99)
	assert_eq(m.stops[0], a)
	assert_eq(m.stops[2], c)
	m.collect()
	# letting one go again before the pull
	m.pull(100000, _losing_seed(m, true, 500))
	m.collect()
	m.toggle_hold(1)
	assert_eq(m.toggle_hold(1), "")
	assert_eq(m.held_count(), 0, "held and let go")


func test_the_unheld_reels_really_spin() -> void:
	var m := _machine(0)
	var seen := {}
	var s := 0
	for k in 60:
		s = _losing_seed(m, true, s + 1)
		m.pull(100000, s)
		m.collect()
		var keep := m.stops[1]
		m.toggle_hold(1)
		m.pull(100000, 7000 + k)
		assert_eq(m.stops[1], keep)
		seen[m.stops[0]] = true
		m.collect()
	assert_gt(seen.size(), 12, "the free reels land all over their strips")


func test_after_a_respin_a_full_spin() -> void:
	var m := _machine(1)
	m.pull(100000, _losing_seed(m))
	m.collect()
	m.toggle_hold(0)
	m.pull(100000, 1)
	m.collect()
	assert_false(m.hold_offered)
	m.pull(100000, 2)
	assert_false(m.respin, "a full spin, whatever was held before")
	assert_eq(m.spun_held, [false, false, false] as Array[bool])
	m.collect()


func test_not_enough_for_the_stake() -> void:
	var m := _machine(0)
	m.set_stake(25)
	var money := 1000
	money -= m.pull(money, _losing_seed(m))
	money += m.collect()
	m.toggle_hold(0)
	money = 10
	assert_eq(m.pull(money, 3), 0, "the respin costs the full stake")
	assert_true(m.held[0], "and the hold waits")
	assert_true(m.hold_offered)


func test_stakes_pay_in_proportion_and_lock_under_the_lamps() -> void:
	var one := _machine(0)
	var five := _machine(0)
	assert_eq(one.stake_choices(), [5, 10, 25] as Array[int])
	assert_eq(_machine(2).stake_choices(), [10, 20, 50] as Array[int], "the Star takes dimes")
	assert_eq(five.set_stake(25), "")
	assert_ne(five.set_stake(30), "", "only the machine's stakes")
	for s in 300:
		var a := one.pull(100000, s)
		var b := five.pull(100000, s)
		assert_eq(b, 5 * a)
		assert_eq(five.collect(), 5 * one.collect(), "five coins in, five times the pay")
		one.hold_offered = false
		five.hold_offered = false
	var m := _machine(0)
	m.pull(100000, _losing_seed(m))
	assert_ne(m.set_stake(25), "", "not while the reels turn")
	m.collect()
	m.toggle_hold(0)
	assert_eq(m.set_stake(25), "")
	assert_false(m.hold_offered, "a new stake puts the lamps out")
	assert_eq(m.held_count(), 0)


func test_the_books_balance_with_holds() -> void:
	for i in 3:
		var m := _machine(i)
		var rng := RandomNumberGenerator.new()
		rng.seed = 5 + i
		var money := 100000
		var start := money
		for k in 4000:
			if m.hold_offered and rng.randf() < 0.8:
				m.toggle_hold(rng.randi_range(0, 2))
				if rng.randf() < 0.5:
					m.toggle_hold(rng.randi_range(0, 2))
			if k % 500 == 0 and not m.hold_offered:
				m.set_stake(m.stake_choices()[rng.randi_range(0, 2)])
			money -= m.pull(money, rng.randi())
			money += m.collect()
			assert_gte(money, 0)
		assert_eq(money, start - m.taken_total + m.paid_total, "%s: every coin accounted for" % m.rules.title)


func test_the_draw_owes_nothing_to_money_or_play() -> void:
	var a := _machine(2)
	var b := _machine(2)
	for s in 200:
		a.pull(20, s)  # a man down to his last two dimes
		b.pull(1000000, s)
		assert_eq(a.stops, b.stops)
		assert_eq(a.collect(), b.collect())
		assert_eq(a.hold_offered, b.hold_offered, "the lamps the same draw too")
		a.hold_offered = false
		b.hold_offered = false


func test_saved_and_loaded() -> void:
	var m := _machine(0)
	m.set_stake(10)
	m.pull(100000, _losing_seed(m))
	# saved with the reels still turning: as it will be once paid (its win in the money)
	var mid := m.to_dict()
	assert_true(bool(mid.hold_offered), "the lamps it will light")
	m.collect()
	m.toggle_hold(2)
	var d := JSON.parse_string(JSON.stringify(m.to_dict())) as Dictionary
	var again := _machine(0)
	again.from_dict(d)
	assert_eq(again.stops, m.stops, "the reels as they stood")
	assert_eq(again.stake, 10)
	assert_true(again.hold_offered)
	assert_eq(again.held, [false, false, true] as Array[bool], "the hold kept")
	assert_false(again.pending, "nothing to pay twice")
	assert_eq(again.collect(), 0)
	# a respin saved: no lamps after it
	again.pull(100000, 8)
	var r := again.to_dict()
	assert_false(bool(r.hold_offered))
	# what a save cannot smuggle in: three holds, lamps over a winning line
	var bad := m.to_dict()
	bad.held = [true, true, true]
	var b := _machine(0)
	b.from_dict(bad)
	assert_eq(b.held_count(), 0, "three holds are never possible")
	var w := _machine(0)
	for s in 1000:
		w.pull(100000, s)
		w.collect()
		if w.win > 0:
			break
	var won := w.to_dict()
	won.hold_offered = true
	var c := _machine(0)
	c.from_dict(won)
	assert_false(c.hold_offered, "no lamps over a winning line")


func test_held_reels_stand_still() -> void:
	var m := _machine(1)
	m.pull(100000, _losing_seed(m))
	m.collect()
	var from: Array[float] = [float(m.stops[0]), float(m.stops[1]), float(m.stops[2])]
	m.toggle_hold(0)
	m.toggle_hold(1)
	m.pull(100000, 31)
	var reels := SlotReels.new(from, m.stops, m.rules.stop_times, [20, 20, 20], 0.25, m.spun_held)
	var t := 0.0
	while not reels.done(t):
		t += 1.0 / 60.0
		assert_eq(reels.position(0, t), from[0], "reel 1 held: not a twitch")
		assert_eq(reels.position(1, t), from[1], "reel 2 held")
	assert_eq(reels.on_line(2, t), m.stops[2], "the free reel stops on its drawn stop")
	assert_lt(t, m.rules.stop_times[2] + 0.3, "done when the free reel is")


func test_the_machines_differ() -> void:
	var chances := []
	var tops := []
	for i in 3:
		var m := _machine(i)
		chances.append(m.rules.hold_chance)
		tops.append(int(m.rules.pays[0].coins))
	assert_ne(chances[0], chances[1], "the Bell's lamps light less often")
	assert_true(tops[0] != tops[1] or tops[1] != tops[2], "different top prizes")
