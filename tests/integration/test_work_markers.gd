extends "res://tests/support/city_test.gd"
## M015 where Danny's work points, in the game: a quiet mark at the place in
## the street (at the person while Danny is in their room), an arrow at the
## edge of the view for known work out of sight - none for a hunch, none for
## hidden work - the same work on the minimap and the city map; the Notebook
## page is the case sheets (Left / Right through them; Enter switches the
## street marks off and on, a preference). Done work drops its marks.


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func _refresh() -> void:
	main.casework.refresh()
	await wait_process_frames(2)


func _owl_door() -> Vector2:
	return main.game.locations.at(Casebook.OWL_DOOR)


func test_rourkes_offer_is_marked_at_the_copper_owl() -> void:
	main.rackets.job.stage = RourkeJob.Stage.OFFERED
	walker().place(_owl_door() + Vector2(0, 120), 0.0)
	main.camera.snap_to(walker())
	await _refresh()
	assert_eq(main.casework.marks.size(), 1)
	assert_lt((main.casework.marks[0].pos as Vector2).distance_to(_owl_door()), 1.0, "at the club's door from the street")
	assert_true(main.casework.marks[0].sure)
	assert_eq(main.work_markers.marks, main.casework.marks, "drawn in the street")
	assert_eq(main.hud.minimap.work, main.casework.marks, "and on the minimap")
	assert_eq(main.hud.city_map.work, main.casework.marks, "and on the city map")
	assert_eq(main.hud.city_map.work_cases, ["Collecting at Lindqvist's"])
	assert_eq(main.hud.work_arrows.arrows, [], "in view: no arrow")


func test_inside_the_room_the_mark_is_at_rourke() -> void:
	main.rackets.job.stage = RourkeJob.Stage.OFFERED
	assert_true(await walk_in_to(main.interiors.plan_named("copper_owl"), "augie"))
	await _refresh()
	assert_lt((main.casework.marks[0].pos as Vector2).distance_to(main.game.locations.at(Casebook.ROURKE)), 1.0)


func test_known_work_out_of_sight_gets_an_arrow_a_hunch_does_not() -> void:
	main.rackets.job.stage = RourkeJob.Stage.OFFERED
	var lefty_corner: Vector2 = main.game.locations.at(Casebook.LEFTY)
	walker().place(lefty_corner + Vector2(0, 60), 0.0)
	main.camera.snap_to(walker())
	await _refresh()
	await wait_process_frames(3)
	var arrows: Array = main.hud.work_arrows.arrows
	assert_eq(arrows.size(), 1, "the Copper Owl is out of sight")
	var toward := (_owl_door() - walker().global_position).normalized()
	assert_gt((arrows[0].dir as Vector2).dot(toward), 0.8, "pointing the way")
	assert_eq(String(arrows[0].label), "Rourke")
	main.rackets.job.stage = RourkeJob.Stage.NOT_OFFERED
	main.rackets.memory.remember("dutch", "deal", main.rackets.night)
	main.rackets.opportunities.crate = "waiting"
	main.clock.set_time(21 * 60.0)
	await _refresh()
	await wait_process_frames(3)
	assert_eq(main.casework.marks.size(), 1, "a hunch about Dutch")
	assert_false(main.casework.marks[0].sure)
	assert_eq(main.hud.work_arrows.arrows, [], "no arrow for a hunch")


func test_hidden_and_done_work_has_no_marks() -> void:
	main.rackets.opportunities.crate = "waiting"  # Dutch has a crate, but Danny has never met him
	main.clock.set_time(21 * 60.0)
	await _refresh()
	assert_eq(main.casework.marks, [])
	main.rackets.job.stage = RourkeJob.Stage.REPORTED
	main.rackets.job.outcome = "deal"
	main.rackets.job.told = "deal"
	await _refresh()
	assert_eq(main.casework.marks, [], "settled and told")
	assert_eq(main.casework.sheets.size(), 1, "but kept in the notebook")


func test_the_notebook_page_is_the_case_sheets() -> void:
	main.rackets.job.stage = RourkeJob.Stage.ACCEPTED
	main.rackets.loan.out = true
	main._unhandled_input(_key(CityInput.MENU))
	var menu: GameMenu = main.hud.game_menu
	while menu.current() != "notebook":
		main._unhandled_input(_key("ui_down"))
	main._unhandled_input(_key("ui_accept"))
	assert_eq(menu.page, "notebook")
	assert_eq(menu.cases, Casebook.cases(main.rackets, main.clock.minute))
	assert_eq(menu.cases.size(), 2)
	assert_eq(menu.case_index, 0)
	main._unhandled_input(_key("ui_right"))
	assert_eq(menu.case_index, 1, "the next sheet")
	assert_eq(menu.page, "notebook", "still on the page")
	assert_true(main.casework.shown())
	main._unhandled_input(_key("ui_accept"))
	assert_false(main.casework.shown(), "Enter: no marks in the street")
	assert_false(main.work_markers.shown)
	assert_false(menu.markers_on)
	main._unhandled_input(_key("ui_accept"))
	assert_true(main.casework.shown(), "and back on")
	main._unhandled_input(_key(CityInput.MENU))
	main._unhandled_input(_key(CityInput.MENU))
	assert_false(main.modals.paused)
