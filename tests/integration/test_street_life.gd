extends "res://tests/support/city_test.gd"
## M003 the inhabited Riverside Ward: in the evening a handful of people walk
## the sidewalks and a few cars go round the blocks; a car stops for someone
## in its path and drives on when the way is clear; people jump out of the
## way of a car and run from gunfire; late at night fewer are out (they go
## only where you cannot see); sleeping brings the evening back. The squad
## car is parked in the alley.


func before_each() -> void:
	quiet_streets = false
	await super.before_each()


func street() -> StreetLife:
	return main.street


func test_people_and_cars_are_out_in_the_evening() -> void:
	assert_eq(street().active_pedestrians(), street().pedestrians.size())
	assert_eq(street().active_traffic(), street().traffic.size())
	var starts := street().traffic.map(func(c: Car) -> Vector2: return c.global_position)
	var walker_starts := street().pedestrians.map(func(p: Pedestrian) -> Vector2: return p.body.global_position)
	await wait_physics_frames(60 * 5)
	for i in street().traffic.size():
		var c: Car = street().traffic[i]
		assert_gt(c.global_position.distance_to(starts[i]), 300.0, "car %d drives round" % i)
		assert_false(main.layout.is_in_building(c.global_position), "and never into a building")
	var moved := 0
	for i in street().pedestrians.size():
		if street().pedestrians[i].body.global_position.distance_to(walker_starts[i]) > 60.0:
			moved += 1
	assert_gte(moved, street().pedestrians.size() - 2, "people stroll (one may stop at a window)")


func test_a_car_waits_for_someone_in_its_path_then_drives_on() -> void:
	var c: Car = street().traffic[0]  # eastbound on Marlowe at the start
	var lane_y := c.global_position.y
	walker().place(Vector2(c.global_position.x + 260.0, lane_y), PI)
	await wait_physics_frames(60 * 4)
	assert_lt(c.model.forward_speed(), 5.0, "it stopped")
	var gap := walker().global_position.x - c.global_position.x
	assert_gt(gap, 40.0, "short of him")
	assert_true(street().drivers[0].waiting)
	walker().place(Vector2(c.global_position.x + 260.0, lane_y - 140.0), PI)  # steps onto the sidewalk
	await wait_physics_frames(60 * 2)
	assert_gt(c.model.forward_speed(), 60.0, "and drives on")


func test_people_jump_out_of_the_way_of_a_car() -> void:
	var p: Pedestrian = street().pedestrians[0]
	var c := car_of_type("sedan")
	var at := p.body.global_position
	await park(c, at + Vector2(-260, 0), 0.0)  # along the sidewalk, straight at him
	await seat_in(c)
	var dodged := false
	for i in 90:
		cmd = PlayerCommand.make(Vector2(0, -1))
		await wait_physics_frames(1)
		if p.brain.state == PedestrianBrain.State.DODGE:
			dodged = true
	cmd = PlayerCommand.new()
	assert_true(dodged, "he saw it coming")


func test_gunfire_sends_people_running() -> void:
	var p: Pedestrian = street().pedestrians[1]
	await at_the_streetcar_stop()
	walker().place(p.body.global_position + Vector2(0, 120), 0.0)
	await wait_physics_frames(2)
	await click(walker().global_position + Vector2(0, 200))
	await aim_for(walker().global_position + Vector2(0, 200), 20)
	assert_eq(p.brain.state, PedestrianBrain.State.FLEE)


func test_late_at_night_fewer_are_out_and_sleep_brings_the_evening_back() -> void:
	main.clock.set_time(main.night_rules.start_minute + 8 * 60)  # 3:30 am
	assert_lt(street().wanted_pedestrians(), street().pedestrians.size())
	assert_lt(street().wanted_traffic(), street().traffic.size())
	assert_gte(street().wanted_pedestrians(), 1, "the streets are never quite empty")
	main.camera.global_position = Vector2(-1500, -1200)  # look away: they go home only out of sight
	street().view = Rect2(-2200, -1600, 100, 100)
	street().recount()
	assert_eq(street().active_pedestrians(), street().wanted_pedestrians())
	assert_eq(street().active_traffic(), street().wanted_traffic())
	var gone: Car = street().traffic.filter(func(c: Car) -> bool: return not c.visible)[0]
	assert_eq(gone.collision_layer, 0, "a car that went home is out of the way")
	await talk_to("home", "bed")
	await answer_with("sleep")
	assert_eq(street().active_pedestrians(), street().pedestrians.size(), "a lively evening again")
	assert_eq(street().active_traffic(), street().traffic.size())


func test_the_squad_car_is_parked_in_the_alley() -> void:
	var police: Array = main.fleet.cars.filter(func(c: Car) -> bool: return c.vehicle.id == "police")
	assert_eq(police.size(), 1)
	assert_eq(police[0].paint, "cars/police")
	assert_false(police[0].driven, "nobody at the wheel")
	assert_true(main.layout.alleys.any(func(a: Dictionary) -> bool: return (a.rect as Rect2).has_point(police[0].global_position)))


## M009: a long vehicle stopped across the lane - the traffic sees all of it,
## not just its middle: with only the bus's nose poking into the lane, the
## car still stops short of it instead of running into it.
func test_a_car_waits_short_of_a_bus_nosing_into_its_lane() -> void:
	var c: Car = street().traffic[0]  # eastbound on Marlowe at the start
	var lane_y := c.global_position.y
	var x0 := c.global_position.x + 330.0
	var bus: Car = main.fleet.make_car({"type": "school_bus", "paint": 0, "pos": Vector2(x0, lane_y + 68.0), "rot": -PI / 2,
		"owner": "St. Brendan's parish school"})
	assert_true(street().parked.has(bus))
	await wait_physics_frames(60 * 5)
	assert_lt(c.model.forward_speed(), 5.0, "it stopped")
	assert_true(street().drivers[0].waiting, "it is waiting, not stuck against it")
	var nose := c.global_position.x + c.vehicle.size.x * 0.5
	assert_lt(nose, x0 - bus.vehicle.size.y * 0.5 - 6.0, "short of the bus's side, not touching it")
