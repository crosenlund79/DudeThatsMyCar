class_name PokerBrain
extends RefCounted
## M010: how the Copper Owl's card players decide - simply, but never against
## the rules (every choice goes through Holdem.legal). Each estimates his
## chance of winning from his cards and the board (a short simulation against
## as many random hands as there are players left in), weighs it against the
## pot odds of a call and the size of the bet, and plays to his style:
## cautious (plays few hands, rarely bluffs, small bets), aggressive (plays
## more, raises and bluffs often, bets big), loose (calls too much, raises
## little). Deterministic for a given generator. No solver; no reads.

const STYLES := {
	# play_at / raise_at: strength against an average hand at this table (1.0)
	# to stay in pre-flop / to bet or raise; slack: calls this much worse than
	# the pot odds; bluff: chance of betting with nothing; size: bet as a share of the pot
	"cautious": {"play_at": 1.2, "raise_at": 1.8, "slack": 0.0, "bluff": 0.02, "size": 0.55},
	"aggressive": {"play_at": 0.95, "raise_at": 1.35, "slack": 0.04, "bluff": 0.16, "size": 0.85},
	"loose": {"play_at": 0.7, "raise_at": 1.75, "slack": 0.12, "bluff": 0.06, "size": 0.5},
}
const SAMPLES := 90


## His chance of winning (ties shared) against `opponents` random hands.
static func equity(hole: Array, board: Array, opponents: int, rng: RandomNumberGenerator, samples: int = SAMPLES) -> float:
	if opponents <= 0:
		return 1.0
	var known := {}
	for c in hole + board:
		known[c] = true
	var rest: Array[int] = []
	for c in 52:
		if not known.has(c):
			rest.append(c)
	var need := 5 - board.size() + opponents * 2
	var won := 0.0
	for k in samples:
		# a partial shuffle: the first `need` cards of `rest`
		for i in need:
			var j := rng.randi_range(i, rest.size() - 1)
			var t := rest[i]
			rest[i] = rest[j]
			rest[j] = t
		var full_board: Array = board.duplicate()
		for i in 5 - board.size():
			full_board.append(rest[i])
		var mine := HandRank.score(hole + full_board)
		var at := 5 - board.size()
		var best_other := -1
		var ties := 0
		for o in opponents:
			var s := HandRank.score([rest[at], rest[at + 1]] + full_board)
			at += 2
			if s > best_other:
				best_other = s
				ties = 0
			if s == best_other:
				ties += 1
		if mine > best_other:
			won += 1.0
		elif mine == best_other:
			won += 1.0 / float(ties + 1)
	return won / float(samples)


## What seat i does now: {kind, to}.
static func decide(game: Holdem, i: int, style: String, rng: RandomNumberGenerator) -> Dictionary:
	var l := game.legal(i)
	if not l.fold:
		return {}
	var st: Dictionary = STYLES.get(style, STYLES.cautious)
	var s: Dictionary = game.seats[i]
	var opponents := game.contenders().size() - 1
	var e := equity(s.hole, game.board, opponents, rng)
	var strength := e * float(opponents + 1)  # 1.0: an average hand against this many
	var owe: int = l.call
	var pot := game.pot_total()
	var odds := float(owe) / float(pot + owe) if owe > 0 else 0.0
	var preflop := game.street == Holdem.PREFLOP
	var roll := rng.randf()
	if l.bet or l.raise:
		var bluffing: bool = roll < st.bluff and opponents <= 2 and owe <= game.big_blind * 2
		if strength >= st.raise_at or bluffing:
			var size := int(float(pot + owe) * st.size)
			var to: int = game.current_bet + maxi(game.min_raise, size)
			to = int(round(float(to) / game.chip)) * game.chip
			to = clampi(to, l.min_to, l.max_to)
			if to >= int(0.75 * float(l.max_to)):
				return {"kind": "all_in", "to": l.max_to}
			return {"kind": "bet" if l.bet else "raise", "to": to}
	if l.check:
		return {"kind": "check", "to": 0}
	var worth: bool = e + st.slack >= odds
	if preflop:
		# before the flop the pot odds against several random hands mislead: he
		# plays the hands good enough for his style, fewer the dearer the call
		var cheap := owe <= game.big_blind
		worth = strength >= st.play_at - (0.3 if cheap else 0.0) + odds * 0.8
	if worth:
		return {"kind": "all_in" if owe >= s.stack else "call", "to": 0}
	return {"kind": "fold", "to": 0}
