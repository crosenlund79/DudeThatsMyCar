class_name Patrons
extends RefCounted
## M013: the gaming room's regulars (pure data, fictional): a handful of
## people who come back night after night, each with a favourite game, a way
## of playing it, a purse for the night, a way of taking a win or a loss and a
## way with other people - no biographies. Their money is the house's play
## money for them ("colour chips" at the wheel, coins at a machine): it never
## mixes with Danny's, never changes what the wheel or a machine gives, and is
## fresh each night.
##
## style (the wheel): "cautious" - even money and dozens, small chips;
## "numbers" - single numbers, splits and corners on their own numbers;
## "plunger" - big chips on columns and dozens, a quarter on a number.

const ROSTER := {
	"edna": {"name": "Mrs. Halloway", "look": "characters/lady", "game": "wheel", "style": "cautious",
		"purse": 300, "colour": Color("b57fc4"), "lucky": [], "social": "chatty",
		"win": ["Oh! How lovely.", "There, you see? Patience.", "Red never lets me down."],
		"big_win": ["Goodness gracious!"],
		"lose": ["Oh, bother.", "Next time, Edna.", "Well, I never."]},
	"stan": {"name": "Big Stan", "look": "characters/patron_man", "game": "wheel", "style": "plunger",
		"purse": 900, "colour": Color("d98a3a"), "lucky": [17, 32], "social": "loud",
		"win": ["Hah! Pay the man!", "That's how it's done!", "Leo, you beauty."],
		"big_win": ["SEVENTEEN! What did I tell ya!", "Read 'em and weep!"],
		"lose": ["Ahh, nuts.", "Spin it again, Leo.", "Wheel's got it in for me."]},
	"bertie": {"name": "Bertie Sloane", "look": "characters/clerk", "game": "wheel", "style": "numbers",
		"purse": 400, "colour": Color("4fa39a"), "lucky": [7, 11, 23, 29], "social": "quiet",
		"win": ["Hm. As predicted.", "The system holds."],
		"big_win": ["Twenty-three. Written down, you see."],
		"lose": ["Noted.", "A statistical blip."]},
	"dolly": {"name": "Dolly Crane", "look": "characters/patron_woman", "game": "slots", "style": "cautious",
		"purse": 250, "colour": Color("c95d6f"), "lucky": [], "social": "chatty",
		"win": ["Jackpot, baby!", "Come to Dolly!"], "big_win": ["Ring that bell!"],
		"lose": ["Cheap tin owl.", "One more nickel."]},
	"mick": {"name": "Mick Tierney", "look": "characters/worker", "game": "slots", "style": "plunger",
		"purse": 350, "colour": Color("7f8fb8"), "lucky": [], "social": "quiet",
		"win": ["Huh.", "About time."], "big_win": ["Well, would you look at that."],
		"lose": ["Figures.", "Rigged, I tell ya. Ain't it, though."]},
}


static func name_of(id: String) -> String:
	return String(ROSTER.get(id, {}).get("name", ""))


static func colour_of(id: String) -> Color:
	return ROSTER.get(id, {}).get("colour", Color.WHITE)


## A line for how `id` takes it: kind "win", "big_win" or "lose" (picked by `rng`).
static func line(id: String, kind: String, rng: RandomNumberGenerator) -> String:
	var lines: Array = ROSTER.get(id, {}).get(kind, [])
	if lines.is_empty():
		return ""
	return String(lines[rng.randi_range(0, lines.size() - 1)])
