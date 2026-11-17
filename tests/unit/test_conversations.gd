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
	r.bought_by_bar = r.rules.bar_demand
	page = talk.choose("augie", "sell")
	assert_string_contains(page.text, "full")
	assert_eq(r.bottles, 3, "no sale when his cellar is full")


func test_leaning_on_augie_pays_more_but_sours_the_price() -> void:
	var page := talk.choose("augie", "protection")
	assert_true(_ids(page).has("ask"))
	assert_true(_ids(page).has("lean"))
	page = talk.choose("augie", "lean")
	assert_eq(page.effects.get("paid"), r.rules.bar_protection_leaned)
	assert_string_contains(page.text, "forget top dollar")
	r.bottles = 2
	page = talk.choose("augie", "sell")
	assert_string_contains(page.text, Rackets.dollars(r.rules.bar_price_sore))
	page = talk.choose("augie", "ask")
	assert_string_contains(page.text, "paid you already")


func test_sal_sells_until_the_cupboard_is_bare() -> void:
	r.rules.barber_stock = 10
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
