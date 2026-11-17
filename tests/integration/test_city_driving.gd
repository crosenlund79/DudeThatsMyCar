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


## Records how hard the car hits anything solid while `body` runs.
var _hardest := 0.0


func _on_wall_hit(_normal: Vector2, impact: float) -> void:
	_hardest = maxf(_hardest, impact)


func test_a_night_loop_through_crossings_and_the_back_alley() -> void:
	# M003: east on Marlowe, right into Kessler, right into the south back alley
	# (weaving past the ash cans), out onto Dorsey, right, and back east on
	# Marlowe: four crossings and a 66 px alley, all with W / A / S / D.
	var c := car_of_type("sedan")
	await park(c, Vector2(1050, 545), 0.0)
	await seat_in(c)
	_hardest = 0.0
	c.wall_hit.connect(_on_wall_hit)
	var route := [Vector2(1500, 545), Vector2(1625, 640), Vector2(1650, 900), Vector2(1630, 1030), Vector2(1520, 1060),
		Vector2(1300, 1056), Vector2(900, 1062), Vector2(520, 1074), Vector2(160, 1070), Vector2(20, 990),
		Vector2(0, 760), Vector2(60, 640), Vector2(300, 655), Vector2(700, 655)]
	var ticks := await drive_route(c, route, 170.0, 60 * 45)
	assert_lt(ticks, 60 * 45, "came round the loop (%d ticks)" % ticks)
	assert_lt(_hardest, 60.0, "no hard knocks on the way (hardest %.0f px/s)" % _hardest)
	assert_lt(absf(angle_difference(c.model.heading, 0.0)), 0.4, "heading east on Marlowe again")


func test_scraping_along_a_wall_keeps_the_car_going() -> void:
	# drifting a few degrees into the Hotel Marlowe frontage at a fair speed
	var c := car_of_type("sedan")
	var front_y := 761.0  # the hotel's north wall
	await park(c, Vector2(2300, front_y - 26.0), deg_to_rad(10.0))
	c.model.velocity = Vector2.from_angle(deg_to_rad(10.0)) * 220.0
	await seat_in(c)
	_hardest = 0.0
	c.wall_hit.connect(_on_wall_hit)
	await hold(Vector2(0, -1), 50)
	assert_gt(_hardest, 0.0, "it touched the wall")
	assert_gt(c.model.forward_speed(), 150.0, "and kept most of its speed")
	assert_lt(c.global_position.y, front_y, "never through it")
	assert_lt(absf(angle_difference(c.model.heading, 0.0)), deg_to_rad(5.0), "nose turned along the wall")
