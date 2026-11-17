extends GutTest
## The two period cars: both load, look different, handle slightly
## differently, and stay close to the approved HyperCars handling.

const BASELINE := {"max_speed": 420.0, "acceleration": 260.0, "brake_deceleration": 520.0, "turn_rate_degrees": 210.0, "grip": 4.5}

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
	assert_gt(coupe.params.turn_rate_degrees, sedan.params.turn_rate_degrees)


func test_both_stay_close_to_the_hypercars_baseline() -> void:
	for v in [sedan, coupe]:
		for key in BASELINE:
			var value: float = v.params.get(key)
			assert_almost_eq(value / BASELINE[key], 1.0, 0.15, "%s %s stays within 15 %% of HyperCars" % [v.id, key])


func test_city_driving_additions_are_sane() -> void:
	for v in [sedan, coupe]:
		var p: DrivingParams = v.params
		assert_lt(p.reverse_max_speed, p.max_speed * 0.5, "reverse is slow")
		assert_gt(p.brake_deceleration, p.coast_deceleration, "braking beats coasting")
		assert_gt(p.full_steer_speed, 0.0, "no turning on the spot")
		assert_lt(p.handbrake_grip_scale, 1.0, "the handbrake lets the tail slide")
