extends SceneTree
## M013 measurements (needs a display, e.g. xvfb-run):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -s tests/support/m013_probe.gd
## Prints the frame rate on Marlowe Avenue in each weather (clear, rain, a
## downpour, fog, rain and fog) with the rain's own work a frame; then the
## gaming room near midnight - idle with the regulars about (their life a
## frame), at the wheel with chips down (the table and its view a frame), at a
## machine while its reels run, at the card table at dime-and-quarter stakes -
## and loading a game saved at the wheel of a car in Halloran Square.

var main: Node2D
var cmd := PlayerCommand.new()


func _initialize() -> void:
	main = load("res://src/main/main.tscn").instantiate()
	main.save_path = ""
	main.settings_path = ""
	main.opening_enabled = false
	main.callouts_enabled = false
	main.command_source = func(_c): return PlayerCommand.make(cmd.move, cmd.interact, cmd.handbrake, cmd.aim)
	root.add_child(main)
	print("M013 probe (software OpenGL unless a GPU is present: %s)" % RenderingServer.get_video_adapter_name())
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


func _cost(label: String, work: Callable, frames: int = 180) -> void:
	var total := 0
	for i in frames:
		await process_frame
		var t0 := Time.get_ticks_usec()
		work.call()
		total += Time.get_ticks_usec() - t0
	print("  %-58s mean %6.3f ms a frame" % [label, total / 1000.0 / frames])


func _place(p: Vector2, facing: float = -PI / 2) -> void:
	main.walker.place(p, facing)
	main.camera.snap_to(main.walker)
	for i in 20:
		await process_frame


func _run() -> void:
	for i in 30:
		await process_frame
	main.street.clear()
	print(" Marlowe Avenue by the Copper Owl:")
	await _place(Vector2(2350, 600))
	for st in ["clear", "rain", "fog", "rain_fog"]:
		main.weather.force(st)
		await _fps("weather: %s" % st)
	main.weather.force("rain")
	for m in range(0, 600):
		main.clock.set_time(19 * 60 + 30.0 + m)
		main.weather.advance(main.clock.minute)
		if main.weather.downpour() > 0.9:
			break
	await _fps("weather: a downpour (rain %.2f)" % main.weather.rain_strength())
	await _cost("the rain's fall and parameters (WeatherView.refresh)", func() -> void:
		main.weather_view.refresh(main.camera.view_rect(), main.camera.eye(), main.camera.zoom.x, [main.city], 1.0 / 60.0))
	main.weather.force("clear")
	print(" the gaming room near midnight:")
	main.clock.set_time(24 * 60.0)
	await _place(Vector2(1958, 300), PI)
	print("  (regulars in: %s)" % [main.back_rooms.gaming_room.present(main.clock.minute)])
	await _fps("in the gaming room, the regulars about")
	await _cost("the regulars' life (GamingRoomLife.update)", func() -> void:
		main.back_rooms.room_life.update(1.0 / 60.0, main.clock.minute, main.walker.global_position, -1))
	await _cost("Leo's wheel run for the room (RouletteTable.advance)", func() -> void:
		main.back_rooms.wheel.advance(1.0 / 60.0))
	main.weather.force("rain_fog")
	await _fps("in the gaming room, rain and fog outside")
	main.weather.force("clear")
	await _place(RiversideInteriors.ROULETTE_SPOT)
	main.rackets.money = 5000
	main.back_rooms.open_roulette()
	for i in 3000:
		if main.back_rooms.wheel.phase == RouletteTable.Phase.OPEN:
			break
		await process_frame
	for b in [["straight:17", 25], ["red", 100], ["dozen:2", 25]]:
		main.back_rooms.bet(b[0], b[1])
	await _fps("at the wheel, bets open, the regulars' chips going down", 4.0)
	await _fps("at the wheel, the ball dropping and paid", 4.0)
	main.back_rooms.leave_roulette()
	await _place(RiversideInteriors.SLOTS[0] + Vector2(0, 32))
	main.back_rooms.open_slot(0)
	main.back_rooms.pull()
	await _fps("at the Owl, its reels running", 2.0)
	main.back_rooms.leave_slot()
	var back: InteriorPlan = main.interiors.view_of("back_room").plan
	await _place(back.spots[0].pos)
	main.back_rooms.open_poker()
	main.hud.poker_view.level_requested.emit(1)
	main.hud.poker_view.choose_buy_in(1)
	main.hud.poker_view.think = Vector2(0.2, 0.3)
	await _fps("at the card table (dime and quarter), a hand under way", 3.0)
	main.back_rooms.leave_poker()
	print(" loading a game saved at the wheel in Halloran Square:")
	var path := OS.get_user_data_dir().path_join("m013_probe_save.json")
	main.save_path = path
	main.world.load_now("halloran")
	var car: Car = main.fleet.cars[main.fleet.ids.find("riverside/3")] if main.fleet.ids.has("riverside/3") else main.fleet.cars[0]
	car.place(Transform2D(PI, Vector2(-600, 600)))
	main.walker.place(car.global_position + Vector2(0, 40), 0.0)
	main.player.enter(car)
	main.save_game()
	root.remove_child(main)
	main.free()
	var t0 := Time.get_ticks_usec()
	main = load("res://src/main/main.tscn").instantiate()
	main.save_path = path
	main.settings_path = ""
	main.opening_enabled = false
	main.callouts_enabled = false
	main.command_source = func(_c): return PlayerCommand.make(cmd.move, cmd.interact, cmd.handbrake, cmd.aim)
	root.add_child(main)
	print("  the scene with Halloran Square and the car back in %.0f ms (in the car: %s)" % [(Time.get_ticks_usec() - t0) / 1000.0,
		not main.player.on_foot()])
	DirAccess.remove_absolute(path)
	await _fps("driving seat, Halloran Square, after loading")
	print(" memory %.1f MB static, %d nodes" % [Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
	quit()
