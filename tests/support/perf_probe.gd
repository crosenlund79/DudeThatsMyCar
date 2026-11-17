extends SceneTree
## Frame-rate probe (needs a display, e.g. xvfb-run): godot --path . -s tests/support/perf_probe.gd
## Prints the frame rate with everything on, then with lamps, mist, vignette,
## ground and buildings switched off in turn (to see what costs most).
var main: Node2D
var cmd := PlayerCommand.new()
func _initialize() -> void:
	main = load("res://src/main/main.tscn").instantiate()
	main.command_source = func(_c): return cmd
	root.add_child(main)
	_run.call_deferred()
func _measure(label: String) -> void:
	for i in 20:
		await process_frame
	var t0 := Time.get_ticks_usec()
	var frames := 0
	var cpu := 0.0
	while Time.get_ticks_usec() - t0 < 2500000:
		await process_frame
		frames += 1
	print("%-28s fps %.1f  process %.1f ms" % [label, frames / 2.5, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0])
func _run() -> void:
	await _measure("baseline")
	for l in main.city.lamp_lights: l.enabled = false
	await _measure("no lamp lights")
	for l in main.city.lamp_lights: l.enabled = true
	for m in main.city.atmosphere._mist: m.visible = false
	await _measure("no mist")
	main.city.atmosphere.vignette.visible = false
	await _measure("no mist+vignette")
	main.city.get_node("Ground").visible = false
	await _measure("no ground either")
	main.city.get_node("Ground").visible = true
	main.city.get_node("Buildings").visible = false
	await _measure("no buildings (mist off)")
	quit()
