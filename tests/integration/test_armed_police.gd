extends "res://tests/support/city_test.gd"
## M008 the beat cop's revolver in the game: gunfire alone gets the old chase;
## shooting somebody where he can see it gets him drawing and firing - real
## rounds through the BulletWorld that wound Danny under the M006 body rules,
## never through a building, held while a car is in the way; he can be lost
## as before, and when Danny goes down he stands down. Passers-by never fire.

var shots := 0
## The physics frame of each of his shots.
var shot_frames: Array[int] = []


func cop() -> PoliceOfficer:
	return main.officer


func _count(_m: Vector2, _d: Vector2) -> void:
	shots += 1
	shot_frames.append(Engine.get_physics_frames())


func before_each() -> void:
	await super()
	shots = 0
	shot_frames.clear()
	cop().fired.connect(_count)


## Somebody on the pavement for Danny to shoot (a passer-by).
func _victim(at: Vector2) -> Walker:
	var v := Walker.create(main.resolver, "characters/worker", {"glow": false})
	main.add_child(v)
	v.place(at, 0.0)
	return v


## Danny shoots a passer-by next to the beat cop, in plain sight.
func _shoot_somebody_in_front_of_him() -> Walker:
	var beat_cop := cop().body.global_position
	walker().place(beat_cop + Vector2(40, 210), -PI / 2)
	var v := _victim(beat_cop + Vector2(40, 140))
	await wait_physics_frames(3)
	await click(v.global_position)
	await aim_for(v.global_position, 25)
	return v


func _until(cond: Callable, max_ticks: int) -> bool:
	for t in max_ticks:
		if cond.call():
			return true
		await wait_physics_frames(1)
	return false


func test_gunfire_alone_gets_a_chase_not_a_bullet() -> void:
	var beat_cop := cop().body.global_position
	walker().place(beat_cop + Vector2(60, 220), 0.0)
	await wait_physics_frames(2)
	await click(walker().global_position + Vector2(0, 200))  # into the street, at nobody
	await aim_for(walker().global_position + Vector2(0, 200), 20)
	assert_true(cop().brain.is_hunting(), "he heard it and comes")
	await wait_physics_frames(60 * 8)
	assert_false(cop().brain.armed)
	assert_eq(shots, 0, "no shot at a man he only heard")
	assert_false(cop().body.gun.is_drawn())
	assert_false(walker().condition.is_hurt())


func test_shooting_somebody_in_his_sight_brings_his_revolver() -> void:
	var v := await _shoot_somebody_in_front_of_him()
	assert_true(v.condition.is_hurt(), "the passer-by is hit")
	assert_true(cop().brain.armed, "he saw it")
	assert_string_contains(main.hud.notice_label.text, "revolver")
	assert_true(await _until(func() -> bool: return shots > 0, 60 * 6), "he fires")
	assert_true(cop().body.gun.is_drawn(), "the revolver is out")
	assert_string_contains(main.hud.police_label.text, "SHOOTING")
	await _until(func() -> bool: return walker().condition.is_hurt() or main.casualties.collapses > 0, 60 * 12)
	assert_true(walker().condition.is_hurt() or main.casualties.collapses > 0, "his rounds find Danny standing in the open")
	await wait_physics_frames(60 * 6)
	for i in range(1, shot_frames.size()):
		assert_gte((shot_frames[i] - shot_frames[i - 1]) / 60.0, main.police_rules.fire_gap - 0.05, "one shot every couple of seconds at most")
	assert_gt(cop().body.global_position.distance_to(walker().global_position), main.police_rules.armed_too_close - 10.0,
		"he keeps a gunfight's distance")


func test_never_through_a_building() -> void:
	# Danny in the alley behind the Copper Owl's block; the copper on Marlowe saw what he did
	walker().place(Vector2(2120, 140), 0.0)
	await wait_physics_frames(2)
	assert_false(cop().can_see(walker().global_position), "the block stands between them")
	cop().brain.witness_violence(walker().global_position)
	for i in 60 * 6:
		if cop().can_see(walker().global_position):
			break
		assert_eq(shots, 0, "not a round while a building stands between them")
		await wait_physics_frames(1)
	assert_true(cop().brain.is_hunting(), "he comes looking, the long way round")
	assert_true(cop().body.gun.is_drawn(), "revolver in hand")


func test_he_holds_fire_while_a_car_is_in_the_way() -> void:
	var beat_cop := cop().body.global_position
	walker().place(beat_cop + Vector2(0, 260), -PI / 2)
	var c: Car = main.fleet.cars[0]
	await park(c, beat_cop + Vector2(0, 130), 0.0)
	cop().brain.witness_violence(walker().global_position)
	await wait_physics_frames(3)
	assert_false(cop().clear_shot(walker()), "the car is between them")
	var start := cop().body.global_position
	for i in 45:
		if cop().clear_shot(walker()):
			break
		assert_eq(shots, 0, "no shot into the car")
		await wait_physics_frames(1)
	await wait_physics_frames(60)
	assert_gt(cop().body.global_position.distance_to(start), 10.0, "he moves for a clear line")


func test_lost_as_before_and_the_revolver_goes_away() -> void:
	await _shoot_somebody_in_front_of_him()
	watch_signals(cop())
	walker().place(Vector2(450, 1550), 0.0)  # far away down Pruitt Street, out of sight
	assert_true(await _until(func() -> bool: return not cop().brain.is_hunting(), 60 * 40), "he gives up")
	assert_signal_emitted(cop(), "gave_up")
	await wait_physics_frames(3)
	assert_false(cop().body.gun.is_drawn(), "revolver back in its holster")


func test_shot_down_by_the_police_danny_comes_to_at_the_doc_s() -> void:
	await _shoot_somebody_in_front_of_him()
	main.rackets.money = 2000
	assert_true(await _until(func() -> bool: return main.casualties.collapses > 0, 60 * 60), "standing in the open, he goes down in the end")
	assert_false(cop().brain.is_hunting(), "the copper stands down")
	assert_false(walker().down, "Danny is never killed")
	var vet: InteriorPlan = main.game.ward_plan("vet")
	assert_true(vet.contains(walker().global_position), "on the Doc's table")


func test_shot_at_the_wheel() -> void:
	var c: Car = main.fleet.cars[7]  # Danny's sedan
	await seat_in(c)
	var beat_cop := cop().body.global_position
	for i in 40:
		main.police.bullet_struck(c, c.global_position, Vector2.RIGHT, cop().body)
	assert_true(walker().condition.is_hurt() or main.casualties.collapses > 0, "some rounds go through the door")
	assert_true(beat_cop != Vector2.INF)


func test_passers_by_never_carry_guns() -> void:
	# the ward's passers-by as the street life makes them (cleared in this script, so made afresh here)
	for spec in main.layout.walkers:
		var p := Pedestrian.new()
		add_child_autofree(p)
		p.setup(main.resolver, spec.look, main.layout.walk_routes[spec.route], main.layout.walk_routes[spec.route][0], 7)
		assert_null(p.body.gun, "a passer-by has no gun")
	assert_not_null(main.rival.body.gun, "Lefty is the armed one")
	assert_not_null(cop().body.gun, "and the beat cop")
