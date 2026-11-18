class_name Rackets
extends RefCounted
## Danny's side of the ward's economy (pure, no scene): his money in cents,
## the bootleg bottles he carries, and his dealings with the businesses of
## the Neighbourhood. Every deal moves exact cents between his pocket and a
## till and real stock between a cupboard, his coat and a cellar, so nothing
## pays out more than the ward holds; protection is once a night per
## business and as much as its till allows. Everything here is saved.

var rules: EconomyRules
var town: Neighbourhood
## Rourke, who the protection money belongs to.
var boss: Boss
var money := 0
## Of Danny's money: Rourke's protection, collected and not yet handed over.
var held := 0
## All nights: what Danny kept back of Rourke's money, and the commission
## Rourke handed back as Danny's end.
var skimmed := 0
var commission_earned := 0
## Counts every protection collection (orders them for Rourke's books).
var seq := 0
var bottles := 0
## Nights slept through since the first evening (night 1).
var night := 1
## Tonight: bottles Sal sold you, bottles Augie bought, and who paid up
## (business id -> "asked" | "leaned") and how much (business id -> cents).
var sold_by_barber := 0
var bought_by_bar := 0
var paid := {}
var paid_amount := {}
## The collection number of each business's payment tonight.
var last_seq := {}
## All nights: money each business has paid you (cents).
var paid_total := {}


func _init(p_rules: EconomyRules = null) -> void:
	rules = p_rules if p_rules != null else EconomyRules.new()
	money = rules.start_money
	town = Neighbourhood.riverside()
	boss = Boss.new()
	boss.observe_club(town.club(), night)
	boss.expect(town)


static func dollars(cents: int) -> String:
	var sign := "-" if cents < 0 else ""
	cents = absi(cents)
	if cents % 100 == 0:
		return "%s$%d" % [sign, cents / 100]
	return "%s$%d.%02d" % [sign, cents / 100, cents % 100]


func sal() -> Business:
	return town.get_business("barber_shop")


func club() -> Business:
	return town.get_business("copper_owl")


func eddie() -> Business:
	return town.get_business("eddie")


## Bottles in Sal's cupboard right now.
func barber_stock() -> int:
	return sal().stock


## What Sal asks a bottle: dearer when his cupboard is nearly bare.
func barber_price() -> int:
	var s := sal()
	if s.stock <= 2:
		return rules.barber_price_scarce
	if s.stock >= s.capacity - 2:
		return rules.barber_price_plenty
	return rules.barber_price


## Bottles Augie takes tonight: room in his cellar, as far as his till goes
## (none while Rourke has told him not to deal with Danny).
func bar_demand() -> int:
	if boss.ban:
		return 0
	var c := club()
	return maxi(0, mini(c.capacity - c.stock, c.cash / maxi(bar_price(), 1)))


## What Augie pays a bottle tonight: more when the cellar runs dry, less when
## it is nearly full, and less the night you have leaned on him.
func bar_price() -> int:
	var c := club()
	var p := rules.bar_price
	if c.is_short():
		p = rules.bar_price_dry
	elif c.stock >= c.capacity - 4:
		p = rules.bar_price_full
	if paid.get("copper_owl", "") == "leaned":
		p -= rules.bar_sore_discount
	return p


func room_to_carry() -> int:
	return maxi(0, rules.carry_limit - bottles)


## Bottles of `n` you could buy from Sal right now.
func can_buy(n: int) -> int:
	return mini(mini(n, barber_stock()), mini(room_to_carry(), money / barber_price()))


## Buys up to n bottles from Sal; returns how many changed hands.
func buy_bottles(n: int) -> int:
	var price := barber_price()
	var k := can_buy(n)
	money -= k * price
	sal().cash += k * price
	sal().stock -= k
	bottles += k
	sold_by_barber += k
	return k


## Sells Augie as many bottles as he takes tonight; returns how many.
func sell_bottles() -> int:
	var price := bar_price()
	var k := mini(bottles, bar_demand())
	money += k * price
	club().cash -= k * price
	club().stock += k
	bottles -= k
	bought_by_bar += k
	if k > 0:
		boss.see_rye_sale(k * price)  # from his corner table he sees it all
	return k


func has_paid(business: String) -> bool:
	return paid.has(business)


## What a business would hand over for protection right now (no deal made).
func protection_offer(business: String, leaned: bool) -> int:
	var b := town.get_business(business)
	return 0 if b == null or has_paid(business) else b.protection_due(leaned)


## Protection from a business ("copper_owl", "grocery"), once a night: as
## much as its till allows (asked, it keeps back what tomorrow's delivery
## costs). Returns the cents collected; 0 when it has paid tonight, is not on
## the list, or has nothing to give (the visit still counts for tonight).
func collect(business: String, leaned: bool) -> int:
	var b := town.get_business(business)
	if has_paid(business) or b == null or b.protection <= 0:
		return 0
	var amount := b.protection_due(leaned)
	b.cash -= amount
	money += amount
	paid[business] = "leaned" if leaned else "asked"
	paid_amount[business] = amount
	paid_total[business] = int(paid_total.get(business, 0)) + amount
	held += amount
	seq += 1
	last_seq[business] = seq
	if business == "copper_owl":
		boss.learn_paid(business, amount, night, seq)  # Augie tells Rourke at once
	return amount


## Hands Rourke `cents` (as far as Danny's pocket goes). `claim`: "" or
## "bad_business". What Danny still held of Rourke's money beyond it, he
## keeps (skimming). Rourke hands back his commission on the protection.
## Returns Rourke's verdict (Boss.settle) plus {handed, kept}.
func pay_boss(cents: int, claim: String = "") -> Dictionary:
	cents = clampi(cents, 0, money)
	var protection_part := mini(cents, held)
	var kept := maxi(0, held - cents)
	money -= cents
	boss.purse += cents
	skimmed += kept
	held = 0
	var out := boss.settle(cents, protection_part, claim, town, night, seq + 1)
	money += out.cut
	boss.purse -= out.cut
	commission_earned += out.cut
	out["handed"] = cents
	out["kept"] = kept
	return out


## Rounds you could buy right now (0: no money, no room, or Eddie's crate is
## empty); `spare` is what you carry.
func ammo_for_sale(spare: int) -> int:
	if money < rules.ammo_price or eddie().stock <= 0:
		return 0
	return mini(rules.ammo_box, maxi(0, rules.spare_limit - spare))


## Buys a box of rounds; returns how many rounds you got (0: no sale).
func buy_ammo(spare: int) -> int:
	var k := ammo_for_sale(spare)
	if k > 0:
		money -= rules.ammo_price
		eddie().cash += rules.ammo_price
		eddie().stock -= 1
	return k


## Morning: the rest of the night's trade, the day's business all over the
## ward, and the next evening starts fresh. Returns the businesses' reports.
func end_night() -> Array:
	night += 1
	sold_by_barber = 0
	bought_by_bar = 0
	paid.clear()
	paid_amount.clear()
	last_seq.clear()
	var reports := town.close_night()
	boss.end_night(town, night)
	return reports


func to_dict() -> Dictionary:
	return {"money": money, "bottles": bottles, "night": night, "sold_by_barber": sold_by_barber,
		"bought_by_bar": bought_by_bar, "paid": paid.duplicate(), "paid_amount": paid_amount.duplicate(),
		"paid_total": paid_total.duplicate(), "town": town.to_dict(), "boss": boss.to_dict(), "held": held,
		"skimmed": skimmed, "commission_earned": commission_earned, "seq": seq, "last_seq": last_seq.duplicate()}


## Restores a saved game; a save from before M005 (no businesses yet) starts
## the ward afresh around the saved money and bottles.
func from_dict(d: Dictionary) -> void:
	money = int(d.get("money", money))
	bottles = clampi(int(d.get("bottles", bottles)), 0, rules.carry_limit)
	night = maxi(1, int(d.get("night", night)))
	sold_by_barber = int(d.get("sold_by_barber", 0))
	bought_by_bar = int(d.get("bought_by_bar", 0))
	paid = (d.get("paid", {}) as Dictionary).duplicate()
	paid_amount = {}
	for k in (d.get("paid_amount", {}) as Dictionary):
		paid_amount[k] = int(d.paid_amount[k])
	paid_total = {}
	for k in (d.get("paid_total", {}) as Dictionary):
		paid_total[k] = int(d.paid_total[k])
	if d.has("town"):
		town.from_dict(d.town)
	if d.has("boss"):
		boss.from_dict(d.boss)
	else:
		boss.observe_club(town.club(), night)
		boss.expect(town)
	held = int(d.get("held", 0))
	skimmed = int(d.get("skimmed", 0))
	commission_earned = int(d.get("commission_earned", 0))
	seq = int(d.get("seq", 0))
	last_seq = {}
	for k in (d.get("last_seq", {}) as Dictionary):
		last_seq[k] = int(d.last_seq[k])
