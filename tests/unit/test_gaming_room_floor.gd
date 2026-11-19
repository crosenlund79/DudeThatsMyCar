extends GutTest
## M013 the gaming room's floor for its regulars (RiversideInteriors.ROOM_*):
## every place to stand or sit and every leg of the walking graph keeps a
## person clear of the walls and the solid furniture; every place can be
## reached from the door; no place is one of Danny's own (the rail where he
## bets, the machines' fronts), and none crowds them.

var plan: InteriorPlan


func before_all() -> void:
	plan = RiversideInteriors.gaming_room(RiversideWard.create())


func _clear(q: Vector2, r: float) -> bool:
	if not plan.room.grow(-2.0).has_point(q):
		return false
	for b in plan.wall_boxes():
		if b.grow(r).has_point(q):
			return false
	for f in plan.furniture:
		if f.has("radius") and q.distance_to(f.pos) < float(f.radius) + r - 0.5:
			return false
		if f.has("box"):
			var local: Vector2 = (q - (f.pos as Vector2)).rotated(-float(f.get("rot", 0.0)))
			if Rect2(-(f.box as Vector2) * 0.5, f.box).grow(r - 0.5).has_point(local):
				return false
	return true


func _where(name: String) -> Vector2:
	return RiversideInteriors.ROOM_NODES[name] if RiversideInteriors.ROOM_NODES.has(name) else RiversideInteriors.ROOM_SPOTS[name][0]


func test_every_place_and_leg_is_clear() -> void:
	var r := Walker.RADIUS
	for k in RiversideInteriors.ROOM_SPOTS:
		assert_true(_clear(RiversideInteriors.ROOM_SPOTS[k][0], r - 1.0), "%s has room for a person" % k)
	for k in RiversideInteriors.ROOM_NODES:
		assert_true(_clear(RiversideInteriors.ROOM_NODES[k], r), "waypoint %s is clear" % k)
	for leg in RiversideInteriors.ROOM_LINKS:
		var a := _where(leg[0])
		var b := _where(leg[1])
		var steps := maxi(2, int(a.distance_to(b) / 3.0))
		for i in range(1, steps):
			var q := a.lerp(b, float(i) / steps)
			if not _clear(q, r - 1.0):
				fail_test("the leg %s - %s runs into something at %s" % [leg[0], leg[1], q])
				break
	pass_test("checked")


func test_every_place_reached_from_the_door() -> void:
	var seen := {"door": true}
	var grew := true
	while grew:
		grew = false
		for leg in RiversideInteriors.ROOM_LINKS:
			if seen.has(leg[0]) and not seen.has(leg[1]):
				seen[leg[1]] = true
				grew = true
			elif seen.has(leg[1]) and not seen.has(leg[0]) and RiversideInteriors.ROOM_NODES.has(leg[1]):
				seen[leg[0]] = true
				grew = true
	for k in RiversideInteriors.ROOM_SPOTS:
		assert_true(seen.has(k), "%s can be walked to" % k)


func test_none_is_dannys() -> void:
	var his: Array[Vector2] = [RiversideInteriors.ROULETTE_SPOT]
	for i in RiversideInteriors.SLOTS.size():
		his.append(RiversideInteriors.SLOTS[i] + Vector2(0, 32))
	for k in RiversideInteriors.ROOM_SPOTS:
		var p: Vector2 = RiversideInteriors.ROOM_SPOTS[k][0]
		for i in his.size():
			var at_machine: bool = String(k).begins_with("slot_") and i == int(String(k).substr(5)) + 1
			if at_machine:
				continue  # a regular at his own machine steps away when Danny comes to it
			assert_gt(p.distance_to(his[i]), 24.0, "%s leaves Danny's place %s free" % [k, his[i]])
	assert_false(RiversideInteriors.ROOM_SPOTS.has("slot_1"), "the Bell is left for Danny")
