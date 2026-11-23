class_name ElTrain
extends Node2D
## M015: the El's train over Canal Market (presentation only): two cars that
## run along the line on the deck, stand at the terminal a while, run back
## and stand at the far end out of sight, over and over - on the clock of the
## world (the same moment in every frame and every test), lifted to the
## deck's height in perspective like every raised thing, its windows lit,
## its rumble heard while it runs.

const SPEED := 240.0
const WAIT_TERMINAL := 26.0
const WAIT_FAR := 34.0
const HEIGHT := 64.0

var a := Vector2.ZERO
var b := Vector2.ZERO
var body: Sprite2D
var windows: Sprite2D
var rumble: AudioStreamPlayer2D
var _scale := Vector2.ONE
## Where the train is on its line (world, on the ground), and whether it runs.
var pos := Vector2.ZERO
var running := false


func setup(line: PackedVector2Array, resolver: AssetResolver) -> void:
	name = "ElTrain"
	a = line[0]
	b = line[1]
	z_index = Layers.Z_RAISED + 1
	z_as_relative = false
	body = Sprite2D.new()
	body.texture = resolver.get_texture("props/el_train")
	_scale = AssetCatalog.scale_for(body.texture, AssetCatalog.display_size("props/el_train"))
	body.scale = _scale
	add_child(body)
	windows = Sprite2D.new()
	windows.texture = resolver.get_texture("props/el_train_lit")
	windows.scale = _scale
	windows.material = DrawLayer.glow_material()
	body.add_child(windows)
	windows.scale = Vector2.ONE
	rumble = AudioStreamPlayer2D.new()
	rumble.stream = resolver.get_audio("fx/el_train")
	rumble.bus = "Ambience" if AudioServer.get_bus_index("Ambience") >= 0 else "Master"
	rumble.max_distance = 1800.0
	rumble.volume_db = -6.0
	add_child(rumble)


## Where the train is at `seconds` on the world's clock: {pos, running}.
func at_time(seconds: float) -> Dictionary:
	var run := a.distance_to(b) / SPEED
	var period := run * 2.0 + WAIT_TERMINAL + WAIT_FAR
	var t := fposmod(seconds, period)
	if t < run:
		return {"pos": a.lerp(b, t / run), "running": true}
	t -= run
	if t < WAIT_TERMINAL:
		return {"pos": b, "running": false}
	t -= WAIT_TERMINAL
	if t < run:
		return {"pos": b.lerp(a, t / run), "running": true}
	return {"pos": a, "running": false}


func update_view(eye: Vector2, eye_height: float, view: Rect2) -> void:
	var now := at_time(Time.get_ticks_msec() / 1000.0)
	pos = now.pos
	running = now.running
	var near := view.grow(400.0).has_point(pos)
	body.visible = near
	if near:
		body.position = Perspective.project(pos, HEIGHT, eye, eye_height)
		body.scale = _scale * Perspective.scale_at(HEIGHT, eye_height)
	rumble.position = pos
	var want := running and view.grow(1400.0).has_point(pos)
	if want and not rumble.playing:
		rumble.play()
	elif not want and rumble.playing:
		rumble.stop()
