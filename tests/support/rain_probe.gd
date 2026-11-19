extends SceneTree
## M013 the rain on the real renderer (needs a display, e.g. xvfb-run):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -s tests/support/rain_probe.gd -- <dir>
## Draws the rain over a dark street with a few lamps (no city) and saves
## pairs of consecutive frames - steady rain, a downpour swelling, a downpour
## easing, panning - as <dir>/rain_<case>_a.png / _b.png, so the drops' motion
## between two frames can be measured (tools: tests/support/rain_motion.py).

var model := Weather.new()
var view: WeatherView
var eye := Vector2(2350, 600)


func _initialize() -> void:
	var back := CanvasLayer.new()
	back.layer = -1
	root.add_child(back)
	var dark := ColorRect.new()
	dark.color = Color(0.07, 0.08, 0.1)
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.add_child(dark)
	for p in [Vector2(300, 200), Vector2(900, 500), Vector2(640, 360)]:
		var lamp := ColorRect.new()
		lamp.color = Color(0.9, 0.75, 0.45)
		lamp.position = p - Vector2(60, 60)
		lamp.size = Vector2(120, 120)
		back.add_child(lamp)
	model.begin_night(1, 19 * 60 + 30.0)
	model.force("rain")
	view = WeatherView.new()
	root.add_child(view)
	view.setup(model)
	_run.call_deferred()


func _frames(n: int, minute_step: float, pan: Vector2) -> void:
	for i in n:
		model.minute += minute_step
		eye += pan
		view.refresh(Rect2(eye - Vector2(640, 360), Vector2(1280, 720)), eye, 1.0, [], 1.0 / 60.0)
		await process_frame


func _pair(dir: String, label: String, minute_step: float, pan: Vector2 = Vector2.ZERO) -> void:
	await _frames(1, minute_step, pan)
	await process_frame
	root.get_texture().get_image().save_png(dir.path_join("rain_%s_a.png" % label))
	await _frames(1, minute_step, pan)
	await process_frame
	root.get_texture().get_image().save_png(dir.path_join("rain_%s_b.png" % label))
	print("  %s: downpour %.2f, rain %.2f" % [label, model.downpour(), model.rain_strength()])


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0] if not args.is_empty() else "user://rain"
	DirAccess.make_dir_recursive_absolute(dir)
	await _frames(30, 0.0, Vector2.ZERO)
	await _pair(dir, "steady", 0.0)
	# a downpour coming on: find a swelling stretch and a fading one on this night
	var swell := -1.0
	var ease := -1.0
	for m in range(0, 600):
		var a := model._downpour_at(19 * 60 + 30.0 + m)
		var b := model._downpour_at(19 * 60 + 30.0 + m + 1)
		if swell < 0.0 and a > 0.3 and b - a > 0.05:
			swell = 19 * 60 + 30.0 + m
		if ease < 0.0 and a > 0.3 and a - b > 0.05:
			ease = 19 * 60 + 30.0 + m
	model.minute = swell
	# the downpour swelling fast (as M012's rain was at its worst: game time running quickly)
	await _frames(10, 0.1, Vector2.ZERO)
	await _pair(dir, "swelling", 0.1)
	model.minute = ease
	await _frames(10, 0.1, Vector2.ZERO)
	await _pair(dir, "easing", 0.1)
	await _frames(10, 0.0, Vector2(4, 0))
	await _pair(dir, "panning", 0.0, Vector2(4, 0))
	quit()
