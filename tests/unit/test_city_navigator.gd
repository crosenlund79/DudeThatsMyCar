extends GutTest
## Walking routes through the Riverside Ward: round buildings, never through
## them, along the streets and through the alleys; straight when the way is open.

var d: DistrictLayout
var nav: CityNavigator


func before_all() -> void:
	d = RiversideWard.create()
	nav = CityNavigator.new(d, 12.0)


func _walk(from: Vector2, points: PackedVector2Array) -> Array[Vector2]:
	# every few px along the route
	var out: Array[Vector2] = []
	var here := from
	for p in points:
		var n := maxi(1, int(here.distance_to(p) / 4.0))
		for i in n + 1:
			out.append(here.lerp(p, float(i) / n))
		here = p
	return out


func test_an_open_street_is_walked_straight() -> void:
	var r := nav.route(Vector2(900, 600), Vector2(1400, 600))
	assert_eq(r, PackedVector2Array([Vector2(1400, 600)]))


func test_round_a_block_never_through_a_building() -> void:
	var from := Vector2(800, 620)    # Marlowe Avenue
	var to := Vector2(800, -300)     # Calloway Street, the other side of the block
	var r := nav.route(from, to)
	assert_false(r.is_empty())
	assert_eq(r[r.size() - 1], to)
	for p in _walk(from, r):
		assert_false(d.is_in_building(p, 1.0), "the route at %s stays out of the buildings" % p)


func test_the_alley_is_a_way_through() -> void:
	# from the alley behind the Copper Owl to Kessler Street: along the alley
	var r := nav.route(Vector2(2300, 135), Vector2(1650, 135))
	assert_eq(r.size(), 1, "straight down the alley")


func test_unreachable_targets_give_the_nearest_open_point() -> void:
	var r := nav.route(Vector2(3500, 300), Vector2(4100, 300))  # in the river
	assert_false(r.is_empty())
	assert_lt(r[r.size() - 1].x, RiversideWard.RIVER_X, "stops at the quay")
	assert_true(nav.is_open(r[r.size() - 1]))


func test_inside_a_building_is_closed() -> void:
	assert_false(nav.is_open(Vector2(2300, 300)), "the Copper Owl")
	assert_true(nav.is_open(Vector2(2300, 600)), "Marlowe Avenue")
	assert_false(nav.clear_line(Vector2(2300, 600), Vector2(2300, 0)), "no walking through the club")


func test_a_goal_close_to_a_wall_is_reached_exactly() -> void:
	var by_the_wall := Vector2(1995, 457)  # 18 px from the shop fronts: closed grid cell, open pavement
	assert_false(nav.is_open(by_the_wall))
	var r := nav.route(Vector2(1990, 560), by_the_wall)
	assert_eq(r[r.size() - 1], by_the_wall)
