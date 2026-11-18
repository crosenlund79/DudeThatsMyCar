extends "res://tests/support/city_test.gd"
## M007 a fistfight in the game: the dial comes up over the street with no
## zoom and no other screen, Space and only Space counts, Danny stays where he
## is (no walking, no shooting, no handbrake) until it is over, five checks
## decide it, the loser is hurt (and it shows on C), and play carries on.

var _outcome := {}


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func _done(won: bool, results: Array) -> void:
	_outcome = {"won": won, "results": results}


func lefty() -> Walker:
	return main.rival.body


func _begin() -> bool:
	walker().place(lefty().global_position + Vector2(-40, 0), 0.0)
	await wait_physics_frames(3)
	return main.start_fight(lefty(), "Lefty Moran", _done)


## Plays the fight: press in the zone for each check in `plan` (true) or let it pass (false).
func _play(plan: Array) -> void:
	var dial: FightDial = main.hud.fight_dial
	for want in plan:
		while dial.fight.phase != FistFight.Phase.RUNNING and not dial.fight.is_over():
			await wait_physics_frames(1)
		if want:
			while not dial.fight.in_zone() and dial.fight.phase == FistFight.Phase.RUNNING:
				await wait_physics_frames(1)
			main._unhandled_input(_key(CityInput.HANDBRAKE))
		while dial.fight.phase == FistFight.Phase.RUNNING:
			await wait_physics_frames(1)
	for i in 120:
		if not main.fighting:
			break
		await wait_physics_frames(1)


func test_the_dial_over_the_street_and_nothing_else_moves() -> void:
	var zoom: Vector2 = main.camera.zoom
	assert_true(await _begin())
	assert_true(main.fighting)
	assert_true(main.hud.fight_dial.visible, "the dial over the street")
	assert_eq(main.camera.zoom, zoom, "no zoom, no other screen")
	assert_false(get_tree().paused, "the night goes on round them")
	var at := walker().global_position
	var rounds: int = walker().gun.ammo
	cmd = PlayerCommand.make(Vector2.RIGHT, false, true, at + Vector2(100, 0))
	_fire_pending = true
	await wait_physics_frames(40)
	assert_lt(walker().global_position.distance_to(at), 1.0, "no walking")
	assert_eq(walker().gun.ammo, rounds, "no shooting")
	cmd = PlayerCommand.new()
	_fire_pending = false
	main._unhandled_input(_key(CityInput.MAP))
	main._unhandled_input(_key(CityInput.STATUS))
	assert_false(main.map_open or main.status_open, "no maps mid-fight")
	assert_false(main.start_fight(lefty(), "Lefty Moran", _done), "one fight at a time")


func test_three_landed_wins() -> void:
	assert_true(await _begin())
	await _play([true, true, false, true, false])
	assert_false(main.fighting, "over")
	assert_true(_outcome.won)
	assert_eq(_outcome.results.count(true), 3)
	assert_lt(walker().condition.worst(), BodyCondition.Level.WOUNDED, "a bruise or two")
	assert_true(lefty().condition.is_hurt())
	assert_false(lefty().down, "nobody dies in a fistfight")
	var at := walker().global_position
	await hold(Vector2.RIGHT, 20)
	assert_gt(walker().global_position.distance_to(at), 5.0, "and he can walk again")


func test_two_landed_loses_and_it_shows() -> void:
	assert_true(await _begin())
	await _play([true, false, false, true, false])
	assert_false(_outcome.won)
	assert_eq(walker().condition.level("head"), BodyCondition.Level.WOUNDED, "a black eye")
	assert_false(walker().down, "beaten, not dead")
	main._unhandled_input(_key(CityInput.STATUS))
	assert_eq(main.hud.status_screen.tint_of("head"), StatusScreen.TINT[BodyCondition.Level.WOUNDED], "on the status screen")
	main._unhandled_input(_key(CityInput.STATUS))


func test_space_out_of_the_zone_is_a_miss() -> void:
	assert_true(await _begin())
	var dial: FightDial = main.hud.fight_dial
	while dial.fight.phase != FistFight.Phase.RUNNING:
		await wait_physics_frames(1)
	main._unhandled_input(_key(CityInput.HANDBRAKE))  # straight away: far too early
	assert_eq(dial.fight.results, [false] as Array[bool])
