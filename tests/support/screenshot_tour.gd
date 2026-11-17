extends SceneTree
## Renders the neighbourhood and saves screenshots (needs a display, e.g.
## xvfb-run; not part of the automated tests):
##   godot --path . -s tests/support/screenshot_tour.gd -- <output dir> [shot names...]
## Shots: street (the starting view), walk (on foot by the roadster), drive
## (driving down Marlowe Avenue), garage, river, alley, wide, shoot (firing at
## the Copper Owl, captured on the muzzle flash), beat / pursuit (the officer),
## story (the M002 sequence: shots, the officer, the getaway, the alley, lost
## him), steer (M003: the roadster's front wheels at full lock, standing and turning).

var main: Node2D
var out_dir := "user://shots"
var cmd := PlayerCommand.new()
var _click := false
var _flash_seen := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = load("res://src/main/main.tscn").instantiate()
	main.save_path = ""
	main.command_source = func(_c: PlayerController) -> PlayerCommand:
		var out := PlayerCommand.make(cmd.move, cmd.interact, cmd.handbrake, cmd.aim, _click)
		_click = false
		return out
	root.add_child(main)
	var shots: Array = args.slice(1) if args.size() > 1 else ["street", "walk", "drive", "garage", "river", "alley", "hotel"]
	_run.call_deferred(shots)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame
	await process_frame


func _shot(name: String, settle: bool = true) -> void:
	if settle:
		await _frames(3)
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)


func _teleport_walker(p: Vector2, facing: float) -> void:
	main.walker.place(p, facing)
	main.camera.snap_to(main.walker)
	cmd = PlayerCommand.make(Vector2.ZERO, false, false, p + Vector2.from_angle(facing) * 80)


func _run(shots: Array) -> void:
	await _frames(20)
	if main.hud.help_panel.visible:
		main.hud.toggle_help()  # the controls card would cover the view
	for s in shots:
		match s:
			"street":
				await _frames(30)
				await _shot("street")
			"walk":
				cmd = PlayerCommand.make(Vector2(0.45, 1.0).normalized(), false, false, Vector2(2425, 694))
				await _frames(30)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, Vector2(2425, 694))
				await _frames(10)
				await _shot("walk")
			"drive":
				if main.player.on_foot():
					var c: Car = main.cars[0]
					main.walker.place(c.global_position + Vector2(0, -34), 0.0)
					await _frames(2)
					main.player.enter(c)
				# pull out of the parking space and cruise east down Marlowe Avenue
				cmd = PlayerCommand.make(Vector2(-0.45, -1.0))
				await _frames(26)
				cmd = PlayerCommand.make(Vector2(0.3, -1.0))
				await _frames(18)
				cmd = PlayerCommand.make(Vector2(0.0, -1.0))
				await _frames(40)
				await _shot("drive")
				cmd = PlayerCommand.make(Vector2(0, 0), true)
				await _frames(2)
				cmd = PlayerCommand.make(Vector2(0, 0))
				await _frames(90)
			"steer":
				# M003: in the roadster at the curb, wheel turned to full lock (front tyres turn)
				var c: Car = main.cars[0]
				main.walker.place(c.global_position + Vector2(0, -34), 0.0)
				await _frames(2)
				main.player.enter(c)
				cmd = PlayerCommand.make(Vector2(-1.0, 0.0))
				await _frames(40)
				await _shot("steer")
				cmd = PlayerCommand.make(Vector2(-1.0, -1.0))
				await _frames(50)
				cmd = PlayerCommand.make(Vector2(-1.0, -0.0))
				await _frames(4)
				await _shot("steer_turning")
				cmd = PlayerCommand.make(Vector2(0, 1))
				await _frames(60)
				cmd = PlayerCommand.make(Vector2(0, 0), true)
				await _frames(2)
				cmd = PlayerCommand.make(Vector2(0, 0))
				await _frames(60)
			"club":
				# M003: walk in under the Copper Owl's canopy; the roof opens up
				_teleport_walker(Vector2(2291, 480), -PI / 2)
				cmd = PlayerCommand.make(Vector2(0, -1), false, false, Vector2(2291, 300))
				await _frames(50)
				cmd = PlayerCommand.make(Vector2(-0.4, -1).normalized(), false, false, Vector2(2240, 202))
				await _frames(45)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, Vector2(2240, 202))
				await _frames(30)
				await _shot("club")
			"barber":
				# M003: Sal's Barber Shop, talking to Sal
				_teleport_walker(Vector2(990, 368), -PI / 2)
				await _frames(40)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, Vector2(990, 334))
				main.start_talk("sal")
				await _frames(20)
				await _shot("barber")
				main.end_talk()
			"club_door":
				_teleport_walker(Vector2(2291, 455), -PI / 2)
				await _frames(40)
				await _shot("club_door")
			"garage":
				_teleport_walker(Vector2(1180, 1395), -PI / 2)
				await _frames(40)
				await _shot("garage")
			"river":
				_teleport_walker(Vector2(3560, 470), 0.0)
				await _frames(40)
				await _shot("river")
			"alley":
				_teleport_walker(Vector2(2300, 135), PI)
				await _frames(40)
				await _shot("alley")
			"hotel":
				_teleport_walker(Vector2(2480, 735), -PI / 2)
				await _frames(40)
				await _shot("hotel")
			"shoot":
				# a few steps up the avenue, then two shots at the Copper Owl's windows
				var target := Vector2(2240, 380)
				cmd = PlayerCommand.make(Vector2(-0.3, -0.5), false, false, target)
				await _frames(24)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, target)
				_click = true
				await _frames(26)
				_click = true
				_flash_seen = false
				main.player.fired.connect(func(_m: Vector2, _d: Vector2) -> void: _flash_seen = true, CONNECT_ONE_SHOT)
				for i in 30:
					await physics_frame
					if _flash_seen:
						break
				await process_frame
				await _shot("shoot", false)
				# the same moment, close up: the pistol in his hand
				main.camera.foot_zoom = 2.6
				for i in 70:
					await process_frame
				_click = true
				_flash_seen = false
				main.player.fired.connect(func(_m: Vector2, _d: Vector2) -> void: _flash_seen = true, CONNECT_ONE_SHOT)
				for i in 30:
					await physics_frame
					if _flash_seen:
						break
				await process_frame
				await _shot("shoot_close", false)
				main.camera.foot_zoom = 1.2
				await _frames(60)
			"beat":
				# the officer on his beat, seen from the corner of Kessler and Marlowe
				_teleport_walker(Vector2(1990, 560), -PI / 2)
				await _frames(150)
				await _shot("beat")
			"pursuit":
				# shots by the newsstand: the officer whistles and comes running
				_teleport_walker(Vector2(2330, 600), PI)
				await _frames(10)
				var near: Vector2 = main.officer.body.global_position
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, near + Vector2(80, -60))
				_click = true
				await _frames(30)
				_click = true
				await _frames(50)
				# run for the roadster
				var car: Car = main.cars[0]
				for i in 120:
					var to: Vector2 = car.global_position + Vector2(0, -36) - main.walker.global_position
					if to.length() < 8.0:
						break
					cmd = PlayerCommand.make(to.normalized(), false, false, main.officer.body.global_position)
					await physics_frame
				await _shot("pursuit")
				main.player.enter(car)
				cmd = PlayerCommand.make(Vector2(-0.4, -1))
				await _frames(30)
				cmd = PlayerCommand.make(Vector2(0, -1))
				await _frames(50)
				await _shot("escape")
			"story":
				await _story()
			"wide":
				_teleport_walker(Vector2(1650, 600), 0.0)
				main.camera.foot_zoom = 0.45
				await _frames(120)
				await _shot("wide")
				main.camera.foot_zoom = 1.4
	quit()


func _drive(c: Car, points: Array, cruise: float, max_ticks: int) -> void:
	var i := 0
	for t in max_ticks:
		var target: Vector2 = points[i]
		if c.global_position.distance_to(target) < 45.0:
			i += 1
			if i >= points.size():
				break
			target = points[i]
		var diff := angle_difference(c.model.heading, (target - c.global_position).angle())
		var steer := 0.0
		if diff > 0.05:
			steer = 1.0
		elif diff < -0.05:
			steer = -1.0
		var speed := c.model.forward_speed()
		var want := cruise if absf(diff) < 0.45 else cruise * 0.45
		var pedal := -1.0 if speed < want else (1.0 if speed > want + 50.0 else 0.0)
		cmd = PlayerCommand.make(Vector2(steer, pedal))
		await physics_frame
	cmd = PlayerCommand.new()


## The M002 sequence, as described for the milestone.
func _story() -> void:
	var cop: PoliceOfficer = main.officer
	await _frames(90)
	await _shot("story_1_officer_on_his_beat")
	# a few shots at the Copper Owl's windows
	var target := Vector2(2250, 380)
	cmd = PlayerCommand.make(Vector2.ZERO, false, false, target)
	_click = true
	await _frames(26)
	_click = true
	_flash_seen = false
	main.player.fired.connect(func(_m: Vector2, _d: Vector2) -> void: _flash_seen = true, CONNECT_ONE_SHOT)
	for i in 30:
		await physics_frame
		if _flash_seen:
			break
	await process_frame
	await _shot("story_2_shots_fired", false)
	await _frames(40)
	# run for the roadster, the copper coming
	var car: Car = main.cars[0]
	for i in 200:
		var to: Vector2 = car.global_position + Vector2(0, -36) - main.walker.global_position
		if to.length() < 6.0:
			break
		cmd = PlayerCommand.make(to.normalized(), false, false, cop.body.global_position)
		await physics_frame
		if i == 25:
			await _shot("story_3_on_your_tail", false)
	main.player.enter(car)
	await _drive(car, [Vector2(2700, 650), Vector2(2950, 650)], 260.0, 90)
	await _shot("story_4_getaway_down_marlowe")
	# north up Wharf Street and into the back alley
	await _drive(car, [Vector2(3150, 640), Vector2(3290, 560), Vector2(3300, 300), Vector2(3270, 175), Vector2(3150, 140)], 230.0, 600)
	await _drive(car, [Vector2(2900, 138)], 140.0, 160)
	await _shot("story_5_into_the_alley")
	# meanwhile, back on Marlowe Avenue: the copper looking for you
	for i in 600:
		if cop.brain.state == OfficerBrain.State.SEARCH:
			break
		await physics_frame
	main.camera.target = cop.body
	await _frames(70)
	await _shot("story_6_copper_searching")
	main.camera.target = car
	for i in 1200:
		if cop.brain.state == OfficerBrain.State.RETURN:
			break
		await physics_frame
	await _frames(20)
	await _shot("story_7_you_lost_him")
