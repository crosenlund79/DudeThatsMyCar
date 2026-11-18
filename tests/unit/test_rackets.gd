extends GutTest
## Danny's dealings (Rackets) with the businesses of the ward: buying rye from
## Sal and selling it to Augie at a profit with real stock and real tills,
## prices that follow scarcity, protection once a night as far as a till
## allows, Eddie's crate, money that only ever moves between pockets and
## tills, and all of it surviving a save (also a save from before M005).

var rules: EconomyRules


func before_each() -> void:
	rules = EconomyRules.new()


## Danny's money plus every till: deals only move it.
func _purse(r: Rackets) -> int:
	return r.money + r.town.total_cash()


func test_a_booze_run_turns_a_profit() -> void:
	var r := Rackets.new(rules)
	assert_eq(r.money, rules.start_money)
	var total := _purse(r)
	assert_eq(r.buy_bottles(6), 6)
	assert_eq(r.money, rules.start_money - 6 * rules.barber_price)
	assert_eq(r.sal().stock, 0, "out of Sal's cupboard")
	assert_eq(r.sell_bottles(), 6)
	assert_eq(r.club().stock, 12, "into Augie's cellar")
	assert_eq(r.money, rules.start_money + 6 * (rules.bar_price - rules.barber_price), "bought low, sold high")
	assert_eq(_purse(r), total, "no money appeared or vanished")


func test_buying_is_limited_by_money_stock_and_what_you_can_carry() -> void:
	var r := Rackets.new(rules)
	r.money = rules.barber_price * 2 + 10
	assert_eq(r.buy_bottles(6), 2, "only what you can pay for")
	r.money = 100000
	r.sal().stock = 10
	assert_eq(r.buy_bottles(10), rules.carry_limit - 2, "only what fits under a coat")
	r.sell_bottles()
	r.sal().stock = 0
	assert_eq(r.buy_bottles(10), 0, "Sal's cupboard is empty")


func test_scarcity_moves_prices() -> void:
	var r := Rackets.new(rules)
	r.sal().stock = 2
	assert_eq(r.barber_price(), rules.barber_price_scarce, "Sal's last bottles cost more")
	r.sal().stock = r.sal().capacity
	assert_eq(r.barber_price(), rules.barber_price_plenty, "a full cupboard is cheaper")
	r.club().stock = 1
	assert_eq(r.bar_price(), rules.bar_price_dry, "a dry cellar pays over the odds")
	r.club().stock = r.club().capacity - 2
	assert_eq(r.bar_price(), rules.bar_price_full)


func test_augie_buys_what_his_cellar_and_till_allow() -> void:
	var r := Rackets.new(rules)
	r.bottles = 6
	r.club().stock = r.club().capacity - 2
	assert_eq(r.sell_bottles(), 2, "room for two")
	assert_eq(r.bottles, 4, "you keep the rest")
	r.club().stock = 0
	r.club().cash = r.bar_price() * 1 + 10
	assert_eq(r.sell_bottles(), 1, "no more than he can pay for")


func test_protection_is_once_a_night_and_as_far_as_the_till_goes() -> void:
	var r := Rackets.new(rules)
	var total := _purse(r)
	assert_eq(r.collect("copper_owl", false), r.club().protection)
	assert_eq(r.collect("copper_owl", false), 0, "already paid tonight")
	var g := r.town.get_business("grocery")
	assert_eq(r.collect("grocery", true), g.protection * 3 / 2, "leaned on, he pays more")
	assert_eq(r.collect("barber_shop", false), 0, "Sal is not on the list")
	assert_eq(_purse(r), total)
	r.end_night()
	g.cash = 200
	assert_eq(r.protection_offer("grocery", false), 0, "asked, he keeps the truck money")
	assert_eq(r.collect("grocery", true), 200, "leaned on, he empties the till")


func test_leaning_on_augie_costs_you_at_the_bar() -> void:
	var r := Rackets.new(rules)
	var fair := r.bar_price()
	r.collect("copper_owl", true)
	assert_eq(r.bar_price(), fair - rules.bar_sore_discount, "he pays less for your rye tonight")
	r.end_night()
	r.club().stock = 6
	assert_eq(r.bar_price(), rules.bar_price, "and gets over it by the next night")


func test_no_deal_pays_out_twice_however_often_you_try() -> void:
	var r := Rackets.new(rules)
	var start := r.money
	for i in 100:
		r.buy_bottles(6)
		r.sell_bottles()
		r.collect("copper_owl", i % 2 == 0)
		r.collect("grocery", i % 3 == 0)
	assert_lte(r.money - start, 6 * (rules.bar_price - rules.barber_price) + 1500 + 750, "one night's takings at most")


func test_the_night_ends_the_ward_moves_on_and_the_money_stays() -> void:
	var r := Rackets.new(rules)
	r.buy_bottles(4)
	r.collect("grocery", false)
	var money := r.money
	var reports := r.end_night()
	assert_eq(reports.size(), 4, "every business had its day")
	assert_eq(r.night, 2)
	assert_eq(r.money, money, "money kept")
	assert_eq(r.bottles, 4, "bottles kept")
	assert_gt(r.barber_stock(), 2, "Sal's man came with more")
	assert_false(r.has_paid("grocery"), "protection is due again")


func test_eddies_crate_runs_out() -> void:
	var r := Rackets.new(rules)
	r.money = 100000
	var boxes := r.eddie().stock
	for k in boxes:
		assert_eq(r.buy_ammo(0), rules.ammo_box)
	assert_eq(r.buy_ammo(0), 0, "no more boxes tonight")
	r.end_night()
	assert_gt(r.buy_ammo(0), 0, "a box came in the day")
	r.money = 0
	assert_eq(r.buy_ammo(0), 0, "no money, no rounds")
	r.money = 100000
	r.eddie().stock = 1
	assert_eq(r.buy_ammo(rules.spare_limit - 3), 3, "only what you can carry")


func test_everything_survives_a_save() -> void:
	var r := Rackets.new(rules)
	r.buy_bottles(3)
	r.collect("copper_owl", true)
	r.end_night()
	r.collect("grocery", false)
	r.town.advance(120.0)
	var copy := Rackets.new(rules)
	copy.from_dict(JSON.parse_string(JSON.stringify(r.to_dict())))
	assert_eq(JSON.stringify(copy.to_dict()), JSON.stringify(r.to_dict()))
	assert_eq(copy.bar_price(), r.bar_price())


func test_a_save_from_before_m005_still_loads() -> void:
	var old := {"money": 2500, "bottles": 3, "night": 4, "sold_by_barber": 2, "bought_by_bar": 0,
		"paid": {"grocery": "asked"}, "paid_total": {"grocery": 1500}}
	var r := Rackets.new(rules)
	r.from_dict(old)
	assert_eq(r.money, 2500)
	assert_eq(r.bottles, 3)
	assert_eq(r.night, 4)
	assert_true(r.has_paid("grocery"))
	assert_eq(r.club().stock, Neighbourhood.riverside().club().stock, "the ward starts afresh")


func test_dollars_read_like_money() -> void:
	assert_eq(Rackets.dollars(1200), "$12")
	assert_eq(Rackets.dollars(150), "$1.50")
	assert_eq(Rackets.dollars(5), "$0.05")
	assert_eq(Rackets.dollars(-250), "-$2.50")
