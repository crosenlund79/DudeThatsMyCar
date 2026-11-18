extends GutTest
## M005 Rourke: he expects what his businesses can pay as far as HE knows,
## at least most of what Danny brought lately, what is owed and his end of
## any rye he has seen sold in his club. He weighs excuses against what he
## knows, catches a lie when the news reaches him (even nights later), and
## running out of patience costs Danny his commission and then his trade at
## the club - pressure, never a game over. Money only moves.

var r: Rackets


func before_each() -> void:
	r = Rackets.new(EconomyRules.new())


func _all_money() -> int:
	return r.money + r.town.total_cash() + r.boss.purse


func test_he_expects_what_his_businesses_can_pay_as_far_as_he_knows() -> void:
	var b := r.boss
	var club := r.club().protection
	var grocer := r.town.get_business("grocery").protection
	assert_eq(b.expected, club + grocer, "a normal night: both pay")
	r.town.get_business("grocery").cash = 0  # Novak is broke - but Rourke has not heard
	b.expect(r.town)
	assert_eq(b.expected, club + grocer, "he does not know what he has not heard")
	b.learn("grocery", "short", r.night)
	b.expect(r.town)
	assert_eq(b.expected, club + grocer / 2, "once he hears, he expects less")


func test_he_sees_the_club_for_himself() -> void:
	r.club().stock = 0
	r.boss.observe_club(r.club(), r.night)
	r.boss.expect(r.town)
	assert_eq(r.boss.belief.get("copper_owl"), "short")
	assert_lt(r.boss.expected, r.club().protection + r.town.get_business("grocery").protection)


func test_paying_in_full_earns_danny_his_end() -> void:
	var total := _all_money()
	r.collect("copper_owl", false)
	r.collect("grocery", false)
	var trust := r.boss.trust
	var money := r.money
	var out := r.pay_boss(r.held)
	assert_true(out.accepted)
	assert_eq(out.cut, (r.club().protection + r.town.get_business("grocery").protection) * Boss.COMMISSION / 100)
	assert_eq(r.money, money - out.handed + out.cut)
	assert_eq(r.held, 0)
	assert_gt(r.boss.trust, trust)
	assert_eq(r.boss.arrears, 0)
	assert_eq(_all_money(), total, "money only moved: tills, Danny, Rourke")


func test_short_without_excuse_goes_on_the_slate() -> void:
	r.collect("copper_owl", false)
	var out := r.pay_boss(r.held)  # Novak not collected
	assert_false(out.accepted)
	assert_eq(out.owed, r.town.get_business("grocery").protection)
	assert_lt(r.boss.patience, Boss.PATIENCE)
	r.end_night()
	assert_gte(r.boss.expected, out.owed, "tomorrow he wants it on top")


func test_a_thin_night_is_believed_when_he_has_heard_so() -> void:
	r.town.get_business("grocery").cash = 0
	r.boss.learn("grocery", "short", r.night)
	r.boss.expect(r.town)
	r.collect("copper_owl", false)
	r.collect("grocery", false)  # Novak had nothing
	var out := r.pay_boss(r.held, "bad_business")
	assert_true(out.accepted, "what he knows backs Danny up")
	assert_eq(r.boss.arrears, 0)


func test_a_thin_night_with_nothing_to_back_it_is_not_believed_from_a_man_he_doubts() -> void:
	r.boss.trust = 45
	r.collect("copper_owl", false)
	var out := r.pay_boss(r.held, "bad_business")
	assert_false(out.accepted)
	assert_gt(out.owed, 0)


func test_he_catches_a_lie_about_the_club_at_once() -> void:
	r.collect("copper_owl", false)  # Augie tells him straight away
	var trust := r.boss.trust
	var out := r.pay_boss(r.held / 2, "bad_business")
	assert_true(out.caught, "Augie told him what he paid")
	assert_eq(r.skimmed, r.club().protection / 2)
	assert_lte(r.boss.trust, trust - 20)


func test_he_finds_out_about_novak_nights_later_through_talk() -> void:
	r.collect("grocery", true)
	var paid: int = r.paid_amount["grocery"]
	r.boss.trust = 70  # he believes the thin night for now
	var out := r.pay_boss(0, "bad_business")
	assert_true(out.accepted, "he has no reason to doubt it yet")
	r.end_night()
	assert_eq(r.boss.caught, 0, "Novak has only told Sal, Augie and Lindqvist so far")
	var arrears := r.boss.arrears
	r.end_night()
	assert_eq(r.boss.caught, 1, "Augie passed it on: now Rourke knows")
	assert_gte(r.boss.arrears, arrears + paid, "and he wants what Danny kept")
	assert_gt(r.memory.recent("rourke", "lie", r.night, 3), 0, "and remembers it")


func test_his_books_do_not_count_old_news_twice() -> void:
	r.collect("grocery", true)
	var paid: int = r.paid_amount["grocery"]
	var seq: int = r.last_seq["grocery"]
	var night := r.night
	r.boss.trust = 70
	r.pay_boss(0, "bad_business")
	r.rumours.items.clear()  # nobody talks: only the ledger
	assert_eq(r.boss.learn_paid("grocery", paid, night, seq), paid)
	assert_eq(r.boss.learn_paid("grocery", paid, night, seq), 0, "old news is not counted twice")


func test_an_honest_thin_night_stands_when_the_news_comes() -> void:
	r.collect("grocery", false)
	var paid: int = r.paid_amount["grocery"]
	var seq: int = r.last_seq["grocery"]
	r.boss.trust = 70
	r.pay_boss(r.held, "bad_business")
	assert_eq(r.boss.learn_paid("grocery", paid, r.night, seq), 0, "the books agree")
	assert_eq(r.boss.caught, 0)


func test_collecting_after_settling_up_is_not_a_lie() -> void:
	r.boss.trust = 70
	r.pay_boss(0, "bad_business")
	r.collect("copper_owl", false)  # later that night
	assert_eq(r.boss.caught, 0)
	assert_eq(r.held, r.club().protection, "it is still his, to hand over tomorrow")


func test_not_showing_up_costs_trust_and_patience() -> void:
	var trust := r.boss.trust
	var expected := r.boss.expected
	r.end_night()
	assert_eq(r.boss.arrears, expected)
	assert_lt(r.boss.trust, trust)
	assert_eq(r.boss.patience, Boss.PATIENCE - 1)


func test_out_of_patience_costs_his_end_then_the_rye_trade_never_the_game() -> void:
	for k in 2:
		r.end_night()
	assert_eq(r.boss.commission, Boss.COMMISSION / 2, "his end is halved")
	assert_false(r.boss.ban)
	r.end_night()
	assert_true(r.boss.ban, "no more rye through the club")
	r.bottles = 3
	assert_eq(r.sell_bottles(), 0, "Augie won't buy")
	r.money = 100000
	var out := r.pay_boss(r.boss.expected)
	assert_true(out.accepted)
	assert_false(r.boss.ban, "square again")
	assert_eq(r.boss.patience, Boss.PATIENCE)
	assert_gt(r.sell_bottles(), 0, "and the trade is back")


func test_bringing_more_raises_what_he_expects() -> void:
	r.collect("copper_owl", true)
	r.collect("grocery", true)
	r.pay_boss(r.held)
	r.end_night()
	var normal := r.club().protection + r.town.get_business("grocery").protection
	assert_gt(r.boss.expected, normal, "leaning on them raised his idea of what they pay")


func test_he_wants_his_end_of_the_rye_he_sees() -> void:
	r.buy_bottles(6)
	r.sell_bottles()
	assert_true(r.boss.knows_rye)
	assert_eq(r.boss.rye_end(), 6 * r.rules.bar_price / 10)
	r.collect("copper_owl", false)
	var out := r.pay_boss(r.held)
	assert_false(out.accepted, "the protection alone is short of his end")


func test_rourke_survives_a_save() -> void:
	r.collect("copper_owl", false)
	r.pay_boss(100, "bad_business")
	r.end_night()
	var copy := Rackets.new(EconomyRules.new())
	copy.from_dict(JSON.parse_string(JSON.stringify(r.to_dict())))
	assert_eq(JSON.stringify(copy.boss.to_dict()), JSON.stringify(r.boss.to_dict()))
	assert_eq(copy.held, r.held)
