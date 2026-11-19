class_name GameMenu
extends Control
## M012: the game menu on Esc - a worn leather case with brass corners, the
## entries down its left side in gilt, and a page of old paper on the right:
## Resume, Save the game, Load the last save, the Notebook (what is on Danny's
## plate tonight), Controls (every key), Sound (the six levels), Cheats (none
## in this build) and Save and quit. The world waits underneath (the game
## pauses it). Presentation and navigation only: the game does the saving,
## loading and quitting when `handle_key` / a click asks for it.
##
## Keys: W / S or the arrows choose, Enter / E / Space open, Esc goes back (on
## the list itself: resume). On the Sound page Up / Down choose a level and
## Left / Right change it (the game owns the levels: see Hud.show_sound).

## The game is asked to resume, save, load or quit ("" = nothing to do).
signal action(what: String)

const ENTRIES := [
	["resume", "Resume"], ["save", "Save the game"], ["load", "Load the last save"], ["notebook", "Notebook"],
	["controls", "Controls"], ["sound", "Sound"], ["cheats", "Cheats"], ["quit", "Save and quit"],
]
## Every key, as the Controls page lists it.
const CONTROLS := [
	["ON FOOT", [["W A S D", "walk"], ["Left Shift (hold)", "run"], ["Mouse", "aim"],
		["Left click", "shoot (hold it down: the Thompson)"], ["Tab", "the other gun, if you carry two"],
		["H", "draw the gun and keep it out / put it away"], ["E", "talk, look, go in or out, sit, get in a car"],
		["1 - 4 or a click", "answer"]]],
	["DRIVING", [["W", "accelerate"], ["S", "brake, then reverse"], ["A  D", "steer"], ["Space", "handbrake"],
		["E", "get out"]]],
	["THE CITY", [["M", "the city map - drag it, wheel to zoom, R: back to you"], ["C", "how Danny is"],
		["F1", "the controls card"], ["Esc", "this menu"]]],
	["AT THE TABLES", [["Space", "cards: go on  ·  wheel: spin  ·  machine: pull"],
		["Click / right click", "cards: bet  ·  wheel: put a chip down, take one back"],
		["1 - 4, mouse wheel", "wheel: choose a chip"], ["Backspace  /  R", "wheel: clear the layout / the same again"],
		["Esc", "get up from the table"]]],
	["IN A FIGHT", [["Space", "throw the punch while the needle is in the bright zone"]]],
]
## Cheats: none in this build. One {id, name} per cheat when there are some -
## the page lists them, greyed out, until a build turns them on.
const CHEATS: Array = []

const INK := Color("2a1a10")
const INK_DIM := Color("2a1a10", 0.62)
const ACCENT := Color("8a2e14")
const GILT := Color("d8a860")
const GILT_DIM := Color("d8a860", 0.55)
const CREAM := Color("f1e4c6")
const PANEL_SIZE := Vector2(900, 560)
const CARD_SIZE := Vector2(540, 470)

var selected := 0
## "" while choosing on the list, else the id of the open page.
var page := ""
## What the Notebook shows: [{title, lines: [String]}] (set by the game).
var notebook: Array = []
## A line under the entries ("Saved: Night 2, 11:40 PM").
var status := ""
## Whether there is a save to go back to (Load is greyed out otherwise).
var can_load := true
## The six sound levels [name, bar, percent] (labels the game fills in).
var sound_rows: Array = []

var _font: Font
var _serif: Font
var _serif_bold: Font
var _panel: TextureRect
var _card: TextureRect
var _entries: Array[Label] = []
var _status_label: Label
var _page_box: VBoxContainer
var _sound_box: VBoxContainer


func setup(resolver: AssetResolver, font: Font) -> void:
	name = "GameMenu"
	CityInput.ensure_actions()  # its keys are the game's (Esc, Q, W, S, E, Space)
	_font = font
	_serif = load("res://assets/fonts/Caladea-Regular.ttf")
	_serif_bold = load("res://assets/fonts/Caladea-Bold.ttf")
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.01, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_panel = _texture(resolver, "ui/menu_panel", PANEL_SIZE)
	add_child(_panel)
	var title := _label("CHICAGO, 1932", _serif_bold, 30, GILT)
	title.position = Vector2(44, 34)
	_panel.add_child(title)
	var sub := _label("Danny \"Dimes\" Mercer", _serif, 16, GILT_DIM)
	sub.position = Vector2(46, 72)
	_panel.add_child(sub)
	for i in ENTRIES.size():
		var l := _label(ENTRIES[i][1], _serif_bold, 21, GILT_DIM)
		l.position = Vector2(48, 118 + i * 44)
		l.mouse_filter = Control.MOUSE_FILTER_STOP
		l.gui_input.connect(_on_entry_input.bind(i))
		_panel.add_child(l)
		_entries.append(l)
	_status_label = _label("", _serif, 14, GILT_DIM)
	_status_label.position = Vector2(48, 488)
	_status_label.size = Vector2(250, 40)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_status_label)
	_card = _texture(resolver, "ui/menu_card", CARD_SIZE)
	_card.position = Vector2(PANEL_SIZE.x - CARD_SIZE.x - 40, (PANEL_SIZE.y - CARD_SIZE.y) * 0.5)
	_panel.add_child(_card)
	_page_box = VBoxContainer.new()
	_page_box.position = Vector2(38, 34)
	_page_box.size = CARD_SIZE - Vector2(76, 68)
	_page_box.add_theme_constant_override("separation", 6)
	_card.add_child(_page_box)
	_sound_box = VBoxContainer.new()
	_sound_box.add_theme_constant_override("separation", 10)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	for bus in AudioSettings.BUSES:
		var row: Array[Label] = [_label(bus, _serif_bold, 19, INK_DIM), _label("", _serif, 19, INK_DIM), _label("", _serif, 19, INK_DIM)]
		row[2].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		for l in row:
			grid.add_child(l)
		sound_rows.append(row)
	_sound_box.add_child(grid)
	_sound_box.add_child(_label("Up / Down   choose a level\nLeft / Right   quieter, louder\nEsc   back", _serif, 15, INK_DIM))


func is_open() -> bool:
	return visible


func open(at_page: String = "") -> void:
	visible = true
	selected = 0
	status = ""
	show_page(at_page)


func close() -> void:
	visible = false
	page = ""


func layout_for(screen: Vector2) -> void:
	position = Vector2.ZERO
	size = screen
	var scale_by := minf(1.0, minf(screen.x / (PANEL_SIZE.x + 40.0), screen.y / (PANEL_SIZE.y + 40.0)))
	_panel.scale = Vector2(scale_by, scale_by)
	_panel.position = ((screen - PANEL_SIZE * scale_by) * 0.5).floor()


## The id of the entry under the cursor.
func current() -> String:
	return ENTRIES[selected][0]


## Opens a page ("" = back to the list with nothing open).
func show_page(id: String) -> void:
	page = id
	for i in ENTRIES.size():
		if ENTRIES[i][0] == id:
			selected = i
	_refresh()


func say(text: String) -> void:
	status = text
	_refresh()


## A key while the menu is open. Returns what the game must do: "" (nothing),
## "resume", "save", "load", "quit" - or "sound" (the Sound page has the key:
## the game changes the levels).
func handle_key(event: InputEvent) -> String:
	if not (event is InputEventKey or event is InputEventAction) or not event.is_pressed() or event.is_echo():
		return ""
	if page == "sound" and (event.is_action("ui_up") or event.is_action("ui_down") or event.is_action("ui_left")
			or event.is_action("ui_right")):
		return "sound"
	if event.is_action(CityInput.MENU):
		if page != "":
			show_page("")
			return ""
		return "resume"
	if event.is_action(CityInput.QUIT):
		return "quit"
	if event.is_action("ui_up") or event.is_action(CityInput.UP):
		selected = (selected + ENTRIES.size() - 1) % ENTRIES.size()
		page = ""
		_refresh()
	elif event.is_action("ui_down") or event.is_action(CityInput.DOWN):
		selected = (selected + 1) % ENTRIES.size()
		page = ""
		_refresh()
	elif event.is_action("ui_accept") or event.is_action(CityInput.INTERACT) or event.is_action(CityInput.HANDBRAKE):
		return choose(selected)
	return ""


## Picks entry i (a click, or Enter on it). Returns what the game must do.
func choose(i: int) -> String:
	selected = i
	var id: String = ENTRIES[i][0]
	match id:
		"resume", "save", "quit":
			_refresh()
			return id
		"load":
			_refresh()
			return "load" if can_load else ""
	show_page(id)
	return ""


func _on_entry_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var what := choose(i)
		if what != "":
			action.emit(what)
		accept_event()


func _refresh() -> void:
	for i in _entries.size():
		var on := i == selected
		var greyed: bool = ENTRIES[i][0] == "load" and not can_load
		_entries[i].text = ("›  " if on else "    ") + String(ENTRIES[i][1])
		_entries[i].add_theme_color_override("font_color", CREAM if on and not greyed else (GILT_DIM if not greyed else Color(GILT, 0.3)))
	_status_label.text = status
	if _sound_box.get_parent() != null:
		_sound_box.get_parent().remove_child(_sound_box)
	for c in _page_box.get_children():
		_page_box.remove_child(c)
		c.queue_free()
	var show := page if page != "" else current()
	match show:
		"resume":
			_heading("The night goes on")
			_text("Esc or Enter to go back to the street. Nothing moves while this case is open: not the clock, not the "
				+ "cards, not the coppers.")
		"save":
			_heading("Save the game")
			_text("Writes down where Danny is and what he has - in the street or in a room, any part of town - and the "
				+ "minute of the night. The game saves itself after every deal as well.")
		"load":
			_heading("Load the last save")
			_text("Back to how things stood when the game was last saved. Whatever happened since is undone." if can_load
				else "There is no saved game to go back to yet.")
		"notebook":
			_heading("Notebook")
			if notebook.is_empty():
				_text("Nothing on your plate tonight. The city has a way of finding you.")
			for e in notebook:
				_sub(String(e.title))
				for line in e.lines:
					_text(String(line))
		"controls":
			_heading("Controls")
			# two columns on the card: on foot and driving; the city, the tables and a fight
			var cols := HBoxContainer.new()
			cols.add_theme_constant_override("separation", 18)
			_page_box.add_child(cols)
			var half := (CARD_SIZE.x - 76.0 - 18.0) * 0.5
			for part in [CONTROLS.slice(0, 2), CONTROLS.slice(2)]:
				var col := VBoxContainer.new()
				col.add_theme_constant_override("separation", 2)
				col.custom_minimum_size = Vector2(half, 0)
				cols.add_child(col)
				for group in part:
					col.add_child(_label(String(group[0]), _serif_bold, 13, ACCENT))
					var grid := GridContainer.new()
					grid.columns = 2
					grid.add_theme_constant_override("h_separation", 8)
					grid.add_theme_constant_override("v_separation", -1)
					for k in group[1]:
						var key := _label(String(k[0]), _serif_bold, 12, INK)
						key.custom_minimum_size = Vector2(78, 0)
						key.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
						grid.add_child(key)
						var a := _label(String(k[1]), _serif, 12, INK)
						a.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
						a.custom_minimum_size = Vector2(half - 86.0, 0)
						grid.add_child(a)
					col.add_child(grid)
		"sound":
			_heading("Sound")
			_page_box.add_child(_sound_box)
		"cheats":
			_heading("Cheats")
			if CHEATS.is_empty():
				_text("None in this build. When there are some, they will be listed here - and stay switched off until "
					+ "you switch them on.")
			for c in CHEATS:
				_page_box.add_child(_label("·  " + String(c.name), _serif, 16, INK_DIM))
		"quit":
			_heading("Save and quit")
			_text("Saves the game where it stands and closes it. Next time it goes on from here.")


func _heading(text: String) -> void:
	_page_box.add_child(_label(text, _serif_bold, 26, INK))
	var rule := ColorRect.new()
	rule.color = Color(INK, 0.5)
	rule.custom_minimum_size = Vector2(0, 1.5)
	_page_box.add_child(rule)


func _sub(text: String) -> void:
	var l := _label(text, _serif_bold, 15, ACCENT)
	_page_box.add_child(l)


func _text(text: String) -> void:
	var l := _label(text, _serif, 16, INK)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(CARD_SIZE.x - 76, 0)
	_page_box.add_child(l)


func _label(text: String, font: Font, px: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _texture(resolver: AssetResolver, logical: String, at_size: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = resolver.get_texture(logical)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.size = at_size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t
