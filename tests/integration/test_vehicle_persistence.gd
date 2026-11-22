extends "res://tests/support/city_test.gd"
## M013 "Car was gone when I loaded game": a game saved at the wheel loads with
## Danny behind that same wheel, where and which way the car stood, in the
## right district, the controls working; a car he left in the street is where
## he left it (in any district, even one not built yet); a car he took is
## still taken (no second theft); Dutch's crate is still in its boot; no car is
## ever made twice or lost; a car never jumps home when its district is let go
## and built again; a saved place a car cannot stand on puts it back at its own
## parking place. Sleeping still brings every car back to its owner's spot.

var _save := ""


func before_each() -> void:
	await super()
	_save = OS.get_user_data_dir().path_join("test_vehicle_persistence_%d.json" % Time.get_ticks_usec())
	main.save_path = _save


func after_each() -> void:
	super()
	if FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _reload() -> void:
	main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = false
	main.save_path = _save
	main.settings_path = ""
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(3)


func _street(l: DistrictLayout, street_name: String) -> Rect2:
	for st in l.streets:
		if st.name == street_name:
			return st.rect
	return Rect2()


func _id_of(c: Car) -> String:
	return main.fleet.ids[main.fleet.cars.find(c)]


func _car(id: String) -> Car:
	var i: int = main.fleet.ids.find(id)
	return main.fleet.cars[i] if i >= 0 else null


func _count(vehicle_id: String) -> int:
	return main.fleet.cars.filter(func(c: Car) -> bool: return c.vehicle.id == vehicle_id).size()


func _assert_no_twins() -> void:
	var seen := {}
	for id in main.fleet.ids:
		assert_false(seen.has(id), "one car called %s" % id)
		seen[id] = true
	assert_eq(main.fleet.ids.size(), main.fleet.cars.size())


func test_saved_at_the_wheel_in_halloran_square() -> void:
	main.world.load_now("halloran")
	var h: DistrictLayout = main.world.layouts.halloran
	var marlowe := _street(h, "Marlowe Avenue")
	var car := roadster()
	var id := _id_of(car)
	await park(car, Vector2(marlowe.end.x - 300.0, marlowe.get_center().y + 30.0), PI)
	await seat_in(car)
	assert_eq(player().car, car)
	cmd = PlayerCommand.make(Vector2(0, -1))  # driving west along Marlowe Avenue
	await wait_physics_frames(50)
	cmd = PlayerCommand.new()
	await wait_physics_frames(2)
	assert_eq(main.world.current, "halloran")
	var at := car.global_position
	var heading := car.global_rotation
	var cars_before: int = main.fleet.cars.size()
	var notices_before: int = main.fleet.theft_incidents
	await _reload()
	assert_eq(main.world.current, "halloran", "the square is built again")
	assert_true(main.world.is_ready("halloran"))
	assert_false(player().on_foot(), "behind the wheel")
	car = player().car
	assert_not_null(car)
	assert_eq(_id_of(car), id, "the same car")
	assert_lt(car.global_position.distance_to(at), 1.0, "where it stood")
	assert_lt(absf(angle_difference(car.global_rotation, heading)), 0.01, "facing the same way")
	assert_true(car.visible and not car.has_meta("away"), "on the street, solid")
	assert_ne(car.collision_layer, 0)
	assert_eq(main.camera.target, car, "the camera on the car")
	assert_false(walker().visible, "Danny in the seat, not beside it")
	assert_true(main.fleet.thefts.is_stolen(main.fleet.cars.find(car)), "still a stolen car")
	assert_eq(main.fleet.theft_incidents, 0, "loading is not a second theft")
	assert_eq(main.fleet.cars.size(), cars_before, "no car lost, none made twice (the square's cars made with it)")
	_assert_no_twins()
	var spec: Dictionary = main.fleet.specs[main.fleet.cars.find(car)]
	assert_false(main.fleet.cars.any(func(c: Car) -> bool: return c != car and c.global_position.distance_to(spec.pos) < 1.0),
		"nothing left standing at its old parking place")
	# the controls work
	cmd = PlayerCommand.make(Vector2(0, -1))
	await wait_physics_frames(40)
	cmd = PlayerCommand.new()
	assert_gt(car.global_position.distance_to(at), 10.0, "it drives off")
	assert_eq(notices_before, 1, "(it was taken once, before the save)")


func test_left_in_the_street_beside_it() -> void:
	var sedan: Car = main.fleet.my_car()
	var id := _id_of(sedan)
	await seat_in(sedan)
	await park(sedan, Vector2(2300, 560), 0.0)
	cmd = PlayerCommand.make(Vector2(0, 1))
	await wait_physics_frames(20)
	cmd = PlayerCommand.new()
	await press_e()
	for i in 120:
		await wait_physics_frames(1)
		if player().on_foot():
			break
	assert_true(player().on_foot(), "out, right after")
	var at := sedan.global_position
	var heading := sedan.global_rotation
	var danny := walker().global_position
	await _reload()
	assert_true(player().on_foot(), "on foot as he was")
	assert_lt(walker().global_position.distance_to(danny), 2.0)
	sedan = _car(id)
	assert_lt(sedan.global_position.distance_to(at), 1.0, "his car where he left it, not back at home")
	assert_lt(absf(angle_difference(sedan.global_rotation, heading)), 0.01)
	assert_false(main.fleet.thefts.is_stolen(main.fleet.cars.find(sedan)), "his own car")
	assert_false(sedan.driven, "parked")
	_assert_no_twins()


func test_saved_right_after_getting_in() -> void:
	var sedan: Car = main.fleet.my_car()
	await seat_in(sedan)
	await _reload()
	assert_false(player().on_foot())
	assert_eq(player().car, main.fleet.my_car(), "his own car")
	assert_true(player().car.driven)


func test_a_truck_from_the_yards_left_in_the_ward() -> void:
	main.world.load_now("yards")
	var truck: Car = car_of_type("dump_truck")
	var id := _id_of(truck)
	assert_true(id.begins_with("yards/"), "named for the district that parks it")
	await seat_in(truck)
	await park(truck, Vector2(1690, 1400), -PI / 2)  # up Kessler Street, in the ward
	await press_e()
	for i in 120:
		await wait_physics_frames(1)
		if player().on_foot():
			break
	main.world.unload("yards")
	await wait_physics_frames(3)
	assert_true(truck.visible, "the truck stays where it was left when the yards go")
	var at := truck.global_position
	await _reload()
	assert_false(main.world.is_ready("yards"), "the yards not built")
	truck = _car(id)
	assert_not_null(truck, "the truck is made all the same")
	assert_lt(truck.global_position.distance_to(at), 1.0, "in the ward where he left it")
	assert_true(truck.visible and not truck.has_meta("away"))
	assert_true(main.fleet.thefts.is_stolen(main.fleet.cars.find(truck)), "still Brennan's, still taken")
	main.world.load_now("yards")
	await wait_physics_frames(3)
	assert_eq(_count("dump_truck"), 1, "no second truck at Brennan's when the yards are built")
	assert_lt(_car(id).global_position.distance_to(at), 1.0)
	_assert_no_twins()


func test_a_car_never_jumps_home_when_its_district_goes() -> void:
	main.world.load_now("yards")
	var truck: Car = car_of_type("dump_truck")
	var y: DistrictLayout = main.world.layouts.yards
	var spot := y.cars.filter(func(s: Dictionary) -> bool: return s.type == "dump_truck")[0].pos as Vector2 + Vector2(0, 160)
	await park(truck, spot, 0.0)
	walker().place(Vector2(2350, 600), 0.0)  # back in the ward
	main.camera.snap_to(walker())
	await wait_physics_frames(2)
	main.world.enabled = false  # the streamer held still while the yards go and come back
	main.world.unload("yards")
	await wait_physics_frames(3)
	assert_true(truck.has_meta("away"), "put away with the yards")
	main.world.load_now("yards")
	await wait_physics_frames(3)
	assert_false(truck.has_meta("away"))
	assert_lt(truck.global_position.distance_to(spot), 1.0, "where it was left, not at Brennan's")
	# and in the yards on foot beside it, saved and loaded
	main.world.enabled = true
	walker().place(spot + Vector2(0, 60), 0.0)
	await wait_physics_frames(3)
	await _reload()
	assert_eq(main.world.current, "yards")
	assert_lt(car_of_type("dump_truck").global_position.distance_to(spot), 1.0)


func test_a_place_no_car_can_stand_on() -> void:
	var sedan: Car = main.fleet.my_car()
	var id := _id_of(sedan)
	await seat_in(sedan)
	main.save_game()
	var data := SaveGame.read(_save)
	var b: Dictionary = main.layout.buildings[0]
	data.cars.moved[id] = {"x": (b.rect as Rect2).get_center().x, "y": (b.rect as Rect2).get_center().y, "rot": 0.0}
	data.place.x = (b.rect as Rect2).get_center().x
	data.place.y = (b.rect as Rect2).get_center().y
	SaveGame.write(_save, data)
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = false
	main.save_path = _save
	main.settings_path = ""
	main.quiet_streets = true
	add_child_autofree(main)
	await wait_physics_frames(3)
	sedan = _car(id)
	var spec: Dictionary = main.fleet.specs[main.fleet.cars.find(sedan)]
	assert_lt(sedan.global_position.distance_to(spec.pos), 1.0, "back at its own parking place, not inside a wall")
	assert_eq(player().car, sedan, "and Danny still in it")
	assert_false(main.layout.is_in_building(sedan.global_position))


func test_dutchs_crate_stays_in_the_boot() -> void:
	var sedan: Car = main.fleet.my_car()
	main.rackets.opportunities.crate = "loaded"
	main.fleet.set_cargo(sedan, true)
	await _reload()
	assert_eq(main.rackets.opportunities.crate, "loaded")
	assert_true(main.fleet.my_car().has_meta("cargo"), "the crate still in the boot")


func test_an_old_save_with_a_crate_and_no_cars() -> void:
	main.rackets.opportunities.crate = "loaded"
	main.save_game()
	var data := SaveGame.read(_save)
	data.erase("cars")  # a game saved before M013
	SaveGame.write(_save, data)
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = false
	main.save_path = _save
	main.settings_path = ""
	main.quiet_streets = true
	add_child_autofree(main)
	await wait_physics_frames(3)
	assert_eq(main.rackets.opportunities.crate, "taken", "the crate back on Dutch's kerb, not lost")


func test_sleeping_still_brings_them_home() -> void:
	var sedan: Car = main.fleet.my_car()
	var spec: Dictionary = main.fleet.specs[main.fleet.cars.find(sedan)]
	await park(sedan, Vector2(2300, 560), 0.0)
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(3)
	await _reload()
	assert_lt(main.fleet.my_car().global_position.distance_to(spec.pos), 1.0, "outside the flat the next evening")
