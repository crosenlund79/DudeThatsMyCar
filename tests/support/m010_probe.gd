extends SceneTree
## M010 measurements (needs a display, e.g. xvfb-run):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -s tests/support/m010_probe.gd
## Prints the frame rate on Marlowe Avenue in each kind of weather (the same
## spot, the same view), and the weather's own work a frame.

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


func _weather_cost(label: String, frames: int = 240) -> void:
	var total := 0
	for i in frames:
		await process_frame
		var t0 := Time.get_ticks_usec()
		main.weather.advance(main.clock.minute)
		main.weather_view.refresh(main.camera.view_rect(), main.camera.eye(), main.camera.zoom.x, [main.city])
		total += Time.get_ticks_usec() - t0
	print("  %-58s mean %6.3f ms" % [label, total / 1000.0 / frames])


func _run() -> void:
	print("M010 probe (software OpenGL unless a GPU is present)")
	for i in 30:
		await process_frame
	main.street.clear()
	main.walker.place(Vector2(2250, 560), -PI / 2)
	main.camera.snap_to(main.walker)
	print(" weather on Marlowe Avenue by the Copper Owl:")
	for s in ["clear", "rain", "fog", "rain_fog"]:
		main.weather.force(s)
		await _fps("%s" % s)
	main.weather.force("rain_fog")
	await _weather_cost("the weather's own work a frame (rain and fog)")
	quit()
