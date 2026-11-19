class_name PokerNight
extends RefCounted
## M010: the Copper Owl's back-room game, night by night. Three regulars come
## every night with their own money (a cautious bookkeeper, an aggressive
## longshoreman, a loose trolley conductor) and a fourth drops in once a night
## when a chair comes free. Danny sits in with a buy-in from his own pocket
## and gets up with whatever is in front of him. No house cut, no credit.
##
## Money is only ever moved, never made: Danny's money + the players' purses
## (what they have away from the table) + the chips on the table add up the
## same from the moment the night begins to the moment it ends.
## Pure and deterministic (each hand and each decision from the night's seed).
##
## M013: the stakes are Danny's choice before he sits down - LEVELS: nickel
## and dime (as ever), dime and quarter, quarter and half - with buy-ins to
## match; they never change while he sits. The regulars bring a night's
## bankroll big enough for any of them (BANKROLL x their purse) and sit down
## with a level's stake (their purse x the level's `scale`), the rest kept in
## their pocket: at the nickel-dime game they sit with what they always did.
## A hand under way when the game is saved counts as folded (stake_for_save):
## what Danny has put in the pot is gone - a save can never undo a losing
## hand (M010 counted it void, which could).

const REGULARS := [
	{"id": "irv", "name": "Irv Feldman", "style": "cautious", "purse": 600, "look": "characters/clerk",
		"what": "a bookkeeper who counts every chip"},
	{"id": "red", "name": "Red Gallagher", "style": "aggressive", "purse": 500, "look": "characters/worker",
		"what": "a longshoreman who bets like he's throwing a punch"},
	{"id": "pete", "name": "Lucky Pete", "style": "loose", "purse": 450, "look": "characters/patron_man",
		"what": "a trolley conductor who never met a hand he didn't like"},
]
const LATE := {"id": "moe", "name": "Moe Brandt", "style": "cautious", "purse": 400, "look": "characters/barber",
	"what": "a cutter from the garment trade, in late off the streetcar"}
const STYLE_WORDS := {"cautious": "careful", "aggressive": "pushy", "loose": "loose"}
## M013: the stakes (cents): blinds, the chip, Danny's buy-ins, and how much
## of their usual stake the regulars sit down with.
const LEVELS := [
	{"id": "low", "name": "Nickel and dime", "sb": 5, "bb": 10, "chip": 5, "buy_ins": [200, 500, 1000], "scale": 1.0},
	{"id": "medium", "name": "Dime and quarter", "sb": 10, "bb": 25, "chip": 5, "buy_ins": [500, 1000, 2500], "scale": 2.5},
	{"id": "high", "name": "Quarter and half", "sb": 25, "bb": 50, "chip": 25, "buy_ins": [1000, 2500, 5000], "scale": 5.0},
]
## A regular's bankroll for the night, in his usual purses.
const BANKROLL := 5

var level := 0
var small_blind := 5
var big_blind := 10
var chip := 5
var min_buy_in := 200
var max_buy_in := 1000
var night := 0
## Money each player has away from the table tonight (cents).
var purses := {}
## Players who have gone for the night: id -> "bust".
var gone := {}
var table: Holdem = null
## Danny's seat at the table (-1: he is not sitting in).
var danny := -1
var late_joined := false
## The game breaks up after the hand under way (closing time).
var closing := false
## Danny's winnings over every night he has played (negative: losses) and
## the hands he has been dealt - remembered in the save.
var net := 0
var hands := 0
var _bought := 0
var _rng := RandomNumberGenerator.new()


func begin_night(n: int) -> void:
	night = n
	purses = {}
	for p in REGULARS + [LATE]:
		purses[p.id] = int(p.purse) * BANKROLL
	gone = {}
	table = null
	danny = -1
	late_joined = false
	closing = false


static func person(id: String) -> Dictionary:
	for p in REGULARS + [LATE]:
		if p.id == id:
			return p
	return {}


## The regulars still about tonight (and Moe once he has come in).
func players_tonight() -> Array:
	var out := []
	for p in REGULARS:
		if not gone.has(p.id) and purses[p.id] > 0:
			out.append(p)
	return out


func seated() -> bool:
	return table != null and danny >= 0


## M013: the stakes Danny will sit down at (not while he sits). False: not now.
func set_level(i: int) -> bool:
	if seated() or i < 0 or i >= LEVELS.size():
		return false
	level = i
	var l: Dictionary = LEVELS[i]
	small_blind = int(l.sb)
	big_blind = int(l.bb)
	chip = int(l.chip)
	min_buy_in = int(l.buy_ins[0])
	max_buy_in = int(l.buy_ins[-1])
	return true


func level_name() -> String:
	return String(LEVELS[level].name)


## What a regular sits down with at these stakes (no more than he has).
func _stake_of(p: Dictionary) -> int:
	var want := int(round(int(p.purse) * float(LEVELS[level].scale) / chip)) * chip
	return mini(want, int(purses[p.id]) / chip * chip)


## Why Danny cannot sit in now ("" when he can).
func cannot_sit(money: int) -> String:
	if closing:
		return "The game's breaking up for the night."
	if players_tonight().is_empty():
		return "Nobody left at the table tonight - they've cleaned each other out."
	if money < min_buy_in:
		return "The %s game's a %s buy-in. You haven't got it." % [level_name().to_lower(), Rackets.dollars(min_buy_in)] if level > 0 \
			else "The game's a two-dollar buy-in. You haven't got it."
	return ""


## The buy-ins Danny can choose from with this much money.
func buy_in_choices(money: int) -> Array[int]:
	var out: Array[int] = []
	for amount in LEVELS[level].buy_ins:
		if amount <= money and amount >= min_buy_in and amount <= max_buy_in:
			out.append(int(amount))
	return out


## Danny sits in for `amount` (whole chips, within the limits, no more than
## he has). The caller takes it from his money. False: not allowed.
func sit_down(amount: int, money: int) -> bool:
	if seated() or cannot_sit(money) != "" or amount < min_buy_in or amount > max_buy_in \
			or amount > money or amount % chip != 0:
		return false
	table = Holdem.new(small_blind, big_blind, chip)
	danny = table.sit("Danny", amount, {"id": "danny"})
	for p in players_tonight():
		var stake := _stake_of(p)
		table.sit(p.name, stake, {"id": p.id, "style": p.style})
		purses[p.id] = int(purses[p.id]) - stake
	if late_joined and not gone.has(LATE.id) and purses[LATE.id] > 0:
		var late := _stake_of(LATE)
		table.sit(LATE.name, late, {"id": LATE.id, "style": LATE.style})
		purses[LATE.id] = int(purses[LATE.id]) - late
	_rng.seed = hash([night, "button", hands])
	table.button = _rng.randi_range(0, table.seats.size() - 1)
	_bought = amount
	return true


## Deals the next hand (between hands). False when the game cannot go on:
## Danny is cleaned out, nobody is left to play him, or it is closing time.
func next_hand() -> bool:
	if not seated() or table.running():
		return false
	_settle_busted()
	if table.seats[danny].out or closing:
		return false
	# a chair came free: the late man pulls it up, once a night
	if not late_joined and _empty_chair() and _stake_of(LATE) > 0:
		late_joined = true
		var late := _stake_of(LATE)
		table.sit(LATE.name, late, {"id": LATE.id, "style": LATE.style, "joined": true})
		purses[LATE.id] = int(purses[LATE.id]) - late
	if not table.can_start():
		return false
	hands += 1
	return table.start_hand(hash([night, hands, "deal"]))


func _empty_chair() -> bool:
	for s in table.seats:
		if s.out:
			return true
	return false


## Players who lost their last chip go home for the night.
func _settle_busted() -> void:
	for s in table.seats:
		if s.get("busted", false) and s.id != "danny" and not gone.has(s.id):
			gone[s.id] = "bust"  # cleaned out at the table: he goes home (with whatever he left in his pocket)


## It is a card player's turn (not Danny's).
func ai_to_act() -> bool:
	return seated() and table.running() and table.to_act >= 0 and table.to_act != danny


## The card player whose turn it is decides and acts. Returns his action.
func ai_turn() -> Dictionary:
	if not ai_to_act():
		return {}
	var i := table.to_act
	_rng.seed = hash([night, hands, table.events.size(), i])
	var d := PokerBrain.decide(table, i, String(table.seats[i].style), _rng)
	if d.is_empty() or not table.act(i, d.kind, d.to):
		table.act(i, "check") if table.legal(i).check else table.act(i, "fold")
		d = {"kind": "fold", "to": 0}
	d["seat"] = i
	return d


## Danny's own action ("fold", "check", "call", "bet", "raise", "all_in").
func danny_acts(kind: String, to: int = 0) -> bool:
	if not seated() or table.to_act != danny:
		return false
	return table.act(danny, kind, to)


## Danny gets up: mid-hand he folds at once and the others play the hand out.
## Returns the money he takes home (the caller adds it to his).
func leave() -> int:
	if not seated():
		return 0
	if table.running():
		table.fold_out(danny)
		var guard := 0
		while table.running() and guard < 400:
			guard += 1
			if ai_to_act():
				ai_turn()
			else:
				break
	_settle_busted()
	var chips := table.leave(danny)
	for i in table.seats.size():
		var s: Dictionary = table.seats[i]
		if s.id != "danny" and not s.out:
			purses[s.id] = int(purses[s.id]) + table.leave(i)
	net += chips - _bought
	table = null
	danny = -1
	_bought = 0
	return chips


## What Danny's money should be counted as if the game were saved now: what
## is in front of him. M013: a hand under way counts as folded - what he has
## put in the pot is gone (as when he gets up mid-hand), so saving and loading
## can never undo a losing hand.
func stake_for_save() -> int:
	if not seated():
		return 0
	return int(table.seats[danny].stack)


## M013: what getting up now would mean: {"in_hand" (he is still in a hand
## under way), "in_pot" (what he has put in it, lost if he goes), "takes" (the
## chips he would take home), "all_in"}.
func leave_terms() -> Dictionary:
	if not seated():
		return {"in_hand": false, "in_pot": 0, "takes": 0, "all_in": false}
	var s: Dictionary = table.seats[danny]
	var live: bool = table.running() and s.in_hand and not s.folded
	return {"in_hand": live, "in_pot": int(s.total) if live else 0, "takes": int(s.stack), "all_in": live and bool(s.all_in)}


## Every cent belonging to the card players tonight: their purses and their
## chips on the table (for the books: with Danny's money it never changes).
func players_money() -> int:
	var t := 0
	for id in purses:
		t += int(purses[id])
	if table != null:
		for s in table.seats:
			if s.id != "danny":
				t += int(s.stack) + int(s.total)
	return t


func danny_chips() -> int:
	if not seated():
		return 0
	return int(table.seats[danny].stack) + int(table.seats[danny].total)


func to_dict() -> Dictionary:
	return {"net": net, "hands": hands, "level": level}


func from_dict(d: Dictionary) -> void:
	net = int(d.get("net", 0))
	hands = int(d.get("hands", 0))
	set_level(clampi(int(d.get("level", 0)), 0, LEVELS.size() - 1))  # the stakes he played last
