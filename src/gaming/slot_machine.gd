class_name SlotMachine
extends RefCounted
## One nickel machine in the gaming room (pure, no scene) - every machine is
## one of these with its own SlotRules. Three reels, each a strip of twenty
## stops; a pull takes the coin, and each reel's stop is drawn fairly (every
## stop on a strip alike, nothing else counts - not Danny's money, not how he
## has been playing, not the last pull). The symbols on the line in the
## window are the result; the paytable on the machine's front says what that
## line pays, and it is paid once when the reels have stopped (`collect`).
## The return to the player follows from the strips and the paytable alone
## (`expected_return`, exact).
##
## M013 hold-and-respin. A pull is a full spin (all three reels). After a full
## spin that pays nothing, the machine's HOLD lamps may light - by a fair draw
## made with the pull, the same chance every time (`rules.hold_chance`, printed
## on the plate), nothing to do with money or play. With the lamps lit Danny
## may hold one or two reels (never three) for the next pull: it costs the same
## stake (taken once), the held reels keep their symbols and stand still, the
## others spin, and all three are paid as any line. Then the holds are
## released, and the pull after a respin is always a full spin - no chains.
## The stake (one, two or five coins: `rules.stakes`) pays in proportion; it
## cannot be changed under lit lamps without putting them out. The best a
## player can get from holds is exact too (`best_hold_return`), and below what
## goes in.

const SYMBOLS := ["cherry", "lemon", "orange", "plum", "bell", "bar", "seven"]
const WORDS := {"cherry": "Cherry", "lemon": "Lemon", "orange": "Orange", "plum": "Plum", "bell": "Bell", "bar": "Bar",
	"seven": "Seven"}

var rules: SlotRules
## Where each reel stands (index into its strip): the symbol on the line.
var stops: Array[int] = [0, 0, 0]
## A pull's win waiting for the reels to stop (cents), and whether it is waiting.
var win := 0
var pending := false
var pulls := 0
var paid_total := 0
var taken_total := 0
## M013: the stake a pull (cents: the coin times rules.stakes[k]).
var stake := 0
## The HOLD lamps are lit (after a losing full spin, by the draw): reels may be held.
var hold_offered := false
## The reels held for the next pull.
var held: Array[bool] = [false, false, false]
## The pull under way (or the last) was a respin of held reels.
var respin := false
## The lamp drawn with the pull under way (only lit if it loses).
var _lamp := false
## The reels held for the pull under way (shown standing still).
var spun_held: Array[bool] = [false, false, false]


func _init(p_rules: SlotRules) -> void:
	rules = p_rules
	stake = rules.coin * int(rules.stakes[0]) if not rules.stakes.is_empty() else rules.coin


## The symbol at `stop` on reel `reel` (wrapping round the strip).
func symbol(reel: int, stop: int) -> String:
	var strip: PackedStringArray = rules.strips[reel]
	return strip[posmod(stop, strip.size())]


## The three symbols on the line now.
func line() -> Array[String]:
	var out: Array[String] = []
	for r in 3:
		out.append(symbol(r, stops[r]))
	return out


## What a line of symbols pays, in coins (the first paytable line it matches).
static func coins_for(r: SlotRules, symbols: Array) -> int:
	for p in r.pays:
		var want: Array = p.line
		var ok := true
		for i in 3:
			if String(want[i]) != "*" and String(want[i]) != String(symbols[i]):
				ok = false
				break
		if ok:
			return int(p.coins)
	return 0


## The paytable line a line of symbols matched (its index, -1 for none).
static func pay_line(r: SlotRules, symbols: Array) -> int:
	for k in r.pays.size():
		var want: Array = r.pays[k].line
		var ok := true
		for i in 3:
			if String(want[i]) != "*" and String(want[i]) != String(symbols[i]):
				ok = false
		if ok:
			return k
	return -1


## Why the lever cannot be pulled now ("" when it can).
func cannot_pull(money: int) -> String:
	if pending:
		return "The reels are still turning."
	if money < stake:
		return "You haven't %s for the slot." % _money_words(stake)
	return ""


static func _money_words(c: int) -> String:
	return "a nickel" if c == 5 else ("a dime" if c == 10 else Rackets.dollars(c))


## How many reels are held for the next pull.
func held_count() -> int:
	return held.count(true)


## Why reel `reel` cannot be held (or let go) now ("" when it can).
func cannot_hold(reel: int) -> String:
	if pending:
		return "The reels are still turning."
	if not hold_offered:
		return "The HOLD lamps aren't lit." if not respin else "Holds are off: this pull spins all three."
	if reel < 0 or reel > 2:
		return "There's no such reel."
	if not held[reel] and held_count() >= 2:
		return "Two reels at most - one has to spin."
	return ""


## Holds reel `reel` for the next pull, or lets it go. Returns "" or why not.
func toggle_hold(reel: int) -> String:
	var why := cannot_hold(reel)
	if why == "":
		held[reel] = not held[reel]
	return why


## The stakes this machine takes (cents), smallest first.
func stake_choices() -> Array[int]:
	var out: Array[int] = []
	for k in rules.stakes:
		out.append(rules.coin * int(k))
	if out.is_empty():
		out.append(rules.coin)
	return out


## Sets the stake (cents, one of stake_choices). Changing it under lit HOLD
## lamps puts them out (no holding at one stake and respinning at another).
## Returns "" or why not.
func set_stake(cents: int) -> String:
	if pending:
		return "Not while the reels are turning."
	if not cents in stake_choices():
		return "The machine doesn't take that."
	if cents != stake and hold_offered:
		_release()
	stake = cents
	return ""


func _release() -> void:
	hold_offered = false
	held = [false, false, false]


## The lever is pulled: the stake goes in and the stops of the reels that spin
## are drawn from `seed` - decided here, once, with the HOLD lamp for a losing
## full spin (the same draw: three stops and the lamp). Held reels (one or two,
## under lit lamps) keep theirs. Returns the cents taken (0: refused).
func pull(money: int, seed: int) -> int:
	if cannot_pull(money) != "":
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var holding := hold_offered and held_count() >= 1 and held_count() <= 2
	for r in 3:
		var keep := holding and held[r]
		var drawn := rng.randi_range(0, rules.strips[r].size() - 1)
		if not keep:
			stops[r] = drawn
	_lamp = rng.randf() < rules.hold_chance
	respin = holding
	spun_held = held.duplicate() if holding else ([false, false, false] as Array[bool])
	_release()  # the holds go with the pull
	win = coins_for(rules, line()) * stake  # the paytable's coins for each coin staked
	pending = true
	pulls += 1
	taken_total += stake
	return stake


## The reels have stopped: the win paid, once. Returns the cents paid (0 a
## second time). A full spin that paid nothing may light the HOLD lamps.
func collect() -> int:
	if not pending:
		return 0
	pending = false
	paid_total += win
	hold_offered = _lights_after()
	return win


func _lights_after() -> bool:
	return not respin and win == 0 and _lamp


## What a save should count on top of Danny's pocket: a pull under way is decided, so its win.
func for_save() -> int:
	return win if pending else 0


## Danny walks away: a pull under way is paid at once.
func walk_away() -> int:
	return collect()


## M013: the machine's state for the save, as it will be once a pull under way
## is paid (its win counted in the money by for_save): the reels, the lamps,
## the holds, the stake.
func to_dict() -> Dictionary:
	var lit := _lights_after() if pending else hold_offered
	return {"stops": [stops[0], stops[1], stops[2]], "stake": stake, "hold_offered": lit,
		"held": [held[0], held[1], held[2]] if lit and not pending else [false, false, false], "respin": respin}


func from_dict(d: Dictionary) -> void:
	var st: Array = d.get("stops", [])
	for r in mini(3, st.size()):
		stops[r] = posmod(int(st[r]), rules.strips[r].size())
	var want := int(d.get("stake", stake))
	stake = want if want in stake_choices() else stake_choices()[0]
	respin = bool(d.get("respin", false))
	hold_offered = bool(d.get("hold_offered", false)) and coins_for(rules, line()) == 0 and not respin
	var h: Array = d.get("held", [])
	held = [false, false, false]
	if hold_offered:
		for r in mini(3, h.size()):
			held[r] = bool(h[r])
		if held_count() > 2:
			held = [false, false, false]
	pending = false
	win = 0


## The exact share of the money put in that comes back, from the strips and the paytable.
func expected_return() -> float:
	var total := 0
	var count := 0
	for a in rules.strips[0]:
		for b in rules.strips[1]:
			for c in rules.strips[2]:
				total += coins_for(rules, [a, b, c])
				count += 1
	return float(total) / float(count)


## M013: the long-run share that comes back to a player who uses the HOLD
## lamps as well as anyone can (exact, from the strips, the paytable and the
## lamp's chance): every losing full spin lights the lamps with
## rules.hold_chance; the best hold for that line (one or two reels) is worth
## its mean respin; holding is worth it when that beats what the play as a
## whole returns - the threshold that gives the most. The same sums as
## tools/slot_odds/analyse.py.
func best_hold_return() -> float:
	var n := [rules.strips[0].size(), rules.strips[1].size(), rules.strips[2].size()]
	var total := float(n[0] * n[1] * n[2])
	var base := expected_return()
	var cache := {}
	var values: Array[float] = []
	for a in n[0]:
		for b in n[1]:
			for c in n[2]:
				var at := [a, b, c]
				var sym := [symbol(0, a), symbol(1, b), symbol(2, c)]
				if coins_for(rules, sym) > 0:
					continue
				var best := 0.0
				for hold in [[0], [1], [2], [0, 1], [0, 2], [1, 2]]:
					best = maxf(best, _held_value(hold, sym, cache))
				values.append(best)
	values.sort()
	values.reverse()
	var q := rules.hold_chance
	var best_r := base
	var sum := 0.0
	for k in values.size():
		sum += values[k]
		best_r = maxf(best_r, (base + q * sum / total) / (1.0 + q * (k + 1) / total))
	return best_r


## The mean coins of a respin holding reels `hold` (their symbols from `sym`).
func _held_value(hold: Array, sym: Array, cache: Dictionary) -> float:
	var key := str(hold) + ":" + ",".join(hold.map(func(r: int) -> String: return String(sym[r])))
	if cache.has(key):
		return cache[key]
	var free: Array = [0, 1, 2].filter(func(r: int) -> bool: return not r in hold)
	var total := 0
	var count := 0
	var line := sym.duplicate()
	if free.size() == 1:
		for x in rules.strips[free[0]]:
			line[free[0]] = x
			total += coins_for(rules, line)
			count += 1
	else:
		for x in rules.strips[free[0]]:
			for y in rules.strips[free[1]]:
				line[free[0]] = x
				line[free[1]] = y
				total += coins_for(rules, line)
				count += 1
	cache[key] = float(total) / float(count)
	return cache[key]


## How often each paytable line comes up (per pull), in paytable order.
func line_odds() -> Array[float]:
	var hits: Array[float] = []
	hits.resize(rules.pays.size())
	hits.fill(0.0)
	var count := 0
	for a in rules.strips[0]:
		for b in rules.strips[1]:
			for c in rules.strips[2]:
				var k := pay_line(rules, [a, b, c])
				if k >= 0:
					hits[k] += 1.0
				count += 1
	for k in hits.size():
		hits[k] /= float(count)
	return hits
