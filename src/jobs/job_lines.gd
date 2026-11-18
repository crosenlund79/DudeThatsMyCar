class_name JobLines
extends RefCounted
## Everything said in Rourke's first job (M007), as data: who says it, how
## (the performance tag - a direction for the line, shown small beside the
## speaker and kept for whoever voices it one day) and the words. Danny's own
## answers are in `ANSWERS`. Text only: no recordings were made for the job.

const LINES := {
	# Rourke, at his corner table
	"offer": {"who": "rourke", "tone": "leaning in, low",
		"text": "Somebody's been collecting at Lindqvist's hardware store. Not my collector. Not my say-so. Find out who, and stop it."},
	"accepted": {"who": "rourke", "tone": "sitting back, satisfied",
		"text": "Good. Start with the Swede - he's scared, but he talks. Settle it quiet if you can, Dimes. Loud if you have to."},
	"postponed": {"who": "rourke", "tone": "drumming his fingers",
		"text": "A night or two. Don't make me ask a third time."},
	"postponed_again": {"who": "rourke", "tone": "flat",
		"text": "You're making a habit of 'later', Dimes. Last chance."},
	"declined": {"who": "rourke", "tone": "cold, then a shrug",
		"text": "Then I'll find somebody who wants the work. Go on. Earn your end some other way."},
	"given_away": {"who": "rourke", "tone": "not looking up",
		"text": "Forget it. I gave the Lindqvist business to somebody who shows up."},
	"moot": {"who": "rourke", "tone": "dry",
		"text": "Some North Side punk was squeezing the Swede. Somebody left him on Pruitt Street for the Morgue. Saves me a job."},
	"waiting": {"who": "rourke", "tone": "impatient",
		"text": "Well? Is the Swede still paying somebody who isn't me?"},
	"report_deal": {"who": "rourke", "tone": "sour, then a shrug",
		"text": "He keeps what he took, and walks? ... Fine. Talk's cheaper than a funeral. Next time I want my money back."},
	"report_backed_down": {"who": "rourke", "tone": "pleased",
		"text": "Folded, did he? Good. Let the North Side know whose ward this is."},
	"report_beaten": {"who": "rourke", "tone": "a slow grin",
		"text": "With your fists? Like the old days. I like that."},
	"report_killed": {"who": "rourke", "tone": "quietly",
		"text": "I said settle it, Dimes. A dead North Side man brings more North Side men. ... Still. It's settled."},
	"report_handed": {"who": "rourke", "tone": "counting it",
		"text": "And you brought me my money. That's the kind of thing I remember."},
	"report_returned": {"who": "rourke", "tone": "a long look",
		"text": "You gave it back to the Swede. Generous with my money. ... He'll remember who looked after him. So will I."},
	"report_reward": {"who": "rourke", "tone": "sliding an envelope across",
		"text": "For your trouble."},
	"report_handled": {"who": "rourke", "tone": "pleased",
		"text": "Handled. That's what I like to hear. For your trouble."},
	"report_working": {"who": "rourke", "tone": "impatient",
		"text": "Then get back to work."},
	"found_unresolved": {"who": "rourke", "tone": "very quiet",
		"text": "The Swede's still paying Lefty Moran. You told me it was handled. I want that money back, and I still want the job done."},
	"found_money": {"who": "rourke", "tone": "cold",
		"text": "Word is Lefty paid you twenty dollars. You told me he didn't have a dime. I'll be taking that, Dimes."},
	"done": {"who": "rourke", "tone": "",
		"text": "The Lindqvist business is closed. Don't open it again."},
	# Mr. Lindqvist, at his counter
	"lindqvist_tells": {"who": "lindqvist", "tone": "glancing at the door, voice down",
		"text": "A fella from the North Side. Camel coat, white hat, a cigar. Lefty Moran. Eight dollars every Friday for a month, or my windows go. He stands about outside Doyle's Garage on Pruitt Street."},
	"lindqvist_waiting": {"who": "lindqvist", "tone": "worried",
		"text": "He was in again. Said you'd been round. Said it like a joke."},
	"lindqvist_deal": {"who": "lindqvist", "tone": "relieved, but rueful",
		"text": "He's stopped coming. I won't see that money again, but it's something. Thank you, Mr. Mercer."},
	"lindqvist_rid": {"who": "lindqvist", "tone": "relieved",
		"text": "He hasn't been back. Whatever you said to him... I don't want to know."},
	"lindqvist_killed": {"who": "lindqvist", "tone": "pale",
		"text": "They say he's in the Morgue. I didn't want that, Mr. Mercer. I wanted my windows."},
	"lindqvist_returned": {"who": "lindqvist", "tone": "moved",
		"text": "You brought it back? ... Nobody brings anything back in this city. I won't forget it."},
	# Eddie, in the back room
	"eddie_tip": {"who": "eddie", "tone": "snorting",
		"text": "Lefty? Leads with his right, every time. Drops his left shoulder when he does it. Watch for that and he's yours."},
	# Lefty Moran, outside Doyle's Garage
	"lefty_open": {"who": "lefty", "tone": "flicking ash, unbothered",
		"text": "Mercer. Rourke's errand boy. What brings you down to Pruitt Street?"},
	"lefty_why": {"who": "lefty", "tone": "shrugging",
		"text": "The Swede's shop sits on the line. North Side says the line's ours. Says Rourke's getting fat."},
	"lefty_deal": {"who": "lefty", "tone": "a thin smile",
		"text": "You're the sensible kind, Mercer. Fine. The Swede's yours. ... You ever get tired of running Rourke's errands, the North Side pays better."},
	"lefty_no_money": {"who": "lefty", "tone": "laughing",
		"text": "Then Rourke can come and get it himself."},
	"lefty_no_talk": {"who": "lefty", "tone": "spitting",
		"text": "After what you did? We're past talking, Mercer."},
	"lefty_folds": {"who": "lefty", "tone": "backing off, hands up",
		"text": "Easy. Easy, Mercer. ... Fine. The Swede's off my list. Here - twenty bucks, it's what I've got. We never had this talk."},
	"lefty_calls_bluff": {"who": "lefty", "tone": "smirking",
		"text": "You don't scare me, Mercer. Not with your hands in your pockets."},
	"lefty_calls_bluff_hurt": {"who": "lefty", "tone": "smirking",
		"text": "Look at you. You can barely stand up. Go home."},
	"lefty_fight": {"who": "lefty", "tone": "grinning, rolling his shoulders",
		"text": "Been waiting for somebody to ask."},
	"lefty_no_fight": {"who": "lefty", "tone": "laughing",
		"text": "Again? Come back when you can see out of both eyes."},
	"lefty_beaten": {"who": "lefty", "tone": "on one knee, spitting blood",
		"text": "All right! All right. The Swede's off my list. ... Here. Twenty bucks. Now get out of my sight."},
	"lefty_won": {"who": "lefty", "tone": "standing over him",
		"text": "Come back when you can stand up straight, errand boy. Friday's still collection day."},
	"lefty_after_deal": {"who": "lefty", "tone": "civil",
		"text": "Mercer. We're square, you and me."},
	"lefty_after_backed_down": {"who": "lefty", "tone": "keeping his distance",
		"text": "Easy, Mercer. I'm just standing here."},
	"lefty_after_beaten": {"who": "lefty", "tone": "rubbing his jaw",
		"text": "You again. I ain't been near the Swede."},
	"lefty_after_lost": {"who": "lefty", "tone": "smirking",
		"text": "How's the jaw, Mercer?"},
}

## Danny's answers.
const ANSWERS := {
	"job_offer": "You said you had work, Mr. Rourke?",
	"job_accept": "I'll handle it, Mr. Rourke.",
	"job_postpone": "Give me a night or two.",
	"job_decline": "Not my kind of work.",
	"job_report": "About Lindqvist's, Mr. Rourke...",
	"job_working": "Still working on it, Mr. Rourke.",
	"job_handled": "It's handled. (It isn't.)",
	"job_truth_hand": "%s And here's the %s he gave back.",
	"job_truth": "%s",
	"job_truth_keep": "%s He didn't have a dime on him. (He did.)",
	"truth_deal": "We talked. He's done collecting at Lindqvist's.",
	"truth_backed_down": "I leaned on him. He folded.",
	"truth_beaten": "We settled it with our fists. I won.",
	"truth_killed": "Lefty Moran won't be collecting anywhere.",
	"truth_returned": "And I gave the Swede back his money.",
	"lindqvist_ask": "Rourke says somebody's been squeezing you.",
	"lindqvist_return": "Here's your %s back. From Lefty.",
	"eddie_lefty": "Know anything about Lefty Moran?",
	"lefty_confront": "You've been squeezing Lindqvist.",
	"lefty_talk": "Let's talk about it.",
	"lefty_threaten": "Lindqvist's off limits. Walk away or get carried.",
	"lefty_fight": "Put 'em up, Lefty.",
	"lefty_deal": "Keep what you took. Just stop.",
	"lefty_money": "Rourke wants his money back.",
}


static func text(id: String) -> String:
	return LINES[id].text if LINES.has(id) else ""


static func tone(id: String) -> String:
	return LINES[id].tone if LINES.has(id) else ""


static func answer(id: String) -> String:
	return ANSWERS.get(id, id)
