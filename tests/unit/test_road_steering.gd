extends GutTest
## M003 road-car steering (CarModel with wheelbase > 0): the front wheels
## turn and the car follows their circle, so it turns in proportion to how
## fast it rolls, pivots round its rear axle, reverses the other way round,
## does not slide in ordinary driving, runs wide when it is too fast for a
## corner, and only slides with the handbrake. Lifting off rolls on.

const DT := 1.0 / 60.0

var sedan: DrivingParams
var roadster: DrivingParams


func before_all() -> void:
	sedan = (load("res://src/driving/vehicles/sedan.tres") as VehicleType).params
	roadster = (load("res://src/driving/vehicles/coupe.tres") as VehicleType).params


## Drives at a held speed with the wheel at `steer` for n ticks.
func _circle(p: DrivingParams, speed: float, steer: float, ticks: int) -> CarModel:
	var m := CarModel.new(p)
	m.velocity = Vector2(speed, 0)
	m.steer_level = steer
	for i in ticks:
		m.update(DT, steer, false, false)
		m.velocity = m.velocity.normalized() * speed
		m.integrate(DT)
	return m


func test_turning_follows_the_front_wheels_circle_at_low_speed() -> void:
	for p in [sedan, roadster]:
		var m := CarModel.new(p)
		for v in [20.0, 60.0, 120.0]:
			var r: float = p.wheelbase / tan(deg_to_rad(m.lock_degrees(v)))  # M006: a little more lock at a crawl
			assert_almost_eq(v / m.road_yaw(v, 1.0), r, 0.5, "%s: the front wheels' circle at %d px/s" % [p.display_name, v])
		assert_almost_eq(m.road_yaw(60.0, 0.5) * 2.0, m.road_yaw(60.0, 1.0), m.road_yaw(60.0, 1.0) * 0.6,
			"half a turn of the wheel turns about half as hard")


func test_no_turning_on_the_spot_and_reversing_turns_the_other_way() -> void:
	var m := CarModel.new(sedan)
	assert_eq(m.road_yaw(0.0, 1.0), 0.0)
	assert_almost_eq(m.road_yaw(-50.0, 1.0), -m.road_yaw(50.0, 1.0), 0.0001)
	m.steer_level = 1.0
	for i in 30:
		m.update(DT, 1.0, false, false)
	assert_eq(m.heading, 0.0, "a car standing still only turns its wheels")
	assert_almost_eq(m.wheel_angle(), deg_to_rad(sedan.crawl_wheel_angle), 0.0001, "and you can see them turned (M006: the crawl lock)")


func test_a_full_lock_circle_has_a_road_cars_diameter() -> void:
	var m := _circle(sedan, 60.0, 1.0, 600)
	var start := Vector2.ZERO
	var far := 0.0
	m = CarModel.new(sedan)
	m.velocity = Vector2(60, 0)
	m.steer_level = 1.0
	for i in 600:
		m.update(DT, 1.0, false, false)
		m.velocity = m.velocity.normalized() * 60.0
		m.integrate(DT)
		far = maxf(far, m.position.distance_to(start))
	assert_almost_eq(far, m.min_circle(60.0) * 2.0, 6.0, "the centre traces the tightest circle")
	assert_between(far / 80.0, 1.6, 2.3, "about twice the car's length across, like a real sedan")


func test_the_car_pivots_round_its_rear_axle() -> void:
	var m := _circle(sedan, 80.0, 1.0, 60)
	var rear_before := m.position - m.forward() * sedan.rear_axle
	var nose_before := m.position + m.forward() * (sedan.car_half_length)
	var heading := m.heading
	m.update(DT, 1.0, false, false)
	m.integrate(DT)
	var rear_move := (m.position - m.forward() * sedan.rear_axle) - rear_before
	var nose_move := (m.position + m.forward() * sedan.car_half_length) - nose_before
	var mid_dir := Vector2.from_angle(heading).orthogonal()
	assert_lt(absf(rear_move.dot(mid_dir)), 0.05, "the rear wheels roll, they do not skate sideways")
	assert_gt(absf(nose_move.dot(mid_dir)), 0.3, "the nose swings into the turn")


func test_ordinary_cornering_does_not_slide() -> void:
	for p in [sedan, roadster]:
		for speed in [60.0, 150.0, 250.0]:
			var m := CarModel.new(p)
			m.velocity = Vector2(speed, 0)
			var worst := 0.0
			for i in 120:
				m.update(DT, 1.0, false, false)
				m.velocity = m.forward() * m.forward_speed() + m.forward().orthogonal() * m.lateral_speed()
				m.integrate(DT)
				worst = maxf(worst, absf(m.slip))
			assert_lt(worst, 2.0, "%s at %d px/s grips (slip %.1f)" % [p.display_name, speed, worst])


func test_too_fast_for_the_corner_runs_wide_instead_of_spinning() -> void:
	var m := CarModel.new(sedan)
	var slow := 120.0 / m.road_yaw(120.0, 1.0)
	var fast := 300.0 / m.road_yaw(300.0, 1.0)
	assert_gt(fast, slow * 2.5, "at 300 px/s the circle is much wider")
	for v in [180.0, 240.0, 330.0]:
		assert_lte(v * m.road_yaw(v, 1.0), sedan.cornering_grip + 0.01, "sideways pull within the tyres' grip at %d" % v)


func test_the_handbrake_brings_the_tail_round_with_a_slide() -> void:
	var m := CarModel.new(roadster)
	m.velocity = Vector2(250, 0)
	var worst := 0.0
	for i in 40:
		m.update(DT, 1.0, false, false, true)
		m.integrate(DT)
		worst = maxf(worst, absf(m.slip))
	assert_gt(worst, 70.0, "the tyres let go (squeal threshold)")
	assert_gt(rad_to_deg(absf(m.heading)), 45.0, "and the car swings round")
	assert_lt(m.forward_speed(), 150.0, "while it slows")


func test_lifting_off_rolls_on_like_a_heavy_car() -> void:
	var m := CarModel.new(sedan)
	m.velocity = Vector2(240, 0)
	var travelled := 0.0
	for i in 60:
		m.update(DT, 0.0, false, false)
		travelled += m.forward_speed() * DT
	assert_gt(m.forward_speed(), 150.0, "a second later it is still rolling")
	assert_gt(travelled, 180.0)


func test_the_steering_wheel_takes_time_both_ways() -> void:
	var m := CarModel.new(sedan)
	m.velocity = Vector2(120, 0)
	var yaws := []
	for i in 30:
		m.update(DT, 1.0, true, false)
		yaws.append(m.road_yaw(m.forward_speed(), m.steer_level))
	assert_lt(yaws[2], yaws[20] * 0.3, "the turn builds up")
	for i in range(1, yaws.size()):
		assert_lt(yaws[i] - yaws[i - 1], 0.35, "no sudden change of direction")
