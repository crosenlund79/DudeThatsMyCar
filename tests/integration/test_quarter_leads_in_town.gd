extends "res://tests/support/city_test.gd"
## M015.13 the new quarters' business in the game: Kaz Wrobel is at his
## corner table in the Golden Lantern only from eleven to two; the market's
## noticeboard starts a lead in the notebook (a faint mark at the Lantern),
## Henry Chu names Kaz (a sure mark on his table); a fistfight with Kaz with
## the normal controls - won, he is gone for good and Hrabal thanks Danny
## once; the State's Attorney's man is told to Rourke at the Copper Owl; the
## bandleader's card reaches the Bird; all of it survives a save and a load.

var _save := ""


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _room(id: String, district: String) -> InteriorPlan:
	main.world.load_now(district)
	var data: InteriorPlan = null
	for p in (main.world.layouts[district] as DistrictLayout).interiors:
		if (p as InteriorPlan).id == id:
			data = p
	walker().place(data.outside_door(0, 40.0), (-(data.doors[0].side as Vector2)).angle())
	await wait_physics_frames(3)
	return main.interiors.plan_named(id)


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


## Plays the fistfight on the dial: Space in the zone for each `true`.
func _fight(plan: Array) -> void:
	for i in 60:
		if main.fights.fighting:
			break
		await wait_physics_frames(1)
	assert_true(main.fights.fighting, "the fight is on")
	var dial: FightDial = main.hud.fight_dial
	for want in plan:
		while dial.fight.phase != FistFight.Phase.RUNNING and not dial.fight.is_over():
			await wait_physics_frames(1)
		if want:
			while not dial.fight.in_zone() and dial.fight.phase == FistFight.Phase.RUNNING:
				await wait_physics_frames(1)
			main._unhandled_input(_key(CityInput.HANDBRAKE))
		while dial.fight.phase == FistFight.Phase.RUNNING:
			await wait_physics_frames(1)
	for i in 120:
		if not main.fights.fighting:
			break
		await wait_physics_frames(1)


func _case(id: String) -> Dictionary:
	for c in Casebook.cases(main.rackets, main.clock.minute):
		if c.id == id:
			return c
	return {}


func test_kaz_keeps_his_hours_at_the_lantern() -> void:
	main.clock.set_time(22 * 60.0)
	await _room("golden_lantern", "market")
	await wait_physics_frames(3)
	var v: InteriorView = main.interiors.view_of("golden_lantern")
	assert_false(v.person_ok("kaz"), "on his rounds at ten")
	main.clock.set_time(24 * 60.0)
	await wait_physics_frames(3)
	assert_true(v.person_ok("kaz"), "at his table at midnight")
	await talk_to("golden_lantern", "kaz")
	assert_eq(main.dialogue.talking, "kaz")
	assert_string_contains(main.hud.line_label.text, "Kaz")


func test_the_board_then_chu_then_kaz_beaten_and_hrabal_s_thanks() -> void:
	main.rackets.money = 500
	main.clock.set_time(23 * 60.0 + 30.0)
	var hall := await _room("market_hall", "market")
	assert_true(await walk_in_to(hall, "hall_board"))
	await press_e()
	assert_eq(main.dialogue.talking, "hall_board")
	await answer_with("bye")
	assert_eq(_case("stall").status, Casebook.LEAD, "a suspicion in the notebook")
	main.casework.refresh()
	var faint: Array = main.casework.marks.filter(func(m: Dictionary) -> bool: return m.case == "Stall insurance")
	assert_false(faint.is_empty(), "marked where to ask")
	assert_true(faint.all(func(m: Dictionary) -> bool: return not m.sure), "only faintly")
	# Chu names him
	await _room("golden_lantern", "market")
	await talk_to("golden_lantern", "chu")
	await answer_with("who_k")
	assert_string_contains(main.hud.line_label.text, "Kaz Wrobel")
	await answer_with("bye")
	assert_eq(_case("stall").status, Casebook.OPEN)
	main.casework.refresh()
	assert_true(main.casework.marks.any(func(m: Dictionary) -> bool: return m.case == "Stall insurance" and m.sure),
		"a sure mark on Kaz's table")
	# Kaz: fists
	await talk_to("golden_lantern", "kaz")
	await answer_with("warn")
	await answer_with("fists")
	await answer_with("bye")
	await _fight([true, true, true, true, true])
	assert_false(main.fights.fighting)
	assert_eq(main.rackets.quarters.leads.stall_how, "beaten")
	assert_eq(main.dialogue.talking, "kaz", "he has something to say from the floor")
	await answer_with("bye")
	await wait_physics_frames(3)
	assert_false(main.interiors.view_of("golden_lantern").person_ok("kaz"), "he has quit the market")
	# Hrabal's thanks, once
	await _room("market_hall", "market")
	await talk_to("market_hall", "hrabal")
	await answer_with("thanks")
	assert_eq(main.rackets.money, 500 + 300, "three dollars from the stallholders' tin")
	await answer_with("bye")
	await talk_to("market_hall", "hrabal")
	assert_false((main.dialogue.page.options as Array).any(func(o: Dictionary) -> bool: return o.id == "thanks"), "once")
	await answer_with("bye")
	assert_eq(_case("stall").status, Casebook.CLOSED)


func test_word_for_rourke_and_a_card_for_the_bird_kept_through_a_save() -> void:
	_save = OS.get_user_data_dir().path_join("test_leads_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	main.rackets.money = 500
	main.rackets.night = 2
	main.rackets.quarters.begin_night(2)
	main.clock.set_time(22 * 60.0)
	# a dollar under Pratt's blotter
	await _room("belvedere", "terrace")
	await talk_to("belvedere", "pratt")
	await answer_with("who")
	await answer_with("tip")
	assert_string_contains(main.hud.line_label.text, "State's Attorney")
	await answer_with("bye")
	# a nickel in the bandleader's cup, and his card
	await _room("paradise", "terrace")
	await talk_to("paradise", "bandleader")
	await answer_with("tune_lake_shore")
	await answer_with("bye")
	await talk_to("paradise", "bandleader")
	await answer_with("card")
	await answer_with("take_card")
	await answer_with("bye")
	assert_eq(main.rackets.money, 500 - Quarters.TIP - Quarters.TUNE + QuarterLeads.CARD_FEE)
	# saved and loaded
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = callouts
	main.save_path = _save
	main.settings_path = ""
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(5)
	assert_eq(main.rackets.quarters.leads.sa, QuarterLeads.Sa.KNOWN, "remembered")
	assert_eq(main.rackets.quarters.leads.card, QuarterLeads.Card.CARRYING, "still in his pocket")
	# to the Copper Owl: Rourke, then the Bird
	var trust: int = main.rackets.boss.trust
	walker().place(main.layout.spawn, 0.0)
	await wait_physics_frames(3)
	await talk_to("copper_owl", "rourke")
	await answer_with("lead_sa")
	assert_string_contains(main.hud.line_label.text, "Good eyes")
	assert_eq(main.rackets.boss.trust, mini(100, trust + QuarterLeads.TRUST_FOR_SA))
	await answer_with("bye")
	await talk_to("copper_owl", "bird")
	if main.dialogue.page.options.any(func(o: Dictionary) -> bool: return o.id == "who"):
		await answer_with("who")
	await answer_with("lead_card_bird")
	assert_string_contains(main.hud.line_label.text, "nobody owns you")
	await answer_with("bye")
	assert_eq(_case("sa_man").status, Casebook.CLOSED)
	assert_eq(_case("bird_card").status, Casebook.CLOSED)
	main.save_path = ""
