extends "res://tests/support/city_test.gd"
## M012 the weather stays outside: in rain and fog, walking into a room - in
## the ward or in a streamed district - takes the rain off the room's part of
## the screen and the street fog and the fog at the buildings' feet out of its
## building; the rain and a downpour come through the walls quieter; stepping
## out puts it all back (nothing left over). Thunder in a downpour: the clap
## heard and the street lit for a breath, duller and dimmer indoors.


func _view() -> WeatherView:
	return main.weather_view


func _hole(m: ShaderMaterial) -> Vector4:
	return m.get_shader_parameter("hole")


func test_no_rain_or_fog_in_the_room_he_is_in() -> void:
	main.weather.force("rain_fog")
	var owl: InteriorPlan = main.interiors.plan_named("copper_owl")
	walker().place(owl.outside_door(0, 40.0), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(150)  # the levels glide in
	assert_false(_view().indoors.has_area(), "in the street: rain and fog everywhere")
	assert_eq(_hole(_view().fog_material), Vector4.ZERO)
	var outdoors_rain: float = main.soundscape.level.rain_db
	await walk_to(owl.inside_door(0, 30.0), 4.0, 240)
	await wait_physics_frames(150)
	var host: BuildingView = main.interiors.view_of("copper_owl").host
	assert_eq(_view().indoors, host.rect, "inside: the club's building is dry")
	var r: Rect2 = host.rect
	assert_eq(_hole(_view().fog_material), Vector4(r.position.x, r.position.y, r.size.x, r.size.y), "no street fog in it")
	assert_eq(_hole(_view().feet_material), _hole(_view().fog_material), "nor the fog at the walls' feet")
	var rain_hole: Vector4 = (_view().rain_rect.material as ShaderMaterial).get_shader_parameter("hole")
	assert_gt(rain_hole.z, 0.0, "the rain stops at its walls on screen")
	assert_lt(main.soundscape.level.rain_db, outdoors_rain - 3.0, "the rain heard through the walls")
	# out again: nothing left over
	await walk_to(owl.outside_door(0, 40.0), 4.0, 240)
	await wait_physics_frames(30)
	assert_false(_view().indoors.has_area())
	assert_eq(_hole(_view().fog_material), Vector4.ZERO)
	assert_eq((_view().rain_rect.material as ShaderMaterial).get_shader_parameter("hole"), Vector4.ZERO)


func test_the_same_in_a_streamed_district() -> void:
	main.weather.force("fog")
	main.world.load_now("halloran")
	var data: InteriorPlan = (main.world.layouts.halloran as DistrictLayout).interiors[0]
	walker().place(data.outside_door(0, 40.0), (-(data.doors[0].side as Vector2)).angle())
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	assert_true(await walk_in_to(main.interiors.plan_named(data.id), String(data.spots[0].id)))
	await wait_physics_frames(10)
	var host: BuildingView = main.interiors.view_of(data.id).host
	assert_eq(_view().indoors, host.rect, "%s keeps the fog out" % data.name)
	var c: City = main.world.city_of("halloran")
	assert_true(c.fog_layer.visible, "the square's fog is still in its streets")
	assert_eq(c.fog_layer.material, _view().fog_material, "drawn with the material that has the hole")


func test_thunder_in_a_downpour_duller_indoors() -> void:
	# find tonight's first clap and run the clock up to it
	main.weather.force("rain")
	var claps: Array = main.weather.thunder_between(main.clock.minute, main.clock.rules.dawn_minute)
	assert_false(claps.is_empty(), "a wet night has thunder in it")
	var clap: Dictionary = claps[0]
	main.clock.set_time(float(clap.minute) - 0.5)
	main.weather.advance(main.clock.minute)
	walker().place(STREETCAR_STOP, 0.0)
	var heard: int = main.soundscape.thunder_heard.size()
	for i in 120:
		await wait_physics_frames(1)
		if main.soundscape.thunder_heard.size() > heard:
			break
	assert_gt(_view().flash, 0.0, "the street lit for a breath")
	await wait_physics_frames(30)
	assert_eq(main.soundscape.thunder_heard.size(), heard + 1, "the clap, once")
	assert_false(main.soundscape.thunder_heard[-1].indoors)
	await wait_physics_frames(60)
	assert_eq(_view().flash, 0.0, "and dark again")
	# indoors: the same clap duller (the street bus is low-passed in a room, and quieter)
	var outdoor_db: float = main.soundscape.thunder_heard[-1].db
	await talk_to("copper_owl", "augie")
	await answer_with("bye")
	await wait_physics_frames(5)
	main.soundscape.thunder(clap.near)
	assert_true(main.soundscape.thunder_heard[-1].indoors)
	assert_lt(main.soundscape.thunder_heard[-1].db, outdoor_db, "quieter through the walls")
	assert_eq(main.soundscape.thunder_player.bus, Soundscape.BUS_STREET, "and through the street's dull bus")


## M013: the weather turning while Danny is inside a room in a streamed
## district: the rain and fog arrive outside only; the rain is heard dull.
func test_weather_turning_while_inside_a_streamed_room() -> void:
	main.weather.force("clear")
	main.world.load_now("halloran")
	var hall: InteriorPlan = main.interiors.plan_named("city_hall")
	walker().place(hall.inside_door(0, 60.0), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(10)
	assert_not_null(main.interiors.current)
	main.weather.force("rain_fog")
	await wait_physics_frames(150)
	var host: BuildingView = main.interiors.view_of("city_hall").host
	assert_eq(_view().indoors, host.rect, "the hall stays dry as the weather turns")
	var rain_hole: Vector4 = (_view().rain_rect.material as ShaderMaterial).get_shader_parameter("hole")
	assert_gt(rain_hole.z * rain_hole.w, 0.0, "no rain on the hall's part of the screen")
	assert_eq(_hole(_view().fog_material), Vector4(host.rect.position.x, host.rect.position.y, host.rect.size.x, host.rect.size.y))
	var inside_db: float = main.soundscape.level.rain_db
	walker().place(hall.outside_door(0, 60.0), PI / 2)
	await wait_physics_frames(150)
	assert_false(_view().indoors.has_area(), "out on the steps: the rain all round")
	assert_gt(main.soundscape.level.rain_db, inside_db + 3.0, "louder out here")


## M013: a game saved in a room in the rain loads with the room dry.
func test_a_room_saved_in_the_rain_loads_dry() -> void:
	var save := OS.get_user_data_dir().path_join("test_weather_room_%d.json" % Time.get_ticks_usec())
	main.save_path = save
	main.weather.force("rain")
	var quilty: InteriorPlan = main.interiors.plan_named("quilty_office")
	walker().place(quilty.inside_door(0, 40.0), -PI / 2)
	await wait_physics_frames(5)
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = false
	main.save_path = save
	main.settings_path = ""
	main.quiet_streets = true
	add_child_autofree(main)
	main.weather.force("rain")
	await wait_physics_frames(5)
	assert_eq(main.interiors.current.id, "quilty_office")
	assert_eq(_view().indoors, main.interiors.view_of("quilty_office").host.rect, "dry from the first frame")
	DirAccess.remove_absolute(save)


## M013: in and out of a door again and again in a downpour: one rain bed and
## one downpour bed, never a second; no hole left behind.
func test_one_rain_bed_however_often_in_and_out() -> void:
	main.weather.force("rain")
	var owl: InteriorPlan = main.interiors.plan_named("copper_owl")
	for i in 4:
		walker().place(owl.inside_door(0, 30.0), -PI / 2)
		await wait_physics_frames(20)
		walker().place(owl.outside_door(0, 40.0), PI / 2)
		await wait_physics_frames(20)
	var streams := [(main.soundscape.beds.rain as AudioStreamPlayer).stream, (main.soundscape.beds.downpour as AudioStreamPlayer).stream]
	var rain_beds := 0
	for n in main.soundscape.find_children("*", "AudioStreamPlayer", true, false):
		if (n as AudioStreamPlayer).stream in streams and (n as AudioStreamPlayer).playing:
			rain_beds += 1
	assert_eq(rain_beds, 2, "the rain bed and the downpour bed, once each")
	assert_false(_view().indoors.has_area())
	assert_eq((_view().rain_rect.material as ShaderMaterial).get_shader_parameter("hole"), Vector4.ZERO)
