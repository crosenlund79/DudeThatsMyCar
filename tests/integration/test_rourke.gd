extends "res://tests/support/city_test.gd"
## M005 Rourke in the game: at his corner table in the Copper Owl, reached
## through the club with the normal controls; the HUD shows how much of
## Danny's money is his; settling up pays Danny his end; owing him too long
## stops Augie buying Danny's rye.


func _club() -> InteriorPlan:
	return main.interiors.view_of("copper_owl").plan


func test_he_sits_at_his_table_in_the_copper_owl() -> void:
	assert_not_null(main.interiors.person("copper_owl", "rourke"))
	assert_true(await walk_in_to(_club(), "rourke"))
	assert_string_contains(main.hud.prompt_label.text, "Talk to Rourke")
	await press_e()
	assert_eq(main.talking, "rourke")
	assert_string_contains(main._page.text, Rackets.dollars(main.rackets.boss.expected))


func test_collect_then_settle_up() -> void:
	await talk_to("copper_owl", "augie")
	await answer_with("protection")
	await answer_with("ask")
	await answer_with("bye")
	assert_eq(main.rackets.held, main.rackets.club().protection)
	assert_string_contains(main.hud.purse_label.text, "Rourke's")
	var before: int = main.rackets.money
	await talk_to("copper_owl", "rourke")
	await answer_with("envelope")
	await answer_with("thin")  # Novak not collected: a thin night, all of it
	assert_eq(main.rackets.held, 0)
	assert_false(main.hud.purse_label.text.contains("Rourke's"))
	assert_lt(main.rackets.money, before, "his money went to him")
	assert_true(main.rackets.boss.settled)


func test_owing_him_stops_the_rye_trade_at_the_club() -> void:
	main.rackets.boss.ban = true
	main.rackets.bottles = 4
	await talk_to("copper_owl", "augie")
	assert_string_contains(main._page.text, "Rourke")
	await answer_with("sell")
	assert_eq(main.rackets.bottles, 4, "Augie won't buy")


func test_his_boys_collect_after_a_night_cut_off() -> void:
	var b: Boss = main.rackets.boss
	b.ban = true
	b.ban_nights = 1
	b.patience = 0
	b.arrears = 700
	b.expected = 700  # what he worked out at dusk: the debt (nothing else is due)
	main.rackets.money = 2000
	await talk_to("home", "bed")
	await answer_with("sleep")
	assert_eq(main.rackets.collected, 700)
	assert_eq(main.rackets.money, 1300)
	assert_string_contains(main.hud.wake_label.text, "Rourke's boys")
