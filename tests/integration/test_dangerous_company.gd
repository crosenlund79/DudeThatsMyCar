extends "res://tests/support/city_test.gd"
## M006 smoke test - one night of Dangerous Company in the game, the way a
## player might go about it, then the next evening and a saved game: Augie's
## greeting, the Bird interrupted and back at her microphone, Eddie's wares,
## Lefty provoked and shooting, Danny hit and patched up at the vet's, Lefty
## shot down, a car taken under the beat cop's nose, the map, sleep, and a
## save that remembers it all. The economy and Rourke carry on underneath.

var _save := ""


func before_each() -> void:
	meet_people = true
	await super()


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func test_a_night_of_dangerous_company() -> void:
	_save = OS.get_user_data_dir().path_join("test_dangerous_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	var r: Rackets = main.rackets
	var music: AudioStreamPlayer = main.soundscape.music
	# the Copper Owl: Augie's greeting, then business
	await talk_to("copper_owl", "augie")
	assert_eq(main.voice.current, "augie_greeting")
	await answer_with("hello")
	await answer_with("protection")
	await answer_with("ask")
	await press_e()
	assert_gt(r.held, 0, "Rourke's money in Danny's pocket")
	# the Bird: scratch, complaint, then her greeting - one voice at a time
	walker().place(Vector2(2343, 336), 0.0)
	await wait_physics_frames(3)
	await press_e()
	assert_true(main.soundscape.music_stopped)
	for i in 30:  # Augie's voice fades out first: never two at once
		if main.voice.current == "bird_interrupted":
			break
		await wait_physics_frames(1)
	assert_eq(main.voice.current, "bird_interrupted")
	await answer_with("who")
	assert_eq(main.voice.queue, ["bird_greeting"] as Array[String])
	await answer_with("bye")
	for i in 300:
		if main.stage.singing():
			break
		await wait_physics_frames(1)
	assert_true(music.playing, "the band counts her back in")
	# Eddie's wares
	await talk_to("hardware", "eddie")
	await answer_with("hello")
	await answer_with("wares")
	assert_has(main.voice.queue + ([main.voice.current] as Array[String]), "eddie_sales")
	await answer_with("ammo")
	await press_e()
	# Lefty: provoked, he shoots back; Danny is hit
	var lefty: Rival = main.rival
	walker().place(lefty.body.global_position + Vector2(-170, 0), 0.0)
	await wait_physics_frames(3)
	await click(lefty.body.global_position)
	await aim_for(lefty.body.global_position, 20)
	assert_true(lefty.is_hostile())
	walker().hit_by_bullet(walker().global_position + Vector2(0, 6), Vector2.UP, lefty.body)
	assert_true(walker().condition.is_hurt())
	for i in 14:
		if lefty.is_down():
			break
		await click(lefty.body.global_position)
		await aim_for(lefty.body.global_position, 25)
	assert_true(lefty.is_down(), "Lefty Moran shot down")
	# how Danny is, and the Doc
	main._unhandled_input(_key(CityInput.STATUS))
	assert_true(main.modals.status_open)
	main._unhandled_input(_key(CityInput.STATUS))
	r.money = maxi(r.money, 2000)
	await talk_to("vet", "pettibone")
	if walker().condition.is_hurt():
		await answer_with("patch")
	assert_false(walker().condition.is_hurt(), "patched up")
	await press_e()
	# a car taken under the beat cop's nose
	var c: Car = main.fleet.cars[0]
	await park(c, main.officer.body.global_position + Vector2(40, 140), 0.0)
	walker().place(c.global_position + c.global_transform.y * -38.0, 0.0)
	await wait_physics_frames(3)
	await press_e()
	assert_eq(player().car, c)
	assert_eq(main.fleet.thefts_witnessed, 1)
	assert_true(main.officer.brain.is_hunting())
	await press_e()
	await wait_physics_frames(20)
	# the map
	main._unhandled_input(_key(CityInput.MAP))
	assert_true(main.hud.city_map.visible)
	main._unhandled_input(_key(CityInput.MAP))
	# home to bed: a new night
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(5)
	assert_eq(r.night, 2)
	assert_true(main.stage.singing() and music.playing, "the Bird sings")
	assert_true(lefty.is_down(), "Lefty stays dead")
	assert_false(main.officer.is_down())
	assert_false(main.fleet.thefts.is_stolen(0), "the car is back with its owner")
	# saved and loaded
	var fees: int = r.doctor_fees
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = callouts  # M012: as in before_each
	main.save_path = _save
	main.settings_path = ""
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(3)
	assert_null(main.films.of("opening"))
	assert_eq(main.rackets.night, 2)
	assert_eq(main.rackets.doctor_fees, fees)
	assert_true(main.rival.is_down())
	for id in ["augie_greeting", "bird_greeting", "eddie_greeting", "eddie_sales"]:
		assert_false(main.voice_lines.due(id), "%s: heard, not said again" % id)
	assert_true(main.voice_lines.due("rourke_greeting"), "Rourke not met yet")
	main.save_path = ""
