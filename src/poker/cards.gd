class_name Cards
extends RefCounted
## M010: a standard 52-card deck as integers 0..51 - rank = c % 13 (0 is a
## deuce, 12 an ace), suit = c / 13 (spades, hearts, diamonds, clubs). Pure.

const RANKS := "23456789TJQKA"
const SUITS := "shdc"
const RANK_NAMES := ["deuce", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
	"jack", "queen", "king", "ace"]
const RANK_PLURALS := ["deuces", "threes", "fours", "fives", "sixes", "sevens", "eights", "nines", "tens",
	"jacks", "queens", "kings", "aces"]
const SUIT_NAMES := ["spades", "hearts", "diamonds", "clubs"]
## Face letters as printed on the cards.
const FACES := ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]


static func rank(c: int) -> int:
	return c % 13


static func suit(c: int) -> int:
	return c / 13


static func make(p_rank: int, p_suit: int) -> int:
	return p_suit * 13 + p_rank


## "As", "Td", "7c".
static func code(c: int) -> String:
	return RANKS[rank(c)] + SUITS[suit(c)]


## A card from its code ("As", "Td").
static func parse(s: String) -> int:
	return make(RANKS.find(s[0].to_upper()), SUITS.find(s[1].to_lower()))


static func parse_all(s: String) -> Array[int]:
	var out: Array[int] = []
	for part in s.split(" ", false):
		out.append(parse(part))
	return out


## "the ace of spades".
static func spoken(c: int) -> String:
	return "the %s of %s" % [RANK_NAMES[rank(c)], SUIT_NAMES[suit(c)]]


## A fresh deck in a random order (Fisher-Yates with the given generator).
static func shuffled(rng: RandomNumberGenerator) -> Array[int]:
	var deck: Array[int] = []
	for c in 52:
		deck.append(c)
	for i in range(51, 0, -1):
		var j := rng.randi_range(0, i)
		var t := deck[i]
		deck[i] = deck[j]
		deck[j] = t
	return deck
