extends GutTest
## M003 the small criminal economy (Rackets): buying rye from Sal, selling it
## to Augie at a profit, protection money once a night, ammunition, the
## nightly limits that stop any deal paying out twice, and saving it all.

var rules: EconomyRules


func before_each() -> void:
	rules = EconomyRules.new()


func test_a_booze_run_turns_a_profit() -> void:
	var r := Rackets.new(rules)
	assert_eq(r.money, rules.start_money)
	var bought := r.buy_bottles(6)
	assert_eq(bought, 6)
	assert_eq(r.money, rules.start_money - 6 * rules.barber_price)
	assert_eq(r.sell_bottles(), 6)
	assert_eq(r.bottles, 0)
	assert_eq(r.money, rules.start_money + 6 * (rules.bar_price - rules.barber_price), "bought low, sold high")


func test_buying_is_limited_by_money_stock_and_what_you_can_carry() -> void:
	var r := Rackets.new(rules)
	r.money = rules.barber_price * 2 + 10
	assert_eq(r.buy_bottles(6), 2, "only what you can pay for")
	r.money = 100000
	assert_eq(r.buy_bottles(10), rules.carry_limit - 2, "only what fits under a coat")
	r.sell_bottles()
	assert_eq(r.buy_bottles(10), 0, "Sal's cupboard is empty for tonight")
	assert_eq(r.barber_stock(), 0)


func test_augie_buys_only_so_much_a_night() -> void:
	var r := Rackets.new(rules)
	r.bottles = 6
	r.bought_by_bar = rules.bar_demand - 2
	assert_eq(r.sell_bottles(), 2)
	assert_eq(r.bottles, 4, "you keep the rest")
	assert_eq(r.sell_bottles(), 0)


func test_protection_is_paid_once_a_night() -> void:
	var r := Rackets.new(rules)
	assert_eq(r.collect("copper_owl", false), rules.bar_protection)
	assert_eq(r.collect("copper_owl", false), 0, "already paid tonight")
	assert_eq(r.collect("copper_owl", true), 0)
	assert_eq(r.collect("grocery", true), rules.grocer_protection_leaned)
	assert_eq(r.collect("nobody", false), 0)
	assert_eq(r.money, rules.start_money + rules.bar_protection + rules.grocer_protection_leaned)


func test_leaning_on_augie_costs_you_at_the_bar() -> void:
	var r := Rackets.new(rules)
	assert_eq(r.bar_price(), rules.bar_price)
	r.collect("copper_owl", true)
	assert_eq(r.bar_price(), rules.bar_price_sore, "he pays less for your rye tonight")
	r.end_night()
	assert_eq(r.bar_price(), rules.bar_price, "and gets over it by the next night")


func test_no_deal_pays_out_twice_however_often_you_try() -> void:
	var r := Rackets.new(rules)
	for i in 100:
		r.buy_bottles(6)
		r.sell_bottles()
		r.collect("copper_owl", i % 2 == 0)
		r.collect("grocery", i % 3 == 0)
	var best_night := rules.start_money + rules.barber_stock * (rules.bar_price - rules.barber_price) \
		+ rules.bar_protection_leaned + rules.grocer_protection_leaned
	assert_lte(r.money, best_night, "one night's takings at most")


func test_the_night_ends_and_the_money_stays() -> void:
	var r := Rackets.new(rules)
	r.buy_bottles(4)
	r.collect("grocery", false)
	var money := r.money
	r.end_night()
	assert_eq(r.night, 2)
	assert_eq(r.money, money, "money kept")
	assert_eq(r.bottles, 4, "bottles kept")
	assert_eq(r.barber_stock(), rules.barber_stock, "a fresh cupboard")
	assert_false(r.has_paid("grocery"), "protection is due again")


func test_ammunition_costs_money_and_room() -> void:
	var r := Rackets.new(rules)
	r.money = rules.ammo_price
	assert_eq(r.buy_ammo(0), rules.ammo_box)
	assert_eq(r.money, 0)
	assert_eq(r.buy_ammo(0), 0, "no money, no rounds")
	r.money = 100000
	assert_eq(r.buy_ammo(rules.spare_limit - 3), 3, "only what you can carry")
	assert_eq(r.buy_ammo(rules.spare_limit), 0)


func test_everything_survives_a_save() -> void:
	var r := Rackets.new(rules)
	r.buy_bottles(3)
	r.collect("copper_owl", true)
	r.end_night()
	r.collect("grocery", false)
	var copy := Rackets.new(rules)
	copy.from_dict(JSON.parse_string(JSON.stringify(r.to_dict())))
	assert_eq(copy.to_dict(), r.to_dict())
	assert_eq(copy.bar_price(), r.bar_price())


func test_dollars_read_like_money() -> void:
	assert_eq(Rackets.dollars(1200), "$12")
	assert_eq(Rackets.dollars(150), "$1.50")
	assert_eq(Rackets.dollars(5), "$0.05")
