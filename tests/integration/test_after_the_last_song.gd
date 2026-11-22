extends "res://tests/support/city_test.gd"
## M012 "After the Last Song": late in a night Danny spends in the Copper Owl,
## once he has met her, the Bird's song ends for good, she steps down to the
## end of the bar and asks him to stay. Answered, a short film in the game:
## the bars, the camera leaving him for her, the club's lamps low, the room
## hushed, a few lines - then her question and his choice, remembered; the
## bars slide away and everything is as it was (the camera on Danny, the HUD
## back, nothing ducked). Skipping goes straight to her question; walking
## away from it is an answer too; let be, she asks another night; once it has
## happened, never again; no recorded voice is added or altered; it lasts
## through saving and loading, and she remembers it.

var _save := ""


func before_each() -> void:
	callouts = true
	await super()


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _in_the_club_late() -> void:
	main.clock.set_time(main.BIRD_LAST_SONG + 1.0)
	walker().place(Vector2(2290, 380), -PI / 2)
	main.camera.snap_to(walker())
	for i in 30:
		await wait_physics_frames(1)
		if main.bird_scene != "":
			break


func _to_her() -> void:
	var bird: Walker = main.bird_show.bird
	for i in 240:
		await wait_physics_frames(1)
		if bird.global_position.distance_to(main.BIRD_SEAT) < 5.0:
			break
	walker().place(main.BIRD_SEAT + Vector2(0, 34), -PI / 2)
	await wait_physics_frames(3)


func _until_question() -> void:
	for i in 1200:
		await wait_physics_frames(1)
		if main.dialogue.talking == "bird_scene":
			break


func test_her_last_song_her_question_and_his_answer() -> void:
	var voices := VoiceLines.LINES.size()
	assert_true(main.stage.singing())
	await _in_the_club_late()
	assert_eq(main.bird_scene, "asking", "the last song of the night")
	assert_true(main.stage.done)
	assert_false(main.stage.singing())
	assert_true(main.soundscape.music_stopped, "the song is over")
	assert_string_contains(main.overhead.label.text, "Stay a minute")
	await _to_her()
	assert_string_contains(main.hud.prompt_label.text, "Stay a minute with the Bird")
	await press_e()
	assert_not_null(main.bird_film, "the film")
	await wait_physics_frames(60)
	assert_eq(main.camera.target, main.bird_film.rig, "the camera leaves Danny")
	assert_false(main.hud.visible, "the HUD out of the way")
	assert_lt(main.interiors.view_of("copper_owl").light_scale, 0.6, "the house lights down")
	assert_gt(main.soundscape.duck, 0.0, "the room hushed")
	await _until_question()
	assert_eq(main.dialogue.talking, "bird_scene", "her question")
	var ids: Array = main.dialogue.page.options.map(func(o: Dictionary) -> String: return o.id)
	for want in ["truth", "kind", "guard", "bye"]:
		assert_has(ids, want, "three ways to answer, or none")
	assert_true(main.hud.visible, "the words on screen")
	await answer_with("truth")
	assert_eq(main.rackets.bird_scene, "truth")
	assert_gt(main.rackets.memory.recent("bird", "told_truth", main.rackets.night), 0, "she remembers what he said")
	await answer_with("bye")
	for i in 120:
		await wait_physics_frames(1)
		if main.bird_film == null:
			break
	assert_null(main.bird_film, "the bars slide away")
	assert_eq(main.camera.target, walker(), "the camera back on Danny")
	assert_true(main.hud.visible)
	await wait_physics_frames(60)
	assert_lt(main.soundscape.duck, 0.1, "nothing ducked")
	assert_eq(main.bird_scene, "")
	assert_eq(VoiceLines.LINES.size(), voices, "no recorded voice added")
	# she remembers it, and it never happens again
	await talk_to("copper_owl", "bird")
	assert_string_contains(main.hud.line_label.text, "honest man")
	await answer_with("bye")
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	assert_true(main.stage.singing(), "a new night, a new set")
	await _in_the_club_late()
	assert_eq(main.bird_scene, "", "once only")


func test_skipped_to_her_question_and_walking_away_from_it() -> void:
	await _in_the_club_late()
	await _to_her()
	await press_e()
	await wait_physics_frames(10)
	var e := InputEventAction.new()
	e.action = CityInput.INTERACT
	e.pressed = true
	main._unhandled_input(e)
	await wait_physics_frames(5)
	assert_eq(main.dialogue.talking, "bird_scene", "skipped straight to her question")
	var esc := InputEventAction.new()
	esc.action = CityInput.MENU
	esc.pressed = true
	main._unhandled_input(esc)
	await wait_physics_frames(5)
	assert_eq(main.rackets.bird_scene, "silent", "walking away is an answer too")
	for i in 120:
		await wait_physics_frames(1)
		if main.bird_film == null:
			break
	assert_null(main.bird_film)
	assert_eq(main.camera.target, walker())


func test_let_be_she_asks_another_night() -> void:
	await _in_the_club_late()
	assert_eq(main.bird_scene, "asking")
	walker().place(main.interiors.plan_named("copper_owl").outside_door(0, 60.0), PI / 2)
	await wait_physics_frames(10)
	assert_eq(main.bird_scene, "", "he walked out: she lets it be")
	assert_eq(main.rackets.bird_scene, "", "nothing said")
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	await _in_the_club_late()
	assert_eq(main.bird_scene, "asking", "another night, she asks again")


func test_not_before_they_have_met() -> void:
	main.voice_lines.heard.erase("bird_greeting")
	await _in_the_club_late()
	assert_eq(main.bird_scene, "", "a stranger at the bar: she just sings")


func test_kept_through_saving_and_loading() -> void:
	_save = OS.get_user_data_dir().path_join("test_bird_scene_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	await _in_the_club_late()
	await _to_her()
	await press_e()
	await _until_question()
	await answer_with("guard")
	await answer_with("bye")
	await wait_physics_frames(80)
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = true
	main.save_path = _save
	main.settings_path = ""
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(3)
	assert_eq(main.rackets.bird_scene, "guard")
	main.stage.finish()  # between songs (talking to her mid-song stops it, as ever)
	await talk_to("copper_owl", "bird")
	assert_string_contains(main.hud.line_label.text, "Know me any better")
	await answer_with("bye")
	main.clock.set_time(main.BIRD_LAST_SONG + 5.0)
	await wait_physics_frames(30)
	assert_eq(main.bird_scene, "", "not again after loading")
