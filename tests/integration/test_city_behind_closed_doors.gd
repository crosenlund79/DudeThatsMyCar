extends "res://tests/support/city_test.gd"
## M012 the playthrough: two nights with the normal controls. Danny starts in
## the ward, walks over the border into Halloran Square and up City Hall's
## steps (the night clerk at his grille), looks in at Alderman Doran's office
## and the Regulars' Club, saves inside the club and loads (back in the club,
## at that minute) and walks out with E; drives Kessler Street down into the
## Riverfront Yards; walks into North Branch Freight's dispatch office, where
## Leon calls him over with his trouble; finds out at Dutch's counter why the
## shed holds the freight, pays the shed gang's six dollars himself and sees
## the corner emptied; saves and loads (the crates still gone); collects
## Leon's ten dollars once; back at the Copper Owl after half past one, the
## Bird's last song, her question and his answer; a pull at a machine in the
## gaming room; rain and fog kept outside the room he is in; sleeps; the next
## night everything he did is as he left it, and nothing starts over.

const SAVE := "user://test_city_behind_closed_doors.json"


func before_each() -> void:
	callouts = true
	await super()


func after_each() -> void:
	super()
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(SAVE)


func _reload() -> void:
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = true
	main.save_path = SAVE
	main.settings_path = ""
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(3)


func _street(l: DistrictLayout, street_name: String) -> Rect2:
	for st in l.streets:
		if st.name == street_name:
			return st.rect
	return Rect2()


func _crates_there() -> bool:
	return (main.interiors.view_of("freight_shed").get_node("freight_crates") as CanvasItem).visible


func test_two_nights_behind_closed_doors() -> void:
	main.save_path = SAVE
	main.rackets.money = 1500
	main.weather.force("clear")
	# 1-2. from the ward across the border into Halloran Square, on foot
	var h: DistrictLayout = main.world.layouts.halloran
	var marlowe := _street(main.layout, "Marlowe Avenue")
	var start := Vector2(main.layout.bounds.position.x + 220.0, marlowe.get_center().y - marlowe.size.y * 0.5 - 20.0)
	walker().place(start, PI)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	for i in 900:
		cmd = PlayerCommand.make(Vector2.LEFT, false, false, walker().global_position + Vector2(-60, 0))
		await wait_physics_frames(1)
		if main.world.current == "halloran":
			break
	cmd = PlayerCommand.new()
	assert_eq(main.world.current, "halloran", "into the square on foot, no loading")
	assert_true(main.world.is_ready("halloran"))
	# 3. City Hall: the night clerk
	var hall: InteriorPlan = main.interiors.plan_named("city_hall")
	assert_true(await walk_in_to(hall, "nightclerk"), "up the steps and in at the night door")
	await press_e()
	assert_eq(main.dialogue.talking, "nightclerk")
	await answer_with("upstairs")
	assert_string_contains(main.hud.line_label.text, "Mayor's office")
	await answer_with("bye")
	# 4. the political offices
	assert_true(await walk_in_to(main.interiors.plan_named("doran_office"), "doran_desk"))
	await press_e()
	assert_string_contains(main.hud.line_label.text, "STREETS & SANITATION")
	await answer_with("bye")
	var club: InteriorPlan = main.interiors.plan_named("regulars_club")
	assert_true(await walk_in_to(club, "steward"))
	await press_e()
	assert_eq(main.dialogue.talking, "steward")
	await answer_with("bye")
	# 5-6. saved in the club; loaded in the club; out with E
	var minute: float = main.clock.minute
	await _reload()
	assert_true(main.world.is_ready("halloran"))
	assert_not_null(main.interiors.current)
	assert_eq(main.interiors.current.id, "regulars_club", "back in the club")
	assert_almost_eq(main.clock.minute, minute, 1.0, "at that minute")
	club = main.interiors.plan_named("regulars_club")
	for q in path_in_room(club, walker().global_position, club.inside_door(0, 14.0), 6.0):
		await walk_to(q, 4.0, 120)
	await walk_to(club.inside_door(0, 10.0), 4.0, 120)
	await press_e()
	assert_null(main.interiors.current, "out on Marlowe Avenue")
	# 7. drive Kessler Street down into the yards
	var kessler := _street(main.layout, "Kessler Street")
	var car := roadster()
	await park(car, Vector2(kessler.get_center().x, kessler.end.y - 500.0), PI / 2)
	await seat_in(car)
	assert_eq(player().car, car)
	var y_front := RiverfrontYards.ORIGIN.y + RiverfrontYards.FRONT
	var door: Vector2 = main.world.layouts.yards.interiors[0].outside_door(0, 60.0)
	await drive_route(car, [Vector2(kessler.get_center().x, y_front - 40.0), Vector2(kessler.get_center().x + 60.0, y_front),
		Vector2(door.x - 60.0, y_front)], 160.0, 1500)
	assert_eq(main.world.current, "yards", "into the Riverfront Yards by car")
	cmd = PlayerCommand.make(Vector2(0, 1))
	await wait_physics_frames(90)
	cmd = PlayerCommand.new()
	await press_e()
	for i in 120:
		await wait_physics_frames(1)
		if player().on_foot():
			break
	assert_true(player().on_foot(), "out of the car")
	# 8-9. the dispatch office: Leon calls him over with his trouble
	var office: InteriorPlan = main.interiors.plan_named("dispatch_office")
	walker().place(office.outside_door(0, 30.0), PI / 2)
	await walk_to(office.inside_door(0, 30.0), 4.0, 200)
	var called := ""
	for i in 200:
		await wait_physics_frames(1)
		if not main.people.callout.is_empty():
			called = main.people.callout.id
			break
	assert_eq(called, "leon_job", "Leon calls out")
	var leon_spot: Vector2 = office.spots.filter(func(sp: Dictionary) -> bool: return sp.id == "leon")[0].pos
	for q in path_in_room(office, walker().global_position, leon_spot, 8.0):  # over to his desk, answering
		await walk_to(q, 4.0, 120)
	await press_e()
	assert_string_contains(main.hud.line_label.text, Callouts.LINES.leon_job.follow)
	await answer_with("freight_hear")
	await answer_with("freight_accept")
	await answer_with("bye")
	# 10. Dutch's counter tells why; Danny pays the shed gang's six himself
	var dutch_at: Vector2 = (main.world.layouts.yards as DistrictLayout).contacts[0].pos
	walker().place(dutch_at + Vector2(0, 30), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	await press_e()
	await answer_with("freight_ask")
	await answer_with("bye")
	assert_true(main.rackets.freight.learned.has("docked"))
	var money: int = main.rackets.money
	assert_true(await walk_in_to(main.interiors.plan_named("freight_shed"), "walt"))
	await press_e()
	await answer_with("walt_pay")
	await answer_with("bye")
	assert_eq(main.rackets.money, money - FreightJob.DOCKED)
	await wait_physics_frames(3)
	assert_false(_crates_there(), "the corner emptied")
	# 11-12. saved and loaded: the crates still gone
	await _reload()
	assert_eq(main.rackets.freight.stage, FreightJob.Stage.SETTLED)
	assert_false(_crates_there(), "still gone after loading")
	office = main.interiors.plan_named("dispatch_office")
	assert_true(await walk_in_to(office, "leon"))
	await press_e()
	await answer_with("bye")
	assert_eq(main.rackets.money, money - FreightJob.DOCKED + FreightJob.FEE, "Leon's ten dollars")
	assert_true(await walk_in_to(office, "leon"))
	await press_e()
	await answer_with("bye")
	assert_eq(main.rackets.money, money - FreightJob.DOCKED + FreightJob.FEE, "once")
	# 13-14. the Copper Owl after half past one: the Bird's last song
	main.clock.set_time(LastSong.LAST_SONG + 1.0)
	walker().place(Vector2(2290, 380), -PI / 2)
	main.camera.snap_to(walker())
	main.people.callout = {}
	for i in 60:
		await wait_physics_frames(1)
		if main.last_song.scene == "asking":
			break
	assert_eq(main.last_song.scene, "asking", "her last song")
	var bird: Walker = main.bird_show.bird
	for i in 240:
		await wait_physics_frames(1)
		if bird.global_position.distance_to(main.last_song.seat()) < 5.0:
			break
	walker().place(main.last_song.seat() + Vector2(0, 34), -PI / 2)
	await wait_physics_frames(3)
	await press_e()
	for i in 1200:
		await wait_physics_frames(1)
		if main.dialogue.talking == "bird_scene":
			break
	await answer_with("kind")
	await answer_with("bye")
	for i in 120:
		await wait_physics_frames(1)
		if main.films.of("bird") == null:
			break
	assert_eq(main.rackets.bird_scene, "kind")
	assert_eq(main.camera.target, walker())
	# 15. a pull at the Owl in the gaming room
	main.clock.set_time(23 * 60.0)  # the machines close at the hour to go home
	walker().place(RiversideInteriors.SLOTS[0] + Vector2(0, 32), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	await press_e()
	assert_true(main.hud.slot_view.is_open(), "the Owl")
	var before_pull: int = main.rackets.money
	main.back_rooms.pull()
	for i in 400:
		await wait_physics_frames(1)
		if main.hud.slot_view.phase == "paid":
			break
	assert_eq(main.hud.slot_view.phase, "paid", "the reels stop and the line is paid")
	main.back_rooms.leave_slot()
	assert_gte(main.rackets.money - before_pull, -5, "a nickel in, what the window shows out")
	# 16. rain and fog outside, none in the room
	main.weather.force("rain_fog")
	await wait_physics_frames(10)
	assert_eq(main.weather_view.indoors, main.interiors.view_of("gaming_room").host.rect)
	assert_ne((main.weather_view.rain_rect.material as ShaderMaterial).get_shader_parameter("hole"), Vector4.ZERO)
	# sleep; the next night as he left it
	main.weather.force("")
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	assert_eq(main.rackets.night, 2)
	assert_eq(main.rackets.freight.stage, FreightJob.Stage.PAID, "nobody starts the freight over")
	assert_eq(main.rackets.bird_scene, "kind")
	main.world.load_now("yards")
	walker().place(main.interiors.plan_named("freight_shed").outside_door(0, 60.0), 0.0)
	await wait_physics_frames(3)
	assert_false(_crates_there(), "the shed's corner stays empty")
	assert_eq(main.rackets.callouts.pick("leon", {"minute": 20 * 60.0, "near": 50.0}, main.rackets), "leon_hello",
		"Leon has no trouble to call him over for")
