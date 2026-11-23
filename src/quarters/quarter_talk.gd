class_name QuarterTalk
extends RefCounted
## M015.12: what the people of Canal Market and Lincoln Terrace say - pages
## like Conversations' (which hands these people on to this), the money side
## in Quarters. Josef Hrabal the night butcher and Mrs. Dvorak at her coffee
## urn in the Canal Market Hall; Henry Chu at the Golden Lantern, who hears
## what is said at his tables; Abe Feld the pawnbroker; Ellery Pratt, the
## Belvedere's night manager; Ruby Marchetti, who runs the Paradise's floor,
## and its bandleader. Effects for the game: {"rounds": n} (as Eddie's), and
## {"quarter": {"coffee": true} | {"dance": true} | {"tune": id}}.

const NAMES := {"hrabal": "Josef Hrabal", "dvorak": "Mrs. Dvorak", "chu": "Henry Chu", "feld": "Abe Feld",
	"pratt": "Ellery Pratt", "ruby": "Ruby Marchetti", "bandleader": "The bandleader",
	"hall_board": "The noticeboard", "belvedere_lift": "The lift"}
const PEOPLE := ["hrabal", "dvorak", "chu", "feld", "pratt", "ruby", "bandleader"]

## Things to look at (narrated pages; nothing changes hands).
const READS := {
	"hall_board": "The market master's notices behind chicken wire: STALL FEES DUE SATURDAY - PAY AT THE OFFICE ONLY - "
		+ "NO OTHER COLLECTOR IS AUTHORISED. Under it somebody has pencilled TELL THAT TO K. A brown dog lost, answers to "
		+ "Pepik. Rooms to let over the baths. The Sokol gymnastic society meets Tuesdays at eight.",
	"belvedere_lift": "A bronze cage and its operator asleep on his stool, his cap over his eyes. A brass card on an easel: "
		+ "RESIDENTS AND THEIR GUESTS. Behind you the night manager clears his throat, just loud enough.",
}

## Mrs. Dvorak's talk, a line a night (the market's own news, not Danny's).
const MARKET_TALK := [
	"\"The El's last train goes at twenty to two. After that you hear the barges knock on the canal all night, like "
		+ "somebody wants to be let in.\"",
	"\"Father Wiśniewski is collecting for a new bell. The old one cracked in the cold of twenty-nine, like everything "
		+ "else.\" She drops a nickel in her own jar, for luck.",
	"\"The baths on Canal Street stay open all night for the men off the late shift. And for some men who aren't off "
		+ "any shift,\" she says, and won't say more.",
	"\"Hrabal's boy has gone to work for the Belvedere's kitchen. Two dollars more a week and a white jacket. His "
		+ "mother lit a candle anyway.\"",
]

## Henry Chu's own news, when nobody at his tables has talked about Danny.
const LANTERN_TALK := [
	"\"Two men from the stockyards ate here at eleven and paid with a twenty. Nobody pays a chop suey with a twenty "
		+ "unless he wants the whole street to know he has one.\"",
	"\"The Paradise's bandleader eats here after the last set. Tonight he says the hostesses had their tips counted - "
		+ "by a man who doesn't work there.\"",
	"\"The market master's clerk had the egg foo young and cried into it. Somebody has been collecting the stall "
		+ "fees before he gets to them.\"",
	"\"A gentleman from Lincoln Terrace came down here in a Pierce-Arrow for my spare ribs. He sent the driver in. "
		+ "The driver ate two plates first.\"",
]

## What Abe Feld has on his shelves, a night at a time.
const FELD_SHELVES := [
	"A cornet with a dented bell, a set of false teeth in a jar, eleven wedding rings in a velvet tray, a policeman's "
		+ "whistle. \"The whistle,\" Feld says, \"is not for sale.\"",
	"A Philco radio, three overcoats with the labels cut out, a christening mug, a typewriter missing its Q. \"Nobody "
		+ "in this neighbourhood needs a Q,\" Feld says.",
	"A saxophone in a velvet case, a pair of opera glasses, a box of somebody's medals from the Argonne. Feld turns "
		+ "the medals face down when he sees you looking.",
]

## Who the Belvedere's night manager says is upstairs, for a dollar (fictional people).
const UPSTAIRS := [
	"\"Room 902 has its drapes drawn: Judge Harlan Voss of the Municipal Court, who is not to be disturbed, and a "
		+ "young lady who is his niece. He has a great many nieces.\"",
	"\"The Mayor's campaign treasurer has the corner suite. He pays in cash, he tips in cash, and twice a week men "
		+ "come up the side stairs with more of it.\"",
	"\"Three gentlemen from Detroit on the seventh floor. They don't take their hats off in the lift and they don't "
		+ "use the front door. I mention it only because you asked.\"",
	"\"A man from the State's Attorney's office, drinking the hotel's coffee as if it were evidence. He asked after "
		+ "you people, in a general way.\"",
]

## The hostess who takes Danny's ticket, and what she says (round in turn).
const HOSTESSES := [
	["Fay", "\"You dance like a man who's carrying something heavy,\" she says. \"In your pocket, I mean.\""],
	["Lottie", "\"Don't look at the door,\" she says, \"look at me. That's what the ten cents is for.\""],
	["Irene", "She hums along with the band and steers you clear of a broker with two left feet. \"Regular customer,\" "
		+ "she says. \"Pays for three dances and stands on all of them.\""],
]

var conv: Conversations
var rackets: Rackets
var q: Quarters


func _init(p_conv: Conversations) -> void:
	conv = p_conv
	rackets = p_conv.rackets
	q = rackets.quarters


static func handles(who: String) -> bool:
	return PEOPLE.has(who) or READS.has(who)


func say(who: String, step: String, context: Dictionary) -> Dictionary:
	q = rackets.quarters  # a loaded game has a new Quarters
	if READS.has(who):
		return conv._told(who, READS[who], [{"id": "bye", "text": "Leave it be."}]) if step == "hello" else {}
	match who:
		"hrabal":
			return _hrabal(step)
		"dvorak":
			return _dvorak(step, context)
		"chu":
			return _chu(step)
		"feld":
			return _feld(step, context)
		"pratt":
			return _pratt(step)
		"ruby":
			return _ruby(step)
		"bandleader":
			return _bandleader(step)
	return {}


func _night_line(lines: Array) -> String:
	return lines[(rackets.night - 1) % lines.size()]


func _page(who: String, text: String, options: Array = [], effects: Dictionary = {}) -> Dictionary:
	return conv._page(who, text, options, effects)


# ------------------------------------------------------------------ the Canal Market Hall

func _hrabal(step: String) -> Dictionary:
	var choices := [{"id": "night", "text": "What's a butcher doing up at this hour?"},
		{"id": "who_runs", "text": "Who runs things around here?"}, {"id": "bye", "text": "Just looking."}]
	match step:
		"hello":
			if q.meet("hrabal"):
				return _page("hrabal", "\"Ahoj. You're not from the market. Nobody from the market comes in with clean "
					+ "shoes.\" He wipes the cleaver on his apron and looks you over, slowly, the way he looks at a side of beef.",
					choices)
			return _page("hrabal", "\"Back again. You want a chop? No? Then stand where the blood doesn't reach.\"", choices)
		"night":
			return _page("hrabal", "\"The restaurants want it cut by four, the hotels by five. The Belvedere's chef sends "
				+ "his own boy for the tenderloins, and the boy counts every ounce.\" The cleaver comes down. \"So I count "
				+ "them first.\"", choices.slice(1))
		"who_runs":
			return _page("hrabal", "\"The market master has an office upstairs and a book with every stall in it. The "
				+ "ward has its alderman. And lately there's a fellow comes round on Saturdays for stall insurance.\" He "
				+ "spits into the sawdust. \"Insurance against him, I think.\"", [choices[0], choices[2]])
	return {}


func _dvorak(step: String, context: Dictionary) -> Dictionary:
	var choices: Array = []
	if q.coffees < Quarters.COFFEES:
		choices.append({"id": "coffee", "text": "A cup of coffee. (5¢)"})
	choices.append({"id": "talk", "text": "What's the talk tonight?"})
	match step:
		"hello":
			var first := q.meet("dvorak")
			return _page("dvorak", "A big enamel urn, a row of thick white cups and Mrs. Dvorak behind them in two "
				+ "cardigans. \"Coffee is a nickel. Talk is free, and worth it.\"" if first
				else "Mrs. Dvorak is already reaching for a cup. \"You again. You look like a man who needs it.\"", choices)
		"coffee":
			if q.coffees >= Quarters.COFFEES:
				return _page("dvorak", "\"Two cups is enough for anybody. Any more and you'll shake like the El.\"",
					choices)
			if not q.buy_coffee(rackets, float(context.get("minute", 0.0))):
				return _page("dvorak", "\"A nickel, darling. Even the priest pays.\"", choices.slice(1))
			return _page("dvorak", "She pours it black without asking and pushes the sugar at you anyway. It is strong "
				+ "enough to stand a spoon in. The heaviness behind your eyes backs off a step.",
				choices.filter(func(o: Dictionary) -> bool: return o.id != "coffee" or q.coffees < Quarters.COFFEES),
				{"quarter": {"coffee": true}})
		"talk":
			return _page("dvorak", _night_line(MARKET_TALK), choices.filter(func(o: Dictionary) -> bool: return o.id != "talk"))
	return {}


# ------------------------------------------------------------------ the Golden Lantern

## The freshest talk about Danny anywhere (everybody eats at the Lantern), else
## the Lantern's own news for the night.
func _table_talk() -> String:
	for i in range(rackets.rumours.items.size() - 1, -1, -1):
		var t: Dictionary = rackets.rumours.items[i]
		if Rackets.BACKGROUND_TALK.has(t.kind):
			continue
		var line := conv._talk_line(t)
		if line != "":
			return "\"Somebody at table four,\" he says, quietly. \"%s\"" % line.trim_prefix("Word is ").capitalize().substr(0, 1) \
				+ line.trim_prefix("Word is ").substr(1) + "\""
	return _night_line(LANTERN_TALK)


func _chu(step: String) -> Dictionary:
	var choices: Array = []
	if q.meals < Quarters.MEALS:
		choices.append({"id": "eat", "text": "A plate of chop suey. (25¢)"})
	choices.append({"id": "talk", "text": "Heard anything worth hearing?"})
	match step:
		"hello":
			if q.meet("chu"):
				return _page("chu", "\"Welcome to the Golden Lantern. Chop suey, egg foo young, tea or tea.\" He smiles "
					+ "like a man who has heard every joke about his menu and laughed at none of them.", choices)
			return _page("chu", "\"Mr. Mercer.\" He has never asked your name. \"Your table is free.\"", choices)
		"eat":
			if not q.buy_meal(rackets):
				return _page("chu", "\"Twenty-five cents. The cook is my cousin, but he is not that kind of cousin.\"",
					choices.slice(1) if q.meals < Quarters.MEALS else choices)
			return _page("chu", "A plate comes through the hatch in a cloud of steam - rice, pork, bean sprouts, a "
				+ "sauce the colour of the lanterns. Chu sits down across from you, which he does not do for everybody. "
				+ _table_talk(), [{"id": "bye", "text": "Thanks, Henry."}])
		"talk":
			if q.meals > 0:
				return _page("chu", _table_talk(), [{"id": "bye", "text": "Thanks, Henry."}])
			return _page("chu", "\"I hear many things. Most of them over a plate of something.\" He taps the menu.",
				choices.filter(func(o: Dictionary) -> bool: return o.id != "talk"))
	return {}


# ------------------------------------------------------------------ A. Feld, Loans

func _feld(step: String, context: Dictionary) -> Dictionary:
	var spare := int(context.get("spare", 0))
	var choices := [{"id": "rounds", "text": "Anything for a .45? ($3.75)"},
		{"id": "shelves", "text": "What's on the shelves tonight?"}]
	match step:
		"hello":
			if q.meet("feld"):
				return _page("feld", "Behind the brass grille a small man in sleeve garters looks up from a watch with its "
					+ "back off. \"A. Feld, Loans. I buy, I sell, I lend. I don't ask and I don't remember. Mostly.\"", choices)
			return _page("feld", "Feld doesn't look up from the watch. \"The young man with the heavy coat. What can I not "
				+ "remember for you tonight?\"", choices)
		"rounds":
			var rest := [choices[1]]
			if q.feld_boxes >= Quarters.FELD_BOXES:
				return _page("feld", "\"One box a night. I'm a pawnbroker, not an arsenal.\"", rest)
			if rackets.rules.spare_limit - spare <= 0:
				return _page("feld", "\"You're carrying enough lead to sink a barge. Come back lighter.\"", rest)
			var k := q.buy_feld_rounds(rackets, spare)
			if k <= 0:
				return _page("feld", "\"Three seventy-five. Not three seventy-four.\"", rest)
			return _page("feld", "He goes into the back and comes out with a box of .45s that smells of somebody's "
				+ "tackle drawer. \"Eddie Lindqvist sells cheaper, I hear. Eddie Lindqvist is asleep.\"", rest, {"rounds": k})
		"shelves":
			return _page("feld", _night_line(FELD_SHELVES), [choices[0]])
	return {}


# ------------------------------------------------------------------ the Belvedere

func _pratt(step: String) -> Dictionary:
	var choices := [{"id": "who", "text": "Who's upstairs tonight?"}, {"id": "rourke", "text": "I'm here for Mr. Rourke."},
		{"id": "bye", "text": "Just admiring the marble."}]
	match step:
		"hello":
			var first := q.meet("pratt")
			return _page("pratt", ("The night manager looks at your shoes before he looks at your face. " if first
				else "The night manager's smile arrives a moment after he does. ") + "\"Good evening. The Belvedere's "
				+ "guests are asleep, or would like to be. Is there something the hotel can do for you?\"", choices)
		"who":
			if q.tipped:
				return _page("pratt", "\"I believe we've had that conversation, sir. Once a night is discretion. Twice "
					+ "is a habit.\"", [choices[1], choices[2]])
			var opts := [{"id": "bye", "text": "Never mind."}]
			if q.can_tip(rackets):
				opts.push_front({"id": "tip", "text": "(Slide him a dollar.)"})
			return _page("pratt", "\"The Belvedere does not discuss its guests.\" He squares a pen with the edge of the "
				+ "blotter. \"Not for nothing, at least.\"", opts)
		"tip":
			if not q.tip(rackets):
				return _page("pratt", "\"Sir.\" Nothing more.", [choices[1], choices[2]])
			return _page("pratt", "The dollar goes under the blotter without his hand seeming to move. " + _night_line(UPSTAIRS),
				[choices[1], {"id": "bye", "text": "Much obliged."}])
		"rourke":
			return _page("pratt", "\"Mr. Rourke does not keep rooms here. Mr. Rourke's friends occasionally do, and they "
				+ "use the side door on Astor Street.\" A thin smile. \"So should his employees.\"", [choices[0], choices[2]])
	return {}


# ------------------------------------------------------------------ the Paradise Ballroom

func _ruby(step: String) -> Dictionary:
	var choices: Array = []
	if q.dances < Quarters.DANCES:
		choices.append({"id": "ticket", "text": "A ticket. (10¢)"})
	choices.append({"id": "business", "text": "Your place does all right."})
	match step:
		"hello":
			var first := q.meet("ruby")
			return _page("ruby", ("A woman in emerald satin with a roll of blue tickets and a cash box. " if first
				else "Ruby Marchetti tears a ticket off the roll before you've asked. ") + "\"Ten cents a dance, four minutes "
				+ "a dance, hands where the bandleader can see them. You want a ticket, handsome, or are you here to look "
				+ "at the stars?\"", choices)
		"ticket":
			if q.dances >= Quarters.DANCES:
				return _page("ruby", "\"Three's plenty. The girls have their regulars, and you're not one yet.\"",
					choices.filter(func(o: Dictionary) -> bool: return o.id != "ticket"))
			if not q.dance(rackets):
				return _page("ruby", "\"A dime, handsome. The stars are free; the girls aren't.\"",
					choices.filter(func(o: Dictionary) -> bool: return o.id != "ticket"))
			var h: Array = HOSTESSES[(q.danced_total - 1) % HOSTESSES.size()]
			var tune: Dictionary = Quarters.tune_named(q.tune)
			var after := choices.filter(func(o: Dictionary) -> bool: return o.id != "ticket" or q.dances < Quarters.DANCES)
			return _page("ruby", "%s takes your ticket and your hand. For four minutes she leads and you follow while the band "
				% h[0] + "plays \"%s\". %s" % [tune.name, h[1]], after, {"quarter": {"dance": true}})
		"business":
			return _page("ruby", "\"The Paradise is a respectable dance academy, mister. The police captain says so every "
				+ "Thursday when he picks up his envelope.\" She snaps the cash box shut. \"Everybody gets an envelope. "
				+ "That's how a place stays respectable.\"", choices.filter(func(o: Dictionary) -> bool: return o.id != "business"))
	return {}


func _bandleader(step: String) -> Dictionary:
	var choices: Array = []
	for t in Quarters.TUNES:
		if t.id != q.tune:
			choices.append({"id": "tune_" + t.id, "text": "\"%s\". (5¢)" % t.name})
	choices = choices.slice(0, 3)
	if step == "hello":
		return _page("bandleader", "The bandleader leans down from the stand between numbers, mopping his face. \"They're "
			+ "playing \"%s\" over there, it says on the card. Request? A nickel in the cup and we play it like we mean "
			% Quarters.tune_named(q.tune).name + "it.\"", choices)
	if step.begins_with("tune_"):
		var id := step.trim_prefix("tune_")
		if not q.request(rackets, id):
			return _page("bandleader", "\"A nickel, pal. Musicians gotta eat.\"", [])
		return _page("bandleader", "The nickel rings in the cup. He counts the band in and they swing into \"%s\". The "
			% Quarters.tune_named(id).name + "couples on the floor change step.", [{"id": "bye", "text": "(Nod.)"}],
			{"quarter": {"tune": id}})
	return {}
