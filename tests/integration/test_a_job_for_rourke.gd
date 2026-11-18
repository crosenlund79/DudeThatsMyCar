extends "res://tests/support/city_test.gd"
## M007 playthrough: one night, one problem, the normal controls. Rourke
## offers the job at his table, Lindqvist names Lefty Moran, Eddie says how he
## fights, the map points at his corner, Danny puts up his fists outside
## Doyle's Garage and wins on the dial, hands Rourke Lefty's twenty, goes home
## to bed; the next evening the ward is talking about it, and a saved game
## remembers all of it. Everything M001-M006 keeps running underneath.

var _save := ""


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func job() -> RourkeJob:
	return main.rackets.job


func test_one_night_one_problem() -> void:
	_save = OS.get_user_data_dir().path_join("test_a_job_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	var r: Rackets = main.rackets
	# business first: Augie's protection, so Rourke has something in his purse
	await talk_to("copper_owl", "augie")
	await answer_with("protection")
	await answer_with("ask")
	await press_e()
	await talk_to("copper_owl", "rourke")
	await answer_with("envelope")
	await answer_with("top_up")  # the full envelope, out of his own pocket
	await press_e()
	# Rourke's job
	await talk_to("copper_owl", "rourke")
	await answer_with("job_offer")
	await answer_with("job_accept")
	await press_e()
	# the Swede
	await talk_to("hardware", "lindqvist")
	await answer_with("job_ask")
	assert_string_contains(main.hud.line_label.text, "Doyle's Garage")
	await press_e()
	# Eddie
	await talk_to("hardware", "eddie")
	await answer_with("job_lefty")
	await press_e()
	# the map: where to go now
	main._unhandled_input(_key(CityInput.MAP))
	assert_eq(main.hud.ward_map.job_at, main.RIVAL_POST[0])
	main._unhandled_input(_key(CityInput.MAP))
	# Lefty Moran: walk up to him and press E
	var lefty: Rival = main.rival
	walker().place(lefty.body.global_position + Vector2(-120, 0), 0.0)
	await wait_physics_frames(3)
	for i in 600:  # he loiters: walk up to wherever he is standing
		var to := lefty.body.global_position - walker().global_position
		if to.length() < 34.0:
			break
		cmd = PlayerCommand.make(to.normalized(), false, false, lefty.body.global_position)
		await wait_physics_frames(1)
	cmd = PlayerCommand.new()
	await wait_physics_frames(2)
	assert_string_contains(main.hud.prompt_label.text, "Lefty Moran")
	await press_e()
	assert_eq(main.talking, "lefty")
	await answer_with("job_fight")
	await answer_with("bye")  # (Raise your fists.)
	for i in 30:
		if main.fighting:
			break
		await wait_physics_frames(1)
	assert_true(main.fighting)
	var dial: FightDial = main.hud.fight_dial
	for check in 5:
		while dial.fight.phase != FistFight.Phase.RUNNING and not dial.fight.is_over():
			await wait_physics_frames(1)
		while not dial.fight.in_zone() and dial.fight.phase == FistFight.Phase.RUNNING:
			await wait_physics_frames(1)
		main._unhandled_input(_key(CityInput.HANDBRAKE))  # Space
		while dial.fight.phase == FistFight.Phase.RUNNING:
			await wait_physics_frames(1)
	for i in 120:
		if not main.fighting:
			break
		await wait_physics_frames(1)
	assert_eq(job().outcome, "beaten")
	assert_eq(job().recovered, RourkeJob.RECOVERABLE)
	await press_e()
	# back to Rourke: the truth and the money
	var money := r.money
	await talk_to("copper_owl", "rourke")
	await answer_with("job_report")
	await answer_with("job_truth_hand")
	assert_eq(job().verdict, "pleased")
	assert_true(job().success)
	assert_eq(job().money_went, "rourke")
	assert_eq(r.money - money, -RourkeJob.RECOVERABLE + job()._paid_now, "the twenty in, his reward out")
	await press_e()
	# home to bed: the next evening
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(5)
	assert_eq(r.night, 2)
	assert_false(lefty.is_down(), "beaten, not dead: back on his corner")
	assert_false(lefty.is_hostile())
	walker().place(lefty.body.global_position + Vector2(-30, 0), 0.0)
	await wait_physics_frames(3)
	await press_e()
	assert_string_contains(main.hud.line_label.text, "ain't been near the Swede")
	await press_e()
	r.end_night()  # another night's talk: Lefty -> Eddie -> Augie
	await talk_to("copper_owl", "augie")
	await answer_with("news")
	assert_string_contains(main.hud.line_label.text, "bare hands")
	await press_e()
	# saved and loaded
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.save_path = _save
	main.settings_path = ""
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(3)
	assert_eq(main.rackets.job.stage, RourkeJob.Stage.REPORTED)
	assert_eq(main.rackets.job.outcome, "beaten")
	assert_eq(main.rackets.job.verdict, "pleased")
	assert_eq(main.rackets.job.attempts.size(), 1)
	assert_true(main.rackets.job.learned.has("tip"))
	main._unhandled_input(_key(CityInput.MAP))
	assert_string_contains(main.hud.ward_map.job_text, "done")
	main._unhandled_input(_key(CityInput.MAP))
	main.save_path = ""
