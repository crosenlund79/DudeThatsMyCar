class_name Holdem
extends RefCounted
## M010: one table of No-Limit Texas Hold'em, the rules entire. Pure and
## deterministic (the deck is shuffled from the seed a hand is started with);
## all amounts are whole cents, in multiples of the smallest chip.
##
## A hand: the button moves to the next player with chips; the two players
## after it post the small and big blinds (heads-up the button posts the small
## blind and acts first before the flop, last after it). Two hole cards each,
## dealt one at a time from the left of the button. Four betting rounds -
## pre-flop, the flop (three cards), the turn and the river (one each), a card
## burnt before each - then the showdown. On a round: fold, check (nothing to
## call), call, bet (nothing bet yet; at least the big blind), raise (by at
## least the last full bet or raise this round) or go all-in for whatever is
## left. An all-in short of a full raise does not reopen the betting: a player
## who has already acted may then only call or fold, unless what he now faces
## adds up to a full raise since he acted. A player all-in for less than the
## big blind leaves the others to call the full big blind. Nobody may raise
## when everyone else is all-in. A round ends when every player who can still
## act has acted and matched the bet; a bet nobody matched is handed back.
## When everyone but one has folded he takes the pot without showing; when
## nobody (or only one) can still bet, the board is dealt out. At the
## showdown every pot - the main pot, then a side pot for each all-in level -
## goes to the best five-card hand among the players with a stake in it,
## split evenly on a tie, an odd chip to the first winner left of the button.
## Players without chips are out (bust); players join and leave between hands.

enum { PREFLOP, FLOP, TURN, RIVER, SHOWDOWN, OVER }
const STREET_NAMES := ["pre-flop", "the flop", "the turn", "the river", "the showdown", ""]

var small_blind := 5
var big_blind := 10
## The smallest chip: every bet is a whole number of these (or all-in).
var chip := 5
## Seats in clockwise order: {name, stack, out, busted, in_hand, folded,
## all_in, hole, bet (this round), total (this hand), acted, acted_at, score,
## won} plus whatever the caller sat them down with (style, id).
var seats: Array[Dictionary] = []
var button := -1
var sb_seat := -1
var bb_seat := -1
var street := OVER
var board: Array[int] = []
var deck: Array[int] = []
## The seat whose turn it is (-1: nobody's).
var to_act := -1
## The bet to match this round.
var current_bet := 0
## The last full bet or raise this round: the least a raise may add.
var min_raise := 0
var hand_no := 0
## What happened this hand, in order: {what, seat, amount / to / cards...}.
var events: Array[Dictionary] = []
## The last hand's pots as they were won: {amount, eligible, winners, hand}.
var results: Array[Dictionary] = []
## The last hand went to a showdown (the hands were shown).
var shown := false
var _rng := RandomNumberGenerator.new()


func _init(p_small: int = 5, p_big: int = 10, p_chip: int = 5) -> void:
	small_blind = p_small
	big_blind = p_big
	chip = p_chip


# ------------------------------------------------------------------ seats

## Sits a player down (between hands) in the first empty seat; returns it.
func sit(p_name: String, stack: int, extra: Dictionary = {}) -> int:
	if street != OVER:
		return -1
	var s := {"name": p_name, "stack": stack, "out": false, "busted": false, "in_hand": false, "folded": true,
		"all_in": false, "hole": [], "bet": 0, "total": 0, "acted": false, "acted_at": 0, "score": -1, "won": 0}
	s.merge(extra)
	for i in seats.size():
		if seats[i].out:
			seats[i] = s
			return i
	seats.append(s)
	return seats.size() - 1


## Gets up from the table between hands: the chips he takes with him.
func leave(i: int) -> int:
	if street != OVER or seats[i].out:
		return 0
	var chips: int = seats[i].stack
	seats[i].stack = 0
	seats[i].out = true
	return chips


## The players who can be dealt in: seated, with chips.
func players() -> Array[int]:
	var out: Array[int] = []
	for i in seats.size():
		if not seats[i].out and seats[i].stack > 0:
			out.append(i)
	return out


## Still contending for the pot this hand.
func contenders() -> Array[int]:
	var out: Array[int] = []
	for i in seats.size():
		if seats[i].in_hand and not seats[i].folded:
			out.append(i)
	return out


func can_start() -> bool:
	return street == OVER and players().size() >= 2


func running() -> bool:
	return street <= RIVER


## Every chip on the table: the stacks and what is in the pot.
func total_chips() -> int:
	var t := 0
	for s in seats:
		t += int(s.stack) + int(s.total)
	return t


## Everything in the pot this hand, the bets in front of the players included.
func pot_total() -> int:
	var t := 0
	for s in seats:
		t += int(s.total)
	return t


# ------------------------------------------------------------------ a hand

func start_hand(seed: int) -> bool:
	if not can_start():
		return false
	var dealt := players()
	hand_no += 1
	_rng.seed = seed
	deck = Cards.shuffled(_rng)
	board.clear()
	events.clear()
	results.clear()
	shown = false
	for s in seats:
		s.in_hand = false
		s.folded = true
		s.all_in = false
		s.hole = []
		s.bet = 0
		s.total = 0
		s.acted = false
		s.acted_at = 0
		s.score = -1
		s.won = 0
	for i in dealt:
		seats[i].in_hand = true
		seats[i].folded = false
	var dealt_in := func(i: int) -> bool: return seats[i].in_hand
	button = dealt[0] if button < 0 or button >= seats.size() else _next(button, dealt_in)
	if dealt.size() == 2:
		sb_seat = button
		bb_seat = _next(button, dealt_in)
	else:
		sb_seat = _next(button, dealt_in)
		bb_seat = _next(sb_seat, dealt_in)
	street = PREFLOP
	_post(sb_seat, small_blind, "small blind")
	_post(bb_seat, big_blind, "big blind")
	current_bet = big_blind
	min_raise = big_blind
	for round in 2:
		var i := button
		for k in dealt.size():
			i = _next(i, dealt_in)
			seats[i].hole.append(deck.pop_back())
	to_act = _next(bb_seat, _needs_action)
	if to_act < 0:
		_end_round()
	return true


func _post(i: int, amount: int, what: String) -> void:
	var a := _put(i, amount)
	events.append({"what": what, "seat": i, "amount": a, "all_in": seats[i].all_in})


## Moves up to `amount` from the stack into the pot; what actually went in.
func _put(i: int, amount: int) -> int:
	var s := seats[i]
	var a := mini(amount, int(s.stack))
	s.stack -= a
	s.bet += a
	s.total += a
	if s.stack == 0:
		s.all_in = true
	return a


func _can_act(i: int) -> bool:
	var s := seats[i]
	return s.in_hand and not s.folded and not s.all_in


func _able_count() -> int:
	var n := 0
	for i in seats.size():
		if _can_act(i):
			n += 1
	return n


## The biggest bet this round among the contenders other than i.
func _max_other_bet(i: int) -> int:
	var m := 0
	for j in seats.size():
		if j != i and seats[j].in_hand and not seats[j].folded:
			m = maxi(m, seats[j].bet)
	return m


func _needs_action(i: int) -> bool:
	if not _can_act(i):
		return false
	var s := seats[i]
	if _able_count() == 1 and s.bet >= _max_other_bet(i):
		return false  # everyone else is all-in and he has them covered: nobody to bet against
	return not s.acted or s.bet < current_bet


## Another contender who could still call a raise.
func _others_can_act(i: int) -> bool:
	for j in seats.size():
		if j != i and _can_act(j):
			return true
	return false


## The next seat clockwise from `from` (itself last) that passes the test, or -1.
func _next(from: int, test: Callable) -> int:
	var n := seats.size()
	for k in range(1, n + 1):
		var i := (from + k) % n
		if test.call(i):
			return i
	return -1


## What seat i may do now: {fold, check, call (chips to put in), bet, raise,
## min_to, max_to (the bet totals a bet / raise may make), all_in (his bet
## total all-in, or 0 when he may not go all-in)}.
func legal(i: int) -> Dictionary:
	var out := {"fold": false, "check": false, "call": 0, "bet": false, "raise": false, "min_to": 0, "max_to": 0, "all_in": 0}
	if i != to_act or not running():
		return out
	var s := seats[i]
	var owe := current_bet - int(s.bet)
	var max_to := int(s.bet) + int(s.stack)
	out.fold = true
	out.check = owe <= 0
	out.call = mini(owe, s.stack) if owe > 0 else 0
	var reopened: bool = not s.acted or current_bet - int(s.acted_at) >= min_raise
	if s.stack > owe and reopened and _others_can_act(i):
		out.bet = current_bet == 0
		out.raise = current_bet > 0
		var least := current_bet + min_raise if current_bet > 0 else big_blind
		out.min_to = mini(least, max_to)  # all-in for less is always allowed
		out.max_to = max_to
		out.all_in = max_to
	elif owe > 0 and s.stack <= owe:
		out.all_in = max_to  # all-in to call
	return out


## Seat i acts: "fold", "check", "call", "bet" / "raise" (to a bet total), or
## "all_in". False (nothing happens) when it is not his turn or not allowed.
func act(i: int, kind: String, to: int = 0) -> bool:
	var l := legal(i)
	if not l.fold:
		return false
	var s := seats[i]
	match kind:
		"fold":
			s.folded = true
			events.append({"what": "fold", "seat": i})
		"check":
			if not l.check:
				return false
			events.append({"what": "check", "seat": i})
		"call":
			if l.check:
				return false
			var a := _put(i, l.call)
			events.append({"what": "call", "seat": i, "amount": a, "to": s.bet, "all_in": s.all_in})
		"bet", "raise":
			if not (l.bet if kind == "bet" else l.raise):
				return false
			if to < l.min_to or to > l.max_to or (to % chip != 0 and to != l.max_to):
				return false
			_raise_to(i, to, kind)
		"all_in":
			if l.all_in <= 0:
				return false
			if l.all_in > current_bet:
				_raise_to(i, l.all_in, "bet" if current_bet == 0 else "raise")
			else:
				var a2 := _put(i, l.call)
				events.append({"what": "call", "seat": i, "amount": a2, "to": s.bet, "all_in": true})
		_:
			return false
	s.acted = true
	s.acted_at = current_bet
	_after_action(i)
	return true


func _raise_to(i: int, to: int, kind: String) -> void:
	var s := seats[i]
	var by := to - current_bet
	var full := by >= min_raise
	_put(i, to - int(s.bet))
	if full:
		min_raise = by
		for j in seats.size():
			if j != i:
				seats[j].acted = false  # a full raise reopens the betting for everyone
	current_bet = maxi(current_bet, to)
	events.append({"what": kind, "seat": i, "to": to, "all_in": s.all_in, "full": full})


## Leaving mid-hand: he folds at once, whoever's turn it is.
func fold_out(i: int) -> void:
	if not running() or not seats[i].in_hand or seats[i].folded:
		return
	seats[i].folded = true
	events.append({"what": "fold", "seat": i})
	if contenders().size() == 1:
		_finish_uncontested()
		return
	if to_act < 0 or to_act == i or not _needs_action(to_act):
		var from := to_act
		to_act = _next(from, _needs_action)
		if to_act < 0:
			_end_round()


func _after_action(i: int) -> void:
	if contenders().size() == 1:
		_finish_uncontested()
		return
	to_act = _next(i, _needs_action)
	if to_act < 0:
		_end_round()


## A bet nobody matched goes back to whoever made it.
func _refund_uncalled() -> void:
	var top := -1
	for i in seats.size():
		if seats[i].bet > 0 and (top < 0 or seats[i].bet > seats[top].bet):
			top = i
	if top < 0:
		return
	var second := 0
	for i in seats.size():
		if i != top:
			second = maxi(second, seats[i].bet)
	var back: int = seats[top].bet - second
	if back > 0:
		seats[top].stack += back
		seats[top].bet -= back
		seats[top].total -= back
		seats[top].all_in = false
		events.append({"what": "returned", "seat": top, "amount": back})


func _end_round() -> void:
	_refund_uncalled()
	for s in seats:
		s.bet = 0
		s.acted = false
		s.acted_at = 0
	current_bet = 0
	min_raise = big_blind
	to_act = -1
	if street == RIVER:
		_showdown()
		return
	street += 1
	deck.pop_back()  # the burn card
	var cards: Array[int] = []
	for k in (3 if street == FLOP else 1):
		cards.append(deck.pop_back())
	board.append_array(cards)
	events.append({"what": "deal", "street": street, "cards": cards})
	to_act = _next(button, _needs_action)
	if to_act < 0:
		_end_round()  # nobody left to bet: the board is dealt out


func _finish_uncontested() -> void:
	_refund_uncalled()
	var w: int = contenders()[0]
	var amount := pot_total()
	results.append({"amount": amount, "eligible": [w], "winners": [w], "hand": ""})
	seats[w].stack += amount
	seats[w].won += amount
	events.append({"what": "win", "seat": w, "amount": amount, "hand": ""})
	_close_hand()


## The pots as they stand: the main pot first, then a side pot for each
## all-in level, each with the contenders who have a stake in it.
func pots() -> Array[Dictionary]:
	var levels: Array[int] = []
	for i in contenders():
		var t: int = seats[i].total
		if t > 0 and not levels.has(t):
			levels.append(t)
	levels.sort()
	var out: Array[Dictionary] = []
	var prev := 0
	for lvl in levels:
		var amount := 0
		for s in seats:
			amount += clampi(int(s.total) - prev, 0, lvl - prev)
		var eligible: Array[int] = []
		for i in contenders():
			if seats[i].total >= lvl:
				eligible.append(i)
		if amount > 0:
			out.append({"amount": amount, "eligible": eligible})
		prev = lvl
	var left := 0
	for s in seats:
		left += maxi(0, int(s.total) - prev)
	if left > 0 and not out.is_empty():
		out.back().amount += left
	return out


func _showdown() -> void:
	street = SHOWDOWN
	shown = true
	for i in contenders():
		seats[i].score = HandRank.score(seats[i].hole + board)
	for pot in pots():
		var best := -1
		var winners: Array[int] = []
		for i in pot.eligible:
			if seats[i].score > best:
				best = seats[i].score
				winners = [i]
			elif seats[i].score == best:
				winners.append(i)
		_split(pot.amount, winners)
		results.append({"amount": pot.amount, "eligible": pot.eligible, "winners": winners, "hand": HandRank.describe(best)})
	_close_hand()


## Shares a pot among the winners in whole chips; the odd chip(s) to the first
## winners clockwise from the button.
func _split(amount: int, winners: Array[int]) -> void:
	var order: Array[int] = []
	var i := button
	for k in seats.size():
		i = (i + 1) % seats.size()
		if winners.has(i):
			order.append(i)
	var units := amount / chip
	var spare := amount - units * chip  # never, while every bet is whole chips
	var share := (units / order.size()) * chip
	var odd := units % order.size()
	for k in order.size():
		var w := order[k]
		var got := share + (chip if k < odd else 0) + (spare if k == 0 else 0)
		seats[w].stack += got
		seats[w].won += got
		events.append({"what": "win", "seat": w, "amount": got, "hand": HandRank.describe(seats[w].score)})


func _close_hand() -> void:
	for s in seats:
		s.total = 0
		s.bet = 0
		if s.in_hand and s.stack == 0 and not s.out:
			s.out = true
			s.busted = true
	street = OVER
	to_act = -1
