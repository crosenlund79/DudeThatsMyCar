extends "res://tests/support/city_test.gd"
## M007 Rourke's job in the game, with the normal controls: offered at his
## table, taken, put off or turned down; remembered after sleeping and
## after saving and loading.

var _save := ""


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func job() -> RourkeJob:
	return main.rackets.job


func _offer() -> void:
	await talk_to("copper_owl", "rourke")
	await answer_with("job_offer")
	assert_string_contains(main.hud.speaker_label.text, "(leaning in, low)", "how he says it, beside his name")


func _reload() -> void:
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


func test_taken_and_remembered_across_sleep_and_saves() -> void:
	_save = OS.get_user_data_dir().path_join("test_job_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	await _offer()
	await answer_with("job_accept")
	assert_eq(job().stage, RourkeJob.Stage.ACCEPTED)
	await press_e()
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	assert_eq(job().stage, RourkeJob.Stage.ACCEPTED, "still his job the next evening")
	await _reload()
	assert_eq(job().stage, RourkeJob.Stage.ACCEPTED, "and in the saved game")
	await talk_to("copper_owl", "rourke")
	var ids: Array = main._page.options.map(func(o: Dictionary) -> String: return o.id)
	assert_has(ids, "job_report", "Rourke asks how it's going")
	main.save_path = ""


func test_put_off_then_turned_down() -> void:
	await _offer()
	await answer_with("job_postpone")
	assert_eq(job().stage, RourkeJob.Stage.OFFERED)
	await press_e()
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	await _offer()
	await answer_with("job_decline")
	assert_eq(job().stage, RourkeJob.Stage.DECLINED)
	assert_false(main.rackets.boss.ban, "disappointed, not an enemy")


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func test_the_map_says_what_next_and_rourke_hears_how_it_went() -> void:
	await _offer()
	await answer_with("job_accept")
	assert_string_contains(main.hud.notice_label.text, "Lindqvist", "what next, as a notice")
	await press_e()
	main._unhandled_input(_key(CityInput.MAP))
	var map: CityMap = main.hud.city_map
	assert_string_contains(map.job_text, "Lindqvist")
	var hardware: Vector2 = main.hud.minimap.places.filter(func(p: Dictionary) -> bool: return p.id == "hardware")[0].pos
	assert_eq(map.job_at, hardware, "a ring round the hardware store")
	assert_eq(map.lefty_at, Vector2.INF, "no Lefty on the map before Danny knows the name")
	main._unhandled_input(_key(CityInput.MAP))
	job().learn("culprit")
	main._unhandled_input(_key(CityInput.MAP))
	assert_eq(map.job_at, main.RIVAL_POST[0], "his corner outside Doyle's Garage")
	assert_eq(map.lefty_at, main.RIVAL_POST[0])
	main._unhandled_input(_key(CityInput.MAP))
	job().resolve("backed_down", main.rackets)
	main.rackets.boss.purse = 3000
	var money: int = main.rackets.money
	await talk_to("copper_owl", "rourke")
	await answer_with("job_report")
	await answer_with("job_truth_hand")
	assert_string_contains(main.hud.line_label.text, JobLines.text("report_backed_down"))
	assert_string_contains(main.hud.line_label.text, JobLines.text("report_handed"))
	assert_eq(main.rackets.money - money, RourkeJob.REWARD - RourkeJob.RECOVERABLE, "Lefty's twenty handed over, ten back")
	assert_eq(job().verdict, "pleased")
	await press_e()
	main._unhandled_input(_key(CityInput.MAP))
	assert_string_contains(map.job_text, "Rourke is pleased")
	assert_eq(map.job_at, Vector2.INF, "nothing more to point at")
	main._unhandled_input(_key(CityInput.MAP))


func test_a_lie_comes_home_a_few_nights_later() -> void:
	_save = OS.get_user_data_dir().path_join("test_job_lie_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	await _offer()
	await answer_with("job_accept")
	job().learn("culprit")
	main.rackets.boss.purse = 3000
	await press_e()
	await talk_to("copper_owl", "rourke")
	await answer_with("job_report")
	await answer_with("job_handled")
	assert_eq(job().stage, RourkeJob.Stage.REPORTED)
	await press_e()
	for i in 2:
		main.sleep()
		await wait_physics_frames(2)
	await _reload()  # the lie keeps in a saved game
	for i in 2:
		main.sleep()
		await wait_physics_frames(2)
	await talk_to("copper_owl", "rourke")
	assert_string_contains(main.hud.line_label.text, "still paying Lefty Moran", "Rourke knows")
	assert_eq(job().stage, RourkeJob.Stage.ACCEPTED, "and still wants it done")
	main.save_path = ""
