extends GutTest
## M005 the systems together, night after night: squeezing Novak empties his
## till, the truck comes short (an incident), the ward talks, Rourke hears
## and expects less; a loan for the truck is a favour Novak repays with
## interest and remembers; Danny's word to Rourke and Sal's regulars; and a
## seven-night playthrough of an honest and a greedy henchman.

var r: Rackets


func before_each() -> void:
	r = Rackets.new(EconomyRules.new())


func _novak() -> Business:
	return r.town.get_business("grocery")


func _squeeze_novak_until_the_truck_comes_short() -> int:
	for k in 8:
		r.collect("grocery", true)
		r.money += 0
		r.end_night()
		if not r.incidents.is_empty():
			return k + 1
	return -1


func test_squeezing_novak_brings_a_short_delivery_and_the_ward_talks() -> void:
	var nights := _squeeze_novak_until_the_truck_comes_short()
	assert_between(nights, 1, 6, "leaned on every night, his truck comes short within days")
	assert_eq(r.incidents[0].kind, "short_delivery")
	var talk: Dictionary = r.gossip("sal")
	assert_true(talk.is_empty() or talk.kind in ["short", "threat"], "Sal hears about it")
	r.end_night()
	r.end_night()
	assert_eq(r.boss.belief.get("grocery", "good"), "short", "and Rourke hears Novak is struggling")
	var full := r.club().protection + _novak().protection
	assert_lt(r.boss.believed_due(_novak()), _novak().protection, "so he expects less of him")
	assert_gt(r.memory.attitude("novak", r.night).fear, 0.0, "Novak is afraid of Danny")
	assert_gt(r.memory.recent("sal", "heard_threat", r.night, 6) + r.memory.recent("augie", "heard_threat", r.night, 6), 0,
		"the others heard about the rough stuff")
	assert_true(full > 0)


func test_a_loan_for_the_truck_is_repaid_with_interest_and_remembered() -> void:
	_novak().cash = 200
	_novak().stock = 0
	r.money = 5000
	var need := r.shortfall_for_truck("grocery")
	assert_gt(need, 0, "he cannot pay tomorrow's truck")
	var total := r.money + r.town.total_cash()
	var lent := r.lend("grocery", need)
	assert_eq(lent, need)
	assert_eq(r.money + r.town.total_cash(), total, "a loan only moves money")
	assert_eq(r.lend("grocery", 100), 0, "one loan at a time")
	r.end_night()
	assert_eq(_novak().missed_delivery, 0, "the truck came in full")
	var money := r.money
	var back := 0
	for k in 3:
		back += r.collect_loan("novak")
		if not r.loans.has("novak"):
			break
		r.end_night()
	assert_eq(back, need * 5 / 4, "paid back with a quarter on top")
	assert_eq(r.money, money + back)
	assert_gt(r.memory.attitude("novak", r.night).goodwill, 1.5, "and he does not forget it")
	assert_eq(r.memory.recent("novak", "kept_promise", r.night, 4), 1, "he kept his word")


func test_a_promise_to_rourke_broken_costs_more_than_the_money() -> void:
	r.pay_boss(0)
	r.promise_boss()
	var trust := r.boss.trust
	r.end_night()  # he did not come back with it
	r.end_night()
	assert_lt(r.boss.trust, trust - 10)
	assert_gt(r.memory.recent("rourke", "broken_promise", r.night, 3), 0)


func test_two_good_deals_make_danny_one_of_sals_regulars() -> void:
	var price := r.barber_price()
	r.buy_bottles(2)
	r.end_night()
	r.sal().stock = 6
	assert_false(r.is_regular())
	r.buy_bottles(2)
	assert_true(r.is_regular())
	assert_eq(r.barber_price(), price - 10, "a dime off for a regular")


## Seven nights of one way of working: returns a summary.
func _play(greedy: bool) -> Dictionary:
	var x := Rackets.new(EconomyRules.new())
	var log := []
	for n in 7:
		x.buy_bottles(6)
		x.sell_bottles()
		x.collect("copper_owl", greedy)
		x.collect("grocery", greedy)
		if greedy:
			x.pay_boss(x.held / 2, "bad_business")  # skim half, plead a thin night
		else:
			if x.town.get_business("grocery").missed_delivery > 0 and not x.loans.has("novak"):
				x.lend("grocery", maxi(100, x.shortfall_for_truck("grocery")))
			x.collect_loan("novak")
			x.pay_boss(maxi(x.held, x.boss.expected + x.boss.rye_end()))
		log.append("night %d: money %s, Rourke trust %d, Novak cash %s, missed %d" % [x.night, Rackets.dollars(x.money),
			x.boss.trust, Rackets.dollars(x.town.get_business("grocery").cash), x.town.get_business("grocery").missed_delivery])
		x.end_night()
	return {"rackets": x, "log": log}


func test_seven_nights_honest_and_greedy() -> void:
	var honest := _play(false)
	var greedy := _play(true)
	gut.p("HONEST HENCHMAN\n  " + "\n  ".join(honest.log))
	gut.p("GREEDY HENCHMAN\n  " + "\n  ".join(greedy.log))
	var h: Rackets = honest.rackets
	var g: Rackets = greedy.rackets
	assert_gt(h.boss.trust, g.boss.trust, "Rourke trusts the honest one")
	assert_gt(g.boss.caught, 0, "the greedy one was found out")
	assert_true(g.boss.ban or g.boss.commission < Boss.COMMISSION or g.boss.arrears > 0, "and is paying for it")
	assert_gt(g.boss.purse, 0)
	assert_gt(g.incidents.filter(func(i: Dictionary) -> bool: return i.kind == "collected").size() + int(g.boss.ban_nights > 0), 0,
		"Rourke's boys came round")
	assert_false(h.boss.ban)
	assert_gt(h.memory.attitude("novak", h.night).goodwill, g.memory.attitude("novak", g.night).goodwill,
		"Novak likes the honest one better")
	assert_gt(g.memory.attitude("novak", g.night).fear, h.memory.attitude("novak", h.night).fear)
	assert_gte(h.town.get_business("grocery").cash, 0, "the honest one's grocer is still in business")
