extends "res://tests/support/city_test.gd"
## M009 the city's own incidents in the game: they begin, go on and end on the
## clock with Danny nowhere near (and nobody drawn); coming upon one half way
## through he finds it as it stands, not started over; walking away, it goes
## on without him; stepping in changes how it ends (and what it brings or
## costs); gunfire scatters them; the ward talks about it afterwards.


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


## Tonight's plan replaced by one incident, due a minute from now.
func _due(kind: String, spot: String, id: String = "t1") -> void:
	main.incidents.plan = [{"id": id, "kind": kind, "spot": spot, "at": main.clock.minute + 1.0, "tries": 0}]


## The clock moved on by `minutes`, a couple of minutes a frame.
func _skip(minutes: float) -> void:
	var end: float = main.clock.minute + minutes
	while main.clock.minute < end:
		main.clock.set_time(minf(main.clock.minute + 2.0, end))
		main._advance_incidents()
		await wait_physics_frames(1)


func _history(id: String) -> Dictionary:
	for h in main.incidents.history:
		if h.id == id:
			return h
	return {}


func _views() -> IncidentViews:
	return main.incident_views


## Danny is put at p, the camera with him.
func _go(p: Vector2, rot: float = 0.0) -> void:
	walker().place(p, rot)
	main.camera.snap_to(player().body())


func test_it_happens_with_nobody_there() -> void:
	_due("argument", "depot_kerb")  # in the yards, which are not even built
	assert_false(main.world.is_ready("yards"))
	await _skip(3.0)
	assert_false(main.incidents.get_incident("t1").is_empty(), "begun")
	assert_true(_views().views.is_empty(), "nobody drawn far away")
	await _skip(40.0)
	var h := _history("t1")
	assert_false(h.is_empty(), "over without Danny")
	assert_true(h.outcome in ["settled", "blows"])
	assert_eq(h.mercer, "")


func test_found_as_it_stands_and_left_to_go_on() -> void:
	_go(Vector2(1000, 1500), 0.0)  # well away
	_due("exchange", "owl_alley")
	await _skip(18.0)  # 12 minutes of waiting, then the handing over has begun
	var inc: Dictionary = main.incidents.get_incident("t1")
	assert_eq(main.incidents.phase_name(inc), "handing")
	_go(Vector2(2440, 200), 0.0)
	await wait_physics_frames(3)
	var people := _views().people_of("t1")
	assert_eq(people.size(), 2, "two men in the alley")
	assert_lt((people[0] as Walker).global_position.distance_to((people[1] as Walker).global_position), 2.0 * IncidentViews.CLOSE + 12.0,
		"together, handing it over - not starting again from the wait")
	assert_eq(main.incidents.phase_name(inc), "handing", "seeing it did not restart it")
	# he walks off; it goes on and ends without him
	_go(Vector2(1000, 1500), 0.0)
	await wait_physics_frames(3)
	assert_true(_views().views.is_empty(), "out of sight, nobody drawn")
	await _skip(20.0)
	assert_eq(_history("t1").outcome, "done", "the deal went through")


func test_breaking_up_an_argument() -> void:
	_go(Vector2(1000, 1500), 0.0)
	_due("argument", "owl_kerb")
	await _skip(3.0)
	_go(Vector2(2120, 500), 0.0)
	await wait_physics_frames(5)
	var people := _views().people_of("t1")
	assert_eq(people.size(), 2)
	var a: Walker = people[0]
	var b: Walker = people[1]
	assert_lt(a.model.facing - (b.global_position - a.global_position).angle(), 0.3, "facing each other")
	walker().place(a.global_position + Vector2(0, 30), 0.0)
	await wait_physics_frames(2)
	assert_string_contains(main.hud.prompt_label.text, "Step in")
	await press_e()
	assert_eq(main.talking, "incident")
	await answer_with("calm")
	assert_eq(main.incidents.get_incident("t1").outcome, "broken_up")
	await press_e()
	await _skip(8.0)
	var h := _history("t1")
	assert_eq(h.outcome, "broken_up")
	assert_eq(h.mercer, "calm")
	assert_eq(main.rackets.memory.recent("augie", "favour", main.rackets.night), 1, "Augie saw it, from the club's door")
	assert_true(main.rackets.rumours.items.any(func(r: Dictionary) -> bool: return r.kind == "street_argument_broken_up"), "and talks")


func test_a_cut_of_somebody_s_business() -> void:
	_go(Vector2(1000, 1500), 0.0)
	_due("exchange", "owl_alley")
	await _skip(3.0)
	_go(Vector2(2440, 150), 0.0)
	await wait_physics_frames(5)
	var person: Walker = _views().people_of("t1")[0]
	walker().place(person.global_position + Vector2(-26, 0), 0.0)
	await wait_physics_frames(2)
	var money: int = main.rackets.money
	await press_e()
	await answer_with("cut")
	assert_eq(main.rackets.money - money, main.HUSH_MONEY, "two bucks to forget it")
	assert_eq(main.incidents.get_incident("t1").outcome, "hushed")


func test_the_copper_takes_a_dollar_or_takes_a_look_at_you() -> void:
	_go(Vector2(1000, 1500), 0.0)
	_due("stop", "marlowe_stop")
	await _skip(3.0)
	assert_false(main.incidents.get_incident("t1").is_empty())
	assert_false(main.officer.duty.is_empty(), "the beat cop goes to his stop")
	_go(Vector2(2070, 540), -PI / 2)
	for i in 120:
		await wait_physics_frames(1)
	assert_lt(main.officer.body.global_position.distance_to(main.officer.duty.pos), 12.0, "and stands there")
	var civ: Walker = _views().people_of("t1")[1]
	walker().place(civ.global_position + Vector2(0, 30), 0.0)
	await wait_physics_frames(2)
	main.rackets.money = 500
	await press_e()
	await answer_with("vouch")
	assert_eq(main.incidents.get_incident("t1").outcome, "vouched")
	assert_true(main.officer.brain.is_hunting(), "he takes a hard look at Danny")
	assert_false(main.officer.brain.armed, "but does not draw on him")
	assert_eq(main.officer.duty, {}, "and leaves the man be")
	await press_e()
	await _skip(6.0)
	assert_eq(_history("t1").outcome, "vouched", "the man went home")
	# another night, another stop: a dollar instead
	main.officer.reset()
	_go(Vector2(1000, 1500), 0.0)
	_due("stop", "marlowe_stop", "t2")
	await _skip(3.0)
	_go(Vector2(2070, 540), -PI / 2)
	for i in 120:
		await wait_physics_frames(1)
	civ = _views().people_of("t2")[1]
	walker().place(civ.global_position + Vector2(0, 30), 0.0)
	await wait_physics_frames(2)
	var money: int = main.rackets.money
	await press_e()
	await answer_with("bribe")
	assert_eq(money - main.rackets.money, Conversations.STOP_BRIBE)
	assert_false(main.officer.brain.is_hunting(), "squared")


func test_gunfire_scatters_them() -> void:
	_go(Vector2(1000, 1500), 0.0)
	_due("argument", "owl_kerb")
	await _skip(3.0)
	_go(Vector2(2120, 560), 0.0)
	await wait_physics_frames(3)
	await click(Vector2(2120, 800))  # into the street
	await aim_for(Vector2(2120, 800), int(main.gun_rules.draw_time * 60.0) + 4)
	assert_eq(_history("t1").outcome, "fled", "they break off and run")


func test_a_man_shot_ends_it() -> void:
	_go(Vector2(1000, 1500), 0.0)
	_due("argument", "novak_kerb")
	await _skip(3.0)
	_go(Vector2(1930, 820), 0.0)
	await wait_physics_frames(3)
	var a: Walker = _views().people_of("t1")[0]
	a.hit_by_bullet(a.global_position, Vector2.RIGHT, walker())
	await wait_physics_frames(2)
	assert_eq(_history("t1").outcome, "shooting")
	assert_true(main.rackets.rumours.items.any(func(r: Dictionary) -> bool: return r.kind == "street_argument_shooting"),
		"Novak saw it from his shop")


func test_the_ward_talks_about_it_next_night() -> void:
	_go(Vector2(1000, 1500), 0.0)
	main.incidents.plan = [{"id": "t1", "kind": "argument", "spot": "sal_kerb", "at": main.clock.minute + 1.0, "tries": 0}]
	# force the city's own ending: blows
	await _skip(3.0)
	main.incidents.get_incident("t1").outcome = "blows"
	await _skip(40.0)
	assert_eq(_history("t1").outcome, "blows")
	main.rackets.end_night()  # Sal saw it; by the next night it has reached Augie
	await talk_to("copper_owl", "augie")
	await answer_with("news")
	assert_string_contains(main.hud.line_label.text, "came to blows")
	assert_string_contains(main.hud.line_label.text, "outside Sal's")


func test_sticking_up_a_handoff() -> void:
	_go(Vector2(1000, 1500), 0.0)
	_due("exchange", "hotel_alley")
	await _skip(3.0)
	_go(Vector2(2700, 1000), 0.0)
	await wait_physics_frames(3)
	var person: Walker = _views().people_of("t1")[0]
	_go(person.global_position + Vector2(0, -26), PI / 2)
	# empty-handed, asking for it only spoils it; so the gun first
	walker().gun.draw()
	await wait_physics_frames(int(main.gun_rules.draw_time * 60.0) + 4)
	assert_true(walker().gun.is_drawn())
	var money: int = main.rackets.money
	await press_e()
	await answer_with("rob")
	assert_eq(main.incidents.get_incident("t1").outcome, "robbed")
	assert_eq(main.rackets.money - money, main.HANDOFF_TAKE)
	await press_e()
	await _skip(8.0)
	assert_eq(_history("t1").mercer, "rob")
