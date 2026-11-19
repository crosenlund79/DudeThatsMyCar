class_name Roulette
extends RefCounted
## The gaming room's wheel (pure, no scene): single-zero European roulette by
## the standard rules, and one round of it at a time - Danny's chips on the
## layout, the spin, the settling.
##
## The wheel: 0 to 36, one zero, the pockets in the standard European order.
## Inside bets: a number (35 to 1), a split of two neighbours on the layout
## (17 to 1), a street of three (11 to 1; also 0-1-2 and 0-2-3), a corner of
## four (8 to 1; also 0-1-2-3), a line of six (5 to 1). Outside bets: red or
## black, odd or even, 1-18 or 19-36 (1 to 1), a dozen or a column (2 to 1).
## The zero loses every outside bet (no "la partage").
##
## Money: placing a chip takes it from Danny there and then (`place` returns
## what it took, and refuses rather than overdraw); before the spin a chip can
## be taken back (`remove`, `clear`). The spin decides the number once, at
## its start, from a fair draw (every pocket 1 in 37) - the wheel on screen
## only shows it. `settle` pays once: each winning bet its stake and its
## winnings; then the round is over and the next can begin. No house edge
## beyond the zero, nothing hidden.
##
## A bet's key: "straight:17", "split:17-20", "street:16-17-18", "corner:16-17-19-20",
## "line:16-17-18-19-20-21", "red", "black", "odd", "even", "low", "high",
## "dozen:1".."dozen:3", "column:1".."column:3" (column 1 holds 1, 4, ... 34).

enum Phase { BETTING, SPINNING, SETTLED }

## Clockwise round the wheel from the zero.
const WHEEL := [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31,
	9, 22, 18, 29, 7, 28, 12, 35, 3, 26]
const REDS := [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
## What each kind of bet pays, to 1.
const PAYS := {"straight": 35, "split": 17, "street": 11, "corner": 8, "line": 5, "dozen": 2, "column": 2,
	"red": 1, "black": 1, "odd": 1, "even": 1, "low": 1, "high": 1}
const INSIDE := ["straight", "split", "street", "corner", "line"]
const OUTSIDE_WORDS := {"red": "Red", "black": "Black", "odd": "Odd", "even": "Even", "low": "1-18", "high": "19-36"}

var rules: RouletteRules
var phase := Phase.BETTING
## Danny's bets this round: key -> cents.
var bets := {}
## The number the wheel gives this round (-1 before the spin).
var result := -1
## What the last settling paid back (stakes and winnings) and what was staked.
var paid := 0
var staked := 0
## The last numbers to come up, newest first.
var history: Array[int] = []
## Spins so far.
var spins := 0
## The bets of the last spin (for "same again").
var last_bets := {}


func _init(p_rules: RouletteRules = null) -> void:
	rules = p_rules if p_rules != null else RouletteRules.new()


# ------------------------------------------------------------------ the rules

static func colour(n: int) -> String:
	if n == 0:
		return "green"
	return "red" if n in REDS else "black"


## The kind of a bet from its key ("split:17-20" -> "split").
static func kind_of(key: String) -> String:
	return key.get_slice(":", 0)


## The numbers a bet covers ([] if the key is not a bet on this table).
static func covers(key: String) -> Array[int]:
	var kind := kind_of(key)
	var out: Array[int] = []
	match kind:
		"red", "black", "odd", "even", "low", "high":
			if key != kind:
				return out
			for n in range(1, 37):
				var hit := false
				match kind:
					"red":
						hit = n in REDS
					"black":
						hit = not n in REDS
					"odd":
						hit = n % 2 == 1
					"even":
						hit = n % 2 == 0
					"low":
						hit = n <= 18
					"high":
						hit = n >= 19
				if hit:
					out.append(n)
			return out
		"dozen", "column":
			var k := key.get_slice(":", 1).to_int()
			if key.get_slice_count(":") != 2 or k < 1 or k > 3:
				return out
			for n in range(1, 37):
				if (kind == "dozen" and (n - 1) / 12 + 1 == k) or (kind == "column" and (n - 1) % 3 + 1 == k):
					out.append(n)
			return out
	if not kind in INSIDE or key.get_slice_count(":") != 2:
		return out
	var nums: Array[int] = []
	for part in key.get_slice(":", 1).split("-"):
		if not part.is_valid_int():
			return out
		nums.append(part.to_int())
	nums.sort()
	if _inside_shape_ok(kind, nums):
		return nums
	return out


static func _inside_shape_ok(kind: String, n: Array[int]) -> bool:
	for x in n:
		if x < 0 or x > 36:
			return false
	for i in range(1, n.size()):
		if n[i] == n[i - 1]:
			return false
	match kind:
		"straight":
			return n.size() == 1
		"split":
			if n.size() != 2:
				return false
			if n[0] == 0:
				return n[1] <= 3
			return (n[1] == n[0] + 1 and n[0] % 3 != 0) or n[1] == n[0] + 3
		"street":
			if n.size() != 3:
				return false
			if n == [0, 1, 2] or n == [0, 2, 3]:
				return true
			return n[0] >= 1 and n[0] % 3 == 1 and n[1] == n[0] + 1 and n[2] == n[0] + 2
		"corner":
			if n.size() != 4:
				return false
			if n == [0, 1, 2, 3]:
				return true
			return n[0] >= 1 and n[0] % 3 != 0 and n[0] <= 32 and n == [n[0], n[0] + 1, n[0] + 3, n[0] + 4]
		"line":
			if n.size() != 6:
				return false
			if n[0] < 1 or n[0] % 3 != 1 or n[0] > 31:
				return false
			for i in 6:
				if n[i] != n[0] + i:
					return false
			return true
	return false


static func valid(key: String) -> bool:
	return not covers(key).is_empty()


## A bet's key made tidy (numbers in order), or "" if it is no bet.
static func normal(key: String) -> String:
	var kind := kind_of(key)
	if not valid(key):
		return ""
	if kind in INSIDE:
		return "%s:%s" % [kind, "-".join(covers(key).map(func(x: int) -> String: return str(x)))]
	return key


static func pays(key: String) -> int:
	return int(PAYS.get(kind_of(key), 0))


static func wins(key: String, number: int) -> bool:
	return number in covers(key)


## What a bet of `stake` returns when `number` comes up: stake and winnings, or nothing.
static func returns(key: String, stake: int, number: int) -> int:
	return stake * (pays(key) + 1) if wins(key, number) else 0


## The bet in words ("17", "Split 17-20", "Red", "2nd dozen").
static func words(key: String) -> String:
	var kind := kind_of(key)
	if OUTSIDE_WORDS.has(kind):
		return OUTSIDE_WORDS[kind]
	var nth: String = ["", "1st", "2nd", "3rd"][clampi(key.get_slice(":", 1).to_int(), 0, 3)] if key.contains(":") else ""
	match kind:
		"dozen":
			return "%s dozen" % nth
		"column":
			return "%s column" % nth
		"straight":
			return "Number %d" % covers(key)[0]
	var nums := "-".join(covers(key).map(func(x: int) -> String: return str(x)))
	return "%s %s" % [{"split": "Split", "street": "Street", "corner": "Corner", "line": "Line"}[kind], nums]


## The most this table takes on one bet of this kind.
func limit(key: String) -> int:
	var kind := kind_of(key)
	if kind == "straight":
		return rules.max_straight
	return rules.max_inside if kind in INSIDE else rules.max_outside


# ------------------------------------------------------------------ a round

func total_staked() -> int:
	var t := 0
	for k in bets:
		t += int(bets[k])
	return t


## Why a chip cannot go on this bet now ("" when it can).
func refuse(key: String, chip: int, money: int) -> String:
	if phase != Phase.BETTING:
		return "No more bets."
	if not chip in rules.chips:
		return "The croupier doesn't sell that chip."
	var k := normal(key)
	if k == "":
		return "That's not a bet on this table."
	if chip > money:
		return "You haven't the money for that chip."
	if int(bets.get(k, 0)) + chip > limit(k):
		return "The table takes no more than %s on that." % Rackets.dollars(limit(k))
	if total_staked() + chip > rules.max_total:
		return "The table takes no more than %s a spin." % Rackets.dollars(rules.max_total)
	return ""


## Puts a chip on a bet. Returns the cents taken from Danny (0: refused).
func place(key: String, chip: int, money: int) -> int:
	if refuse(key, chip, money) != "":
		return 0
	var k := normal(key)
	bets[k] = int(bets.get(k, 0)) + chip
	return chip


## Takes up to `chip` back off a bet before the spin. Returns the cents given back.
func remove(key: String, chip: int) -> int:
	var k := normal(key)
	if phase != Phase.BETTING or k == "" or not bets.has(k):
		return 0
	var back := mini(chip, int(bets[k]))
	bets[k] = int(bets[k]) - back
	if int(bets[k]) <= 0:
		bets.erase(k)
	return back


## Takes every chip back off the layout before the spin. Returns the cents given back.
func clear() -> int:
	if phase != Phase.BETTING:
		return 0
	var back := total_staked()
	bets.clear()
	return back


## Why the wheel cannot be spun now ("" when it can).
func cannot_spin() -> String:
	if phase != Phase.BETTING:
		return "The wheel's already turning."
	if bets.is_empty():
		return "Place a bet first."
	for k in bets:
		if int(bets[k]) < rules.min_bet:
			return "%s is under the table's %s." % [words(k), Rackets.dollars(rules.min_bet)]
	return ""


## No more bets: the wheel is spun and the number decided, once, from a fair
## draw seeded by `seed` (every pocket alike). Returns the number (-1: refused).
func spin(seed: int) -> int:
	if cannot_spin() != "":
		return -1
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	result = rng.randi_range(0, 36)
	staked = total_staked()
	last_bets = bets.duplicate()
	spins += 1
	phase = Phase.SPINNING
	return result


## The ball has dropped: every bet is settled once. Returns the cents paid
## back to Danny (stakes and winnings of the winning bets; 0 a second time).
func settle() -> int:
	if phase != Phase.SPINNING:
		return 0
	paid = 0
	for k in bets:
		paid += returns(k, int(bets[k]), result)
	phase = Phase.SETTLED
	history.push_front(result)
	if history.size() > 12:
		history.resize(12)
	return paid


## The bets that won this round.
func winning_bets() -> Array[String]:
	var out: Array[String] = []
	if result < 0:
		return out
	for k in bets:
		if wins(k, result):
			out.append(k)
	return out


## Puts the last spin's bets down again (a fresh round, nothing on the
## layout yet). Returns the cents taken (0: not now, or not enough money).
func repeat(money: int) -> int:
	if phase != Phase.BETTING or not bets.is_empty() or last_bets.is_empty():
		return 0
	var total := 0
	for k in last_bets:
		total += int(last_bets[k])
	if total > money or total > rules.max_total:
		return 0
	bets = last_bets.duplicate()
	return total


## The next round: the layout cleared (after settling).
func new_round() -> void:
	if phase == Phase.SPINNING:
		return
	if phase == Phase.BETTING and not bets.is_empty():
		return  # the chips are still Danny's: clear() them back first
	bets.clear()
	result = -1
	paid = 0
	staked = 0
	phase = Phase.BETTING


## What Danny's money should be counted as if the game were saved now, on
## top of what is in his pocket: chips on the layout come back to him before
## the spin; once the wheel is spun the number is decided, so the round counts
## as settled; after settling, nothing is owed either way.
func for_save() -> int:
	match phase:
		Phase.BETTING:
			return total_staked()
		Phase.SPINNING:
			var back := 0
			for k in bets:
				back += returns(k, int(bets[k]), result)
			return back
	return 0


## Danny walks away from the table: bets not yet spun come back; a spin under
## way is settled at once. Returns the cents owed to him.
func walk_away() -> int:
	var back := 0
	if phase == Phase.BETTING:
		back = clear()
	elif phase == Phase.SPINNING:
		back = settle()
	new_round()
	return back


## Where pocket `number` sits round the wheel (its index clockwise from the zero).
static func pocket_index(number: int) -> int:
	return WHEEL.find(number)
