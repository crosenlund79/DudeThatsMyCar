extends GutTest
## M010 Halloran Park and the seats: the square's middle block is a little
## park - four lawns, flowerbeds, hedges, a railing with a gate at each path,
## more benches - the same trees and lamps; the passers-by's path goes through
## the gates; every bench is a seat that faces the way it is drawn.

var h: DistrictLayout


func before_all() -> void:
	h = HalloranSquare.create()


func test_the_park() -> void:
	# the park's own (M011: the mayor's garden and railing across Pruitt Street are not the park's)
	var park: Rect2 = Rect2(HalloranSquare.COLS[1][0], HalloranSquare.ROWS[2][0], HalloranSquare.COLS[1][1] - HalloranSquare.COLS[1][0],
		HalloranSquare.ROWS[2][1] - HalloranSquare.ROWS[2][0])
	park.position += HalloranSquare.ORIGIN
	var lawns := h.lots.filter(func(l: Dictionary) -> bool: return l.kind == "grass" and park.encloses(l.rect))
	assert_eq(lawns.size(), 4, "four lawns")
	var railing := h.fences.filter(func(f: Array) -> bool: return f.size() > 2 and f[2] == "iron" and park.has_point(f[0]))
	assert_eq(railing.size(), 8, "a railing round it, broken by four gates")
	assert_eq(h.props.filter(func(p: Dictionary) -> bool: return p.kind == "props/flowerbed").size(), 4)
	assert_eq(h.props.filter(func(p: Dictionary) -> bool: return p.kind == "props/hedge").size(), 4)
	assert_gte(h.props.filter(func(p: Dictionary) -> bool: return p.kind == "interiors/bench").size(), 4, "benches")
	assert_gte(h.props.filter(func(p: Dictionary) -> bool: return p.kind == "props/tree").size(), 8, "the same trees")
	assert_true(h.landmarks.any(func(l: Dictionary) -> bool: return l.label == "Halloran Park"))
	for p in h.props.filter(func(p2: Dictionary) -> bool: return p2.kind in ["props/flowerbed", "props/hedge"]):
		assert_false(p.has("box") or p.has("radius"), "flowerbeds and hedges are low: not solid")


func test_the_footpath_goes_through_the_gates() -> void:
	var route: PackedVector2Array = h.walk_routes[h.walk_routes.size() - 1]
	for f in h.fences:
		var cross: Variant = Geometry2D.segment_intersects_segment(route[0], route[1], f[0], f[1])
		assert_null(cross, "the path does not cut through a railing")
	assert_true(h.walkers.any(func(w: Dictionary) -> bool: return int(w.route) == h.walk_routes.size() - 1), "somebody strolls it")


func test_benches_are_seats() -> void:
	var seats := Seats.of(h)
	assert_gte(seats.size(), 4)
	for s in seats:
		assert_almost_eq((s.stand as Vector2).distance_to(s.pos), Seats.STAND_OFF - 2.0, 0.1)
		assert_almost_eq(angle_difference(((s.stand as Vector2) - (s.pos as Vector2)).angle(), float(s.facing)), 0.0, 0.001, "he stands up the way he faces")
		assert_false(h.is_in_building(s.stand), "and there is room to")
	assert_eq(Seats.near(seats, (seats[0].stand as Vector2) + Vector2(5, 0)), seats[0])
	assert_true(Seats.near(seats, Vector2(-5000, -5000)).is_empty())
	var ward := RiversideWard.create()
	assert_gte(Seats.of(ward).size(), 2, "the ward's benches too (the streetcar stop, the barber's)")
