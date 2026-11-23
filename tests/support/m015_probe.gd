extends SceneTree
## M015 measurements (needs a display, e.g. xvfb-run):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -s tests/support/m015_probe.gd
## Drives Danny's sedan north up Wharf Street under the railroad into Lincoln
## Terrace, then south down Halloran Avenue from the square into Canal Market,
## then east along Front Street into the yards (a fourth district wanted: one
## is let go to make room), printing each build (work, frames, worst frame,
## slowest step), frame times by phase, memory and nodes with one, two and
## three districts built, and the frame rate in the new quarters - on Lincoln
## Boulevard, in the Paradise with its band and dancers, on Market Street under
## the El with its train, in the market hall, and in fog and rain - with and
## without the street life.

var main: Node2D
var cmd := PlayerCommand.new()


func _initialize() -> void:
	main = load("res://src/main/main.tscn").instantiate()
	main.save_path = ""
	main.settings_path = ""
	main.opening_enabled = false
	main.callouts_enabled = false
	main.command_source = func(_c): return cmd
	root.add_child(main)
	_run.call_deferred()


func _mem_mb() -> float:
	return Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0


func _nodes() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))


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


func _drive(label: String, c: Car, from: Vector2, rot: float, border: Callable, done: Callable) -> void:
	main.fleet.put_away(c, false)
	c.place(Transform2D(rot, from))
	c.model.position = from
	main.walker.place(from + Vector2(0, -40).rotated(rot), 0.0)
	await process_frame
	main.player.enter(c)
	for i in 10:
		await process_frame
	var phases := {"before the build": [], "while building": [], "at the border (±150 px)": [], "after": []}
	var last := Time.get_ticks_usec()
	var built := false
	var most := 0
	for i in 60 * 30:
		cmd = PlayerCommand.make(Vector2(0, -1))
		await process_frame
		most = maxi(most, main.world.loaded.size())
		var now := Time.get_ticks_usec()
		var dt := now - last
		last = now
		var building: bool = main.world.is_building()
		built = built or building
		var phase := "before the build"
		if building:
			phase = "while building"
		elif absf(border.call(c.global_position)) < 150.0:
			phase = "at the border (±150 px)"
		elif built:
			phase = "after"
		(phases[phase] as Array).append(dt)
		if done.call(c.global_position):
			break
	cmd = PlayerCommand.new()
	print("  %s (at most %d districts built)" % [label, most])
	for k in phases:
		var a: Array = phases[k]
		if a.is_empty():
			continue
		var total := 0
		var worst := 0
		for v in a:
			total += v
			worst = maxi(worst, v)
		print("    %-26s %4d frames   mean %5.1f ms   worst %5.1f ms" % [k, a.size(), total / 1000.0 / a.size(), worst / 1000.0])
	for k in 20:
		cmd = PlayerCommand.make(Vector2(0, 1))
		await process_frame
	cmd = PlayerCommand.make(Vector2.ZERO, true)
	await process_frame
	cmd = PlayerCommand.new()
	for k in 30:
		await process_frame


func _stats(id: String) -> void:
	var st: Dictionary = main.world.stats[id]
	print("  %s: build #%d took %.1f ms of work over %d frames (%.0f ms start to finish); worst frame %.1f ms; slowest step %s %.1f ms; last unload %.1f ms" % [
		id, st.builds, st.work_usec / 1000.0, st.frames, st.last_build_usec / 1000.0, st.worst_frame_usec / 1000.0,
		st.get("slowest_step", "?"), st.worst_step_usec / 1000.0, st.unload_usec / 1000.0])


func _memory(label: String) -> void:
	print("  %-40s %.1f MB static, %d nodes  (built: %s)" % [label, _mem_mb(), _nodes(), ", ".join(main.world.ready_ids())])


func _stand(at: Vector2) -> void:
	main.walker.place(at, 0.0)
	main.camera.snap_to(main.walker)
	for i in 5:
		await process_frame


func _street_life(on: bool) -> void:
	for st in main.districts.streets():
		if on:
			st.recount_locals(true)
		else:
			st.clear()


func _run() -> void:
	print("M015 probe (software OpenGL unless a GPU is present: %s)" % RenderingServer.get_video_adapter_name())
	main.weather.force("clear")
	main.clock.set_time(22 * 60.0 + 30.0)
	for i in 30:
		await process_frame
	_memory("one district (the ward)")
	await _fps("the ward, on foot at home")
	var sedan: Car = main.fleet.cars[7]
	# north under the railroad into Lincoln Terrace
	await _drive("driving north up Wharf Street, under the railroad, into Lincoln Terrace", sedan, Vector2(3328, -250), -PI / 2,
		func(p: Vector2) -> float: return p.y + 1300.0, func(p: Vector2) -> bool: return p.y < -1900.0)
	_stats("terrace")
	_memory("two districts (the ward, the terrace)")
	await _fps("driving on Wharf Street in the terrace")
	main.weather.force("clear")
	await _stand(Vector2(2900, -2440))
	await _fps("Lincoln Boulevard, the Belvedere (street life)")
	_street_life(false)
	await _fps("Lincoln Boulevard (no street life)")
	_street_life(true)
	var paradise: InteriorPlan = main.interiors.plan_named("paradise")
	await _stand(paradise.spots[1].pos)
	await _fps("in the Paradise: the band, the dancers")
	# south down Halloran Avenue into Canal Market (the square built first)
	await _stand(main.layout.spawn)
	main.world.load_now("halloran")
	for i in 120:
		await process_frame
	await _drive("driving south down Halloran Avenue into Canal Market", sedan, Vector2(-3472, 1500), PI / 2,
		func(p: Vector2) -> float: return p.y - 2700.0, func(p: Vector2) -> bool: return p.y > 3250.0)
	_stats("market")
	_memory("three districts (ward, square, market)")
	await _stand(Vector2(-3500, 3480))
	var city: City = main.world.city_of("market")
	await _fps("Market Street under the El (train %s)" % ("running" if city.el_train.running else "standing"))
	_street_life(false)
	await _fps("Market Street (no street life)")
	_street_life(true)
	var hall: InteriorPlan = main.interiors.plan_named("market_hall")
	await _stand(hall.spots[1].pos)
	await _fps("in the Canal Market Hall")
	await _stand(Vector2(-3500, 3480))
	main.weather.force("fog")
	for i in 60:
		await process_frame
	await _fps("Market Street in fog")
	main.weather.force("rain")
	for i in 60:
		await process_frame
	await _fps("Market Street in rain")
	main.weather.force("clear")
	# east along Front Street into the yards: four wanted, one let go
	await _drive("driving east along Front Street into the Riverfront Yards", sedan, Vector2(-2200, 2810), 0.0,
		func(p: Vector2) -> float: return p.x + 1700.0, func(p: Vector2) -> bool: return p.x > -1000.0)
	_stats("yards")
	for id in ["halloran", "market"]:
		if main.world.stats.has(id):
			_stats(id)
	_memory("after the yards (one let go)")
	quit()
