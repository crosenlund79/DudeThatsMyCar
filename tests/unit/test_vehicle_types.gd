extends GutTest
## The two period cars: both load, look different, handle slightly
## differently, and (M003) drive like heavy 1930s road cars rather than the
## HyperCars racers they came from: lower top speeds, gentler pedals, road-car
## steering with a believable turning circle.

var sedan: VehicleType
var coupe: VehicleType


func before_all() -> void:
	sedan = load("res://src/driving/vehicles/sedan.tres")
	coupe = load("res://src/driving/vehicles/coupe.tres")


func test_both_cars_load_with_their_own_look() -> void:
	for v in [sedan, coupe]:
		assert_not_null(v.params)
		assert_gt(v.paints.size(), 0)
		for paint in v.paints:
			assert_true(AssetCatalog.SPECS.has(paint), paint)
		assert_eq(v.size, AssetCatalog.display_size(v.paints[0]))
		assert_lt(v.collision.x, v.size.x, "collision a little inside the body")
	assert_ne(sedan.paints[0], coupe.paints[0])


func test_handling_differs_slightly() -> void:
	assert_gt(coupe.params.max_speed, sedan.params.max_speed, "the roadster is quicker")
	assert_gt(coupe.params.acceleration, sedan.params.acceleration)
	assert_lt(coupe.params.grip, sedan.params.grip, "and slides more")
	assert_lt(CarModel.new(coupe.params).min_circle(), CarModel.new(sedan.params).min_circle(), "and turns tighter")
	assert_gt(coupe.params.cornering_grip, sedan.params.cornering_grip)


func test_both_are_city_cars_not_racers() -> void:
	for v in [sedan, coupe]:
		var p: DrivingParams = v.params
		assert_gt(p.wheelbase, 0.0, "%s steers like a road car" % v.id)
		assert_between(p.max_speed, 280.0, 400.0, "%s: a city top speed (about 45-60 mph)" % v.id)
		assert_lt(p.acceleration, 220.0, "%s gathers speed like a heavy car" % v.id)
		assert_lt(p.brake_deceleration, 400.0, "%s has drum brakes, not racing brakes" % v.id)
		assert_lt(p.coast_deceleration, 100.0, "%s rolls on when you lift off" % v.id)
		var circle := CarModel.new(p).min_circle()
		assert_between(circle, 60.0, 95.0, "%s turns on a road car's circle (about 4-6.5 m)" % v.id)
		assert_gt(p.tyre_grip, p.cornering_grip, "%s does not slide in ordinary cornering" % v.id)


func test_city_driving_additions_are_sane() -> void:
	for v in [sedan, coupe]:
		var p: DrivingParams = v.params
		assert_lt(p.reverse_max_speed, p.max_speed * 0.5, "reverse is slow")
		assert_gt(p.brake_deceleration, p.coast_deceleration, "braking beats coasting")
		assert_eq(CarModel.new(p).road_yaw(0.0, 1.0), 0.0, "no turning on the spot")
		assert_lt(p.handbrake_grip_scale, 1.0, "the handbrake lets the tail slide")
