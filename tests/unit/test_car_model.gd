extends GutTest
## CarModel: the HyperCars momentum / grip model with city controls:
## throttle, brake that turns into reverse, handbrake, steering that needs the
## car to roll (and reverses when rolling backwards), parked cars.

const DT := 1.0 / 60.0


func _params() -> DrivingParams:
	var p := DrivingParams.new()
	p.max_speed = 400.0
	p.acceleration = 200.0
	p.coast_deceleration = 120.0
	p.brake_deceleration = 500.0
	p.reverse_max_speed = 150.0
	p.reverse_acceleration = 220.0
	p.turn_rate_degrees = 180.0
	p.full_steer_speed = 100.0
	p.grip = 4.0
	p.handbrake_deceleration = 300.0
	p.handbrake_grip_scale = 0.25
	p.handbrake_turn_scale = 1.4
	p.parked_friction = 900.0
	p.wall_restitution = 0.5
	p.wall_tangent_retention = 0.8
	return p


func _run(model: CarModel, seconds: float, steer: float, throttle: bool, brake := false, handbrake := false) -> void:
	for i in int(round(seconds / DT)):
		model.update(DT, steer, throttle, brake, handbrake)
		model.integrate(DT)


func test_throttle_accelerates_along_heading() -> void:
	var m := CarModel.new(_params())
	m.heading = PI / 2.0
	m.update(DT, 0.0, true, false)
	assert_almost_eq(m.forward_speed(), 200.0 * DT, 0.001)
	assert_almost_eq(m.velocity.normalized().dot(Vector2.DOWN), 1.0, 0.0001, "moves where the car points")


func test_speed_is_capped_at_max_speed() -> void:
	var m := CarModel.new(_params())
	_run(m, 5.0, 0.0, true)
	assert_almost_eq(m.forward_speed(), 400.0, 0.001)


func test_coasting_slows_gently_and_braking_hard() -> void:
	var coast := CarModel.new(_params())
	var braked := CarModel.new(_params())
	coast.velocity = Vector2(300, 0)
	braked.velocity = Vector2(300, 0)
	coast.update(DT, 0.0, false, false)
	braked.update(DT, 0.0, false, true)
	assert_almost_eq(coast.forward_speed(), 300.0 - 120.0 * DT, 0.001)
	assert_almost_eq(braked.forward_speed(), 300.0 - 500.0 * DT, 0.001)


func test_brake_stops_the_car_then_reverses() -> void:
	var m := CarModel.new(_params())
	m.velocity = Vector2(100, 0)
	_run(m, 0.2, 0.0, false, true)
	assert_almost_eq(m.forward_speed(), 0.0, 0.001, "braked to a stop first (100 px/s at 500 px/s^2)")
	_run(m, 0.5, 0.0, false, true)
	assert_lt(m.forward_speed(), -50.0, "holding S at rest reverses")
	_run(m, 3.0, 0.0, false, true)
	assert_almost_eq(m.forward_speed(), -150.0, 0.001, "reverse is slow")


func test_throttle_while_rolling_back_brakes_first() -> void:
	var m := CarModel.new(_params())
	m.velocity = Vector2(-120, 0)
	m.update(DT, 0.0, true, false)
	assert_almost_eq(m.forward_speed(), -120.0 + 500.0 * DT, 0.001)


func test_both_pedals_brake_either_way() -> void:
	for v in [Vector2(200, 0), Vector2(-100, 0)]:
		var m := CarModel.new(_params())
		m.velocity = v
		_run(m, 1.0, 0.0, true, true)
		assert_almost_eq(m.forward_speed(), 0.0, 0.001)


func test_a_car_at_rest_cannot_turn_on_the_spot() -> void:
	var m := CarModel.new(_params())
	m.update(0.5, 1.0, false, false)
	assert_eq(m.heading, 0.0)


func test_steering_grows_with_speed_up_to_the_full_turn_rate() -> void:
	var slow := CarModel.new(_params())
	var fast := CarModel.new(_params())
	slow.velocity = Vector2(50, 0)
	fast.velocity = Vector2(300, 0)
	slow.update(0.1, 1.0, false, false)
	fast.update(0.1, 1.0, false, false)
	assert_almost_eq(slow.heading, deg_to_rad(180.0) * 0.5 * 0.1, 0.002, "half the turn at half the full-steer speed")
	assert_almost_eq(fast.heading, deg_to_rad(180.0) * 0.1, 0.002)
	assert_gt(fast.heading, 0.0, "right turns clockwise on screen (+Y)")


func test_reversing_steers_the_other_way() -> void:
	var m := CarModel.new(_params())
	m.velocity = Vector2(-150, 0)
	m.update(0.1, 1.0, false, true)
	assert_lt(m.heading, 0.0, "right lock while reversing swings the nose left, like a real car")


func test_no_steer_keeps_heading() -> void:
	var m := CarModel.new(_params())
	m.heading = 1.0
	_run(m, 1.0, 0.0, true)
	assert_almost_eq(m.heading, 1.0, 0.00001)


func test_momentum_makes_the_car_slide_after_turning() -> void:
	var m := CarModel.new(_params())
	m.velocity = Vector2(400, 0)
	m.update(DT, 1.0, true, false)
	assert_gt(absf(m.lateral_speed()), 1.0, "velocity lags the new heading")


func test_grip_decays_sideways_velocity() -> void:
	var m := CarModel.new(_params())
	m.velocity = Vector2(0, 100)  # purely sideways relative to heading 0
	m.update(0.25, 0.0, false, false)
	assert_almost_eq(absf(m.lateral_speed()), 100.0 * exp(-4.0 * 0.25), 0.01)


func test_handbrake_slows_the_car_harder_than_coasting() -> void:
	var coast := CarModel.new(_params())
	var hand := CarModel.new(_params())
	for m in [coast, hand]:
		m.velocity = Vector2(300, 0)
	_run(coast, 0.4, 0.0, false)
	_run(hand, 0.4, 0.0, false, false, true)
	assert_almost_eq(hand.forward_speed(), 300.0 - 300.0 * 0.4, 0.5)
	assert_lt(hand.forward_speed(), coast.forward_speed())


func test_handbrake_lets_the_tail_slide_and_turns_in_harder() -> void:
	var normal := CarModel.new(_params())
	var hand := CarModel.new(_params())
	for m in [normal, hand]:
		m.velocity = Vector2(300, 0)
	_run(normal, 0.3, 1.0, false)
	_run(hand, 0.3, 1.0, false, false, true)
	assert_gt(hand.heading, normal.heading, "turns in harder")
	assert_gt(absf(hand.lateral_speed()), absf(normal.lateral_speed()) * 1.3, "the tail slides")


func test_a_shoved_parked_car_stops() -> void:
	var m := CarModel.new(_params())
	m.velocity = Vector2(90, 60)
	m.update_parked(DT)
	assert_lt(m.velocity.length(), Vector2(90, 60).length())
	for i in 30:
		m.update_parked(DT)
	assert_eq(m.velocity, Vector2.ZERO)


func test_wall_collision_bounces_and_keeps_some_tangent_speed() -> void:
	var m := CarModel.new(_params())
	m.velocity = Vector2(100, -200)  # moving up into a wall whose normal points down
	m.apply_wall_collision(Vector2.DOWN)
	assert_almost_eq(m.velocity.x, 80.0, 0.001)
	assert_almost_eq(m.velocity.y, 100.0, 0.001)


func test_wall_collision_ignores_motion_away_from_wall() -> void:
	var m := CarModel.new(_params())
	m.velocity = Vector2(100, 50)
	m.apply_wall_collision(Vector2.DOWN)
	assert_eq(m.velocity, Vector2(100, 50))


func test_car_contact_is_symmetric_for_equal_cars() -> void:
	var a := CarModel.new(_params())
	var b := CarModel.new(_params())
	a.velocity = Vector2(-200, 0)
	b.velocity = Vector2(100, 0)
	var before := a.velocity + b.velocity
	CarModel.resolve_car_collision(a, b, Vector2(1, 0))
	assert_almost_eq((a.velocity + b.velocity).x, before.x, 0.001, "momentum is kept")
	assert_gt(a.velocity.x, -200.0)
	assert_lt(b.velocity.x, 100.0)


func test_model_is_deterministic() -> void:
	var a := CarModel.new(_params())
	var b := CarModel.new(_params())
	for i in 240:
		var steer := float((i / 30) % 3 - 1)
		var throttle := (i % 50) < 35
		var brake := (i % 70) > 60
		a.update(DT, steer, throttle, brake, i % 90 > 84)
		a.integrate(DT)
		b.update(DT, steer, throttle, brake, i % 90 > 84)
		b.integrate(DT)
	assert_eq(a.position, b.position)
	assert_eq(a.heading, b.heading)


func test_the_hypercars_feel_is_kept_at_speed() -> void:
	# With the throttle held and no brake, the city model reproduces the HyperCars
	# fire-held behaviour exactly: same acceleration, steering and grip slide.
	var p := _params()
	p.full_steer_speed = 0.0
	var m := CarModel.new(p)
	m.velocity = Vector2(300, 0)
	m.update(DT, 1.0, true, false)
	var heading := deg_to_rad(180.0) * DT
	assert_almost_eq(m.heading, heading, 0.00001)
	var fwd := Vector2(300, 0).dot(Vector2.from_angle(heading)) + 200.0 * DT
	assert_almost_eq(m.forward_speed(), fwd, 0.001)
