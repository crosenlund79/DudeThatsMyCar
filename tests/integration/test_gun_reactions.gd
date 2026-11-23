extends "res://tests/support/city_test.gd"
## M015 a gun in Danny's hand, out in the open: passers-by keep away and run if
## he comes close; the people who keep a place of business won't deal with it
## out (put away, the talk goes on); a copper tells him to put it away and
## comes for him if he doesn't (sooner for a Thompson), lets it go if he does;
## Lefty warns him about a handgun and goes for his gun at a Tommy gun.


func _draw() -> void:
	if not walker().gun.is_drawn():
		walker().gun.toggle_kept()
	await wait_physics_frames(2)


func _holster() -> void:
	walker().gun.holster()
	await wait_physics_frames(2)


## Seconds of the game (physics frames at 60 a second).
func _seconds(s: float) -> void:
	await wait_physics_frames(int(s * 60.0))


func test_nothing_out_nothing_to_see() -> void:
	assert_eq(main.armoury.shown_level(), GunSight.NONE)
	await _draw()
	assert_eq(main.armoury.shown_level(), GunSight.HANDGUN)
	await _holster()
	assert_eq(main.armoury.shown_level(), GunSight.NONE)


func test_a_passer_by_keeps_away() -> void:
	var p: Pedestrian = main.street.pedestrians[0]
	p.set_active(true)
	var at := p.body.global_position
	walker().place(at + Vector2(-180, 0), 0.0)
	main.officer.body.place(Vector2(-1500, -800), 0.0)  # (the copper out of it)
	await wait_physics_frames(3)
	assert_ne(p.brain.state, PedestrianBrain.State.WARY, "nothing in his hand")
	await _draw()
	await wait_physics_frames(3)
	assert_true(p.brain.state in [PedestrianBrain.State.WARY, PedestrianBrain.State.FLEE], "uneasy at once")
	var d0 := p.body.global_position.distance_to(walker().global_position)
	await _seconds(1.0)
	assert_gt(p.body.global_position.distance_to(walker().global_position), d0, "keeping their distance")
	walker().place(p.body.global_position + Vector2(-60, 0), 0.0)
	await wait_physics_frames(3)
	assert_eq(p.brain.state, PedestrianBrain.State.FLEE, "too close with it: they run")


func test_a_shopkeeper_wont_deal_with_it_out() -> void:
	await _draw()
	await talk_to("copper_owl", "augie")
	assert_string_contains(main.dialogue.page.text, "put that away")
	assert_eq((main.dialogue.page.options as Array).map(func(o: Dictionary) -> String: return o.id), ["holster", "bye"])
	assert_gt(main.rackets.memory.recent("augie", "gun_shown", main.rackets.night), 0, "and he remembers it")
	await answer_with("holster")
	assert_false(walker().gun.is_drawn(), "put away")
	assert_true((main.dialogue.page.options as Array).any(func(o: Dictionary) -> bool: return o.id == "protection" or o.id == "sell"),
		"and business as usual")


func test_a_copper_warns_then_comes() -> void:
	var cop: PoliceOfficer = main.officer
	walker().place(cop.body.global_position + Vector2(0, 160), -PI / 2)
	await wait_physics_frames(3)
	assert_false(cop.brain.is_hunting())
	await _draw()
	await _seconds(1.0)
	assert_false(cop.brain.is_hunting(), "first a warning")
	assert_string_contains(main.overhead.label.text, "Put that gun away", "the copper's word over his head")
	assert_eq(main.overhead.speaker, cop.body)
	await _seconds(6.5)  # (his six seconds of patience, and a look round)
	assert_true(cop.brain.is_hunting(), "he didn't put it away: the copper comes for him")
	assert_false(cop.brain.armed, "unarmed - carrying is no violent crime")


func test_put_away_in_time() -> void:
	var cop: PoliceOfficer = main.officer
	walker().place(cop.body.global_position + Vector2(0, 160), -PI / 2)
	await wait_physics_frames(3)
	await _draw()
	await _seconds(2.0)
	await _holster()
	await _seconds(6.0)
	assert_false(cop.brain.is_hunting(), "he let it go")


func test_a_thompson_gets_less_patience() -> void:
	main.armoury.arm_thompson(true)
	main.player.switch_gun()
	await wait_physics_frames(2)
	assert_eq(walker().gun, main.armoury.thompson)
	var cop: PoliceOfficer = main.officer
	walker().place(cop.body.global_position + Vector2(0, 160), -PI / 2)
	await wait_physics_frames(3)
	await _draw()
	assert_eq(main.armoury.shown_level(), GunSight.THOMPSON)
	await _seconds(3.6)
	assert_true(cop.brain.is_hunting(), "three seconds with a Tommy gun")


func test_lefty() -> void:
	var lefty: Rival = main.rival
	walker().place(lefty.body.global_position + Vector2(-150, 0), 0.0)
	main.officer.body.place(Vector2(-1500, -800), 0.0)
	await wait_physics_frames(3)
	await _draw()
	await _seconds(1.0)
	assert_false(lefty.is_hostile(), "a handgun: a word, not a fight")
	await _holster()
	main.armoury.arm_thompson(true)
	main.player.switch_gun()
	await _draw()
	await _seconds(1.0)
	assert_true(lefty.is_hostile(), "a Tommy gun pointed his way is a fight")
