class_name PokerShowdown
extends RefCounted
## M015: what the card table on screen marks, worked out from the table as it
## stands (pure; presentation only - no chip, card or rule is touched):
##   * the community cards just dealt - the three of the flop, the turn, the
##     river - while their beat waits for Space;
##   * at the showdown, every hand still in (folded hands never): its best five
##     cards of the seven and the hand's name; a winner's five (every winner
##     of a split pot, or of any side pot) strongly, a loser's subtly.

const WIN := "win"
const BEST := "best"
const FRESH := "fresh"


## The board's indexes dealt by the beat on show ([] unless it is a deal).
static func fresh_board(beat: Dictionary) -> Array[int]:
	var out: Array[int] = []
	if String(beat.get("kind", "")) != "deal":
		return out
	var shown := int(beat.get("shown", 0))
	var n := (beat.get("cards", []) as Array).size()
	for k in range(maxi(0, shown - n), shown):
		out.append(k)
	return out


## The showdown's hands: {seat: {"five": [card codes], "name": "two pair, ...",
## "winner": bool}} for every hand still in at a showdown ({} when there was
## none: everyone else folded, or the hand is not over).
static func hands(t: Holdem) -> Dictionary:
	var out := {}
	if not t.shown or t.board.size() < 5:
		return out
	var winners := {}
	for r in t.results:
		for w in r.winners:
			winners[int(w)] = true
	for i in t.seats.size():
		var s: Dictionary = t.seats[i]
		if not s.in_hand or s.folded:
			continue
		var cards: Array = (s.hole as Array) + t.board
		out[i] = {"five": HandRank.best_five(cards), "name": HandRank.describe(HandRank.score(cards)),
			"winner": winners.has(i)}
	return out


## How each board card is marked at the showdown: WIN if it is in a winner's
## five, BEST if only in a loser's, "" if in nobody's.
static func board_marks(t: Holdem, shown_hands: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for c in t.board:
		out.append(card_mark(c, shown_hands, -1))
	return out


## How a card is marked: for `seat`'s own hole card, by his hand alone; for a
## board card (seat -1), by everyone's (a winner's mark first).
static func card_mark(c: int, shown_hands: Dictionary, seat: int) -> String:
	var mark := ""
	for i in shown_hands:
		if seat >= 0 and int(i) != seat:
			continue
		var h: Dictionary = shown_hands[i]
		if c in (h.five as Array):
			if bool(h.winner):
				return WIN
			mark = BEST
	return mark
