extends "res://tests/support/city_test.gd"
## M006 violence and its consequences in the game: Lefty Moran minds his own
## business until Danny shoots at him, then fights back and can be wounded
## and killed (and stays dead); Danny can be wounded and goes down rather than
## dies; the ward's own people are carried off to the Doc's for the night, not
## killed, and remember it; the Bird shot means no music; the beat cop is
## mortal and a new man walks the beat the next night.

var _save := ""


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func lefty() -> Rival:
	return main.rival


## Rounds into a person as Danny's bullets would put them (from his side).
func hit(w: Walker, times: int, by: Node = null) -> void:
	for i in times:
		w.hit_by_bullet(w.global_position + Vector2(-6, 0), Vector2.RIGHT, by if by != null else walker())
		await wait_physics_frames(1)


func _shots(r: Rival) -> Array:
	var shots := []
	r.fired.connect(func(m: Vector2, _d: Vector2) -> void: shots.append(m))
	return shots


func test_lefty_minds_his_own_business() -> void:
	var r := lefty()
	assert_true(main.layout.is_open_ground(r.body.global_position, 9.0), "on the sidewalk outside Doyle's Garage")
	var shots := _shots(r)
	walker().place(r.body.global_position + Vector2(-34, 0), 0.0)
	await wait_physics_frames(180)
	assert_false(r.is_hostile(), "Danny can walk right up to him")
	assert_eq(shots.size(), 0)
	walker().place(r.body.global_position + Vector2(-30, 0), 0.0)
	await wait_physics_frames(3)
	assert_string_contains(main.hud.prompt_label.text, "Lefty")
	await press_e()
	assert_eq(main.dialogue.talking, "lefty")
	await answer_with("who")
	assert_string_contains(main.dialogue.page.text, "North Side")


func test_shoot_him_and_he_fights_back_until_he_goes_down() -> void:
	var r := lefty()
	var shots := _shots(r)
	walker().place(r.body.global_position + Vector2(-170, 0), 0.0)
	await wait_physics_frames(3)
	await click(r.body.global_position)
	await aim_for(r.body.global_position, 20)
	assert_true(r.body.condition.is_hurt(), "hit")
	assert_true(r.is_hostile(), "and now he is after Danny")
	for i in 240:
		await wait_physics_frames(1)
		if not shots.is_empty():
			break
	assert_gt(shots.size(), 0, "he shoots back")
	for i in 14:
		if r.is_down():
			break
		await click(r.body.global_position)
		await aim_for(r.body.global_position, 25)
	assert_true(r.is_down(), "shot down")
	assert_eq(r.body.collision_layer, 0, "lying still, out of the way")
	var n := shots.size()
	await wait_physics_frames(120)
	assert_eq(shots.size(), n, "a dead man fires no more")
	# saved and loaded: he stays dead
	_save = OS.get_user_data_dir().path_join("test_violence_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = callouts  # M012: as in before_each
	main.save_path = _save
	main.settings_path = ""
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(3)
	assert_true(main.rival.is_down(), "dead in the saved game too")
	main.save_path = ""


func test_a_near_miss_is_enough() -> void:
	var r := lefty()
	walker().place(r.body.global_position + Vector2(-200, 0), 0.0)
	await wait_physics_frames(3)
	await click(r.body.global_position + Vector2(0, 28))
	await aim_for(r.body.global_position, 10)
	assert_true(r.is_hostile(), "a round past his ear counts")


func test_danny_is_wounded_and_goes_down_but_does_not_die() -> void:
	var r := lefty()
	walker().place(Vector2(2350, 600), 0.0)
	await wait_physics_frames(2)
	walker().hit_by_bullet(walker().global_position + Vector2(0, 8), Vector2.UP, r.body)
	assert_true(walker().condition.is_hurt())
	assert_string_contains(main.hud.notice_label.text, "Hit in the")
	walker().condition.hurt("left_leg", 60)
	var start := walker().global_position
	await hold(Vector2.RIGHT, 60)
	assert_lt(walker().global_position.distance_to(start), walker().model.walk_speed * 0.9, "limping")
	var minute: float = main.clock.minute
	for i in 8:
		if main.casualties.collapses > 0:
			break
		await hit(walker(), 1, r.body)
	assert_eq(main.casualties.collapses, 1, "Danny went down")
	assert_false(walker().down, "and came to")
	assert_true(main.interiors.view_of("vet").plan.contains(walker().global_position), "at the Doc's (M006.7)")
	assert_lt(walker().condition.worst(), BodyCondition.Level.WOUNDED, "patched up in a hurry")
	assert_gt(main.clock.minute, minute + 50.0, "an hour later")


func test_the_wards_own_people_are_carried_off_not_killed() -> void:
	var augie: Walker = main.interiors.person("copper_owl", "augie")
	var trust: int = main.rackets.boss.trust
	for i in 8:
		if augie.down:
			break
		await hit(augie, 1)
	assert_true(augie.down)
	assert_true(main.casualties.ward_out.has("augie"), "out for the night")
	assert_lt(main.rackets.boss.trust, trust - 15, "Rourke takes it badly: one of his own")
	assert_eq(main.rackets.memory.recent("augie", "shot", main.rackets.night), 1, "Augie won't forget")
	await wait_physics_frames(int(InteriorView.CARRIED_OFF_AFTER * 60.0) + 30)
	assert_false(augie.visible, "carried off to the Doc's")
	walker().place(Vector2(2240, 252), 0.0)
	await wait_physics_frames(3)
	await press_e()
	assert_eq(main.dialogue.talking, "", "nobody behind the bar to talk to")
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	assert_true(augie.visible and not augie.down, "back behind his bar the next evening")
	assert_true(main.interiors.view_of("copper_owl").person_ok("augie"))
	await talk_to("copper_owl", "augie")
	assert_eq(main.dialogue.talking, "augie")


func test_the_bird_shot_means_no_music_tonight() -> void:
	var bird: Walker = main.interiors.person("copper_owl", "bird")
	for i in 8:
		if bird.down:
			break
		await hit(bird, 1)
	assert_true(main.stage.out)
	assert_true(main.soundscape.music_stopped)
	assert_false(main.soundscape.music.playing)
	await wait_physics_frames(200)
	assert_false(main.soundscape.music.playing, "and it does not start again")
	main.night.sleep()
	await wait_physics_frames(5)
	assert_true(main.soundscape.music.playing, "she is back the next night")


func test_the_beat_cop_is_mortal_and_replaced_the_next_night() -> void:
	var cop: Walker = main.officer.body
	for i in 8:
		if cop.down:
			break
		await hit(cop, 1)
	assert_true(main.officer.is_down(), "shot down (%s)" % cop.condition.to_dict())
	assert_eq(main.hud.minimap.police, Vector2.INF, "no police on the map")
	var at := cop.global_position
	await wait_physics_frames(60)
	assert_eq(cop.global_position, at, "he lies where he fell")
	main.night.sleep()
	await wait_physics_frames(5)
	assert_false(main.officer.is_down(), "a new man on the beat")


func test_dannys_wounds_are_saved() -> void:
	_save = OS.get_user_data_dir().path_join("test_wounds_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	walker().condition.shoot("right_arm", 0.5)
	main.save_game()
	var arm: int = walker().condition.damage.right_arm
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = callouts  # M012: as in before_each
	main.save_path = _save
	main.settings_path = ""
	add_child_autofree(main)
	await wait_physics_frames(3)
	assert_eq(main.walker.condition.damage.right_arm, arm)
	main.save_path = ""
