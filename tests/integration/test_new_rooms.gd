extends "res://tests/support/city_test.gd"
## M012 the new rooms: City Hall, Alderman Doran's office and the Regulars'
## Club in Halloran Square, Alderman Quilty's office in the ward, North Branch
## Freight's dispatch office and freight shed in the yards. Each sits inside
## its own building with its door on open ground; each is walked into through
## that door with the normal controls; every place to stand in it is reached on
## foot round the furniture, and E there talks or reads; its people are in;
## its walls hold; E at the door takes Danny back out. The depot's two rooms
## share one building and are sealed from each other. City Hall's stairs to
## the Mayor stay roped off.

const ROOMS := {
	"doran_office": "halloran", "city_hall": "halloran", "regulars_club": "halloran",
	"quilty_office": "riverside", "dispatch_office": "yards", "freight_shed": "yards",
}


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


func test_each_room_sits_in_its_building_with_its_door_on_open_ground() -> void:
	for id in ROOMS:
		var p := _plan_data(id)
		assert_not_null(p, id)
		var l: DistrictLayout = main.world.layouts[ROOMS[id]]
		var b: Dictionary = l.buildings[p.building]
		assert_true((b.rect as Rect2).encloses(p.building_rect), "%s: its part of its building" % id)
		assert_true(p.building_rect.encloses(p.room), "%s: inside it" % id)
		assert_false(p.people.is_empty(), "%s: somebody is in" % id)
		for i in p.doors.size():
			var out := p.outside_door(i, 30.0)
			assert_false((b.rect as Rect2).has_point(out), "%s: door %d opens out of the building" % [id, i])
			main.world.load_now(ROOMS[id])
			assert_true(main.world.is_open_ground(out, 10.0), "%s: door %d opens on open ground" % [id, i])
		for s in p.spots:
			assert_false(path_in_room(p, p.inside_door(0, 14.0), s.pos, float(s.radius) - 10.0).is_empty(),
				"%s: %s can be walked to from the door" % [id, s.id])
		walker().place(main.layout.spawn, 0.0)
		await wait_physics_frames(1)


func test_walked_into_used_and_left_with_the_normal_controls() -> void:
	main.rackets.money = 900
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
		# out by the door with E
		for q in path_in_room(p, walker().global_position, p.inside_door(0, 14.0), 6.0):
			await walk_to(q, 4.0, 120)
		await walk_to(p.inside_door(0, 10.0), 4.0, 120)
		await press_e()
		assert_null(main.interiors.current, "%s: back out in the street" % id)
	assert_eq(main.rackets.money, 900, "nothing changes hands by looking round")


func test_the_walls_hold() -> void:
	for id in ["city_hall", "regulars_club", "quilty_office", "dispatch_office"]:
		var p := await _to(id)
		walker().place(p.inside_door(0, 30.0), 0.0)
		await wait_physics_frames(2)
		var from := walker().global_position
		var side: Vector2 = p.doors[0].side
		# along the wall the door is in, both ways, then into the far wall
		await hold(side.orthogonal(), 160)
		assert_true(p.room.grow(-InteriorPlan.WALL + 1.0).has_point(walker().global_position), "%s: one side wall holds" % id)
		walker().place(from, 0.0)
		await hold(-side.orthogonal(), 160)
		assert_true(p.room.grow(-InteriorPlan.WALL + 1.0).has_point(walker().global_position), "%s: the other holds" % id)


func test_the_depots_two_rooms_are_sealed_from_each_other() -> void:
	var office := await _to("dispatch_office")
	var shed: InteriorPlan = main.interiors.plan_named("freight_shed")
	assert_eq(office.building, shed.building, "one building")
	assert_false(office.building_rect.intersects(shed.building_rect), "each its own part")
	var whole: Rect2 = main.world.layouts.yards.buildings[office.building].rect
	assert_eq(office.building_rect.merge(shed.building_rect), whole, "together the whole depot")
	# from the office, east into the rest of the depot: the wall holds
	walker().place(Vector2(office.room.end.x - 30.0, office.room.get_center().y), 0.0)
	await wait_physics_frames(2)
	await hold(Vector2.RIGHT, 200)
	assert_lt(walker().global_position.x, office.room.end.x, "the office's east wall")
	assert_eq(main.interiors.current, office)
	await wait_physics_frames(30)
	var host: BuildingView = main.interiors.view_of("dispatch_office").host
	assert_eq(main.interiors.view_of("freight_shed").host, host, "one building")
	assert_false(host.visible, "its roof stays off while Danny is in the office, whatever the shed's view does")
	# the closed middle of the depot is solid from the street side too
	walker().place(Vector2(whole.get_center().x, whole.position.y - 30.0), PI / 2)
	await wait_physics_frames(2)
	await hold(Vector2.DOWN, 120)
	assert_lt(walker().global_position.y, whole.position.y, "no way in through the depot's front between the rooms")
	assert_null(main.interiors.current)


func test_the_stairs_to_the_mayor_stay_roped_off() -> void:
	var hall := await _to("city_hall")
	var stairs := HalloranInteriors.CITY_HALL_STAIRS + HalloranSquare.ORIGIN
	assert_true(await walk_in_to(hall, "city_stairs"))
	await hold(Vector2.UP, 150)
	assert_gt(walker().global_position.y, stairs.y + 20.0, "the staircase is not a way up")
	assert_eq(main.interiors.current, hall)
	await press_e()
	assert_string_contains(main.hud.line_label.text, "BY APPOINTMENT")
	await answer_with("bye")
