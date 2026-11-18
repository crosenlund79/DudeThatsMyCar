extends GutTest
## M003 what Augie and Sal say: answers depend on what you carry and what
## has happened tonight, deals show up in the money, and every page lets you
## walk away.

var r: Rackets
var talk: Conversations


func before_each() -> void:
	r = Rackets.new(EconomyRules.new())
	talk = Conversations.new(r)


func _ids(page: Dictionary) -> Array:
	return page.options.map(func(o: Dictionary) -> String: return o.id)


func _check_page(page: Dictionary) -> void:
	assert_ne(String(page.text), "")
	assert_true(_ids(page).has("bye"), "you can always walk away")
	for o in page.options:
		assert_ne(String(o.text), "")


func test_augie_only_offers_what_makes_sense() -> void:
	var hello := talk.open("augie")
	_check_page(hello)
	assert_eq(hello.speaker, "Augie")
	assert_false(_ids(hello).has("sell"), "nothing to sell yet")
	assert_true(_ids(hello).has("protection"))
	r.bottles = 3
	assert_true(_ids(talk.open("augie")).has("sell"))
	r.collect("copper_owl", false)
	assert_false(_ids(talk.open("augie")).has("protection"), "he has paid tonight")


func test_selling_to_augie_pays_and_says_so() -> void:
	r.bottles = 4
	var money := r.money
	var page := talk.choose("augie", "sell")
	_check_page(page)
	assert_eq(r.money, money + 4 * r.rules.bar_price)
	assert_string_contains(page.text, Rackets.dollars(4 * r.rules.bar_price))
	r.bottles = 3
	r.club().stock = r.club().capacity
	page = talk.choose("augie", "sell")
	assert_string_contains(page.text, "full")
	assert_eq(r.bottles, 3, "no sale when his cellar is full")
	r.club().stock = 0
	r.club().cash = 0
	page = talk.choose("augie", "sell")
	assert_string_contains(page.text, "till")
	assert_eq(r.bottles, 3, "nor when his till is empty")


func test_a_dry_cellar_pays_over_the_odds() -> void:
	r.club().stock = 1
	r.bottles = 2
	assert_string_contains(talk.open("augie").text, "dry")
	var page := talk.choose("augie", "sell")
	assert_string_contains(page.text, Rackets.dollars(2 * r.rules.bar_price_dry))


func test_leaning_on_augie_pays_more_but_sours_the_price() -> void:
	var page := talk.choose("augie", "protection")
	assert_true(_ids(page).has("ask"))
	assert_true(_ids(page).has("lean"))
	page = talk.choose("augie", "lean")
	assert_eq(page.effects.get("paid"), r.club().protection * 3 / 2)
	assert_string_contains(page.text, "forget top dollar")
	r.bottles = 2
	page = talk.choose("augie", "sell")
	assert_string_contains(page.text, Rackets.dollars(r.rules.bar_price - r.rules.bar_sore_discount))
	page = talk.choose("augie", "ask")
	assert_string_contains(page.text, "paid you already")


func test_sal_sells_until_the_cupboard_is_bare() -> void:
	r.sal().stock = 9
	r.money = 100000
	var hello := talk.open("sal")
	_check_page(hello)
	assert_true(_ids(hello).has("buy2"))
	var page := talk.choose("sal", "buy2")
	assert_eq(r.bottles, 2)
	assert_eq(page.effects.get("bought"), 2)
	talk.choose("sal", "buy_all")
	assert_eq(r.bottles, r.rules.carry_limit)
	page = talk.choose("sal", "buy2")
	assert_string_contains(page.text, "coat", "can't carry more")
	r.bottles = 0
	page = talk.choose("sal", "buy_all")
	assert_eq(r.barber_stock(), 0)
	assert_string_contains(talk.open("sal").text, "bare")


func test_sal_wants_cash() -> void:
	r.money = 20
	var page := talk.choose("sal", "buy2")
	assert_string_contains(page.text, "Cash")
	assert_eq(r.bottles, 0)


func test_walking_away_ends_it() -> void:
	assert_true(talk.choose("augie", "bye").is_empty())
	assert_true(talk.choose("sal", "bye").is_empty())


func test_novak_pays_once_and_runs_for_the_copper_if_pushed() -> void:
	var hello := talk.open("novak")
	_check_page(hello)
	assert_eq(hello.speaker, "Mr. Novak")
	assert_true(_ids(hello).has("protection"))
	var page := talk.choose("novak", "protection")
	assert_true(_ids(page).has("ask") and _ids(page).has("lean"))
	page = talk.choose("novak", "lean", {"gun_drawn": true})
	assert_eq(page.effects.get("paid"), r.town.get_business("grocery").protection * 3 / 2)
	assert_true(page.effects.get("police", false), "he won't keep quiet about it")
	assert_false(_ids(talk.open("novak")).has("protection"), "nothing more tonight")
	assert_eq(talk.choose("novak", "ask").get("effects", {}).get("paid", 0), 0)


func test_asking_novak_nicely_keeps_the_peace() -> void:
	var page := talk.choose("novak", "ask")
	assert_eq(page.effects.get("paid"), r.town.get_business("grocery").protection)
	assert_false(page.effects.get("police", false))


func test_a_broke_novak_cannot_pay_and_says_why() -> void:
	var g := r.town.get_business("grocery")
	g.cash = 100
	g.missed_delivery = 4
	assert_string_contains(talk.open("novak").text, "truck")
	var page := talk.choose("novak", "ask")
	assert_eq(page.effects.get("paid"), 0)
	assert_string_contains(page.text, "truck")


func test_eddie_sells_rounds_not_a_catalogue() -> void:
	var hello := talk.open("eddie", {"spare": 0})
	_check_page(hello)
	assert_eq(_ids(hello), ["ammo", "heavy", "bye"], "a box of rounds, nothing more")
	var money := r.money
	var page := talk.choose("eddie", "ammo", {"spare": 0})
	assert_eq(page.effects.get("rounds"), r.rules.ammo_box)
	assert_eq(r.money, money - r.rules.ammo_price)
	page = talk.choose("eddie", "ammo", {"spare": r.rules.spare_limit})
	assert_false(page.effects.has("rounds"), "no room for more")
	r.money = 10
	page = talk.choose("eddie", "ammo", {"spare": 0})
	assert_string_contains(page.text, "Money first")
	assert_false(page.effects.has("rounds"))


func test_lindqvist_points_to_the_back() -> void:
	_check_page(talk.open("lindqvist"))
	assert_string_contains(talk.choose("lindqvist", "back").text, "Through the door")
