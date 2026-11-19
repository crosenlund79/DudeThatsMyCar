class_name RouletteView
extends Control
## M011: the gaming room's wheel on screen, over the dimmed room: the wheel in
## its bowl at the left, the single-zero layout on the baize at the right, the
## chip tray, the last numbers, what Danny has in his pocket and on the table.
##
## 1-4 (or a click on the tray, or the mouse wheel) picks a chip - 5¢, 10¢,
## 25¢, $1; a click on the layout puts it on the bet under the pointer (a
## number's middle, the line between two numbers, a crossing, the edge under a
## column of three or between two, the boxes outside); a right click takes one
## back; Backspace takes them all back; R puts last spin's bets down again;
## Space spins ("no more bets"); Esc or E walks away (chips not yet spun come
## back; a spin under way is settled at once). The covered numbers light up
## under the pointer, with what the bet pays.
##
## The money and the rules are Roulette's, moved by the game (main) on this
## view's requests; the number is decided when the wheel is spun, and the
## wheel and the ball here only show it (RouletteSpin lands the ball in that
## pocket). When the ball comes to rest the view says so (`spin_finished`)
## and the game settles - once.

signal bet_requested(key: String, chip: int)
signal take_back_requested(key: String, chip: int)
signal clear_requested
signal repeat_requested
signal spin_requested
## The ball has come to rest in its pocket: time to settle.
signal spin_finished
signal leave_requested
## A sound for the game to play: "chips", "spin", "ball_drop", "ball_rest", "win", "lose".
signal sound(kind: String)

const CREAM := Color("f1e4c6")
const DIM := Color("f1e4c6", 0.55)
const COPPER := Color("d8a060")
const GOLD := Color("ffd86a")
const PLATE := Color(0.07, 0.05, 0.04, 0.88)
const RED := Color("9a2322")
const BLACK := Color("1c1a1e")
const GREEN := Color("2f7a3a")
const LINE := Color("e8dcc0", 0.85)
const CHIP_COLOURS := {5: Color("e8e0cf"), 10: Color("c0392b"), 25: Color("2f5fa8"), 100: Color("2f7a46")}
## Base screen px (at 1280 x 720), from the screen's middle.
const WHEEL_AT := Vector2(-345, 10)
const BOWL_RADIUS := 165.0
const LAYOUT_AT := Vector2(-150, -150)
const LAYOUT_SCALE := 1.15

var table: Roulette
var money := 0
var chip_index := 0
var phase := "closed"  # closed / betting / spinning / result
var message := ""
var result_line := ""
var hover_key := ""
var centre := Vector2(640, 340)
var ui_scale := 1.0
var spin: RouletteSpin = null
var spin_t := 0.0
var rotor_angle := 0.0
var _finished := false
var _dropped := false
var _buttons: Array = []  # {rect, id}
var _font: Font
var _felt: Texture2D
var _bowl: Texture2D
var _rotor: Texture2D
var _ball: Texture2D
var _chip: Texture2D
var _dolly: Texture2D
var _rng := RandomNumberGenerator.new()
var _ball_rest := -PI / 2.0  # where the ball lies (relative to the head) between spins
## The wheel on a layer of its own: while it spins only the wheel is drawn
## again each frame, not the whole table (its layout, chips and text).
var _wheel_layer: Control


func setup(resolver: AssetResolver, font: Font) -> void:
	name = "RouletteView"
	_font = font
	_felt = resolver.get_texture("ui/roulette_felt")
	_bowl = resolver.get_texture("ui/roulette_bowl")
	_rotor = resolver.get_texture("ui/roulette_rotor")
	_ball = resolver.get_texture("ui/roulette_ball")
	_chip = resolver.get_texture("ui/poker_chip")
	_dolly = resolver.get_texture("ui/roulette_dolly")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_PAUSABLE
	visible = false
	_rng.randomize()
	_wheel_layer = Control.new()
	_wheel_layer.name = "Wheel"
	_wheel_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wheel_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wheel_layer.draw.connect(_draw_wheel)
	add_child(_wheel_layer)


func layout_for(screen: Vector2) -> void:
	size = screen
	ui_scale = minf(screen.x / 1280.0, screen.y / 720.0)
	centre = Vector2(screen.x * 0.5, screen.y * 0.5 - 20.0 * ui_scale)
	refresh()


func is_open() -> bool:
	return phase != "closed"


func open(p_table: Roulette, p_money: int) -> void:
	table = p_table
	money = p_money
	phase = "betting"
	message = "Place your bets."
	result_line = ""
	hover_key = ""
	spin = null
	visible = true
	refresh()


func close() -> void:
	phase = "closed"
	visible = false
	spin = null


func set_money(cents: int) -> void:
	money = cents
	queue_redraw()


## A word from the croupier (or why something cannot be done).
func say(text: String) -> void:
	message = text
	queue_redraw()


func chip() -> int:
	return table.rules.chips[clampi(chip_index, 0, table.rules.chips.size() - 1)]


## The wheel is spun: the head and the ball show `number` coming up.
func start_spin(number: int, seconds: float) -> void:
	spin = RouletteSpin.new(number, rotor_angle, rotor_angle + _rng.randf_range(0.0, TAU), seconds)
	spin_t = 0.0
	_finished = false
	_dropped = false
	phase = "spinning"
	message = "No more bets."
	result_line = ""
	sound.emit("spin")
	refresh()


## The round is settled: what came up and what it paid.
func show_result(paid: int) -> void:
	phase = "result"
	var n := table.result
	var words := "%d  %s" % [n, "green" if n == 0 else Roulette.colour(n)]
	if n != 0:
		words += ", %s, %s" % ["odd" if n % 2 else "even", "low" if n <= 18 else "high"]
	result_line = words
	var net := paid - table.staked
	if paid > 0:
		message = "%s.   You collect %s%s." % [words, PokerView.money_text(paid),
			"  (%s ahead)" % PokerView.money_text(net) if net > 0 else ("  (%s down)" % PokerView.money_text(-net) if net < 0 else "")]
		sound.emit("win")
	else:
		message = "%s.   The house takes %s." % [words, PokerView.money_text(table.staked)]
		sound.emit("lose")
	queue_redraw()


func _process(delta: float) -> void:
	if phase == "closed" or spin == null:
		return
	spin_t += delta
	rotor_angle = spin.rotor_angle(spin_t)
	if not _dropped and spin_t >= spin.duration * RouletteSpin.DROP:
		_dropped = true
		sound.emit("ball_drop")
	if not _finished and spin.done(spin_t):
		_finished = true
		_ball_rest = RouletteSpin.pocket_angle(spin.result)
		sound.emit("ball_rest")
		spin_finished.emit()
	if spin_t < spin.duration + 12.0:
		_wheel_layer.queue_redraw()  # only the wheel moves


## The whole table drawn again (state changed), the wheel with it.
func refresh() -> void:
	queue_redraw()
	if _wheel_layer != null:
		_wheel_layer.queue_redraw()


## The keys at the table (the game hands them on while the view is open).
func handle_key(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			pick_chip(chip_index + 1)
			return true
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			pick_chip(chip_index - 1)
			return true
		return false
	if not (event is InputEventKey and event.pressed and not event.echo):
		return event is InputEventKey
	var k: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if k == KEY_ESCAPE or k == KEY_E:
		leave_requested.emit()
	elif k >= KEY_1 and k <= KEY_4:
		pick_chip(k - KEY_1)
	elif k == KEY_SPACE or k == KEY_ENTER or k == KEY_KP_ENTER:
		spin_requested.emit()
	elif k == KEY_BACKSPACE or k == KEY_DELETE:
		clear_requested.emit()
	elif k == KEY_R:
		repeat_requested.emit()
	return true


func pick_chip(i: int) -> void:
	chip_index = clampi(i, 0, table.rules.chips.size() - 1)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var k := _bet_under(event.position)
		if k != hover_key:
			hover_key = k
			queue_redraw()
		return
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		for b in _buttons:
			if (b.rect as Rect2).has_point(event.position):
				_click(b.id)
				accept_event()
				return
		var key := _bet_under(event.position)
		if key != "":
			bet_requested.emit(key, chip())
		accept_event()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		var key2 := _bet_under(event.position)
		if key2 != "":
			take_back_requested.emit(key2, chip())
		accept_event()
	elif handle_key(event):
		accept_event()


func _click(id: String) -> void:
	match id:
		"leave":
			leave_requested.emit()
		"spin":
			spin_requested.emit()
		"clear":
			clear_requested.emit()
		"repeat":
			repeat_requested.emit()
		_:
			if id.begins_with("chip"):
				pick_chip(int(id.substr(4)))


# ------------------------------------------------------------------ geometry

func _s(v: float) -> float:
	return v * ui_scale


func _layout_origin() -> Vector2:
	return centre + LAYOUT_AT * ui_scale


func _k() -> float:
	return LAYOUT_SCALE * ui_scale


func _to_layout(p: Vector2) -> Vector2:
	return (p - _layout_origin()) / _k()


func _from_layout(p: Vector2) -> Vector2:
	return _layout_origin() + p * _k()


func _bet_under(p: Vector2) -> String:
	return RouletteLayout.bet_at(_to_layout(p))


## Where the ball is drawn now (screen px).
func ball_position() -> Vector2:
	var wc := centre + WHEEL_AT * ui_scale
	var rw := _s(BOWL_RADIUS)
	if spin != null:
		return wc + Vector2.from_angle(spin.ball_angle(spin_t)) * spin.ball_radius(spin_t) * rw
	return wc + Vector2.from_angle(rotor_angle + _ball_rest) * RouletteSpin.POCKET * rw


# ------------------------------------------------------------------ drawing

func _text(pos: Vector2, s: String, size: int, colour: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var fs := int(round(size * ui_scale))
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x := pos.x - (w * 0.5 if align == HORIZONTAL_ALIGNMENT_CENTER else (w if align == HORIZONTAL_ALIGNMENT_RIGHT else 0.0))
	draw_string_outline(_font, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(4 * ui_scale), Color(0, 0, 0, 0.7))
	draw_string(_font, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)


func _panel(r: Rect2, border: Color = Color(COPPER, 0.6), width := 2.0) -> void:
	draw_rect(r, PLATE)
	draw_rect(r, border, false, width * ui_scale)


func _draw() -> void:
	_buttons.clear()
	if table == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.015, 0.02, 0.62))
	var felt_size := AssetCatalog.display_size("ui/roulette_felt") * ui_scale
	draw_texture_rect(_felt, Rect2(centre - felt_size * 0.5, felt_size), false)
	_draw_layout()
	_draw_bets()
	_draw_history()
	_draw_tray()
	_draw_status()
	var r := Rect2(Vector2(size.x - _s(250), size.y - _s(60)), Vector2(_s(230), _s(30)))
	_panel(r, Color(COPPER, 0.4), 1.0)
	_text(r.get_center() + Vector2(0, _s(6)), "Esc   Leave the wheel", 15, DIM)
	_buttons.append({"rect": r, "id": "leave"})


func _draw_wheel() -> void:
	if table == null or phase == "closed":
		return
	var c := _wheel_layer
	var wc := centre + WHEEL_AT * ui_scale
	var rw := _s(BOWL_RADIUS)
	c.draw_texture_rect(_bowl, Rect2(wc - Vector2(rw, rw), Vector2(rw, rw) * 2.0), false)
	var rr := rw * RouletteSpin.ROTOR
	c.draw_set_transform(wc, rotor_angle, Vector2.ONE)
	c.draw_texture_rect(_rotor, Rect2(-rr, -rr, rr * 2.0, rr * 2.0), false)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var b := _s(13.0)
	var bp := ball_position()
	c.draw_texture_rect(_ball, Rect2(bp - Vector2(b, b) * 0.5, Vector2(b, b)), false)


func _cell_colour(n: int) -> Color:
	return GREEN if n == 0 else (RED if n in Roulette.REDS else BLACK)


func _draw_layout() -> void:
	var k := _k()
	var lit: Array[int] = Roulette.covers(hover_key) if phase != "spinning" and hover_key != "" else ([] as Array[int])
	var won := table.result if phase == "result" or (phase == "spinning" and _finished) else -1
	for n in 37:
		var c := RouletteLayout.cell(n)
		var r := Rect2(_from_layout(c.position), c.size * k)
		draw_rect(r, _cell_colour(n))
		if n in lit:
			draw_rect(r, Color(GOLD, 0.35))
		if n == won:
			draw_rect(r, Color(GOLD, 0.55))
		draw_rect(r, LINE, false, maxf(1.0, _s(1.2)))
		_text(r.get_center() + Vector2(0, _s(6)), str(n), 17, CREAM)
	for key in ["column:1", "column:2", "column:3", "dozen:1", "dozen:2", "dozen:3", "low", "even", "red", "black", "odd", "high"]:
		var c2 := RouletteLayout.outside_cell(key)
		var r2 := Rect2(_from_layout(c2.position), c2.size * k)
		if key == "red":
			draw_rect(r2.grow(-_s(4)), Color(RED, 0.9))
		elif key == "black":
			draw_rect(r2.grow(-_s(4)), Color(BLACK, 0.9))
		if key == hover_key and phase != "spinning":
			draw_rect(r2, Color(GOLD, 0.25))
		if won > 0 and Roulette.wins(key, won):
			draw_rect(r2, Color(GOLD, 0.3))
		draw_rect(r2, LINE, false, maxf(1.0, _s(1.2)))
		var label: String = {"column:1": "2 to 1", "column:2": "2 to 1", "column:3": "2 to 1", "dozen:1": "1st 12",
			"dozen:2": "2nd 12", "dozen:3": "3rd 12", "low": "1-18", "even": "EVEN", "red": "", "black": "", "odd": "ODD",
			"high": "19-36"}[key]
		if label != "":
			_text(r2.get_center() + Vector2(0, _s(5)), label, 14, CREAM)
	if won >= 0:
		var dp := _from_layout(RouletteLayout.cell(won).get_center())
		var d := _s(26)
		draw_texture_rect(_dolly, Rect2(dp - Vector2(d, d) * 0.5 + Vector2(_s(10), -_s(10)), Vector2(d, d)), false)


func _draw_chip(at: Vector2, cents: int, radius: float, faded: bool = false) -> void:
	# a stack: the biggest chips first, at most four shown
	var left := cents
	var stack: Array[int] = []
	var chips: Array[int] = table.rules.chips.duplicate()
	chips.reverse()
	for c in chips:
		while left >= c and stack.size() < 4:
			stack.append(c)
			left -= c
	if stack.is_empty():
		stack.append(chips.back())
	for i in stack.size():
		var p := at - Vector2(0, _s(3.0) * i)
		var col: Color = CHIP_COLOURS.get(stack[stack.size() - 1 - i], Color.WHITE)
		if faded:
			col = Color(col, 0.4)
		draw_texture_rect(_chip, Rect2(p - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, col)


func _draw_bets() -> void:
	var won: Array[String] = table.winning_bets() if phase == "result" else ([] as Array[String])
	for key in table.bets:
		var at := _from_layout(RouletteLayout.anchor(key))
		var lost: bool = phase == "result" and not key in won
		if key in won:
			draw_circle(at, _s(16), Color(GOLD, 0.45))
		_draw_chip(at, int(table.bets[key]), _s(11), lost)
		if int(table.bets[key]) > table.rules.chips[0] or key in won:
			_text(at + Vector2(0, _s(22)), PokerView.money_text(int(table.bets[key])), 11, GOLD if key in won else CREAM)


func _draw_history() -> void:
	var o := _from_layout(Vector2.ZERO) + Vector2(0, -_s(22))
	_text(o + Vector2(0, _s(4)), "Last numbers", 14, CREAM, HORIZONTAL_ALIGNMENT_LEFT)
	for i in table.history.size():
		var n: int = table.history[i]
		var p := o + Vector2(_s(118) + i * _s(30), 0)
		draw_circle(p, _s(12), _cell_colour(n))
		draw_arc(p, _s(12), 0, TAU, 20, GOLD if i == 0 else LINE, _s(1.4 if i == 0 else 1.0))
		_text(p + Vector2(0, _s(5)), str(n), 12, CREAM)


func _draw_tray() -> void:
	var y := _from_layout(Vector2(0, RouletteLayout.SIZE.y)).y + _s(44)
	var x0 := _from_layout(Vector2.ZERO).x + _s(30)
	for i in table.rules.chips.size():
		var c: int = table.rules.chips[i]
		var p := Vector2(x0 + i * _s(64), y - (_s(6) if i == chip_index else 0.0))
		if i == chip_index:
			draw_circle(p, _s(25), Color(GOLD, 0.5))
		draw_texture_rect(_chip, Rect2(p - Vector2(_s(20), _s(20)), Vector2(_s(40), _s(40))), false, CHIP_COLOURS.get(c, Color.WHITE))
		_text(p + Vector2(0, _s(38)), "%d  %s" % [i + 1, _chip_words(c)], 13, GOLD if i == chip_index else DIM)
		_buttons.append({"rect": Rect2(p - Vector2(_s(24), _s(24)), Vector2(_s(48), _s(48))), "id": "chip%d" % i})
	var bx := x0 + _s(270)
	var items := [["spin", "Space   Spin"], ["repeat", "R   Same again"], ["clear", "Backspace   Clear"]]
	for i in items.size():
		var r := Rect2(Vector2(bx + i * _s(128), y - _s(18)), Vector2(_s(120), _s(32)))
		var on := phase != "spinning"
		_panel(r, Color(GOLD if items[i][0] == "spin" and on else COPPER, 0.7 if on else 0.25), 1.0)
		_text(r.get_center() + Vector2(0, _s(6)), items[i][1], 13, CREAM if on else DIM)
		_buttons.append({"rect": r, "id": items[i][0]})


static func _chip_words(c: int) -> String:
	return "%d¢" % c if c < 100 else "$%d" % (c / 100)


func _draw_status() -> void:
	var wc := centre + WHEEL_AT * ui_scale
	var y := wc.y + _s(BOWL_RADIUS) + _s(34)
	_text(Vector2(wc.x, y), "In your pocket %s      On the table %s" % [PokerView.money_text(money),
		PokerView.money_text(table.total_staked() if phase != "result" else 0)], 15, CREAM)
	var top := centre.y - AssetCatalog.display_size("ui/roulette_felt").y * 0.5 * ui_scale
	_text(Vector2(centre.x, top + _s(52)), "The wheel  -  single zero.   A number pays 35 to 1, a split 17, a street 11, a corner 8, a line 5, dozens and columns 2, the rest even money.", 13, CREAM)
	var line := message
	if hover_key != "" and phase != "spinning":
		line = "%s  -  pays %d to 1%s" % [Roulette.words(hover_key), Roulette.pays(hover_key),
			"  (on it: %s)" % PokerView.money_text(int(table.bets[hover_key])) if table.bets.has(hover_key) and phase == "betting" else ""]
	var r := Rect2(Vector2(centre.x - _s(420), size.y - _s(108)), Vector2(_s(840), _s(36)))
	_panel(r, Color(GOLD if phase == "result" else COPPER, 0.6), 1.0)
	_text(r.get_center() + Vector2(0, _s(6)), line, 16, GOLD if phase == "result" and hover_key == "" else CREAM)
	_text(Vector2(centre.x, size.y - _s(20)),
		"1-4 / wheel  Chip     Click  Bet     Right-click  Take one back     Backspace  Clear     R  Same again     Space  Spin     Esc  Leave", 13, DIM)
