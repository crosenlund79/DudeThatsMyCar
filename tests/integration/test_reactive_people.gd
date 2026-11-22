extends "res://tests/support/city_test.gd"
## M012 the people Danny knows, in the game: Rourke calls him over when he
## comes into the Copper Owl with business on the table, and answering opens
## on what he called him for, with his usual choices; nobody calls twice a
## night, and a call is not repeated after saving and loading; Quilty calls
## and comes a few steps over, and goes back to his place when Danny walks
## off; nobody calls while Danny sits at the cards or just after a shot;
## Augie remembers a threat; Quilty hears of a shooting only when the talk
## reaches him; by the hour Quilty goes home and Leon takes his coffee at
## Dutch's, where Danny can find him.

var _save := ""


func before_each() -> void:
	callouts = true
	await super()


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _calls_within(ticks: int) -> String:
	for i in ticks:
		await wait_physics_frames(1)
		if not main.people.callout.is_empty():
			return String(main.people.callout.id)
	return ""


func test_rourke_calls_danny_over_and_answering_opens_on_it() -> void:
	var owl: InteriorPlan = main.interiors.plan_named("copper_owl")
	assert_true(main.rackets.job.rourke_has_business(main.rackets.night))
	walker().place(owl.inside_door(0, 20.0), -PI / 2)
	main.camera.snap_to(walker())
	await walk_to(Vector2(2290, 380), 6.0, 200)
	var id: String = await _calls_within(120)
	assert_eq(id, "rourke_business", "Rourke calls him over")
	assert_true(main.overhead.visible)
	assert_eq(main.overhead.label.text, Callouts.LINES.rourke_business.call)
	var rourke: Walker = main.interiors.person("copper_owl", "rourke")
	assert_lt(angle_difference(rourke.model.facing, (walker().global_position - rourke.global_position).angle()), 0.6,
		"and turns to him")
	await talk_to("copper_owl", "rourke")
	assert_eq(main.dialogue.talking, "rourke")
	assert_string_contains(main.hud.line_label.text, Callouts.LINES.rourke_business.follow, "the talk opens on what he called him for")
	assert_false(main.hud.line_label.text.contains("["), "no stage direction on screen")
	assert_true(main.dialogue.page.options.size() > 1, "with his usual choices")
	await answer_with("bye")
	# not twice tonight
	await wait_physics_frames(120)
	walker().place(owl.outside_door(0, 30.0), PI / 2)
	await wait_physics_frames(10)
	walker().place(Vector2(2290, 380), 0.0)
	assert_eq(await _calls_within(150), "", "he does not call twice a night")


func test_quilty_comes_over_and_goes_back_when_ignored() -> void:
	var q: InteriorPlan = main.interiors.plan_named("quilty_office")
	var quilty: Walker = main.interiors.person("quilty_office", "quilty")
	var home := quilty.global_position
	walker().place(q.inside_door(0, 20.0), -PI / 2)
	main.camera.snap_to(walker())
	assert_eq(await _calls_within(120), "quilty_hello")
	await wait_physics_frames(40)
	assert_gt(quilty.global_position.distance_to(home), 4.0, "a few steps his way")
	assert_lt(quilty.global_position.distance_to(home), 60.0, "only a few")
	# Danny walks off without a word
	walker().place(q.outside_door(0, 300.0), PI / 2)
	main.camera.snap_to(walker())
	for i in 400:
		await wait_physics_frames(1)
		if main.people.callout.is_empty():
			break
	assert_true(main.people.callout.is_empty(), "the call lapses")
	assert_lt(quilty.global_position.distance_to(home), 1.0, "back in his chair")


func test_nobody_calls_at_the_cards_or_after_a_shot() -> void:
	await talk_to("back_room", "poker")
	assert_true(main.hud.poker_view.is_open())
	main.rackets.callouts.begin_night(main.rackets.night)
	assert_eq(await _calls_within(60), "", "at the card table: nobody")
	main.back_rooms.leave_poker()
	await wait_physics_frames(3)
	# a shot in the street, then straight into Quilty's office
	walker().place(STREETCAR_STOP, 0.0)
	await click(walker().global_position + Vector2(200, 0))
	await wait_physics_frames(20)
	var q: InteriorPlan = main.interiors.plan_named("quilty_office")
	walker().place(q.inside_door(0, 20.0), -PI / 2)
	assert_eq(await _calls_within(120), "", "not with a shot still in the air")


func test_augie_remembers_a_threat() -> void:
	main.rackets.memory.remember("augie", "threat", main.rackets.night)
	await talk_to("copper_owl", "augie")
	await answer_with("bye")
	main.rackets.callouts.begin_night(main.rackets.night)
	main.people.callout = {}
	assert_eq(await _calls_within(120), "augie_wary")
	assert_string_contains(main.overhead.label.text, "Hands")


func test_a_call_is_not_repeated_after_saving_and_loading() -> void:
	_save = OS.get_user_data_dir().path_join("test_people_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	var q: InteriorPlan = main.interiors.plan_named("quilty_office")
	walker().place(q.inside_door(0, 20.0), -PI / 2)
	assert_eq(await _calls_within(120), "quilty_hello")
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = callouts  # M012: as in before_each
	main.save_path = _save
	main.settings_path = ""
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(3)
	assert_not_null(main.interiors.current, "back in Quilty's office (the save was made there)")
	assert_eq(await _calls_within(150), "", "he greeted him already tonight")


func test_quilty_hears_of_a_shooting_through_the_talk() -> void:
	main.rackets.shot_person("sal")
	var q: InteriorPlan = main.interiors.plan_named("quilty_office")
	walker().place(q.inside_door(0, 20.0), -PI / 2)
	assert_eq(await _calls_within(120), "quilty_hello", "the same night he has not heard")
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	walker().place(q.inside_door(0, 20.0), -PI / 2)
	main.camera.snap_to(walker())
	assert_eq(await _calls_within(150), "quilty_shooting", "the next night the barber's chair has told him")


func test_quilty_goes_home_and_leon_takes_his_coffee_at_dutchs() -> void:
	main.clock.set_time(25 * 60.0 + 5.0)
	await wait_physics_frames(3)
	assert_false(main.interiors.view_of("quilty_office").person_ok("quilty"), "gone home after one")
	main.clock.set_time(24 * 60.0 + 5.0)
	main.world.load_now("yards")
	walker().place(Routines.LEON_AT_DUTCH + RiverfrontYards.ORIGIN + Vector2(0, 26), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(5)
	assert_false(main.interiors.view_of("dispatch_office").person_ok("leon"), "not at his desk")
	assert_true(main.people.leon_at_dutch.visible, "at Dutch's counter")
	assert_string_contains(main.hud.prompt_label.text, "Leon Sobczak")
	await press_e()
	assert_eq(main.dialogue.talking, "leon", "and Danny can talk to him there")
	await answer_with("bye")
	main.clock.set_time(24 * 60.0 + 40.0)
	await wait_physics_frames(3)
	assert_false(main.people.leon_at_dutch.visible, "back to his desk")
	assert_true(main.interiors.view_of("dispatch_office").person_ok("leon"))
