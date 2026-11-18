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
## What people remember about Danny, and the talk about town.
var memory := Memories.new()
var rumours := Rumours.new()
## Danny's private loans: keeper -> {principal, owed, due (night)}.
var loans := {}
## Things that happened in the ward overnight: {kind, business, night}.
var incidents: Array = []
## What Rourke's collectors took from Danny this morning (cents).
var collected := 0
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


## What Sal asks a bottle: dearer when his cupboard is nearly bare, cheaper
## when it is full, and a dime off for a regular (two deals in three nights).
func barber_price() -> int:
	var s := sal()
	var p := rules.barber_price
	if s.stock <= 2:
		p = rules.barber_price_scarce
	elif s.stock >= s.capacity - 2:
		p = rules.barber_price_plenty
	if is_regular():
		p -= 10
	return p


## Sal counts Danny a regular after two good deals in three nights.
func is_regular() -> bool:
	return memory.recent("sal", "deal", night, 3) >= 2


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
	if k > 0 and sold_by_barber == k:
		memory.remember("sal", "deal", night)  # one good deal a night counts
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
		if bought_by_bar == k:
			memory.remember("augie", "deal", night)
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
	if leaned:
		memory.remember(b.keeper, "threat", night, business)
		rumours.start("threat", b.keeper, night, {"business": business})
	elif amount < b.protection:
		memory.remember(b.keeper, "dispute", night, "could not pay it all")
	rumours.start("paid", b.keeper, night, {"business": business, "cents": amount, "seq": seq})
	return amount


## What a business still needs for tomorrow's delivery, beyond its till.
func shortfall_for_truck(business: String) -> int:
	var b := town.get_business(business)
	var need := mini(b.supply, maxi(0, b.capacity - b.stock)) * b.supply_cost
	return maxi(0, need - b.cash)


## Danny lends a shopkeeper money for the truck: a favour he remembers, to be
## repaid with a quarter on top within three nights. Returns the cents lent.
func lend(business: String, cents: int) -> int:
	var b := town.get_business(business)
	if b == null or loans.has(b.keeper) or cents <= 0 or cents > money:
		return 0
	money -= cents
	b.cash += cents
	loans[b.keeper] = {"business": business, "principal": cents, "owed": cents * 5 / 4, "due": night + 3}
	memory.remember(b.keeper, "favour", night, "lent %s" % dollars(cents))
	memory.promise(b.keeper, "danny", "repay", cents * 5 / 4, night + 3)
	rumours.start("favour", b.keeper, night, {"business": business, "cents": cents})
	return cents


## The borrower pays back what he can spare beyond tomorrow's delivery.
## Returns the cents repaid (the loan ends when it is all paid).
func collect_loan(keeper: String) -> int:
	if not loans.has(keeper):
		return 0
	var loan: Dictionary = loans[keeper]
	var b := town.get_business(loan.business)
	var need := mini(b.supply, maxi(0, b.capacity - b.stock)) * b.supply_cost
	var pay := clampi(b.cash - need, 0, int(loan.owed))
	b.cash -= pay
	money += pay
	loan.owed = int(loan.owed) - pay
	if int(loan.owed) <= 0:
		loans.erase(keeper)
		memory.keep(keeper, "repay", night)
		memory.remember(keeper, "deal", night, "paid back")
	return pay


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
	if out.caught:
		memory.remember("rourke", "lie", night)
		rumours.start("lie", "rourke", night)
	elif out.accepted:
		memory.remember("rourke", "deal", night)
		if boss.arrears == 0:
			memory.keep("danny", "pay", night)
	elif cents > 0 or claim != "":
		memory.remember("rourke", "dispute", night)
	return out


## Danny tells Rourke he will have it tomorrow (and had better).
func promise_boss() -> void:
	if memory.open_promise("danny", "pay").is_empty():
		memory.promise("danny", "rourke", "pay", boss.arrears, night + 1)


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
	# overnight: what the books say happened in the ward
	for rep in reports:
		if int(rep.missed) > 0 and town.get_business(rep.id).protection > 0:
			var b := town.get_business(rep.id)
			incidents.append({"kind": "short_delivery", "business": rep.id, "night": night})
			rumours.start("short", b.keeper, night, {"business": rep.id})
	# a night of talk
	for learnt in rumours.spread():
		_hear(learnt.to, learnt.rumour)
	for p in memory.end_night(night):
		if p.by == "danny" and p.to == "rourke":
			boss.trust = maxi(0, boss.trust - 5)
			boss.hear("Dimes promised and didn't pay", night)
	# out of patience and still not square after a night without the rye trade:
	# Rourke's collectors take what is owed from what Danny has on him
	collected = 0
	if boss.ban:
		boss.ban_nights += 1
		if boss.ban_nights >= 2 and boss.arrears > 0 and money > 0:
			collected = mini(money, boss.arrears)
			money -= collected
			boss.purse += collected
			boss.arrears -= collected
			memory.remember("rourke", "dispute", night, "his boys collected")
			incidents.append({"kind": "collected", "business": "", "night": night})
	else:
		boss.ban_nights = 0
	boss.expect(town)
	rumours.forget(night)
	incidents = incidents.filter(func(i: Dictionary) -> bool: return night - int(i.night) <= 3)
	return reports


## Someone hears a piece of talk.
func _hear(person: String, r: Dictionary) -> void:
	if person == "rourke":
		match r.kind:
			"paid":
				if boss.learn_paid(r.business, int(r.cents), int(r.night), int(r.seq)) > 0:
					memory.remember("rourke", "lie", night, "found out")
			"short":
				boss.learn(r.business, "short", night)
				boss.hear("%s is struggling" % town.get_business(r.business).name, night)
			"threat":
				boss.hear("Dimes leaned on %s" % town.get_business(r.business).name, night)
			"favour":
				boss.hear("Dimes is lending money to %s" % town.get_business(r.business).name, night)
		return
	match r.kind:
		"threat":
			if r.origin != person:
				memory.remember(person, "heard_threat", night)
		"favour":
			if r.origin != person:
				memory.remember(person, "heard_favour", night)


## The newest piece of talk a person can pass on to Danny (or {}).
func gossip(person: String) -> Dictionary:
	for r in rumours.known_to(person):
		if r.origin != person and r.kind in ["short", "threat", "favour", "lie"]:
			return r
	return {}


func to_dict() -> Dictionary:
	return {"money": money, "bottles": bottles, "night": night, "sold_by_barber": sold_by_barber,
		"bought_by_bar": bought_by_bar, "paid": paid.duplicate(), "paid_amount": paid_amount.duplicate(),
		"paid_total": paid_total.duplicate(), "town": town.to_dict(), "boss": boss.to_dict(), "held": held,
		"skimmed": skimmed, "commission_earned": commission_earned, "seq": seq, "last_seq": last_seq.duplicate(),
		"memory": memory.to_dict(), "rumours": rumours.to_dict(), "loans": loans.duplicate(true),
		"incidents": incidents.duplicate(true)}


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
	memory.from_dict(d.get("memory", {}))
	rumours.from_dict(d.get("rumours", {}))
	loans = {}
	var l: Dictionary = d.get("loans", {})
	for k in l:
		loans[k] = {"business": String(l[k].business), "principal": int(l[k].principal), "owed": int(l[k].owed),
			"due": int(l[k].due)}
	incidents = []
	for i in d.get("incidents", []):
		incidents.append({"kind": String(i.kind), "business": String(i.business), "night": int(i.night)})
