extends "res://tests/support/city_test.gd"
## M003 the booze run in the game: buy rye from Sal at the barbershop, carry
## it to the Copper Owl, sell it to Augie for more, collect his protection
## money once, with the HUD showing what you carry. While you talk you stand
## still; E walks away.


func test_buy_from_sal_and_sell_to_augie_at_a_profit() -> void:
	var start: int = main.rackets.money
	await talk_to("barber_shop", "sal")
	assert_eq(main.dialogue.talking, "sal", "talking to Sal")
	assert_true(main.hud.dialogue_panel.visible)
	await answer_with("buy_all")
	assert_eq(main.rackets.bottles, 6)
	assert_string_contains(main.hud.purse_label.text, "6 bottles")
	assert_lt(main.rackets.money, start)
	await answer_with("bye")
	assert_eq(main.dialogue.talking, "", "the talk is over")
	assert_false(main.hud.dialogue_panel.visible)
	await talk_to("copper_owl", "augie")
	await answer_with("sell")
	assert_eq(main.rackets.bottles, 0)
	assert_gt(main.rackets.money, start, "a profit on the run")
	assert_eq(main.rackets.money, start + 6 * (main.economy_rules.bar_price - main.economy_rules.barber_price))


func test_protection_once_a_night() -> void:
	var start: int = main.rackets.money
	await talk_to("copper_owl", "augie")
	await answer_with("protection")
	await answer_with("ask")
	assert_eq(main.rackets.money, start + main.rackets.club().protection)
	await press_e()
	assert_eq(main.dialogue.talking, "", "E walks away")
	await talk_to("copper_owl", "augie")
	var ids: Array = main.dialogue.page.options.map(func(o: Dictionary) -> String: return o.id)
	assert_false(ids.has("protection"), "no second collection tonight")


func test_you_stand_still_while_talking() -> void:
	await talk_to("barber_shop", "sal")
	var at := walker().global_position
	await hold(Vector2(1, 0), 30)
	assert_almost_eq(walker().global_position.distance_to(at), 0.0, 0.5)
	assert_eq(main.dialogue.talking, "sal")
