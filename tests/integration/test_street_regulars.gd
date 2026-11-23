extends "res://tests/support/city_test.gd"
## M015 the street's regulars in the ward: each out for their own hours (the
## newsboy early, the Copper Owl's crowd from nine, a drunk late), a couple
## walking together, a knot of talkers who say something now and then near
## the camera, the "ginger ale" van at the Owl's alley door with its carriers
## for an hour, a cab among the traffic; gunfire scatters them and they come
## back to their spots; a car coming at somebody standing about is dodged.


func before_each() -> void:
	quiet_streets = false
	await super.before_each()


func street() -> StreetLife:
	return main.street


func _local(look: String, kind: String, group := "") -> Pedestrian:
	for p in street().locals:
		if p.brain.kind == kind and String(p._spec.get("look", "")) == look and p.group == group:
			return p
	return null


func _at(minute: float) -> void:
	main.clock.set_time(minute)
	street().recount_locals(true)
	await wait_physics_frames(2)


func _owl_group() -> Array:
	return street().locals.filter(func(p: Pedestrian) -> bool: return p.group == "owl")


func test_each_is_out_for_their_hours() -> void:
	await _at(19 * 60 + 40.0)
	var newsboy := street().locals.filter(func(p: Pedestrian) -> bool: return p.lines.any(func(l: String) -> bool: return l.contains("Extra")))[0] as Pedestrian
	assert_true(newsboy.active, "the newsboy with the late edition")
	assert_false(_owl_group().any(func(p: Pedestrian) -> bool: return p.active), "nobody outside the Owl yet")
	var drunk := _local("characters/patron_man", "drunk")
	assert_false(drunk.active, "too early for him")
	await _at(22 * 60.0)
	assert_eq(_owl_group().filter(func(p: Pedestrian) -> bool: return p.active).size(), 3, "the Owl's crowd on the pavement")
	await _at(23 * 60 + 30.0)
	assert_true(drunk.active)
	assert_false(newsboy.active, "sold out and gone home")


func test_a_couple_walk_together() -> void:
	await _at(20 * 60 + 30.0)
	var him: Pedestrian = null
	var her: Pedestrian = null
	for p in street().locals:
		if p.companion != null:
			her = p
			him = p.companion
	assert_not_null(her)
	var start := him.body.global_position
	var widest := 0.0
	for i in 60 * 8:
		await wait_physics_frames(1)
		widest = maxf(widest, him.body.global_position.distance_to(her.body.global_position))
	assert_gt(him.body.global_position.distance_to(start), 150.0, "out walking")
	assert_lt(widest, 60.0, "side by side all the way")


func test_the_owls_crowd_says_something_now_and_then() -> void:
	await _at(22 * 60.0)
	var group := _owl_group()
	walker().place((group[0] as Pedestrian).body.global_position + Vector2(-60, 100), 0.0)
	main.camera.snap_to(walker())
	var heard := ""
	for i in 60 * 14:
		await wait_physics_frames(1)
		for p in group:
			var l: String = main.street_lines.line_of((p as Pedestrian).body)
			if l != "":
				heard = l
				assert_true((p as Pedestrian).lines.has(l), "their own lines")
		if heard != "":
			break
	assert_ne(heard, "", "a word over their heads within a few seconds")
	assert_lte(main.street_lines.speaking(), 2, "not everybody at once")


func test_the_ginger_ale_van_for_an_hour() -> void:
	assert_eq(street().service.size(), 1)
	var van: Car = street().service[0]
	await _at(21 * 60.0)
	assert_false(van.visible, "not yet")
	assert_eq(van.collision_layer, 0)
	await _at(21 * 60 + 45.0)
	assert_true(van.visible)
	assert_eq(van.collision_layer, Layers.CARS, "solid while it stands there")
	var carriers := street().locals.filter(func(p: Pedestrian) -> bool: return p.brain.kind == "carry")
	assert_eq(carriers.size(), 2)
	var door: Vector2 = main.layout.deliveries[0].door
	var reached := false
	var crates := false
	for i in 60 * 12:
		await wait_physics_frames(1)
		for c in carriers:
			var cp := c as Pedestrian
			if cp.body.global_position.distance_to(door) < 12.0:
				reached = true
			if cp.crate.visible:
				crates = true
	assert_true(reached, "carried to the Owl's back door")
	assert_true(crates, "a crate in his arms")
	walker().place(Vector2(400, 1300), 0.0)  # (away: they go only where nobody sees)
	main.camera.snap_to(walker())
	await wait_physics_frames(2)
	main.clock.set_time(22 * 60 + 40.0)
	street().recount_locals()
	assert_false(van.visible, "gone after its hour")


func test_gunfire_scatters_them_and_they_come_back() -> void:
	await _at(22 * 60.0)
	var p: Pedestrian = _owl_group()[0]
	var spot := p.brain.spot
	street().hear_gunshot(spot + Vector2(80, 0))
	assert_eq(p.brain.state, PedestrianBrain.State.FLEE)
	await wait_physics_frames(60 * 2)
	assert_gt(p.body.global_position.distance_to(spot), 60.0, "ran")
	await wait_physics_frames(60 * 12)
	assert_lt(p.body.global_position.distance_to(spot), 10.0, "and came back to the pavement outside the Owl")


func test_somebody_standing_about_gets_out_of_a_cars_way() -> void:
	await _at(20 * 60 + 40.0)
	var smoker := _local("characters/worker", "stand")
	assert_not_null(smoker)
	var at := smoker.body.global_position
	var c := car_of_type("sedan")
	await park(c, at + Vector2(0, -300), PI * 0.5)
	await seat_in(c)
	for i in 120:
		cmd = PlayerCommand.make(Vector2(0, -1))
		await wait_physics_frames(1)
	cmd = PlayerCommand.new()
	assert_eq(main.run_overs.tonight, 0, "nobody run down")
	assert_false(smoker.body.condition.is_hurt())


func test_a_cab_among_the_traffic() -> void:
	var cabs := street().traffic.filter(func(c: Car) -> bool: return c.vehicle.id == "taxi")
	assert_eq(cabs.size(), 1)
	var cab: Car = cabs[0]
	var from := cab.global_position
	await wait_physics_frames(60 * 5)
	assert_gt(cab.global_position.distance_to(from), 250.0, "going round for fares")
	assert_false(main.layout.is_in_building(cab.global_position))


func test_the_squares_regulars_come_with_their_district() -> void:
	walker().place(main.game.locations.at("halloran/spawn"), 0.0)  # (there: the square stays built)
	main.world.load_now("halloran")
	await wait_physics_frames(3)
	var sq: StreetLife = null
	for s2 in main.districts.streets():
		if s2.layout.id == "halloran":
			sq = s2
	assert_not_null(sq, "built with the square")
	assert_true(sq.say.is_valid(), "and they can speak")
	main.clock.set_time(22 * 60 + 30.0)
	sq.recount_locals(true)
	assert_eq(sq.locals.filter(func(p: Pedestrian) -> bool: return p.group == "bijou" and p.active).size(), 3,
		"the late show's crowd under the marquee")
	main.clock.set_time(26 * 60 + 45.0)
	sq.recount_locals(true)
	assert_true(sq.service[0].visible, "Kowalski's van before dawn")
	assert_true(sq.traffic.any(func(c: Car) -> bool: return c.vehicle.id == "taxi"))


func test_the_beat_cop_takes_his_post_and_has_a_word() -> void:
	var cop: PoliceOfficer = main.officer
	var post: Dictionary = main.layout.police_posts[0]
	main.clock.set_time(float(post.from) + 5.0)
	await wait_physics_frames(2)
	assert_true(bool(cop.duty.get("post", false)), "closing time: at his post outside the Owl")
	await wait_physics_frames(60 * 8)
	assert_lt(cop.body.global_position.distance_to(post.pos), 12.0, "standing there")
	walker().place(cop.body.global_position + Vector2(0, 80), -PI * 0.5)
	main.camera.snap_to(walker())
	await wait_physics_frames(20)
	assert_eq(main.street_lines.line_of(cop.body), String(post.line), "and a word for Danny")
	main.clock.set_time(float(post.until) + 1.0)
	await wait_physics_frames(2)
	assert_true(cop.duty.is_empty(), "his hour up: back on his beat")


func test_a_post_never_takes_a_copper_who_is_busy() -> void:
	var cop: PoliceOfficer = main.officer
	var post: Dictionary = main.layout.police_posts[0]
	var other := {"pos": Vector2(1900, 470), "face": Vector2(1900, 520)}
	cop.duty = other
	main.clock.set_time(float(post.from) + 5.0)
	await wait_physics_frames(2)
	assert_eq(cop.duty, other, "an incident had him first")
