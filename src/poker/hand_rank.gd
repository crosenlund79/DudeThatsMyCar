class_name HandRank
extends RefCounted
## M010: the best five-card poker hand out of five, six or seven cards, as one
## comparable number (higher wins, equal ties), with its name and the five
## cards it uses. Every ranking: high card, one pair, two pair, three of a
## kind, a straight (the wheel A-2-3-4-5 is the lowest, A-K-Q-J-10 the
## highest; no wrapping round), a flush, a full house, four of a kind, a
## straight flush (the royal flush is the ace-high one). Kickers decide
## between equal hands; suits never do. Pure.

enum { HIGH_CARD, PAIR, TWO_PAIR, TRIPS, STRAIGHT, FLUSH, FULL_HOUSE, QUADS, STRAIGHT_FLUSH }

const CATEGORY_NAMES := ["high card", "one pair", "two pair", "three of a kind", "a straight", "a flush",
	"a full house", "four of a kind", "a straight flush"]


static func category(score: int) -> int:
	return score >> 20


## The score of the best five of these cards: the category in the top bits,
## then up to five ranks (most significant first) of 4 bits each.
static func score(cards: Array) -> int:
	var counts := PackedInt32Array()
	counts.resize(13)
	var suit_masks := PackedInt32Array([0, 0, 0, 0])
	var suit_counts := PackedInt32Array([0, 0, 0, 0])
	var mask := 0
	for c in cards:
		var r: int = c % 13
		var s: int = c / 13
		counts[r] += 1
		suit_masks[s] |= 1 << r
		suit_counts[s] += 1
		mask |= 1 << r
	# straight flush / flush
	var flush_suit := -1
	for s in 4:
		if suit_counts[s] >= 5:
			flush_suit = s
	if flush_suit >= 0:
		var sf := _straight_high(suit_masks[flush_suit])
		if sf >= 0:
			return _pack(STRAIGHT_FLUSH, [sf])
	var quads := -1
	var trips: Array[int] = []
	var pairs: Array[int] = []
	for r in range(12, -1, -1):
		match counts[r]:
			4:
				quads = r
			3:
				trips.append(r)
			2:
				pairs.append(r)
	if quads >= 0:
		return _pack(QUADS, [quads, _top(mask & ~(1 << quads), 1)[0]])
	if trips.size() >= 1 and (trips.size() >= 2 or pairs.size() >= 1):
		var pair_rank := pairs[0] if pairs.size() > 0 else -1
		if trips.size() >= 2:
			pair_rank = maxi(pair_rank, trips[1])
		return _pack(FULL_HOUSE, [trips[0], pair_rank])
	if flush_suit >= 0:
		return _pack(FLUSH, _top(suit_masks[flush_suit], 5))
	var st := _straight_high(mask)
	if st >= 0:
		return _pack(STRAIGHT, [st])
	if trips.size() == 1:
		return _pack(TRIPS, [trips[0]] + _top(mask & ~(1 << trips[0]), 2))
	if pairs.size() >= 2:
		var rest := mask & ~(1 << pairs[0]) & ~(1 << pairs[1])
		return _pack(TWO_PAIR, [pairs[0], pairs[1]] + _top(rest, 1))
	if pairs.size() == 1:
		return _pack(PAIR, [pairs[0]] + _top(mask & ~(1 << pairs[0]), 3))
	return _pack(HIGH_CARD, _top(mask, 5))


## The highest card of the highest straight in a mask of ranks, or -1. The
## wheel (A-2-3-4-5) counts as five-high.
static func _straight_high(mask: int) -> int:
	for high in range(12, 3, -1):
		var run := 0b11111 << (high - 4)
		if mask & run == run:
			return high
	if mask & 0b1000000001111 == 0b1000000001111:
		return 3  # the wheel: five-high
	return -1


## The n highest ranks in a mask, highest first.
static func _top(mask: int, n: int) -> Array[int]:
	var out: Array[int] = []
	for r in range(12, -1, -1):
		if out.size() >= n:
			break
		if mask & (1 << r):
			out.append(r)
	return out


static func _pack(cat: int, ranks: Array) -> int:
	var v := cat
	for i in 5:
		v = (v << 4) | (int(ranks[i]) if i < ranks.size() else 0)
	return v


## The ranks packed into a score, most significant first.
static func ranks_of(p_score: int) -> Array[int]:
	var out: Array[int] = []
	for i in 5:
		out.append((p_score >> (16 - i * 4)) & 0xF)
	return out


## The hand's name as the table says it: "a pair of jacks", "two pair, kings
## and sevens", "a flush, ace high", "a straight, five high", "a royal flush".
static func describe(p_score: int) -> String:
	var r := ranks_of(p_score)
	match category(p_score):
		STRAIGHT_FLUSH:
			return "a royal flush" if r[0] == 12 else "a straight flush, %s high" % Cards.RANK_NAMES[r[0]]
		QUADS:
			return "four %s" % Cards.RANK_PLURALS[r[0]]
		FULL_HOUSE:
			return "a full house, %s over %s" % [Cards.RANK_PLURALS[r[0]], Cards.RANK_PLURALS[r[1]]]
		FLUSH:
			return "a flush, %s high" % Cards.RANK_NAMES[r[0]]
		STRAIGHT:
			return "a straight, %s high" % Cards.RANK_NAMES[r[0]]
		TRIPS:
			return "three %s" % Cards.RANK_PLURALS[r[0]]
		TWO_PAIR:
			return "two pair, %s and %s" % [Cards.RANK_PLURALS[r[0]], Cards.RANK_PLURALS[r[1]]]
		PAIR:
			return "a pair of %s" % Cards.RANK_PLURALS[r[0]]
	return "%s high" % Cards.RANK_NAMES[r[0]]


## The five cards that make the best hand (for showing it at the showdown).
static func best_five(cards: Array) -> Array[int]:
	var target := score(cards)
	var n := cards.size()
	if n <= 5:
		var all: Array[int] = []
		all.assign(cards)
		return all
	# every way of leaving out n - 5 cards
	for a in n:
		for b in range(a + 1, n) if n == 7 else [n]:
			var five: Array[int] = []
			for i in n:
				if i != a and i != b:
					five.append(cards[i])
			if five.size() == 5 and score(five) == target:
				return five
	var fallback: Array[int] = []
	fallback.assign(cards.slice(0, 5))
	return fallback
