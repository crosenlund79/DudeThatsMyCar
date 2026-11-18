class_name Cinematic
extends CanvasLayer
## M010: a short scene played in the game itself (no movie): black bars slide
## in, a narrated line or two at the bottom, the camera follows `rig` along a
## path of keys {t, pos, zoom}, a white flash when asked, and the bars slide
## away again. The world goes on underneath. E (or Esc, Space, a click) skips
## to the end; nothing that happens in the world is skipped. Emits `cue` at
## named moments (once each, skipping included) and `finished` at the end.

signal cue(id: String)
signal finished

const BARS_IN := 0.8
const BARS_OUT := 0.9

var rig: Node2D
var zoom := 1.0
var time := 0.0
var length := 0.0
## {t, pos, zoom}, in time order.
var keys: Array = []
## {t, text} captions, in time order (each shows until the next).
var captions: Array = []
## {t, id} moments to announce.
var cues: Array = []
var running := false
var _fired := {}
var _flash := 0.0
var _out := -1.0
var top_bar: ColorRect
var bottom_bar: ColorRect
var caption: Label
var hint: Label
var flash: ColorRect


func start(p_keys: Array, p_captions: Array, p_cues: Array, font: Font) -> void:
	name = "Cinematic"
	layer = 9
	keys = p_keys
	captions = p_captions
	cues = p_cues
	length = float(keys.back().t)
	rig = Node2D.new()
	rig.name = "CameraRig"
	add_child(rig)
	rig.global_position = keys[0].pos
	zoom = keys[0].zoom
	flash = ColorRect.new()
	flash.color = Color(1.0, 0.95, 0.85, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	top_bar = _bar()
	bottom_bar = _bar()
	caption = _label(font, 22, Color("f1e4c6"))
	hint = _label(font, 14, Color("f1e4c6", 0.55))
	hint.text = "E   skip"
	running = true
	_layout()


func _bar() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color.BLACK
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _label(font: Font, size: int, colour: Color) -> Label:
	var l := Label.new()
	if font != null:
		l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


## A white flash over everything (the blast), fading over `seconds`.
func white_flash(strength: float = 0.9) -> void:
	_flash = strength


## To the end at once: every cue still to come is announced (in order), then
## the bars slide away.
func skip() -> void:
	if not running or _out >= 0.0:
		return
	for c in cues:
		if not _fired.has(c.id):
			_fired[c.id] = true
			cue.emit(c.id)
	time = length
	_out = 0.0


func _process(delta: float) -> void:
	if not running:
		return
	if _out < 0.0:
		time += delta
		for c in cues:
			if time >= float(c.t) and not _fired.has(c.id):
				_fired[c.id] = true
				cue.emit(c.id)
		if time >= length:
			_out = 0.0
	else:
		_out += delta
		if _out >= BARS_OUT:
			running = false
			finished.emit()
			return
	var r := rig_at(keys, minf(time, length))
	rig.global_position = r.pos
	zoom = r.zoom
	_flash = maxf(0.0, _flash - delta * 1.6)
	_layout()


## Where the camera is at time t: eased between the keys.
static func rig_at(p_keys: Array, t: float) -> Dictionary:
	if t <= float(p_keys[0].t):
		return {"pos": p_keys[0].pos, "zoom": p_keys[0].zoom}
	for i in range(1, p_keys.size()):
		var a: Dictionary = p_keys[i - 1]
		var b: Dictionary = p_keys[i]
		if t <= float(b.t):
			var u := clampf((t - float(a.t)) / maxf(0.001, float(b.t) - float(a.t)), 0.0, 1.0)
			u = u * u * (3.0 - 2.0 * u)
			return {"pos": (a.pos as Vector2).lerp(b.pos, u), "zoom": lerpf(a.zoom, b.zoom, u)}
	return {"pos": p_keys.back().pos, "zoom": p_keys.back().zoom}


## The caption showing at time t ("" between them).
static func caption_at(p_captions: Array, t: float) -> String:
	var out := ""
	for c in p_captions:
		if t >= float(c.t):
			out = c.text
	return out


func _layout() -> void:
	var screen := get_viewport().get_visible_rect().size
	var bar_h := screen.y * 0.11
	var k := clampf(time / BARS_IN, 0.0, 1.0) if _out < 0.0 else clampf(1.0 - _out / BARS_OUT, 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	top_bar.position = Vector2(0.0, -bar_h * (1.0 - k))
	top_bar.size = Vector2(screen.x, bar_h)
	bottom_bar.position = Vector2(0.0, screen.y - bar_h * k)
	bottom_bar.size = Vector2(screen.x, bar_h)
	caption.text = caption_at(captions, time) if _out < 0.0 else ""
	caption.position = Vector2(screen.x * 0.1, screen.y - bar_h * k)
	caption.size = Vector2(screen.x * 0.8, bar_h)
	hint.position = Vector2(screen.x - 140.0, bar_h * k - bar_h + 8.0)
	hint.size = Vector2(120.0, 24.0)
	flash.position = Vector2.ZERO
	flash.size = screen
	flash.color.a = _flash
