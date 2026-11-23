extends GutTest
## M015 a passer-by and the cars (PedestrianBrain, pure): a fast car is seen
## coming sooner than a slow one; it takes a moment to react; they get out of
## its line sideways (towards the kerb when it comes straight at them) and
## throw themselves clear at the last moment; a car that turns after them is
## a chase - they cut back behind its turn and then run for it; a wall in the
## way sends them the other way. Against the real Sedan and Roadster driven
## straight at them (CarModel), a determined chase seldom ends with somebody
## run down - but a sudden swerve at the last moment still can.

const DT := 1.0 / 60.0
const ROUTE := [Vector2(-2000, 0), Vector2(2000, 0)]
const SEDAN := preload("res://src/driving/vehicles/sedan.tres")
const COUPE := preload("res://src/driving/vehicles/coupe.tres")


func _brain() -> PedestrianBrain:
	return PedestrianBrain.new(PackedVector2Array(ROUTE), 3)


## Moves `me` by the brain's wish for n ticks against cars that do not move.
func _run(b: PedestrianBrain, me: Vector2, ticks: int, cars: Array = []) -> Vector2:
	for i in ticks:
		var out := b.update(DT, me, cars)
		me += (out.dir as Vector2) * float(out.speed) * DT
	return me


func test_a_faster_car_is_seen_coming_sooner() -> void:
	assert_gt(PedestrianBrain.look_ahead(320.0), PedestrianBrain.look_ahead(100.0))
	assert_lte(PedestrianBrain.look_ahead(2000.0), PedestrianBrain.LOOK_MAX)
	var me := Vector2.ZERO
	var slow := {"pos": Vector2(-600, 0), "vel": Vector2(120, 0)}
	var fast := {"pos": Vector2(-600, 0), "vel": Vector2(330, 0)}
	assert_true(PedestrianBrain.danger(me, [slow]).is_empty(), "a slow car 600 px off is no worry yet (five seconds away)")
	assert_false(PedestrianBrain.danger(me, [fast]).is_empty(), "a fast one is")
	assert_gt(PedestrianBrain.near_miss(330.0), PedestrianBrain.near_miss(60.0), "and given a wider berth")


func test_it_takes_a_moment_to_react() -> void:
	var b := _brain()
	var car := {"pos": Vector2(-500, 0), "vel": Vector2(300, 0)}
	b.update(DT, Vector2.ZERO, [car])
	assert_ne(b.state, PedestrianBrain.State.DODGE, "not in the first instant")
	_run(b, Vector2.ZERO, int(PedestrianBrain.REACT / DT) + 1, [car])
	assert_eq(b.state, PedestrianBrain.State.DODGE, "then they move")


func test_they_get_out_of_its_line_sideways_not_ahead_of_it() -> void:
	var b := _brain()
	var me := Vector2(0, 30)  # a little to one side of its line
	var car := {"pos": Vector2(-500, 0), "vel": Vector2(300, 0)}
	var end := _run(b, me, 30, [car])
	assert_gt(end.y, 60.0, "further to the side they were already on")
	assert_lt(absf(end.x), 12.0, "not running on ahead of it")


func test_straight_at_them_they_make_for_the_kerb() -> void:
	var b := _brain()
	var me := Vector2(0, -50)  # in the road, the route (the kerb) below them
	var car := {"pos": Vector2(-500, -50), "vel": Vector2(300, 0)}
	var end := _run(b, me, 30, [car])
	assert_gt(end.y, -40.0, "towards the sidewalk")


func test_at_the_last_moment_they_throw_themselves_clear() -> void:
	var b := _brain()
	var out := {}
	for i in 30:
		out = b.update(DT, Vector2.ZERO, [{"pos": Vector2(-180, 0), "vel": Vector2(300, 0)}])
	assert_eq(out.speed, PedestrianBrain.DIVE, "0.6 s from it: a dive")
	var b2 := _brain()
	for i in 30:
		out = b2.update(DT, Vector2.ZERO, [{"pos": Vector2(-560, 0), "vel": Vector2(300, 0)}])
	assert_eq(out.speed, PedestrianBrain.RUN, "further off: a run")


func test_a_wall_in_the_way_sends_them_the_other_way() -> void:
	var b := _brain()
	var car := {"pos": Vector2(-500, 0), "vel": Vector2(300, 0)}
	_run(b, Vector2(0, 30), 20, [car])
	var side := b.side
	b.blocked()
	assert_eq(b.side, -side)
	b.blocked()
	assert_eq(b.side, -side, "once a dodge")


func test_a_car_that_turns_after_them_is_a_chase() -> void:
	var b := _brain()
	var me := Vector2(0, 30)
	var pos := Vector2(-500, 0)
	var heading := 0.0
	for i in 40:
		heading += 0.012 * signf((me - pos).angle() - heading)  # it keeps turning after them
		var car := {"pos": pos, "vel": Vector2.from_angle(heading) * 300.0}
		var out := b.update(DT, me, [car])
		me += (out.dir as Vector2) * float(out.speed) * DT
		pos += (car.vel as Vector2) * DT
	assert_eq(b.chased, 1, "it is after them")


## A car of type `vt` from `start`, steering at them (or where they are going:
## `lead`) with `gain`, flat out, for `seconds`: whether it ran them down.
func _chase(vt: VehicleType, start: Vector2, lead: bool, gain: float, seconds: float) -> bool:
	var b := _brain()
	var me := Vector2.ZERO
	var car := CarModel.new(vt.params)
	car.position = start
	car.heading = (me - start).angle()
	var prev := me
	for i in int(seconds / DT):
		var target := me
		if lead:
			target = me + (me - prev) / DT * minf(car.position.distance_to(me) / maxf(car.velocity.length(), 120.0), 1.2)
		prev = me
		car.update(DT, clampf(wrapf((target - car.position).angle() - car.heading, -PI, PI) * gain, -1.0, 1.0), true, false, false)
		car.integrate(DT)
		var out := b.update(DT, me, [{"pos": car.position, "vel": car.velocity}])
		me += (out.dir as Vector2) * float(out.speed) * DT
		if _touches(car, me):
			return true
	return false


## Passing `offset` px wide of them at 300 px/s, it swerves at them `when` s
## before it would pass; `frozen`: they do not move at all.
func _swerve(vt: VehicleType, offset: float, when: float, frozen := false) -> bool:
	var b := _brain()
	var me := Vector2.ZERO
	var car := CarModel.new(vt.params)
	car.position = Vector2(-900, offset)
	car.velocity = Vector2(300, 0)
	car.drive_level = 1.0
	var swerving := false
	for i in int(5.0 / DT):
		swerving = swerving or (me.x - car.position.x) / maxf(car.velocity.x, 1.0) < when
		var steer := clampf(wrapf((me - car.position).angle() - car.heading, -PI, PI) * 8.0, -1.0, 1.0) if swerving else 0.0
		car.update(DT, steer, true, false, false)
		car.integrate(DT)
		if not frozen:
			var out := b.update(DT, me, [{"pos": car.position, "vel": car.velocity}])
			me += (out.dir as Vector2) * float(out.speed) * DT
		if _touches(car, me):
			return true
	return false


## The car's body (76 x 30) touches a person (radius 9) at `me`.
func _touches(car: CarModel, me: Vector2) -> bool:
	var local := (me - car.position).rotated(-car.heading)
	var q := Vector2(clampf(local.x, -38.0, 38.0), clampf(local.y, -15.0, 15.0))
	return local.distance_to(q) < 9.0


func test_a_determined_chase_seldom_runs_anybody_down() -> void:
	var hits := 0
	var runs := 0
	for vt in [SEDAN, COUPE]:
		for lead in [false, true]:
			for gain in [4.0, 8.0]:
				for start in [Vector2(-500, 0), Vector2(-800, -100), Vector2(-300, 200), Vector2(400, -300)]:
					runs += 1
					if _chase(vt, start, lead, gain, 10.0):
						hits += 1
	gut.p("chases that ran somebody down: %d of %d" % [hits, runs])
	assert_lte(hits, runs / 5, "hard to chase somebody down (10 s flat out, steering at them)")


func test_a_sudden_swerve_can_still_catch_somebody() -> void:
	var hits := 0
	var still := 0
	for vt in [SEDAN, COUPE]:
		for off in [-90.0, -75.0, 75.0, 90.0]:
			for when in [0.35, 0.5, 0.65, 0.8]:
				if _swerve(vt, off, when):
					hits += 1
				if _swerve(vt, off, when, true):
					still += 1
	gut.p("late swerves that caught somebody: %d of 32 (standing still: %d)" % [hits, still])
	assert_gt(still, 16, "(the swerve reaches a person who stands still)")
	assert_gt(hits, 0, "by surprise it can happen")
	assert_lt(hits, still, "but people still try")
