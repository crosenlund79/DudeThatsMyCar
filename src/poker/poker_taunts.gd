class_name PokerTaunts
extends RefCounted
## M013: hooks for recorded card-table taunts, later (pure data; nothing is
## recorded or synthesised now, and nothing is said aloud unless a recording
## is there). Each card player has a few lines for a few situations, each with
## an id, the words, and a delivery note for whoever records it (a performance
## script, never shown in the game): docs/POKER_TAUNTS.md is the draft for a
## recording session. A recording goes under its voice name -
## voice/poker/<id> - in custom/audio/ (or shipped with the game), like every
## sound; the game plays it if it is there, once in a while, and not over
## another voice.
##
## situation(): what a shown beat means for whom - "fold", "raise", "bluff"
## (betting or raising with nothing made yet - known to him, not to the
## table), "win", "lose", "complain" (a big pot lost at the showdown) and
## "at_danny" (Danny takes a pot off him). pick(): a line for that.

const SITUATIONS := ["fold", "raise", "bluff", "win", "lose", "complain", "at_danny"]

const LINES := {
	"irv": {
		"fold": [{"id": "irv_fold_1", "text": "Too rich for a careful man.", "note": "dry, closing his cards with one finger"}],
		"raise": [{"id": "irv_raise_1", "text": "I'll make it a little dearer.", "note": "quiet, almost apologetic"}],
		"bluff": [{"id": "irv_bluff_1", "text": "Numbers don't lie. Mostly.", "note": "a thin smile, not looking up"}],
		"win": [{"id": "irv_win_1", "text": "Into the ledger it goes.", "note": "satisfied, stacking chips neatly"}],
		"lose": [{"id": "irv_lose_1", "text": "Hm. A rounding error.", "note": "pained, under his breath"}],
		"complain": [{"id": "irv_complain_1", "text": "The odds on that were eleven to one. Eleven!", "note": "aggrieved, tapping the table"}],
		"at_danny": [{"id": "irv_danny_1", "text": "You play loose for a man in your line, Mercer.", "note": "polite, wary"}],
	},
	"red": {
		"fold": [{"id": "red_fold_1", "text": "Bah. Take it.", "note": "gruff, tossing the cards"}],
		"raise": [{"id": "red_raise_1", "text": "Raise. Let's see some spine.", "note": "loud, leaning over the table"},
			{"id": "red_raise_2", "text": "That's my money talking.", "note": "a growl, chips slapped down"}],
		"bluff": [{"id": "red_bluff_1", "text": "Go on. Call me. I dare ya.", "note": "too loud, grinning"}],
		"win": [{"id": "red_win_1", "text": "Come to papa!", "note": "a bark of a laugh, raking the pot"}],
		"lose": [{"id": "red_lose_1", "text": "Lousy cards all night.", "note": "sour, low"}],
		"complain": [{"id": "red_complain_1", "text": "On the river? Somebody's dealing from the bottom!", "note": "furious, half out of his chair"}],
		"at_danny": [{"id": "red_danny_1", "text": "Rourke pay you to rob honest workingmen too?", "note": "needling, half a joke"}],
	},
	"pete": {
		"fold": [{"id": "pete_fold_1", "text": "Next stop, the next hand!", "note": "cheerful, a conductor's call"}],
		"raise": [{"id": "pete_raise_1", "text": "All aboard - raise!", "note": "sing-song"}],
		"bluff": [{"id": "pete_bluff_1", "text": "I got a feeling about this one.", "note": "breezy, winking at nobody"}],
		"win": [{"id": "pete_win_1", "text": "Lucky Pete rides again!", "note": "delighted, slapping the felt"}],
		"lose": [{"id": "pete_lose_1", "text": "Easy come, easy go.", "note": "shrugging, unbothered"}],
		"complain": [{"id": "pete_complain_1", "text": "Aw, that's a crime, that is.", "note": "mock-wounded"}],
		"at_danny": [{"id": "pete_danny_1", "text": "Mercer, you're a regular card shark!", "note": "admiring, friendly"}],
	},
	"moe": {
		"fold": [{"id": "moe_fold_1", "text": "Not with these, no.", "note": "tired, off the late streetcar"}],
		"raise": [{"id": "moe_raise_1", "text": "So, a little more.", "note": "measured, a tailor's precision"}],
		"bluff": [{"id": "moe_bluff_1", "text": "Who knows? Maybe I have it.", "note": "deadpan, eyebrows up"}],
		"win": [{"id": "moe_win_1", "text": "A good night after all.", "note": "quietly pleased"}],
		"lose": [{"id": "moe_lose_1", "text": "Such is life.", "note": "resigned"}],
		"complain": [{"id": "moe_complain_1", "text": "I should have stayed on the streetcar.", "note": "rueful, shaking his head"}],
		"at_danny": [{"id": "moe_danny_1", "text": "You I should have watched closer.", "note": "dry respect"}],
	},
}


## The voice name a line's recording goes under (custom/audio/<it>.ogg/.wav/.mp3).
static func audio_name(line: Dictionary) -> String:
	return "voice/poker/" + String(line.get("id", ""))


## A line for `player` in `situation` ({} when he has none), picked by `rng`.
static func pick(player: String, situation: String, rng: RandomNumberGenerator) -> Dictionary:
	var lines: Array = LINES.get(player, {}).get(situation, [])
	if lines.is_empty():
		return {}
	return lines[rng.randi_range(0, lines.size() - 1)]


## What a beat on show (PokerPacing) means: [{player, situation}] - an action
## for the player who made it; a result for every card player still in at the
## end (won, lost, a big pot lost, a pot Danny took off him).
static func situations(beat: Dictionary, t: Holdem, danny: int) -> Array:
	var out := []
	match String(beat.get("kind", "")):
		"action":
			var who := String(beat.get("player", ""))
			if who == "" or who == "danny":
				return out
			var act := String(beat.get("action", ""))
			if act == "fold":
				out.append({"player": who, "situation": "fold"})
			elif act in ["bet", "raise", "all_in"]:
				out.append({"player": who, "situation": "bluff" if _nothing_made(t, int(beat.get("seat", -1))) else "raise"})
		"result":
			var winners := []
			for r in t.results:  # the pots as they were won
				for w in r.winners:
					if not w in winners:
						winners.append(w)
			var big := t.big_blind * 20
			for i in t.seats.size():
				var s: Dictionary = t.seats[i]
				if i == danny or not s.in_hand or String(s.id) == "danny":
					continue
				if i in winners:
					out.append({"player": String(s.id), "situation": "win"})
				elif not s.folded:
					var lost_big: bool = int(s.total) >= big
					var to_danny: bool = danny in winners
					out.append({"player": String(s.id), "situation": "at_danny" if to_danny else ("complain" if lost_big else "lose")})
	return out


## A bet or raise with nothing made (high card only) once the flop is out.
static func _nothing_made(t: Holdem, seat: int) -> bool:
	if seat < 0 or t.board.size() < 3:
		return false
	var cards: Array = (t.seats[seat].hole as Array) + t.board
	return HandRank.category(HandRank.score(cards)) == 0
