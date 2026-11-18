extends "res://tests/support/city_test.gd"
## M006 how Danny is and who patches him up: C shows his figure with every
## wound where it is; Doc Pettibone, the vet on Pruitt Street, patches him up
## for cash (walked into with the normal controls); going down, Danny comes to
## on the Doc's table; the Morgue stands on Pruitt Street as a landmark.


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func vet() -> InteriorPlan:
	return main.interiors.view_of("vet").plan


func test_c_shows_where_he_is_hurt() -> void:
	walker().condition.shoot("left_arm", 0.5)
	walker().condition.hurt("right_leg", 80)
	main._unhandled_input(_key(CityInput.STATUS))
	assert_true(main.status_open)
	assert_true(get_tree().paused, "the night waits")
	var s: StatusScreen = main.hud.status_screen
	assert_true(s.visible)
	assert_eq(s.tint_of("left_arm"), StatusScreen.TINT[BodyCondition.Level.WOUNDED], "the left arm, wounded")
	assert_eq(s.tint_of("right_leg"), StatusScreen.TINT[BodyCondition.Level.CRITICAL], "the right leg, badly hurt")
	assert_eq(s.tint_of("head"), StatusScreen.TINT[BodyCondition.Level.FINE], "the rest fine")
	var lines := " ".join(s.effects())
	assert_string_contains(lines, "Limping")
	assert_string_contains(lines, "Pettibone", "and where to go")
	main._unhandled_input(_key(CityInput.MENU))
	assert_false(main.status_open, "Esc closes it")
	assert_false(main.paused)
	main._unhandled_input(_key(CityInput.STATUS))
	main._unhandled_input(_key(CityInput.STATUS))
	assert_false(s.visible, "and C again")


func test_walk_in_and_get_patched_up() -> void:
	walker().condition.shoot("torso", 0.5)
	var price: int = walker().condition.treatment_price()
	main.rackets.money = 3000
	var ok: bool = await walk_in_to(vet(), "pettibone")
	assert_true(ok, "walked into the animal hospital off Pruitt Street")
	assert_string_contains(main.hud.prompt_label.text, "Doc Pettibone")
	await press_e()
	assert_eq(main.talking, "pettibone")
	await answer_with("patch")
	assert_false(walker().condition.is_hurt(), "patched up")
	assert_eq(main.rackets.money, 3000 - price)
	main._unhandled_input(_key(CityInput.MENU))
	main._unhandled_input(_key(CityInput.STATUS))
	assert_eq(main.hud.status_screen.tint_of("torso"), StatusScreen.TINT[0], "and the status screen says so")
	main._unhandled_input(_key(CityInput.STATUS))


func test_going_down_he_comes_to_at_the_docs() -> void:
	main.rackets.money = 1200
	for i in 8:
		if main.collapses > 0:
			break
		walker().hit_by_bullet(walker().global_position + Vector2(0, 6), Vector2.UP, main.rival.body)
		await wait_physics_frames(1)
	assert_eq(main.collapses, 1)
	assert_true(vet().contains(walker().global_position), "on the Doc's premises")
	assert_eq(main.rackets.money, 1200 - main.COLLAPSE_FEE, "his fee")
	assert_string_contains(main.hud.wake_label.text, "Pettibone")


func test_the_morgue_is_a_landmark() -> void:
	var i: int = main.layout.building_named("The Morgue")
	assert_gt(i, -1)
	var b: Dictionary = main.layout.buildings[i]
	assert_true(b.signs.any(func(s: Dictionary) -> bool: return s.kind == "signs/morgue"), "its sign over the doors")
	assert_null(main.layout.interior_at((b.rect as Rect2).get_center()), "nobody goes in")
	var labels: Array = main.hud.city_map.landmarks.map(func(l: Dictionary) -> String: return l.label)
	assert_has(labels, "The Morgue", "on the ward map")
