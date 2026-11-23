extends "res://tests/support/city_test.gd"
## M004 markers over the doors of the places you can walk into: every one of
## the five has one (the flat its own house-shaped badge), they show from a
## block away and grow clearer as you come near on foot or in a car, the one
## whose door you stand at pulses, and the place you are in hides its own.


func markers() -> PlaceMarkers:
	return main.markers


func _frame() -> void:
	await wait_process_frames(2)


func test_the_places_are_marked() -> void:
	var ids := markers().markers.map(func(m: Dictionary) -> String: return (m.plan as InteriorPlan).id)
	ids.sort()
	assert_eq(ids, ["barber_shop", "belvedere", "copper_owl", "golden_lantern", "grocery", "hardware", "home", "market_hall",
		"paradise", "pawnshop", "union_hall", "vet"],
		"the five of M004, the vet (M006), the union hall (M011) and the new quarters' five (M015)")
	var home: Dictionary = markers().marker_of("home")
	assert_eq(home.plan.marker, "ui/marker_home")
	for m in markers().markers:
		if not (m.plan as InteriorPlan).is_home:
			assert_ne(m.plan.marker, "ui/marker_home", "businesses look different from your flat")


func test_strength_grows_as_you_come_near() -> void:
	assert_eq(PlaceMarkers.strength_at(0.0), 1.0)
	assert_eq(PlaceMarkers.strength_at(PlaceMarkers.FAR + 1.0), 0.0)
	var last := 2.0
	for d in [100.0, 300.0, 500.0, 700.0, 900.0]:
		var s := PlaceMarkers.strength_at(d)
		assert_lte(s, last)
		last = s


func test_at_home_the_flat_hides_its_marker_and_the_club_shows() -> void:
	await _frame()
	assert_eq(main.interiors.current.id, "home")
	assert_false(markers().marker_of("home").node.visible, "no marker over the place you are in")
	assert_true(markers().marker_of("copper_owl").node.visible, "the club next door is marked")
	assert_false(markers().marker_of("barber_shop").node.visible, "Sal's is too far to see yet")


func test_walking_up_to_a_door_brings_its_marker_up_and_it_pulses() -> void:
	var plan: InteriorPlan = main.interiors.view_of("grocery").plan
	walker().place(Vector2(1650, 300), PI / 2)  # up Kessler Street, a block away
	await _frame()
	var far: float = markers().marker_of("grocery").strength
	assert_between(far, 0.05, 0.95, "faint from a block away")
	await walk_to(plan.outside_door(0, 14.0), 4.0, 300)
	await _frame()
	var m: Dictionary = markers().marker_of("grocery")
	assert_gt(m.strength, far, "clearer up close")
	assert_eq(m.strength, 1.0)
	assert_string_contains(main.hud.prompt_label.text, "Enter Novak's Grocery")
	var scale_at_door: float = (m.node as Node2D).scale.x
	assert_gt(scale_at_door, 1.05, "the door you stand at is the one that pulses")
	await press_e()
	await _frame()
	assert_false((m.node as Node2D).visible, "inside, its marker is gone")


func test_driving_past_the_markers_light_up() -> void:
	var c := car_of_type("sedan")
	await park(c, Vector2(200, 555), 0.0)  # westbound lane of Marlowe, far west
	await seat_in(c)
	await _frame()
	var start: float = markers().marker_of("barber_shop").strength
	await drive_route(c, [Vector2(700, 555), Vector2(1000, 555)], 160.0, 60 * 10)
	await _frame()
	var near: float = markers().marker_of("barber_shop").strength
	assert_gt(near, start, "Sal's marker comes up as you drive towards it")
	assert_gt(near, 0.8)
	assert_true(markers().marker_of("barber_shop").node.visible)
