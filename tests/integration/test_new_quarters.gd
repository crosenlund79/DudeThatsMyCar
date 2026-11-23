extends "res://tests/support/city_test.gd"
## M015 the two new quarters in the game: Canal Market (south of Halloran
## Square, west of the yards) and Lincoln Terrace (north of the railroad):
## not built at the start; built ahead of Danny and driven or walked into
## without a stop or a jump - down Halloran Avenue from the square, west
## along Front Street from the yards, north up Wharf Street through the
## railroad's underpass; never more than three districts; each with its own
## beat cop, cars and name; the El's columns and the buildings solid; the El
## train on its timetable; the quarters on the city map.


func _ready_in(id: String) -> bool:
	return main.world.is_ready(id)


## Drives `c` from `from` along `dir` (W held) until `done` holds of its
## position; returns the largest step and where the district `id` was ready.
func _drive(c: Car, from: Vector2, heading: float, id: String, done: Callable) -> Dictionary:
	await park(c, from, heading)
	await seat_in(c)
	var worst := 0.0
	var ready_at := Vector2.INF
	var last := c.global_position
	for i in 60 * 25:
		cmd = PlayerCommand.make(Vector2(0, -1))
		await wait_physics_frames(1)
		assert_lte(main.world.loaded.size(), DistrictStreamer.MAX_LOADED, "three districts at most")
		worst = maxf(worst, c.global_position.distance_to(last))
		last = c.global_position
		if ready_at == Vector2.INF and _ready_in(id):
			ready_at = c.global_position
		if done.call(c.global_position):
			break
	cmd = PlayerCommand.new()
	return {"worst": worst, "ready_at": ready_at, "at": c.global_position}


func test_the_quarters_are_not_built_at_the_start() -> void:
	assert_false(_ready_in("market"))
	assert_false(_ready_in("terrace"))
	assert_eq(main.world.ready_ids(), ["riverside"] as Array[String])
	assert_eq(main.world.order.size(), 5, "five districts in the plan")
	assert_eq(main.world.district_at(Vector2(-3500, 3400)), "market")
	assert_eq(main.world.district_at(Vector2(3300, -2000)), "terrace")


func test_driving_down_halloran_avenue_into_canal_market() -> void:
	main.world.load_now("halloran")
	var c := main.fleet.cars[7] as Car
	var out := await _drive(c, Vector2(-3500 + 28, 1500), PI / 2, "market",
		func(p: Vector2) -> bool: return p.y > 3150.0)
	assert_true(_ready_in("market"))
	assert_lt(out.ready_at.y, 2700.0 - 300.0, "built and there before he reached the border")
	assert_gt(out.at.y, 3150.0, "he drove straight on into the market")
	assert_lt(out.worst, 12.0, "no stop, no jump at the border")
	assert_eq(main.world.current, "market")
	assert_eq(main.hud.district_label.text, "CANAL MARKET")
	assert_string_contains(main.hud.place_label.text, "Halloran Ave")
	assert_not_null(main.police.district_officer("market"), "the market's own beat cop")
	var st: Dictionary = main.world.stats.market
	gut.p("Canal Market: built in %.1f ms of work over %d frames (worst frame %.1f ms, worst step %.1f ms)" % [
		st.work_usec / 1000.0, st.frames, st.worst_frame_usec / 1000.0, st.worst_step_usec / 1000.0])
	assert_lt(st.worst_frame_usec, 20000, "no frame of building takes long")


func test_walking_west_along_front_street_from_the_yards() -> void:
	main.world.load_now("yards")
	walker().place(Vector2(-1450, 2790), PI)
	var worst := 0.0
	var last := walker().global_position
	for i in 60 * 20:
		cmd = PlayerCommand.make(Vector2(-1, 0))
		await wait_physics_frames(1)
		worst = maxf(worst, walker().global_position.distance_to(last))
		last = walker().global_position
		if walker().global_position.x < -1900.0:
			break
	cmd = PlayerCommand.new()
	assert_true(_ready_in("market"))
	assert_lt(walker().global_position.x, -1900.0, "he walked on into the market's Front Street")
	assert_lt(worst, 6.0, "no jump at the border")
	assert_eq(main.hud.district_label.text, "CANAL MARKET")


func test_up_wharf_street_through_the_underpass_into_lincoln_terrace() -> void:
	var c := main.fleet.cars[7] as Car
	var out := await _drive(c, Vector2(3300 + 28, -250), -PI / 2, "terrace",
		func(p: Vector2) -> bool: return p.y < -1750.0)
	assert_true(_ready_in("terrace"))
	assert_gt(out.ready_at.y, -1300.0 + 300.0, "built before he reached the bridge")
	assert_lt(out.at.y, -1750.0, "under the railroad and on into the terrace")
	assert_lt(out.worst, 12.0, "no stop, no jump under the bridge")
	assert_eq(main.world.current, "terrace")
	assert_eq(main.hud.district_label.text, "LINCOLN TERRACE")
	assert_string_contains(main.hud.place_label.text, "Wharf")
	assert_not_null(main.police.district_officer("terrace"), "the terrace's own beat cop")
	var ward: DistrictLayout = main.world.layouts.riverside
	assert_false(ward.is_open_ground(Vector2(3000, -1200)), "the embankment beside the underpass is solid")
	assert_true(ward.is_open_ground(Vector2(3300, -1200)), "the road under the bridge is open")


func test_the_el_and_the_buildings_are_solid() -> void:
	main.world.load_now("halloran")
	main.world.load_now("market")
	var l: DistrictLayout = main.world.layouts.market
	var col := Vector2.INF
	for p in l.props:
		if p.kind == "props/el_column" and absf(p.pos.y - (3460.0 - 115.0 + 8.0)) < 1.0 and p.pos.x > -3300.0:
			col = p.pos
			break
	assert_ne(col, Vector2.INF, "a column at the north kerb")
	var q := PhysicsPointQueryParameters2D.new()
	q.position = col
	assert_false(main.get_world_2d().direct_space_state.intersect_point(q).is_empty(), "the column is a solid body")
	# walk south into it from the pavement: he goes round it, never through it
	walker().place(col + Vector2(0, -50), PI / 2)
	cmd = PlayerCommand.make(Vector2(0, 1), false, false, col + Vector2(0, 200))
	var closest := INF
	for i in 90:
		await wait_physics_frames(1)
		closest = minf(closest, walker().global_position.distance_to(col))
	cmd = PlayerCommand.new()
	assert_gt(closest, 7.0 + 4.0, "never inside the El's column")
	# and north into the baths' wall from Canal Street
	var baths: Rect2 = l.buildings[l.building_named("Canal Street Baths")].rect
	walker().place(Vector2(baths.get_center().x + 120.0, baths.end.y + 30.0), -PI / 2)
	await hold(Vector2(0, -1), 90)
	assert_false(baths.has_point(walker().global_position), "the baths' wall stops him")
	assert_gt(walker().global_position.y, baths.end.y - 1.0)


func test_the_el_train_keeps_its_timetable() -> void:
	main.world.load_now("halloran")
	main.world.load_now("market")
	var city: City = main.world.city_of("market")
	assert_not_null(city.el_train, "the market's El has its train")
	var t: ElTrain = city.el_train
	var run := t.a.distance_to(t.b) / ElTrain.SPEED
	var start: Dictionary = t.at_time(0.0)
	assert_true(start.running)
	assert_almost_eq((start.pos as Vector2).distance_to(t.a), 0.0, 0.5, "it sets out from the west end")
	var mid: Dictionary = t.at_time(run * 0.5)
	assert_almost_eq((mid.pos as Vector2).distance_to(t.a.lerp(t.b, 0.5)), 0.0, 0.5, "halfway at half the run")
	var at_terminal: Dictionary = t.at_time(run + 1.0)
	assert_false(at_terminal.running, "standing at the terminal")
	assert_almost_eq((at_terminal.pos as Vector2).distance_to(t.b), 0.0, 0.5)
	var back: Dictionary = t.at_time(run + ElTrain.WAIT_TERMINAL + run * 0.25)
	assert_true(back.running, "and back again")
	assert_lt((back.pos as Vector2).distance_to(t.b), (back.pos as Vector2).distance_to(t.a))
	var l: DistrictLayout = main.world.layouts.market
	assert_almost_eq(t.a.y, 3400.0, 0.01, "along Market Street's El")
	assert_almost_eq(t.b.y, 3400.0, 0.01)
	assert_true(l.bounds.has_point(t.b), "the terminal end is in the market")
	assert_lt(t.a.x, l.play_area.position.x, "the far end is out past the market's west edge, out of sight")


func test_never_more_than_three_with_five_districts() -> void:
	main.world.load_now("halloran")
	main.world.load_now("market")
	assert_eq(main.world.ready_ids(), ["riverside", "halloran", "market"] as Array[String])
	# east along Front Street into the yards: the square, far behind, makes room
	walker().place(Vector2(-1500, 2790), 0.0)
	for i in 900:
		assert_lte(main.world.loaded.size(), 3, "three districts at most")
		if _ready_in("yards"):
			break
		await wait_physics_frames(1)
	assert_true(_ready_in("yards"))
	assert_true(_ready_in("riverside"), "the ward is pinned")
	assert_false(_ready_in("halloran"), "the square was let go to make room")
	assert_eq(main.police.officers().size(), main.world.ready_ids().size(), "one beat cop a built district")


func test_the_quarters_on_the_city_map() -> void:
	var m: CityMap = main.hud.city_map
	assert_eq(m.minimap.districts.size(), 5)
	var market: DistrictLayout = main.world.layouts.market
	var terrace: DistrictLayout = main.world.layouts.terrace
	var square: DistrictLayout = main.world.layouts.halloran
	var ward: DistrictLayout = main.world.layouts.riverside
	assert_true(m.city_rect.encloses(market.bounds))
	assert_true(m.city_rect.encloses(terrace.bounds))
	assert_almost_eq(market.bounds.position.y, square.bounds.end.y, 0.01, "the market begins where the square ends")
	assert_almost_eq(terrace.bounds.end.y, ward.bounds.position.y, 0.01, "the terrace ends at the ward's north edge")
	assert_eq(m.minimap.colour_at(Vector2(-3500, 3000)), Minimap.STREET, "Halloran Avenue runs on south")
	assert_eq(m.minimap.colour_at(Vector2(3300, -1500)), Minimap.STREET, "Wharf Street runs on north")
	var labels: Array = m.landmarks.map(func(l: Dictionary) -> String: return l.label)
	for want in ["Canal Market Hall", "St. Casimir's Plaza", "Market St. El terminal", "The Belvedere Hotel",
			"Paradise Ballroom", "The Old Water Tower", "Wharf Street underpass"]:
		assert_has(labels, want, "%s on the map" % want)
