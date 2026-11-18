extends GutTest
## M005 the businesses of the ward as numbers that live on their own: the
## club drinks its cellar dry through the night, the shops trade by day,
## suppliers come each morning and are paid from the till; a till emptied
## in the night means a short delivery and thin shelves, a fair arrangement
## keeps a shop going. Deterministic, and money only moves, never appears.

const NIGHT := 600.0


func _ward() -> Neighbourhood:
	return Neighbourhood.riverside()


func test_the_ward_has_its_businesses() -> void:
	var n := _ward()
	for id in ["copper_owl", "barber_shop", "grocery", "eddie"]:
		assert_not_null(n.get_business(id), id)
	assert_eq(n.club().keeper, "augie")
	assert_gt(n.club().protection, 0, "the club is on Rourke's list")
	assert_gt(n.get_business("grocery").protection, 0, "so is Novak")
	assert_eq(n.get_business("barber_shop").protection, 0, "Sal is not")


func test_the_club_sells_through_the_night_as_the_clock_runs() -> void:
	var n := _ward()
	var c := n.club()
	var stock := c.stock
	var cash := c.cash
	n.advance(NIGHT * 0.5)
	assert_lt(c.stock, stock, "drinks served by midnight")
	assert_gt(c.cash, cash)
	assert_almost_eq(n.night_done, 0.5, 0.001)
	n.advance(NIGHT)  # more than is left: only the rest of the night
	assert_almost_eq(n.night_done, 1.0, 0.001)


func test_a_dry_cellar_loses_money_a_supplied_one_makes_it() -> void:
	var dry := _ward()
	var fed := _ward()
	for k in 6:
		dry.close_night()
		fed.club().stock = mini(fed.club().stock + 6, fed.club().capacity)  # Danny's six bottles a night
		fed.club().cash -= 6 * 300
		fed.close_night()
	assert_true(dry.club().is_short(), "nobody brings rye: the cellar runs dry")
	assert_lt(dry.club().trend(), 0, "and the club loses money")
	assert_gt(fed.club().trend(), 0, "supplied, it pays its way")


func test_suppliers_restock_shops_paid_from_the_till() -> void:
	var n := _ward()
	var sal := n.get_business("barber_shop")
	sal.stock = 0
	var cash := sal.cash
	var report: Dictionary = n.close_night()[1]
	assert_eq(report.id, "barber_shop")
	assert_eq(report.delivered, sal.supply, "his man from Cicero came")
	assert_gt(sal.stock, 0)
	assert_eq(sal.history.size(), 1)
	assert_lt(sal.cash, cash + sal.fixed_takings + sal.demand * sal.price, "the rye cost him")


func test_an_emptied_till_means_a_short_delivery_and_thin_shelves() -> void:
	var n := _ward()
	var g := n.get_business("grocery")
	g.cash = 300  # Danny took it all last night
	g.stock = 0
	n.close_night()
	assert_gt(g.missed_delivery, 0, "the truck came half empty")
	assert_lt(g.last_profit, 600, "and the day's trade was thin")


func test_a_fair_arrangement_keeps_novak_going_leaning_breaks_him() -> void:
	var fair := _ward()
	var hard := _ward()
	var missed := 0
	for k in 6:
		var gf := fair.get_business("grocery")
		gf.cash -= gf.protection_due(false)
		fair.close_night()
		var gh := hard.get_business("grocery")
		gh.cash -= gh.protection_due(true)
		hard.close_night()
		missed += gh.missed_delivery
	var fair_g := fair.get_business("grocery")
	assert_eq(fair_g.missed_delivery, 0, "asked politely, he always pays the truck")
	assert_gte(fair_g.cash, 2100 - 200, "and stays afloat")
	assert_gt(missed, 0, "leaned on every night, deliveries come short")
	assert_lt(hard.get_business("grocery").protection_due(false), fair_g.protection_due(false),
		"and he soon has less to pay anyone")


func test_the_same_nights_give_the_same_ward() -> void:
	var a := _ward()
	var b := _ward()
	for k in 5:
		a.advance(250.0)
		b.advance(250.0)
		a.close_night()
		b.close_night()
	assert_eq(a.to_dict(), b.to_dict())


func test_the_ward_survives_a_save() -> void:
	var a := _ward()
	a.advance(300.0)
	a.close_night()
	a.advance(120.0)
	var b := _ward()
	b.from_dict(JSON.parse_string(JSON.stringify(a.to_dict())))
	assert_eq(JSON.stringify(b.to_dict()), JSON.stringify(a.to_dict()))
