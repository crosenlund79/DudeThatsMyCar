extends GutTest
## M006 the walk cycle matches the walking pace: about two steps a second at
## Danny's normal speed (not six), quicker only when he moves quicker, and
## no stepping while he stands still and aims about.

var w: Walker


func before_each() -> void:
	w = Walker.create(AssetResolver.new(OS.get_user_data_dir().path_join("no_overrides")))
	add_child_autofree(w)
	w.place(Vector2(0, 0), 0.0)
	await wait_physics_frames(1)


## Steps (feet coming forward: frames 1 and 3) per second of walking at
## `move`, measured over the distance walked at the speed he walks.
func _steps_per_second(move: Vector2, distance: float) -> float:
	w.move = move
	await wait_physics_frames(30)  # up to speed
	var speed := w.model.speed()
	var start := w.global_position
	var steps := 0
	var last := w.sprite.frame
	while w.global_position.distance_to(start) < distance:
		await wait_physics_frames(1)
		var f := w.sprite.frame
		if f != last and (f == 1 or f == 3):
			steps += 1
		last = f
	w.move = Vector2.ZERO
	return steps / (w.global_position.distance_to(start) / speed)


func test_a_walking_cadence_at_walking_pace() -> void:
	var sps := await _steps_per_second(Vector2.RIGHT, 430.0)
	assert_between(sps, 1.6, 2.8, "steps a second at %.0f px/s (was about 6)" % w.model.walk_speed)


func test_slower_feet_when_he_moves_slower() -> void:
	var full := await _steps_per_second(Vector2.RIGHT, 430.0)
	w.place(Vector2(0, 0), 0.0)
	var half := await _steps_per_second(Vector2.RIGHT * 0.5, 430.0)
	assert_lt(half, full * 0.7, "the cycle follows the speed")


func test_standing_still_and_aiming_never_steps() -> void:
	w.move = Vector2.RIGHT
	await wait_physics_frames(40)
	w.move = Vector2.ZERO
	await wait_physics_frames(20)
	assert_eq(w.sprite.frame, 0, "feet together once he has stopped")
	for i in 60:
		w.aim_point = w.global_position + Vector2.from_angle(i * 0.3) * 80.0
		await wait_physics_frames(1)
		assert_eq(w.sprite.frame, 0, "turning to aim is not walking")
