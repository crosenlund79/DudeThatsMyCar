class_name Rackets
extends RefCounted
## The player's small criminal economy (pure, no scene): money in cents, the
## bootleg bottles he carries, and what each business has done for him
## tonight. Every deal is limited per night (Sal's cupboard, Augie's cellar,
## one protection payment per business), so nothing pays out twice; the
## limits reset only when he sleeps (end_night). Everything here is saved.

var rules: EconomyRules
var money := 0
var bottles := 0
## Nights slept through since the first evening (night 1).
var night := 1
## Tonight: bottles Sal sold you, bottles Augie bought, and who paid up:
## business id -> "asked" | "leaned".
var sold_by_barber := 0
var bought_by_bar := 0
var paid := {}
## All nights: money each business has paid you (cents).
var paid_total := {}


func _init(p_rules: EconomyRules = null) -> void:
	rules = p_rules if p_rules != null else EconomyRules.new()
	money = rules.start_money


static func dollars(cents: int) -> String:
	if cents % 100 == 0:
		return "$%d" % (cents / 100)
	return "$%d.%02d" % [cents / 100, cents % 100]


func barber_stock() -> int:
	return maxi(0, rules.barber_stock - sold_by_barber)


func bar_demand() -> int:
	return maxi(0, rules.bar_demand - bought_by_bar)


## What Augie pays a bottle tonight (less once you have leaned on him).
func bar_price() -> int:
	return rules.bar_price_sore if paid.get("copper_owl", "") == "leaned" else rules.bar_price


func room_to_carry() -> int:
	return maxi(0, rules.carry_limit - bottles)


## Bottles of `n` you could buy from Sal right now.
func can_buy(n: int) -> int:
	return mini(mini(n, barber_stock()), mini(room_to_carry(), money / rules.barber_price))


## Buys up to n bottles from Sal; returns how many changed hands.
func buy_bottles(n: int) -> int:
	var k := can_buy(n)
	money -= k * rules.barber_price
	bottles += k
	sold_by_barber += k
	return k


## Sells Augie as many bottles as he takes tonight; returns how many.
func sell_bottles() -> int:
	var k := mini(bottles, bar_demand())
	money += k * bar_price()
	bottles -= k
	bought_by_bar += k
	return k


func has_paid(business: String) -> bool:
	return paid.has(business)


## Protection from a business ("copper_owl", "grocery"), once a night.
## Returns the cents collected (0 when it already paid tonight).
func collect(business: String, leaned: bool) -> int:
	if has_paid(business):
		return 0
	var amount := 0
	match business:
		"copper_owl":
			amount = rules.bar_protection_leaned if leaned else rules.bar_protection
		"grocery":
			amount = rules.grocer_protection_leaned if leaned else rules.grocer_protection
		_:
			return 0
	paid[business] = "leaned" if leaned else "asked"
	paid_total[business] = int(paid_total.get(business, 0)) + amount
	money += amount
	return amount


## Rounds you could buy right now (0: no money or no room); `spare` is what you carry.
func ammo_for_sale(spare: int) -> int:
	if money < rules.ammo_price:
		return 0
	return mini(rules.ammo_box, maxi(0, rules.spare_limit - spare))


## Buys a box of rounds; returns how many rounds you got (0: no sale).
func buy_ammo(spare: int) -> int:
	var k := ammo_for_sale(spare)
	if k > 0:
		money -= rules.ammo_price
	return k


## Morning: tonight's deals are done; the next evening starts fresh.
func end_night() -> void:
	night += 1
	sold_by_barber = 0
	bought_by_bar = 0
	paid.clear()


func to_dict() -> Dictionary:
	return {"money": money, "bottles": bottles, "night": night, "sold_by_barber": sold_by_barber,
		"bought_by_bar": bought_by_bar, "paid": paid.duplicate(), "paid_total": paid_total.duplicate()}


func from_dict(d: Dictionary) -> void:
	money = int(d.get("money", money))
	bottles = clampi(int(d.get("bottles", bottles)), 0, rules.carry_limit)
	night = maxi(1, int(d.get("night", night)))
	sold_by_barber = int(d.get("sold_by_barber", 0))
	bought_by_bar = int(d.get("bought_by_bar", 0))
	paid = (d.get("paid", {}) as Dictionary).duplicate()
	paid_total = {}
	for k in (d.get("paid_total", {}) as Dictionary):
		paid_total[k] = int(d.paid_total[k])
