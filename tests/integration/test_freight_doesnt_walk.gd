extends "res://tests/support/city_test.gd"
## M012 "Freight Doesn't Walk" in the game, with the normal controls: Leon in
## his dispatch office tells Danny his trouble; Dutch's counter and the union
## hall's noticeboard give away why the shed holds the freight; each way of
## settling it with Walt in the freight shed - Leon's petty cash on Danny's
## word, Danny's own six dollars, a gun in hand, a fistfight (lost, then paid)
## - empties the shed's corner and Leon pays his ten dollars once; left past
## the truck, Leon sorts it himself; a save mid-job and a save after it load
## as they were, the crates still gone and no second fee; the next night
## nobody starts it over.

var _save := ""


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func f() -> FreightJob:
	return main.rackets.freight


func _to_yards() -> void:
	main.world.load_now("yards")
	walker().place(main.interiors.plan_named("dispatch_office").outside_door(0, 60.0), PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)


## Leon's trouble, heard and taken on.
func _take_it() -> void:
	await _to_yards()
	var office: InteriorPlan = main.interiors.plan_named("dispatch_office")
	assert_true(await walk_in_to(office, "leon"), "in at the dispatch office door, up to Leon's desk")
	await press_e()
	assert_eq(main.dialogue.talking, "leon")
	await answer_with("freight_hear")
	assert_string_contains(main.hud.line_label.text, "Hartmann's")
	assert_eq(f().stage, FreightJob.Stage.OFFERED)
	await answer_with("freight_accept")
	assert_eq(f().stage, FreightJob.Stage.ACCEPTED)
	await answer_with("bye")


func _talk_to_walt() -> void:
	var shed: InteriorPlan = main.interiors.plan_named("freight_shed")
	assert_true(await walk_in_to(shed, "walt"), "in at the loading door, over to Walt by his stove")
	await press_e()
	assert_eq(main.dialogue.talking, "walt")


func _crates_there() -> bool:
	var v: InteriorView = main.interiors.view_of("freight_shed")
	return (v.get_node("freight_crates") as CanvasItem).visible


func _collect_fee() -> int:
	var before: int = main.rackets.money
	var office: InteriorPlan = main.interiors.plan_named("dispatch_office")
	assert_true(await walk_in_to(office, "leon"))
	await press_e()
	await answer_with("bye")
	return main.rackets.money - before


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


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func test_talked_round_dutch_tells_and_leon_squares_it() -> void:
	main.rackets.money = 900
	await _take_it()
	assert_true(_crates_there())
	# Walt won't say; Dutch's counter will
	await _talk_to_walt()
	await answer_with("walt_why")
	assert_false(f().learned.has("docked"), "Walt keeps it to himself")
	await answer_with("bye")
	var dutch_at: Vector2 = (main.world.layouts.yards as DistrictLayout).contacts[0].pos
	walker().place(dutch_at + Vector2(0, 30), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	await press_e()
	assert_eq(main.dialogue.talking, "dutch")
	await answer_with("freight_ask")
	assert_true(f().learned.has("docked"), "the shed gang's docked six dollars")
	assert_string_contains(main.hud.line_label.text, "six bucks")
	await answer_with("bye")
	# Leon is talked round, Walt hears it
	var office: InteriorPlan = main.interiors.plan_named("dispatch_office")
	assert_true(await walk_in_to(office, "leon"))
	await press_e()
	await answer_with("freight_square")
	assert_true(f().leon_agreed)
	await answer_with("bye")
	await _talk_to_walt()
	await answer_with("walt_squared")
	assert_eq(f().stage, FreightJob.Stage.SETTLED)
	assert_eq(f().how, "squared")
	await answer_with("bye")
	await wait_physics_frames(3)
	assert_false(_crates_there(), "the corner's empty")
	assert_eq(main.rackets.money, 900, "not a cent of Danny's")
	assert_eq(await _collect_fee(), FreightJob.FEE, "Leon's ten dollars")
	assert_eq(await _collect_fee(), 0, "once")


func test_dannys_own_six_after_the_union_board() -> void:
	main.rackets.money = 900
	await _take_it()
	var hall: InteriorPlan = main.interiors.plan_named("union_hall")
	assert_true(await walk_in_to(hall, "union_board"))
	await press_e()
	assert_string_contains(main.hud.line_label.text, "SHED GANG")
	assert_true(f().learned.has("docked"), "the board gives it away")
	await answer_with("bye")
	await _talk_to_walt()
	await answer_with("walt_six")
	await answer_with("walt_pay")
	assert_eq(f().how, "paid")
	assert_eq(main.rackets.money, 900 - FreightJob.DOCKED, "six dollars out of his own pocket")
	await answer_with("bye")
	assert_eq(await _collect_fee(), FreightJob.FEE)
	assert_eq(main.rackets.money, 900 - FreightJob.DOCKED + FreightJob.FEE, "four dollars to the good")


func test_a_gun_in_hand_or_fists() -> void:
	await _take_it()
	await _talk_to_walt()
	await answer_with("walt_threat")
	assert_eq(f().stage, FreightJob.Stage.ACCEPTED, "no gun: he laughs")
	await answer_with("walt_fight")
	await answer_with("bye")
	await _fight([false, false, false, true, false])
	assert_false(main.fights.fighting)
	assert_eq(f().fight_lost_night, main.rackets.night, "beaten")
	assert_gt(walker().condition.worst(), BodyCondition.Level.FINE, "bruised")
	assert_eq(f().stage, FreightJob.Stage.ACCEPTED, "not stuck")
	await answer_with("bye")
	# then with the gun in his hand
	cmd = PlayerCommand.new()
	cmd.holster = true
	await wait_physics_frames(30)
	assert_true(walker().gun.is_drawn())
	await _talk_to_walt()
	await answer_with("walt_threat")
	assert_eq(f().how, "leaned")
	await answer_with("bye")
	assert_false(_crates_there())
	assert_gt(main.rackets.memory.recent("walt", "threat", main.rackets.night), 0, "Walt remembers")


func test_fists_win_it() -> void:
	await _take_it()
	await _talk_to_walt()
	await answer_with("walt_fight")
	await answer_with("bye")
	await _fight([true, true, true, true, true])
	assert_eq(f().how, "beaten")
	await answer_with("bye")
	assert_false(_crates_there())
	assert_eq(await _collect_fee(), FreightJob.FEE)


func test_left_past_the_truck_leon_sorts_it() -> void:
	await _take_it()
	main.clock.set_time(FreightJob.TRUCK - 0.5)
	await wait_physics_frames(90)
	assert_eq(f().stage, FreightJob.Stage.LAPSED)
	assert_false(_crates_there(), "the freight went, late")
	var office: InteriorPlan = main.interiors.plan_named("dispatch_office")
	assert_true(await walk_in_to(office, "leon"))
	await press_e()
	assert_string_contains(main.hud.line_label.text, "say no")
	await answer_with("bye")
	assert_eq(await _collect_fee(), 0)


func test_saved_mid_job_and_after_it() -> void:
	_save = OS.get_user_data_dir().path_join("test_freight_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	main.rackets.money = 900
	await _take_it()
	await _talk_to_walt()
	await answer_with("walt_threat")
	await answer_with("bye")
	await _reload()
	assert_eq(f().stage, FreightJob.Stage.ACCEPTED, "the job as it was")
	assert_eq(f().threat_failed_night, main.rackets.night, "and Walt still laughing")
	assert_true(_crates_there())
	f().learn("docked")
	await _talk_to_walt()
	await answer_with("walt_pay")
	await answer_with("bye")
	assert_eq(await _collect_fee(), FreightJob.FEE)
	var money: int = main.rackets.money
	await _reload()
	assert_false(_crates_there(), "the corner still empty after loading")
	assert_eq(main.rackets.money, money)
	assert_eq(await _collect_fee(), 0, "no second fee")
	# the next night: nobody starts it over
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	assert_eq(f().stage, FreightJob.Stage.PAID)
	await _to_yards()
	assert_false(_crates_there())


func _reload() -> void:
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.save_path = _save
	main.settings_path = ""
	main.quiet_streets = true
	main.callouts_enabled = false
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(3)
