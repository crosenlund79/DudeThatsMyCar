class_name RouletteView
extends Control
## M011: the gaming room's wheel on screen, over the dimmed room: the wheel in
## its bowl at the left, the single-zero layout on the baize at the right, the
## chip tray, the last numbers, what Danny has in his pocket and on the table.
## M013: Leo runs the wheel (RouletteTable): it turns all the time, round after
## round, and the view shows the round as it stands - bets open (a brass ring
## round the bowl runs down to the call, and waits while Danny is still putting
## chips down), last bets, no more bets, the ball dropping, the number, the
## payout - whether Danny bets or only watches. Space no longer spins.
##
## 1-4 (or a click on the tray, or the mouse wheel) picks a chip - 5¢, 10¢,
## 25¢, $1; a click on the layout puts it on the bet under the pointer (a
## number's middle, the line between two numbers, a crossing, the edge under a
## column of three or between two, the boxes outside); a right click takes one
## back; Backspace takes them all back; R puts last round's bets down again;
## Esc or E walks away (chips not yet called come back; a number already
## drawn is settled at once). The covered numbers light up under the pointer,
## with what the bet pays.
##
## The money and the rules are Roulette's and RouletteTable's, moved by the
## game (main) on this view's requests and the table's events; the number is
## drawn at the call, and the wheel here only shows it.

signal bet_requested(key: String, chip: int)
signal take_back_requested(key: String, chip: int)
signal clear_requested
signal repeat_requested
signal leave_requested
## M015: Danny asks Leo for the next pace of the betting timer.
signal pace_requested

const CREAM := Color("f1e4c6")
const DIM := Color("f1e4c6", 0.55)
const COPPER := Color("d8a060")
const GOLD := Color("ffd86a")
const PLATE := Color(0.07, 0.05, 0.04, 0.88)
const RED := Color("9a2322")
const BLACK := Color("1c1a1e")
const GREEN := Color("2f7a3a")
const LINE := Color("e8dcc0", 0.85)
## M015: the chips' spacing in the tray (five chips before the buttons).
const CHIP_STEP := 56.0
const CHIP_COLOURS := {5: Color("e8e0cf"), 10: Color("c0392b"), 25: Color("2f5fa8"), 100: Color("2f7a46"), 500: Color("5b2a6e")}
## Base screen px (at 1280 x 720), from the screen's middle.
const WHEEL_AT := Vector2(-345, 10)
const BOWL_RADIUS := 165.0
const LAYOUT_AT := Vector2(-150, -150)
const LAYOUT_SCALE := 1.15

## Danny's chips (his Roulette) and the round they are in (Leo's table).
var table: Roulette
var wheel: RouletteTable
var money := 0
var chip_index := 0
var phase := "closed"  # closed / open (the view; the round's own phase is wheel.phase)
var message := ""
var result_line := ""
var hover_key := ""
var centre := Vector2(640, 340)
var ui_scale := 1.0
var _shown_phase := -1
var _shown_second := -1
var _buttons: Array = []  # {rect, id}
var _font: Font
var _felt: Texture2D
var _bowl: Texture2D
var _rotor: Texture2D
var _ball: Texture2D
var _chip: Texture2D
var _dolly: Texture2D
## The wheel on a layer of its own: it is drawn again each frame (it always
## turns), the whole table (its layout, chips and text) only when it changes.
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


func open(p_wheel: RouletteTable, p_money: int) -> void:
	wheel = p_wheel
	table = p_wheel.danny
	money = p_money
	phase = "open"
	message = _call_for(wheel.phase)
	result_line = ""
	hover_key = ""
	_shown_phase = wheel.phase
	visible = true
	refresh()


func close() -> void:
	phase = "closed"
	visible = false


## What Leo is saying at this point of a round.
static func _call_for(p: int) -> String:
	match p:
		RouletteTable.Phase.OPEN:
			return "\"Place your bets, ladies and gentlemen.\""
		RouletteTable.Phase.BALL:
			return "The ball goes round. Bets are still open."
		RouletteTable.Phase.DROP:
			return "\"No more bets.\""
		RouletteTable.Phase.CLOSED:
			return "The cover's over the wheel for tonight."
	return ""


## Whether chips can go down now (the round's bets are open).
func betting() -> bool:
	return phase == "open" and wheel != null and wheel.betting_open()


func set_money(cents: int) -> void:
	money = cents
	queue_redraw()


## A word from the croupier (or why something cannot be done).
func say(text: String) -> void:
	message = text
	queue_redraw()


func chip() -> int:
	return table.rules.chips[clampi(chip_index, 0, table.rules.chips.size() - 1)]


## The ball has come to rest: what came up and what Danny's chips paid
## (`played`: whether he had any on it); M013.3: the regulars' biggest win
## told too (`others`: [{id, staked, paid}]).
func show_result(paid: int, played: bool, others: Array = []) -> void:
	var n := wheel.number
	var words := "%d  %s" % [n, "green" if n == 0 else Roulette.colour(n)]
	if n != 0:
		words += ", %s, %s" % ["odd" if n % 2 else "even", "low" if n <= 18 else "high"]
	result_line = words
	var net := paid - table.staked
	var best := {}
	for o in others:
		if int(o.paid) > int(o.staked) and (best.is_empty() or int(o.paid) - int(o.staked) > int(best.paid) - int(best.staked)):
			best = o
	if not played:
		message = "\"%s.\"" % words
		if not best.is_empty():
			message += "   %s collects %s." % [Patrons.name_of(best.id), PokerView.money_text(int(best.paid))]
	elif paid > 0:
		message = "%s.   You collect %s%s." % [words, PokerView.money_text(paid),
			"  (%s ahead)" % PokerView.money_text(net) if net > 0 else ("  (%s down)" % PokerView.money_text(-net) if net < 0 else "")]
	else:
		message = "%s.   The house takes %s." % [words, PokerView.money_text(table.staked)]
	refresh()


func _process(_delta: float) -> void:
	if phase == "closed" or wheel == null:
		return
	if wheel.phase != _shown_phase:  # the round moved on: the whole table drawn again once
		_shown_phase = wheel.phase
		if wheel.phase in [RouletteTable.Phase.OPEN, RouletteTable.Phase.DROP, RouletteTable.Phase.CLOSED]:
			message = _call_for(wheel.phase)
			if wheel.phase == RouletteTable.Phase.OPEN:
				result_line = ""
		queue_redraw()
	var sec := ceili(wheel.seconds_to_close())
	if sec != _shown_second:  # the plaque's count, once a second
		_shown_second = sec
		queue_redraw()
	_wheel_layer.queue_redraw()  # the wheel always turns


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
	elif k >= KEY_1 and k < KEY_1 + table.rules.chips.size():
		pick_chip(k - KEY_1)
	elif k == KEY_T:
		pace_requested.emit()
	elif k == KEY_SPACE or k == KEY_ENTER or k == KEY_KP_ENTER:
		say("Leo calls the bets, not you. Watch the ring round the wheel.")
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
		"clear":
			clear_requested.emit()
		"repeat":
			repeat_requested.emit()
		"pace":
			pace_requested.emit()
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
	var m := wheel.motion
	return wc + Vector2.from_angle(m.ball_angle) * m.ball_r * _s(BOWL_RADIUS)


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
	# M015: the betting timer's pace (Leo changes it from his next round), beside the message line
	var pr := Rect2(Vector2(size.x - _s(250), size.y - _s(108)), Vector2(_s(230), _s(36)))
	_panel(pr, Color(COPPER, 0.7), 1.0)
	var pace_words := "T   Pace: %s%s" % [RouletteRules.pace_name(wheel.pace_asked), "  (next round)" if wheel.pace_asked != wheel.pace else ""]
	_text(pr.get_center() + Vector2(0, _s(6)), pace_words, 14, CREAM)
	_buttons.append({"rect": pr, "id": "pace"})


func _draw_wheel() -> void:
	if table == null or wheel == null or phase == "closed":
		return
	var c := _wheel_layer
	var wc := centre + WHEEL_AT * ui_scale
	var rw := _s(BOWL_RADIUS)
	_draw_call_ring(c, wc, rw)
	c.draw_texture_rect(_bowl, Rect2(wc - Vector2(rw, rw), Vector2(rw, rw) * 2.0), false)
	var rr := rw * RouletteMotion.ROTOR
	c.draw_set_transform(wc, wheel.motion.rotor, Vector2.ONE)
	c.draw_texture_rect(_rotor, Rect2(-rr, -rr, rr * 2.0, rr * 2.0), false)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var b := _s(13.0)
	var bp := ball_position()
	c.draw_texture_rect(_ball, Rect2(bp - Vector2(b, b) * 0.5, Vector2(b, b)), false)


## M013: a brass ring round the bowl, running down to the call (it holds
## while Danny is still putting chips down); red for the last bets, gone once
## the call has come.
func _draw_call_ring(c: Control, wc: Vector2, rw: float) -> void:
	if not wheel.betting_open():
		return
	var whole := wheel.close_time()
	var left := wheel.seconds_to_close()
	var frac := clampf(left / maxf(whole, 0.1), 0.0, 1.0)
	var last := left <= wheel.rules.last_call_seconds
	var col := Color(RED.lightened(0.25), 0.95) if last else Color(GOLD, 0.85)
	c.draw_arc(wc, rw + _s(9), 0, TAU, 72, Color(0, 0, 0, 0.45), _s(7))
	c.draw_arc(wc, rw + _s(9), -PI / 2.0, -PI / 2.0 + TAU * frac, 72, col, _s(4.5))


func _cell_colour(n: int) -> Color:
	return GREEN if n == 0 else (RED if n in Roulette.REDS else BLACK)


func _draw_layout() -> void:
	var k := _k()
	var lit: Array[int] = Roulette.covers(hover_key) if betting() and hover_key != "" else ([] as Array[int])
	var won := wheel.number if wheel.phase == RouletteTable.Phase.RESULT else -1
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
		if key == hover_key and betting():
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


## M013.3: the regulars' colour chips (each their own colour), set a little
## to the left of where Danny's own would sit, under his.
func _draw_others() -> void:
	if wheel.patrons == null:
		return
	var result := wheel.phase == RouletteTable.Phase.RESULT
	var ids: Array = Patrons.ROSTER.keys()
	for id in wheel.patrons.bets:
		var k := ids.find(id)
		for key in wheel.patrons.bets[id]:
			var at := _from_layout(RouletteLayout.anchor(key)) + Vector2(-_s(8) - _s(5) * k, -_s(5) + _s(3) * k)
			var col := Patrons.colour_of(id)
			var won := result and Roulette.wins(key, wheel.number)
			if won:
				draw_circle(at, _s(12), Color(GOLD, 0.4))
			if result and not won:
				col = Color(col, 0.35)
			draw_texture_rect(_chip, Rect2(at - Vector2(_s(8), _s(8)), Vector2(_s(16), _s(16))), false, col)
			draw_arc(at, _s(7.5), 0, TAU, 16, Color(1, 1, 1, 0.5 if not result or won else 0.2), maxf(1.0, _s(1.0)))


func _draw_bets() -> void:
	_draw_others()
	var settled := wheel.phase == RouletteTable.Phase.RESULT and table.phase == Roulette.Phase.SETTLED
	var won: Array[String] = table.winning_bets() if settled else ([] as Array[String])
	for key in table.bets:
		var at := _from_layout(RouletteLayout.anchor(key))
		var lost: bool = settled and not key in won
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
		var p := Vector2(x0 + i * _s(CHIP_STEP), y - (_s(6) if i == chip_index else 0.0))
		if i == chip_index:
			draw_circle(p, _s(25), Color(GOLD, 0.5))
		draw_texture_rect(_chip, Rect2(p - Vector2(_s(20), _s(20)), Vector2(_s(40), _s(40))), false, CHIP_COLOURS.get(c, Color.WHITE))
		_text(p + Vector2(0, _s(38)), "%d  %s" % [i + 1, _chip_words(c)], 13, GOLD if i == chip_index else DIM)
		_buttons.append({"rect": Rect2(p - Vector2(_s(24), _s(24)), Vector2(_s(48), _s(48))), "id": "chip%d" % i})
	var bx := x0 + _s(270)
	var items := [["repeat", "R   Same again"], ["clear", "Backspace   Clear"]]
	var on := betting()
	for i in items.size():
		var r := Rect2(Vector2(bx + i * _s(128), y - _s(18)), Vector2(_s(120), _s(32)))
		_panel(r, Color(COPPER, 0.7 if on else 0.25), 1.0)
		_text(r.get_center() + Vector2(0, _s(6)), items[i][1], 13, CREAM if on else DIM)
		_buttons.append({"rect": r, "id": items[i][0]})
	# M015: the table's limits, plainly, under the chips and buttons
	_text(Vector2(_from_layout(Vector2(RouletteLayout.SIZE.x * 0.5, 0)).x, y + _s(58)), table.rules.limits_text(), 13, GOLD)
	# the round as it stands, beside them (Leo calls it, not Danny)
	var sr := Rect2(Vector2(bx + 2 * _s(128), y - _s(18)), Vector2(_s(136), _s(32)))
	var left := wheel.seconds_to_close()
	var last := on and left <= wheel.rules.last_call_seconds
	var state: String = {RouletteTable.Phase.OPEN: "Bets open  %d" % ceili(left), RouletteTable.Phase.BALL: "Bets open  %d" % ceili(left),
		RouletteTable.Phase.DROP: "No more bets", RouletteTable.Phase.RESULT: "Paying out",
		RouletteTable.Phase.CLOSED: "Closed"}[wheel.phase]
	if last:
		state = "Last bets!"
	_panel(sr, Color(RED.lightened(0.3) if last else (GOLD if on else COPPER), 0.75 if on else 0.35), 1.0)
	_text(sr.get_center() + Vector2(0, _s(6)), state, 14, GOLD if on else DIM)
	if on and wheel.changed_at >= 0.0 and wheel.close_time() > wheel.usual_close():
		_text(sr.get_center() + Vector2(0, _s(30)), "Leo waits on you", 12, DIM)


## M013.3: who is at the rail with Danny, each by their chips' colour.
func _draw_rail(wc: Vector2) -> void:
	if wheel.patrons == null or wheel.patrons.seated().is_empty():
		return
	# on the row of the last numbers, left of them (over the wheel's corner of the baize)
	var y := _from_layout(Vector2.ZERO).y - _s(18)
	var names: Array = wheel.patrons.seated()
	var fs := int(round(13 * ui_scale))
	var x := centre.x - AssetCatalog.display_size("ui/roulette_felt").x * 0.5 * ui_scale + _s(38)
	var label := "At the rail:"
	draw_string(_font, Vector2(x, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, DIM)
	x += _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + _s(10)
	for id in names:
		draw_circle(Vector2(x + _s(5), y - _s(4)), _s(5), Patrons.colour_of(id))
		var who := Patrons.name_of(id)
		draw_string(_font, Vector2(x + _s(14), y), who, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, CREAM)
		x += _s(24) + _font.get_string_size(who, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


static func _chip_words(c: int) -> String:
	return "%d¢" % c if c < 100 else "$%d" % (c / 100)


func _draw_status() -> void:
	var wc := centre + WHEEL_AT * ui_scale
	var y := wc.y + _s(BOWL_RADIUS) + _s(34)
	_draw_rail(wc)
	var on_table := table.total_staked() if table.phase != Roulette.Phase.SETTLED else 0
	_text(Vector2(wc.x, y), "In your pocket %s      On the table %s" % [PokerView.money_text(money),
		PokerView.money_text(on_table)], 15, CREAM)
	var top := centre.y - AssetCatalog.display_size("ui/roulette_felt").y * 0.5 * ui_scale
	_text(Vector2(centre.x, top + _s(52)), "The wheel  -  single zero.   A number pays 35 to 1, a split 17, a street 11, a corner 8, a line 5, dozens and columns 2, the rest even money.", 13, CREAM)
	var line := message
	if hover_key != "" and betting():
		line = "%s  -  pays %d to 1%s" % [Roulette.words(hover_key), Roulette.pays(hover_key),
			"  (on it: %s)" % PokerView.money_text(int(table.bets[hover_key])) if table.bets.has(hover_key) else ""]
	var result := wheel.phase == RouletteTable.Phase.RESULT
	var r := Rect2(Vector2(centre.x - _s(440), size.y - _s(108)), Vector2(_s(800), _s(36)))  # (the pace beside it, M015)
	_panel(r, Color(GOLD if result else COPPER, 0.6), 1.0)
	_text(r.get_center() + Vector2(0, _s(6)), line, 16, GOLD if result and hover_key == "" else CREAM)
	_text(Vector2(centre.x, size.y - _s(20)),
		"1-%d / wheel  Chip     Click  Bet     Right-click  Take one back     Backspace  Clear     R  Same again     T  Pace     Esc  Leave" % table.rules.chips.size(), 13, DIM)
