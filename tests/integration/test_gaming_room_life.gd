extends "res://tests/support/city_test.gd"
## M013.6 the gaming room alive: walking in, the regulars are where the
## evening has them (and nobody who is not in tonight); when the schedule moves
## one on he walks there across the room, keeping to the floor; a newcomer
## comes in at the door and a regular going home leaves by it; a regular at a
## machine Danny comes up to steps away; two regulars near each other pass the
## time (a line, an answer); the smoke drifts and the lamps are never quite
## steady; outside the room nothing moves; Danny's money is never touched.


func _room() -> InteriorView:
	return main.interiors.view_of("gaming_room")


func _life() -> GamingRoomLife:
	return main.room_life


func _walk_in(minute: float) -> void:
	main.clock.set_time(minute)
	walker().place(RiversideInteriors.ROULETTE_SPOT + Vector2(0, 26), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)


## The next minute after `from` when `id` goes from one place to another (both in the room).
func _a_move(id: String, from: float) -> float:
	var m := from
	for k in 30:
		var next: float = main.gaming_room.next_change(id, m)
		if next == INF:
			return -1.0
		if main.gaming_room.spot_of(id, next) != "" and main.gaming_room.spot_of(id, next) != main.gaming_room.spot_of(id, next - 0.1) \
				and main.gaming_room.spot_of(id, next - 0.1) != "":
			return next
		m = next + 0.01
	return -1.0


func test_walking_in_everyone_is_where_the_evening_has_them() -> void:
	var money: int = main.rackets.money
	await _walk_in(24 * 60.0)
	var tonight: Array = main.gaming_room.present(main.clock.minute)
	assert_gte(tonight.size(), 3)
	for id in Patrons.ROSTER:
		var w: Walker = _room().people[id]
		assert_eq(w.visible, id in tonight, "%s %s" % [id, "in" if id in tonight else "not in tonight"])
		if id in tonight:
			var spot: String = main.gaming_room.spot_of(id, main.clock.minute)
			assert_lt(w.global_position.distance_to(GamingRoomLife.spot_pos(spot)), 1.0, "%s at %s" % [id, spot])
	await wait_physics_frames(120)
	assert_eq(main.rackets.money, money, "their evening costs Danny nothing")


func test_moving_on_across_the_room() -> void:
	var id := ""
	var when := -1.0
	for who in ["bertie", "edna", "stan", "dolly", "mick"]:
		when = _a_move(who, 21 * 60.0)
		if when > 0.0:
			id = who
			break
	assert_ne(id, "", "(someone moves from one place to another tonight)")
	await _walk_in(when - 0.3)
	var to: String = main.gaming_room.spot_of(id, when + 0.1)
	var w: Walker = _room().people[id]
	var walked := false
	for f in 60 * 30:
		await wait_physics_frames(1)
		if w.move.length() > 0.0:
			walked = true
			assert_true(_room().plan.room.has_point(w.global_position), "on the floor")
		if _life().here.get(id, "") == to:
			break
	assert_true(walked, "%s walks over" % id)
	assert_eq(_life().here.get(id, ""), to, "and arrives at %s" % to)
	assert_lt(w.global_position.distance_to(GamingRoomLife.spot_pos(to)), 1.0)


func test_in_at_the_door_and_home_by_it() -> void:
	var d: Dictionary = main.gaming_room.nights.mick
	await _walk_in(float(d.in) - 0.2)
	var w: Walker = _room().people.mick
	assert_false(w.visible, "not in yet")
	var came := false
	for f in 60 * 4:
		await wait_physics_frames(1)
		if w.visible:
			came = true
			assert_lt(w.global_position.distance_to(GamingRoomLife.spot_pos("door")), 30.0, "in at the door from the card room")
			break
	assert_true(came, "Mick comes in")
	# and at his time, home by the same door
	main.clock.set_time(float(d.out) - 0.05)
	var left := false
	for f in 60 * 40:
		await wait_physics_frames(1)
		if not w.visible:
			left = true
			break
	assert_true(left, "Mick goes home")
	assert_lt(w.global_position.distance_to(GamingRoomLife.spot_pos("door")), 12.0, "by the door")


func test_a_regular_at_a_machine_steps_away_for_danny() -> void:
	var m := -1.0
	for k in range(21 * 60 + 40, 27 * 60):
		if main.gaming_room.spot_of("dolly", float(k)) == "slot_0" and main.gaming_room.spot_of("dolly", float(k) + 3.0) == "slot_0":
			m = float(k) + 0.5
			break
	assert_gt(m, 0.0, "(Dolly at the Owl tonight)")
	await _walk_in(m)
	assert_eq(_life().here.get("dolly", ""), "slot_0", "Dolly at the Owl")
	walker().place(RiversideInteriors.SLOTS[0] + Vector2(30, 70), -PI / 2)
	await wait_physics_frames(2)
	await walk_to(RiversideInteriors.SLOTS[0] + Vector2(0, 50), 4.0, 120)
	for f in 240:
		await wait_physics_frames(1)
		if _life().here.get("dolly", "") == "table1_r":
			break
	assert_ne(_life().goal.get("dolly", ""), "slot_0", "she gives the machine up")
	await walk_to(RiversideInteriors.SLOTS[0] + Vector2(0, 32), 4.0, 200)
	await press_e()
	assert_true(main.hud.slot_view.is_open(), "the Owl is his")
	main.leave_slot()


func test_two_regulars_pass_the_time() -> void:
	await _walk_in(24 * 60.0)
	var said := false
	for k in 40:
		_life()._chat = 0.0
		await wait_physics_frames(2)
		if main.room_lines.speaking() > 0:
			said = true
			break
		main.clock.set_time(24 * 60.0 + k * 7.0)
		await wait_physics_frames(120)
	assert_true(said, "a word between two of them")
	var first: int = main.room_lines.speaking()
	await wait_physics_frames(60 * 3)
	assert_gte(main.room_lines.speaking(), first, "and an answer")


func test_the_air_moves_inside_and_nothing_outside() -> void:
	await _walk_in(24 * 60.0)
	var smoke: Sprite2D = _room().get_node("smoke")
	var p0 := smoke.position
	var e0: float = _room().lights[0].energy
	await wait_physics_frames(90)
	assert_ne(smoke.position, p0, "the smoke drifts")
	assert_ne(_room().lights[0].energy, e0, "the lamp is never quite steady")
	# out in the street: nobody in the gaming room walks
	walker().place(STREETCAR_STOP, 0.0)
	await wait_physics_frames(5)
	var where := {}
	for id in Patrons.ROSTER:
		where[id] = (_room().people[id] as Walker).global_position
	main.clock.set_time(26 * 60.0)
	await wait_physics_frames(120)
	for id in Patrons.ROSTER:
		assert_eq((_room().people[id] as Walker).global_position, where[id], "%s not simulated while Danny is away" % id)


func test_nobody_after_four() -> void:
	await _walk_in(28 * 60.0 - 0.5)
	await wait_physics_frames(60)
	main.clock.set_time(28 * 60.0)
	await wait_physics_frames(60 * 40)
	for id in Patrons.ROSTER:
		assert_false((_room().people[id] as Walker).visible, "%s gone home by four" % id)
