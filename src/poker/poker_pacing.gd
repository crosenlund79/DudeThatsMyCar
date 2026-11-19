class_name PokerPacing
extends RefCounted
## The back-room game, one beat at a time: what the table has done (Holdem's
## event log) is shown a step at a time, each step held until Danny presses
## Space - every card player's action (fold, check, call, bet, raise or all-in,
## with who did it), each street of community cards (the flop, the turn, the
## river - one at a time even when an all-in deals them all at once), and the
## showdown's result. Danny's own actions are not held (he has just made them),
## but what follows them is. Only presentation: the rules, the money and the
## card players' decisions are untouched; the table is already where it is.
##
## A beat: {kind: "action", seat, player (the seat's id, e.g. "red"), name,
## action ("fold", "check", "call", "bet", "raise", "all_in"), amount (cents
## put in, or the total bet raised to), text} | {kind: "deal", street, cards,
## shown (board cards showing after it), text} | {kind: "result", text}.
## Pure; one press of Space moves on exactly one beat (a held key never does).

const STREET_WORDS := {Holdem.FLOP: "The flop", Holdem.TURN: "The turn", Holdem.RIVER: "The river"}

## Beats still to show, in order.
var queue: Array[Dictionary] = []
## The beat on show now ({} when none: play goes on).
var current := {}
## Community cards showing (the table may have dealt more than this already).
var revealed := 0
## The showdown's hands are face up (the result beat has been reached).
var hands_shown := false
var _seen := 0
var _result_queued := false
var _space_down := false


## A fresh hand: nothing shown, nothing waiting.
func new_hand() -> void:
	queue.clear()
	current = {}
	revealed = 0
	hands_shown = false
	_seen = 0
	_result_queued = false


## Something is on show and play waits for Space.
func waiting() -> bool:
	return not current.is_empty()


## Turns what the table has done since the last read into beats (Danny's own
## actions excepted) and shows the first if nothing is on show. Returns the
## beat that came on show now ({} if none did).
func read(t: Holdem, danny: int) -> Dictionary:
	for k in range(_seen, t.events.size()):
		var e: Dictionary = t.events[k]
		match String(e.what):
			"fold", "check", "call", "bet", "raise":
				if int(e.seat) != danny:
					queue.append(action_beat(t, e))
			"deal":
				var shown := revealed_after(e.street)
				queue.append({"kind": "deal", "street": e.street, "cards": e.cards, "shown": shown,
					"text": "%s: %s" % [STREET_WORDS.get(e.street, "The cards"), " ".join((e.cards as Array).map(
						func(c: int) -> String: return Cards.FACES[Cards.rank(c)] + ["s", "h", "d", "c"][Cards.suit(c)]))]})
	_seen = t.events.size()
	if not t.running() and t.hand_no > 0 and not _result_queued and not t.results.is_empty():
		_result_queued = true
		queue.append({"kind": "result", "text": result_text(t)})
	if current.is_empty():
		return _next()
	return {}


## Space pressed (`pressed`) or let go; `echo` for a key's auto-repeat. Only a
## fresh press moves on, and only one beat: holding the key, its repeats and
## a second press before it is let go do nothing. Returns the beat that came
## on show ({} if none).
func space(pressed: bool, echo: bool = false) -> Dictionary:
	if not pressed:
		_space_down = false
		return {}
	if echo or _space_down:
		return {}
	_space_down = true
	return press_continue()


## Moves on one beat (the one on show is dismissed). Returns the next beat on
## show ({} when play goes on).
func press_continue() -> Dictionary:
	if current.is_empty():
		return {}
	current = {}
	return _next()


func _next() -> Dictionary:
	if queue.is_empty():
		return {}
	current = queue.pop_front()
	match String(current.kind):
		"deal":
			revealed = int(current.shown)
		"result":
			hands_shown = true
			revealed = 5
	return current


static func revealed_after(street: int) -> int:
	return {Holdem.FLOP: 3, Holdem.TURN: 4, Holdem.RIVER: 5}.get(street, 0)


## A beat for one action event (also used to word Danny's own actions).
static func action_beat(t: Holdem, e: Dictionary) -> Dictionary:
	var s: Dictionary = t.seats[e.seat]
	var kind := String(e.what)
	var all_in: bool = e.get("all_in", false) and kind != "fold"
	var amount := int(e.get("to", e.get("amount", 0))) if kind in ["bet", "raise"] else int(e.get("amount", 0))
	var text := ""
	match kind:
		"fold":
			text = "Folds"
		"check":
			text = "Checks"
		"call":
			text = "Calls %s - all in!" % PokerPacing.money(amount) if all_in else "Calls %s" % PokerPacing.money(amount)
		"bet":
			text = "All in for %s!" % PokerPacing.money(amount) if all_in else "Bets %s" % PokerPacing.money(amount)
		"raise":
			text = "All in for %s!" % PokerPacing.money(amount) if all_in else "Raises to %s" % PokerPacing.money(amount)
	return {"kind": "action", "seat": int(e.seat), "player": String(s.get("id", "")), "name": String(s.name),
		"action": "all_in" if all_in else kind, "amount": amount, "all_in": all_in, "text": text}


## The hand's result as the table says it ("Red Gallagher wins $1.40 with two pair, ...").
static func result_text(t: Holdem) -> String:
	var parts: Array[String] = []
	for r in t.results:
		var names := []
		for w in r.winners:
			names.append(t.seats[w].name)
		var who := " and ".join(names)
		if String(r.hand) == "" or not t.shown:
			parts.append("%s takes %s%s" % [who, "split " if r.winners.size() > 1 else "", money(r.amount)])
		else:
			parts.append("%s %s %s with %s" % [who, "split" if r.winners.size() > 1 else "wins", money(r.amount), r.hand])
	return ";  ".join(parts)


static func money(cents: int) -> String:
	return "$%d.%02d" % [cents / 100, cents % 100]
