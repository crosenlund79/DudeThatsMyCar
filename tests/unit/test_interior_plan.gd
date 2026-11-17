extends GutTest
## M003 rooms you can walk into (InteriorPlan): the walls close the room
## except at its doors, the rest of the house stays solid, inner walls have
## doorways, and in the Riverside Ward every room has a way in, people
## standing in the open and a clear walk from the door to every spot.

const STEP := 6.0


func _plan() -> InteriorPlan:
	var p := InteriorPlan.new("test", "Test")
	p.building_rect = Rect2(0, 0, 300, 200)
	p.room = Rect2(0, 60, 200, 140)  # the front part of the house, west end
	p.doors = [{"side": Vector2.DOWN, "at": 100.0, "width": 28.0}]
	p.partitions = [{"a": Vector2(120, 60), "b": Vector2(120, 200), "door_at": 130.0, "door_width": 26.0}]
	p.spots = [{"id": "bed", "pos": Vector2(40, 100), "radius": 30.0, "prompt": "Sleep"}]
	return p


func _in_any(boxes: Array[Rect2], q: Vector2) -> bool:
	for b in boxes:
		if b.has_point(q):
			return true
	return false


func test_the_walls_close_the_room_except_at_the_doors() -> void:
	var p := _plan()
	var walls := p.wall_boxes()
	assert_false(_in_any(walls, p.door_centre(0)), "the doorway is open")
	assert_true(_in_any(walls, Vector2(30, 196)), "the front wall beside the door")
	assert_true(_in_any(walls, Vector2(170, 196)))
	assert_true(_in_any(walls, Vector2(2, 120)), "the side wall")
	assert_true(_in_any(walls, Vector2(198, 120)))
	assert_true(_in_any(walls, Vector2(60, 62)), "the back wall")
	assert_false(_in_any(walls, Vector2(60, 120)), "the room is free")
	assert_almost_eq(p.outside_door(0, 10.0).y, 200.0 + 10.0, 0.01, "outside means beyond the wall")
	assert_true(p.contains(p.inside_door(0)))


func test_inner_walls_have_doorways() -> void:
	var p := _plan()
	var walls := p.wall_boxes()
	assert_true(_in_any(walls, Vector2(120, 80)), "the partition")
	assert_true(_in_any(walls, Vector2(120, 170)))
	assert_false(_in_any(walls, Vector2(120, 130)), "with its doorway")


func test_the_rest_of_the_house_stays_solid() -> void:
	var p := _plan()
	var solid := p.solid_boxes()
	assert_true(_in_any(solid, Vector2(150, 30)), "behind the room")
	assert_true(_in_any(solid, Vector2(250, 150)), "beside it")
	assert_false(_in_any(solid, Vector2(60, 120)), "but not the room")


func test_spots_answer_only_within_reach() -> void:
	var p := _plan()
	assert_eq(p.spot_at(Vector2(50, 110)).id, "bed")
	assert_true(p.spot_at(Vector2(150, 150)).is_empty())


## Walkable cells of a room for a person of `radius`, as a flood fill from `from`.
func _reach(d: DistrictLayout, p: InteriorPlan, from: Vector2, radius: float) -> Dictionary:
	var solid := p.wall_boxes()
	var round_things := []
	var boxes := []
	for f in p.furniture:
		if f.has("radius"):
			round_things.append([f.pos, float(f.radius)])
		elif f.has("box"):
			boxes.append([f.pos, f.box, float(f.get("rot", 0.0))])
	var free := func(q: Vector2) -> bool:
		if not p.room.grow(-2.0).has_point(q):
			return false
		for b in solid:
			if b.grow(radius).has_point(q):
				return false
		for c in round_things:
			if q.distance_to(c[0]) < float(c[1]) + radius:
				return false
		for b2 in boxes:
			var local: Vector2 = (q - (b2[0] as Vector2)).rotated(-float(b2[2]))
			if Rect2(-(b2[1] as Vector2) * 0.5, b2[1]).grow(radius).has_point(local):
				return false
		return true
	var seen := {}
	var start := Vector2i(roundi(from.x / STEP), roundi(from.y / STEP))
	var todo := [start]
	seen[start] = true
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for n in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nc: Vector2i = c + n
			if not seen.has(nc) and free.call(Vector2(nc) * STEP):
				seen[nc] = true
				todo.append(nc)
	return seen


func test_every_riverside_room_can_be_walked_into_and_used() -> void:
	var d := RiversideWard.create()
	assert_gt(d.interiors.size(), 0)
	for plan in d.interiors:
		var p: InteriorPlan = plan
		assert_true(p.building >= 0, "%s sits in a building" % p.id)
		assert_true(p.building_rect.encloses(p.room), "%s: the room is inside its house" % p.id)
		assert_gt(p.doors.size(), 0, "%s has a door" % p.id)
		var reach := _reach(d, p, p.inside_door(0, 14.0), Walker.RADIUS + 1.0)
		assert_gt(reach.size(), 20, "%s: room to move inside the door" % p.id)
		for i in p.doors.size():
			var out := p.outside_door(i, 20.0)
			assert_true(d.is_open_ground(out, Walker.RADIUS), "%s door %d opens onto open ground" % [p.id, i])
			assert_false(d.is_in_building(out, 4.0) and d.interior_at(out) == null, "%s door %d is not blocked by a neighbour" % [p.id, i])
		for s in p.spots:
			var near := false
			for k in reach.keys():
				if (Vector2(k) * STEP).distance_to(s.pos) <= float(s.radius) - 4.0:
					near = true
					break
			assert_true(near, "%s: you can walk up to '%s'" % [p.id, s.prompt])
		for person in p.people:
			assert_true(p.contains(person.pos, -InteriorPlan.WALL), "%s: %s stands inside" % [p.id, person.id])


func test_a_car_does_not_fit_through_any_door() -> void:
	var d := RiversideWard.create()
	var car_width := 30.0  # the narrower car's collision capsule
	for plan in d.interiors:
		for door in (plan as InteriorPlan).doors:
			assert_lte(float(door.width), car_width, "%s: people only" % plan.id)
			assert_gte(float(door.width), Walker.RADIUS * 2.0 + 6.0, "%s: a person walks through easily" % plan.id)
