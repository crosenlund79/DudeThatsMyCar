extends GutTest
## M009 the dump truck and the school bus are their own vehicles, not a
## sedan made bigger: heavier (they shove a car aside and are hardly moved),
## slow to pick up speed and slower at the top, heavy steering that builds
## slowly, a much wider turning circle, and long box-shaped bodies.

var sedan: VehicleType = load("res://src/driving/vehicles/sedan.tres")
var truck: VehicleType = load("res://src/driving/vehicles/dump_truck.tres")
var bus: VehicleType = load("res://src/driving/vehicles/school_bus.tres")


## Speed after `seconds` of full throttle from rest (steering straight).
func _speed_after(v: VehicleType, seconds: float) -> float:
	var m := CarModel.new(v.params)
	for i in int(seconds * 60.0):
		m.update(1.0 / 60.0, 0.0, true, false)
		m.integrate(1.0 / 60.0)
	return m.forward_speed()


## The diameter of the circle driven at a crawl with the wheel hard over.
func _crawl_circle(v: VehicleType) -> float:
	var m := CarModel.new(v.params)
	var lo := Vector2(INF, INF)
	var hi := -lo
	for i in 60 * 30:
		var slow := m.forward_speed() < 40.0
		m.update(1.0 / 60.0, 1.0, slow, not slow)
		m.integrate(1.0 / 60.0)
		if i > 60 * 4:
			lo = lo.min(m.position)
			hi = hi.max(m.position)
	return (hi - lo).x


func test_their_own_vehicles() -> void:
	for v in [truck, bus]:
		assert_ne(v.params, sedan.params)
		assert_true(AssetCatalog.SPECS.has(v.paints[0]), "%s has its own art" % v.id)
		assert_ne(v.size, sedan.size)
	assert_eq(truck.params.display_name, "Dump Truck")
	assert_eq(bus.params.display_name, "School Bus")


func test_slow_to_pick_up_speed_and_slower_at_the_top() -> void:
	for v in [truck, bus]:
		assert_lt(_speed_after(v, 3.0), _speed_after(sedan, 3.0) * 0.6, "%s gathers speed slowly" % v.id)
		assert_lt(_speed_after(v, 20.0), _speed_after(sedan, 20.0) * 0.75, "%s tops out lower" % v.id)
		assert_gt(_speed_after(v, 20.0), 150.0, "%s still gets along a street" % v.id)


func test_heavy_steering_and_a_wide_turning_circle() -> void:
	var car := _crawl_circle(sedan)
	for v in [truck, bus]:
		assert_gt(v.params.steer_rise_time, sedan.params.steer_rise_time, "%s: the wheel turns slowly" % v.id)
		assert_lt(v.params.max_wheel_angle, sedan.params.max_wheel_angle)
		var circle := _crawl_circle(v)
		assert_gt(circle, car * 1.5, "%s turns a much wider circle (%.0f px against %.0f)" % [v.id, circle, car])
		assert_lt(circle, 330.0, "%s can still turn round at a crossing" % v.id)
	assert_gt(_crawl_circle(bus), _crawl_circle(truck), "the bus widest of all")


func test_long_box_bodies() -> void:
	for v in [truck, bus]:
		assert_gt(v.collision.x, sedan.collision.x * 1.35, "%s is long" % v.id)
		assert_gte(v.collision_chamfer, 0.0, "%s is a box with cut corners, not a capsule" % v.id)
		assert_lt(v.collision.x, v.size.x + 0.5, "inside its painted body")
		assert_lt(v.collision.y, v.size.y + 0.5)
		assert_gt(v.params.car_half_length, sedan.params.car_half_length)
	assert_lt(sedan.collision_chamfer, 0.0, "the cars keep their capsule")


func test_heavy_against_a_car() -> void:
	# a sedan runs into a standing truck at 100 px/s, head on
	var t := CarModel.new(truck.params)
	var c := CarModel.new(sedan.params)
	c.velocity = Vector2(100, 0)
	CarModel.resolve_car_collision(t, c, Vector2(1, 0))
	assert_lt(t.velocity.length(), 40.0, "the truck is barely nudged")
	assert_lt(c.velocity.x, 0.0, "the sedan bounces back off it")
	assert_lt(t.velocity.length() * 2.5, 100.0 - c.velocity.x, "the sedan takes the brunt")
	# the truck at 100 into a standing sedan: the sedan is shoved on, the truck carries on
	var t2 := CarModel.new(truck.params)
	var c2 := CarModel.new(sedan.params)
	t2.velocity = Vector2(100, 0)
	CarModel.resolve_car_collision(c2, t2, Vector2(1, 0))
	assert_gt(c2.velocity.x, 100.0, "shoved")
	assert_gt(t2.velocity.x, 40.0, "and the truck rolls on")
	# momentum is kept
	assert_almost_eq(t2.velocity.x * truck.params.mass + c2.velocity.x * sedan.params.mass, 100.0 * truck.params.mass, 0.01)


func test_two_cars_as_before() -> void:
	var a := CarModel.new(sedan.params)
	var b := CarModel.new(sedan.params)
	a.velocity = Vector2(-100, 0)
	CarModel.resolve_car_collision(a, b, Vector2(1, 0))
	var e := sedan.params.car_restitution
	assert_almost_eq(a.velocity.x, -100.0 + (1.0 + e) * 100.0 * 0.5, 0.001, "equal masses: half each, as in M001")
	assert_almost_eq(b.velocity.x, -(1.0 + e) * 100.0 * 0.5, 0.001)


func test_lamps_and_wheels_at_the_right_ends() -> void:
	for v in [truck, bus]:
		assert_gt(v.front_axle_x, v.size.x * 0.25, "%s: steering wheels at the front" % v.id)
		assert_lt(v.front_axle_x + v.wheel_size.x * 0.5, v.size.x * 0.5, "%s: inside the nose" % v.id)
		assert_gt(v.wheel_size.x, 14.0, "%s: bigger tyres than a car" % v.id)
		assert_lt(v.engine_pitch, sedan.engine_pitch, "%s: a deeper engine" % v.id)
