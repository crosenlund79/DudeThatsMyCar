extends "res://tests/support/city_test.gd"
## M009.3 the city goes on when Danny is not looking: an incident in a
## neighbouring district is only state until the district is built round him,
## then it is shown as it stands; when the district is let go its people go
## with it and the incident carries on to its end; a whole night of the city's
## own troubles plays out on the clock alone, the same way every time; a saved
## and reloaded night does not hand him the same incidents again.

var _save := ""


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _go(p: Vector2, rot: float = 0.0) -> void:
	walker().place(p, rot)
	main.camera.snap_to(player().body())


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


func test_a_district_built_and_let_go_round_an_incident() -> void:
	_go(Vector2(1000, 600))
	var depot: Dictionary = main.incidents.spot("depot_kerb")
	main.incidents.plan = [{"id": "t1", "kind": "argument", "spot": "depot_kerb", "at": main.clock.minute + 1.0, "tries": 0}]
	await _skip(16.0)  # past its talking, into the heated part, with nobody there
	var inc: Dictionary = main.incidents.get_incident("t1")
	assert_eq(main.incidents.phase_name(inc), "heated")
	assert_true(main.incident_views.views.is_empty())
	# the yards are built round Danny and he comes upon it as it stands
	main.world.load_now("yards")
	_go(depot.pos + Vector2(0, 160))
	await wait_physics_frames(3)
	assert_eq(main.incident_views.people_of("t1").size(), 2, "two men, at it")
	assert_eq(main.incidents.phase_name(inc), "heated", "still heated: nothing started over")
	assert_true(inc.seen)
	# he goes home; the yards are let go and their people with them
	_go(main.layout.spawn)
	main.world.unload("yards")
	await wait_physics_frames(3)
	assert_false(main.incident_views.views.has("t1"), "nobody left standing in a district that is gone")
	assert_false(main.incidents.get_incident("t1").is_empty(), "but it is still going on")
	await _skip(20.0)
	assert_false(_history("t1").is_empty(), "and it ended on its own")
	assert_eq(get_tree().get_nodes_in_group("incident_people").size(), 0, "no one left behind")


func test_a_whole_night_on_its_own() -> void:
	_go(main.layout.spawn)
	var planned: Array = main.incidents.plan.map(func(p: Dictionary) -> String: return p.id)
	assert_gt(planned.size(), 3, "a few troubles tonight")
	assert_lt(planned.size(), 12, "but not a crowd of them")
	await _skip(float(main.night_rules.dawn_minute) - main.clock.minute)
	assert_true(main.incidents.active.is_empty(), "nothing left hanging at dawn")
	assert_true(main.incidents.plan.is_empty())
	assert_gt(main.incidents.history.size(), 2, "it happened without him")
	var ends := {}
	for h in main.incidents.history:
		assert_eq(h.mercer, "")
		ends[h.id] = h.outcome
	# the same night run again ends the same way
	var again := StreetIncidents.new(main.incidents.spots)
	again.begin_night(main.rackets.night, float(main.night_rules.start_minute), float(main.night_rules.dawn_minute))
	var m := float(main.night_rules.start_minute)
	while m < main.night_rules.dawn_minute:
		m += 2.0
		again.advance(m)
	for h in again.history:
		if ends.has(h.id):
			assert_eq(h.outcome, ends[h.id], "%s ends the same" % h.id)


func test_a_reloaded_night_does_not_repeat_itself() -> void:
	_save = OS.get_user_data_dir().path_join("test_incidents_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	_go(Vector2(1000, 1500))
	main.incidents.plan = [{"id": "t1", "kind": "argument", "spot": "owl_kerb", "at": main.clock.minute + 1.0, "tries": 0}]
	await _skip(40.0)
	assert_false(_history("t1").is_empty())
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = callouts  # M012: as in before_each
	main.save_path = _save
	main.settings_path = ""
	main.opening_enabled = false
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(3)
	assert_false(_history("t1").is_empty(), "remembered as over")
	var first: String = "n%d_0" % main.rackets.night
	main.incidents.begin_night(main.rackets.night, float(main.night_rules.start_minute), float(main.night_rules.dawn_minute),
		[{"id": first, "kind": "argument", "spot": "owl_kerb", "outcome": "settled", "mercer": ""}])
	assert_false(main.incidents.plan.any(func(p: Dictionary) -> bool: return p.id == first), "what is over tonight does not come round again")
	main.save_path = ""
