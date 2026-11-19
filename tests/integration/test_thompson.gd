extends "res://tests/support/city_test.gd"
## M010 Eddie's Thompson and the parcel in the game: borrowed from Eddie for
## the deposit, Tab takes it in hand (and back to the .45), held down it fires
## bursts with its own rounds and is heard further off than the pistol, it
## stays on loan through a save and a night's sleep, it goes back to Eddie for
## the deposit less his dollar; the parcel is bought only when the job wants
## it, shows by the purse and is kept in the save.

const SAVE := "user://test_thompson_save.json"


func _borrow() -> void:
	main.rackets.money = 2000
	await talk_to("hardware", "eddie")
	await answer_with("wares")
	await answer_with("heavy")
	await answer_with("borrow")
	await press_e()  # walk away
	await wait_physics_frames(2)


func _reload_game() -> void:
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = callouts  # M012: as in before_each
	main.save_path = SAVE
	main.settings_path = ""
	main.opening_enabled = false
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(3)


func after_each() -> void:
	super()
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_borrow_switch_and_fire_a_burst() -> void:
	await _borrow()
	assert_eq(main.rackets.money, 1500, "five dollars down")
	assert_not_null(main.thompson, "on loan")
	assert_eq(walker().gun, main.pistol, "the .45 still in hand")
	assert_string_contains(main.hud.notice_label.text, "Tab")
	# out into the street, Tab, and a burst
	walker().place(STREETCAR_STOP, 0.0)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	cmd.switch_gun = true
	await wait_physics_frames(2)
	assert_eq(walker().gun, main.thompson, "Tab: the Thompson in his hands")
	var shots := [0]
	main.player.fired.connect(func(_m: Vector2, _d: Vector2) -> void: shots[0] += 1)
	cmd = PlayerCommand.make(Vector2.ZERO, false, false, STREETCAR_STOP + Vector2(0, 200))
	cmd.fire = true
	_fire_pending = true
	var f0 := Engine.get_physics_frames()
	while Engine.get_physics_frames() - f0 < 21 + 60:  # drawn (0.35 s), then a second held
		await wait_physics_frames(1)
	cmd.fire = false
	await wait_physics_frames(10)
	assert_between(shots[0], 9, 12, "a held burst: about ten rounds a second (%d)" % shots[0])
	assert_eq(main.thompson.ammo + main.thompson.spare, 60 - shots[0], "its own rounds")
	assert_eq(main.pistol.ammo, 7, "the .45 untouched")
	assert_string_contains(main.hud.gun_label.text, "Thompson")
	cmd.switch_gun = true
	await wait_physics_frames(2)
	assert_eq(walker().gun, main.pistol, "Tab again: back to the .45")


func test_heard_further_off_than_the_pistol() -> void:
	await _borrow()
	var o: PoliceOfficer = main.officer
	var off := o.body.global_position + Vector2(0, 0)
	var far := Vector2(820, 0)  # beyond a .45's 720 px, inside the Thompson's 950
	assert_false(o.hear_gunshot(off + far, main.pistol.rules.noise_radius), "a .45 that far off goes unheard")
	o.reset()
	assert_true(o.hear_gunshot(off + far, main.thompson.rules.noise_radius), "the Thompson does not")


func test_on_loan_through_a_save_and_a_night() -> void:
	main.save_path = SAVE
	await _borrow()
	main.thompson.ammo = 13
	main.thompson.spare = 20
	await _reload_game()
	assert_not_null(main.thompson, "still on loan after loading")
	assert_eq(main.thompson.ammo, 13)
	assert_eq(main.thompson.spare, 20)
	assert_eq(main.player.arsenal.size(), 2)
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	assert_not_null(main.thompson, "and after a night's sleep")
	# back to Eddie
	var before: int = main.rackets.money
	await talk_to("hardware", "eddie")
	await answer_with("give_back")
	await press_e()
	await wait_physics_frames(2)
	assert_null(main.thompson, "back with Eddie")
	assert_eq(main.player.arsenal.size(), 1)
	assert_eq(walker().gun, main.pistol)
	assert_eq(main.rackets.money, before + 400, "the deposit less his dollar")


func test_the_parcel() -> void:
	main.save_path = SAVE
	main.rackets.money = 1000
	await talk_to("hardware", "eddie")
	await answer_with("wares")
	var ids: Array = main._page.options.map(func(o: Dictionary) -> String: return o.id)
	assert_false(ids.has("parcel"), "not without the job")
	await press_e()
	main.rackets.parcel_wanted = true
	await talk_to("hardware", "eddie")
	await answer_with("wares")
	await answer_with("parcel")
	assert_eq(main.rackets.money, 400)
	assert_eq(main.rackets.parcels, 1)
	await press_e()
	await wait_physics_frames(2)
	assert_string_contains(main.hud.purse_label.text, "a parcel")
	assert_true(main.hud.item_icon.visible, "its badge by the purse")
	await _reload_game()
	assert_eq(main.rackets.parcels, 1, "kept in the save")
	assert_true(main.hud.item_icon.visible)
