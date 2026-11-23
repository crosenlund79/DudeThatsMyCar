extends "res://tests/support/city_test.gd"
## M015 Danny's car and the people in the street: a car he drives knocks a
## person down instead of stopping dead against them - a clip at a crawl
## (bruised, up again in a moment), a hard knock (badly hurt, limping) or
## worse (they don't get up) - and goes on through, a little slower. A copper
## who sees it comes for him (his revolver out for anything worse than a
## clip); a copper struck himself always knows; Lefty takes it personally;
## people nearby scatter; the local who saw it starts the talk. The street's
## own traffic still stops short of people. And a passer-by sees a car coming
## straight at them and gets out of its way.

const SPOT := Vector2(2700, 640)  # Marlowe Avenue, the open road east of the streetcar stop


## Danny's own sedan (outside his flat).
func _own_car() -> Car:
	for i in main.fleet.cars.size():
		if String(main.fleet.specs[i].get("owner", "")) == CarThefts.DANNY:
			return main.fleet.cars[i]
	return null


func _stranger(at: Vector2) -> Walker:
	var w := Walker.create(main.resolver, "characters/worker", {"glow": false})
	main.add_child(w)
	w.place(at, PI * 0.5)
	return w


## Danny's own sedan rolling east along the avenue at `speed` px/s from
## `run_up` px short of `at`, held at that speed until it strikes somebody
## (or goes past), then coasting on.
func _roll_at(at: Vector2, speed: float, run_up: float = 160.0) -> Car:
	var c := _own_car()
	await park(c, at + Vector2(-run_up, 0), 0.0)
	await seat_in(c)
	var struck: int = main.run_overs.tonight
	for i in 120:
		if main.run_overs.tonight > struck or c.global_position.x > at.x + 60.0:
			break
		c.model.velocity = Vector2.from_angle(c.model.heading) * speed
		await wait_physics_frames(1)
	return c


func _until_past(c: Car, x: float, ticks: int = 120) -> void:
	for i in ticks:
		if c.global_position.x > x + 70.0:
			return
		await wait_physics_frames(1)


func test_a_clip_at_a_crawl_bruises_and_they_get_up() -> void:
	var w := _stranger(SPOT)
	var c := await _roll_at(SPOT, 100.0)
	var said: String = main.hud.notice_label.text
	for i in 40:  # his foot still on the pedal
		cmd = PlayerCommand.make(Vector2(0, -1))
		await wait_physics_frames(1)
	cmd = PlayerCommand.new()
	assert_gt(c.global_position.x, SPOT.x + 60.0, "the car went on, not stopped dead against them")
	assert_eq(w.condition.worst(), BodyCondition.Level.GRAZED, "bruised")
	assert_false(w.down)
	assert_eq(w.last_cause, "car")
	assert_eq(w.last_shooter, walker(), "Danny was at the wheel")
	assert_gt(absf(w.global_position.y - SPOT.y), 15.0, "thrown aside, out of its path")
	assert_string_contains(said, "clipped a passer-by")
	assert_eq(main.run_overs.tonight, 1)
	await wait_physics_frames(int(1.5 * 60))
	assert_eq(w.knocked, 0.0, "on their feet again")


func test_a_fast_one_is_fatal_and_the_car_goes_on_through() -> void:
	var w := _stranger(SPOT)
	var c := await _roll_at(SPOT, 300.0, 220.0)
	await _until_past(c, SPOT.x)
	assert_true(w.down, "they don't get up")
	assert_eq(w.collision_layer, 0, "no longer in anybody's way")
	assert_string_contains(main.hud.notice_label.text, "Nobody gets up")
	assert_true(main.run_overs.last.killed)
	assert_gt(c.speed(), 150.0, "it lost some speed, not all of it")


func test_a_hard_knock_badly_hurts() -> void:
	var w := _stranger(SPOT)
	var c := await _roll_at(SPOT, 210.0)
	await _until_past(c, SPOT.x)
	assert_false(w.down)
	assert_eq(w.condition.worst(), BodyCondition.Level.WOUNDED)
	assert_lt(w.condition.speed_factor(), 1.0, "limping when up again")
	assert_gt(w.knocked, 1.0, "on the ground a while")
	assert_string_contains(main.hud.notice_label.text, "flat - badly hurt")


func test_a_copper_who_sees_it_comes_for_him() -> void:
	var cop: PoliceOfficer = main.officer
	cop.body.place(SPOT + Vector2(120, -150), PI)
	_stranger(SPOT)
	var c := await _roll_at(SPOT, 220.0)
	await _until_past(c, SPOT.x)
	assert_true(cop.brain.is_hunting(), "he saw it")
	assert_true(cop.brain.armed, "a hard knock is violence: his revolver out")
	assert_true(main.run_overs.last.seen)


func test_a_clip_seen_by_a_copper_means_a_word() -> void:
	var cop: PoliceOfficer = main.officer
	cop.body.place(SPOT + Vector2(120, -150), PI)
	_stranger(SPOT)
	var c := await _roll_at(SPOT, 100.0)
	await _until_past(c, SPOT.x)
	assert_true(cop.brain.is_hunting(), "he comes over")
	assert_false(cop.brain.armed, "unarmed, for a clip")


func test_a_copper_struck_himself_always_knows() -> void:
	var cop: PoliceOfficer = main.officer
	cop.body.place(SPOT, PI * 0.5)
	cop.brain.state = OfficerBrain.State.ALERTED  # (standing where he is for a moment)
	var c := await _roll_at(SPOT, 160.0, 120.0)
	assert_string_contains(main.hud.notice_label.text, "the copper")
	await _until_past(c, SPOT.x)
	assert_eq(main.run_overs.last.who, "copper")
	assert_true(cop.body.condition.is_hurt())
	assert_true(cop.brain.armed, "struck by Danny's car: he draws")


func test_lefty_takes_it_personally() -> void:
	var rival: Rival = main.rival
	rival.body.place(SPOT, PI * 0.5)
	var c := await _roll_at(SPOT, 140.0, 120.0)
	await _until_past(c, SPOT.x)
	assert_eq(main.run_overs.last.who, "lefty")
	assert_true(rival.body.condition.is_hurt())
	assert_true(rival.is_hostile(), "he'll remember whose car it was")
	assert_string_contains(main.hud.notice_label.text, "Lefty Moran")


func test_people_near_scatter_and_the_local_starts_the_talk() -> void:
	var near := Vector2(2150, 640)  # by the Copper Owl's kerb: Augie sees it
	var p: Pedestrian = main.street.pedestrians[0]
	p.set_active(true)
	p.body.place(near + Vector2(0, -170), 0.0)
	_stranger(near)
	var c := await _roll_at(near, 220.0)
	await _until_past(c, near.x)
	assert_eq(p.brain.state, PedestrianBrain.State.FLEE, "a passer-by who saw it runs")
	var talk: Array = main.rackets.rumours.known_to("augie", "ran_down_street")
	assert_eq(talk.size(), 1, "Augie saw it")
	assert_string_contains(String(talk[0].text), "Marlowe Avenue")


func test_the_streets_own_traffic_never_strikes_anybody() -> void:
	for c in main.street.traffic:
		assert_false(c.strikes_people)
	for c in main.fleet.cars:
		assert_true(c.strikes_people, "the cars Danny can drive do")


func test_a_passer_by_gets_out_of_the_way_of_a_car_coming_straight_at_them() -> void:
	var p: Pedestrian = main.street.pedestrians[0]
	p.set_active(true)
	p.body.place(SPOT, PI * 0.5)
	var c := _own_car()
	await park(c, SPOT + Vector2(-480, 0), 0.0)
	await seat_in(c)
	for i in 150:  # flat out, straight at them
		cmd = PlayerCommand.make(Vector2(0, -1))
		await wait_physics_frames(1)
	cmd = PlayerCommand.new()
	assert_gt(c.global_position.x, SPOT.x, "the car went by")
	assert_eq(main.run_overs.tonight, 0, "and nobody was run down")
	assert_false(p.body.condition.is_hurt())
