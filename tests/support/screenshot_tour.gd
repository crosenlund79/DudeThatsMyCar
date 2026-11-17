extends SceneTree
## Renders the neighbourhood and saves screenshots (needs a display, e.g.
## xvfb-run; not part of the automated tests):
##   godot --path . -s tests/support/screenshot_tour.gd -- <output dir> [shot names...]
## Shots: street (the starting view), walk (on foot by the roadster), drive
## (driving down Marlowe Avenue), garage, river, alley, wide, shoot (firing at
## the Copper Owl, captured on the muzzle flash).

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
			"wide":
				_teleport_walker(Vector2(1650, 600), 0.0)
				main.camera.foot_zoom = 0.45
				await _frames(120)
				await _shot("wide")
				main.camera.foot_zoom = 1.4
	quit()
