extends GutTest
## M006 headlights: two beams, one from each lamp - distinct close in front of
## the car, widening with distance and merging further out - drawn by a single
## light per car, so they cost what the old single beam did.


func _width(x: float) -> float:
	# how wide the lit strip is (above a quarter of the brightest) at x px ahead
	var peak := 0.0
	for k in range(-160, 161):
		peak = maxf(peak, VehicleLights.beam_at(x, k))
	var lit := 0
	for k in range(-160, 161):
		if VehicleLights.beam_at(x, k) > peak * 0.25:
			lit += 1
	return lit


func test_two_beams_close_in() -> void:
	var lamp := VehicleLights.LAMP_SPACING
	var on_lamp := VehicleLights.beam_at(16.0, lamp)
	var between := VehicleLights.beam_at(16.0, 0.0)
	assert_gt(on_lamp, between * 1.4, "in front of each lamp, a beam; between them, less")
	assert_almost_eq(VehicleLights.beam_at(16.0, -lamp), on_lamp, 0.001, "two alike")


func test_they_widen_and_merge_further_out() -> void:
	assert_gt(_width(150.0), _width(20.0) * 3.0, "wider with distance")
	assert_gte(VehicleLights.beam_at(150.0, 0.0), VehicleLights.beam_at(150.0, VehicleLights.LAMP_SPACING) * 0.95,
		"one pool down the road")
	assert_lt(VehicleLights.beam_at(300.0, 0.0), VehicleLights.beam_at(100.0, 0.0), "fading out ahead")
	assert_eq(VehicleLights.beam_at(-5.0, 0.0), 0.0, "nothing behind the lamps")


func test_one_light_per_car() -> void:
	var c: Car = (load("res://src/driving/car.tscn") as PackedScene).instantiate()
	add_child_autofree(c)
	c.setup(load("res://src/driving/vehicles/sedan.tres"), null, "cars/sedan")
	var lights := VehicleLights.new()
	lights.setup(c, LightTextures.radial())
	var n := 0
	for child in lights.get_children():
		if child is PointLight2D:
			n += 1
	assert_eq(n, 1, "one light, both beams")
	assert_eq(lights.beam.texture.get_width(), VehicleLights.TWIN_SIZE)
	assert_gt(lights.beam.position.x, c.vehicle.headlights[0].x, "the beams start at the lamps and reach ahead")
