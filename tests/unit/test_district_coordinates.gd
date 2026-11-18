extends GutTest
## M008 one world for every district: a district is drawn up in its own
## coordinates and placed at its origin; everything in it moves together and
## the conversion both ways is exact. The Riverside Ward stays where it was.

const Toy := preload("res://tests/support/toy_district.gd")


func test_everything_moves_with_the_origin() -> void:
	var here := Toy.make("a", Vector2.ZERO, "", "b")
	var there := Toy.make("a", Vector2(5000, -700), "", "b")
	var off := Vector2(5000, -700)
	assert_eq(there.origin, off)
	assert_eq(there.bounds.position, here.bounds.position + off)
	assert_eq(there.play_area.position, here.play_area.position + off)
	assert_eq(there.streets[0].rect.position, here.streets[0].rect.position + off)
	assert_eq(there.blocks[1].position, here.blocks[1].position + off)
	assert_eq(there.buildings[3].rect.position, here.buildings[3].rect.position + off)
	assert_eq(there.buildings[3].props[0].pos, here.buildings[3].props[0].pos + off, "rooftop furniture too")
	assert_eq(there.lamps[2], here.lamps[2] + off)
	assert_eq(there.props[0].pos, here.props[0].pos + off)
	assert_eq(there.decals[0].pos, here.decals[0].pos + off)
	assert_eq(there.cars[0].pos, here.cars[0].pos + off)
	assert_eq(there.police_beat[1], here.police_beat[1] + off)
	assert_eq(there.walk_routes[0][1], here.walk_routes[0][1] + off)
	assert_eq(there.exits[0].rect.position, here.exits[0].rect.position + off)
	assert_eq(there.landmarks[0].pos, here.landmarks[0].pos + off)
	assert_eq(there.spawn, here.spawn + off)


func test_local_and_world_round_trip() -> void:
	var d := Toy.make("a", Vector2(-4900, -1300))
	for p in [Vector2.ZERO, Vector2(123.5, -77.25), Vector2(-4900, -1300), Vector2(9999, 4321)]:
		assert_eq(d.to_world(d.to_local(p)), p)
	assert_eq(d.to_world(Vector2.ZERO), Vector2(-4900, -1300), "its own top-left corner")
	assert_eq(d.to_local(d.buildings[0].rect.position), Toy.make("a", Vector2.ZERO).buildings[0].rect.position)


func test_placing_twice_adds_up() -> void:
	var d := Toy.make("a", Vector2(100, 0))
	d.shift(Vector2(0, 250))
	assert_eq(d.origin, Vector2(100, 250))
	assert_eq(d.bounds.position, Vector2(100, 250))


func test_the_riverside_ward_stays_at_the_origin() -> void:
	var r := RiversideWard.create()
	assert_eq(r.id, "riverside")
	assert_eq(r.origin, Vector2.ZERO)
	assert_eq(r.spawn, Vector2(2522, 384), "Danny's flat where it always was")
