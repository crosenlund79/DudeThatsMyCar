extends GutTest
## The Riverside Ward layout as data: buildings never overlap, every look it
## asks for exists, the player and the parked cars start on open ground, the
## landmarks are there, lamps stand on the pavement, places have names.

var d: DistrictLayout


func before_all() -> void:
	d = RiversideWard.create()


func test_buildings_never_overlap() -> void:
	assert_eq(d.overlapping_buildings(), [], "touching is fine, overlapping is not")


func test_every_building_uses_catalogued_art() -> void:
	for b in d.buildings:
		assert_gt(b.storeys, 0)
		assert_true(AssetCatalog.SPECS.has("facades/" + b.facade), b.facade)
		assert_true(AssetCatalog.SPECS.has("roofs/" + b.roof), b.roof)
		for p in b.props:
			assert_true(AssetCatalog.SPECS.has(p.kind), p.kind)
			assert_true((b.rect as Rect2).has_point(p.pos), "%s sits on its own roof" % p.kind)
	for p in d.props:
		assert_true(AssetCatalog.SPECS.has(p.kind), p.kind)
	for dcl in d.decals:
		assert_true(AssetCatalog.SPECS.has(dcl.kind), dcl.kind)


func test_landmarks_are_there() -> void:
	var names := d.buildings.map(func(b: Dictionary) -> String: return b.name)
	for n in ["The Copper Owl", "Hotel Marlowe", "Doyle's Garage", "Lakeshore Cold Storage", "Marlowe Avenue Bridge"]:
		assert_has(names, n)
	var club: Dictionary = d.buildings[names.find("The Copper Owl")]
	assert_eq(club.facade, "club")
	assert_eq(club.signs.size(), 1, "rooftop sign")
	assert_true(d.props.any(func(p: Dictionary) -> bool: return p.kind == "props/marquee"), "the canopy over the sidewalk")


func test_the_player_starts_at_home_with_the_street_outside() -> void:
	var home := d.interior_at(d.spawn)
	assert_not_null(home, "the night starts indoors")
	assert_eq(home.id, "home")
	assert_true(home.contains(d.spawn, -Walker.RADIUS - InteriorPlan.WALL), "clear of the walls")
	assert_eq(d.place_name(home.outside_door(0)), "Marlowe Avenue")


func test_a_car_waits_a_few_steps_from_the_front_door() -> void:
	var door := d.interior_at(d.spawn).outside_door(0)
	var nearest := INF
	for c in d.cars:
		nearest = minf(nearest, (c.pos as Vector2).distance_to(door))
	assert_lt(nearest, 160.0, "walk over to a car")
	assert_gt(nearest, 60.0, "but not standing on it")


func test_parked_cars_stand_on_open_ground_and_apart() -> void:
	assert_gte(d.cars.size(), 4)
	var types := {}
	for c in d.cars:
		types[c.type] = true
		var t := Transform2D(c.rot, c.pos)
		for corner in [Vector2(40, 18), Vector2(40, -18), Vector2(-40, 18), Vector2(-40, -18)]:
			assert_true(d.is_open_ground(t * corner), "car at %s fits on open ground" % c.pos)
	assert_true(types.has("sedan") and types.has("coupe"), "both period cars are parked somewhere")
	for i in d.cars.size():
		for j in range(i + 1, d.cars.size()):
			assert_gt((d.cars[i].pos as Vector2).distance_to(d.cars[j].pos), 60.0)


func test_lamps_stand_on_open_ground() -> void:
	assert_gt(d.lamps.size(), 40)
	for p in d.lamps:
		assert_false(d.is_in_building(p, 4.0), "lamp at %s" % p)
		assert_false(d.is_in_water(p), "lamp at %s" % p)


func test_alleys_open_onto_streets() -> void:
	for a in d.alleys:
		var r: Rect2 = a.rect
		var ends := [Vector2(r.position.x - 2.0, r.get_center().y), Vector2(r.end.x + 2.0, r.get_center().y)]
		for e in ends:
			assert_true(d.streets.any(func(s: Dictionary) -> bool: return (s.rect as Rect2).grow(50.0).has_point(e)),
				"%s reaches a street at %s" % [a.name, e])


func test_places_have_names() -> void:
	assert_eq(d.place_name(Vector2(1650, 600)), "Kessler St & Marlowe Ave")
	assert_eq(d.place_name(Vector2(800, -300)), "Calloway Street")
	assert_true(d.place_name(Vector2(800, 135)).begins_with("Alley"))
