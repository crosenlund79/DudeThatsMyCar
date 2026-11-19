extends "res://tests/support/city_test.gd"
## M013.3 the living wheel in the game: Mrs. Halloway and Big Stan at the
## rail play their own colour chips through the betting time; Danny can stand
## and watch them; their wins and losses are taken as people take them (a
## hop, a turn away, a line over the head - always for a big win, when Leo
## names the winner and turns to him); a regular struck down plays no more;
## Danny's money moves only with his own chips, to the cent, however the
## regulars bet. Shorter rounds for the tests (the same rules otherwise).


func before_each() -> void:
	await super()
	var quick: RouletteRules = main.roulette_rules.duplicate()
	quick.open_seconds = 4.0
	quick.ball_seconds = 3.0
	quick.drop_seconds = 2.0
	quick.result_seconds = 2.0
	main.wheel.rules = quick
	main.wheel_patrons.rules = quick


func _view() -> RouletteView:
	return main.hud.roulette_view


func _room() -> InteriorView:
	return main.interiors.view_of("gaming_room")


func _step_up(money: int) -> void:
	main.rackets.money = money
	walker().place(RiversideInteriors.ROULETTE_SPOT, -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	await press_e()
	assert_true(_view().is_open())


func _until_phase(phase: int, fresh := false) -> void:
	if fresh:
		for i in 2400:
			if main.wheel.phase != phase:
				break
			await wait_physics_frames(1)
	for i in 2400:
		if main.wheel.phase == phase:
			return
		await wait_physics_frames(1)


func test_the_regulars_play_at_the_rail_while_danny_watches() -> void:
	await _step_up(700)
	assert_has(main.wheel.patrons.seated(), "edna")
	assert_has(main.wheel.patrons.seated(), "stan")
	var most := 0
	var rounds := 0
	while rounds < 4:
		await _until_phase(RouletteTable.Phase.RESULT, true)
		rounds += 1
		await _until_phase(RouletteTable.Phase.BALL, true)
		most = maxi(most, main.wheel_patrons.total_down())
		await _until_phase(RouletteTable.Phase.DROP, true)
		most = maxi(most, main.wheel_patrons.total_down())
	assert_gt(most, 0, "their chips on the layout")
	assert_eq(main.rackets.money, 700, "watching them costs Danny nothing")
	assert_eq(main.roulette.total_staked(), 0, "none of their chips are his")
	await press_e()


func test_dannys_money_moves_only_with_his_own_chips() -> void:
	await _step_up(3000)
	for r in 3:
		await _until_phase(RouletteTable.Phase.OPEN, true)
		var before: int = main.rackets.money
		main._on_wheel_bet("black", 100)
		main._on_wheel_bet("straight:17", 25)
		await _until_phase(RouletteTable.Phase.RESULT)
		var n: int = main.wheel.number
		assert_eq(main.rackets.money, before - 125 + Roulette.returns("black", 100, n) + Roulette.returns("straight:17", 25, n),
			"round %d: his own chips, to the cent, whatever the regulars had down" % r)
	main.leave_roulette()


func test_a_big_win_at_the_rail() -> void:
	walker().place(RiversideInteriors.ROULETTE_SPOT + Vector2(0, 30), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	var stan: Walker = _room().people.stan
	var leo: Walker = _room().people.croupier
	main._wheel_reactions(17, [{"id": "stan", "staked": 25, "paid": 900}, {"id": "edna", "staked": 10, "paid": 0}])
	await wait_physics_frames(2)
	assert_has(Patrons.ROSTER.stan.big_win, main.room_lines.line_of(stan), "Big Stan takes it as he would")
	assert_string_contains(main.room_lines.line_of(leo), "17, black.")
	assert_string_contains(main.room_lines.line_of(leo), "Well played, Big Stan", "Leo names the winner")
	assert_lt(leo.aim_point.distance_to(stan.global_position), 1.0, "and turns to him")
	await wait_physics_frames(200)
	var home: Dictionary = _room().plan.person("croupier")
	assert_lt(leo.aim_point.distance_to((home.pos as Vector2) + Vector2.from_angle(float(home.facing)) * 50.0), 1.0,
		"then back to his wheel")


func test_a_regular_struck_down_plays_no_more() -> void:
	walker().place(RiversideInteriors.ROULETTE_SPOT + Vector2(0, 30), -PI / 2)
	await wait_physics_frames(3)
	main._on_person_down("edna", false, _room())
	assert_false("edna" in main.wheel.patrons.seated())
	for i in 600:
		await wait_physics_frames(1)
		for id in main.wheel_patrons.bets:
			assert_ne(id, "edna")
