extends "res://tests/support/city_test.gd"
## M010 the weather in the game: the first night is wet; the fog is drawn over
## the street, the people and the cars but under the walls and roofs (so the
## rooftops stand clear) and never inside the room Danny is in; the rain falls
## under the HUD; the rain is heard outdoors and dully indoors; streets look
## wetter and headlights glare in the rain; sleeping brings the next night's
## own weather; a forced state holds.


func _view() -> WeatherView:
	return main.weather_view


func test_drawn_in_the_right_order() -> void:
	main.weather.force("rain_fog")
	await wait_physics_frames(3)
	var fog: DrawLayer = main.city.fog_layer
	assert_not_null(fog, "the ward's street fog")
	assert_true(fog.visible)
	assert_eq(fog.material, _view().fog_material, "one look for every district's fog")
	assert_false(fog.z_as_relative)
	assert_gt(fog.z_index, Layers.Z_ACTOR, "over the people and the cars")
	assert_lt(fog.z_index, Layers.Z_WALL, "under the walls")
	assert_lt(fog.z_index, Layers.Z_ROOF, "and the rooftops")
	assert_true(fog.light_mask & Layers.LIGHT_STREET != 0, "lit by the lamps and headlights")
	var rain_layer := _view().rain_rect.get_parent() as CanvasLayer
	assert_lt(rain_layer.layer, main.hud.layer, "the rain falls under the HUD")
	assert_true(_view().rain_rect.visible)
	assert_true(main.city.get_node_or_null("Props/FogFeet") != null, "fog banked at the buildings' feet")


func test_fog_lies_between_the_buildings_never_in_a_room() -> void:
	var cover: PackedVector2Array = main.layout.fog_cover()
	assert_gt(cover.size(), 300)
	var owl: Rect2 = main.layout.buildings[main.interiors.view_of("copper_owl").plan.building].rect
	var inner := owl.grow(-FogCover.CELL)
	for i in range(0, cover.size(), 3):
		var centre := (cover[i] + cover[i + 1] + cover[i + 2]) / 3.0
		assert_false(inner.has_point(centre), "no fog inside the Copper Owl")
	# but in the street outside it
	var street := Vector2(2300, 600)
	var covered := false
	for i in range(0, cover.size(), 3):
		if Geometry2D.point_is_inside_triangle(street, cover[i], cover[i + 1], cover[i + 2]):
			covered = true
			break
	assert_true(covered, "on Marlowe Avenue")
	# and a neighbour's fog over its own ground, when it is built
	main.weather.force("fog")
	walker().place(main.world.layouts.yards.contacts[0].pos, 0.0)
	main.world.load_now("yards")
	await wait_physics_frames(3)
	assert_not_null(main.world.city_of("yards").fog_layer)


func test_rain_heard_outdoors_and_dully_indoors() -> void:
	main.weather.force("rain")
	walker().place(Vector2(2350, 600), 0.0)
	for i in 120:
		await wait_physics_frames(1)
	var outdoors: float = main.soundscape.level.rain_db
	assert_gt(outdoors, SoundscapeMix.AUDIBLE_DB, "the rain on the street")
	await talk_to("copper_owl", "augie")
	await press_e()
	for i in 240:
		await wait_physics_frames(1)
	assert_lt(main.soundscape.level.rain_db, outdoors - 3.0, "quieter indoors")
	main.weather.force("clear")
	for i in 240:
		await wait_physics_frames(1)
	assert_lt(main.soundscape.level.rain_db, SoundscapeMix.AUDIBLE_DB, "and gone when it stops")


func test_wet_streets_and_glare() -> void:
	main.weather.force("rain")
	await wait_physics_frames(3)
	assert_almost_eq(VehicleLights.wet, 1.0, 0.001)
	var reflections: Array = main.city._reflections
	assert_gt(reflections.size(), 0)
	assert_gt((reflections[0].node as Sprite2D).modulate.a, 0.8, "the lamps' reflections brighter on the wet street")
	main.weather.force("clear")
	await wait_physics_frames(3)
	assert_almost_eq((reflections[0].node as Sprite2D).modulate.a, 0.5, 0.01)
	assert_false(_view().rain_rect.visible)
	assert_false(main.city.fog_layer != null and main.city.fog_layer.visible)


func test_a_night_s_weather_and_the_next() -> void:
	main.weather_override = ""
	main.weather.force("")
	main.weather.begin_night(1, float(main.night_rules.start_minute))
	assert_eq(main.weather.state_name(), "rain", "the first night is a wet one")
	main.clock.set_time(main.clock.minute + 200.0)
	main._update_clock(0.0)
	assert_gt(main.weather.fog, 0.5, "the fog came in after ten")
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	assert_eq(main.weather.night, 2)
	assert_eq(main.weather.state_name(), Weather.course_of(2)[0][1], "the next night's own weather")
	main.weather_override = "fog"
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	assert_eq(main.weather.state_name(), "fog", "a forced state holds")
