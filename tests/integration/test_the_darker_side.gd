extends "res://tests/support/city_test.gd"
## M010 the playthrough: a wet first night and a second, with the normal
## controls. Danny runs out of the flat in the rain; borrows Eddie's Thompson
## and takes Rourke's café job; buys the parcel; sits in at the back-room game
## for a few hands and gets up with every cent accounted for; drives... walks
## to Rosie's Café in Halloran Square, slips the parcel under the Packard, sits
## on the bench and lets the night pass until the film; the emergency comes;
## the city map names the café; Rourke pays once; he sleeps; the game is saved
## and loaded; the next night the wreck is still at the kerb, the Thompson
## still on loan, and he gives it back to Eddie.

const SAVE := "user://test_the_darker_side.json"


func after_each() -> void:
	super()
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _key(code: Key) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	main._unhandled_input(e)
	await wait_physics_frames(1)


func _reload() -> void:
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = callouts  # M012: as in before_each
	main.save_path = SAVE
	main.settings_path = ""
	main.opening_enabled = false
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(3)


func test_two_dark_nights() -> void:
	main.save_path = SAVE
	main.weather.force("")
	main.weather.begin_night(1, float(main.night_rules.start_minute))
	assert_eq(main.weather.state_name(), "rain", "the first night is a wet one")
	main.rackets.money = 3000
	# out of the flat at a run
	var home: InteriorPlan = main.interiors.view_of("home").plan
	walker().place(home.inside_door(0, 20.0), PI / 2)
	await wait_physics_frames(2)
	cmd = PlayerCommand.make(Vector2(0, 1))
	cmd.sprint = true
	await wait_physics_frames(30)
	assert_gt(walker().velocity.length(), WalkerModel.new().walk_speed + 20.0, "running")
	cmd = PlayerCommand.new()
	# Eddie: the Thompson on loan
	await talk_to("hardware", "eddie")
	await answer_with("wares")
	await answer_with("heavy")
	await answer_with("borrow")
	await press_e()
	assert_not_null(main.thompson)
	# Rourke: the café job
	await talk_to("copper_owl", "rourke")
	await answer_with("cafe")
	await answer_with("cafe_accept")
	await press_e()
	# Eddie: the parcel
	await talk_to("hardware", "eddie")
	await answer_with("wares")
	await answer_with("parcel")
	await press_e()
	assert_eq(main.rackets.parcels, 1)
	# a few hands in the back room
	var books: int = main.rackets.money + main.back_rooms.poker.players_money()
	var back: InteriorPlan = main.interiors.view_of("back_room").plan
	walker().place(back.spots[0].pos, -PI / 2)
	await wait_physics_frames(3)
	await press_e()
	var pv: PokerView = main.hud.poker_view
	pv.think = Vector2(0.03, 0.05)
	await _key(KEY_1)  # $2
	assert_true(main.back_rooms.poker.seated())
	for f in 4000:
		if main.back_rooms.poker.hands >= 3 and pv.pacing.current.get("kind", "") == "result":
			break  # the third hand's result on show: get up between hands
		if pv.pacing.waiting():
			await _key(KEY_SPACE)  # each card player's move, each street, each result: Space
			var up := InputEventKey.new()
			up.physical_keycode = KEY_SPACE
			up.keycode = KEY_SPACE
			main._unhandled_input(up)
		elif main.back_rooms.poker.table.running() and main.back_rooms.poker.table.to_act == main.back_rooms.poker.danny:
			await _key(KEY_2 if main.back_rooms.poker.table.legal(main.back_rooms.poker.danny).check else KEY_1)
		await wait_process_frames(1)
	await _key(KEY_ESCAPE)
	assert_false(main.back_rooms.poker.seated())
	assert_eq(main.rackets.money + main.back_rooms.poker.players_money(), books, "every cent accounted for at the cards")
	# Rosie's Café
	var h: DistrictLayout = main.world.layouts.halloran
	var car: Vector2 = h.cafe_point("car").pos
	walker().place(car + Vector2(0, -34), PI / 2)
	main.camera.snap_to(walker())
	main.world.load_now("halloran")
	main.clock.set_time(22 * 60.0 + 30.0)
	await wait_physics_frames(4)
	await press_e()
	assert_eq(main.rackets.cafe.stage, CafeJob.Stage.PLANTED)
	var seats: Array = main._seats_near().filter(func(s: Dictionary) -> bool: return (s.pos as Vector2).distance_to(h.cafe_point("bench").pos) < 4.0)
	walker().place(seats[0].stand, PI)
	await wait_physics_frames(2)
	await press_e()
	cmd = PlayerCommand.make(Vector2.ZERO, false, true)
	for i in 600:
		await wait_physics_frames(1)
		if main.cafe_film != null:
			break
	cmd = PlayerCommand.new()
	assert_not_null(main.cafe_film, "the film")
	for i in 60 * 5:
		await wait_physics_frames(1)
	main.cafe_film.skip()
	await wait_physics_frames(60)
	assert_eq(main.rackets.cafe.stage, CafeJob.Stage.DONE)
	var f0 := Engine.get_physics_frames()
	while Engine.get_physics_frames() - f0 < 60 * 30:
		await wait_physics_frames(1)
		if main.emergency.units.all(func(u: Dictionary) -> bool: return u.state == "stopped"):
			break
	assert_true(main.emergency.units.all(func(u: Dictionary) -> bool: return u.state == "stopped"), "the emergency came")
	await press_e()  # up from the bench
	# the city map names the café
	var m := InputEventAction.new()
	m.action = CityInput.MAP
	m.pressed = true
	main._unhandled_input(m)
	assert_true(main.hud.city_map.building_labels.any(func(l: Dictionary) -> bool: return String(l.label).contains("Rosie")))
	main._unhandled_input(m)
	# Rourke pays
	var before: int = main.rackets.money
	await talk_to("copper_owl", "rourke")
	await answer_with("cafe_report")
	await press_e()
	assert_eq(main.rackets.money, before + CafeJob.REWARD)
	# sleep, save, load
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	assert_eq(main.rackets.night, 2)
	main.thompson.ammo = 11
	await _reload()
	assert_eq(main.rackets.night, 2)
	assert_not_null(main.thompson, "still on loan")
	assert_eq(main.thompson.ammo, 11)
	assert_eq(main.rackets.cafe.stage, CafeJob.Stage.REPORTED, "paid, remembered")
	main.clock.set_time(23 * 60.0)
	main._update_clock(0.0)
	assert_true(main.cafe_scene._wreck.visible, "the wreck at the kerb the next night")
	assert_false(main.emergency.active(2), "the emergency has gone")
	# the Thompson goes home
	var back_money: int = main.rackets.money
	await talk_to("hardware", "eddie")
	await answer_with("give_back")
	await press_e()
	assert_null(main.thompson)
	assert_eq(main.rackets.money, back_money + 400)
