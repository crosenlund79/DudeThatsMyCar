extends GutTest
## M003 a passer-by's decisions: strolling a sidewalk route and back, getting
## out of the way of a car coming at them (and not of one going elsewhere),
## running from gunfire nearby, then walking back to the route.

const DT := 1.0 / 60.0
const ROUTE := [Vector2(0, 0), Vector2(400, 0)]


func _brain() -> PedestrianBrain:
	return PedestrianBrain.new(PackedVector2Array(ROUTE), 7)


## Moves `me` by the brain's wish for n ticks (no physics); returns the end point.
func _run(b: PedestrianBrain, me: Vector2, ticks: int, cars: Array = []) -> Vector2:
	for i in ticks:
		var out := b.update(DT, me, cars)
		me += (out.dir as Vector2) * float(out.speed) * DT
	return me


func test_strolls_the_route_and_back() -> void:
	var b := _brain()
	var me := Vector2(10, 0)
	var furthest := 0.0
	for i in 60 * 15:
		var out := b.update(DT, me, [])
		me += (out.dir as Vector2) * float(out.speed) * DT
		furthest = maxf(furthest, me.x)
		assert_lt(absf(me.y), 1.0, "stays on the sidewalk line")
	assert_gt(furthest, 380.0, "walked to the end")
	assert_lt(me.x, 380.0, "and turned back")
	assert_lt(PedestrianBrain.STROLL, 60.0, "at a stroll")


func test_steps_out_of_the_way_of_a_car_coming_at_them() -> void:
	var b := _brain()
	var me := Vector2(200, 0)
	var car := {"pos": Vector2(200, -150), "vel": Vector2(0, 200)}  # coming straight at them
	var out := b.update(DT, me, [car])
	assert_eq(b.state, PedestrianBrain.State.DODGE)
	assert_eq(out.speed, PedestrianBrain.RUN)
	var end := _run(b, me, 40, [car])
	assert_gt(absf(end.x - 200.0), 30.0, "jumped clear of the car's line")
	_run(b, end, 90)
	assert_true(b.state in [PedestrianBrain.State.RETURN, PedestrianBrain.State.WALK], "watched it pass, then back to the walk")


func test_ignores_cars_that_are_parked_or_going_elsewhere() -> void:
	var b := _brain()
	var me := Vector2(200, 0)
	b.update(DT, me, [{"pos": Vector2(200, -60), "vel": Vector2.ZERO}])
	assert_eq(b.state, PedestrianBrain.State.WALK, "parked")
	b.update(DT, me, [{"pos": Vector2(200, -150), "vel": Vector2(0, -200)}])
	assert_eq(b.state, PedestrianBrain.State.WALK, "driving away")
	b.update(DT, me, [{"pos": Vector2(0, -150), "vel": Vector2(200, 0)}])
	assert_eq(b.state, PedestrianBrain.State.WALK, "passing well clear in the street")


func test_runs_from_gunfire_and_comes_back() -> void:
	var b := _brain()
	var me := Vector2(200, 0)
	assert_false(b.hear_gunshot(me, Vector2(200, 2000)), "too far to care")
	assert_true(b.hear_gunshot(me, Vector2(100, 0)))
	assert_eq(b.state, PedestrianBrain.State.FLEE)
	var end := _run(b, me, 60)
	assert_gt(end.x, 300.0, "ran away from the shot")
	end = _run(b, end, 60 * 10)
	assert_lt(absf(end.y), 8.0, "back on the route")
	assert_eq(b.state != PedestrianBrain.State.FLEE, true)
