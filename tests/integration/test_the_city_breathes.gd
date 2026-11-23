extends "res://tests/support/city_test.gd"
## M015 the playthrough: two nights across the grown city with the normal
## controls for every talk, three saves and loads, and Danny's money counted
## to the cent. Night one: Danny drives his own sedan up Wharf Street under
## the railroad into Lincoln Terrace and leaves it there; in Canal Market he
## has Mrs. Dvorak's coffee, reads the market's noticeboard, eats at the
## Golden Lantern and learns who "K." is, buys Kaz Wrobel off at midnight and
## takes Hrabal's thanks; at the Paradise he dances once and pays for a tune,
## and takes the bandleader's card (saved and loaded in the ballroom); back
## at the Copper Owl the card goes to the Bird; home to bed. Night two: the
## sedan is where he left it, tonight's limits are fresh and the business he
## settled stays settled; a dollar for the Belvedere's night manager, and the
## word goes to Rourke; saved and loaded; the notebook has three closed cases.

const SAVE := "user://test_the_city_breathes.json"


func after_each() -> void:
	super()
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _reload() -> void:
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = false
	main.save_path = SAVE
	main.settings_path = ""
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(5)


## Danny on the pavement before room `id` of `district` (the district built).
func _to(id: String, district: String) -> InteriorPlan:
	main.world.load_now(district)
	for p in (main.world.layouts[district] as DistrictLayout).interiors:
		if (p as InteriorPlan).id == id:
			walker().place((p as InteriorPlan).outside_door(0, 40.0), (-((p as InteriorPlan).doors[0].side as Vector2)).angle())
	await wait_physics_frames(3)
	return main.interiors.plan_named(id)


## Walks in through the door to `spot` and presses E.
func _talk(id: String, district: String, spot: String) -> void:
	var p := await _to(id, district)
	assert_true(await walk_in_to(p, spot), "walked in to %s" % spot)
	await press_e()
	assert_eq(main.dialogue.talking, spot, "talking to %s" % spot)


func _case(id: String) -> Dictionary:
	for c in Casebook.cases(main.rackets, main.clock.minute):
		if c.id == id:
			return c
	return {}


func test_two_nights_in_the_grown_city() -> void:
	main.save_path = SAVE
	main.rackets.money = 2000
	var purse := 2000
	# 1. the sedan up Wharf Street, under the railroad, into Lincoln Terrace; left there
	var sedan: Car = main.fleet.cars[7]
	var sedan_id: String = main.fleet.ids[7]
	await park(sedan, Vector2(3300 + 28, -250), -PI / 2)
	await seat_in(sedan)
	for i in 60 * 25:
		cmd = PlayerCommand.make(Vector2(0, -1))
		await wait_physics_frames(1)
		if sedan.global_position.y < -1700.0:
			break
	cmd = PlayerCommand.new()
	await hold(Vector2.ZERO, 120, true)
	assert_eq(main.world.current, "terrace", "driven into the terrace")
	await press_e()
	await wait_physics_frames(30)
	assert_true(player().on_foot(), "out of the car")
	var sedan_at := sedan.global_position
	# 2. Canal Market: coffee, the noticeboard, the Lantern
	main.clock.set_time(22 * 60.0)
	await _talk("market_hall", "market", "dvorak")
	await answer_with("coffee")
	purse -= Quarters.COFFEE
	await answer_with("bye")
	var hall: InteriorPlan = main.interiors.plan_named("market_hall")
	for q in path_in_room(hall, walker().global_position, Vector2(hall.spots[2].pos), 8.0):
		await walk_to(q, 4.0, 120)
	await press_e()
	assert_eq(main.dialogue.talking, "hall_board")
	await answer_with("bye")
	assert_eq(_case("stall").status, Casebook.LEAD)
	await _talk("golden_lantern", "market", "chu")
	await answer_with("eat")
	purse -= Quarters.MEAL
	await answer_with("bye")
	await talk_to("golden_lantern", "chu")
	await answer_with("who_k")
	await answer_with("bye")
	assert_eq(_case("stall").status, Casebook.OPEN, "Kaz named")
	# 3. midnight: Kaz bought off; Hrabal's thanks
	main.clock.set_time(24 * 60.0)
	await wait_physics_frames(3)
	await talk_to("golden_lantern", "kaz")
	assert_eq(main.dialogue.talking, "kaz")
	await answer_with("warn")
	await answer_with("buy")
	purse -= QuarterLeads.KAZ_BUYOUT
	await answer_with("bye")
	await _talk("market_hall", "market", "hrabal")
	await answer_with("thanks")
	purse += QuarterLeads.HRABAL_THANKS.bought
	await answer_with("bye")
	assert_eq(main.rackets.money, purse, "the market to the cent")
	# 4. the Paradise: a dance, a tune, the card
	await _talk("paradise", "terrace", "ruby")
	var before: float = main.clock.minute
	await answer_with("ticket")
	purse -= Quarters.TICKET
	assert_almost_eq(main.clock.minute - before, Quarters.DANCE_MINUTES, 0.2)
	await answer_with("bye")
	await talk_to("paradise", "bandleader")
	await answer_with("tune_lake_shore")
	purse -= Quarters.TUNE
	await answer_with("bye")
	await talk_to("paradise", "bandleader")
	await answer_with("card")
	await answer_with("take_card")
	purse += QuarterLeads.CARD_FEE
	await answer_with("bye")
	assert_eq(main.rackets.money, purse)
	assert_true(main.quarter_life.band.playing, "the band plays")
	# 5. saved and loaded in the ballroom
	await _reload()
	assert_eq(main.rackets.money, purse, "his money as it was")
	assert_eq(main.interiors.current.id, "paradise", "in the ballroom")
	assert_eq(main.rackets.quarters.dances, 1)
	assert_eq(main.rackets.quarters.tune, "lake_shore", "the band plays his tune")
	assert_eq(main.rackets.quarters.leads.card, QuarterLeads.Card.CARRYING)
	await wait_physics_frames(30)
	assert_almost_eq(main.quarter_life.band.pitch_scale, 1.1, 0.001, "at its pace")
	# 6. the card to the Bird, at the Copper Owl
	walker().place(main.layout.spawn, 0.0)
	await wait_physics_frames(3)
	await talk_to("copper_owl", "bird")
	await answer_with("lead_card_bird")
	await answer_with("bye")
	assert_eq(_case("bird_card").status, Casebook.CLOSED)
	# 7. home to bed: the next night
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(5)
	assert_eq(main.rackets.night, 2)
	purse -= main.rackets.collected  # (Rourke's collectors, if he were out of patience)
	assert_eq(main.rackets.money, purse)
	assert_eq(main.rackets.quarters.coffees, 0, "tonight's limits afresh")
	assert_eq(main.rackets.quarters.dances, 0)
	assert_eq(main.rackets.quarters.leads.stall_how, "bought", "settled stays settled")
	var i: int = main.fleet.ids.find(sedan_id)
	assert_lt(main.fleet.cars[i].global_position.distance_to(sedan_at), 1.0, "the sedan where he left it, in the terrace")
	# 8. night two: the Belvedere, then Rourke
	main.clock.set_time(21 * 60.0)
	await _talk("belvedere", "terrace", "pratt")
	await answer_with("who")
	await answer_with("tip")
	purse -= Quarters.TIP
	assert_string_contains(main.hud.line_label.text, "State's Attorney")
	await answer_with("bye")
	walker().place(main.layout.spawn, 0.0)
	await wait_physics_frames(3)
	var trust: int = main.rackets.boss.trust
	await talk_to("copper_owl", "rourke")
	await answer_with("lead_sa")
	await answer_with("bye")
	assert_eq(main.rackets.boss.trust, mini(100, trust + QuarterLeads.TRUST_FOR_SA))
	# 9. saved and loaded; the notebook
	await _reload()
	assert_eq(main.rackets.night, 2)
	assert_eq(main.rackets.money, purse, "to the cent, two nights and three loads later")
	for id in ["stall", "bird_card", "sa_man"]:
		assert_eq(_case(id).status, Casebook.CLOSED, "%s closed" % id)
	assert_true(main.rackets.quarters.met.has("ruby") and main.rackets.quarters.met.has("chu"), "they remember him")
