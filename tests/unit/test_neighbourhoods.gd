extends GutTest
## M008 the Riverside Ward's neighbours, as data: each is a proper district
## (buildings that never overlap, catalogued art, cars, lamps, the beat and the
## walking routes on open ground, traffic on the streets), they sit beside the
## ward without overlapping it, and every way across a border opens onto a
## street on both sides, with a matching way back.

var ward: DistrictLayout
var others: Array = []


func before_all() -> void:
	ward = RiversideWard.create()
	var all := CityPlan.layouts(ward)
	others = all.slice(1)


func _check(fn: Callable) -> void:
	assert_gt(others.size(), 0, "there are neighbours")
	for l in others:
		fn.call(l as DistrictLayout)


func test_each_has_an_id_a_name_and_an_origin() -> void:
	var ids := {"riverside": true}
	_check(func(d: DistrictLayout) -> void:
		assert_ne(d.id, "")
		assert_false(ids.has(d.id), "ids are unique")
		ids[d.id] = true
		assert_ne(d.name, "")
		assert_ne(d.origin, Vector2.ZERO, "%s is placed beside the ward" % d.name)
		assert_true(d.bounds.encloses(d.play_area), "%s: its ground is inside its bounds" % d.name))


func test_none_overlaps_the_ward_or_each_other() -> void:
	var all: Array = [ward] + others
	for i in all.size():
		for j in range(i + 1, all.size()):
			var a: Rect2 = all[i].bounds
			var b: Rect2 = all[j].bounds
			assert_false(a.grow(-1.0).intersects(b.grow(-1.0)), "%s and %s do not overlap" % [all[i].name, all[j].name])


func test_buildings_never_overlap_and_use_catalogued_art() -> void:
	_check(func(d: DistrictLayout) -> void:
		assert_eq(d.overlapping_buildings(), [], d.name)
		for b in d.buildings:
			assert_true(AssetCatalog.SPECS.has("facades/" + b.facade), b.facade)
			assert_true(AssetCatalog.SPECS.has("roofs/" + b.roof), b.roof)
			for p in b.props:
				assert_true((b.rect as Rect2).has_point(p.pos), "%s on its own roof" % p.kind)
			for sg in b.signs:
				assert_true(AssetCatalog.SPECS.has(sg.kind), sg.kind)
		for p in d.props:
			assert_true(AssetCatalog.SPECS.has(p.kind), p.kind)
			if p.has("box") or p.has("radius"):
				assert_false(d.is_in_building(p.pos), "%s at %s is not inside a building" % [p.kind, p.pos])
		for dcl in d.decals:
			assert_true(AssetCatalog.SPECS.has(dcl.kind), dcl.kind))


func test_cars_lamps_beat_and_people_on_open_ground() -> void:
	_check(func(d: DistrictLayout) -> void:
		for c in d.cars:
			var t := Transform2D(c.rot, c.pos)
			for corner in [Vector2(40, 18), Vector2(40, -18), Vector2(-40, 18), Vector2(-40, -18)]:
				assert_true(d.is_open_ground(t * corner), "%s: car at %s on open ground" % [d.name, c.pos])
			assert_ne(String(c.get("owner", "")), "", "every car belongs to somebody")
			assert_ne(String(c.get("owner", "")), CarThefts.DANNY, "Danny's car is in the ward")
		for p in d.lamps:
			assert_false(d.is_in_building(p, 4.0), "%s: lamp at %s" % [d.name, p])
			assert_false(d.is_in_water(p), "%s: lamp at %s" % [d.name, p])
		assert_false(d.police_beat.is_empty(), "%s has a beat cop" % d.name)
		for p in d.police_beat:
			assert_true(d.is_open_ground(p, 14.0), "%s: beat at %s" % [d.name, p])
		for route in d.walk_routes:
			for k in range(route.size() - 1):
				for t in 9:
					var p: Vector2 = route[k].lerp(route[k + 1], t / 8.0)
					assert_true(d.is_open_ground(p, 10.0), "%s: walking route at %s" % [d.name, p])
		for loop in d.drive_loops:
			for p in loop:
				assert_true(d.streets.any(func(s: Dictionary) -> bool: return (s.rect as Rect2).has_point(p)),
					"%s: traffic at %s is on a street" % [d.name, p]))


func test_every_way_across_a_border_has_a_way_back() -> void:
	var all: Array = [ward] + others
	var by_id := {}
	for l in all:
		by_id[l.id] = l
	for l in all:
		var d: DistrictLayout = l
		for e in d.exits:
			assert_true(by_id.has(e.to), "%s leads to a planned district (%s)" % [d.name, e.to])
			if not by_id.has(e.to):
				continue
			var other: DistrictLayout = by_id[e.to]
			var r: Rect2 = e.rect
			var mid := r.get_center()
			assert_true(d.bounds.grow(1.0).has_point(mid) and other.bounds.grow(8.0).has_point(mid), "%s -> %s on the border" % [d.name, other.name])
			assert_true(d.streets.any(func(s: Dictionary) -> bool: return (s.rect as Rect2).grow(2.0).intersects(r)),
				"%s: a street reaches the way out at %s" % [d.name, mid])
			assert_true(other.streets.any(func(s: Dictionary) -> bool: return (s.rect as Rect2).grow(8.0).intersects(r)),
				"%s: the street goes on at %s" % [other.name, mid])
			assert_true(other.exits.any(func(b: Dictionary) -> bool: return b.to == d.id and (b.rect as Rect2).grow(10.0).intersects(r)),
				"%s has the way back to %s at %s" % [other.name, d.name, mid])


func test_the_streets_carry_on_across_the_border() -> void:
	var yards: DistrictLayout = others.filter(func(l: DistrictLayout) -> bool: return l.id == "yards")[0]
	for street_name in ["Kessler Street", "Wharf Street"]:
		var up: Rect2 = ward.streets.filter(func(s: Dictionary) -> bool: return s.name == street_name)[0].rect
		var down: Rect2 = yards.streets.filter(func(s: Dictionary) -> bool: return s.name == street_name)[0].rect
		assert_eq(down.position.x, up.position.x, "%s keeps its line" % street_name)
		assert_eq(down.size.x, up.size.x, "and its width")
		assert_almost_eq(down.position.y, up.end.y, 1.0, "and runs on from the ward's border")
	assert_eq(yards.place_name(Vector2(1650, 3200)), "Kessler Street", "the same name on both sides")
	assert_eq(yards.lamp_energy < 1.0, true, "the yards are dimmer")
	assert_false(yards.smoke.is_empty(), "a works smokestack")
	assert_true(yards.landmarks.size() >= 4, "named works for the map")
