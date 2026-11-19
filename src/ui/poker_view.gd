class_name PokerView
extends Control
## M010: the back-room game on screen, over the dimmed room. First the buy-in
## (what Danny can afford, or "not tonight"); then the table: the baize in
## its rail, a plate for every player (name, his way of playing, his chips,
## what he just did), the dealer's button and the blinds, the hole cards
## (Danny's face up, the others' face down until a showdown), the bets in
## front of each player, the board and the pot with any side pots, the
## player whose turn it is lit in copper; under it Danny's choices:
## 1 Fold, 2 Check / Call, 3 Bet / Raise to (the mouse wheel or the arrow keys
## change how much), 4 All in. Esc or E gets up from the table (mid-hand he
## folds). Workshop (poker pacing): the game goes one beat at a time
## (PokerPacing) - each card player's action, each street of the board and the
## showdown's result stay on show, with a small "Space  Continue" prompt,
## until Danny presses Space (one press, one beat; holding it does nothing
## more); the betting keys wait meanwhile. Runs the game's pace; the rules and
## the money are PokerNight's and Holdem's.

signal bought_in(amount: int)
signal leave_requested
## A beat came on show (PokerPacing's {kind, ...}; an action names its player:
## `player` is the seat's id, `action` what he did) - the hook for anything
## that reacts to a particular player's play (e.g. recorded taunts later).
signal beat_shown(beat: Dictionary)
## A sound for the game to play: "chips", "cards"; M011: "shuffle", "reveal", "pot".
signal sound(kind: String)

const CREAM := Color("f1e4c6")
const DIM := Color("f1e4c6", 0.55)
const COPPER := Color("d8a060")
const GOLD := Color("ffd86a")
const RED := Color("c4423a")
const PLATE := Color(0.07, 0.05, 0.04, 0.88)
const INK := Color("1c1a1e")
const RED_INK := Color("a3201e")
const CHIP_COLOURS := [Color("e8e0cf"), Color("c0392b"), Color("2f5fa8"), Color("2f7a46"), Color("1c1a1e")]
## Slots round the table, in base screen px from its middle: Danny at the bottom, then clockwise.
const SLOTS := [Vector2(0, 228), Vector2(-468, 10), Vector2(0, -214), Vector2(468, 10)]
## Where each slot's bet lies on the baize (same base px).
const BETS := [Vector2(170, 140), Vector2(-290, 84), Vector2(-170, -150), Vector2(290, 84)]
## The pace (seconds): a card player thinking before he acts.
var think := Vector2(0.4, 0.8)
## What is on show and what waits for Space.
var pacing := PokerPacing.new()

var night: PokerNight
var phase := "closed"  # closed / buyin / play / over
var money := 0
var choices: Array[int] = []
var raise_to := 0
var banner := ""
var over_text := ""
## The last thing each seat did this hand, for its plate.
var said := {}
var log_lines: Array[String] = []
var centre := Vector2(640, 330)
var ui_scale := 1.0
var _wait := 0.0
var _buttons: Array = []  # {rect, id}
var _font: Font
var _felt: Texture2D
var _face: Texture2D
var _back: Texture2D
var _suits: Array[Texture2D] = []
var _chip: Texture2D
var _dealer: Texture2D
var _rng := RandomNumberGenerator.new()


func setup(resolver: AssetResolver, font: Font) -> void:
	name = "PokerView"
	_font = font
	_felt = resolver.get_texture("ui/poker_felt")
	_face = resolver.get_texture("ui/card_face")
	_back = resolver.get_texture("ui/card_back")
	for s in ["spades", "hearts", "diamonds", "clubs"]:
		_suits.append(resolver.get_texture("ui/suit_" + s))
	_chip = resolver.get_texture("ui/poker_chip")
	_dealer = resolver.get_texture("ui/dealer_button")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_PAUSABLE
	visible = false


func layout_for(screen: Vector2) -> void:
	size = screen
	ui_scale = minf(screen.x / 1280.0, screen.y / 720.0)
	centre = Vector2(screen.x * 0.5, screen.y * 0.5 - 30.0 * ui_scale)
	queue_redraw()


func is_open() -> bool:
	return phase != "closed"


## The buy-in: what he can afford.
func open(p_night: PokerNight, p_money: int) -> void:
	night = p_night
	money = p_money
	choices = night.buy_in_choices(money)
	phase = "buyin"
	banner = ""
	over_text = night.cannot_sit(money)
	said = {}
	log_lines.clear()
	pacing.new_hand()
	visible = true
	queue_redraw()


## He has bought in: the game begins.
func begin_play() -> void:
	phase = "play"
	_wait = 0.4
	pacing.new_hand()
	_log("Danny sits in with %s." % money_text(night.danny_chips()))
	queue_redraw()


func close() -> void:
	phase = "closed"
	visible = false


static func money_text(cents: int) -> String:
	return "$%d.%02d" % [cents / 100, cents % 100]


func _log(line: String) -> void:
	log_lines.append(line)
	while log_lines.size() > 5:
		log_lines.remove_at(0)


# ------------------------------------------------------------------ pace

func _process(delta: float) -> void:
	if phase != "play" or night == null or not night.seated():
		return
	queue_redraw()
	if pacing.waiting():
		return  # one beat on show: nothing moves until Space
	var t := night.table
	if t.running():
		if night.ai_to_act():
			_wait -= delta
			if _wait <= 0.0:
				night.ai_turn()
				_show(pacing.read(t, night.danny))
				_wait = _rng.randf_range(think.x, think.y)
		elif t.to_act == night.danny and raise_to == 0:
			_fresh_raise()
	elif night.next_hand():
		pacing.new_hand()
		said = {}
		banner = ""
		raise_to = 0
		_wait = _rng.randf_range(think.x, think.y)
		sound.emit("shuffle")  # M011: the riffle before the deal
		_log("Hand %d: %s deals." % [night.hands, t.seats[t.button].name])
		_show(pacing.read(t, night.danny))  # a hand can be settled at once (all-in blinds)
	else:
		phase = "over"
		over_text = _why_over()


## A beat has come on show: the player's plate says what he did, the board
## turns its cards, the result is read out; the sounds; the hook.
func _show(beat: Dictionary) -> void:
	if beat.is_empty():
		return
	match String(beat.kind):
		"action":
			said[beat.seat] = beat.text
			_log("%s: %s" % [beat.name, String(beat.text).to_lower()])
			if beat.action != "fold" and beat.action != "check":
				sound.emit("chips")
		"deal":
			_log(beat.text)
			sound.emit("cards")
		"result":
			banner = beat.text
			_log(beat.text)
			if night != null and night.table != null and night.table.shown:
				sound.emit("reveal")  # M011: the hands turned over
			sound.emit("pot")  # M011: the pot pushed to the winner
	beat_shown.emit(beat)
	queue_redraw()


## Space (or a click on the prompt): the next beat, or play goes on.
func continue_step() -> void:
	_show(pacing.press_continue())


func _why_over() -> String:
	var t := night.table
	if t.seats[night.danny].out:
		return "You're cleaned out. The boys are sorry to see you go - not very."
	if night.closing:
		return "Four o'clock. The game breaks up: chairs back, coats on, the lamp turned down."
	return "Nobody left to play you - you've cleaned out the table."


## Danny's own action, as his plate shows it (it is not held for Space).
func _note_danny() -> void:
	var t := night.table
	for k in range(t.events.size() - 1, -1, -1):
		var e: Dictionary = t.events[k]
		if int(e.get("seat", -1)) == night.danny and String(e.what) in ["fold", "check", "call", "bet", "raise"]:
			var b := PokerPacing.action_beat(t, e)
			said[night.danny] = b.text
			_log("Danny: %s" % String(b.text).to_lower())
			if b.action != "fold" and b.action != "check":
				sound.emit("chips")
			return


func _fresh_raise() -> void:
	var l := night.table.legal(night.danny)
	raise_to = l.min_to if (l.bet or l.raise) else 0


# ------------------------------------------------------------------ Danny's choices

## 1 Fold, 2 Check / Call, 3 Bet / Raise (to raise_to), 4 All in.
func act(choice: int) -> bool:
	if phase != "play" or not night.seated() or night.table.to_act != night.danny or pacing.waiting():
		return false
	var l := night.table.legal(night.danny)
	var kind := ""
	var to := 0
	match choice:
		1:
			kind = "fold"
		2:
			kind = "check" if l.check else "call"
		3:
			if not (l.bet or l.raise):
				return false
			kind = "bet" if l.bet else "raise"
			to = clampi(raise_to, l.min_to, l.max_to)
		4:
			if l.all_in <= 0:
				return false
			kind = "all_in"
	if not night.danny_acts(kind, to):
		return false
	_note_danny()
	raise_to = 0
	_wait = _rng.randf_range(think.x, think.y)
	_show(pacing.read(night.table, night.danny))  # what follows his action (a street dealt, the result) waits for Space
	queue_redraw()
	return true


## The raise a step (a big blind) up or down.
func adjust(steps: int) -> void:
	if phase != "play" or not night.seated() or night.table.to_act != night.danny or pacing.waiting():
		return
	var l := night.table.legal(night.danny)
	if not (l.bet or l.raise):
		return
	raise_to = clampi(raise_to + steps * night.big_blind, l.min_to, l.max_to)
	queue_redraw()


func choose_buy_in(i: int) -> void:
	if phase != "buyin":
		return
	if i < 0 or i >= choices.size() or over_text != "":
		bought_in.emit(0)
		return
	bought_in.emit(choices[i])


## Keys from the game (it sends them here while the table is open). True: used.
func handle_key(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			adjust(1)
			return true
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			adjust(-1)
			return true
		return false
	if event is InputEventKey and (event.physical_keycode == KEY_SPACE or event.keycode == KEY_SPACE):
		# one press, one beat: a held Space (its auto-repeat, or a press before it is let go) moves nothing more
		if phase == "play":
			_show(pacing.space(event.pressed, event.echo))
		return true
	if not (event is InputEventKey and event.pressed and not event.echo):
		return false
	var k: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if k == KEY_ESCAPE or k == KEY_E:
		if phase == "buyin":
			bought_in.emit(0)
		else:
			leave_requested.emit()
		return true
	if k >= KEY_1 and k <= KEY_4:
		if phase == "buyin":
			choose_buy_in(k - KEY_1)
		elif phase == "play":
			act(k - KEY_1 + 1)
		return true
	if k == KEY_UP or k == KEY_EQUAL or k == KEY_KP_ADD:
		adjust(1)
		return true
	if k == KEY_DOWN or k == KEY_MINUS or k == KEY_KP_SUBTRACT:
		adjust(-1)
		return true
	return true  # nothing else gets through while at the table


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			for b in _buttons:
				if (b.rect as Rect2).has_point(event.position):
					_click(b.id)
					accept_event()
					return
		elif handle_key(event):
			accept_event()


func _click(id: String) -> void:
	match id:
		"leave":
			leave_requested.emit()
		"continue":
			continue_step()
		"buy0", "buy1", "buy2":
			choose_buy_in(int(id.substr(3)))
		"no":
			bought_in.emit(0)
		"up":
			adjust(1)
		"down":
			adjust(-1)
		_:
			if id.begins_with("act"):
				act(int(id.substr(3)))


# ------------------------------------------------------------------ drawing

func _s(v: float) -> float:
	return v * ui_scale


func _text(pos: Vector2, s: String, size: int, colour: Color, align := HORIZONTAL_ALIGNMENT_CENTER, width := -1.0) -> void:
	var fs := int(round(size * ui_scale))
	var w := width if width > 0 else _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x := pos.x - (w * 0.5 if align == HORIZONTAL_ALIGNMENT_CENTER else (w if align == HORIZONTAL_ALIGNMENT_RIGHT else 0.0))
	draw_string_outline(_font, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(4 * ui_scale), Color(0, 0, 0, 0.7))
	draw_string(_font, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)


func _panel(r: Rect2, border: Color = Color(COPPER, 0.6), width := 2.0) -> void:
	draw_rect(r, PLATE)
	draw_rect(r, border, false, width * ui_scale)


func _draw() -> void:
	_buttons.clear()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.015, 0.02, 0.62))
	var felt_size := AssetCatalog.display_size("ui/poker_felt") * ui_scale
	draw_texture_rect(_felt, Rect2(centre - felt_size * 0.5, felt_size), false)
	if phase == "buyin":
		_draw_buy_in()
		return
	if night == null or night.table == null:
		_draw_over()
		return
	var t := night.table
	_draw_board(t)
	for i in t.seats.size():
		_draw_seat(t, i)
	_draw_controls(t)
	_draw_log()
	if banner != "":
		var r := Rect2(centre + Vector2(_s(-360), _s(50)), Vector2(_s(720), _s(40)))
		_panel(r, Color(GOLD, 0.7))
		_text(r.get_center() + Vector2(0, _s(7)), banner, 17, GOLD)
	if phase == "over":
		_draw_over()
	_leave_hint()


func _leave_hint() -> void:
	var r := Rect2(Vector2(size.x - _s(250), size.y - _s(104)), Vector2(_s(230), _s(30)))
	_panel(r, Color(COPPER, 0.4), 1.0)
	_text(r.get_center() + Vector2(0, _s(6)), "Esc   Leave the table", 15, DIM)
	_buttons.append({"rect": r, "id": "leave"})


func _draw_buy_in() -> void:
	var r := Rect2(centre - Vector2(_s(300), _s(150)), Vector2(_s(600), _s(300)))
	_panel(r, Color(COPPER, 0.8), 2.5)
	_text(r.position + Vector2(r.size.x * 0.5, _s(46)), "The back-room game", 28, COPPER)
	_text(r.position + Vector2(r.size.x * 0.5, _s(80)),
		"No-Limit Hold'em.  Blinds a nickel and a dime.  No house cut, no markers.", 15, DIM)
	var y := r.position.y + _s(124)
	if over_text != "":
		_text(Vector2(r.get_center().x, y), over_text, 18, CREAM)
		y += _s(46)
	else:
		for i in choices.size():
			var b := Rect2(Vector2(r.position.x + _s(150), y - _s(24)), Vector2(_s(300), _s(34)))
			_panel(b, Color(COPPER, 0.5), 1.0)
			_text(b.get_center() + Vector2(0, _s(7)), "%d   Buy in for %s" % [i + 1, money_text(choices[i])], 18, CREAM)
			_buttons.append({"rect": b, "id": "buy%d" % i})
			y += _s(42)
	var nb := Rect2(Vector2(r.position.x + _s(150), y - _s(24)), Vector2(_s(300), _s(34)))
	_panel(nb, Color(COPPER, 0.3), 1.0)
	_text(nb.get_center() + Vector2(0, _s(7)), "Esc   Not tonight", 18, DIM)
	_buttons.append({"rect": nb, "id": "no"})
	_text(Vector2(r.get_center().x, r.end.y - _s(16)), "In your pocket: %s" % money_text(money), 14, DIM)


func _draw_over() -> void:
	var r := Rect2(centre - Vector2(_s(330), _s(60)), Vector2(_s(660), _s(120)))
	_panel(r, Color(COPPER, 0.8), 2.5)
	_text(r.get_center() + Vector2(0, _s(-8)), over_text, 17, CREAM)
	_text(r.get_center() + Vector2(0, _s(30)), "Esc   Get up from the table", 15, DIM)


func _slot_index(t: Holdem, i: int) -> int:
	var n := t.seats.size()
	var k := (i - night.danny + n) % n
	if n == 3 and k == 2:
		k = 3  # three at the table: left, Danny, right
	return k


func _slot(t: Holdem, i: int) -> Vector2:
	return centre + SLOTS[_slot_index(t, i)] * ui_scale


func _draw_seat(t: Holdem, i: int) -> void:
	var s: Dictionary = t.seats[i]
	var at := _slot(t, i)
	var mine := i == night.danny
	if s.out and not s.in_hand:
		var er := Rect2(at - Vector2(_s(90), _s(24)), Vector2(_s(180), _s(48)))
		draw_rect(er, Color(0, 0, 0, 0.35))
		_text(er.get_center() + Vector2(0, _s(6)), "(an empty chair)", 14, DIM)
		return
	var folded: bool = s.in_hand and s.folded
	var beat := pacing.current
	var turn: bool = (beat.get("seat", -1) == i) if pacing.waiting() else (t.running() and t.to_act == i)
	var pr := Rect2(at - Vector2(_s(100), _s(30)), Vector2(_s(200), _s(60)))
	if turn:
		var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.006)
		draw_rect(pr.grow(_s(5)), Color(COPPER, 0.35 * pulse))
	_panel(pr, COPPER if turn else Color(COPPER, 0.45), 2.0 if turn else 1.0)
	var name_colour := DIM if folded else (GOLD if mine else CREAM)
	_text(pr.position + Vector2(_s(100), _s(22)), String(s.name), 18, name_colour)
	var style_word: String = PokerNight.STYLE_WORDS.get(String(s.get("style", "")), "you" if mine else "")
	_text(pr.position + Vector2(_s(10), _s(48)), style_word, 13, DIM, HORIZONTAL_ALIGNMENT_LEFT)
	_text(pr.position + Vector2(_s(190), _s(48)), money_text(s.stack), 16, COPPER, HORIZONTAL_ALIGNMENT_RIGHT)
	# what he did
	if said.has(i):
		var c := RED if String(said[i]).begins_with("All") else (DIM if said[i] == "Folds" else GOLD)
		_text(pr.position + Vector2(_s(100), _s(-12)), said[i], 16, c)
	# the button and the blinds
	var toward := (centre - at).normalized()
	if i == t.button:
		var bs := Vector2(_s(26), _s(26))
		draw_texture_rect(_dealer, Rect2(at + toward * _s(70) + toward.orthogonal() * _s(70) - bs * 0.5, bs), false)
	if t.running() or t.street == Holdem.OVER and t.hand_no > 0:
		var tag := "SB" if i == t.sb_seat else ("BB" if i == t.bb_seat else "")
		if tag != "":
			_text(pr.position + Vector2(_s(10), _s(22)), tag, 12, COPPER, HORIZONTAL_ALIGNMENT_LEFT)
	# hole cards
	if s.in_hand and not (folded and not mine):
		var show: bool = mine or (t.shown and pacing.hands_shown and not s.folded)
		var cs := Vector2(_s(54), _s(76)) if mine else Vector2(_s(38), _s(53))
		var side := absf(toward.x) > 0.5
		var base := at + toward * _s(152 if side else 72) - Vector2(cs.x + _s(2), cs.y * 0.5)
		if mine:
			base = at + Vector2(-_s(112) - cs.x * 2.0 - _s(4), -cs.y * 0.5)
		for k in (s.hole as Array).size():
			var r := Rect2(base + Vector2(k * (cs.x + _s(4)), 0), cs)
			if show:
				_card(r, s.hole[k], folded)
			else:
				draw_texture_rect(_back, r, false)
	# the bet in front of him
	if s.bet > 0:
		var bp: Vector2 = centre + BETS[_slot_index(t, i)] * ui_scale
		_chips(bp, s.bet)
		_text(bp + Vector2(0, _s(30)), money_text(s.bet), 14, CREAM)


func _chips(p: Vector2, amount: int) -> void:
	var n := clampi(1 + amount / 20, 1, 6)
	var cs := Vector2(_s(22), _s(22))
	var colour: Color = CHIP_COLOURS[clampi(int(log(maxf(amount, 1.0)) / log(4.0)) - 1, 0, CHIP_COLOURS.size() - 1)]
	for k in n:
		draw_texture_rect(_chip, Rect2(p - cs * 0.5 - Vector2(0, k * _s(3)), cs), false, colour)


func _card(r: Rect2, c: int, dim := false) -> void:
	var tint := Color(0.6, 0.6, 0.6) if dim else Color.WHITE
	draw_texture_rect(_face, r, false, tint)
	var red := Cards.suit(c) == 1 or Cards.suit(c) == 2
	var ink := (RED_INK if red else INK) * tint
	var face: String = Cards.FACES[Cards.rank(c)]
	var fs := int(round(r.size.y * 0.27))
	draw_string(_font, r.position + Vector2(r.size.x * 0.1, r.size.y * 0.3), face, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
	var pip := r.size.x * 0.48
	draw_texture_rect(_suits[Cards.suit(c)], Rect2(r.get_center() + Vector2(-pip * 0.5, -pip * 0.25), Vector2(pip, pip)), false, tint)
	var small := r.size.x * 0.22
	draw_texture_rect(_suits[Cards.suit(c)], Rect2(r.position + Vector2(r.size.x * 0.1, r.size.y * 0.34), Vector2(small, small)), false, tint)


func _draw_board(t: Holdem) -> void:
	var cs := Vector2(_s(56), _s(78))
	var gap := _s(8)
	var start := centre - Vector2((cs.x * 5 + gap * 4) * 0.5, cs.y * 0.5 + _s(6))
	for k in 5:
		var r := Rect2(start + Vector2(k * (cs.x + gap), 0), cs)
		if k < mini(t.board.size(), pacing.revealed):
			_card(r, t.board[k])
		else:
			draw_rect(r, Color(0, 0, 0, 0.18))
			draw_rect(r, Color(CREAM, 0.12), false, 1.0)
	var pot := t.pot_total()
	if pot > 0:
		_chips(centre + Vector2(0, _s(-74)), pot)
		_text(centre + Vector2(0, _s(-92)), "Pot  %s" % money_text(pot), 18, GOLD)
		var pots := t.pots()
		var all_in := t.contenders().any(func(i: int) -> bool: return t.seats[i].all_in)
		if pots.size() > 1 and all_in:
			var parts := []
			for k in range(1, pots.size()):
				parts.append(money_text(pots[k].amount))
			_text(centre + Vector2(0, _s(64)), "main %s  ·  side %s" % [money_text(pots[0].amount), ", ".join(parts)], 14, CREAM)
	if t.running() and not pacing.waiting():
		_text(centre + Vector2(0, _s(84)), "to call  %s" % money_text(t.current_bet) if t.current_bet > 0 else Holdem.STREET_NAMES[t.street], 13, DIM)


func _draw_controls(t: Holdem) -> void:
	if phase == "play" and pacing.waiting():
		_draw_continue()
		return
	if phase != "play" or not t.running() or t.to_act != night.danny:
		if phase == "play" and t.running():
			var who: String = t.seats[t.to_act].name if t.to_act >= 0 else ""
			if who != "":
				_text(Vector2(size.x * 0.5, size.y - _s(26)), "%s is thinking..." % who, 16, DIM)
		return
	var l := t.legal(night.danny)
	var labels := [
		"1   Fold",
		"2   Check" if l.check else "2   Call %s" % money_text(l.call),
		("3   Bet %s" if l.bet else "3   Raise to %s") % money_text(clampi(raise_to, l.min_to, l.max_to)) if (l.bet or l.raise) else "3   Raise",
		"4   All in %s" % money_text(l.all_in) if l.all_in > 0 else "4   All in",
	]
	var enabled := [true, true, l.bet or l.raise, l.all_in > 0]
	var w := _s(210)
	var gap := _s(14)
	var x := size.x * 0.5 - (w * 4 + gap * 3) * 0.5
	var y := size.y - _s(52)
	for k in 4:
		var r := Rect2(Vector2(x + k * (w + gap), y), Vector2(w, _s(38)))
		_panel(r, Color(COPPER, 0.8 if enabled[k] else 0.25), 1.5)
		_text(r.get_center() + Vector2(0, _s(7)), labels[k], 17, CREAM if enabled[k] else Color(DIM, 0.35))
		if enabled[k]:
			_buttons.append({"rect": r, "id": "act%d" % (k + 1)})
	if l.bet or l.raise:
		_text(Vector2(x + 2 * (w + gap) + w * 0.5, y - _s(10)), "wheel or arrows: more / less", 12, DIM)


## The beat on show in a word at the bottom, and the small prompt (also a button).
func _draw_continue() -> void:
	var beat := pacing.current
	var what: String = ("%s: %s" % [beat.name, beat.text]) if beat.kind == "action" else ("" if beat.kind == "result" else String(beat.text))
	var y := size.y - _s(30)
	if what != "":
		_text(Vector2(size.x * 0.5, y - _s(26)), what, 17, CREAM)
	var label := "Space   Continue"
	var w := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, int(round(14 * ui_scale))).x + _s(28)
	var r := Rect2(Vector2(size.x * 0.5 - w * 0.5, y - _s(16)), Vector2(w, _s(26)))
	_panel(r, Color(COPPER, 0.45), 1.0)
	_text(r.get_center() + Vector2(0, _s(5)), label, 14, DIM)
	_buttons.append({"rect": r, "id": "continue"})


func _draw_log() -> void:
	var y := size.y - _s(60) - log_lines.size() * _s(18)
	for line in log_lines:
		_text(Vector2(_s(20), y), line, 13, DIM, HORIZONTAL_ALIGNMENT_LEFT)
		y += _s(18)
