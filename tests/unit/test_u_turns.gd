extends GutTest
## M006 U-turns: at a crawl (28 px/s, about 7 km/h) with the wheel on full
## lock, how wide a strip of road each car sweeps turning round (its corners
## included). Marlowe Avenue is 230 px kerb to kerb, the side streets 170 px.
## At a crawl the cars have a little more lock than at speed (crawl_wheel_angle);
## at a driving pace they steer exactly as in M003.

const DT := 1.0 / 60.0
const AVENUE := 230.0
const STREET := 170.0


## Starts with the car's right side 4 px off the kerb (at y = 0), heading east,
## turns left round to west at a crawl; returns how far north its corners reach.
func _sweep(vt: VehicleType, speed: float) -> float:
	var p := vt.params
	var m := CarModel.new(p)
	var half := vt.size * 0.5
	m.position = Vector2(0, -half.y - 4.0)
	m.velocity = Vector2(speed, 0)
	var reach := 0.0
	for i in 2400:
		m.update(DT, -1.0, false, false)
		m.velocity = m.velocity.normalized() * speed
		m.integrate(DT)
		for c in [Vector2(half.x, half.y), Vector2(half.x, -half.y), Vector2(-half.x, half.y), Vector2(-half.x, -half.y)]:
			reach = maxf(reach, -(m.position + c.rotated(m.heading)).y)
		if absf(angle_difference(m.heading, PI)) < 0.03:
			break
	return reach


func test_both_cars_turn_round_on_marlowe_avenue() -> void:
	for path in ["res://src/driving/vehicles/sedan.tres", "res://src/driving/vehicles/coupe.tres"]:
		var vt: VehicleType = load(path)
		var width := _sweep(vt, 28.0)
		gut.p("%s sweeps %.0f px turning round" % [vt.params.display_name, width])
		assert_lt(width, AVENUE - 40.0, "%s: a U-turn on the avenue, with room for a parked car" % vt.params.display_name)
		assert_gt(width, STREET, "%s: but not in one sweep in a side street (a three-point turn there)" % vt.params.display_name)


func test_at_a_driving_pace_the_steering_is_as_before() -> void:
	for path in ["res://src/driving/vehicles/sedan.tres", "res://src/driving/vehicles/coupe.tres"]:
		var vt: VehicleType = load(path)
		var m := CarModel.new(vt.params)
		assert_eq(m.lock_degrees(60.0), vt.params.max_wheel_angle, "%s at 60 px/s: the M003 lock" % vt.params.display_name)
		assert_eq(m.lock_degrees(200.0), vt.params.max_wheel_angle)
		assert_eq(m.lock_degrees(20.0), vt.params.crawl_wheel_angle, "at a crawl: a little more")
		assert_lt(vt.params.crawl_wheel_angle - vt.params.max_wheel_angle, 5.0, "only a little")
		var prev := m.lock_degrees(0.0)
		for v in range(0, 80, 2):
			assert_lte(m.lock_degrees(v), prev + 0.0001, "easing back smoothly")
			prev = m.lock_degrees(v)
