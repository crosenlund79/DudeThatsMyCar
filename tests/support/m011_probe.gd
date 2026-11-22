extends SceneTree
## M011 measurements (needs a display, e.g. xvfb-run):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -s tests/support/m011_probe.gd
## Prints the frame rate in the Copper Owl (for comparison), the card room and
## the gaming room - idle, with the wheel spinning, with a machine running and
## at the card table - and the games' own work a frame (the view's drawing and
## the room's sound); then in the union hall and in front of City Hall in
## clear weather and in fog; and the start-up cost of the new rooms.

var main: Node2D
var cmd := PlayerCommand.new()


func _initialize() -> void:
	var t0 := Time.get_ticks_usec()
	main = load("res://src/main/main.tscn").instantiate()
	main.save_path = ""
	main.settings_path = ""
	main.opening_enabled = false
	main.command_source = func(_c): return PlayerCommand.make(cmd.move, cmd.interact, cmd.handbrake, cmd.aim)
	root.add_child(main)
	print("M011 probe (software OpenGL unless a GPU is present); the scene up in %.0f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
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


## A view's own work a frame: its _process and _draw (forced), measured directly.
func _view_cost(label: String, view: Control, frames: int = 120) -> void:
	var total := 0
	for i in frames:
		await process_frame
		var t0 := Time.get_ticks_usec()
		view._process(1.0 / 60.0)
		view.queue_redraw()
		total += Time.get_ticks_usec() - t0
	print("  %-58s mean %6.3f ms (the view's update)" % [label, total / 1000.0 / frames])


func _sound_cost(label: String, frames: int = 240) -> void:
	var total := 0
	var room: InteriorPlan = main.interiors.current
	for i in frames:
		await process_frame
		var t0 := Time.get_ticks_usec()
		main.soundscape.update_listener(main.walker.global_position, room, false, 1.0, 1.0 / 60.0)
		total += Time.get_ticks_usec() - t0
	print("  %-58s mean %6.3f ms" % [label, total / 1000.0 / frames])


func _run() -> void:
	for i in 30:
		await process_frame
	main.street.clear()
	main.weather.force("clear")
	main.rackets.money = 5000
	var gaming: InteriorPlan = main.interiors.view_of("gaming_room").plan
	print(" rooms built at start-up: %d (the gaming room and the union hall among them)" % main.interiors.views.size())
	print(" the Copper Owl and its back rooms (clear weather):")
	await _place(Vector2(2290, 330))
	await _fps("in the Copper Owl (the band, the crowd)")
	await _place(RiversideInteriors.TABLE + Vector2(0, 54))
	await _fps("in the card room")
	await _place(RiversideInteriors.ROULETTE_SPOT + Vector2(20, 0))
	await _fps("in the gaming room, idle")
	await _sound_cost("the soundscape's update a frame (in the gaming room)")
	# the wheel
	await _place(RiversideInteriors.ROULETTE_SPOT)
	main.back_rooms.open_roulette()
	await _fps("at the wheel, between spins (the table on screen)")
	for i in 3000:  # M013: Leo's next round
		if main.back_rooms.wheel.phase == RouletteTable.Phase.OPEN:
			break
		await process_frame
	for b in [["straight:17", 25], ["red", 100], ["dozen:2", 25]]:
		main.back_rooms.bet(b[0], b[1])
	await _fps("at the wheel, bets open, the wheel turning", 4.0)
	await _view_cost("the wheel's view", main.hud.roulette_view)
	main.back_rooms.leave_roulette()
	# a machine
	await _place(RiversideInteriors.SLOTS[1] + Vector2(0, 32))
	main.back_rooms.open_slot(1)
	var sv: SlotView = main.hud.slot_view
	await _fps("at a machine, idle (its front on screen)")
	for k in 2:
		main.back_rooms.pull()
		var t0 := Time.get_ticks_usec()
		while sv.phase != "paid" and Time.get_ticks_usec() - t0 < 4000000:
			await process_frame
	main.back_rooms.pull()
	await _fps("at a machine, the reels running", 2.0)
	await _view_cost("a machine's view", sv)
	main.back_rooms.leave_slot()
	# the card table
	await _place(gaming.inside_door(0, 14.0))
	await _place(RiversideInteriors.TABLE + Vector2(0, 54))
	main.back_rooms.open_poker()
	main.hud.poker_view.choose_buy_in(1)
	main.hud.poker_view.think = Vector2(0.05, 0.1)
	await _fps("at the card table (a hand under way)")
	main.back_rooms.leave_poker()
	print(" the union hall and City Hall:")
	var hall: InteriorPlan = main.interiors.view_of("union_hall").plan
	await _place(hall.inside_door(0, 30.0), PI)
	await _fps("in the union hall")
	var h: DistrictLayout = main.world.layouts.halloran
	var door: Dictionary = h.locked_doors[0]
	main.walker.place(door.pos + Vector2(0, -80), PI / 2)
	main.camera.snap_to(main.walker)
	var t1 := Time.get_ticks_usec()
	main.world.load_now("halloran")
	print("  Halloran Square built in %.1f ms (load_now, all at once)" % ((Time.get_ticks_usec() - t1) / 1000.0))
	for i in 20:
		await process_frame
	await _fps("in front of City Hall, clear")
	main.weather.force("fog")
	await _fps("in front of City Hall, fog")
	main.weather.force("clear")
	print(" memory: %.1f MB static, %d nodes" % [Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
	quit()
