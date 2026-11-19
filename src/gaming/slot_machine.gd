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


func _init(p_rules: SlotRules) -> void:
	rules = p_rules


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
	if money < rules.coin:
		return "You haven't %s for the slot." % ("a nickel" if rules.coin == 5 else ("a dime" if rules.coin == 10 else Rackets.dollars(rules.coin)))
	return ""


## The lever is pulled: the coin goes in and each reel's stop is drawn from
## `seed` - decided here, once. Returns the cents taken (0: refused).
func pull(money: int, seed: int) -> int:
	if cannot_pull(money) != "":
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for r in 3:
		stops[r] = rng.randi_range(0, rules.strips[r].size() - 1)
	win = coins_for(rules, line()) * rules.coin
	pending = true
	pulls += 1
	taken_total += rules.coin
	return rules.coin


## The reels have stopped: the win paid, once. Returns the cents paid (0 a second time).
func collect() -> int:
	if not pending:
		return 0
	pending = false
	paid_total += win
	return win


## What a save should count on top of Danny's pocket: a pull under way is decided, so its win.
func for_save() -> int:
	return win if pending else 0


## Danny walks away: a pull under way is paid at once.
func walk_away() -> int:
	return collect()


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
