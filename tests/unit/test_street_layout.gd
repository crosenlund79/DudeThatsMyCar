extends GutTest
## M003 street life in the Riverside Ward as data: people walk on the
## sidewalks clear of lamp posts and other solid furniture, cars drive round
## the blocks on the right-hand side of the street, clear of the parked cars
## and buildings, and the squad car waits in an alley.

var d: DistrictLayout


func before_all() -> void:
	d = RiversideWard.create()


func _samples(route: PackedVector2Array, step: float, closed := false) -> Array:
	var out := []
	var n := route.size() if closed else route.size() - 1
	for k in n:
		var a := route[k]
		var b := route[(k + 1) % route.size()]
		var count := maxi(1, int(a.distance_to(b) / step))
		for i in count + 1:
			out.append(a.lerp(b, float(i) / count))
	return out


func _on_street(p: Vector2) -> bool:
	return d.streets.any(func(s: Dictionary) -> bool: return (s.rect as Rect2).has_point(p))


func test_people_walk_on_the_sidewalks_clear_of_furniture() -> void:
	assert_gte(d.walkers.size(), 4, "a handful of people")
	assert_lte(d.walkers.size(), 8, "not a crowd")
	for route in d.walk_routes:
		for p in _samples(route, 8.0):
			assert_true(d.is_open_ground(p, Walker.RADIUS + 1.0), "%s is open ground" % p)
			assert_false(_on_street(p), "%s is on the sidewalk, not the road" % p)
			for prop in d.props:
				if prop.has("radius"):
					assert_gt(p.distance_to(prop.pos), float(prop.radius) + Walker.RADIUS, "%s clear of %s" % [p, prop.kind])
				elif prop.has("box"):
					var local: Vector2 = (p - (prop.pos as Vector2)).rotated(-float(prop.rot))
					assert_false(Rect2(-(prop.box as Vector2) * 0.5, prop.box).grow(Walker.RADIUS).has_point(local), "%s clear of %s" % [p, prop.kind])
			for lamp in d.lamps:
				assert_gt(p.distance_to(lamp), 5.0 + Walker.RADIUS, "%s clear of the lamp at %s" % [p, lamp])


func test_cars_drive_round_the_blocks_on_the_right() -> void:
	assert_between(d.traffic.size(), 1, 4, "sparse traffic")
	for loop in d.drive_loops:
		var pts: PackedVector2Array = loop
		for k in pts.size():
			var a := pts[k]
			var b := pts[(k + 1) % pts.size()]
			var heading := (b - a).normalized()
			var right := heading.orthogonal() * -1.0  # the driver's right hand (y points down)
			var mid := a.lerp(b, 0.5)
			var street: Dictionary = {}
			for s in d.streets:
				if (s.rect as Rect2).has_point(mid):
					street = s
			assert_false(street.is_empty(), "%s on a street" % mid)
			var centre: Vector2 = (street.rect as Rect2).get_center()
			assert_gt((mid - centre).dot(right), 10.0, "%s keeps to the right" % mid)
		for p in _samples(pts, 10.0, true):
			assert_false(d.is_in_building(p, 22.0), "%s clear of buildings" % p)
			for c in d.cars:
				assert_gt(p.distance_to(c.pos), 36.0, "%s clear of the car parked at %s" % [p, c.pos])


func test_the_squad_car_waits_in_an_alley() -> void:
	var police := d.cars.filter(func(c: Dictionary) -> bool: return c.type == "police")
	assert_eq(police.size(), 1)
	var in_alley := d.alleys.any(func(a: Dictionary) -> bool: return (a.rect as Rect2).grow(-14.0).has_point(police[0].pos))
	assert_true(in_alley, "parked in a back alley")
