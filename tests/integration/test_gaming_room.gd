extends "res://tests/support/city_test.gd"
## M011 the Copper Owl's gaming room in the game: through the door in the
## card room's west wall (the card room keeps its table and its players), a
## room of its own in the house next door - the roof opens over it, the card
## room's closes - with the wheel table and its croupier, three machines along
## the back wall, small tables, players; the wheel and the machines are solid;
## the wheel's rail and each machine can be walked up to with the normal
## movement round the furniture and the people; and back the same way.


func _card_room() -> InteriorPlan:
	return main.interiors.view_of("back_room").plan


func _gaming_room() -> InteriorPlan:
	return main.interiors.view_of("gaming_room").plan


## The door index of `plan` that leads into the room `to_id`.
func _door_to(plan: InteriorPlan, to_id: String) -> int:
	for i in plan.doors.size():
		var other: InteriorPlan = main.layout.interior_at(plan.outside_door(i, 20.0))
		if other != null and other.id == to_id:
			return i
	return -1


## A path round the furniture and the people standing about (path_in_room plus the people).
func _path(plan: InteriorPlan, from: Vector2, to: Vector2, reach: float) -> Array:
	var keep := plan.furniture
	var extra := keep.duplicate()
	for p in plan.people:
		extra.append({"pos": p.pos, "radius": Walker.RADIUS + 2.0})
	plan.furniture = extra
	var out := path_in_room(plan, from, to, reach)
	plan.furniture = keep
	return out


func _walk_to_spot(plan: InteriorPlan, id: String) -> bool:
	var spot := {}
	for s in plan.spots:
		if s.id == id:
			spot = s
	var path := _path(plan, walker().global_position, spot.pos, float(spot.radius) - 8.0)
	if path.is_empty():
		return false
	for p in path:
		await walk_to(p, 4.0, 120)
	await wait_physics_frames(3)
	return plan.spot_at(walker().global_position).get("id", "") == id


func test_through_the_card_room_to_the_gaming_room_and_back() -> void:
	var card := _card_room()
	var gaming := _gaming_room()
	var west := _door_to(card, "gaming_room")
	assert_gte(west, 0, "a door in the card room's west wall")
	walker().place(card.inside_door(west, 10.0), PI)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	assert_eq(main.interiors.current, card)
	assert_string_contains(main.hud.prompt_label.text, "Through to The Copper Owl's Gaming Room")
	await press_e()
	await wait_physics_frames(20)
	assert_eq(main.interiors.current, gaming, "in the gaming room")
	var view: InteriorView = main.interiors.view_of("gaming_room")
	assert_almost_eq(view.alpha, 1.0, 0.01, "its roof open")
	assert_false(view.host.visible, "the house's roof gone while you are inside")
	assert_almost_eq(main.interiors.view_of("back_room").alpha, 0.0, 0.01, "the card room shut behind")
	assert_true((view.people.croupier as Walker).visible, "the croupier at the wheel")
	for id in ["player_a", "player_b", "drinker"]:
		assert_true((view.people[id] as Walker).visible, "%s about the room" % id)
	for kind in ["roulette_table", "roulette_rotor", "slot_machine_owl", "slot_machine_bell", "slot_machine_star", "side_table"]:
		assert_not_null(view.get_node_or_null(kind), "the %s is there" % kind)
	assert_true(main.markers.marker_of("gaming_room").is_empty(), "no badge on the street for it")
	assert_eq(main.hud.place_label.text, gaming.name, "the HUD says where he is")
	# back to the cards and on into the club
	walker().place(gaming.inside_door(0, 10.0), 0.0)
	await wait_physics_frames(3)
	assert_string_contains(main.hud.prompt_label.text, "Through to The Copper Owl's Back Room")
	await press_e()
	await wait_physics_frames(3)
	assert_eq(main.interiors.current, card, "back at the card table")
	var dbg := card.spot_at(RiversideInteriors.TABLE + Vector2(0, 54))
	assert_eq(dbg.get("id", ""), "poker", "the card game where it was")


func test_every_game_has_its_own_place_on_foot() -> void:
	var gaming := _gaming_room()
	walker().place(gaming.inside_door(0, 14.0), PI)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	assert_true(await _walk_to_spot(gaming, "roulette"), "up to the wheel's rail")
	for i in RiversideInteriors.SLOTS.size():
		assert_true(await _walk_to_spot(gaming, "slot_%d" % i), "up to the %s" % RiversideInteriors.SLOT_NAMES[i])
	# and back to the door
	var path := _path(gaming, walker().global_position, gaming.inside_door(0, 14.0), 8.0)
	assert_false(path.is_empty(), "a way back to the door")
	for p in path:
		await walk_to(p, 4.0, 120)
	assert_lt(walker().global_position.distance_to(gaming.inside_door(0, 14.0)), 16.0)


func test_the_wheel_and_the_machines_are_solid() -> void:
	var gaming := _gaming_room()
	# into the wheel table from Danny's side
	walker().place(RiversideInteriors.ROULETTE_SPOT, -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	await hold(Vector2.UP, 60)
	var table_bottom := RiversideInteriors.WHEEL_TABLE.y + 28.0
	assert_gt(walker().global_position.y, table_bottom + Walker.RADIUS - 2.0, "stopped at the table's edge")
	# into a machine
	walker().place(RiversideInteriors.SLOTS[1] + Vector2(0, 34), -PI / 2)
	await wait_physics_frames(3)
	await hold(Vector2.UP, 60)
	assert_gt(walker().global_position.y, RiversideInteriors.SLOTS[1].y + 14.0 + Walker.RADIUS - 2.0, "stopped at the machine")
	assert_eq(main.interiors.current, gaming)
