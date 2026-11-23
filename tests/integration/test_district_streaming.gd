extends GutTest
## M008 district streaming on made-up districts in a row (west to east:
## a, b, c and, since M015, d - each 3000 px wide): only what is near is
## built; a neighbour is built ahead of its border, a slice a frame, and
## appears complete; until then a frontier wall closes the way in; at most
## MAX_LOADED are loaded (two until M015, three since); one left far behind
## is freed (with hysteresis); turning back abandons a half-built one; an
## adopted district is pinned.

const Toy := preload("res://tests/support/toy_district.gd")

var streamer: DistrictStreamer
var unloaded: Array[String] = []
var readied: Array[String] = []


func before_each() -> void:
	unloaded.clear()
	readied.clear()
	streamer = DistrictStreamer.new()
	add_child_autofree(streamer)
	streamer.setup(AssetResolver.new(""), [Toy.make("a", Vector2(0, 0), "", "b"), Toy.make("b", Vector2(3000, 0), "a", "c"),
		Toy.make("c", Vector2(6000, 0), "b", "d"), Toy.make("d", Vector2(9000, 0), "c", "")])
	streamer.district_unloading.connect(func(id: String) -> void: unloaded.append(id))
	streamer.district_ready.connect(func(id: String) -> void: readied.append(id))


## Runs the streamer with the focus at p for up to `frames` frames, until `cond` holds.
func _stream(p: Vector2, frames: int, cond: Callable = func() -> bool: return false) -> int:
	for i in frames:
		streamer.update(p)
		assert_lte(streamer.loaded.size(), DistrictStreamer.MAX_LOADED, "never more than MAX_LOADED districts")
		if cond.call():
			return i + 1
		await get_tree().process_frame
	return frames


func test_only_what_is_near_is_built() -> void:
	await _stream(Vector2(300, 600), 120)
	assert_eq(streamer.ready_ids(), ["a"] as Array[String], "the district he is in, nothing else")
	assert_eq(streamer.layouts.size(), 4, "every layout is known (data)")
	assert_eq(streamer.district_at(Vector2(4000, 600)), "b")
	assert_false(streamer.is_open_ground(Vector2(4000, 600), 12.0), "b is not there to stand on yet")
	assert_eq(streamer.bounds(), Rect2(0, 0, 3000, 1200), "the camera stays inside a")


func test_a_neighbour_is_built_ahead_of_its_border_a_slice_a_frame() -> void:
	await _stream(Vector2(300, 600), 120)
	assert_eq(streamer.frontier_rects().size(), 1, "the way east is closed while b is not there")
	streamer.budget_usec = 300  # small slices, to see them
	var frames := await _stream(Vector2(2000, 600), 600, func() -> bool: return streamer.is_ready("b"))
	assert_true(streamer.is_ready("b"), "1000 px from the border: b is built")
	assert_gt(frames, 3, "over several frames")
	var st: Dictionary = streamer.stats.b
	assert_gt(st.frames, 3)
	assert_eq(readied, ["a", "b"] as Array[String], "a where he stands, then b")
	var node: Node2D = streamer.loaded.b.node
	assert_true(node.visible, "it appears when it is complete")
	assert_not_null(streamer.navigator_of("b"), "with its walking grid (built on a worker thread)")
	assert_true(streamer.navigator_of("b").is_open(Vector2(4500, 600)))
	assert_true(streamer.is_open_ground(Vector2(4000, 600), 12.0))
	assert_eq(streamer.bounds(), Rect2(0, 0, 6000, 1200), "the camera may show both")
	var walls := streamer.frontier_rects()
	assert_eq(walls.size(), 1, "a to b open; only b's way east into c is closed")
	assert_gt(walls[0].position.x, 5900.0)


func test_far_ones_are_freed() -> void:
	await _stream(Vector2(2000, 600), 600, func() -> bool: return streamer.is_ready("b"))
	# into b and on towards c: a has to go to make room
	await _stream(Vector2(5000, 600), 900, func() -> bool: return streamer.is_ready("c"))
	assert_true(streamer.is_ready("c"))
	assert_false(streamer.is_ready("a"), "a let go")
	assert_has(unloaded, "a")
	assert_null(get_node_or_null("Districts/District_a"))
	# back west: c stays while he is close, goes once he is far (and a comes back)
	await _stream(Vector2(4500, 600), 30)
	assert_true(streamer.is_ready("c"), "hysteresis: not freed the moment he turns round")
	await _stream(Vector2(3200, 600), 900, func() -> bool: return streamer.is_ready("a"))
	assert_true(streamer.is_ready("a"))
	assert_false(streamer.is_ready("c"))
	assert_eq(streamer.stats.a.builds, 2, "built again on the way back")


func test_turning_back_abandons_a_half_built_district() -> void:
	await _stream(Vector2(300, 600), 60)
	streamer.budget_usec = 1
	streamer.update(Vector2(2000, 600))
	assert_true(streamer.is_building("b"))
	await _stream(Vector2(100, 600), 3)
	assert_false(streamer.is_building("b"), "too far now: let go")
	assert_false(streamer.is_ready("b"))
	assert_null(get_node_or_null("Districts/District_b"), "nothing half-built left behind")


func test_an_adopted_district_is_pinned() -> void:
	var city := City.new()
	add_child_autofree(city)
	city.build(streamer.layouts.a, streamer.resolver)
	streamer.adopt("a", city, CityNavigator.new(streamer.layouts.a))
	await _stream(Vector2(4000, 600), 600, func() -> bool: return streamer.is_ready("b"))
	await _stream(Vector2(5800, 600), 600, func() -> bool: return streamer.is_ready("c"))
	assert_true(streamer.is_ready("a"), "pinned: never let go")
	assert_eq(streamer.ready_ids(), ["a", "b", "c"] as Array[String], "three: the limit")
	# into c near d's border, b still too close to be let go by distance: d is wanted,
	# so b (not a, pinned) makes room
	await _stream(Vector2(7800, 600), 900, func() -> bool: return streamer.is_ready("d"))
	assert_true(streamer.is_ready("d"))
	assert_true(streamer.is_ready("a"), "still pinned")
	assert_false(streamer.is_ready("b"), "b made room")
	assert_eq(streamer.loaded.size(), 3)
	streamer.unload("a")
	assert_true(streamer.is_ready("a"), "an adopted district cannot be unloaded")


func test_load_now_builds_at_once() -> void:
	streamer.load_now("c")
	assert_true(streamer.is_ready("c"))
	assert_eq(streamer.stats.c.builds, 1)
