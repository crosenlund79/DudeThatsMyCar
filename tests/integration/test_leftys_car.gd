extends "res://tests/support/city_test.gd"
## M015 Lefty Moran's own car: a one-of-a-kind speedster at the kerb by his
## corner, stealable like any car and kept where it is left. Taken under his
## eyes (or driven past him) he knows it was Danny and goes for his gun; taken
## unseen he misses it the next evening (not knowing who); a copper who saw it
## spreads the word, and by the next evening Lefty knows and holds a grudge;
## brought back to his kerb he lets it go - remembered either way, and talked
## about; all of it kept in a saved game.

var _save := ""


func before_each() -> void:
	await super()
	_save = OS.get_user_data_dir().path_join("test_leftys_car_%d.json" % Time.get_ticks_usec())


func after_each() -> void:
	super()
	if FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _car() -> Car:
	return main.leftys_car.car()


func _get_in(c: Car) -> void:
	walker().place(c.global_position + c.global_transform.y * -38.0, 0.0)
	await wait_physics_frames(3)
	await press_e()


## Lefty kept out of the way (somewhere he cannot see his car).
func _lefty_away() -> void:
	main.rival.held = true
	main.rival.body.place(Vector2(3600, -700), 0.0)
	await wait_physics_frames(2)


func test_his_car_by_his_corner() -> void:
	var c := _car()
	assert_not_null(c)
	assert_eq(c.vehicle.id, "lefty", "a car of its own")
	assert_eq(c.vehicle.paints, PackedStringArray(["cars/lefty"]))
	assert_lt(c.global_position.distance_to(main.layout.place("lefty_post")), 200.0, "at the kerb by his corner")
	assert_eq(main.fleet.thefts.owner(main.leftys_car.index()), "lefty")
	walker().place(c.global_position + c.global_transform.y * -38.0, 0.0)
	await wait_physics_frames(3)
	assert_string_contains(main.hud.prompt_label.text, "Speedster")
	assert_string_contains(main.hud.prompt_label.text, "not yours")


func test_taken_under_his_eyes() -> void:
	assert_true(main.rival.can_see(_car().global_position), "Lefty can see his car from his corner")
	await _get_in(_car())
	assert_eq(player().car, _car())
	var m: LeftysCar = main.rackets.lefty_car
	assert_eq(m.knows, "danny")
	assert_eq(m.how, "saw_taken")
	assert_true(main.rival.is_hostile(), "he goes for his gun")
	assert_true(m.grudge())
	assert_gt(main.rackets.memory.recent("lefty", "took_car", main.rackets.night), 0, "and he remembers it")
	assert_false(main.rackets.rumours.known_to("lefty", "lefty_car").is_empty(), "the talk starts with him")


func test_taken_unseen_missed_the_next_evening() -> void:
	await _lefty_away()
	var c := _car()
	await _get_in(c)
	assert_eq(main.rackets.lefty_car.knows, "", "nobody saw a thing")
	await park(c, Vector2(2300, 560), 0.0)
	await press_e()  # out
	var left_at := c.global_position
	main.night.sleep()
	await wait_physics_frames(5)
	assert_lt(c.global_position.distance_to(left_at), 1.0, "still where Danny left it")
	assert_eq(main.rackets.lefty_car.knows, "gone", "Lefty misses it - and doesn't know who")
	assert_false(main.rival.brain.grudge)
	main.dialogue.open("lefty")
	assert_string_contains(main.dialogue.page.text, "Somebody took my car")


func test_a_copper_saw_it_and_the_word_gets_round() -> void:
	await _lefty_away()
	var c := _car()
	main.officer.body.place(c.global_position + Vector2(-120, -60), 0.0)
	await wait_physics_frames(2)
	await _get_in(c)
	assert_eq(main.fleet.thefts_witnessed, 1, "the beat cop saw it")
	assert_eq(main.rackets.lefty_car.knows, "", "Lefty not yet")
	await park(c, Vector2(2300, 560), 0.0)
	await press_e()
	main.night.sleep()
	await wait_physics_frames(5)
	assert_eq(main.rackets.lefty_car.knows, "danny", "by the next evening Lefty knows")
	assert_eq(main.rackets.lefty_car.how, "word")
	assert_true(main.rival.brain.grudge, "and goes for Danny on sight")


func test_brought_back_to_his_kerb() -> void:
	await _lefty_away()
	var c := _car()
	var home: Vector2 = main.leftys_car.home()
	await _get_in(c)
	await park(c, home + Vector2(900, 0), 0.0)
	await press_e()
	main.rackets.lefty_car.learn_danny("word", main.rackets.night)
	main.rackets.lefty_car_taken("word")
	await wait_physics_frames(20)
	assert_true(main.rackets.lefty_car.grudge())
	await _get_in(c)
	await park(c, home + Vector2(30, 0), 0.0)
	await press_e()  # out, at his kerb
	await wait_physics_frames(30)
	assert_true(main.rackets.lefty_car.returned, "back where he left it")
	assert_false(main.rackets.lefty_car.grudge())
	assert_gt(main.rackets.memory.recent("lefty", "returned_car", main.rackets.night), 0)
	assert_string_contains(main.hud.notice_label.text, "back at his kerb")


func test_kept_in_a_saved_game() -> void:
	await _lefty_away()
	var c := _car()
	await _get_in(c)
	await park(c, Vector2(2300, 560), 0.0)
	await press_e()
	main.rackets.lefty_car.learn_danny("saw_driving", main.rackets.night)
	main.save_path = _save
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = false
	main.save_path = _save
	main.settings_path = ""
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(3)
	assert_lt(main.leftys_car.car().global_position.distance_to(Vector2(2300, 560)), 2.0, "where Danny left it")
	assert_eq(main.rackets.lefty_car.knows, "danny")
	assert_eq(main.rackets.lefty_car.how, "saw_driving")
	assert_true(main.fleet.thefts.is_stolen(main.leftys_car.index()), "still the car he took")
	assert_true(main.rival.brain.grudge, "the grudge with it")
