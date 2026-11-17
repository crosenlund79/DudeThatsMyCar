extends GutTest
## M002 driving: weight (the engine builds up, pull fades towards top speed),
## a steering wheel that turns in rather than snapping, a fixed tightest
## turning circle for low-speed precision, steadier steering at speed, and
## wall contact that lets shallow hits scrape along. M003: the brakes bite
## over a fraction of a second and the nose turns along a wall gradually; the
## two cars steer like road cars (test_road_steering.gd), so the turn-rate
## steering of M002 is checked here on copies with wheelbase 0.
## With the default (M001) settings the model behaves exactly as before.

const DT := 1.0 / 60.0

var sedan: DrivingParams
var roadster: DrivingParams


func before_all() -> void:
	sedan = (load("res://src/driving/vehicles/sedan.tres") as VehicleType).params
	roadster = (load("res://src/driving/vehicles/coupe.tres") as VehicleType).params


func _time_to(p: DrivingParams, speed: float) -> float:
	var m := CarModel.new(p)
	var t := 0.0
	while m.forward_speed() < speed and t < 20.0:
		m.update(DT, 0.0, true, false)
		t += DT
	return t


## The same car with M002's turn-rate steering.
func _turn_rate(p: DrivingParams) -> DrivingParams:
	var old := p.duplicate() as DrivingParams
	old.wheelbase = 0.0
	return old


func _m001(p: DrivingParams) -> DrivingParams:
	var old := p.duplicate() as DrivingParams
	old.throttle_rise_time = 0.0
	old.throttle_fall_time = 0.0
	old.accel_falloff = 0.0
	old.steer_rise_time = 0.0
	old.steer_return_time = 0.0
	old.min_turn_radius = 0.0
	old.high_speed_turn_scale = 1.0
	old.wall_friction = -1.0
	old.wall_align = 0.0
	return old


func test_default_settings_reproduce_m001_exactly() -> void:
	var p := DrivingParams.new()
	var m := CarModel.new(p)
	m.update(DT, 1.0, true, false)
	assert_almost_eq(m.forward_speed(), p.acceleration * DT, 0.0001, "full pull on the first tick")
	assert_eq(m.steer_level, 1.0, "the wheel snaps")
	m.velocity = Vector2(300, 0)
	m.heading = 0.0
	assert_almost_eq(m.apply_wall_collision(Vector2(-1, 0).rotated(0.3)), p.wall_tangent_retention, 0.0001)


func test_the_engine_builds_up_instead_of_jumping() -> void:
	var m := CarModel.new(sedan)
	m.update(DT, 0.0, true, false)
	assert_lt(m.forward_speed(), sedan.acceleration * DT * 0.1, "barely moving after one tick")
	for i in int(sedan.throttle_rise_time / DT) + 1:
		m.update(DT, 0.0, true, false)
	assert_almost_eq(m.drive_level, 1.0, 0.001, "full pull after the rise time")


func test_both_cars_feel_heavier_than_m001_and_the_sedan_heaviest() -> void:
	var s := _time_to(sedan, 300.0)
	var r := _time_to(roadster, 300.0)
	assert_gt(s, _time_to(_m001(sedan), 300.0) * 1.25, "the sedan gathers speed noticeably more slowly")
	assert_gt(r, _time_to(_m001(roadster), 300.0) * 1.15)
	assert_gt(s, r, "the roadster is the quicker car")
	assert_lt(s, 3.0, "but it is not sluggish")


func test_pull_fades_towards_top_speed_but_top_speed_is_reached() -> void:
	var m := CarModel.new(sedan)
	assert_gt(m.pull_at(sedan.max_speed * 0.2, sedan.acceleration, sedan.max_speed),
		m.pull_at(sedan.max_speed * 0.8, sedan.acceleration, sedan.max_speed) * 1.3)
	assert_lt(_time_to(sedan, sedan.max_speed * 0.99), 12.0)


func test_the_brakes_bite_quickly_but_not_in_one_jolt() -> void:
	var m := CarModel.new(sedan)
	m.velocity = Vector2(300, 0)
	m.update(DT, 0.0, false, true)
	assert_lt(300.0 - m.forward_speed(), sedan.brake_deceleration * DT * 0.2, "a gentle first touch")
	for i in int(sedan.brake_rise_time / DT) + 1:
		m.update(DT, 0.0, false, true)
	var v := m.forward_speed()
	m.update(DT, 0.0, false, true)
	assert_almost_eq(v - m.forward_speed(), sedan.brake_deceleration * DT, 0.001, "full braking after the rise time")
	assert_lt(sedan.brake_rise_time, 0.3, "still a quick pedal")


func test_steering_builds_up_and_settles() -> void:
	var m := CarModel.new(sedan)
	m.update(DT, 1.0, false, false)
	assert_lt(m.steer_level, 0.12, "the wheel starts turning, it does not snap")
	for i in int(sedan.steer_rise_time / DT) + 1:
		m.update(DT, 1.0, false, false)
	assert_eq(m.steer_level, 1.0, "full lock after the rise time")
	for i in int(sedan.steer_return_time / DT) + 1:
		m.update(DT, 0.0, false, false)
	assert_eq(m.steer_level, 0.0, "and back to straight, faster")


func test_counter_steering_swings_across_quickly() -> void:
	var m := CarModel.new(roadster)
	m.steer_level = 1.0
	var ticks := 0
	while m.steer_level > -1.0 and ticks < 120:
		m.update(DT, -1.0, false, false)
		ticks += 1
	assert_lt(ticks * DT, roadster.steer_return_time + roadster.steer_rise_time + 0.05,
		"straighten at the return rate, then turn in")


func test_at_a_crawl_the_car_follows_its_tightest_circle() -> void:
	for p in [_turn_rate(sedan), _turn_rate(roadster)]:
		var m := CarModel.new(p)
		for v in [30.0, 60.0, 120.0]:
			var yaw := deg_to_rad(p.turn_rate_degrees) * m.steer_factor(v)
			assert_almost_eq(v / yaw, p.min_turn_radius, 0.5, "same circle at %d px/s" % v)
	assert_lt(roadster.min_turn_radius, sedan.min_turn_radius, "the roadster turns tighter")


func test_reversing_follows_the_same_circle_the_other_way() -> void:
	var m := CarModel.new(_turn_rate(sedan))
	assert_almost_eq(m.steer_factor(-60.0), -m.steer_factor(60.0), 0.0001)
	assert_eq(m.steer_factor(0.0), 0.0, "no turning on the spot")


func test_a_real_low_speed_turn_traces_a_tight_circle() -> void:
	var m := CarModel.new(_turn_rate(sedan))
	m.velocity = Vector2(60, 0)
	m.steer_level = 1.0
	var start := m.position
	var far := 0.0
	for i in 600:
		m.update(DT, 1.0, false, false)
		m.velocity = m.forward() * 60.0  # hold a crawl
		m.integrate(DT)
		far = maxf(far, m.position.distance_to(start))
	assert_almost_eq(far, sedan.min_turn_radius * 2.0, 10.0, "the circle's diameter is twice the tightest radius")


func test_steering_is_steadier_at_speed() -> void:
	var m := CarModel.new(_turn_rate(sedan))
	assert_almost_eq(m.steer_factor(sedan.max_speed), sedan.high_speed_turn_scale, 0.0001)
	assert_gt(m.steer_factor(sedan.max_speed * 0.6), m.steer_factor(sedan.max_speed))


func test_a_shallow_wall_hit_keeps_its_speed_and_turns_along_the_wall() -> void:
	var m := CarModel.new(sedan)
	m.heading = 0.0
	m.velocity = Vector2(300, 0)
	var wall := Vector2(-sin(deg_to_rad(15.0)), -cos(deg_to_rad(15.0)))  # wall 15 degrees off the travel
	var keep := m.apply_wall_collision(wall)
	assert_gt(keep, 0.75)
	assert_gt(m.velocity.length(), 300.0 * 0.75, "momentum kept")
	assert_gte(m.velocity.dot(wall), 0.0, "never into the wall")
	var along := wall.orthogonal()
	if along.x < 0.0:
		along = -along  # the way the car was going
	var turned := deg_to_rad(15.0) - absf(angle_difference(m.heading, along.angle()))
	assert_gt(turned, 0.0, "the nose swings towards the wall's line")
	assert_almost_eq(turned, sedan.wall_align_rate * DT, 0.0001, "but only a little per tick of contact, no snap")
	var glance := 1.0 - 15.0 / sedan.wall_glance_angle
	assert_lt(turned, deg_to_rad(15.0) * sedan.wall_align * glance, "rate-limited")


func test_a_head_on_hit_stops_the_car_and_bounces_it_back() -> void:
	var m := CarModel.new(sedan)
	m.velocity = Vector2(300, 0)
	m.apply_wall_collision(Vector2(-1, 0))
	assert_almost_eq(m.velocity.x, -300.0 * sedan.wall_restitution, 0.01)
	assert_eq(m.heading, 0.0, "no turn on a head-on hit")


func test_steeper_hits_lose_more() -> void:
	var keeps := []
	for deg in [10.0, 25.0, 40.0, 60.0]:
		var m := CarModel.new(sedan)
		m.velocity = Vector2(300, 0)
		keeps.append(m.apply_wall_collision(Vector2(-sin(deg_to_rad(deg)), -cos(deg_to_rad(deg)))))
	for i in range(1, keeps.size()):
		assert_lt(keeps[i], keeps[i - 1])
