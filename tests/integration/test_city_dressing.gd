extends "res://tests/support/city_test.gd"
## M010 the city's new grit, in the game: the rubbish is only paint (Danny
## walks over every piece of it; nothing solid lies where it is drawn); fences
## stand where you can see them and block exactly along the line they are
## drawn on; the shadows of the cars and of the people fall the same way as
## every other shadow, whichever way they face.


func _solid_at(p: Vector2) -> bool:
	var q := PhysicsPointQueryParameters2D.new()
	q.position = p
	q.collision_mask = Layers.WORLD
	q.collide_with_bodies = true
	for hit in main.get_world_2d().direct_space_state.intersect_point(q, 8):
		if hit.collider is StaticBody2D:
			return true
	return false


func _load_yards() -> DistrictLayout:
	var l: DistrictLayout = main.world.layouts.yards
	walker().place(l.contacts[0].pos + Vector2(0, 60), 0.0)
	main.camera.snap_to(walker())
	main.world.load_now("yards")
	return l


func test_the_rubbish_is_only_paint() -> void:
	var l := _load_yards()
	await wait_physics_frames(3)
	var checked := 0
	for layout in [main.layout, l]:
		var items: Array = (layout as DistrictLayout).grime_items()
		for k in range(0, items.size(), maxi(1, items.size() / 60)):
			assert_false(_solid_at(items[k].pos), "nothing solid under the %d at %s" % [items[k].frame, items[k].pos])
			checked += 1
	assert_gt(checked, 80)
	# and Danny walks straight over a piece of it
	var piece: Dictionary = main.layout.grime_items().filter(func(it: Dictionary) -> bool:
		return not main.layout.is_in_building(it.pos, 40.0))[0]
	walker().place(piece.pos + Vector2(-50, 0), 0.0)
	await walk_to(piece.pos + Vector2(50, 0), 6.0, 300)
	assert_lt(walker().global_position.distance_to(piece.pos + Vector2(50, 0)), 8.0, "walked over it")


func test_fences_seen_and_solid_along_their_line() -> void:
	var l := _load_yards()
	await wait_physics_frames(3)
	var city: City = main.world.city_of("yards")
	assert_not_null(city.get_node_or_null("Props/FenceTops"), "fences drawn from above")
	assert_not_null(city.get_node_or_null("Props/FenceFaces"), "and standing up")
	for f in l.fences:
		var a: Vector2 = f[0]
		var b: Vector2 = f[1]
		var mid := (a + b) * 0.5
		var side := (b - a).normalized().orthogonal()
		assert_true(_solid_at(mid), "solid on its line")
		for beside in [mid + side * 12.0, mid - side * 12.0]:
			if not l.is_in_building(beside):  # a fence may run along a works' wall
				assert_false(_solid_at(beside), "not beside it")
	var kinds := {}
	for f in l.fences:
		kinds[String(f[2]) if (f as Array).size() > 2 else "boards"] = true
	assert_true(kinds.has("chain") and kinds.has("boards"), "chain-link round the works, boards round the sidings (%s)" % [kinds.keys()])


func test_shadows_fall_one_way() -> void:
	var c: Car = main.fleet.my_car()
	for rot in [0.0, PI / 2, PI, -2.3]:
		await park(c, c.global_position, rot)
		var shadow: Sprite2D = c.get_node("Shadow")
		var off := shadow.global_position - c.global_position
		assert_almost_eq(off.angle_to(Shadows.DIR), 0.0, 0.01, "the car's shadow falls the same way at %.1f" % rot)
	var w := walker()
	var ws: Sprite2D = null
	for ch in w.get_children():
		if ch is Sprite2D and (ch as Sprite2D).texture == SoftShadow.texture():
			ws = ch
	assert_not_null(ws)
	assert_almost_eq(ws.position.angle_to(Shadows.DIR), 0.0, 0.01, "and Danny's")
	assert_not_null(main.city.get_node_or_null("Ground/BuildingShadows"))
	assert_not_null(main.city.get_node_or_null("Ground/Grime"))
