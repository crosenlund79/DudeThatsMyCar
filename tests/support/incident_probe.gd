extends SceneTree
## M009 measurements (needs a display, e.g. xvfb-run):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -s tests/support/incident_probe.gd
## Prints what the city's own incidents and Danny's opportunities cost: a
## whole night of incidents run as state alone; the per-frame work (the
## incident clock, the incident views, the contacts) with nothing going on
## and with two incidents in view; the frame rate on foot with and without
## them; and the same in the yards with Dutch and Brennan's truck about.

var main: Node2D
var cmd := PlayerCommand.new()


func _initialize() -> void:
	main = load("res://src/main/main.tscn").instantiate()
	main.save_path = ""
	main.settings_path = ""
	main.opening_enabled = false
	main.command_source = func(_c): return cmd
	root.add_child(main)
	_run.call_deferred()


func _fps(label: String, seconds: float = 2.5) -> void:
	for i in 15:
		await process_frame
	var t0 := Time.get_ticks_usec()
	var frames := 0
	var worst := 0
	var last := t0
	while Time.get_ticks_usec() - t0 < int(seconds * 1000000.0):
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxi(worst, now - last)
		last = now
		frames += 1
	print("  %-58s %5.1f fps   worst frame %5.1f ms" % [label, frames / seconds, worst / 1000.0])


## The M009 per-frame work, timed by itself (called again outside the frame), mean and worst.
func _m009_cost(label: String, frames: int = 240) -> void:
	var total := 0
	var worst := 0
	for i in frames:
		await process_frame
		var t0 := Time.get_ticks_usec()
		main._advance_incidents()
		for e in main.rackets.opportunities.advance(main.clock.minute):
			main._opportunity_over(e)
		main.incident_views.refresh(main.camera.eye(), main.player.body().global_position, 1.0 / 60.0)
		main.opportunity_views.refresh(main.player.body().global_position)
		main._spot()
		var dt := Time.get_ticks_usec() - t0
		total += dt
		worst = maxi(worst, dt)
	print("  %-58s mean %6.3f ms   worst %6.3f ms" % [label, total / 1000.0 / frames, worst / 1000.0])


func _go(p: Vector2) -> void:
	main.walker.place(p, 0.0)
	main.camera.snap_to(main.walker)


func _run() -> void:
	print("M009 incident and opportunity probe (software OpenGL unless a GPU is present)")
	for i in 30:
		await process_frame
	# a whole night of incidents, as state alone, in two-minute steps (as the clock would)
	var model := StreetIncidents.new(main.incidents.spots)
	var t0 := Time.get_ticks_usec()
	var started := 0
	for night in range(1, 8):
		model.begin_night(night, float(main.night_rules.start_minute), float(main.night_rules.dawn_minute))
		var m := float(main.night_rules.start_minute)
		while m < float(main.night_rules.dawn_minute):
			m += 2.0 / 60.0  # a frame at a time: a game minute a second, 60 frames a second
			for e in model.advance(m):
				if e.event == "started":
					started += 1
	var night_ms := (Time.get_ticks_usec() - t0) / 1000.0 / 7.0
	print("  a night of incidents as state, frame by frame (%d frames): %.1f ms all told (%.4f ms a frame); %.1f incidents a night" % [
		int((main.night_rules.dawn_minute - main.night_rules.start_minute) * 30), night_ms,
		night_ms / ((main.night_rules.dawn_minute - main.night_rules.start_minute) * 30.0), started / 7.0])
	# in the ward, nothing going on
	main.incidents.plan = []
	main.street.clear()
	_go(Vector2(2300, 420))  # the same spot as with the incidents below
	await _m009_cost("the ward, nothing going on: M009 work a frame")
	await _fps("the ward on foot, nothing going on")
	# two incidents in view, Danny close by
	main.incidents.plan = [{"id": "a", "kind": "argument", "spot": "owl_kerb", "at": main.clock.minute + 0.5, "tries": 0},
		{"id": "b", "kind": "exchange", "spot": "owl_alley", "at": main.clock.minute + 0.5, "tries": 0}]
	_go(Vector2(1000, 1500))
	main.clock.set_time(main.clock.minute + 1.0)
	main._advance_incidents()
	_go(Vector2(2300, 420))
	for i in 10:
		await process_frame
	print("  incidents going on: %d, drawn: %d (people %d)" % [main.incidents.active.size(), main.incident_views.views.size(),
		get_nodes_in_group("incident_people").size()])
	await _m009_cost("the ward, two incidents in view: M009 work a frame")
	await _fps("the ward on foot, two incidents in view")
	# the yards: Dutch, his crate and Brennan's truck
	var l: DistrictLayout = main.world.layouts.yards
	_go(l.contacts[0].pos + Vector2(0, 60))
	t0 = Time.get_ticks_usec()
	main.world.load_now("yards")
	print("  the yards built at once (in one go, as a test does): %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	for i in 10:
		await process_frame
	await _m009_cost("the yards at Dutch's: M009 work a frame")
	await _fps("the yards on foot at Dutch's (truck parked on the dock)")
	# the school bus in Halloran Square, driven
	var h: DistrictLayout = main.world.layouts.halloran
	var bus_spec: Dictionary = h.cars.filter(func(x: Dictionary) -> bool: return x.type == "school_bus")[0]
	_go(bus_spec.pos + Vector2(-40, 0))
	main.world.load_now("halloran")
	for i in 10:
		await process_frame
	var bus: Car = main.cars.filter(func(x: Car) -> bool: return x.vehicle.id == "school_bus")[0]
	main.player.enter(bus)
	cmd = PlayerCommand.make(Vector2(0, -1))
	await _fps("Halloran Square, driving the school bus", 3.0)
	cmd = PlayerCommand.new()
	print("  cars %d, loaded %s" % [main.cars.size(), main.world.ready_ids()])
	quit()
