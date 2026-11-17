extends GutTest
## M003 the late-night driver: round a block on its lane, slowing for the
## corners, stopping short of anything in its path (not for things in the
## other lane) and waiting at a busy crossing.

const DT := 1.0 / 60.0
const LOOP := [Vector2(0, 0), Vector2(800, 0), Vector2(800, 600), Vector2(0, 600)]

var sedan: DrivingParams


func before_all() -> void:
	sedan = (load("res://src/driving/vehicles/sedan.tres") as VehicleType).params


func _drive(d: TrafficDriver, m: CarModel, ticks: int, obstacles: Array = [], busy := false) -> Dictionary:
	var worst := 0.0
	var top := 0.0
	for i in ticks:
		var cmd := d.decide(m.position, m.heading, m.forward_speed(), obstacles, busy)
		m.update(DT, cmd.steer, cmd.throttle, cmd.brake)
		m.integrate(DT)
		top = maxf(top, m.forward_speed())
		var off := INF
		for k in LOOP.size():
			off = minf(off, m.position.distance_to(Geometry2D.get_closest_point_to_segment(m.position, LOOP[k], LOOP[(k + 1) % LOOP.size()])))
		worst = maxf(worst, off)
	return {"worst": worst, "top": top}


func test_goes_round_the_block_on_its_lane() -> void:
	var d := TrafficDriver.new(PackedVector2Array(LOOP), 0)
	var m := CarModel.new(sedan)
	m.position = Vector2(100, 0)
	var r := _drive(d, m, 60 * 30)
	assert_lt(r.worst, 40.0, "never far off the lane (cutting corners a little)")
	assert_lte(r.top, TrafficDriver.CRUISE + 15.0, "at a sensible town speed")
	assert_gt(r.top, 120.0)
	assert_ne(d.next, 1, "it has gone round the corners")


func test_slows_down_for_corners() -> void:
	var d := TrafficDriver.new(PackedVector2Array(LOOP), 0)
	assert_eq(d.corner_speed(Vector2(200, 0)), TrafficDriver.CRUISE)
	assert_lt(d.corner_speed(Vector2(780, 0)), TrafficDriver.CRUISE * 0.6)


func test_stops_short_of_something_in_its_path() -> void:
	var d := TrafficDriver.new(PackedVector2Array(LOOP), 0)
	var m := CarModel.new(sedan)
	m.position = Vector2(50, 0)
	m.velocity = Vector2(140, 0)
	var person := {"pos": Vector2(330, 0), "radius": 12.0}
	_drive(d, m, 60 * 6, [person])
	assert_lt(m.forward_speed(), 2.0, "stopped")
	assert_lt(m.position.x, 330.0 - 12.0 - 38.0, "before reaching them")
	assert_true(d.waiting)
	assert_eq(TrafficDriver.clear_speed(Vector2(50, 0), 0.0, 140.0, [{"pos": Vector2(250, 60), "radius": 12.0}]), INF,
		"someone on the sidewalk beside the lane is no reason to stop")


func test_waits_at_a_busy_crossing() -> void:
	var d := TrafficDriver.new(PackedVector2Array(LOOP), 0)
	var m := CarModel.new(sedan)
	m.position = Vector2(100, 0)
	m.velocity = Vector2(140, 0)
	_drive(d, m, 60 * 4, [], true)
	assert_lt(m.forward_speed(), 2.0)
	assert_true(d.waiting)
