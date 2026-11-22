extends "res://tests/support/city_test.gd"
## M006 the Bird on the Copper Owl's bandstand: she performs while the song
## plays; E at her microphone scratches the record and stops it; the first
## time she complains and then introduces herself - one voice after the
## other - and when Danny walks away the band counts her back in, once.


func before_each() -> void:
	meet_people = true
	await super()


func bird() -> Walker:
	return main.interiors.person("copper_owl", "bird")


func sound() -> Soundscape:
	return main.soundscape


func _wait_voice(id: String, max_frames: int = 1200) -> void:
	for i in max_frames:
		if main.voice.current == id:
			return
		await wait_physics_frames(1)


func _wait_singing(max_frames: int = 400) -> void:
	for i in max_frames:
		if main.stage.singing():
			return
		await wait_physics_frames(1)


func test_she_performs_on_the_bandstand() -> void:
	var b := bird()
	assert_not_null(b, "the Bird is in the Copper Owl")
	var plan: InteriorPlan = main.interiors.view_of("copper_owl").plan
	assert_true(plan.contains(b.global_position))
	assert_gt(b.global_position.x, 2363.0, "on the bandstand")
	assert_eq(b.sprite.texture, main.resolver.get_texture("characters/singer"))
	await talk_to("copper_owl", "augie")
	await press_e()
	var frames := {}
	var rotations := {}
	for i in 60:
		await wait_physics_frames(10)
		frames[b.sprite.frame] = true
		rotations[snappedf(b.sprite.rotation, 0.01)] = true
	assert_gt(frames.size(), 1, "her gestures change with the song")
	assert_gt(rotations.size(), 3, "she sways")
	assert_true(sound().music.playing)


func test_interrupting_her_the_first_time() -> void:
	var music := sound().music
	walker().place(Vector2(2343, 336), 0.0)
	await wait_physics_frames(3)
	assert_string_contains(main.hud.prompt_label.text, "Interrupt the Bird")
	await press_e()
	assert_eq(main.dialogue.talking, "bird")
	assert_true(sound().music_stopped, "the song stops")
	assert_false(music.playing)
	assert_eq(sound().scratches, 1, "with one scratch")
	assert_has(main.dialogue.page.voice, "bird_interrupted")
	assert_eq(main.voice.current, "bird_interrupted", "she gives him a piece of her mind")
	assert_eq(main.dialogue.page.text, VoiceLines.text("bird_interrupted"))
	assert_eq(bird().sprite.frame, 0, "she stops performing")
	await answer_with("who")
	assert_eq(main.dialogue.page.text, VoiceLines.text("bird_greeting"), "then she introduces herself")
	assert_eq(main.voice.current, "bird_interrupted", "after she has finished the first line")
	assert_eq(main.voice.queue, ["bird_greeting"] as Array[String])
	await _wait_voice("bird_greeting")
	assert_eq(main.voice.current, "bird_greeting", "one voice after the other, never both")
	assert_false(main.voice_lines.due("bird_greeting"))
	await answer_with("secrets")
	assert_eq(main.dialogue.talking, "bird")
	await answer_with("bye")
	assert_eq(main.dialogue.talking, "")
	assert_false(main.stage.singing(), "a moment's pause")
	await _wait_singing()
	assert_true(main.stage.singing(), "the band counts her back in")
	assert_true(music.playing)
	assert_same(sound().music, music, "the same player")
	assert_eq(sound().music_starts, 2, "started again once")
	await wait_physics_frames(120)
	assert_eq(sound().music_starts, 2, "and only once")


func test_no_second_scratch_and_no_second_greeting() -> void:
	main.voice_lines.mark("bird_greeting")
	walker().place(Vector2(2343, 336), 0.0)
	await wait_physics_frames(3)
	await press_e()
	assert_eq(sound().scratches, 1)
	var ids: Array = main.dialogue.page.options.map(func(o: Dictionary) -> String: return o.id)
	assert_false(ids.has("who"), "she has introduced herself before")
	await press_e()
	assert_eq(main.dialogue.talking, "", "E walks away")
	await wait_physics_frames(20)
	await press_e()
	assert_eq(main.dialogue.talking, "bird", "back before the band starts")
	assert_eq(sound().scratches, 1, "no scratch: she wasn't singing")
	assert_string_contains(main.dialogue.page.text, "Make it quick")
	assert_eq(main.voice.current, "", "and no complaint")
	await press_e()
	await _wait_singing()
	assert_eq(sound().music_starts, 2, "one start after both talks")


func test_a_new_night_she_is_singing() -> void:
	walker().place(Vector2(2343, 336), 0.0)
	await wait_physics_frames(3)
	await press_e()
	assert_true(sound().music_stopped)
	main.night.sleep()
	await wait_physics_frames(5)
	assert_true(main.stage.singing())
	assert_true(sound().music.playing, "the club opens with her song")
