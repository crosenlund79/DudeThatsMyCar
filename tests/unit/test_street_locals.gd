extends GutTest
## M015 every district's street regulars and delivery vans (layout data): each
## standing one on open ground, clear of the walls; each walker on a real
## route; every couple's partner a real regular walking the same way; every
## van on open ground with its door in reach; hours inside the night; lines
## for anyone in a group; every kind a known one.

var layouts: Array = CityPlan.layouts(RiversideWard.create())


func test_every_regular_stands_or_walks_somewhere_real() -> void:
	var total := 0
	for l in layouts:
		var d: DistrictLayout = l
		for i in d.locals.size():
			var spec: Dictionary = d.locals[i]
			var label := "%s local %d" % [d.id, i]
			total += 1
			assert_true(String(spec.kind) in PedestrianBrain.KINDS, label)
			if spec.has("pos"):
				assert_true(d.is_open_ground(spec.pos, 8.0), label + " stands on open ground")
			else:
				assert_between(int(spec.route), 0, d.walk_routes.size() - 1, label + " walks a real route")
			if spec.has("hours"):
				assert_lt(float(spec.hours[0]), float(spec.hours[1]), label)
				assert_gte(float(spec.hours[0]), 19 * 60.0, label + " out at night")
			if spec.has("with"):
				var other: Dictionary = d.locals[int(spec.with)]
				assert_eq(other.get("route", -1), spec.get("route", -2), label + " walks beside a partner on the same route")
			if spec.has("group"):
				assert_false((spec.get("lines", []) as Array).is_empty(), label + " has something to say")
	assert_gte(total, 20, "a good few of them across the city")


func test_every_van_stands_in_the_street_by_its_door() -> void:
	var vans := 0
	for l in layouts:
		var d: DistrictLayout = l
		for dv in d.deliveries:
			vans += 1
			assert_true(d.is_open_ground(dv.pos, 12.0), "%s van on open ground" % d.id)
			assert_true(d.is_open_ground(dv.door, 4.0), "%s door step on open ground" % d.id)
			assert_lt((dv.pos as Vector2).distance_to(dv.door), 160.0, "the crates have a short way to go")
			assert_true(Fleet.VEHICLES.has(dv.vehicle))
	assert_gte(vans, 2)


func test_every_traffic_vehicle_is_known() -> void:
	var kinds := {}
	for l in layouts:
		for t in (l as DistrictLayout).traffic:
			assert_true(Fleet.VEHICLES.has(t.type), String(t.type))
			kinds[t.type] = true
	assert_true(kinds.has("taxi"), "cabs among the traffic")


func test_every_police_post_is_on_open_ground_at_night() -> void:
	var posts := 0
	for l in layouts:
		var d: DistrictLayout = l
		for pp in d.police_posts:
			posts += 1
			assert_true(d.is_open_ground(pp.pos, 8.0), "%s post on open ground" % d.id)
			assert_lt(float(pp.from), float(pp.until))
			assert_ne(String(pp.line), "")
	assert_eq(posts, layouts.size(), "one a district")


func test_a_coppers_mood_holds_all_night_and_changes_between_nights() -> void:
	var seen := {}
	for night in range(1, 9):
		var m := PoliceForce.mood_of("riverside", night)
		assert_true(PoliceForce.MOODS.has(m))
		assert_eq(PoliceForce.mood_of("riverside", night), m, "the same all night")
		seen[m] = true
	assert_gte(seen.size(), 3, "a different man most nights")
