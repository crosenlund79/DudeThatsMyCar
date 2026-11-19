extends "res://tests/support/city_test.gd"
## M009 playthrough, the experience target with the normal controls, over
## three nights. Night 1: while Danny is still at home an argument starts
## outside Sal's barber shop and runs its course without him; he takes his
## sedan down Kessler Street into the Riverfront Yards, takes on Dutch's
## crate, loads it at the kerb and drives it back up to Novak's, where he is
## paid - his own money; on the way back he comes upon a handoff in the
## alley behind the Copper Owl half way through and takes a cut. He never
## goes to Halloran Square, so at eleven the Bijou's late show is cancelled
## without him. Night 2: the ward is talking (the crate run, the Bijou), a
## new night's incidents are planned, Dutch has another crate. Night 3: the
## talk has reached Rourke, who remarks on Danny's own work without holding
## it against him; Rourke's own job for Danny was never touched. Saved and
## loaded, the night begins again as it should.

var _save := ""


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _skip(minutes: float) -> void:
	var end: float = main.clock.minute + minutes
	while main.clock.minute < end:
		main.clock.set_time(minf(main.clock.minute + 2.0, end))
		main._update_clock(0.0)
		await wait_physics_frames(1)


func _history(id: String) -> Dictionary:
	for h in main.incidents.history:
		if h.id == id:
			return h
	return {}


func _out_of_the_car() -> void:
	cmd = PlayerCommand.make(Vector2(0, 1))
	await wait_physics_frames(40)
	cmd = PlayerCommand.new()
	for i in 20:
		if player().on_foot():
			return
		await press_e()


func test_three_nights_in_a_city_that_does_not_wait() -> void:
	_save = OS.get_user_data_dir().path_join("test_city_sleep_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	var job_before: Dictionary = main.rackets.job.to_dict()
	var start_money: int = main.rackets.money
	# --- night 1, at home: the city starts without him
	var home: InteriorPlan = main._plan("home")
	walker().place(home.outside_door(0, 20.0), PI / 2)
	main.camera.snap_to(walker())
	main.incidents.plan = [{"id": "p1", "kind": "argument", "spot": "sal_kerb", "at": main.clock.minute + 1.0, "tries": 0}]
	await _skip(3.0)
	assert_false(main.incidents.get_incident("p1").is_empty(), "an argument outside Sal's, with Danny nowhere near")
	# into the sedan and down Kessler Street into the yards
	var sedan: Car = main.my_car()
	await walk_to(sedan.global_position + Vector2(0, -40), 8.0, 600)
	await press_e()
	assert_eq(player().car, sedan)
	await drive_route(sedan, [Vector2(2300, 650), Vector2(1700, 650), Vector2(1690, 1600)], 260.0, 900)
	await drive_route(sedan, [Vector2(1690, 2600), Vector2(1690, 3900)], 260.0, 900)
	var yards: DistrictLayout = main.world.layouts.yards
	assert_eq(main.world.current, "yards")
	var crate_at: Vector2 = yards.errands[0].pos
	await drive_route(sedan, [Vector2(1660, 3972), Vector2(crate_at.x + 20.0, 3965)], 160.0, 900)
	await _out_of_the_car()
	# Dutch, and his crate into the boot
	var dutch: Walker = main.opportunity_views.contact("dutch")
	assert_not_null(dutch)
	await walk_to(dutch.global_position + Vector2(0, 26), 6.0, 600)
	await press_e()
	assert_eq(main.talking, "dutch")
	await answer_with("take")
	await press_e()
	await walk_to(crate_at + Vector2(0, 20), 6.0, 400)
	await press_e()
	assert_eq(main.rackets.opportunities.crate, "loaded", "into the sedan's boot")
	assert_true(sedan.has_meta("cargo"))
	# back up Kessler Street to Novak's
	await seat_in(sedan)
	await drive_route(sedan, [Vector2(1720, 3972), Vector2(1712, 3700), Vector2(1712, 2600), Vector2(1712, 1600),
		Vector2(1712, 760), Vector2(1980, 690)], 240.0, 2400)
	assert_eq(main.world.current, "riverside")
	await _out_of_the_car()
	assert_not_null(main._crate_car_at(main._novak_door()), "out front of Novak's")
	var money: int = main.rackets.money
	await talk_to("grocery", "novak")
	await answer_with("crate")
	await press_e()
	assert_eq(main.rackets.money - money, Opportunities.CRATE_PAY, "paid at Novak's")
	assert_eq(main.rackets.held, 0, "his own money: nothing set aside for Rourke")
	# the handoff in the alley behind the club, come upon half way through
	walker().place(Vector2(1000, 1500), 0.0)
	main.camera.snap_to(walker())
	main.incidents.plan.append({"id": "p2", "kind": "exchange", "spot": "owl_alley", "at": main.clock.minute + 1.0, "tries": 0})
	await _skip(16.0)
	var p2: Dictionary = main.incidents.get_incident("p2")
	assert_false(p2.is_empty(), "a handoff behind the Copper Owl")
	assert_eq(main.incidents.phase_name(p2), "handing", "already under way")
	walker().place(Vector2(2440, 160), 0.0)
	main.camera.snap_to(walker())
	await wait_physics_frames(4)
	var man: Walker = main.incident_views.people_of("p2")[0]
	await walk_to(man.global_position + Vector2(-24, 0), 6.0, 300)
	money = main.rackets.money
	await press_e()
	await answer_with("cut")
	await press_e()
	assert_eq(main.rackets.money - money, main.HUSH_MONEY)
	# meanwhile, outside Sal's, the argument ran its course
	assert_false(_history("p1").is_empty(), "it ended without him")
	assert_eq(_history("p1").mercer, "")
	# he never goes to Halloran Square: at eleven the Bijou's late show is off without him
	main.clock.set_time(Opportunities.REEL_SHOW - 1.0)
	await _skip(2.0)
	assert_eq(main.rackets.opportunities.reel, "cancelled", "a chance he never heard of, gone")
	# --- home to bed: night 2
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(5)
	assert_eq(main.rackets.night, 2)
	assert_false(sedan.has_meta("cargo"))
	assert_true(main.incidents.history.is_empty(), "a new night's troubles")
	assert_false(main.incidents.plan.is_empty())
	assert_eq(main.rackets.opportunities.crate, "waiting", "Dutch has another crate")
	assert_eq(main.rackets.opportunities.reel, "none")
	assert_gt(main.rackets.rumours.known_to("augie", "crate_run").size(), 0, "Novak told Augie about the crate")
	assert_gt(main.rackets.rumours.known_to("sal", "reel_cancelled").size(), 0, "Feeney told Sal about the Bijou")
	assert_true(main.rackets.boss.heard.is_empty() or not main.rackets.boss.heard.any(func(h: Dictionary) -> bool:
		return String(h.text).contains("crates")), "Rourke has not heard yet")
	# --- night 3: Rourke has heard, and minds only his envelopes
	var trust: int = main.rackets.boss.trust
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(5)
	assert_eq(main.rackets.night, 3)
	assert_true(main.rackets.boss.heard.any(func(h: Dictionary) -> bool: return String(h.text).contains("hauling crates")),
		"two nights on, through Novak and Augie")
	var news: Dictionary = main.talk.choose("rourke", "news", main._talk_context())
	assert_string_contains(news.text, "Your own time's your own business")
	assert_eq(main.rackets.job.to_dict(), job_before, "Rourke's own job for Danny untouched, still his to take")
	assert_true(main.rackets.job.rourke_has_business(main.rackets.night) or main.rackets.job.stage == RourkeJob.Stage.NOT_OFFERED,
		"and it has not run out")
	assert_gt(main.rackets.money, start_money, "Danny's own earnings in his pocket")
	assert_eq(main.rackets.opportunities.crate, "none", "night 3: no crate")
	# saved and loaded: the night begins again at dusk, nothing doubled
	main.save_game()
	var nights_history: int = main.rackets.opportunities.history.size()
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
	assert_eq(main.rackets.night, 3)
	assert_eq(main.rackets.opportunities.history.size(), nights_history, "what Danny did on earlier nights is kept")
	var hist: Array = main.rackets.opportunities.history
	assert_true(hist.any(func(h: Dictionary) -> bool: return h.night == 1 and h.what == "crate" and h.outcome == "delivered"),
		"night 1: delivered")
	assert_true(hist.any(func(h: Dictionary) -> bool: return h.night == 2 and h.what == "crate" and h.outcome == "gone"),
		"night 2: left alone, Dutch found another way")
	assert_true(hist.any(func(h: Dictionary) -> bool: return h.night == 1 and h.what == "reel" and h.outcome == "cancelled"))
	assert_false(main.incidents.plan.is_empty(), "tonight's troubles are planned again")
	main.save_path = ""
