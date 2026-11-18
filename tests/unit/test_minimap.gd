extends GutTest
## M004 the minimap draws the real district: streets, alleys, buildings (the
## places you can enter in copper), the river and the raised bridge, and the
## void past the edges; north is up, east is right, the player is in the
## middle, and places off the map wait at its rim in the right direction.

var map: Minimap
var d: DistrictLayout


func before_all() -> void:
	d = RiversideWard.create()
	map = Minimap.new()
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://assets/graphics/ui/template_panel.png")
	map.setup(d, AssetResolver.new(), sb, null)


func after_all() -> void:
	map.free()


func test_the_map_is_painted_from_the_district() -> void:
	assert_eq(map.colour_at(Vector2(1000, 600)), Minimap.STREET, "Marlowe Avenue")
	assert_eq(map.colour_at(Vector2(1650, 1000)), Minimap.STREET, "Kessler Street")
	assert_eq(map.colour_at(Vector2(300, 135)), Minimap.ALLEY, "the back alley")
	assert_eq(map.colour_at(Vector2(2900, 300)), Minimap.BUILDING, "an ordinary house")
	assert_eq(map.colour_at(Vector2(2290, 300)), Minimap.PLACE, "the Copper Owl stands out")
	assert_eq(map.colour_at(Vector2(1890, 850)), Minimap.PLACE, "so does Novak's")
	assert_eq(map.colour_at(Vector2(4150, 300)), Minimap.WATER, "the river")
	assert_eq(map.colour_at(Vector2(3910, 600)), Minimap.STEEL, "the raised bridge")
	assert_eq(map.colour_at(Vector2(-4000, -4000)), Minimap.VOID, "nothing past the edge")
	assert_eq(map.colour_at(d.bounds.end + Vector2(300, 300)), Minimap.VOID)


func test_north_up_east_right_player_in_the_middle() -> void:
	map.set_view(Vector2(1000, 600), 0.0, 0.0, Vector2.INF, false, 0.0)
	assert_eq(map.to_map(Vector2(1000, 600)), Minimap.SIZE * 0.5)
	var east := map.to_map(Vector2(1000 + map.zoom * 20.0, 600))
	assert_almost_eq(east.x - Minimap.SIZE.x * 0.5, 20.0, 0.001, "east is right")
	var north := map.to_map(Vector2(1000, 600 - map.zoom * 20.0))
	assert_almost_eq(north.y - Minimap.SIZE.y * 0.5, -20.0, 0.001, "north is up")


func test_driving_zooms_out_a_little() -> void:
	map.set_view(Vector2(1000, 600), 0.0, 0.0, Vector2.INF, false, 0.0)
	var foot := map.zoom
	map.set_view(Vector2(1000, 600), 0.0, 1.0, Vector2.INF, false, 0.0)
	assert_gt(map.zoom, foot)
	assert_lt(map.zoom, foot * 2.0, "not so far that the streets vanish")


func test_places_off_the_map_wait_at_its_rim() -> void:
	map.set_view(Vector2(2350, 600), 0.0, 0.0, Vector2.INF, false, 0.0)
	var club := map.place_on_map(Vector2(2291, 460))
	assert_true(club.on_map, "the club next door is on the map")
	var sal := map.place_on_map(Vector2(1080, 460))
	assert_false(sal.on_map, "Sal's is a long way west")
	assert_lt((sal.at as Vector2).x, Minimap.SIZE.x * 0.2, "pinned at the west rim")
	assert_true(Rect2(Vector2.ZERO, Minimap.SIZE).has_point(sal.at))


func test_every_marked_place_is_on_the_map_with_its_own_badge() -> void:
	var by_id := {}
	for p in map.places:
		by_id[p.id] = p
	for plan in d.interiors:
		var ip: InteriorPlan = plan
		if ip.marker == "":
			assert_false(by_id.has(ip.id), "%s (M010: a back room) has no badge" % ip.id)
			continue
		assert_true(by_id.has(ip.id), "%s is on the map" % ip.id)
		assert_eq((by_id[ip.id].tex as Texture2D).resource_path.get_file(), "template_%s.png" % ip.marker.get_file(),
			"%s: the same badge as over its door" % ip.id)
		assert_eq(by_id[ip.id].home, ip.is_home)
