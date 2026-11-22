extends "res://tests/support/city_test.gd"
## M005 the night as Danny hears it, in the game: the Copper Owl's singer on
## one player that never restarts, muffled through the walls and full inside,
## fading as he walks or drives away; the street, the alleys and the river by
## place and hour; the small sounds of his dealings. (The headless test run has
## no sound card: these tests check levels, filters, routing and continuity,
## not what it sounds like - see the listening checks in the M005 checklist.)


func after_each() -> void:
	super()
	AudioSettings.new("").apply()  # back to the default levels


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func sound() -> Soundscape:
	return main.soundscape


func club() -> InteriorPlan:
	return main.interiors.view_of("copper_owl").plan


## An open spot of street near p (searching outward on a 20 px grid).
func open_near(p: Vector2) -> Vector2:
	for r in range(0, 400, 20):
		for a in 16:
			var q := p + Vector2.from_angle(a * PI / 8.0) * r
			if main.layout.is_open_ground(q, 14.0) and main.layout.interior_at(q) == null:
				return q
	return p


func stand_at(p: Vector2, frames: int = 90) -> void:
	walker().place(p, 0.0)
	main.camera.snap_to(walker())
	await wait_physics_frames(frames)


func test_the_band_plays_on_one_player_that_never_restarts() -> void:
	var music := sound().music
	assert_not_null(music.stream, "the song is there")
	assert_true(music.stream is AudioStreamOggVorbis, "the packaged, cleaned recording")
	assert_almost_eq(music.stream.get_length(), 254.15, 0.05, "the cleaned length")
	assert_true(music.stream.loop, "it loops")
	assert_true(music.playing)
	assert_eq(sound().music_starts, 1)
	# walk up to it, go in, come out, drive away, sleep: still the same performance
	await stand_at(open_near(club().outside_door(0, 400.0)))
	await stand_at(club().outside_door(0, 22.0), 40)
	await press_e()
	await wait_physics_frames(60)
	await press_e()
	await wait_physics_frames(60)
	main.night.sleep()
	await wait_physics_frames(30)
	assert_same(sound().music, music, "one player")
	assert_true(music.playing, "still playing")
	assert_eq(sound().music_starts, 1, "never restarted")


func test_through_the_walls_on_the_way_in_and_full_inside() -> void:
	var far := open_near(club().building_rect.get_center() + Vector2(-1500.0, 260.0))
	await stand_at(far)
	var far_db: float = sound().level.music_db
	await stand_at(open_near(club().outside_door(0, 300.0)))
	var near_db: float = sound().level.music_db
	await stand_at(club().outside_door(0, 22.0))
	var door_db: float = sound().level.music_db
	assert_lt(far_db, near_db, "louder as you come closer (%.1f, %.1f dB)" % [far_db, near_db])
	assert_lt(near_db, door_db, "louder still at the door (%.1f dB)" % door_db)
	assert_lt(door_db, SoundscapeMix.MUSIC_INSIDE_DB - 5.0, "but muffled: you are outside")
	assert_eq(sound().music.bus, Soundscape.BUS_CLUB_MUSIC, "through the walls' filter")
	assert_lt(Soundscape.cutoff_of(Soundscape.BUS_CLUB_MUSIC), 1000.0, "the bass, not the words")
	# in through the door: a smooth swell, not a jump
	var trace: Array[float] = [sound().music.volume_db]
	await press_e()
	assert_eq(main.interiors.current, club(), "inside the Copper Owl")
	for i in 90:
		await wait_physics_frames(1)
		trace.append(sound().music.volume_db)
	for i in range(1, trace.size()):
		assert_lt(absf(trace[i] - trace[i - 1]), 3.0, "no jump stepping in (frame %d)" % i)
	assert_almost_eq(sound().level.music_db, SoundscapeMix.MUSIC_INSIDE_DB, 0.5, "full inside")
	assert_eq(sound().music.bus, "Music", "unfiltered inside")
	assert_almost_eq(sound().level.crowd_db, SoundscapeMix.CROWD_INSIDE_DB, 1.0, "the room's crowd under it")
	# and out again: muffled again, smoothly
	walker().place(club().inside_door(0, 14.0), 0.0)
	await wait_physics_frames(2)
	trace = [sound().music.volume_db]
	await press_e()
	for i in 90:
		await wait_physics_frames(1)
		trace.append(sound().music.volume_db)
	for i in range(1, trace.size()):
		assert_lt(absf(trace[i] - trace[i - 1]), 3.0, "no jump stepping out (frame %d)" % i)
	assert_null(main.interiors.current)
	assert_eq(sound().music.bus, Soundscape.BUS_CLUB_MUSIC)
	assert_lt(Soundscape.cutoff_of(Soundscape.BUS_CLUB_MUSIC), 1000.0, "muffled again")


func test_driving_away_it_sinks_under_the_city() -> void:
	var c := roadster()
	await seat_in(c)
	await park(c, open_near(club().outside_door(0, 120.0)), 0.0)
	await wait_physics_frames(60)
	assert_gt(sound().level.music_db, SoundscapeMix.AUDIBLE_DB, "heard from the car outside the club")
	await park(c, open_near(club().building_rect.get_center() + Vector2(-1300.0, 260.0)), 0.0)
	await wait_physics_frames(120)
	assert_eq(sound().level.music_db, SoundscapeMix.SILENT_DB, "gone a few streets away")
	assert_true(sound().music.playing, "but the band plays on")


func test_the_street_the_alley_and_the_river() -> void:
	var avenue := open_near(club().outside_door(0, 200.0))
	await stand_at(avenue)
	assert_gt(sound().level.street_db, SoundscapeMix.AUDIBLE_DB, "the street's bed on the avenue")
	assert_eq(sound().level.alley_db, SoundscapeMix.SILENT_DB)
	var alley_rect: Rect2 = main.layout.alleys[0].rect
	await stand_at(open_near(alley_rect.get_center()))
	assert_gt(sound().level.alley_db, SoundscapeMix.AUDIBLE_DB, "dripping in the alley")
	var water: Rect2 = main.layout.water[0]
	await stand_at(open_near(Vector2(water.position.x - 60.0, avenue.y)))
	assert_gt(sound().level.river_db, SoundscapeMix.AUDIBLE_DB, "the river at the quay")
	# inside a shop the street comes through the windows, dull
	var grocery: InteriorPlan = main.interiors.view_of("grocery").plan
	await stand_at(grocery.room.get_center(), 180)
	assert_almost_eq(sound().level.street_cutoff, SoundscapeMix.INDOOR_STREET_CUTOFF, 30.0)
	# and the streets are quieter in the small hours
	await stand_at(avenue)
	var evening: float = sound().level.street_db
	main.clock.set_time(4.0 * 60.0 + 24.0 * 60.0)
	await wait_physics_frames(90)
	assert_lt(sound().level.street_db, evening - 3.0, "quieter before dawn")


func test_doors_bells_tills_bottles_and_car_doors() -> void:
	var grocery: InteriorPlan = main.interiors.view_of("grocery").plan
	await stand_at(grocery.outside_door(0, 22.0), 3)
	await press_e()
	assert_has(sound().played, "places/door")
	assert_has(sound().played, "places/shop_bell", "the grocer's bell")
	sound().played.clear()
	await stand_at(club().outside_door(0, 22.0), 3)
	await press_e()
	assert_has(sound().played, "places/door")
	assert_does_not_have(sound().played, "places/shop_bell", "no bell at the club")
	sound().played.clear()
	await talk_to("barber_shop", "sal")
	await answer_with("buy_all")
	assert_has(sound().played, "places/bottles")
	assert_has(sound().played, "places/register", "Sal's till")
	await answer_with("bye")
	sound().played.clear()
	await at_the_streetcar_stop()
	var c := roadster()
	await walk_to(c.global_position, 40.0)
	await press_e()
	assert_true(player().car == c, "in the roadster")
	assert_has(sound().played, "vehicles/door")


func test_narration_lets_the_night_step_back() -> void:
	await stand_at(club().outside_door(0, 22.0))
	var normal: float = sound().music.volume_db
	sound().set_duck(true)
	await wait_physics_frames(90)
	assert_almost_eq(sound().music.volume_db, normal + SoundscapeMix.DUCK_DB, 1.0)
	sound().set_duck(false)
	await wait_physics_frames(90)
	assert_almost_eq(sound().music.volume_db, normal, 1.0)


func test_passing_cars_carry_their_engines() -> void:
	assert_eq(main.street.traffic.size() > 0, true)
	for c in main.street.traffic:
		assert_not_null(c.get_node_or_null("EngineSound"), "an engine on each car of the traffic")


func test_sound_levels_on_the_pause_screen() -> void:
	main._unhandled_input(_key(CityInput.MENU))
	assert_true(main.paused)
	assert_true(main.hud.game_menu.visible, "M012: the game menu")
	while main.hud.game_menu.current() != "sound":  # its Sound page
		main._unhandled_input(_key("ui_down"))
	main._unhandled_input(_key("ui_accept"))
	assert_eq(main.hud.game_menu.page, "sound")
	assert_eq(main.hud.sound_rows.size(), 6, "Master, Music, Engine, Effects, Voice, Ambience")
	var music: float = main.settings.volume["Music"]
	main._unhandled_input(_key("ui_down"))
	assert_eq(AudioSettings.BUSES[main.sound_row], "Music")
	main._unhandled_input(_key("ui_left"))
	assert_almost_eq(main.settings.volume["Music"], music - 0.1, 0.001, "quieter")
	assert_almost_eq(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), linear_to_db(music - 0.1), 0.01,
		"heard at once")
	main._unhandled_input(_key("ui_up"))
	main._unhandled_input(_key("ui_up"))
	assert_eq(AudioSettings.BUSES[main.sound_row], "Ambience", "round to the bottom")
	var amb: float = main.settings.volume["Ambience"]
	main._unhandled_input(_key("ui_right"))
	assert_almost_eq(main.settings.volume["Ambience"], minf(amb + 0.1, 1.0), 0.001, "louder")
	assert_eq(main.hud.sound_rows[5][2].text, "%d%%" % int(round(main.settings.volume["Ambience"] * 100.0)))
	main._unhandled_input(_key(CityInput.MENU))
	assert_true(main.paused, "Esc: back to the menu's list")
	main._unhandled_input(_key(CityInput.MENU))
	assert_false(main.paused, "Esc again: back to the street")
