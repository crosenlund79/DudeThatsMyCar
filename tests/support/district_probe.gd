extends SceneTree
## M008 district streaming measurements (needs a display, e.g. xvfb-run):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -s tests/support/district_probe.gd
## Drives Danny's sedan across each border with the normal pedal and prints:
## how long each district took to build (work, frames, worst frame, slowest
## step), frame times before, during and after the build and at the border,
## memory and nodes with one district and with two, unloading and rebuilding,
## and the frame rate in each district with and without its street life and lamps.

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
	print("  %-46s %5.1f fps   worst frame %5.1f ms" % [label, frames / seconds, worst / 1000.0])


## Drives `c` with W from `from` heading `rot` until `done` holds; prints frame times by phase.
func _drive(label: String, c: Car, from: Vector2, rot: float, border: Callable, done: Callable) -> void:
	main.fleet.put_away(c, false)  # it may have been put away with a district it was left in
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
	for i in 60 * 30:
		cmd = PlayerCommand.make(Vector2(0, -1))
		await process_frame
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
	print("  %s" % label)
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
		cmd = PlayerCommand.make(Vector2(0, 1))  # brake
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


func _wait_until(cond: Callable, frames: int = 1200) -> void:
	for i in frames:
		if cond.call():
			return
		await process_frame


func _run() -> void:
	var world: DistrictStreamer = main.world
	print("M008 district probe (software OpenGL unless a GPU is present)")
	for i in 30:
		await process_frame
	var mem1 := _mem_mb()
	var nodes1 := _nodes()
	print("  one district (the ward):  %.1f MB static, %d nodes" % [mem1, nodes1])
	await _fps("the ward, on foot at home")
	var sedan: Car = main.fleet.cars[7]
	# south into the Riverfront Yards
	await _drive("driving south down Kessler Street into the Riverfront Yards", sedan, Vector2(1678, 1250), PI / 2,
		func(p: Vector2) -> float: return p.y - 2700.0, func(p: Vector2) -> bool: return p.y > 3300.0)
	_stats("yards")
	var mem2 := _mem_mb()
	var nodes2 := _nodes()
	print("  two districts (ward + yards): %.1f MB static (+%.1f), %d nodes (+%d)" % [mem2, mem2 - mem1, nodes2, nodes2 - nodes1])
	if not main.player.on_foot():
		main.player.exit_car()
	await _fps("the Riverfront Yards, on foot")
	for s in main.streets():
		if s != main.street:
			s.clear()
	await _fps("  the same, its street life cleared")
	var yc: City = world.city_of("yards")
	for l in yc.lamp_lights:
		l.enabled = false
	await _fps("  the same, its street lamps off too")
	for l in yc.lamp_lights:
		l.enabled = true
	# home: the yards are let go
	main.walker.place(main.layout.spawn, 0.0)
	var worst_unload := 0
	var last := Time.get_ticks_usec()
	var frames := 0
	while world.is_ready("yards") or world.is_freeing():
		await process_frame
		var now := Time.get_ticks_usec()
		if not world.is_ready("yards"):
			worst_unload = maxi(worst_unload, now - last)
			frames += 1
		last = now
	for i in 30:
		await process_frame
	print("  unloading the yards: let go and taken apart over %d frames, worst frame %.1f ms (whole frame, software renderer)" % [frames, worst_unload / 1000.0])
	print("  after unloading the yards: %.1f MB static, %d nodes" % [_mem_mb(), _nodes()])
	_stats("yards")
	# west into Halloran Square
	await _drive("driving west along Marlowe Avenue into Halloran Square", sedan, Vector2(-100, 640), PI,
		func(p: Vector2) -> float: return p.x + 1700.0, func(p: Vector2) -> bool: return p.x < -2700.0)
	_stats("halloran")
	print("  two districts (ward + square): %.1f MB static, %d nodes" % [_mem_mb(), _nodes()])
	if not main.player.on_foot():
		main.player.exit_car()
	await _fps("Halloran Square, on foot")
	for s in main.streets():
		if s != main.street:
			s.clear()
	await _fps("  the same, its street life cleared")
	# back into the ward and on to the yards again: rebuilt
	main.walker.place(Vector2(1600, 2300), 0.0)
	await _wait_until(func() -> bool: return world.is_ready("yards"))
	_stats("yards")
	print("  loaded now: %s; cars %d (never duplicated)" % [world.ready_ids(), main.fleet.cars.size()])
	quit()
