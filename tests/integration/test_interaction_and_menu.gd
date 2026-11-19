extends "res://tests/support/city_test.gd"
## M012 entrances, the highlight, the holster and the game menu in the game:
## a brass plate before every street door (warm where it opens, cold where it
## is shut, amber at the mayor's bell), brighter as Danny comes up, none at a
## door between two rooms, built and let go with their district; the ring
## under exactly what E would act on - a person, a door, a car, a bell - and
## nothing while he talks; H draws the gun and keeps it out, H puts it away,
## the rounds and the chosen gun kept; the click that ends a talk or closes the
## menu is never a shot; Esc opens the menu over a waiting world - the clock
## stopped - with the Notebook, Controls, Sound and Cheats pages, Save writes
## the game where he stands, Load asks for the last save, Esc goes back; at
## the card table Esc is the table's, not the menu's.

var _save := ""
var _shots := 0


func before_each() -> void:
	await super()
	_shots = 0
	main.player.fired.connect(func(_m: Vector2, _d: Vector2) -> void: _shots += 1)


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func _press_h() -> void:
	cmd = PlayerCommand.new()
	cmd.holster = true
	await wait_physics_frames(3)


func test_plates_at_the_street_doors() -> void:
	var ward_doors := 0
	for p in main.layout.interiors:
		for d in (p as InteriorPlan).doors:
			if not d.get("inner", false):
				ward_doors += 1
	assert_eq(main.plates.plates.filter(func(e: Dictionary) -> bool: return e.district == "riverside").size(), ward_doors,
		"one plate a street door in the ward")
	assert_true(main.plates.plates.all(func(e: Dictionary) -> bool: return e.kind == "open"), "every ward door opens")
	var gaming: InteriorPlan = main.interiors.plan_named("gaming_room")
	for d in gaming.doors:
		var at := gaming.door_centre(gaming.doors.find(d))
		assert_gt(main.plates.nearest(at).pos.distance_to(at), 40.0, "no plate gives away the gaming room's door")
	# Halloran Square's come with it: City Hall's open, the mayor's bell
	main.world.load_now("halloran")
	var gate: Dictionary = main.world.layouts.halloran.locked_doors[0]
	walker().place(gate.pos + Vector2(0, -20), PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	var bell: Dictionary = main.plates.nearest(gate.pos)
	assert_eq(bell.kind, "bell", "the mayor's gate: a bell")
	var s: Sprite2D = bell.node
	assert_gt(s.modulate.a, 0.9, "bright when he is at it")
	var far: Dictionary = main.plates.nearest(main.interiors.plan_named("regulars_club").outside_door(0, 7.0))
	assert_eq(far.kind, "open")
	assert_almost_eq((far.node as Sprite2D).modulate.a, EntrancePlates.FAR_ALPHA, 0.01, "dim across the square")
	assert_true(main.world.loaded.halloran.node.is_ancestor_of(s), "it goes with the district")
	walker().place(main.layout.spawn, 0.0)
	main.world.unload("halloran")
	assert_eq(main.plates.plates.filter(func(e: Dictionary) -> bool: return e.district == "halloran").size(), 0)


func test_the_ring_goes_under_what_e_would_do() -> void:
	# a person: Augie behind his bar
	await talk_to("copper_owl", "augie")
	await answer_with("bye")
	await wait_physics_frames(2)
	var augie: Walker = main.interiors.person("copper_owl", "augie")
	assert_eq(main.highlight.target.kind, "ring")
	assert_lt((main.highlight.target.pos as Vector2).distance_to(augie.global_position), 1.0, "under Augie")
	assert_false(main.highlight.target.get("cold", false))
	# talking: nothing
	await press_e()
	assert_eq(main.talking, "augie")
	await wait_physics_frames(2)
	assert_true(main.highlight.target.is_empty(), "nothing picked out while he talks")
	await answer_with("bye")
	# a door
	var owl: InteriorPlan = main.interiors.plan_named("copper_owl")
	walker().place(owl.outside_door(0, 12.0), -PI / 2)
	await wait_physics_frames(3)
	assert_eq(main.highlight.target.kind, "door", "the doorway")
	# a car he can get into
	var c: Car = roadster()
	walker().place(c.global_position + c.global_transform.y * -34.0, 0.0)
	await wait_physics_frames(3)
	if main.player.enterable_car() == c and main._spot().is_empty():
		assert_eq(main.highlight.target.kind, "car")
	# nothing in reach: nothing
	walker().place(STREETCAR_STOP + Vector2(0, 30), 0.0)
	await wait_physics_frames(3)
	if main._spot().is_empty() and main.player.enterable_car() == null:
		assert_true(main.highlight.target.is_empty())
	# the mayor's bell: warm, not the cold of a shut door
	main.world.load_now("halloran")
	var gate: Dictionary = main.world.layouts.halloran.locked_doors[0]
	walker().place(gate.pos, PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	assert_eq(main.highlight.target.kind, "ring")
	assert_false(main.highlight.target.cold, "a bell, not a locked door")


func test_h_draws_the_gun_and_keeps_it_out() -> void:
	walker().place(STREETCAR_STOP, 0.0)
	await wait_physics_frames(2)
	var rounds := walker().gun.ammo
	assert_false(walker().gun.is_drawn())
	await _press_h()
	await wait_physics_frames(30)
	assert_true(walker().gun.is_drawn(), "H: in hand")
	await wait_physics_frames(60 * 12)
	assert_true(walker().gun.is_drawn(), "kept out, unfired")
	assert_eq(_shots, 0)
	await _press_h()
	assert_false(walker().gun.is_drawn(), "H again: away")
	assert_eq(walker().gun.ammo, rounds, "every round kept")
	# with the Thompson on loan: H draws the gun he has chosen
	main.rackets.money = 2000
	main.rackets.borrow_thompson()
	main._arm_thompson(true)
	cmd = PlayerCommand.new()
	cmd.switch_gun = true
	await wait_physics_frames(3)
	assert_eq(walker().gun, main.thompson, "the Thompson chosen")
	await _press_h()
	await wait_physics_frames(30)
	assert_eq(walker().gun, main.thompson, "and drawn")
	assert_true(main.thompson.is_drawn())
	assert_eq(main.pistol.ammo, rounds, "the .45's rounds untouched")


func test_the_click_that_ends_a_talk_is_not_a_shot() -> void:
	await talk_to("copper_owl", "augie")
	assert_eq(main.talking, "augie")
	# the mouse button goes down on the last answer and is held a moment
	cmd = PlayerCommand.new()
	cmd.fire = true
	_fire_pending = true
	main._answer(main._page.options.size() - 1)
	await wait_physics_frames(10)
	assert_eq(main.talking, "")
	assert_eq(_shots, 0, "no shot from the click that ended it")
	cmd = PlayerCommand.new()
	await wait_physics_frames(3)
	await click(walker().global_position + Vector2(80, 0))
	await wait_physics_frames(40)
	assert_gt(_shots, 0, "the next click shoots as ever")


func test_the_menu_over_a_waiting_world() -> void:
	_save = OS.get_user_data_dir().path_join("test_menu_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	main.rackets.job.stage = RourkeJob.Stage.OFFERED
	walker().place(STREETCAR_STOP, 0.0)
	await wait_physics_frames(2)
	main._unhandled_input(_key(CityInput.MENU))
	var menu: GameMenu = main.hud.game_menu
	assert_true(menu.visible)
	assert_true(get_tree().paused, "the world waits")
	var minute: float = main.clock.minute
	await get_tree().create_timer(0.5, true, false, true).timeout
	assert_eq(main.clock.minute, minute, "the clock stopped")
	assert_eq(menu.notebook.filter(func(e: Dictionary) -> bool: return String(e.title).begins_with("Rourke")).size(), 1,
		"the Notebook: Rourke's offer (beside tonight's errands)")
	assert_eq(menu.notebook, Notebook.entries(main.rackets, main.clock.minute), "exactly what is under way tonight")
	# Save: written where he stands
	main.menu_action(menu.choose(1))
	assert_true(FileAccess.file_exists(_save))
	assert_string_contains(menu.status, "Saved")
	var saved: Dictionary = SaveGame.read(_save)
	assert_lt(Vector2(saved.place.x, saved.place.y).distance_to(walker().global_position), 1.0)
	# Load: back to the last save
	var asked := [0]
	main.reload_requested.connect(func() -> void: asked[0] += 1)
	main.menu_action(menu.choose(2))
	assert_eq(asked[0], 1, "Load asks for the last save")
	# the pages
	for id in ["notebook", "controls", "sound", "cheats"]:
		while menu.current() != id:
			main._unhandled_input(_key("ui_down"))
		main._unhandled_input(_key("ui_accept"))
		assert_eq(menu.page, id)
		main._unhandled_input(_key(CityInput.MENU))
		assert_eq(menu.page, "", "Esc: back to the list")
		assert_true(main.paused)
	main._unhandled_input(_key(CityInput.MENU))
	assert_false(main.paused, "Esc on the list: back to the street")
	assert_false(get_tree().paused)
	assert_true(main.player.fire_lock, "the click that closed it is not a shot")
	await wait_physics_frames(3)
	assert_eq(_shots, 0)


func test_at_the_card_table_esc_is_the_tables() -> void:
	await talk_to("back_room", "poker")
	assert_true(main.hud.poker_view.is_open())
	main._unhandled_input(_key(CityInput.MENU))
	await wait_physics_frames(2)
	assert_false(main.hud.game_menu.visible, "no menu over the cards")
	assert_false(main.paused)
