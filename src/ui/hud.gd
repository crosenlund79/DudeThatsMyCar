class_name Hud
extends CanvasLayer
## On-screen information, kept small so the city stays the picture: where you
## are (top left), what E does here (bottom centre), the car and its speed
## while driving (bottom right), a short notice when something cannot be
## done, the controls card (F1), the aim reticle on foot and the pause menu.
## M003: what you carry (money, bottles) under the place name, and the
## dialogue panel when you talk to someone (answers 1-4, E to walk away).

## The player clicked answer i (0-based) in the dialogue panel.
signal dialogue_choice(index: int)

const FONT_PATH := "res://assets/fonts/Fredoka.ttf"
const CREAM := Color("f1e4c6")
const COPPER := Color("d8a060")
const DIM := Color("f1e4c6", 0.65)
## px per second -> miles per hour (one world px is about 7.5 cm of street).
const MPH_PER_PX := 0.168
const HELP_TEXT := "ON FOOT\nW A S D   walk      Shift   run\nMouse   aim\nLeft click   shoot\nH   draw / put away      Tab   the other gun\nE   talk / go in, out / get in a car\n1 - 4   answer\n\nDRIVING\nW   accelerate\nS   brake / reverse\nA  D   steer\nSpace   handbrake\nE   get out\n\nM   map      C   how you are\nF1   this card      Esc   the menu"

var resolver: AssetResolver
var place_label: Label
var purse_label: Label
var minimap: Minimap
## M006: the whole ward (M), and how Danny is (C).
var city_map: CityMap
var status_screen: StatusScreen
## M007: a fistfight's dial over the street.
var fight_dial: FightDial
var poker_view: PokerView
## M011: the gaming room's wheel and its machines on screen.
var roulette_view: RouletteView
var slot_view: SlotView
var clock_panel: PanelContainer
var clock_label: Label
var home_label: Label
## Black screen with the night's title, fading out as you wake.
var wake_screen: ColorRect
var wake_label: Label
var _wake_left := 0.0
var dialogue_panel: PanelContainer
var speaker_label: Label
var line_label: Label
var option_labels: Array[Label] = []
var district_label: Label
var prompt: PanelContainer
var prompt_label: Label
var car_panel: PanelContainer
var car_label: Label
var gun_panel: PanelContainer
var gun_label: Label
var police_panel: PanelContainer
var police_label: Label
var notice_label: Label
var help_panel: PanelContainer
## M012: the game menu on Esc (it replaced the M005 pause screen; the sound
## levels are its Sound page).
var game_menu: GameMenu
## The sound levels on the pause screen: [name, bar, percent] per bus.
var sound_rows: Array = []
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
	var purse_row := HBoxContainer.new()
	purse_row.add_theme_constant_override("separation", 6)
	box.add_child(purse_row)
	purse_label = _label("", 16, DIM)
	purse_row.add_child(purse_label)
	item_icon = TextureRect.new()  # M010: the parcel, while he carries it
	item_icon.texture = resolver.get_texture("ui/item_parcel")
	item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_icon.custom_minimum_size = Vector2(26, 26)
	item_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	item_icon.visible = false
	purse_row.add_child(item_icon)
	_build_dialogue()
	clock_panel = _panel(Vector2.ZERO)
	var cb := VBoxContainer.new()
	cb.add_theme_constant_override("separation", -2)
	clock_panel.add_child(cb)
	clock_label = _label("", 19, CREAM)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home_label = _label("GET HOME TO BED", 14, Color("ffb070"))
	home_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home_label.visible = false
	cb.add_child(clock_label)
	cb.add_child(home_label)
	wake_screen = ColorRect.new()
	wake_screen.color = Color(0.02, 0.02, 0.04)
	wake_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wake_screen.visible = false
	add_child(wake_screen)
	wake_label = _label("", 30, CREAM)
	wake_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wake_screen.add_child(wake_label)
	prompt = _panel(Vector2.ZERO)
	prompt_label = _label("", 19, CREAM)
	prompt.add_child(prompt_label)
	prompt.visible = false
	car_panel = _panel(Vector2.ZERO)
	car_label = _label("", 18, CREAM)
	car_panel.add_child(car_label)
	car_panel.visible = false
	gun_panel = _panel(Vector2.ZERO)
	gun_label = _label("", 18, CREAM)
	gun_panel.add_child(gun_label)
	gun_panel.visible = false
	police_panel = _panel(Vector2.ZERO)
	police_label = _label("", 20, Color("ff7a5c"))
	police_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	police_panel.add_child(police_label)
	police_panel.visible = false
	notice_label = _label("", 20, Color("ffd9a0"))
	notice_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	notice_label.add_theme_constant_override("outline_size", 6)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(notice_label)
	help_panel = _panel(Vector2.ZERO)
	var help := _label(HELP_TEXT, 15, CREAM)
	help_panel.add_child(help)
	game_menu = GameMenu.new()
	add_child(game_menu)
	game_menu.setup(resolver, _font)
	for row in game_menu.sound_rows:
		sound_rows.append(row)
	crosshair = TextureRect.new()
	crosshair.texture = resolver.get_texture("ui/crosshair")
	crosshair.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crosshair.stretch_mode = TextureRect.STRETCH_SCALE
	crosshair.size = AssetCatalog.display_size("ui/crosshair")
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(crosshair)


func _build_dialogue() -> void:
	dialogue_panel = _panel(Vector2.ZERO)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	dialogue_panel.add_child(v)
	speaker_label = _label("", 17, COPPER)
	line_label = _label("", 20, CREAM)
	line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line_label.custom_minimum_size = Vector2(640, 0)
	v.add_child(speaker_label)
	v.add_child(line_label)
	for i in 4:
		var o := _label("", 18, CREAM)
		o.mouse_filter = Control.MOUSE_FILTER_STOP
		o.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				dialogue_choice.emit(i))
		v.add_child(o)
		option_labels.append(o)
	dialogue_panel.visible = false


## Straight double quotes turned into opening and closing curly ones, in turn.
static func _curly(t: String) -> String:
	var out := ""
	var open := true
	for ch in t:
		if ch == "\"":
			out += "\u201c" if open else "\u201d"
			open = not open
		else:
			out += ch
	return out


## Shows a conversation page ({speaker, text, options: [{id, text}], narrated}).
func show_dialogue(page: Dictionary) -> void:
	speaker_label.text = String(page.speaker).to_upper()
	if String(page.get("tone", "")) != "":
		speaker_label.text += "   (%s)" % page.tone  # M007: how the line is said
	# M009: a narrated page (what happens, with the speech in quotes) is shown as written
	line_label.text = _curly(String(page.text)) if page.get("narrated", false) else "\u201c%s\u201d" % page.text
	var options: Array = page.options
	for i in option_labels.size():
		var o := option_labels[i]
		o.visible = i < options.size()
		if o.visible:
			o.text = "%d   %s" % [i + 1, options[i].text]
			o.add_theme_color_override("font_color", DIM if options[i].id == "bye" else CREAM)
	dialogue_panel.visible = true
	_place_dialogue()


func hide_dialogue() -> void:
	dialogue_panel.visible = false


func _place_dialogue() -> void:
	var screen := get_viewport().get_visible_rect().size
	dialogue_panel.reset_size()
	dialogue_panel.position = Vector2((screen.x - dialogue_panel.size.x) * 0.5, screen.y - dialogue_panel.size.y - 24)


## The minimap in the bottom-left corner (M004).
func add_minimap(layout: DistrictLayout) -> void:
	minimap = Minimap.new()
	add_child(minimap)
	minimap.setup(layout, resolver, _panel_style(), _font)
	move_child(minimap, 0)  # under the dialogue panel and notices
	city_map = CityMap.new()
	add_child(city_map)
	city_map.setup(minimap, _font)
	status_screen = StatusScreen.new()
	add_child(status_screen)
	status_screen.setup(resolver, _font)
	fight_dial = FightDial.new()
	add_child(fight_dial)
	fight_dial.setup(resolver, _font)
	poker_view = PokerView.new()
	add_child(poker_view)
	poker_view.setup(resolver, _font)
	roulette_view = RouletteView.new()
	add_child(roulette_view)
	roulette_view.setup(resolver, _font)
	slot_view = SlotView.new()
	add_child(slot_view)
	slot_view.setup(resolver, _font)


## The status screen open (true, showing `condition`) or closed.
func show_status(on: bool, condition: BodyCondition = null) -> void:
	status_screen.visible = on
	if on:
		status_screen.layout_for(get_viewport().get_visible_rect().size)
		status_screen.show_condition(condition)


## The city map open (true) or closed (M008: on Danny, with the mouse to drag it round).
func show_map(on: bool, danny: Vector2 = Vector2.ZERO, district: Rect2 = Rect2()) -> void:
	city_map.visible = on
	if on:
		city_map.layout_for(get_viewport().get_visible_rect().size)
		city_map.open_on(danny, district if district.has_area() else city_map.city_rect)


## The clock at the top of the screen: "NIGHT 2   ·   11:40 PM", and a
## reminder to go home once it is late.
func set_clock(night: int, time_text: String, late: bool) -> void:
	clock_label.text = "NIGHT %d   \u00b7   %s" % [night, time_text]
	home_label.visible = late
	var screen := get_viewport().get_visible_rect().size
	clock_panel.reset_size()
	clock_panel.position = Vector2((screen.x - clock_panel.size.x) * 0.5, 12)


## Wakes up to a new night: a moment of black with its title, then the city.
func wake_up(night: int, time_text: String, news: String = "") -> void:
	wake_label.text = "NIGHT %d\n%s\n\n%s" % [night, time_text, news if news != "" else "The street lamps are coming on."]
	_wake_left = 3.0
	wake_screen.visible = true
	wake_screen.modulate.a = 1.0


## Money and bottles under the place name, and how much of the money is
## Rourke's (protection collected and not yet handed over).
## M010: what else Danny carries ("a parcel"), shown with the purse.
var carrying := ""
var item_icon: TextureRect


func set_purse(cents: int, bottles: int, rourkes: int = 0) -> void:
	var b := "no bottles" if bottles == 0 else ("1 bottle of rye" if bottles == 1 else "%d bottles of rye" % bottles)
	purse_label.text = "%s   \u00b7   %s" % [Rackets.dollars(cents), b]
	if carrying != "":
		purse_label.text += "   \u00b7   %s" % carrying
	if item_icon != null:
		item_icon.visible = carrying != ""
	if rourkes > 0:
		purse_label.text += "\n%s of it is Rourke's" % Rackets.dollars(rourkes)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _panel_style() -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = resolver.get_texture("ui/panel")
	var t := sb.texture.get_size() / 96.0
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		sb.set_texture_margin(side, 24.0 * t.x)
		sb.set_content_margin(side, 14.0)
	return sb


func _panel(at: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := _panel_style()
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


## The handgun readout (bottom right, while it is drawn): rounds left, or reloading.
func show_gun(gun: Gun) -> void:
	gun_panel.visible = gun != null and gun.is_drawn()
	if not gun_panel.visible:
		return
	if gun.is_reloading():
		gun_label.text = "%s   reloading..." % gun.rules.display_name
	else:
		gun_label.text = "%s   %d / %d" % [gun.rules.display_name, gun.ammo, gun.rules.magazine]
		if gun.spare >= 0:
			gun_label.text += "   +%d" % gun.spare if gun.spare > 0 else "   no spare rounds"
	var screen := get_viewport().get_visible_rect().size
	gun_panel.reset_size()
	gun_panel.position = Vector2(screen.x - gun_panel.size.x - 18, screen.y - gun_panel.size.y - 18)


## The pursuit line at the top of the screen, from the officer's state.
## M008: the district Danny is in now (top-left).
func set_district(district_name: String) -> void:
	district_label.text = district_name.to_upper()


func set_police_status(state: int, armed: bool = false) -> void:
	match state:
		OfficerBrain.State.ALERTED, OfficerBrain.State.CHASE:
			police_label.text = "THE COPPER IS SHOOTING AT YOU" if armed else "A COPPER IS ON YOUR TAIL"
			police_label.add_theme_color_override("font_color", Color("ff7a5c"))
			police_label.visible = true
		OfficerBrain.State.SEARCH:
			police_label.text = "THE COPPER IS LOOKING FOR YOU"
			police_label.add_theme_color_override("font_color", Color("ffcf7a"))
			police_label.visible = true
		_:
			police_label.visible = false
	police_panel.visible = police_label.visible
	var screen := get_viewport().get_visible_rect().size
	police_panel.reset_size()
	police_panel.position = Vector2((screen.x - police_panel.size.x) * 0.5, 84)


func set_paused(on: bool) -> void:
	if on:
		game_menu.layout_for(get_viewport().get_visible_rect().size)
		game_menu.open()
	else:
		game_menu.close()


## The volume of each bus on the menu's Sound page, the chosen one highlighted.
func show_sound(settings: AudioSettings, selected: int) -> void:
	for i in sound_rows.size():
		var bus: String = AudioSettings.BUSES[i]
		var v: float = settings.volume[bus]
		var steps := int(round(v * 10.0))
		var row: Array = sound_rows[i]
		(row[1] as Label).text = "|".repeat(steps) + ".".repeat(10 - steps)
		(row[2] as Label).text = "%d%%" % int(round(v * 100.0))
		for l in row:
			(l as Label).add_theme_color_override("font_color", GameMenu.ACCENT if i == selected else GameMenu.INK_DIM)


## Refreshes everything from the current state.
func refresh(delta: float, place: String, prompt_text: String, driving: Car, mouse: Vector2, show_crosshair: bool) -> void:
	var screen := get_viewport().get_visible_rect().size
	place_label.text = place if place != "" else " "
	prompt.visible = prompt_text != "" and not dialogue_panel.visible
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
	# M012: a long notice wraps instead of running off the screen
	var widest := screen.x - 240.0
	var one_line := _font.get_string_size(notice_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		notice_label.get_theme_font_size("font_size")).x + 8.0
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if one_line > widest else TextServer.AUTOWRAP_OFF
	notice_label.custom_minimum_size = Vector2(minf(one_line, widest), 0)
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
	if game_menu.visible and game_menu.size != screen:
		game_menu.layout_for(screen)
	if minimap != null:
		minimap.position = Vector2(18, screen.y - Minimap.SIZE.y - 18)
	if city_map != null and city_map.visible:
		city_map.layout_for(screen)
	if poker_view != null and poker_view.visible and poker_view.size != screen:
		poker_view.layout_for(screen)
	if roulette_view != null and roulette_view.visible and roulette_view.size != screen:
		roulette_view.layout_for(screen)
	if slot_view != null and slot_view.visible and slot_view.size != screen:
		slot_view.layout_for(screen)
	if _wake_left > 0.0:
		_wake_left -= delta
		wake_screen.size = screen
		wake_label.size = Vector2(screen.x, 200)
		wake_label.position = Vector2(0, screen.y * 0.5 - 100)
		wake_screen.modulate.a = clampf(_wake_left / 1.5, 0.0, 1.0)
		wake_screen.visible = _wake_left > 0.0
	crosshair.visible = show_crosshair and not dialogue_panel.visible and not wake_screen.visible
	if dialogue_panel.visible:
		_place_dialogue()
	crosshair.position = mouse - crosshair.size * 0.5
