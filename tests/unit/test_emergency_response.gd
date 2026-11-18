extends GutTest
## M010 the emergency response, without the scene: the police car first, the
## fire engine, then the ambulance, each after its delay; driving in along
## the lane and easing into its place at the kerb, stopped square to the
## street; the fire out a while after the engine stops; settled at once for a
## district built later; cleared for the next night; the paths in.


func _response() -> EmergencyResponse:
	var r := EmergencyResponse.new()
	var stops := {"police": Vector2(760, 1830), "fire": Vector2(940, 1840), "ambulance": Vector2(1110, 1835)}
	r.dispatch(2, 23 * 60.0, Vector2(600, 1808), EmergencyResponse.routes_for(Vector2(3100, 1855), stops))
	return r


func _run(r: EmergencyResponse, from: float, seconds: float) -> Array:
	var events := []
	var t := 0.0
	while t < seconds:
		events.append_array(r.advance(from + t, 1.0 / 30.0))  # a game minute a second
		t += 1.0 / 30.0
	return events


func test_in_order_and_into_their_places() -> void:
	var r := _response()
	assert_true(r.active(2))
	assert_false(r.active(3))
	var start := 23 * 60.0
	var events := _run(r, start, 1.0)
	assert_true(events.is_empty(), "nobody off yet")
	events = _run(r, start + 1.0, 25.0)
	var offs := events.filter(func(e: Dictionary) -> bool: return e.what == "set_off").map(func(e: Dictionary) -> String: return e.id)
	assert_eq(offs, ["police", "fire", "ambulance"], "the police car first, the ambulance last")
	var stops := events.filter(func(e: Dictionary) -> bool: return e.what == "stopped").map(func(e: Dictionary) -> String: return e.id)
	assert_eq(stops.size(), 3, "all three got there")
	for i in r.units.size():
		var p := r.pose(i)
		assert_eq(r.units[i].state, "stopped")
		assert_almost_eq(absf(angle_difference(p.rot, PI)), 0.0, 0.01, "stopped square to the street, facing the scene")
	assert_lt((r.pose(0).pos as Vector2).distance_to(Vector2(760, 1830)), 0.5)


func test_driving_along_the_lane() -> void:
	var r := _response()
	_run(r, 23 * 60.0, 2.0)  # the police car has set off
	var p := r.pose(0)
	assert_almost_eq((p.pos as Vector2).y, 1855.0, 0.5, "in the lane")
	assert_lt((p.pos as Vector2).x, 3100.0, "coming in from the edge")
	assert_almost_eq(absf(angle_difference(p.rot, PI)), 0.0, 0.01, "facing the way it goes")


func test_the_fire_put_out_and_settled_later() -> void:
	var r := _response()
	var events := _run(r, 23 * 60.0, 40.0)
	assert_true(events.any(func(e: Dictionary) -> bool: return e.what == "fire_out"), "the firemen put it out")
	assert_true(r.fire_out)
	var r2 := _response()
	r2.settle(23 * 60.0 + 30.0)
	for u in r2.units:
		assert_eq(u.state, "stopped", "already there when the district is built again")
	r2.clear()
	assert_false(r2.active(2), "gone the next night")
