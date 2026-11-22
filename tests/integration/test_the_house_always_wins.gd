extends "res://tests/support/city_test.gd"
## M013 the playthrough: two nights with the normal controls. (1-2) Danny
## drives the roadster into Halloran Square, the game is saved at the wheel
## and loaded: he is behind the same wheel, there. (3) He drives back into the
## ward through the rain - falling down, every frame. (4-5) Into the Copper
## Owl: dry under its roof, the street wet outside. (6-12) Through to the
## gaming room near midnight: the regulars about; he steps up to the wheel
## after Leo's call (too late for that round), waits for the next, puts chips
## down while the regulars put theirs; Leo calls it by himself and pays him to
## the cent. (13-14) A pull at each machine; at the Owl a losing pull lights
## the HOLD lamps: two reels held, the third respun, the holds released.
## (15-16) The card table at dime-and-quarter stakes; getting up mid-hand asks
## first - he stays, then goes. (17) The room's bed playing, the regulars in
## their places. (18-19) Saved and loaded in the gaming room: his money, the
## machines' state and his stakes as they were; a fresh round at the wheel.
## (20) Business as usual with Augie, then home to bed; the next night the
## wheel turns again, the machines remember, the roadster is back with its owner.

const SAVE := "user://test_the_house_always_wins.json"


func after_each() -> void:
	super()
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _reload() -> void:
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = false
	main.save_path = SAVE
	main.settings_path = ""
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(3)


func _key(code: Key, pressed: bool = true) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	main._unhandled_input(e)
	await wait_physics_frames(1)


func _street(l: DistrictLayout, street_name: String) -> Rect2:
	for st in l.streets:
		if st.name == street_name:
			return st.rect
	return Rect2()


func _until_wheel(phase: int, fresh := true) -> void:
	if fresh:
		for i in 3000:
			if main.back_rooms.wheel.phase != phase:
				break
			await wait_physics_frames(1)
	for i in 3000:
		if main.back_rooms.wheel.phase == phase:
			return
		await wait_physics_frames(1)


func _until_paid() -> void:
	for f in 600:
		if main.hud.slot_view.phase == "paid":
			return
		await wait_physics_frames(1)


func test_two_nights_of_the_house_always_wins() -> void:
	main.save_path = SAVE
	main.rackets.money = 5000
	# 1-2. the roadster into Halloran Square; saved at the wheel and loaded
	main.world.load_now("halloran")
	var h: DistrictLayout = main.world.layouts.halloran
	var marlowe := _street(h, "Marlowe Avenue")
	var car := roadster()
	var id: String = main.fleet.ids[main.fleet.cars.find(car)]
	await park(car, Vector2(marlowe.end.x - 700.0, marlowe.get_center().y + 30.0), 0.0)  # facing east, for the ward
	await seat_in(car)
	cmd = PlayerCommand.make(Vector2(0, -1))
	await wait_physics_frames(40)
	cmd = PlayerCommand.new()
	await wait_physics_frames(30)
	var at := car.global_position
	await _reload()
	assert_eq(main.world.current, "halloran", "loaded in the square")
	car = player().car
	assert_not_null(car, "behind the wheel")
	assert_eq(main.fleet.ids[main.fleet.cars.find(car)], id, "of the same car")
	assert_lt(car.global_position.distance_to(at), 1.0)
	# 3. back into the ward through the rain
	main.weather.force("rain")
	var falls := 0
	var frames := 0
	var anchor: Vector2 = main.weather_view.anchors[0]
	var ward_marlowe := _street(main.layout, "Marlowe Avenue")
	var y := ward_marlowe.get_center().y + 30.0
	for i in 1500:
		var to := Vector2(STREETCAR_STOP.x - 120.0, y) - car.global_position
		var want := to.angle()
		var steer := clampf(angle_difference(car.global_rotation, want) * 2.0, -1.0, 1.0)
		cmd = PlayerCommand.make(Vector2(steer, -1.0 if car.speed() < 200.0 else 0.0))
		await wait_physics_frames(1)
		var now: Vector2 = main.weather_view.anchors[0]
		frames += 1
		var dy := wrapf(anchor.y - now.y, -50000.0, 50000.0)
		if dy > 0.0:
			falls += 1
		anchor = now
		if to.length() < 80.0:
			break
	cmd = PlayerCommand.make(Vector2(0, 1))
	await wait_physics_frames(80)
	cmd = PlayerCommand.new()
	assert_eq(main.world.current, "riverside", "back in the ward")
	assert_true(main.weather_view.rain_rect.visible, "in the rain")
	assert_eq(falls, frames, "the rain fell down every frame of the drive")
	for i in 20:
		if player().on_foot():
			break
		await press_e()
	assert_true(player().on_foot())
	# 4-5. into the Copper Owl: dry inside, wet outside
	await talk_to("copper_owl", "augie")
	assert_eq(main.weather_view.indoors, main.interiors.view_of("copper_owl").host.rect, "the club's roof keeps the rain off")
	await answer_with("bye")
	# 6-7. through to the gaming room near midnight; the regulars about; watching the wheel
	var busy := 24 * 60.0
	for m in range(23 * 60, 26 * 60):
		var at_rail := 0
		for p in Patrons.ROSTER:
			if main.back_rooms.gaming_room.spot_of(p, float(m)).begins_with("rail_"):
				at_rail += 1
		if at_rail >= 2:
			busy = float(m)
			break
	main.clock.set_time(busy)
	walker().place(RiversideInteriors.ROULETTE_SPOT + Vector2(0, 30), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(5)
	assert_eq(main.interiors.current.id, "gaming_room")
	var tonight: Array = main.back_rooms.gaming_room.present(main.clock.minute)
	assert_gte(tonight.size(), 3, "a lively room")
	# 8. joining after the call: too late for that round
	await _until_wheel(RouletteTable.Phase.DROP)
	walker().place(RiversideInteriors.ROULETTE_SPOT, -PI / 2)
	await wait_physics_frames(3)
	await press_e()
	assert_true(main.hud.roulette_view.is_open())
	main.back_rooms.bet("red", 25)
	assert_true(main.back_rooms.roulette.bets.is_empty(), "no more bets on that one")
	# 9-12. the next round: chips down with the regulars'; Leo calls it; paid to the cent
	await _until_wheel(RouletteTable.Phase.OPEN, false)
	for r in 4:  # a round with regulars at the rail (they come and go between rounds)
		if not main.back_rooms.wheel_patrons.seated().is_empty():
			break
		await _until_wheel(RouletteTable.Phase.OPEN)
	var before: int = main.rackets.money
	main.hud.roulette_view.pick_chip(3)
	main.back_rooms.bet("black", 100)
	main.hud.roulette_view.pick_chip(1)
	main.back_rooms.bet("straight:23", 10)
	assert_eq(main.rackets.money, before - 110)
	var others := 0
	while main.back_rooms.wheel.betting_open():
		others = maxi(others, main.back_rooms.wheel_patrons.total_down())
		await wait_physics_frames(1)
	var n: int = main.back_rooms.wheel.number
	await _until_wheel(RouletteTable.Phase.RESULT, false)
	assert_eq(main.rackets.money, before - 110 + Roulette.returns("black", 100, n) + Roulette.returns("straight:23", 10, n),
		"paid to the cent")
	for r in 5:  # a cautious regular sits a round out now and then: watch on until their chips go down
		if others > 0:
			break
		await _until_wheel(RouletteTable.Phase.BALL)
		while main.back_rooms.wheel.betting_open():
			others = maxi(others, main.back_rooms.wheel_patrons.total_down())
			await wait_physics_frames(1)
	assert_gt(others, 0, "the regulars' chips on the layout too")
	await _key(KEY_ESCAPE)
	# 13-14. each machine once; at the Owl two reels held and the third respun
	for i in 3:
		walker().place(RiversideInteriors.SLOTS[i] + Vector2(0, 32), -PI / 2)
		await wait_physics_frames(3)
		await press_e()
		assert_true(main.hud.slot_view.is_open(), "at the %s" % RiversideInteriors.SLOT_NAMES[i])
		var m: SlotMachine = main.back_rooms.slot_machines[i]
		var pocket: int = main.rackets.money
		await _key(KEY_SPACE)
		await _key(KEY_SPACE, false)
		await _until_paid()
		assert_eq(main.rackets.money, pocket - m.stake + SlotMachine.coins_for(m.rules, m.line()) * m.stake, "paid as the window shows")
		await _key(KEY_ESCAPE)
	walker().place(RiversideInteriors.SLOTS[0] + Vector2(0, 32), -PI / 2)
	await wait_physics_frames(3)
	await press_e()
	var owl: SlotMachine = main.back_rooms.slot_machines[0]
	for s in 200000:
		var r := RandomNumberGenerator.new()
		r.seed = s
		var probe := SlotMachine.new(owl.rules)
		probe.pull(100000, r.randi())
		probe.collect()
		if probe.win == 0 and probe.hold_offered:
			main.back_rooms.slot_rng.seed = s
			break
	await _key(KEY_SPACE)
	await _key(KEY_SPACE, false)
	await _until_paid()
	assert_true(owl.hold_offered, "the HOLD lamps light")
	var kept := [owl.stops[0], owl.stops[1]]
	await _key(KEY_1)
	await _key(KEY_2)
	var pocket2: int = main.rackets.money
	await _key(KEY_SPACE)
	await _key(KEY_SPACE, false)
	assert_true(owl.respin)
	await _until_paid()
	assert_eq([owl.stops[0], owl.stops[1]], kept, "the held reels kept")
	assert_eq(main.rackets.money, pocket2 - owl.stake + SlotMachine.coins_for(owl.rules, owl.line()) * owl.stake)
	assert_eq(owl.held_count(), 0, "the holds released")
	await _key(KEY_S)
	var stake: int = owl.stake
	await _key(KEY_ESCAPE)
	# 15-16. the card table at dime and quarter; getting up mid-hand asks first
	var back: InteriorPlan = main.interiors.view_of("back_room").plan
	walker().place(back.spots[0].pos, -PI / 2)
	await wait_physics_frames(3)
	await press_e()
	var pv: PokerView = main.hud.poker_view
	pv.think = Vector2(0.05, 0.08)
	await _key(KEY_RIGHT)
	assert_eq(main.back_rooms.poker.level, 1)
	var books: int = main.rackets.money + main.back_rooms.poker.players_money()
	await _key(KEY_1)  # $5 at dime and quarter
	assert_eq(main.back_rooms.poker.table.big_blind, 25)
	for f in 3000:
		var t: Holdem = main.back_rooms.poker.table
		if t.running() and t.to_act == main.back_rooms.poker.danny and not pv.pacing.waiting():
			break
		if pv.pacing.waiting():
			await _key(KEY_SPACE)
			await _key(KEY_SPACE, false)
		await wait_process_frames(1)
	await _key(KEY_ESCAPE)
	assert_false(pv.confirm.is_empty(), "asked first")
	await _key(KEY_ESCAPE)
	assert_true(main.back_rooms.poker.seated(), "he stays")
	await _key(KEY_ESCAPE)
	await _key(KEY_ENTER)
	assert_false(main.back_rooms.poker.seated(), "and then goes")
	assert_eq(main.rackets.money + main.back_rooms.poker.players_money(), books, "every cent accounted for")
	# 17. the room's sound and its people
	walker().place(RiversideInteriors.ROULETTE_SPOT + Vector2(0, 30), -PI / 2)
	await wait_physics_frames(60)
	assert_true(main.soundscape.gaming_bed.playing, "the gaming room's bed")
	assert_gte(main.back_rooms.room_life.standing().size() + 1, tonight.size(), "the regulars in their places")
	# 18-19. saved and loaded in the gaming room
	var money: int = main.rackets.money
	await _reload()
	assert_eq(main.rackets.money, money, "his money as it was")
	assert_eq(main.back_rooms.slot_machines[0].stake, stake, "the Owl's stake remembered")
	assert_eq(main.back_rooms.poker.level, 1, "his stakes at the cards remembered")
	assert_true(main.back_rooms.wheel.betting_open(), "a fresh round at the wheel")
	assert_eq(main.interiors.current.id, "gaming_room")
	# 20. business as usual; home to bed; the next night
	await talk_to("copper_owl", "augie")
	assert_eq(main.dialogue.talking, "augie")
	await answer_with("bye")
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	assert_eq(main.rackets.night, 2)
	assert_true(main.back_rooms.wheel.betting_open(), "the wheel turns again tonight")
	assert_eq(main.back_rooms.slot_machines[0].stake, stake, "the machines remember")
	var spec: Dictionary = main.fleet.specs[main.fleet.ids.find(id)]
	assert_lt(main.fleet.cars[main.fleet.ids.find(id)].global_position.distance_to(spec.pos), 1.0, "the roadster back with its owner")
	await _reload()
	assert_eq(main.rackets.night, 2)
