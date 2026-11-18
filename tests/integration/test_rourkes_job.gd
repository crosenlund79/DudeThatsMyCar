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
