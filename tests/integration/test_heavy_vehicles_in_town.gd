extends "res://tests/support/city_test.gd"
## M009 the dump truck in the Riverfront Yards and the school bus in Halloran
## Square, in the game: parked where they belong, somebody else's (E takes
## them, a theft like any other, and a copper who sees it notices); driven
## with the normal controls out of the coal dock and round a corner, down
## Halloran Avenue and round onto Pruitt Street; heavy against a parked car
## and solid against a wall; carried across a district border and back, the
## same vehicle all the way, never doubled.


func _go(p: Vector2, rot: float = 0.0) -> void:
	walker().place(p, rot)
	main.camera.snap_to(player().body())


func _built(id: String, spec_type: String) -> Car:
	var l: DistrictLayout = main.world.layouts[id]
	var spec: Dictionary = l.cars.filter(func(s: Dictionary) -> bool: return s.type == spec_type)[0]
	_go(spec.pos + Vector2(0, -80).rotated(spec.rot + PI / 2))
	main.world.load_now(id)
	for c in main.cars:
		if c.vehicle.id == spec_type:
			return c
	return null


func _spec(id: String, spec_type: String) -> Dictionary:
	return (main.world.layouts[id] as DistrictLayout).cars.filter(func(s: Dictionary) -> bool: return s.type == spec_type)[0]


func _never_in_a_building(c: Car, frames: int, l: DistrictLayout) -> bool:
	for i in frames:
		await wait_physics_frames(1)
		if l.is_in_building(c.global_position):
			return false
	return true


func test_the_coal_truck_on_its_dock() -> void:
	var truck := _built("yards", "dump_truck")
	assert_not_null(truck, "Brennan's truck is there when the yards are")
	var spec := _spec("yards", "dump_truck")
	assert_lt(truck.global_position.distance_to(spec.pos), 1.0)
	var i: int = main.cars.find(truck)
	assert_eq(main.thefts.owner(i), "Brennan Coal & Ice")
	# the yards' copper happens to be watching
	var cop: PoliceOfficer = main._districts.yards.officer
	cop.body.place(truck.global_position + Vector2(-120, -60), 0.0)
	_go(truck.global_position + Vector2(-34, 20), 0.0)
	await wait_physics_frames(3)
	assert_string_contains(main.hud.prompt_label.text, "Take the Dump Truck (not yours)")
	var witnessed: int = main.thefts_witnessed
	await press_e()
	assert_eq(player().car, truck)
	assert_true(main.thefts.is_stolen(i), "a theft like any other")
	assert_eq(main.thefts_witnessed, witnessed + 1, "and the copper saw it")
	cop.body.place(cop.body.global_position + Vector2(-2000, 0), 0.0)  # out of the way of the test drive
	cop.reset()
	# up Wharf Street and left onto Front Street, away west, with the normal pedals and wheel
	var l: DistrictLayout = main.world.layouts.yards
	var front_y: float = l.origin.y + 57.0  # Front Street, westbound side
	var ticks: int = await drive_route(truck, [Vector2(truck.global_position.x, l.origin.y + 260.0),
		Vector2(truck.global_position.x - 160.0, front_y), Vector2(truck.global_position.x - 700.0, front_y)], 150.0, 60 * 40)
	assert_lt(ticks, 60 * 40, "up the street and round the corner")
	assert_lt(absf(truck.global_position.y - front_y), 60.0, "on Front Street")
	assert_false(l.is_in_building(truck.global_position))


## M010: the truck the player could not find. It stands where a driver coming into the yards
## sees it - at the kerb of Wharf Street, the road down from the ward, under a lamp, in the open -
## and the works trucks that are only scenery say so, and point to it.
func test_the_coal_truck_is_found() -> void:
	var truck := _built("yards", "dump_truck")
	var l: DistrictLayout = main.world.layouts.yards
	var wharf: Rect2 = l.streets.filter(func(st: Dictionary) -> bool: return st.name == "Wharf Street")[0].rect
	assert_true(wharf.has_point(truck.global_position), "on Wharf Street itself")
	var lamp_near := l.lamps.any(func(p: Vector2) -> bool: return p.distance_to(truck.global_position) < 120.0)
	assert_true(lamp_near, "under a street lamp")
	for k in [-1.0, 1.0]:
		var end: Vector2 = truck.global_position + Vector2(0, k * truck.vehicle.size.x * 0.5)
		assert_false(l.is_in_building(end), "all of it in the open")
	for loop in l.drive_loops:
		var pts: PackedVector2Array = loop
		for j in pts.size():
			var a: Vector2 = pts[j]
			var b: Vector2 = pts[(j + 1) % pts.size()]
			var q := Geometry2D.get_closest_point_to_segment(truck.global_position, a, b)
			assert_gt(q.distance_to(truck.global_position), truck.vehicle.size.y * 0.5 + 18.0, "clear of the traffic's lane")
	# beside one of the freight yard's works trucks: scenery, and it says where to look
	var scenery: Dictionary = l.props.filter(func(p: Dictionary) -> bool: return String(p.kind).begins_with("props/truck"))[0]
	_go(scenery.pos + Vector2(0, 52), -PI / 2)
	await wait_physics_frames(3)
	assert_string_contains(main.hud.prompt_label.text, "chained up for the night")
	await press_e()
	assert_true(player().on_foot(), "it cannot be taken")
	assert_string_contains(main.hud.notice_label.text, "Brennan's coal truck on Wharf Street")


func test_the_school_bus_by_the_church() -> void:
	var bus := _built("halloran", "school_bus")
	assert_not_null(bus, "St. Brendan's bus is there when the square is")
	var i: int = main.cars.find(bus)
	assert_eq(main.thefts.owner(i), "St. Brendan's parish school")
	_go(bus.global_position + Vector2(40, 0), PI)
	await wait_physics_frames(3)
	assert_string_contains(main.hud.prompt_label.text, "Take the School Bus (not yours)")
	await press_e()
	assert_eq(player().car, bus)
	# down Halloran Avenue and left onto Pruitt Street
	var l: DistrictLayout = main.world.layouts.halloran
	var pruitt: float = l.origin.y + 2828.0
	var x0: float = bus.global_position.x
	var ticks: int = await drive_route(bus, [Vector2(x0, pruitt - 180.0), Vector2(x0 + 150.0, pruitt), Vector2(x0 + 600.0, pruitt)],
		150.0, 60 * 40)
	assert_lt(ticks, 60 * 40, "round the corner onto Pruitt Street")
	assert_lt(absf(bus.global_position.y - pruitt), 60.0)
	assert_false(l.is_in_building(bus.global_position))


func test_heavy_against_a_parked_car_and_solid_against_a_wall() -> void:
	var truck := _built("yards", "dump_truck")
	main._put_away(truck, false)
	_go(main.layout.spawn)
	# along Marlowe Avenue in the ward, a sedan parked in its way
	await park(truck, Vector2(900, 640), 0.0)
	var sedan: Car = main.cars.filter(func(c: Car) -> bool: return c.vehicle.id == "sedan" and c != main.my_car())[0]
	await park(sedan, Vector2(1180, 640), 0.0)
	await seat_in(truck)
	cmd = PlayerCommand.make(Vector2(0, -1))
	for f in 60 * 6:
		await wait_physics_frames(1)
		if sedan.global_position.x > 1200.0:
			break
	assert_gt(sedan.global_position.x, 1200.0, "the sedan is shoved along")
	await wait_physics_frames(10)
	assert_gt(truck.model.forward_speed(), 20.0, "and the truck rolls on")
	cmd = PlayerCommand.make(Vector2(0, 1))
	await wait_physics_frames(60 * 3)
	# nose first into the Copper Owl's front wall: it stops at the wall, never in it
	cmd = PlayerCommand.new()
	await park(truck, Vector2(2200, 600), -PI / 2)
	cmd = PlayerCommand.make(Vector2(0, -1))
	assert_true(await _never_in_a_building(truck, 60 * 4, main.layout), "never through the wall")
	assert_lt(truck.model.forward_speed(), 40.0, "it stopped at the wall")
	# a glancing scrape along the wall: it slides on
	cmd = PlayerCommand.new()
	await park(truck, Vector2(2100, 520), -PI / 2 + 0.35)
	cmd = PlayerCommand.make(Vector2(0, -1))
	assert_true(await _never_in_a_building(truck, 60 * 3, main.layout))
	cmd = PlayerCommand.new()


func test_the_bus_across_the_border_and_back() -> void:
	var bus := _built("halloran", "school_bus")
	var count: int = main.cars.size()
	main._put_away(bus, false)
	# at the east end of Marlowe Avenue in the square, nose east
	await park(bus, Vector2(-1950, 640), 0.0)
	await seat_in(bus)
	cmd = PlayerCommand.make(Vector2(0, -1))
	for f in 60 * 12:
		await wait_physics_frames(1)
		if bus.global_position.x > -1000.0:
			break
	cmd = PlayerCommand.make(Vector2(0, 1))
	await wait_physics_frames(60 * 2)
	cmd = PlayerCommand.new()
	assert_gt(bus.global_position.x, -1300.0, "into the ward without a stop")
	assert_eq(main.world.current, "riverside")
	# M012: the streamer held still while we look - the bus stands inside its load
	# distance, so it would otherwise build the square again within a frame or two
	# (the race that made this test flaky; see docs/BACKLOG.md, 2026-11-19)
	main.world.enabled = false
	main.world.unload("halloran")
	await wait_physics_frames(5)
	assert_false(main.world.is_ready("halloran"))
	assert_true(is_instance_valid(bus) and bus.visible and not bus.has_meta("away"), "Danny's bus is not put away with the square")
	assert_eq(player().car, bus)
	assert_eq(main.cars.size(), count, "no car made or lost")
	main.world.enabled = true
	# back west: the square is built again round him - and there is still one bus
	await park(bus, Vector2(-1750, 640), PI)
	main.world.load_now("halloran")
	await wait_physics_frames(5)
	assert_eq(main.cars.size(), count, "no second bus")
	assert_eq(main.cars.filter(func(c: Car) -> bool: return c.vehicle.id == "school_bus").size(), 1)
	assert_eq(player().car, bus)
