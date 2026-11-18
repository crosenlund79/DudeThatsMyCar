extends GutTest
## M010 the rubbish of a lived-in city: scattered once per district from its own
## streets, alleys and works, the same every time; never in a building, the
## river, a doorway, on a fence or under the street furniture; the industrial
## yards dirtier than the ward, the residential square cleanest; plenty of
## variety and no heaps.

var ward: DistrictLayout
var yards: DistrictLayout
var square: DistrictLayout


func before_all() -> void:
	ward = RiversideWard.create()
	yards = RiverfrontYards.create()
	square = HalloranSquare.create()


func _kerb_length(l: DistrictLayout) -> float:
	var total := 0.0
	for st in l.streets:
		total += maxf((st.rect as Rect2).size.x, (st.rect as Rect2).size.y) * 2.0
	return total


func test_the_same_district_has_the_same_rubbish() -> void:
	var a := StreetGrime.scatter(RiversideWard.create())
	var b := StreetGrime.scatter(RiversideWard.create())
	assert_eq(a.size(), b.size())
	for i in a.size():
		assert_eq(a[i].pos, b[i].pos)
		assert_eq(a[i].frame, b[i].frame)


func test_never_where_it_should_not_be() -> void:
	for l in [ward, yards, square]:
		var items: Array = (l as DistrictLayout).grime_items()
		assert_gt(items.size(), 50, "%s has rubbish" % l.id)
		for it in items:
			var p: Vector2 = it.pos
			assert_false(l.is_in_building(p), "%s: not inside a building at %s" % [l.id, p])
			assert_false(l.is_in_water(p), "%s: not in the river" % l.id)
			assert_true(int(it.frame) >= 0 and int(it.frame) < StreetGrime.FRAMES)
		for plan in l.interiors:
			for i in (plan as InteriorPlan).doors.size():
				var door := (plan as InteriorPlan).door_centre(i)
				assert_false(items.any(func(it: Dictionary) -> bool: return (it.pos as Vector2).distance_to(door) < 30.0),
					"%s: the doorway of %s kept clear" % [l.id, (plan as InteriorPlan).id])
		for f in l.fences:
			var fa: Vector2 = f[0]
			var fb: Vector2 = f[1]
			assert_false(items.any(func(it: Dictionary) -> bool:
				return Geometry2D.get_closest_point_to_segment(it.pos, fa, fb).distance_to(it.pos) < 8.0), "not on a fence")
		for pr in l.props:
			if pr.has("box"):
				assert_false(items.any(func(it: Dictionary) -> bool: return (it.pos as Vector2).distance_to(pr.pos) < (pr.box as Vector2).length() * 0.5),
					"%s: not under %s" % [l.id, pr.kind])


func test_the_yards_dirtiest_the_square_cleanest() -> void:
	var per := func(l: DistrictLayout) -> float: return l.grime_items().size() / _kerb_length(l) * 1000.0
	assert_gt(per.call(yards), per.call(ward), "the industrial yards dirtier than the ward")
	assert_gt(per.call(ward), per.call(square), "the residential square the cleanest")
	var dust := func(l: DistrictLayout) -> int: return l.grime_items().filter(func(it: Dictionary) -> bool: return it.frame in [7, 8]).size()
	assert_gt(dust.call(yards), dust.call(square) * 3, "coal dust and soot belong to the yards")


func test_variety_and_no_heaps() -> void:
	for l in [ward, yards, square]:
		var frames := {}
		var items: Array = (l as DistrictLayout).grime_items()
		for it in items:
			frames[it.frame] = true
		assert_gte(frames.size(), 9, "%s: many kinds of rubbish" % l.id)
		for i in mini(items.size(), 300):
			for j in range(i + 1, mini(items.size(), 300)):
				assert_gte((items[i].pos as Vector2).distance_to(items[j].pos), StreetGrime.GAP - 0.01)
