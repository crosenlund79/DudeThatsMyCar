class_name GameMenu
extends Control
## M012: the game menu on Esc - a worn leather case with brass corners, the
## entries down its left side in gilt, and a page of old paper on the right:
## Resume, Save the game, Load the last save, the Notebook (what is on Danny's
## plate tonight), Controls (every key), Sound (the six levels), Developer
## tools (M015: for testing - switched on here first; the game's DevTools
## lists them) and Save and quit. The world waits underneath (the game
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
	["controls", "Controls"], ["sound", "Sound"], ["cheats", "Developer tools"], ["quit", "Save and quit"],
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
## M015: the developer tools' page shows this many tools at a time (a long list scrolls with the cursor).
const DEV_ROWS := 12

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
## M015: the Notebook as case sheets (Casebook.cases, set by the game), the
## sheet on show and how far down it is scrolled; whether work is marked in the street.
var cases: Array = []
var case_index := 0
var case_scroll := 0
var markers_on := true
## A line under the entries ("Saved: Night 2, 11:40 PM").
var status := ""
## Whether there is a save to go back to (Load is greyed out otherwise).
var can_load := true
## M015: the developer tools - switched on (the player's preference), their
## categories as the game lists them ([{name, tools: [{id, name, ask}]}]), and
## where the cursor is on that page.
var dev_on := false
var dev_categories: Array = []
var dev_cat := 0
var dev_row := 0
var _dev_confirm := ""
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
	if page == "cheats" and not event.is_action(CityInput.MENU):
		var dev := _dev_key(event)
		if dev != "?":
			return dev
	if page == "notebook" and not event.is_action(CityInput.MENU):
		var nb := _notebook_key(event)
		if nb != "?":
			return nb
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


## M015: a key on the Notebook page: Left / Right another case, Up / Down
## scroll the sheet, Enter switches the work marks in the street on or off
## ("markers": the game keeps the preference). "?" when not the page's key.
func _notebook_key(event: InputEvent) -> String:
	var n := cases.size()
	if event.is_action("ui_accept") or event.is_action(CityInput.INTERACT) or event.is_action(CityInput.HANDBRAKE):
		return "markers"
	if n == 0:
		return "?"
	if event.is_action("ui_left") or event.is_action(CityInput.LEFT):
		case_index = (case_index + n - 1) % n
		case_scroll = 0
	elif event.is_action("ui_right") or event.is_action(CityInput.RIGHT):
		case_index = (case_index + 1) % n
		case_scroll = 0
	elif event.is_action("ui_up") or event.is_action(CityInput.UP):
		case_scroll = maxi(0, case_scroll - 1)
	elif event.is_action("ui_down") or event.is_action(CityInput.DOWN):
		case_scroll += 1
	else:
		return "?"
	_refresh()
	return ""


## M015: a key on the developer tools' page: "dev_on" (switch them on),
## "dev:<id>" (use a tool), "" (the page took it), "?" (not the page's key).
func _dev_key(event: InputEvent) -> String:
	var accept: bool = event.is_action("ui_accept") or event.is_action(CityInput.INTERACT) or event.is_action(CityInput.HANDBRAKE)
	if not dev_on:
		return "dev_on" if accept else "?"
	if dev_categories.is_empty():
		return "?"
	var n := dev_categories.size()
	if event.is_action("ui_left") or event.is_action(CityInput.LEFT):
		dev_cat = (dev_cat + n - 1) % n
	elif event.is_action("ui_right") or event.is_action(CityInput.RIGHT):
		dev_cat = (dev_cat + 1) % n
	elif event.is_action("ui_up") or event.is_action(CityInput.UP):
		dev_row = maxi(0, dev_row - 1)
		_dev_confirm = ""
		_refresh()
		return ""
	elif event.is_action("ui_down") or event.is_action(CityInput.DOWN):
		dev_row = mini((dev_categories[dev_cat].tools as Array).size() - 1, dev_row + 1)
		_dev_confirm = ""
		_refresh()
		return ""
	elif accept:
		return dev_pick(dev_row)
	else:
		return "?"
	dev_row = 0
	_dev_confirm = ""
	_refresh()
	return ""


## Tool `i` of the category on show: a tool that throws something away asks
## first (a second Enter or click goes ahead). Returns "dev:<id>" or "".
func dev_pick(i: int) -> String:
	var tools: Array = dev_categories[dev_cat].tools if dev_cat < dev_categories.size() else []
	if i < 0 or i >= tools.size():
		return ""
	dev_row = i
	var tool: Dictionary = tools[i]
	if String(tool.ask) != "" and _dev_confirm != String(tool.id):
		_dev_confirm = String(tool.id)
		status = "%s  Enter again to go ahead." % tool.ask
		_refresh()
		return ""
	_dev_confirm = ""
	return "dev:" + String(tool.id)


func _on_dev_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var what := dev_pick(i)
		if what != "":
			action.emit(what)
		accept_event()


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
			if cases.is_empty():
				_text("Nothing on your plate tonight. The city has a way of finding you.")
				for e in notebook:
					_sub(String(e.title))
					for line in e.lines:
						_text(String(line))
			else:
				_case_sheet()
			_page_box.add_child(_label("Enter: work marked in the street - %s" % ("on" if markers_on else "off"), _serif, 12, INK_DIM))
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
			_heading("Developer tools")
			var note := _label("For testing the game - not part of it. Every tool works through the game itself; nothing is "
				+ "saved until the game saves.", _serif, 13, INK_DIM)
			note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			note.custom_minimum_size = Vector2(CARD_SIZE.x - 76, 0)
			_page_box.add_child(note)
			if not dev_on:
				_text("Switched off.  Enter: switch them on (they stay on in later games until switched off here).")
			elif not dev_categories.is_empty():
				dev_cat = clampi(dev_cat, 0, dev_categories.size() - 1)
				var cat: Dictionary = dev_categories[dev_cat]
				var tools: Array = cat.tools
				dev_row = clampi(dev_row, 0, maxi(0, tools.size() - 1))
				_sub("‹  %s  ›      %d of %d" % [cat.name, dev_cat + 1, dev_categories.size()])
				var first := clampi(dev_row - DEV_ROWS / 2, 0, maxi(0, tools.size() - DEV_ROWS))
				for i in range(first, mini(tools.size(), first + DEV_ROWS)):
					var on := i == dev_row
					var asks: bool = String(tools[i].ask) != ""
					var l := _label(("›  " if on else "    ") + String(tools[i].name) + ("   (asks first)" if asks else ""),
						_serif_bold if on else _serif, 14, ACCENT if on else INK)
					l.mouse_filter = Control.MOUSE_FILTER_STOP
					l.gui_input.connect(_on_dev_input.bind(i))
					_page_box.add_child(l)
				if tools.size() > DEV_ROWS:
					_page_box.add_child(_label("    (%d more: Up / Down)" % (tools.size() - DEV_ROWS), _serif, 12, INK_DIM))
				_page_box.add_child(_label("Left / Right: another kind     Up / Down: choose     Enter or a click: use", _serif, 12, INK_DIM))
		"quit":
			_heading("Save and quit")
			_text("Saves the game where it stands and closes it. Next time it goes on from here.")


## M015: one case sheet: its name and where it stands, then the things,
## persons and places in it, what Danny knows, what he doesn't, and his leads
## (only as much as fits; Up / Down scroll the rest).
const SHEET_LINES := 13
const STAMPS := {"open": "OPEN", "lead": "A HUNCH", "closed": "CLOSED", "lapsed": "LAPSED"}

func _case_sheet() -> void:
	case_index = clampi(case_index, 0, cases.size() - 1)
	var c: Dictionary = cases[case_index]
	_sub("‹  %s  ›      %d of %d" % [String(c.title), case_index + 1, cases.size()])
	var stamp := _label("%s   ·   %s" % [STAMPS.get(String(c.status), ""), "Rourke's business" if String(c.who) == "Rourke" else "your own business"],
		_serif_bold, 12, ACCENT if c.status == "open" or c.status == "lead" else INK_DIM)
	_page_box.add_child(stamp)
	var rows := []  # [kind, text]: "h" a heading, "s" the standing, "l" a line
	if String(c.standing) != "":
		rows.append(["s", String(c.standing)])
	for part in [["things", "Things"], ["persons", "Persons"], ["places", "Places"], ["known", "What you know"],
			["unknown", "What you don't"], ["leads", "Leads"]]:
		var lines: Array = c.get(part[0], [])
		if lines.is_empty():
			continue
		rows.append(["h", String(part[1]).to_upper()])
		for line in lines:
			rows.append(["l", String(line)])
	case_scroll = clampi(case_scroll, 0, maxi(0, rows.size() - SHEET_LINES))
	var shown := 0
	for i in range(case_scroll, rows.size()):
		if shown >= SHEET_LINES:
			break
		var row: Array = rows[i]
		var l: Label
		match row[0]:
			"s":
				l = _label(String(row[1]), _serif, 14, INK)
			"h":
				l = _label(String(row[1]), _serif_bold, 11, ACCENT)
			_:
				l = _label("-  " + String(row[1]), _serif, 13, INK)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(CARD_SIZE.x - 76, 0)
		_page_box.add_child(l)
		shown += 1
	var more := rows.size() - case_scroll - shown
	_page_box.add_child(_label("Left / Right: another case%s" % ("     Up / Down: %d more lines" % more if more > 0 or case_scroll > 0 else ""),
		_serif, 12, INK_DIM))


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
