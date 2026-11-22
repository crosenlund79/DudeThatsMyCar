extends "res://tests/support/city_test.gd"
## M010 Halloran Park in the game, and sitting down: in through a gate along
## the path (the railing stops you elsewhere); E at a bench sits Danny down -
## he does not move, Space held lets the night pass much faster (the city's
## incidents and the clock keep their order), E stands him up in front of the
## bench; being hit stands him up; the benches in the ward work the same way.


func _go(p: Vector2, rot: float = 0.0) -> void:
	walker().place(p, rot)
	main.camera.snap_to(walker())


func _park() -> DistrictLayout:
	var h: DistrictLayout = main.world.layouts.halloran
	var mid: Vector2 = h.landmarks.filter(func(l: Dictionary) -> bool: return l.label == "Halloran Park")[0].pos
	_go(mid + Vector2(0, -360))
	main.world.load_now("halloran")
	return h


func _park_mid() -> Vector2:
	var h: DistrictLayout = main.world.layouts.halloran
	return h.landmarks.filter(func(l: Dictionary) -> bool: return l.label == "Halloran Park")[0].pos


func test_in_by_the_gate_not_over_the_railing() -> void:
	_park()
	await wait_physics_frames(3)
	var mid := _park_mid()
	# straight down the north-south path through the north gate
	_go(mid + Vector2(0, -330), PI / 2)
	await walk_to(mid + Vector2(0, -60), 6.0, 400)
	assert_lt(walker().global_position.distance_to(mid + Vector2(0, -60)), 8.0, "through the gate")
	# through the railing a little way along: no
	_go(mid + Vector2(-200, -330), PI / 2)
	await walk_to(mid + Vector2(-200, -200), 6.0, 200)
	assert_gt(walker().global_position.distance_to(mid + Vector2(-200, -200)), 60.0, "the railing stops him")


func test_sitting_and_letting_the_night_pass() -> void:
	_park()
	await wait_physics_frames(3)
	var seats: Array = main.districts.seats_near()
	var seat: Dictionary = seats.filter(func(s: Dictionary) -> bool: return (s.pos as Vector2).distance_to(_park_mid()) < 200.0)[0]
	_go(seat.stand)
	await wait_physics_frames(2)
	assert_string_contains(main.hud.prompt_label.text, "Sit down")
	await press_e()
	assert_false(player().seat.is_empty(), "sitting")
	assert_lt(walker().global_position.distance_to(seat.pos), 1.0, "on the bench")
	assert_string_contains(main.hud.prompt_label.text, "Stand up")
	assert_string_contains(main.hud.prompt_label.text, "Let the time pass")
	cmd = PlayerCommand.make(Vector2(1, 0))
	await wait_physics_frames(30)
	assert_lt(walker().global_position.distance_to(seat.pos), 1.0, "WASD does not walk him off the bench")
	# an argument begins down the street while he sits; the night passes fast, in order
	main.incidents.plan = [{"id": "s1", "kind": "argument", "spot": "bakery_kerb", "at": main.clock.minute + 2.0, "tries": 0}]
	var before: float = main.clock.minute
	cmd = PlayerCommand.make(Vector2.ZERO, false, true)  # Space held
	await wait_physics_frames(60 * 3)
	var passed: float = main.clock.minute - before
	assert_gt(passed, 30.0, "the night passes fast (%.0f game minutes in 3 s)" % passed)
	assert_lt(passed, 3.0 * NightCycle.FAST_TIME + 2.0)
	assert_true(main.incidents.history.any(func(x: Dictionary) -> bool: return x.id == "s1"), "the argument began and ended in its order")
	cmd = PlayerCommand.new()
	before = main.clock.minute
	await wait_physics_frames(60)
	assert_almost_eq(main.clock.minute - before, 1.0, 0.2, "Space let go: a minute a second again")
	# up again, in front of the bench, free to go
	await press_e()
	assert_true(player().seat.is_empty())
	assert_lt(walker().global_position.distance_to(seat.stand), 1.0, "standing in front of it")
	cmd = PlayerCommand.make(Vector2(0, 0) + Vector2.from_angle(seat.facing))
	await wait_physics_frames(40)
	assert_gt(walker().global_position.distance_to(seat.stand), 20.0, "and walks off")
	cmd = PlayerCommand.new()


func test_never_past_a_moment_that_must_not_be_missed() -> void:
	var seats: Array = main.districts.seats_near()
	assert_gt(seats.size(), 0, "the ward's benches")
	_go(seats[0].stand)
	await wait_physics_frames(2)
	await press_e()
	assert_false(player().seat.is_empty())
	main.night.moments.assign([main.clock.minute + 10.0])
	cmd = PlayerCommand.make(Vector2.ZERO, false, true)
	await wait_physics_frames(90)  # 1.5 s: fast for the first 8 minutes, then a minute a second
	assert_lt(main.clock.minute, main.night.moments[0], "slowed to normal before it")
	assert_gt(main.clock.minute, main.night.moments[0] - 2.5, "after coming up to it fast")
	main.night.moments.clear()
	cmd = PlayerCommand.new()


func test_hit_while_sitting_stands_him_up() -> void:
	var seats: Array = main.districts.seats_near()
	_go(seats[0].stand)
	await wait_physics_frames(2)
	await press_e()
	assert_false(player().seat.is_empty())
	walker().hit_by_bullet(walker().global_position, Vector2.RIGHT, null)
	await wait_physics_frames(2)
	assert_true(player().seat.is_empty(), "nobody stays sitting when he is hit")
