class_name RoulettePatrons
extends RefCounted
## M013: the other players at Leo's wheel (pure). Each plays with the house's
## colour chips from a purse of their own for the night (Patrons.ROSTER),
## kept entirely apart from Danny's money and chips; nothing here touches the
## draw (the table's own generator, drawn at the call) - their choices come
## from a generator of their own.
##
## At each round's opening every regular at the rail decides whether to play
## it (a cautious player sits out more often; nobody bets money they no longer
## have) and plans a bet or two, put down at moments through the betting time
## (so the chips appear one by one, as people make up their minds) - and only
## while the bets are open. At the rest their bets are settled by the same
## rules as Danny's (Roulette.returns): winnings into their purse, losing chips
## to the house. A regular who has lost his purse stops playing for the night.

## What each kind of player bets on and with which chips (cents).
const STYLE := {
	"cautious": {"play": 0.7, "bets": [1, 2], "chips": [5, 10],
		"keys": ["red", "black", "odd", "even", "low", "high", "dozen:1", "dozen:2", "dozen:3"]},
	"numbers": {"play": 0.8, "bets": [1, 3], "chips": [5, 10], "keys": []},
	"plunger": {"play": 0.85, "bets": [1, 2], "chips": [25, 100], "keys": ["column:1", "column:2", "column:3", "dozen:1",
		"dozen:2", "dozen:3", "red", "black"]},
}

var rules: RouletteRules
var rng := RandomNumberGenerator.new()
## id -> {"style", "purse" (cents), "start" (the night's purse)}
var players := {}
## This round: id -> {key: cents}
var bets := {}
var _planned: Array = []  # [{at, id, key, cents}] (round time)


func _init(p_rules: RouletteRules, p_seed := -1) -> void:
	rules = p_rules
	if p_seed >= 0:
		rng.seed = p_seed
	else:
		rng.randomize()


## A regular steps up to the rail (their purse for the night if they are new tonight).
func seat(id: String) -> void:
	if not Patrons.ROSTER.has(id):
		return
	if players.has(id):
		players[id].seated = true  # back at the rail, with what is left of tonight's purse
		return
	var r: Dictionary = Patrons.ROSTER[id]
	players[id] = {"style": String(r.style), "purse": int(r.purse), "start": int(r.purse), "seated": true}


## A regular steps away: chips not yet called come back to their purse.
func unseat(id: String) -> void:
	if not players.has(id):
		return
	_refund(id)
	players[id].seated = false
	_planned = _planned.filter(func(p: Dictionary) -> bool: return p.id != id)


func seated() -> Array:
	return players.keys().filter(func(id: String) -> bool: return bool(players[id].seated))


func purse(id: String) -> int:
	return int(players.get(id, {}).get("purse", 0))


## A new night: purses as they came in.
func begin_night() -> void:
	bets.clear()
	_planned.clear()
	for id in players:
		players[id].purse = int(players[id].start)


## A round opens: who plays it, and when they put their chips down (round
## time, before `close_at` - the usual call).
func plan_round(close_at: float) -> void:
	bets.clear()
	_planned.clear()
	for id in seated():
		var style: Dictionary = STYLE[String(players[id].style)]
		if rng.randf() > float(style.play):
			continue
		var n := rng.randi_range(int(style.bets[0]), int(style.bets[1]))
		var left := purse(id)
		for i in n:
			var chip: int = style.chips[rng.randi_range(0, style.chips.size() - 1)]
			if chip > left or chip < rules.min_bet:
				chip = style.chips[0]
			if chip > left:
				break
			left -= chip
			var at := rng.randf_range(0.8, maxf(1.0, close_at - 1.2))
			_planned.append({"at": at, "id": id, "key": _pick(id, String(players[id].style)), "cents": chip})
	_planned.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.at < b.at)


func _pick(id: String, style: String) -> String:
	var keys: Array = STYLE[style].keys
	if style == "numbers" or (style == "plunger" and rng.randf() < 0.3):
		var lucky: Array = Patrons.ROSTER[id].lucky
		var n: int = lucky[rng.randi_range(0, lucky.size() - 1)] if not lucky.is_empty() else rng.randi_range(0, 36)
		if style == "numbers" and rng.randf() < 0.35 and n >= 1 and n <= 33:
			return Roulette.normal("split:%d-%d" % [n, n + 3])  # a split with the number across
		return "straight:%d" % n
	return String(keys[rng.randi_range(0, keys.size() - 1)])


## The bets whose moment has come by `round_time` go down (only while the
## bets are open). Returns them: [{id, key, cents}].
func advance(round_time: float, open: bool) -> Array:
	var out := []
	if not open:
		_planned.clear()
		return out
	while not _planned.is_empty() and float(_planned[0].at) <= round_time:
		var p: Dictionary = _planned.pop_front()
		var id: String = p.id
		if not players.has(id) or not bool(players[id].seated):
			continue
		var cents: int = p.cents
		var key: String = p.key
		var mine: Dictionary = bets.get(id, {})
		if cents > purse(id) or int(mine.get(key, 0)) + cents > _limit(key):
			continue
		players[id].purse = purse(id) - cents
		mine[key] = int(mine.get(key, 0)) + cents
		bets[id] = mine
		out.append({"id": id, "key": key, "cents": cents})
	return out


func _limit(key: String) -> int:
	var kind := Roulette.kind_of(key)
	if kind == "straight":
		return rules.max_straight
	return rules.max_inside if kind in Roulette.INSIDE else rules.max_outside


## The ball is at rest on `number`: every regular's bets settled by the
## table's rules. Returns [{id, staked, paid}] (paid: stakes and winnings back).
func settle(number: int) -> Array:
	var out := []
	for id in bets:
		var staked := 0
		var paid := 0
		for key in bets[id]:
			staked += int(bets[id][key])
			paid += Roulette.returns(key, int(bets[id][key]), number)
		if players.has(id):
			players[id].purse = purse(id) + paid
		out.append({"id": id, "staked": staked, "paid": paid})
	bets.clear()
	_planned.clear()
	return out


## Everything the regulars have down on `key` this round: [{id, cents}].
func on(key: String) -> Array:
	var out := []
	for id in bets:
		if bets[id].has(key):
			out.append({"id": id, "cents": int(bets[id][key])})
	return out


func total_down() -> int:
	var t := 0
	for id in bets:
		for key in bets[id]:
			t += int(bets[id][key])
	return t


## Every regular's chips not yet called back to their purses (the table stopped).
func refund_all() -> void:
	for id in bets.keys():
		_refund(id)
	_planned.clear()


func _refund(id: String) -> void:
	if bets.has(id):
		for key in bets[id]:
			players[id].purse = purse(id) + int(bets[id][key])
		bets.erase(id)
