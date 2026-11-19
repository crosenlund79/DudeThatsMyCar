extends "res://tests/support/city_test.gd"
## M011 the city's powers, by name and in stone, in the game: City Hall facing
## Halloran Park across Pruitt Street (limestone, its copper cupola, granite
## steps between globe lamps; its doors locked at night with the mayor's
## window lit); the mayor's house a few doors along, set back behind a garden
## and a railing with a gate; Alderman Doran's ward office and the Regulars'
## Club in Halloran Square, Alderman Quilty's office in the ward. Each can be
## tried at the door and says why it is shut; nothing changes hands; every
## one is named on the city map (the mayor's house with its address). No
## elections, no influence, no bribes.


func _halloran() -> DistrictLayout:
	return main.world.layouts.halloran


func _named(d: DistrictLayout, n: String) -> Dictionary:
	return d.buildings[d.building_named(n)]


func test_city_hall_and_the_mayors_house_stand_as_built() -> void:
	var h := _halloran()
	var hall := _named(h, HalloranSquare.CITY_HALL)
	assert_eq(hall.facade, "civic", "limestone, not flats")
	assert_eq(hall.storeys, 4)
	assert_eq(hall.front, Vector2.UP, "it faces Pruitt Street")
	assert_true(hall.props.any(func(p: Dictionary) -> bool: return p.kind == "roof/cupola"), "its copper cupola")
	assert_true(hall.signs.any(func(sg: Dictionary) -> bool: return sg.kind == "signs/city_hall"))
	var park: Vector2 = h.landmarks.filter(func(l: Dictionary) -> bool: return l.label == "Halloran Park")[0].pos
	assert_lt(absf((hall.rect as Rect2).get_center().x - park.x), 100.0, "straight across from the park")
	assert_gt((hall.rect as Rect2).position.y, park.y, "south of it")
	var house := _named(h, HalloranSquare.MAYOR)
	assert_eq(house.facade, "townhouse")
	var front_y: float = (house.rect as Rect2).position.y
	var garden := false
	for l in h.lots:
		if l.kind == "grass" and absf((l.rect as Rect2).end.y - front_y) < 1.0:
			garden = true
	assert_true(garden, "a garden in front of it")
	var railing := 0
	for f in h.fences:
		if f.size() > 2 and f[2] == "iron" and absf((f[0] as Vector2).y - (front_y - 66.0)) < 6.0:
			railing += 1
	assert_gte(railing, 2, "a railing with a gate")
	for n in [HalloranSquare.DORAN, HalloranSquare.REGULARS]:
		assert_gte(h.building_named(n), 0, "%s in the square" % n)
	assert_gte(main.layout.building_named(RiversideWard.QUILTY), 0, "the ward's alderman")


func test_the_doors_say_why_they_are_shut() -> void:
	main.rackets.money = 900
	var h := _halloran()
	main.world.load_now("halloran")
	var expect := {HalloranSquare.CITY_HALL: "Mayor's office", HalloranSquare.MAYOR: "Mayor Dunleavy",
		HalloranSquare.DORAN: "DORAN", HalloranSquare.REGULARS: "REGULARS"}
	for l in h.locked_doors:
		walker().place(l.pos, PI / 2)
		main.camera.snap_to(walker())
		await wait_physics_frames(3)
		assert_string_contains(main.hud.prompt_label.text, String(l.prompt))
		await press_e()
		assert_string_contains(main.hud.notice_label.text, String(l.text).substr(0, 20))
	assert_eq(h.locked_doors.size(), 4, "City Hall, the mayor's gate, Doran's office, the Regulars' Club")
	for n in expect:
		assert_true(h.locked_doors.any(func(l: Dictionary) -> bool: return String(l.text).contains(expect[n])), "%s's door" % n)
	# the ward's alderman
	var q: Dictionary = main.layout.locked_doors[0]
	walker().place(q.pos, -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	await press_e()
	assert_string_contains(main.hud.notice_label.text, "QUILTY")
	assert_eq(main.rackets.money, 900, "nothing changes hands")
	assert_eq(main.talking, "", "no one to talk to")


func test_named_on_the_city_map() -> void:
	var m := InputEventAction.new()
	m.action = CityInput.MAP
	m.pressed = true
	main._unhandled_input(m)
	var labels: Array = main.hud.city_map.building_labels.map(func(l: Dictionary) -> String: return String(l.label))
	for n in [HalloranSquare.CITY_HALL, HalloranSquare.DORAN, HalloranSquare.REGULARS, RiversideWard.QUILTY, RiversideWard.UNION_HALL]:
		assert_has(labels, n)
	var mayor: Array = labels.filter(func(l: String) -> bool: return l.begins_with(HalloranSquare.MAYOR))
	assert_eq(mayor.size(), 1, "the mayor's house")
	assert_string_contains(mayor[0], "Pruitt St", "with its address")
	main._unhandled_input(m)
