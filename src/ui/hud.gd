class_name Hud
extends CanvasLayer
## On-screen information, kept small so the city stays the picture: where you
## are (top left), what E does here (bottom centre), the car and its speed
## while driving (bottom right), a short notice when something cannot be
## done, the controls card (F1), the aim reticle on foot and the pause menu.

const FONT_PATH := "res://assets/fonts/Fredoka.ttf"
const CREAM := Color("f1e4c6")
const COPPER := Color("d8a060")
const DIM := Color("f1e4c6", 0.65)
## px per second -> miles per hour (one world px is about 7.5 cm of street).
const MPH_PER_PX := 0.168
const HELP_TEXT := "ON FOOT\nW A S D   walk\nMouse   aim\nE   get in a car\n\nDRIVING\nW   accelerate\nS   brake / reverse\nA  D   steer\nSpace   handbrake\nE   get out\n\nF1   this card      Esc   pause"

var resolver: AssetResolver
var place_label: Label
var district_label: Label
var prompt: PanelContainer
var prompt_label: Label
var car_panel: PanelContainer
var car_label: Label
var notice_label: Label
var help_panel: PanelContainer
var pause_panel: PanelContainer
var crosshair: TextureRect
var _notice_left := 0.0
var _help_left := 12.0
var _font: FontFile


func setup(p_resolver: AssetResolver, district_name: String) -> void:
	resolver = p_resolver
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = load(FONT_PATH)
	var top_left := _panel(Vector2(18, 16))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -2)
	top_left.add_child(box)
	district_label = _label(district_name.to_upper(), 13, COPPER)
	place_label = _label("", 21, CREAM)
	box.add_child(district_label)
	box.add_child(place_label)
	prompt = _panel(Vector2.ZERO)
	prompt_label = _label("", 19, CREAM)
	prompt.add_child(prompt_label)
	prompt.visible = false
	car_panel = _panel(Vector2.ZERO)
	car_label = _label("", 18, CREAM)
	car_panel.add_child(car_label)
	car_panel.visible = false
	notice_label = _label("", 20, Color("ffd9a0"))
	notice_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	notice_label.add_theme_constant_override("outline_size", 6)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(notice_label)
	help_panel = _panel(Vector2.ZERO)
	var help := _label(HELP_TEXT, 15, CREAM)
	help_panel.add_child(help)
	pause_panel = _panel(Vector2.ZERO)
	var pause := _label("PAUSED\n\nEsc   resume\nQ   quit", 24, CREAM)
	pause.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_panel.add_child(pause)
	pause_panel.visible = false
	crosshair = TextureRect.new()
	crosshair.texture = resolver.get_texture("ui/crosshair")
	crosshair.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crosshair.stretch_mode = TextureRect.STRETCH_SCALE
	crosshair.size = AssetCatalog.display_size("ui/crosshair")
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(crosshair)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _panel(at: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxTexture.new()
	sb.texture = resolver.get_texture("ui/panel")
	var t := sb.texture.get_size() / 96.0
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		sb.set_texture_margin(side, 24.0 * t.x)
		sb.set_content_margin(side, 14.0)
	p.add_theme_stylebox_override("panel", sb)
	p.position = at
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	return p


func show_notice(text: String) -> void:
	notice_label.text = text
	_notice_left = 2.6


func toggle_help() -> void:
	help_panel.visible = not help_panel.visible
	_help_left = -1.0


func set_paused(on: bool) -> void:
	pause_panel.visible = on


## Refreshes everything from the current state.
func refresh(delta: float, place: String, prompt_text: String, driving: Car, mouse: Vector2, show_crosshair: bool) -> void:
	var screen := get_viewport().get_visible_rect().size
	place_label.text = place if place != "" else " "
	prompt.visible = prompt_text != ""
	prompt_label.text = prompt_text
	prompt.reset_size()
	prompt.position = Vector2((screen.x - prompt.size.x) * 0.5, screen.y - prompt.size.y - 26)
	car_panel.visible = driving != null
	if driving != null:
		var mph := int(round(absf(driving.model.forward_speed()) * MPH_PER_PX))
		car_label.text = "%s   %d mph" % [driving.vehicle.params.display_name, mph]
		car_panel.reset_size()
		car_panel.position = Vector2(screen.x - car_panel.size.x - 18, screen.y - car_panel.size.y - 18)
	_notice_left -= delta
	notice_label.visible = _notice_left > 0.0
	notice_label.modulate.a = clampf(_notice_left / 0.5, 0.0, 1.0)
	notice_label.reset_size()
	notice_label.position = Vector2((screen.x - notice_label.size.x) * 0.5, screen.y * 0.3)
	if _help_left > 0.0:
		_help_left -= delta
		help_panel.modulate.a = clampf(_help_left / 1.0, 0.0, 1.0)
		if _help_left <= 0.0:
			help_panel.visible = false
			help_panel.modulate.a = 1.0
	help_panel.reset_size()
	help_panel.position = Vector2(screen.x - help_panel.size.x - 18, 16)
	pause_panel.reset_size()
	pause_panel.position = (screen - pause_panel.size) * 0.5
	crosshair.visible = show_crosshair
	crosshair.position = mouse - crosshair.size * 0.5
