extends GutTest
## M014: places by stable id, district-local coordinates and the conversions at
## a district's boundary - the ids find the same world positions the M013 code
## had written into it as numbers, a district placed elsewhere takes its named
## places with it, and every door, room and spot of every district has an id.

var layouts: Array
var at: CityLocations


func before_all() -> void:
	layouts = CityPlan.layouts(RiversideWard.create())
	at = CityLocations.of(layouts)


func _layout(id: String) -> DistrictLayout:
	for l in layouts:
		if (l as DistrictLayout).id == id:
			return l
	return null


func test_the_named_places_are_where_the_numbers_were() -> void:
	assert_eq(at.at("riverside/place/lefty_post"), Vector2(1180, 1392), "Lefty's corner (M013: main.RIVAL_POST[0])")
	assert_eq(at.at("riverside/place/lefty_post_east"), Vector2(1330, 1392))
	assert_eq(at.at("riverside/place/bird_seat"), Vector2(2334, 262), "the end of the bar (M013: main.BIRD_SEAT)")
	assert_eq(at.at("yards/place/leon_at_dutch"), Vector2(3052, 1300 - 85.0 - 26.0) + RiverfrontYards.ORIGIN,
		"Leon at Dutch's (M013: Routines.LEON_AT_DUTCH + the yards' origin)")


func test_districts_are_written_locally_and_placed() -> void:
	var yards := _layout("yards")
	assert_eq(yards.origin, RiverfrontYards.ORIGIN)
	assert_eq(_layout("riverside").origin, RiversideWard.ORIGIN, "the ward is placed like the others (at zero)")
	assert_eq(_layout("halloran").origin, HalloranSquare.ORIGIN)
	for l in layouts:
		var p := Vector2(123.5, -42.25)
		assert_eq((l as DistrictLayout).to_local((l as DistrictLayout).to_world(p)), p, l.id)
		assert_eq((l as DistrictLayout).to_world(Vector2.ZERO), l.origin, l.id)
	assert_eq(yards.to_local(yards.place("leon_at_dutch")), Vector2(3052, 1300 - 85.0 - 26.0), "local again")


func test_a_district_placed_elsewhere_takes_its_places_with_it() -> void:
	var a := RiverfrontYards.create()
	var b := RiverfrontYards.create().shift(Vector2(1000, -500))
	assert_eq(b.place("leon_at_dutch") - a.place("leon_at_dutch"), Vector2(1000, -500))
	assert_eq(b.spawn - a.spawn, Vector2(1000, -500))
	assert_eq((b.interiors[0] as InteriorPlan).room.position - (a.interiors[0] as InteriorPlan).room.position, Vector2(1000, -500))
	var moved := CityLocations.of([b])
	assert_eq(moved.at("yards/place/leon_at_dutch"), a.place("leon_at_dutch") + Vector2(1000, -500))
	assert_eq(a.place("no_such_place"), Vector2.INF)


func test_every_door_room_spot_and_parking_place_has_an_id() -> void:
	for l in layouts:
		var d: String = l.id
		for p in l.interiors:
			var plan: InteriorPlan = p
			assert_true(at.has("%s/room/%s" % [d, plan.id]), plan.id)
			for i in plan.doors.size():
				assert_eq(at.at("%s/door/%s/%d" % [d, plan.id, i]), plan.outside_door(i), "%s door %d" % [plan.id, i])
			for s in plan.spots:
				assert_eq(at.at("%s/spot/%s/%s" % [d, plan.id, s.id]), s.pos as Vector2)
		assert_eq(at.ids(d + "/parking/").size(), l.cars.size(), d)
		for c in l.contacts:
			assert_eq(at.at("%s/contact/%s" % [d, c.id]), c.pos as Vector2)
		assert_eq(at.at(d + "/spawn"), l.spawn)
	assert_eq(at.at("halloran/cafe/car"), _layout("halloran").cafe_point("car").pos as Vector2, "the cafe job's places")
	assert_eq(at.at("nowhere/place/x"), Vector2.INF)
	assert_eq(CityLocations.district_of("yards/place/leon_at_dutch"), "yards")


func test_ids_are_unique_and_stable() -> void:
	var ids := at.ids()
	var unique := {}
	for id in ids:
		unique[id] = true
	assert_eq(unique.size(), ids.size())
	var again := CityLocations.of(CityPlan.layouts(RiversideWard.create()))
	assert_eq(again.ids(), ids, "the same ids every time the city is made")
	for id in ids:
		assert_eq(again.at(id), at.at(id), id)
