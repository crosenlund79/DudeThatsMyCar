extends "res://tests/support/city_test.gd"
## M002 driving in the Riverside Ward: cornering at a crossing, nosing into a
## narrow back alley and reversing out, using only the player's W / A / S / D.


func test_cornering_from_marlowe_into_kessler_street() -> void:
	var c := car_of_type("sedan")
	await park(c, Vector2(1050, 545), 0.0)  # eastbound on Marlowe Avenue
	await seat_in(c)
	watch_signals(c)
	var ticks := await drive_route(c, [Vector2(1480, 545), Vector2(1600, 620), Vector2(1650, 820), Vector2(1650, 1200)], 210.0)
	assert_lt(ticks, 900, "made the turn and drove on down Kessler Street")
	assert_signal_not_emitted(c, "wall_hit", "a clean corner at a sensible speed")


func test_nosing_into_the_back_alley_and_through_it() -> void:
	var c := roadster()
	await park(c, Vector2(1650, -120), PI / 2)  # southbound on Kessler Street
	await seat_in(c)
	var ticks := await drive_route(c, [Vector2(1650, 60), Vector2(1585, 135), Vector2(1450, 135), Vector2(1150, 135)], 120.0)
	assert_lt(ticks, 900, "reached the far end of the alley")
	assert_between(c.global_position.y, 102.0 + 12.0, 168.0 - 12.0, "inside the 66 px alley")
	assert_lt(absf(angle_difference(c.model.heading, PI)), 0.25, "lined up with it")


func test_reversing_out_of_the_alley_in_a_straight_line() -> void:
	var c := car_of_type("sedan")
	await park(c, Vector2(1300, 135), PI)  # in the alley, facing west
	await seat_in(c)
	await hold(Vector2(0, 1), 150)
	assert_gt(c.global_position.x, 1300.0 + 120.0, "backed out east")
	assert_lt(c.model.forward_speed(), 0.0)
	assert_gte(c.model.forward_speed(), -c.model.params.reverse_max_speed - 0.01, "reverse stays slow")
	assert_between(c.global_position.y, 102.0 + 12.0, 168.0 - 12.0, "and stayed in the alley")
