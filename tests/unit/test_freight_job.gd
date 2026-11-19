extends GutTest
## M012 "Freight Doesn't Walk" (pure): Leon's offer, its truck; finding out
## why; each way of settling it - Leon's petty cash on Danny's word, Danny's
## own six dollars, a gun shown, a fistfight won (lost: try another way) -
## with its money, memories and talk; the fee once; past the truck Leon sorts
## it himself; nothing settled twice; saved and loaded; the talk reaches
## Rourke only along the ward's own chain, days later.

var r: Rackets
var f: FreightJob


func before_each() -> void:
	r = Rackets.new(EconomyRules.new())
	r.money = 2000
	f = r.freight


func _taken() -> void:
	f.offer(r.night, 21 * 60.0)
	assert_true(f.accept())


func test_the_offer_and_its_truck() -> void:
	assert_eq(f.stage, FreightJob.Stage.NOT_OFFERED)
	f.offer(r.night, 21 * 60.0)
	assert_eq(f.stage, FreightJob.Stage.OFFERED)
	assert_eq(f.deadline, FreightJob.TRUCK, "the two o'clock truck")
	var late := FreightJob.new()
	late.offer(1, 25 * 60.0 + 10.0)
	assert_eq(late.deadline, FreightJob.LATE_TRUCK, "asked after one: the five o'clock")
	f.decline()
	assert_eq(f.stage, FreightJob.Stage.DECLINED)
	assert_false(f.accept(), "said no is no")


func test_squared_on_dannys_word() -> void:
	_taken()
	assert_false(f.talk_leon_round(), "Danny does not know why yet")
	f.learn("docked")
	assert_true(f.talk_leon_round())
	var before := r.money
	assert_true(f.settle(r, "squared"))
	assert_eq(r.money, before, "Leon's petty cash, not Danny's")
	assert_eq(f.walt_paid_by, "leon")
	assert_true(f.crates_out)
	assert_gt(r.memory.recent("leon", "kept_promise", r.night), 0)
	assert_eq(f.collect_fee(r), FreightJob.FEE)
	assert_eq(r.money, before + FreightJob.FEE)
	assert_eq(f.collect_fee(r), 0, "paid once")
	assert_eq(r.money, before + FreightJob.FEE)


func test_dannys_own_six_dollars() -> void:
	_taken()
	r.money = 500
	assert_false(f.settle(r, "paid"), "not with five dollars")
	r.money = 700
	assert_true(f.settle(r, "paid"))
	assert_eq(r.money, 100, "six dollars out of his pocket")
	assert_eq(f.walt_paid_by, "danny")
	assert_gt(r.memory.attitude("walt", r.night).goodwill, 2.0, "the shed gang won't forget it")
	assert_false(f.settle(r, "paid"), "nothing settled twice")
	assert_eq(r.money, 100)


func test_a_gun_or_fists() -> void:
	_taken()
	assert_false(f.threaten(r, false), "no gun: Walt laughs")
	assert_eq(f.threat_failed_night, r.night)
	assert_eq(f.stage, FreightJob.Stage.ACCEPTED)
	f.fought(r, false)
	assert_false(f.can_fight(r.night), "beaten once tonight")
	assert_eq(f.stage, FreightJob.Stage.ACCEPTED, "not stuck: still open")
	f.learn("docked")
	assert_true(f.settle(r, "paid"), "another way after losing")
	var gr := Rackets.new(EconomyRules.new())
	var g := gr.freight
	g.offer(gr.night, 21 * 60.0)
	g.accept()
	assert_true(g.threaten(gr, true), "a gun in hand: he loads")
	assert_eq(g.how, "leaned")
	assert_gt(gr.memory.recent("walt", "threat", gr.night), 0)
	var h := Rackets.new(EconomyRules.new())
	h.freight.offer(h.night, 21 * 60.0)
	h.freight.accept()
	h.freight.fought(h, true)
	assert_eq(h.freight.how, "beaten")
	assert_true(h.freight.crates_out)


func test_past_the_truck_leon_sorts_it_himself() -> void:
	_taken()
	assert_eq(f.advance(r, 25 * 60.0), "", "before the truck")
	assert_eq(f.advance(r, FreightJob.TRUCK + 1.0), "lapsed")
	assert_eq(f.stage, FreightJob.Stage.LAPSED)
	assert_true(f.crates_out, "the freight went, late")
	assert_gt(r.memory.recent("leon", "broken_promise", r.night), 0, "Danny let him down")
	assert_false(f.settle(r, "paid"), "too late to settle")
	assert_eq(f.collect_fee(r), 0, "no fee")
	# said no: no broken promise
	var r2 := Rackets.new(EconomyRules.new())
	r2.freight.offer(r2.night, 21 * 60.0)
	r2.freight.decline()
	r2.end_night()
	assert_eq(r2.freight.stage, FreightJob.Stage.DECLINED, "a no stays a no")
	assert_eq(r2.memory.recent("leon", "broken_promise", r2.night, 3), 0)
	# taken and left: the morning finds it lapsed
	var r3 := Rackets.new(EconomyRules.new())
	r3.freight.offer(r3.night, 21 * 60.0)
	r3.freight.accept()
	r3.end_night()
	assert_eq(r3.freight.stage, FreightJob.Stage.LAPSED)


func test_saved_and_loaded_mid_job() -> void:
	_taken()
	f.learn("docked")
	f.talk_leon_round()
	var copy := Rackets.new(EconomyRules.new())
	copy.from_dict(JSON.parse_string(JSON.stringify(r.to_dict())))
	assert_eq(copy.freight.stage, FreightJob.Stage.ACCEPTED)
	assert_true(copy.freight.learned.has("docked"))
	assert_true(copy.freight.leon_agreed)
	assert_true(copy.freight.settle(copy, "squared"))
	assert_eq(copy.freight.collect_fee(copy), FreightJob.FEE)
	var again := Rackets.new(EconomyRules.new())
	again.from_dict(JSON.parse_string(JSON.stringify(copy.to_dict())))
	assert_eq(again.freight.collect_fee(again), 0, "a reload never pays twice")
	assert_true(again.freight.crates_out)


func test_rourke_hears_only_through_the_talk_days_later() -> void:
	_taken()
	f.threaten(r, true)
	assert_eq(r.rumours.known_to("rourke", "freight_leaned"), [], "not the night of it")
	var nights := 0
	while r.rumours.known_to("rourke", "freight_leaned").is_empty() and nights < 8:
		r.end_night()
		nights += 1
	assert_between(nights, 3, 6, "Walt -> Dutch -> Novak -> Augie -> Rourke")


func test_the_fee_is_dannys_own() -> void:
	_taken()
	f.threaten(r, true)
	var held := r.held
	var owed: int = r.boss.arrears
	assert_eq(f.collect_fee(r), FreightJob.FEE)
	assert_eq(r.held, held, "nothing of it set aside for Rourke")
	assert_eq(r.boss.arrears, owed, "nor owed to him")


func test_the_notebook_follows_it() -> void:
	f.offer(r.night, 21 * 60.0)
	assert_string_contains(f.objective(), "Leon Sobczak")
	f.accept()
	assert_string_contains(f.objective(), "Find out why")
	f.learn("docked")
	assert_string_contains(f.objective(), "six dollars")
	f.talk_leon_round()
	assert_string_contains(f.objective(), "Tell Walt")
	f.settle(r, "squared")
	assert_string_contains(f.objective(), "owes you ten")
	f.collect_fee(r)
	assert_eq(f.objective(), "")
