extends "res://tests/support/city_test.gd"
## M015.12 the new quarters' landmark rooms in the game: the Canal Market
## Hall, the Golden Lantern and A. Feld's pawnshop in Canal Market; the
## Belvedere's lobby and the Paradise Ballroom in Lincoln Terrace. Each sits in
## its own building with its doors on open ground and a badge over the door;
## each is walked into through its door with the normal controls; every place
## to stand is reached round the furniture and E there talks or reads; its
## people are in; E at the door takes Danny out. Then what they do: Mrs.
## Dvorak's coffee holds the drowsiness off; Feld's box of rounds; a dance at
## the Paradise lets four minutes go by; the band plays from the bandstand,
## full inside and muffled outside, at the pace of the tune Danny asks for, and
## packs up at three; the dancers turn; a keeper won't deal with a gun out;
## a game saved in the ballroom goes on there with the night's dealings kept.

const ROOMS := {
	"market_hall": "market", "golden_lantern": "market", "pawnshop": "market",
	"belvedere": "terrace", "paradise": "terrace",
}

var _save := ""


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _plan_data(id: String) -> InteriorPlan:
	var l: DistrictLayout = main.world.layouts[ROOMS[id]]
	for p in l.interiors:
		if (p as InteriorPlan).id == id:
			return p
	return null


## The room's district built and Danny on the pavement before its door.
func _to(id: String) -> InteriorPlan:
	var data := _plan_data(id)
	main.world.load_now(ROOMS[id])
	walker().place(data.outside_door(0, 40.0), (-(data.doors[0].side as Vector2)).angle())
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	return main.interiors.plan_named(id)


## Stands Danny at `spot` in room `id` (its district built) and presses E.
func _talk(id: String, spot: String) -> void:
	await _to(id)
	await talk_to(id, spot)


func test_each_room_sits_in_its_building_with_its_door_on_open_ground_and_a_badge() -> void:
	for id in ROOMS:
		var p := _plan_data(id)
		assert_not_null(p, id)
		var l: DistrictLayout = main.world.layouts[ROOMS[id]]
		var b: Dictionary = l.buildings[p.building]
		assert_true((b.rect as Rect2).encloses(p.building_rect), "%s: its part of its building" % id)
		assert_true(p.building_rect.encloses(p.room), "%s: inside it" % id)
		assert_false(p.people.is_empty(), "%s: somebody is in" % id)
		assert_true(AssetCatalog.SPECS.has(p.marker), "%s: a badge (%s)" % [id, p.marker])
		main.world.load_now(ROOMS[id])
		for i in p.doors.size():
			var out := p.outside_door(i, 30.0)
			assert_false((b.rect as Rect2).has_point(out), "%s: door %d opens out of the building" % [id, i])
			assert_true(main.world.is_open_ground(out, 10.0), "%s: door %d opens on open ground" % [id, i])
			for lamp in l.lamps:
				assert_gt((lamp as Vector2).distance_to(out), 45.0, "%s: no lamp post in front of door %d" % [id, i])
			for pr in l.props:
				if (pr.has("box") or pr.has("radius")) and pr.kind != "props/el_column":
					assert_gt((pr.pos as Vector2).distance_to(out), 60.0, "%s: no %s in front of door %d" % [id, pr.kind, i])
		for s in p.spots:
			assert_false(path_in_room(p, p.inside_door(0, 14.0), s.pos, float(s.radius) - 10.0).is_empty(),
				"%s: %s can be walked to from the door" % [id, s.id])
		walker().place(main.layout.spawn, 0.0)
		await wait_physics_frames(1)


func test_walked_into_used_and_left_with_the_normal_controls() -> void:
	main.rackets.money = 2000
	for id in ROOMS:
		var p := await _to(id)
		assert_not_null(p, "%s is built with its district" % id)
		var v: InteriorView = main.interiors.view_of(id)
		for s in p.spots:
			assert_true(await walk_in_to(p, s.id), "%s: walked in to %s" % [id, s.id])
			assert_eq(main.interiors.current, p, "%s: inside" % id)
			assert_string_contains(main.hud.prompt_label.text, String(s.prompt))
			await press_e()
			assert_eq(main.dialogue.talking, s.id, "%s: E at %s" % [id, s.id])
			assert_ne(main.hud.line_label.text, "", "%s: %s has something to say" % [id, s.id])
			await answer_with("bye")
			assert_eq(main.dialogue.talking, "")
		await wait_physics_frames(30)
		assert_eq(v.alpha, 1.0, "%s: the roof off" % id)
		assert_eq(main.hud.place_label.text, p.name)
		for person in p.people:
			assert_true(v.person_ok(person.id), "%s: %s is in" % [id, person.id])
		for q in path_in_room(p, walker().global_position, p.inside_door(0, 14.0), 6.0):
			await walk_to(q, 4.0, 120)
		await walk_to(p.inside_door(0, 10.0), 4.0, 120)
		await press_e()
		await wait_physics_frames(3)
		assert_null(main.interiors.current, "%s: out by the door with E" % id)


func test_the_badges_hang_over_the_new_doors_and_on_the_maps() -> void:
	var on_map: Array = main.hud.minimap.places.map(func(pl: Dictionary) -> String: return pl.id)
	for id in ROOMS:
		var m: Dictionary = main.markers.marker_of(id)
		assert_false(m.is_empty(), "%s: a badge over its door" % id)
		assert_eq(m.plan.marker, _plan_data(id).marker)
		assert_has(on_map, id, "%s: its badge on the minimap and the city map" % id)
	# the badge shows as Danny comes up to the door
	var p := await _to("golden_lantern")
	await wait_physics_frames(20)
	assert_gt(float(main.markers.marker_of("golden_lantern").strength), 0.5, "bright at the door")


func test_mrs_dvoraks_coffee_holds_off_the_small_hours() -> void:
	main.clock.set_time(float(main.night_rules.drowsy_minute) + 30.0)
	await wait_physics_frames(2)
	var heavy: float = main.clock.drowsiness()
	assert_gt(heavy, 0.0, "half past four in the morning feels it")
	main.rackets.money = 100
	await _talk("market_hall", "dvorak")
	assert_eq(main.dialogue.talking, "dvorak")
	await answer_with("coffee")
	assert_eq(main.rackets.money, 95, "a nickel")
	await answer_with("bye")
	await wait_physics_frames(2)
	assert_lt(main.clock.drowsiness(), heavy, "the heaviness backs off")
	assert_has(main.soundscape.played, "places/cup", "the cup set down")


func test_feld_sells_a_box_of_rounds() -> void:
	main.rackets.money = 1000
	var gun := walker().gun
	gun.spare = 0
	await _talk("pawnshop", "feld")
	assert_eq(main.dialogue.talking, "feld")
	await answer_with("rounds")
	assert_eq(gun.spare, main.rackets.rules.ammo_box, "a box of .45s")
	assert_eq(main.rackets.money, 1000 - Quarters.FELD_BOX)
	await answer_with("bye")
	await talk_to("pawnshop", "feld")
	await answer_with("rounds")
	assert_string_contains(main.hud.line_label.text, "One box a night")
	assert_eq(gun.spare, main.rackets.rules.ammo_box, "one box a night")
	assert_eq(main.rackets.money, 1000 - Quarters.FELD_BOX)


func test_a_dance_lets_four_minutes_go_by() -> void:
	main.rackets.money = 100
	main.clock.set_time(22 * 60.0)
	await _talk("paradise", "ruby")
	var before: float = main.clock.minute
	await answer_with("ticket")
	assert_eq(main.rackets.money, 90, "a dime a dance")
	assert_almost_eq(main.clock.minute - before, Quarters.DANCE_MINUTES, 0.2, "four minutes on the floor")
	assert_eq(main.rackets.quarters.dances, 1)


func test_the_band_plays_inside_and_through_the_walls_and_packs_up_at_three() -> void:
	main.clock.set_time(22 * 60.0)
	var life: QuarterLife = main.quarter_life
	assert_null(life.band, "no band while the terrace is not built")
	var p := await _to("paradise")
	await wait_physics_frames(40)
	assert_not_null(life.band, "the band with the terrace")
	assert_true(life.band.playing, "playing")
	var outside := life.band.volume_db
	assert_lt(life.cutoff, 1000.0, "muffled through the walls")
	assert_true(await walk_in_to(p, "bandleader"))
	await wait_physics_frames(60)
	assert_gt(life.band.volume_db, outside + 4.0, "full on the floor")
	assert_gt(life.cutoff, 10000.0, "open")
	# the dancers turn
	var v: InteriorView = main.interiors.view_of("paradise")
	var at: Vector2 = v.people.dancer_a.global_position
	await wait_physics_frames(30)
	assert_gt(v.people.dancer_a.global_position.distance_to(at), 1.0, "the couples turn on the floor")
	# a request: the band's pace
	main.rackets.money = 100
	await press_e()
	assert_eq(main.dialogue.talking, "bandleader")
	await answer_with("tune_lake_shore")
	await wait_physics_frames(2)
	assert_eq(main.rackets.money, 95)
	assert_almost_eq(life.band.pitch_scale, 1.1, 0.001, "a quicker tune")
	await answer_with("bye")
	main.clock.set_time(27 * 60.0 + 1.0)
	await wait_physics_frames(3)
	assert_false(life.band.playing, "packed up at three")


func test_a_keeper_wont_deal_with_a_gun_out() -> void:
	main.rackets.money = 100
	await _to("market_hall")
	await wait_physics_frames(2)
	if not walker().gun.is_drawn():
		walker().gun.toggle_kept()
	await wait_physics_frames(2)
	await talk_to("market_hall", "dvorak")
	assert_eq(main.dialogue.talking, "dvorak")
	assert_string_contains(main.hud.line_label.text, "Put that away")
	assert_eq(main.rackets.money, 100)


func test_saved_in_the_ballroom_and_loaded_there() -> void:
	_save = OS.get_user_data_dir().path_join("test_landmarks_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	main.rackets.money = 100
	main.clock.set_time(22 * 60.0)
	await _talk("paradise", "ruby")
	await answer_with("ticket")
	await answer_with("bye")
	var at := walker().global_position
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = callouts
	main.save_path = _save
	main.settings_path = ""
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(10)
	assert_lt(walker().global_position.distance_to(at), 2.0, "where he was")
	assert_eq(main.world.current, "terrace")
	assert_not_null(main.interiors.current, "in the ballroom")
	assert_eq(main.interiors.current.id, "paradise")
	assert_eq(main.rackets.quarters.dances, 1, "tonight's dance remembered")
	assert_eq(main.rackets.money, 90)
	assert_true(main.rackets.quarters.met.has("ruby"))
	main.save_path = ""
