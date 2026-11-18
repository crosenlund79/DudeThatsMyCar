extends "res://tests/support/city_test.gd"
## M006 a U-turn on Marlowe Avenue with the normal controls: from the
## eastbound lane, wheel on full lock to the left and the car kept at a crawl
## with a touch on the pedal, both cars come round to face west without touching a wall, a kerb
## object or a parked car, and stay on the avenue.

const AVENUE_TOP := 485.0
const AVENUE_BOTTOM := 715.0


func _u_turn(c: Car) -> Dictionary:
	await seat_in(c)
	# an open stretch of the avenue west of the hotel, eastbound lane by the south kerb
	await park(c, Vector2(1450, AVENUE_BOTTOM - c.vehicle.size.y * 0.5 - 6.0), 0.0)
	var hits := [0]
	c.wall_hit.connect(func(_a = null, _b = null, _c = null) -> void: hits[0] += 1)
	c.car_hit.connect(func(_a = null, _b = null, _c = null) -> void: hits[0] += 1)
	var top := INF
	for i in 1500:
		var speed := c.model.forward_speed()
		cmd = PlayerCommand.make(Vector2(-1.0, -1.0 if speed < 26.0 else 0.0))
		await wait_physics_frames(1)
		var half := c.vehicle.size * 0.5
		for k in [Vector2(half.x, half.y), Vector2(half.x, -half.y), Vector2(-half.x, half.y), Vector2(-half.x, -half.y)]:
			top = minf(top, (c.global_position + k.rotated(c.rotation)).y)
		if absf(angle_difference(c.model.heading, PI)) < 0.05:
			break
	cmd = PlayerCommand.new()
	return {"heading": c.model.heading, "top": top, "hits": hits[0]}


func test_the_sedan_turns_round_on_the_avenue() -> void:
	var out := await _u_turn(car_of_type("sedan"))
	assert_lt(absf(angle_difference(out.heading, PI)), 0.06, "facing west")
	assert_gt(out.top, AVENUE_TOP, "without leaving the avenue (reached y %.0f)" % out.top)
	assert_eq(out.hits, 0, "touching nothing")


func test_the_roadster_turns_round_on_the_avenue() -> void:
	var out := await _u_turn(roadster())
	assert_lt(absf(angle_difference(out.heading, PI)), 0.06, "facing west")
	assert_gt(out.top, AVENUE_TOP, "without leaving the avenue (reached y %.0f)" % out.top)
	assert_eq(out.hits, 0, "touching nothing")
