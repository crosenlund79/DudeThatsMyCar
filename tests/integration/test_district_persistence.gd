extends "res://tests/support/city_test.gd"
## M008 the districts over time: a game saved in any district loads there
## (M012: where and when it was saved, that district built at once, the other
## neighbour only when he goes there), with what tonight left behind - a beat cop shot dead stays down until the
## next evening; sleeping puts every district back as a night starts; the
## police and Lefty stay on their own district's ground across a border; each
## district's beat cop answers a shooting in his district; bullets in a freed
## district are let go.

var _save := ""


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _reload() -> void:
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


func _until(cond: Callable, frames: int = 900) -> bool:
	for i in frames:
		if cond.call():
			return true
		await wait_physics_frames(1)
	return false


func _cop_of(id: String) -> PoliceOfficer:
	return main.police.district_officer(id)


func _victim(at: Vector2) -> Walker:
	var v := Walker.create(main.resolver, "characters/worker", {"glow": false})
	main.add_child(v)
	v.place(at, 0.0)
	return v


func test_saved_in_each_district_and_loaded() -> void:
	_save = OS.get_user_data_dir().path_join("test_districts_%d.json" % Time.get_ticks_usec())
	for id in ["yards", "halloran"]:
		main.save_path = _save
		main.world.load_now(id)
		var l: DistrictLayout = main.world.layouts[id]
		var at: Vector2 = l.police_beat[0] + Vector2(0, 60)
		walker().place(at, 0.0)
		await wait_physics_frames(3)
		assert_eq(main.world.current, id)
		await _reload()
		assert_lt(walker().global_position.distance_to(at), 2.0, "%s: the game goes on where he was (M012)" % l.name)
		assert_eq(main.world.ready_ids(), ["riverside", id] as Array[String], "the ward and %s built, nothing else" % l.name)
		await wait_physics_frames(3)
		assert_eq(main.hud.district_label.text, l.name.to_upper())
		assert_true(main.world.is_ready(id), "%s built again" % l.name)
		assert_eq(main.fleet.cars.size(), 9 + l.cars.size(), "no car twice")
	main.save_path = ""


func test_a_beat_cop_shot_dead_stays_down_tonight() -> void:
	_save = OS.get_user_data_dir().path_join("test_districts_cop_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	main.world.load_now("yards")
	var cop := _cop_of("yards")
	for i in 30:
		if cop.is_down():
			break
		cop.body.hit_by_bullet(cop.body.global_position + Vector2(0, 4), Vector2.RIGHT, walker())
	assert_true(cop.is_down())
	var where := cop.body.global_position
	await _reload()
	main.world.load_now("yards")
	var again := _cop_of("yards")
	assert_true(again.is_down(), "still lying there after a reload")
	assert_eq(again.body.global_position, where)
	assert_eq(main.police.officers().size(), 2)
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	main.world.load_now("yards")
	assert_false(_cop_of("yards").is_down(), "the next evening there is a new man on the beat")
	main.save_path = ""


func test_sleeping_puts_every_district_back() -> void:
	main.world.load_now("halloran")
	var i: int = 9  # the square's first parked car
	var c: Car = main.fleet.cars[i]
	var spec: Dictionary = main.fleet.specs[i]
	await park(c, spec.pos + Vector2(300, 0), 0.0)
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(5)
	assert_eq(c.global_position, spec.pos as Vector2, "back where its owner left it")
	assert_true(main.world.state.values().all(func(s: Dictionary) -> bool: return not s.has("officer")), "every beat has its man")


func test_the_police_and_lefty_stay_on_their_own_ground() -> void:
	main.world.load_now("yards")
	var ward: Rect2 = main.layout.play_area
	# the ward's beat cop saw Danny shoot somebody on Kessler Street...
	main.officer.brain.witness_violence(Vector2(1650, 2500))
	main.rival.provoke()
	# ...and Danny is far down in the yards
	walker().place(Vector2(1650, 3800), 0.0)
	var left := false
	for t in 60 * 30:
		if not ward.grow(2.0).has_point(main.officer.body.global_position) or not ward.grow(2.0).has_point(main.rival.body.global_position):
			left = true
			break
		if not main.officer.brain.is_hunting() and t > 60:
			break
		await wait_physics_frames(1)
	assert_false(left, "neither crosses into another district")
	assert_true(await _until(func() -> bool: return not main.officer.brain.is_hunting(), 60 * 30), "the copper gives up at the edge")


func test_each_district_s_beat_cop_answers_a_shooting_there() -> void:
	main.world.load_now("halloran")
	var cop := _cop_of("halloran")
	var at := cop.body.global_position
	walker().place(at + Vector2(30, 220), -PI / 2)
	var v := _victim(at + Vector2(30, 150))
	await wait_physics_frames(3)
	await click(v.global_position)
	await aim_for(v.global_position, 25)
	assert_true(cop.brain.armed, "the square's copper saw it")
	assert_false(main.officer.brain.armed, "the ward's man, far away, did not")
	var shots := [0]
	cop.fired.connect(func(_m: Vector2, _d: Vector2) -> void: shots[0] += 1)
	assert_true(await _until(func() -> bool: return shots[0] > 0, 60 * 6), "and he fires")


func test_bullets_in_a_freed_district_are_let_go() -> void:
	var b: BulletWorld = main.bullets
	b.bullets.append({"pos": Vector2(1650, 3500), "dir": Vector2.RIGHT, "speed": 10.0, "left": 500.0, "exclude": [] as Array[RID], "shooter": null})
	b.bullets.append({"pos": Vector2(1650, 600), "dir": Vector2.RIGHT, "speed": 10.0, "left": 500.0, "exclude": [] as Array[RID], "shooter": null})
	b.drop_in(main.world.layouts.yards.bounds)
	assert_eq(b.bullets.size(), 1, "the one in the yards is gone, the ward's flies on")
