extends "res://tests/support/city_test.gd"
## M003 the grocer and the gun dealer in the game: Mr. Novak pays his
## protection once a night, and if you lean on him he runs out for the copper
## once you have gone; Eddie in the back room of Lindqvist Hardware sells
## a box of .45 rounds that goes into your pocket; an empty gun only clicks.


func test_asking_novak_nicely_keeps_the_copper_on_his_round() -> void:
	var start: int = main.rackets.money
	await talk_to("grocery", "novak")
	await answer_with("protection")
	await answer_with("ask")
	assert_eq(main.rackets.money, start + main.rackets.town.get_business("grocery").protection)
	await press_e()
	await walk_to(Vector2(1828, 720), 6.0, 300)
	await wait_physics_frames(60)
	assert_false(main.officer.brain.is_hunting())


func test_leaning_on_novak_brings_the_copper() -> void:
	var start: int = main.rackets.money
	await talk_to("grocery", "novak")
	await answer_with("protection")
	await answer_with("lean")
	assert_eq(main.rackets.money, start + main.rackets.town.get_business("grocery").protection * 3 / 2)
	await press_e()
	assert_false(main.officer.brain.is_hunting(), "not while you are still in the shop")
	await walk_to(Vector2(1828, 700), 6.0, 300)
	await wait_physics_frames(10)
	assert_true(main.officer.brain.is_hunting(), "Novak ran out shouting for him")
	assert_string_contains(main.hud.notice_label.text, "Novak")
	await talk_to("grocery", "novak")
	var ids: Array = main._page.options.map(func(o: Dictionary) -> String: return o.id)
	assert_false(ids.has("protection"), "and he won't pay twice")


func test_through_the_hardware_store_to_eddie_for_rounds() -> void:
	var plan: InteriorPlan = main.interiors.view_of("hardware").plan
	walker().place(plan.outside_door(0, 20.0), PI / 2)
	await wait_physics_frames(2)
	for p in [plan.inside_door(0, 20.0), Vector2(1100, 830), Vector2(1095, 885), Vector2(1095, 925), Vector2(1040, 950)]:
		await walk_to(p, 6.0, 300)
	assert_lt(walker().global_position.distance_to(Vector2(1040, 950)), 8.0, "walked into the back room")
	assert_string_contains(main.hud.prompt_label.text, "Talk to Eddie")
	var spare: int = walker().gun.spare
	var start: int = main.rackets.money
	await press_e()
	assert_eq(main.talking, "eddie")
	await answer_with("ammo")
	assert_eq(walker().gun.spare, spare + main.economy_rules.ammo_box)
	assert_eq(main.rackets.money, start - main.economy_rules.ammo_price)


func test_an_empty_gun_only_clicks() -> void:
	walker().gun.ammo = 1
	walker().gun.spare = 0
	walker().place(Vector2(2300, 600), 0.0)
	await click(Vector2(2500, 600))
	await aim_for(Vector2(2500, 600), 30)
	assert_eq(walker().gun.ammo, 0)
	watch_signals(player())
	await click(Vector2(2500, 600))
	await aim_for(Vector2(2500, 600), 30)
	assert_signal_not_emitted(player(), "fired")
	assert_string_contains(main.hud.notice_label.text, "Out of rounds")
