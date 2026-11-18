class_name Opening
extends CanvasLayer
## The opening of a new game: Danny's monologue over the Riverside Ward at
## night, the city already going about its business, the camera drifting from
## the river to his flat (OpeningScript). Black bars above and below, his
## words as subtitles, and then the bars slide away and he is yours.
## Skippable at any moment. Nothing here touches the game: the composition
## root hides the HUD, holds the player and ducks the night's sound while it
## runs, and puts everything back on `finished`.

signal finished

## The point the camera follows (world position) and the zoom wanted now.
var rig: Node2D
var zoom := 1.0
var running := false
## Seconds since the voice started (follows the voice while it plays).
var time := 0.0
## The recording's length (s): the opening lasts as long as it does.
var length := 0.0
var voice: AudioStreamPlayer
var subtitles := true
var keys: Array = []
var top_bar: ColorRect
var bottom_bar: ColorRect
var subtitle: Label
var hint: Label
var fade: ColorRect
## Whether the hand-over has begun, and the seconds left of it.
var _handing := false
var _outro := 0.0


## Starts the opening with `stream` (Danny's monologue). Returns false - and
## nothing happens - when there is no usable recording.
func start(stream: AudioStream, p_keys: Array, show_subtitles: bool, font: Font) -> bool:
	if stream == null or stream.get_length() <= 0.0:
		return false
	name = "Opening"
	layer = 10
	length = stream.get_length()
	keys = p_keys
	subtitles = show_subtitles
	rig = Node2D.new()
	rig.name = "CameraRig"
	add_child(rig)
	var first := OpeningScript.rig_at(keys, 0.0)
	rig.global_position = first.pos
	zoom = first.zoom
	voice = AudioStreamPlayer.new()
	voice.stream = stream
	voice.bus = "Voice" if AudioServer.get_bus_index("Voice") >= 0 else "Master"
	add_child(voice)
	top_bar = _bar()
	bottom_bar = _bar()
	subtitle = _text(font, 24, Color("f1e4c6"))
	hint = _text(font, 14, Color("f1e4c6", 0.55))
	hint.text = "E   skip"
	fade = ColorRect.new()
	fade.color = Color(0.0, 0.0, 0.0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	running = true
	voice.play()
	_layout(0.0)
	return true


func _bar() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.0, 0.0, 0.0)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _text(font: Font, size: int, color: Color) -> Label:
	var l := Label.new()
	if font != null:
		l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


## The player wants to get on with it: the voice fades out quickly and the
## hand-over begins.
func skip() -> void:
	if not running or _handing:
		return
	_begin_outro()
	var fade_voice := create_tween()
	fade_voice.tween_property(voice, "volume_db", -60.0, 0.35)
	fade_voice.tween_callback(voice.stop)


func is_handing_over() -> bool:
	return _handing


func _begin_outro() -> void:
	_handing = true
	_outro = OpeningScript.OUTRO


func _process(delta: float) -> void:
	if not running:
		return
	var pos := voice.get_playback_position() if voice.playing else 0.0
	time = pos if pos > time else time + delta
	var r := OpeningScript.rig_at(keys, time)
	rig.global_position = r.pos
	zoom = r.zoom
	if not _handing and time >= length + OpeningScript.TAIL:
		_begin_outro()
	var out := 0.0
	if _handing:
		_outro -= delta
		out = clampf(1.0 - _outro / OpeningScript.OUTRO, 0.0, 1.0)
	_layout(out)
	if _handing and _outro <= 0.0:
		_finish()


## Places the bars, the subtitle and the fade for the screen size; `out` is
## how far the hand-over has gone (0..1: the bars slide off the screen).
func _layout(out: float) -> void:
	var screen := get_viewport().get_visible_rect().size
	var bar_h := screen.y * 0.11
	var slide := bar_h * out * out
	top_bar.position = Vector2(0.0, -slide)
	top_bar.size = Vector2(screen.x, bar_h)
	bottom_bar.position = Vector2(0.0, screen.y - bar_h + slide)
	bottom_bar.size = Vector2(screen.x, bar_h)
	subtitle.text = OpeningScript.cue_at(time) if subtitles and out <= 0.0 else ""
	subtitle.position = Vector2(0.0, screen.y - bar_h + slide)
	subtitle.size = Vector2(screen.x, bar_h)
	hint.position = Vector2(screen.x - 150.0, -slide)
	hint.size = Vector2(130.0, bar_h)
	hint.visible = out <= 0.0
	fade.position = Vector2.ZERO
	fade.size = screen
	fade.color.a = clampf(1.0 - time / OpeningScript.FADE_IN, 0.0, 1.0) * (1.0 - out)


func _finish() -> void:
	running = false
	if voice.playing:
		voice.stop()
	finished.emit()
