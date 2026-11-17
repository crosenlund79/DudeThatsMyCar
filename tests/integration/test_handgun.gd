extends "res://tests/support/city_test.gd"
## The handgun in the street: shots go where the mouse aims (whatever way the
## gangster walks), bullets stop at buildings and cars, run out of range in the
## open, a gun pressed to a wall fires into it, the magazine empties and
## reloads, and nobody shoots from behind the wheel.

const OWL_FRONT := 439.0  # the Copper Owl's front wall (y)


func before_each() -> void:
	await super.before_each()
	await at_the_streetcar_stop()


func _bullets() -> BulletWorld:
	return main.bullets


func _last_impact() -> Array:
	return get_signal_parameters(_bullets(), "impact")


func test_a_shot_at_the_copper_owl_stops_at_its_wall() -> void:
	watch_signals(_bullets())
	watch_signals(player())
	var aim := Vector2(walker().global_position.x, OWL_FRONT - 60.0)  # straight up at the club
	await click(aim)
	await wait_physics_frames(int(main.gun_rules.draw_time * 60.0) + 4)
	assert_signal_emitted(player(), "fired")
	assert_true(walker().gun.is_drawn())
	assert_true(walker().pistol.visible, "the pistol is in his hand")
	await wait_physics_frames(20)
	assert_signal_emitted(_bullets(), "impact")
	var hit: Vector2 = _last_impact()[0]
	assert_almost_eq(hit.y, OWL_FRONT, 2.0, "the bullet stopped at the wall")
	assert_eq(_bullets().bullets.size(), 0, "nothing passed through")


func test_shots_follow_the_mouse_not_the_feet() -> void:
	watch_signals(player())
	var target := walker().global_position + Vector2(0, -300)
	await click(target, Vector2.RIGHT)  # walking east, aiming north
	await aim_for(target, int(main.gun_rules.draw_time * 60.0) + 4, Vector2.RIGHT)
	assert_signal_emitted(player(), "fired")
	var dir: Vector2 = get_signal_parameters(player(), "fired")[1]
	assert_lt(absf(angle_difference(dir.angle(), -PI / 2)), deg_to_rad(4.0), "fired north while walking east")
	assert_gt(walker().velocity.x, 30.0)


func test_a_bullet_can_hit_a_parked_car() -> void:
	watch_signals(_bullets())
	var car := roadster()
	await click(car.global_position)
	await wait_physics_frames(40)
	assert_signal_emitted(_bullets(), "impact")
	assert_eq(_last_impact()[2], car, "the roadster took the bullet")


func test_in_the_open_a_bullet_runs_out_of_range() -> void:
	watch_signals(_bullets())
	walker().place(Vector2(1000, 600), 0.0)  # middle of Marlowe Avenue, looking west down it
	await wait_physics_frames(1)
	await click(Vector2(400, 600))
	await wait_physics_frames(60)
	assert_signal_emitted(_bullets(), "spent")
	assert_signal_not_emitted(_bullets(), "impact")
	var at: Vector2 = get_signal_parameters(_bullets(), "spent")[0]
	assert_almost_eq(walker().global_position.distance_to(at), main.gun_rules.bullet_range + main.gun_rules.muzzle_offset.x, 20.0)


func test_a_gun_pressed_to_a_wall_fires_into_the_wall() -> void:
	watch_signals(_bullets())
	walker().place(Vector2(2210, OWL_FRONT + Walker.RADIUS + 1.0), -PI / 2)  # nose to the club wall, beside its door
	await wait_physics_frames(1)
	await click(Vector2(2210, OWL_FRONT - 100.0))
	await wait_physics_frames(15)
	assert_signal_emitted(_bullets(), "impact")
	var hit: Vector2 = _last_impact()[0]
	assert_gte(hit.y, OWL_FRONT - 1.0, "never on the far side of the wall")


func test_seven_shots_then_a_reload() -> void:
	watch_signals(player())
	var aim := walker().global_position + Vector2(0, -200)
	for i in 7:
		await click(aim)
		await aim_for(aim, 20)
	assert_eq(get_signal_emit_count(player(), "fired"), 7)
	assert_eq(walker().gun.ammo, 0)
	assert_true(walker().gun.is_reloading())
	assert_string_contains(main.hud.gun_label.text, "reloading")
	await click(aim)
	await aim_for(aim, 10)
	assert_eq(get_signal_emit_count(player(), "fired"), 7, "no shot while reloading")
	await aim_for(aim, int(main.gun_rules.reload_time * 60.0) + 5)
	assert_eq(walker().gun.ammo, main.gun_rules.magazine)
	assert_string_contains(main.hud.gun_label.text, "7 / 7")


func test_no_shooting_from_behind_the_wheel() -> void:
	watch_signals(player())
	var c := roadster()
	await click(c.global_position + Vector2(0, 200))
	await seat_in(c)
	assert_false(walker().gun.is_drawn(), "the gun goes away in the car")
	await click(c.global_position + Vector2(300, 0))
	await wait_physics_frames(30)
	assert_signal_not_emitted(player(), "fired")
