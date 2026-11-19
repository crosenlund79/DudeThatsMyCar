class_name SlotView
extends Control
## M011: one of the gaming room's nickel machines on screen, over the dimmed
## room - its cast front, the three reels behind the windows, the lever at
## its side, the paytable printed on its plate from the machine's own rules,
## the payout cup. Space (or a click on the lever) pulls: the lever comes
## down, the reels jerk into motion and stop one after the other with a clunk
## on the stops the machine drew; a win lights its line on the plate and the
## coins drop into the cup. Esc or E steps away (a pull under way is paid at
## once). The money and the draw are SlotMachine's, moved by the game.

signal pull_requested
## The reels have stopped: time to pay.
signal reels_stopped
signal leave_requested
## A sound for the game to play: "lever", "reels" (they start running), "stop", "stop_last"
## (the last reel: the running stops), "coin" (each coin into the cup), "win", "lose".
signal sound(kind: String)

const CREAM := Color("f1e4c6")
const DIM := Color("f1e4c6", 0.55)
const COPPER := Color("d8a060")
const GOLD := Color("ffd86a")
const PLATE := Color(0.07, 0.05, 0.04, 0.88)
const INK := Color("2a1e14")
const RED_INK := Color("a3201e")
const PAPER := Color("efe6cf")
## In the front's own px (440 x 600, its middle at the screen's): the reel windows and the pay line.
const FRONT := Vector2(440, 600)
const WINDOWS := [Rect2(75, 150, 90, 120), Rect2(175, 150, 90, 120), Rect2(275, 150, 90, 120)]
const PAY_Y := 210.0
const PLATE_RECT := Rect2(60, 304, 320, 166)
const CUP := Vector2(220, 555)
const LEVER_PIVOT := Vector2(452, 300)
## Height of one stop on a reel (front px).
const STOP_H := 78.0

var machine: SlotMachine
var title := ""
var money := 0
var phase := "closed"  # closed / ready / spinning / stopped / paid
var message := ""
var centre := Vector2(640, 350)
var ui_scale := 1.0
var reels: SlotReels = null
var t := 0.0
var _positions: Array[float] = [0.0, 0.0, 0.0]
var _stopped := [true, true, true]
var _paid_line := -1
var _coins := 0
var _coin_t := 0.0
var _fronts := {}
var _symbols := {}
var _lever: Texture2D
var _coin: Texture2D
var _font: Font
var _buttons: Array = []
var _space_down := false
var _running_said := false


func setup(resolver: AssetResolver, font: Font) -> void:
	name = "SlotView"
	_font = font
	for k in ["owl", "bell", "star"]:
		_fronts[k] = resolver.get_texture("ui/slot_front_" + k)
	for s in SlotMachine.SYMBOLS:
		_symbols[s] = resolver.get_texture("ui/slot_" + s)
	_lever = resolver.get_texture("ui/slot_lever")
	_coin = resolver.get_texture("ui/slot_coin")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_PAUSABLE
	visible = false


func layout_for(screen: Vector2) -> void:
	size = screen
	ui_scale = minf(screen.x / 1280.0, screen.y / 720.0) * 0.95
	centre = Vector2(screen.x * 0.5 - 40.0 * ui_scale, screen.y * 0.5 - 4.0 * ui_scale)
	queue_redraw()


func is_open() -> bool:
	return phase != "closed"


func open(p_machine: SlotMachine, p_money: int) -> void:
	machine = p_machine
	title = machine.rules.title
	money = p_money
	phase = "ready"
	message = "%s  -  %s a pull." % [title, _coin_words(machine.rules.coin)]
	for r in 3:
		_positions[r] = float(machine.stops[r])
	_stopped = [true, true, true]
	reels = null
	_paid_line = -1
	_coins = 0
	_space_down = false
	visible = true
	queue_redraw()


func close() -> void:
	phase = "closed"
	visible = false
	reels = null


func set_money(cents: int) -> void:
	money = cents
	queue_redraw()


func say(text: String) -> void:
	message = text
	queue_redraw()


static func _coin_words(c: int) -> String:
	return "a nickel" if c == 5 else ("a dime" if c == 10 else Rackets.dollars(c))


## The lever is down: the reels run and stop on the machine's drawn stops.
func start_reels() -> void:
	var from: Array[float] = [_positions[0], _positions[1], _positions[2]]
	reels = SlotReels.new(from, machine.stops, machine.rules.stop_times,
		[machine.rules.strips[0].size(), machine.rules.strips[1].size(), machine.rules.strips[2].size()])
	t = 0.0
	_running_said = false
	_stopped = [false, false, false]
	_paid_line = -1
	_coins = 0
	phase = "spinning"
	message = "Round they go..."
	sound.emit("lever")
	queue_redraw()


## The win is paid (cents): its line lit on the plate, the coins into the cup.
func show_paid(cents: int) -> void:
	phase = "paid"
	_paid_line = SlotMachine.pay_line(machine.rules, machine.line())
	var words := " - ".join(machine.line().map(func(s: String) -> String: return SlotMachine.WORDS[s]))
	if cents > 0:
		_coins = mini(cents / machine.rules.coin, 24)
		_coin_t = 0.0
		message = "%s.   It pays %s." % [words, PokerView.money_text(cents)]
		sound.emit("win")
	else:
		message = "%s.   Nothing." % words
		sound.emit("lose")
	queue_redraw()


func _process(delta: float) -> void:
	if phase == "closed":
		return
	if reels != null and phase == "spinning":
		t += delta
		if not _running_said and t >= reels.begin:
			_running_said = true
			sound.emit("reels")
		for r in 3:
			_positions[r] = reels.position(r, t)
			if not _stopped[r] and reels.stopped(r, t):
				_stopped[r] = true
				sound.emit("stop_last" if r == 2 else "stop")
		if reels.done(t):
			for r in 3:
				_positions[r] = float(reels.on_line(r, t))
			phase = "stopped"  # until the game has paid (show_paid)
			reels_stopped.emit()
		queue_redraw()
	elif phase == "paid" and _coins > 0:
		var before := int(_coin_t / 0.09)
		_coin_t += delta
		if int(_coin_t / 0.09) > before and int(_coin_t / 0.09) <= _coins:
			sound.emit("coin")
		if _coin_t < _coins * 0.09 + 0.8:
			queue_redraw()


func handle_key(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var k: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if k == KEY_SPACE or k == KEY_ENTER or k == KEY_KP_ENTER:
		# one pull a press: holding the key does not keep pulling
		if not event.pressed:
			_space_down = false
		elif not event.echo and not _space_down:
			_space_down = true
			pull_requested.emit()
		return true
	if event.pressed and not event.echo and (k == KEY_ESCAPE or k == KEY_E):
		leave_requested.emit()
	return true


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for b in _buttons:
			if (b.rect as Rect2).has_point(event.position):
				if b.id == "pull":
					pull_requested.emit()
				elif b.id == "leave":
					leave_requested.emit()
				accept_event()
				return


# ------------------------------------------------------------------ drawing

func _s(v: float) -> float:
	return v * ui_scale


## A point of the front (its own px) on screen.
func _f(p: Vector2) -> Vector2:
	return centre + (p - FRONT * 0.5) * ui_scale


func _text(pos: Vector2, s: String, size: int, colour: Color, align := HORIZONTAL_ALIGNMENT_CENTER, outline := true) -> void:
	var fs := int(round(size * ui_scale))
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x := pos.x - (w * 0.5 if align == HORIZONTAL_ALIGNMENT_CENTER else (w if align == HORIZONTAL_ALIGNMENT_RIGHT else 0.0))
	if outline:
		draw_string_outline(_font, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(4 * ui_scale), Color(0, 0, 0, 0.7))
	draw_string(_font, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)


func _panel(r: Rect2, border: Color = Color(COPPER, 0.6), width := 2.0) -> void:
	draw_rect(r, PLATE)
	draw_rect(r, border, false, width * ui_scale)


func _kind() -> String:
	return title.to_lower().replace("the ", "")


func _draw() -> void:
	_buttons.clear()
	if machine == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.015, 0.02, 0.62))
	_draw_reels()
	var front: Texture2D = _fronts.get(_kind(), _fronts.owl)
	draw_texture_rect(front, Rect2(_f(Vector2.ZERO), FRONT * ui_scale), false)
	_draw_paytable()
	_draw_lever()
	_draw_coins()
	# what he has, what happened, the keys
	var r := Rect2(Vector2(size.x * 0.5 - _s(420), size.y - _s(84)), Vector2(_s(840), _s(34)))
	_panel(r, Color(GOLD if phase == "paid" and _coins > 0 else COPPER, 0.6), 1.0)
	_text(r.get_center() + Vector2(0, _s(6)), message, 16, GOLD if phase == "paid" and _coins > 0 else CREAM)
	_text(Vector2(size.x * 0.5, size.y - _s(16)), "Space  Pull the lever      Esc  Step away      In your pocket %s" % PokerView.money_text(money), 14, DIM)
	var lb := Rect2(Vector2(size.x - _s(250), size.y - _s(140)), Vector2(_s(230), _s(30)))
	_panel(lb, Color(COPPER, 0.4), 1.0)
	_text(lb.get_center() + Vector2(0, _s(6)), "Esc   Step away", 15, DIM)
	_buttons.append({"rect": lb, "id": "leave"})


func _draw_reels() -> void:
	for r in 3:
		var win: Rect2 = WINDOWS[r]
		var box := Rect2(_f(win.position), win.size * ui_scale)
		draw_rect(box, PAPER)
		var p := _positions[r]
		var base := floori(p)
		var strip: PackedStringArray = machine.rules.strips[r]
		var running: bool = not _stopped[r]
		for k in range(base - 2, base + 3):
			var y := PAY_Y + (p - k) * STOP_H  # the next stop comes down from above
			if y < win.position.y - STOP_H * 0.5 or y > win.end.y + STOP_H * 0.5:
				continue
			var tex: Texture2D = _symbols[strip[posmod(k, strip.size())]]
			var sz := Vector2(68, 68) * ui_scale
			var at := _f(Vector2(win.get_center().x, y))
			draw_texture_rect(tex, Rect2(at - sz * 0.5, sz), false, Color(1, 1, 1, 0.55 if running else 1.0))
			if running:  # a blur trail as it runs
				draw_texture_rect(tex, Rect2(at - sz * 0.5 - Vector2(0, _s(14)), sz), false, Color(1, 1, 1, 0.25))
		# the reel's curve: darker at the top and bottom of the window
		for i in 6:
			var a := 0.32 * (1.0 - i / 6.0)
			var hh := box.size.y * 0.06
			draw_rect(Rect2(box.position + Vector2(0, i * hh), Vector2(box.size.x, hh)), Color(0, 0, 0, a))
			draw_rect(Rect2(Vector2(box.position.x, box.end.y - (i + 1) * hh), Vector2(box.size.x, hh)), Color(0, 0, 0, a))
	if phase == "paid" and _paid_line >= 0:
		draw_line(_f(Vector2(70, PAY_Y)), _f(Vector2(370, PAY_Y)), Color(GOLD, 0.8), _s(3))


func _draw_paytable() -> void:
	var pays: Array = machine.rules.pays
	var half := ceili(pays.size() / 2.0)
	var col_w := PLATE_RECT.size.x * 0.5
	var row_h := minf(25.0, (PLATE_RECT.size.y - 20.0) / half)
	for k in pays.size():
		var col := 0 if k < half else 1
		var row := k if k < half else k - half
		var o := PLATE_RECT.position + Vector2(10 + col * col_w, 14 + row * row_h)
		if k == _paid_line and phase == "paid":
			draw_rect(Rect2(_f(o - Vector2(4, 2)), Vector2(col_w - 12, row_h) * ui_scale), Color(GOLD, 0.55))
		var line: Array = pays[k].line
		for i in 3:
			var at := _f(o + Vector2(10 + i * 24, row_h * 0.45))
			var sym := String(line[i])
			if sym == "*":
				_text(at + Vector2(0, _s(5)), "any", 9, INK, HORIZONTAL_ALIGNMENT_CENTER, false)
			else:
				var sz := Vector2(21, 21) * ui_scale
				draw_texture_rect(_symbols[sym], Rect2(at - sz * 0.5, sz), false)
		_text(_f(o + Vector2(col_w - 22, row_h * 0.45 + 5)), "%d" % int(pays[k].coins), 14, RED_INK if int(pays[k].coins) >= 50 else INK,
			HORIZONTAL_ALIGNMENT_RIGHT, false)
	_text(_f(PLATE_RECT.position + Vector2(PLATE_RECT.size.x * 0.5, PLATE_RECT.size.y - 2)), "coins paid for one in", 9, INK,
		HORIZONTAL_ALIGNMENT_CENTER, false)


## The lever: upright at rest; pulled, it swings down towards you and springs back.
func _lever_drop() -> float:
	if phase != "spinning" or reels == null:
		return 0.0
	var x := t / reels.begin
	if x < 1.0:
		return smoothstep(0.0, 1.0, x)
	return clampf(1.0 - (t - reels.begin) / 0.35, 0.0, 1.0)


func _draw_lever() -> void:
	var pivot := _f(LEVER_PIVOT)
	var k := 1.0 - 1.75 * _lever_drop()  # the arm foreshortens and comes down past the pivot
	var sz := AssetCatalog.display_size("ui/slot_lever") * ui_scale
	draw_set_transform(pivot, 0.0, Vector2(1.0, k))
	draw_texture_rect(_lever, Rect2(Vector2(-sz.x * 0.5, -sz.y + sz.x * 0.4), sz), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(pivot, _s(12), Color("8a8a90"))
	draw_circle(pivot, _s(7), Color("c8c8ce"))
	_buttons.append({"rect": Rect2(pivot - Vector2(_s(30), sz.y), Vector2(_s(60), sz.y + _s(20))), "id": "pull"})


func _draw_coins() -> void:
	if phase != "paid" or _coins <= 0:
		return
	var cup := _f(CUP)
	var sz := Vector2(22, 22) * ui_scale
	for i in _coins:
		var age := _coin_t - i * 0.09
		if age < 0.0:
			continue
		var fall := clampf(age / 0.3, 0.0, 1.0)
		var rest := cup + Vector2(_s(-38 + (i * 37) % 76), _s(4 + (i % 3) * 4))
		var at := rest - Vector2(0, _s(70) * (1.0 - fall * fall))
		draw_texture_rect(_coin, Rect2(at - sz * 0.5, sz), false)
