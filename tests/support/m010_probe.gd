extends SceneTree
## M010 measurements (needs a display, e.g. xvfb-run):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -s tests/support/m010_probe.gd
## Prints the frame rate on Marlowe Avenue in each kind of weather (the same
## spot, the same view), and the weather's own work a frame; then the frame
## rate with the later M010 features on screen - the card table, a Thompson
## burst, the café's film and fire, the emergency at the kerb - and their own
## work a frame.

var main: Node2D
var cmd := PlayerCommand.new()


func _initialize() -> void:
	main = load("res://src/main/main.tscn").instantiate()
	main.save_path = ""
	main.settings_path = ""
	main.opening_enabled = false
	main.command_source = func(_c):
		var out := PlayerCommand.make(cmd.move, cmd.interact, cmd.handbrake, cmd.aim, cmd.fire_pressed)
		out.fire = cmd.fire
		cmd.fire_pressed = false
		return out
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
	main.weather.force("clear")
	print(" the later M010 features (clear weather):")
	# the card table, a hand under way
	var back: InteriorPlan = main.interiors.view_of("back_room").plan
	main.walker.place(back.spots[0].pos, -PI / 2)
	main.camera.snap_to(main.walker)
	main.rackets.money = 2000
	for i in 5:
		await process_frame
	main.interactions.use(main.walker.global_position)
	main.hud.poker_view.choose_buy_in(1)
	main.hud.poker_view.think = Vector2(0.4, 0.6)
	await _fps("the back room, the card table open, a hand being played")
	main.back_rooms.leave_poker()
	# a Thompson burst on Marlowe Avenue
	main.rackets.borrow_thompson()
	main.armoury.arm_thompson(true)
	main.walker.place(Vector2(2250, 560), -PI / 2)
	main.camera.snap_to(main.walker)
	main.player.switch_gun()
	cmd.aim = Vector2(2250, 300)
	cmd.fire = true
	cmd.fire_pressed = true
	await _fps("Marlowe Avenue, the Thompson held down (bursts, reloads)", 3.0)
	cmd.fire = false
	# Rosie's Café: the film and the fire
	var h: DistrictLayout = main.world.layouts.halloran
	main.walker.place(h.cafe_point("bench").pos + Vector2(0, 28), PI)
	main.camera.snap_to(main.walker)
	main.world.load_now("halloran")
	main.clock.set_time(22 * 60.0 + 30.0)
	for i in 10:
		await process_frame
	main.rackets.take_cafe_job()
	main.rackets.buy_parcel()
	main.rackets.plant_parcel(main.clock.minute, false)
	main.clock.set_time(main.rackets.cafe.due(main.rackets.night) - 0.02)
	await _fps("Rosie's Cafe: the film (the blast, debris, smoke, fire)", 6.0)
	await _fps("the burning wreck, the emergency driving in", 6.0)
	for i in 600:
		await process_frame
		if main.cafe.emergency.units.all(func(u: Dictionary) -> bool: return u.state == "stopped"):
			break
	await _fps("the emergency at the kerb, its crews, the fire")
	var total := 0
	for i in 240:
		await process_frame
		var t0 := Time.get_ticks_usec()
		main.cafe.scene.refresh(main.rackets.night, main.clock.minute)
		main.cafe.emergency_views.update(main.rackets.night, main.clock.minute, 0.0)
		total += Time.get_ticks_usec() - t0
	print("  %-58s mean %6.3f ms" % ["the scene's and the emergency's own updates a frame", total / 1000.0 / 240])
	quit()
