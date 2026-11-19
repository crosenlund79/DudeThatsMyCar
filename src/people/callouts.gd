class_name Callouts
extends RefCounted
## M012: when the people Danny knows speak first (pure). Rourke, Augie, Eddie,
## the Bird, Alderman Quilty and Leon Sobczak at North Branch Freight call out
## to him when he comes near - a line over their heads, a turn and a step his
## way - from what they remember of him and what the talk has told them
## (Memories, Rumours), never from what they cannot know. E answers (the
## conversation opens on what they called out about); walking on ignores it.
## Modest by design: one call a person a night at most, none within a while of
## another, a line once said not said again for some nights, never while Danny
## is busy (driving, talking, at a table, in a fight or a film, with a gun
## going off). The game supplies the moment (`context`) and the person's
## distance; this decides whether, and what.
##
## The delivery tags ([Dry, amused]) are production notes for a voice actor
## later (docs/M012_PERFORMANCE_SCRIPT.md); they are kept here with the words
## and never shown on screen.

## How near he must come (px), and how long a call waits for an answer.
const RANGE := 190.0
const ANSWER_SECONDS := 20.0
## Game minutes between any two calls (the clock runs a minute a second).
const GAP_MINUTES := 25.0
## Nights before the same line is used again.
const REPEAT_NIGHTS := 4

## Every line: who, the call (over their head), the follow-up when Danny
## answers (the first page of the talk), Danny's reply into the usual talk, and
## the delivery tag. `business`: may come again any night it still applies.
const LINES := {
	"rourke_business": {"who": "rourke", "call": "Mercer. A minute.", "tag": "Low; not a request",
		"follow": "Sit. There's something wants doing, and you're the man I want doing it.",
		"reply": "I'm listening, Mr. Rourke.", "business": true},
	"rourke_lie": {"who": "rourke", "call": "Danny. Sit down.", "tag": "Cold, quiet",
		"follow": "People tell me things, Danny. I'd sooner hear them from you, first time round.",
		"reply": "Sure, Mr. Rourke."},
	"rourke_pleased": {"who": "rourke", "call": "There he is.", "tag": "Dry, amused",
		"follow": "Lindqvist's sleeping nights again. That's worth a drink, and the drink's on me.",
		"reply": "I'll take it."},
	"rourke_shooting": {"who": "rourke", "call": "Mercer. Over here. Now.", "tag": "Flat, very calm",
		"follow": "Shooting draws coppers, and coppers draw aldermen. Keep it quiet in my ward.",
		"reply": "It won't happen again."},
	"augie_wary": {"who": "augie", "call": "You. Hands where I can see 'em.", "tag": "Wary, low",
		"follow": "Say what you came to say, Dimes, and say it at the bar.", "reply": "Easy, Augie."},
	"augie_dry": {"who": "augie", "call": "Dimes! Over here - the cellar's near dry.", "tag": "Urgent, under his breath",
		"follow": "The swells are drinking the paint off the walls. You bring rye, I pay for rye.",
		"reply": "Let's see what you've got.", "business": true},
	"augie_boss": {"who": "augie", "call": "Dimes - the boss is asking.", "tag": "Low, a nod at the corner table",
		"follow": "He's been asking since eight. Don't make him ask again.", "reply": "Thanks, Augie."},
	"augie_warm": {"who": "augie", "call": "Dimes! Your corner's free.", "tag": "Warm",
		"follow": "Good to see a friendly face. The usual?", "reply": "Pour it."},
	"eddie_overdue": {"who": "eddie", "call": "Hey! Dimes! You got something of mine.", "tag": "Sharp, half a joke",
		"follow": "The Chicago typewriter, pal. A loan's a loan.", "reply": "About that.", "business": true},
	"eddie_noise": {"who": "eddie", "call": "Heard you been making noise.", "tag": "Sly",
		"follow": "Noise uses rounds. Rounds I got.", "reply": "Show me."},
	"bird_again": {"who": "bird", "call": "Come to stop another song, mister?", "tag": "Arch, tired",
		"follow": "You've got a way of walking in on the best part. Well? You stopped it - say something.",
		"reply": "Just wanted a word."},
	"bird_hello": {"who": "bird", "call": "You're the one Rourke keeps by the door.", "tag": "Curious, unhurried",
		"follow": "Everybody in here looks at me. You look at the room. Why's that?", "reply": "Habit."},
	"quilty_hello": {"who": "quilty", "call": "Mercer! Come in, come in.", "tag": "Expansive",
		"follow": "The ward's door is always open - mine more than most. Sit, sit.", "reply": "Evening, Alderman."},
	"quilty_shooting": {"who": "quilty", "call": "Danny! A word.", "tag": "Genial, worried underneath",
		"follow": "My voters hear shots, Danny, and then they hear about it from me. I'd like to have something to tell them.",
		"reply": "Nothing to tell, Alderman."},
	"quilty_kindness": {"who": "quilty", "call": "Mercer! A friend of the ward.", "tag": "Pleased, a hand out",
		"follow": "I hear you did a good turn on Marlowe Avenue. I don't forget a good turn. Neither does the ward.",
		"reply": "Just neighbourly."},
	"leon_hello": {"who": "leon", "call": "Shut that door - you're letting the coal dust in.", "tag": "Dry, not looking up",
		"follow": "North Branch Freight, night dispatch. If you're not a driver with a waybill, you're in my light.",
		"reply": "Just looking round."},
	"leon_job": {"who": "leon", "call": "You there - got a minute and a strong back?", "tag": "Tired, hopeful",
		"follow": "North Branch Freight, night dispatch. You've got the look of a fella who can carry a problem. Mine weighs twelve crates.",
		"reply": "Go on.", "business": true},
	"leon_fee": {"who": "leon", "call": "Mercer! The truck's loading - come and get your money.", "tag": "Relieved, almost laughing",
		"follow": "Twelve crates, all present and correct. Here - ten dollars, like I said.", "reply": "Pleasure.",
		"business": true},
}

## line id -> the night it was last said
var said := {}
## person -> the night they last called
var called := {}
## the minute of the last call tonight (-INF: none yet)
var last_minute := -INF
var night := 0


func begin_night(n: int) -> void:
	night = n
	last_minute = -INF


## Whether anyone may call out at all right now (Danny not busy, nobody shooting).
static func free_to_call(ctx: Dictionary) -> bool:
	for k in ["driving", "talking", "busy", "film", "fighting", "menu"]:
		if ctx.get(k, false):
			return false
	return float(ctx.get("since_gunfire", INF)) > 30.0


## The line `who` would call out now, or "" (nothing to say, or not now).
## `ctx`: the moment ({minute, night, driving, talking, busy, film, fighting,
## since_gunfire (s)} and what the game knows of the person: present, near
## (px), and the facts below), `r`: the rackets (memories, rumours, the jobs).
func pick(who: String, ctx: Dictionary, r: Rackets) -> String:
	if not free_to_call(ctx) or not ctx.get("present", true) or float(ctx.get("near", INF)) > RANGE:
		return ""
	if int(called.get(who, -1)) == night:
		return ""
	if float(ctx.get("minute", 0.0)) - last_minute < GAP_MINUTES:
		return ""
	for id in _candidates(who, ctx, r):
		var line: Dictionary = LINES[id]
		if line.get("business", false) or night - int(said.get(id, -1000)) >= REPEAT_NIGHTS:
			return id
	return ""


## The call was made: spent for tonight.
func mark(id: String, minute: float) -> void:
	var who: String = LINES[id].who
	said[id] = night
	called[who] = night
	last_minute = minute


## What each person might say, most pressing first (only what they know).
func _candidates(who: String, ctx: Dictionary, r: Rackets) -> Array:
	var m := r.memory
	var out := []
	match who:
		"rourke":
			if m.recent("rourke", "lie", night, 3) > 0:
				out.append("rourke_lie")
			if not r.rumours.known_to("rourke", "shot").filter(func(x: Dictionary) -> bool: return night - int(x.night) <= 2).is_empty():
				out.append("rourke_shooting")
			if ctx.get("rourke_business", false):
				out.append("rourke_business")
			if r.job.stage == RourkeJob.Stage.REPORTED and r.job.success and night - r.job.resolved_night <= 2:
				out.append("rourke_pleased")
		"augie":
			if m.recent("augie", "threat", night, 3) > 0 or m.recent("augie", "shot", night, 5) > 0:
				out.append("augie_wary")
			elif r.club().is_short():
				out.append("augie_dry")
			elif ctx.get("rourke_business", false):
				out.append("augie_boss")
			elif m.attitude("augie", night).goodwill > 2.0:
				out.append("augie_warm")
		"eddie":
			if r.loan.out and r.loan.overdue(night):
				out.append("eddie_overdue")
			elif not r.rumours.known_to("eddie", "shot").is_empty():
				out.append("eddie_noise")
		"bird":
			if ctx.get("singing", true):
				return []  # she does not call out from the middle of a song
			if m.recent("bird", "interrupted", night, 2) > 0:
				out.append("bird_again")
			else:
				out.append("bird_hello")
		"quilty":
			if not r.rumours.known_to("quilty", "shot").is_empty():
				out.append("quilty_shooting")
			if not r.rumours.known_to("quilty", "crate_run").is_empty() or m.attitude("quilty", night).goodwill > 0.5:
				out.append("quilty_kindness")
			out.append("quilty_hello")
		"leon":
			match r.freight.stage:
				FreightJob.Stage.NOT_OFFERED:
					out.append("leon_job")
				FreightJob.Stage.SETTLED:
					out.append("leon_fee")
			out.append("leon_hello")
	return out


func to_dict() -> Dictionary:
	return {"said": said.duplicate(), "called": called.duplicate(), "night": night}


func from_dict(d: Dictionary) -> void:
	said = {}
	for k in d.get("said", {}):
		said[k] = int(d.said[k])
	called = {}
	for k in d.get("called", {}):
		called[k] = int(d.called[k])
	night = int(d.get("night", night))
	last_minute = -INF
