extends "res://tests/support/city_test.gd"
## M011 the playthrough: two nights with the normal controls. Late in the
## first night Danny walks into the Copper Owl - the band full - and through
## the door in the west wall into the card room: the band muffled through the
## wall, the back rooms' own sound up. He sits in for a few hands (each card
## player's move on show until Space), gets up with every cent accounted for,
## goes through to the gaming room, bets at the wheel (it pays exactly what
## the rules say for the number the ball lands on), pulls the Owl's lever
## (paid what the window shows), saves mid-spin and loads (the decided spin
## counted once); walks down to the union hall by the yards and reads the
## noticeboard; goes up City Hall's steps across from Halloran Park and in
## at the night door (M012: it opens on the hall), where the stairs to the
## Mayor are roped off; finds them all on the city map; sleeps; the next night the wheel and the machines
## are there again and the card players have their purses back.

const SAVE := "user://test_power_and_vice.json"


func after_each() -> void:
	super()
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _key(code: Key, pressed: bool = true) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	main._unhandled_input(e)
	await wait_physics_frames(1)


func _click(view: RouletteView, key: String) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = view._from_layout(RouletteLayout.anchor(key))
	view._gui_input(e)
	await wait_physics_frames(1)


func _reload() -> void:
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.save_path = SAVE
	main.settings_path = ""
	main.opening_enabled = false
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(3)


func test_two_nights_of_power_and_vice() -> void:
	main.save_path = SAVE
	main.weather.force("clear")
	main.rackets.money = 2500
	main.clock.set_time(23 * 60.0)
	# into the Copper Owl, the band full
	var owl: InteriorPlan = main.interiors.view_of("copper_owl").plan
	assert_true(await walk_in_to(owl, "augie"), "into the club by the front door")
	await wait_physics_frames(90)
	assert_gt(main.soundscape.level.music_db, -6.0, "the band full in the club")
	# through to the card room: muffled band, the back rooms' sound
	walker().place(owl.inside_door(2, 10.0), PI)
	await wait_physics_frames(3)
	await press_e()
	assert_eq(main.interiors.current.id, "back_room")
	await wait_physics_frames(150)
	assert_lt(main.soundscape.level.music_db, main.soundscape.level.gaming_db, "the band through the wall, the room's own sound over it")
	# a few hands of Hold'em, a beat at a time
	var back: InteriorPlan = main.interiors.current
	var card_books: int = main.rackets.money + main.poker.players_money()
	walker().place(back.spots[0].pos, -PI / 2)
	await wait_physics_frames(3)
	await press_e()
	var pv: PokerView = main.hud.poker_view
	pv.think = Vector2(0.03, 0.05)
	await _key(KEY_1)  # $2
	var shown := []
	pv.beat_shown.connect(func(b: Dictionary) -> void: shown.append(b))
	for f in 4000:
		if main.poker.hands >= 3 and pv.pacing.current.get("kind", "") == "result":
			break
		if pv.pacing.waiting():
			await _key(KEY_SPACE)
			await _key(KEY_SPACE, false)
		elif main.poker.table.running() and main.poker.table.to_act == main.poker.danny:
			await _key(KEY_2 if main.poker.table.legal(main.poker.danny).check else KEY_1)
		await wait_process_frames(1)
	assert_gt(shown.size(), 5, "the card players' moves shown one at a time")
	await _key(KEY_ESCAPE)
	assert_false(main.poker.seated())
	assert_eq(main.rackets.money + main.poker.players_money(), card_books, "every cent accounted for at the cards")
	var after_cards: int = main.rackets.money
	# through to the gaming room: the wheel
	var west := -1
	for i in back.doors.size():
		var other: InteriorPlan = main.layout.interior_at(back.outside_door(i, 20.0))
		if other != null and other.id == "gaming_room":
			west = i
	walker().place(back.inside_door(west, 10.0), PI)
	await wait_physics_frames(3)
	await press_e()
	assert_eq(main.interiors.current.id, "gaming_room")
	walker().place(RiversideInteriors.ROULETTE_SPOT, -PI / 2)
	await wait_physics_frames(3)
	await press_e()
	var rv: RouletteView = main.hud.roulette_view
	assert_true(rv.is_open())
	await _key(KEY_4)
	await _click(rv, "black")
	await _key(KEY_3)
	await _click(rv, "corner:13-14-16-17")
	await _click(rv, "straight:0")
	assert_eq(main.rackets.money, after_cards - 150)
	await _key(KEY_SPACE)
	var n: int = main.roulette.result
	for f in 900:
		if main.roulette.phase == Roulette.Phase.SETTLED:
			break
		await wait_physics_frames(1)
	assert_eq(rv.spin.pocket_under(rv.spin_t), n, "the ball in the number's pocket")
	var won := Roulette.returns("black", 100, n) + Roulette.returns("corner:13-14-16-17", 25, n) + Roulette.returns("straight:0", 25, n)
	assert_eq(main.rackets.money, after_cards - 150 + won, "paid what the rules say")
	await _key(KEY_ESCAPE)
	# the Owl
	var before_slot: int = main.rackets.money
	walker().place(RiversideInteriors.SLOTS[0] + Vector2(0, 32), -PI / 2)
	await wait_physics_frames(3)
	await press_e()
	assert_true(main.hud.slot_view.is_open())
	await _key(KEY_SPACE)
	await _key(KEY_SPACE, false)
	var owl_m: SlotMachine = main.slot_machines[0]
	for f in 400:
		if main.hud.slot_view.phase == "paid":
			break
		await wait_physics_frames(1)
	assert_eq(main.rackets.money, before_slot - 5 + SlotMachine.coins_for(owl_m.rules, owl_m.line()) * 5, "paid what the window shows")
	await _key(KEY_ESCAPE)
	# a save mid-spin, and the game loaded: the spin counted once
	walker().place(RiversideInteriors.ROULETTE_SPOT, -PI / 2)
	await wait_physics_frames(3)
	await press_e()
	await _key(KEY_4)
	await _click(rv, "red")
	await _key(KEY_SPACE)
	var n2: int = main.roulette.result
	var expect: int = main.rackets.money + Roulette.returns("red", 100, n2)
	await _reload()
	assert_eq(main.rackets.money, expect, "the spin under way counted as settled, once")
	assert_false(main.hud.roulette_view.is_open())
	# the union hall at the yards' doorstep: the noticeboard
	var hall: InteriorPlan = main.interiors.view_of("union_hall").plan
	assert_true(await walk_in_to(hall, "union_board"), "into the union hall from Wharf Street")
	await press_e()
	assert_string_contains(main.hud.line_label.text, "GENERAL MEETING")
	await press_e()
	# City Hall across from the park: in at the night door, to the roped-off stairs (M012)
	var h: DistrictLayout = main.world.layouts.halloran
	var hall_data: InteriorPlan = h.interiors.filter(func(p: InteriorPlan) -> bool: return p.id == "city_hall")[0]
	walker().place(hall_data.outside_door(0, 60.0), PI / 2)
	main.camera.snap_to(walker())
	main.world.load_now("halloran")
	await wait_physics_frames(3)
	assert_true(await walk_in_to(main.interiors.plan_named("city_hall"), "city_stairs"), "up the steps and in")
	await press_e()
	assert_string_contains(main.hud.line_label.text, "OFFICE OF THE MAYOR")
	await press_e()
	# the city map knows them all
	var m := InputEventAction.new()
	m.action = CityInput.MAP
	m.pressed = true
	main._unhandled_input(m)
	var labels: Array = main.hud.city_map.building_labels.map(func(l: Dictionary) -> String: return String(l.label))
	for name in [RiversideWard.UNION_HALL, HalloranSquare.CITY_HALL, HalloranSquare.DORAN, RiversideWard.QUILTY]:
		assert_has(labels, name)
	main._unhandled_input(m)
	# sleep; the next night
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	assert_eq(main.rackets.night, 2)
	assert_eq(main.roulette.phase, Roulette.Phase.BETTING, "a fresh layout")
	assert_true(main.interiors.view_of("gaming_room").person_ok("croupier"), "Leo at the wheel")
	for p in PokerNight.REGULARS:
		assert_gt(int(main.poker.purses.get(p.id, 0)), 0, "%s back with his purse" % p.id)
	walker().place(RiversideInteriors.SLOTS[2] + Vector2(0, 32), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	await press_e()
	assert_true(main.hud.slot_view.is_open(), "the Star waiting")
	await _key(KEY_ESCAPE)
