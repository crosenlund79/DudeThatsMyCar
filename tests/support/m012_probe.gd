extends SceneTree
## M012 measurements (needs a display, e.g. xvfb-run):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -s tests/support/m012_probe.gd
## Prints the frame rate on Marlowe Avenue in each weather (clear, rain, a
## downpour, fog, rain and fog), in a room with fog and rain outside, on the
## ward's border with Halloran Square in fog; the weather view's own work a
## frame; then the new rooms - building Halloran Square and the yards with
## their rooms, standing in City Hall and the freight shed - the people's
## call-outs a frame, the Bird's film, and the menu open.

var main: Node2D
var cmd := PlayerCommand.new()


func _initialize() -> void:
	main = load("res://src/main/main.tscn").instantiate()
	main.save_path = ""
	main.settings_path = ""
	main.opening_enabled = false
	main.command_source = func(_c): return PlayerCommand.make(cmd.move, cmd.interact, cmd.handbrake, cmd.aim)
	root.add_child(main)
	print("M012 probe (software OpenGL unless a GPU is present)")
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


func _place(p: Vector2, facing: float = -PI / 2) -> void:
	main.walker.place(p, facing)
	main.camera.snap_to(main.walker)
	for i in 20:
		await process_frame


func _weather_cost(label: String, frames: int = 120) -> void:
	var total := 0
	var cities := [main.city]
	for id in main.world.ready_ids():
		if id != main.layout.id:
			cities.append(main.world.city_of(id))
	for i in frames:
		await process_frame
		var t0 := Time.get_ticks_usec()
		main.weather_view.refresh(main.camera.view_rect(), main.camera.eye(), main.camera.zoom.x, cities, 1.0 / 60.0)
		total += Time.get_ticks_usec() - t0
	print("  %-58s mean %6.3f ms (the weather view's update)" % [label, total / 1000.0 / frames])


func _run() -> void:
	for i in 30:
		await process_frame
	main.street.clear()
	var street := Vector2(2350, 600)
	print(" Marlowe Avenue by the Copper Owl:")
	await _place(street)
	for st in ["clear", "rain", "fog", "rain_fog"]:
		main.weather.force(st)
		await _fps("weather: %s" % st)
	main.weather.force("rain")
	main.weather.minute = 0.0
	for m in range(0, 400):  # find a downpour on this night's course
		main.weather.minute = float(19 * 60 + 30 + m)
		if main.weather.downpour() > 0.9:
			break
	print("  (downpour %.2f, rain strength %.2f)" % [main.weather.downpour(), main.weather.rain_strength()])
	await _fps("weather: a downpour")
	await _weather_cost("in a downpour")
	main.weather.force("rain_fog")
	await _weather_cost("in rain and fog")
	print(" indoors (Quilty's office), rain and fog outside:")
	var q: InteriorPlan = main.interiors.plan_named("quilty_office")
	await _place(q.inside_door(0, 40.0))
	await _fps("in a room, rain and fog outside")
	await _weather_cost("in a room, rain and fog outside")
	print(" the ward's border with Halloran Square (Marlowe Avenue, fog):")
	main.weather.force("fog")
	var h: DistrictLayout = main.world.layouts.halloran
	var border := Vector2(h.bounds.end.x + 120.0, 600.0)
	await _place(border, PI)
	for i in 600:  # streamed in ahead of the border, a slice a frame
		await process_frame
		if main.world.is_ready("halloran"):
			break
	var st: Dictionary = main.world.stats.get("halloran", {})
	print("  Halloran Square with its three rooms streamed in: %.1f ms of work over %d frames (worst slice %.1f ms)" % [
		float(st.get("work_usec", 0)) / 1000.0, int(st.get("frames", 0)), float(st.get("worst_step_usec", 0)) / 1000.0])
	await _fps("at the border in fog, both districts built")
	print(" the new rooms:")
	main.weather.force("clear")
	var hall: InteriorPlan = main.interiors.plan_named("city_hall")
	await _place(hall.inside_door(0, 60.0))
	await _fps("in City Hall")
	var t2 := Time.get_ticks_usec()
	main.world.unload("halloran")
	main.world.load_now("yards")
	print("  the yards with their two rooms built in %.1f ms (after letting the square go)" % ((Time.get_ticks_usec() - t2) / 1000.0))
	var shed: InteriorPlan = main.interiors.plan_named("freight_shed")
	await _place(shed.inside_door(0, 60.0), PI)
	await _fps("in the freight shed")
	main.weather.force("rain_fog")
	await _fps("in the freight shed, rain and fog outside")
	main.weather.force("clear")
	print(" the people (call-outs and routines) and the Bird's film:")
	await _place(Vector2(2290, 380))
	var total := 0
	for i in 240:
		await process_frame
		var t0 := Time.get_ticks_usec()
		main._people_update(1.0 / 60.0)
		total += Time.get_ticks_usec() - t0
	print("  %-58s mean %6.3f ms" % ["call-outs and routines a frame, in the Copper Owl", total / 1000.0 / 240.0])
	for id in VoiceLines.LINES:
		main.voice_lines.mark(id)
	main.clock.set_time(LastSong.LAST_SONG + 1.0)
	for i in 120:
		await process_frame
		if main.last_song.scene == "asking":
			break
	await _place(main.last_song.seat() + Vector2(0, 34))
	main.last_song.start_film()
	await _fps("the Bird's film (lights down, the room hushed)", 4.0)
	main.weather.force("clear")
	main.modals.open_menu(true)
	await _fps("the game menu open (the world paused)")
	main.modals.open_menu(false)
	print(" rooms built now: %d; memory %.1f MB static, %d nodes" % [main.interiors.views.size(),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
	quit()
