class_name VoiceLines
extends RefCounted
## The people's recorded lines (pure, no scene): which recording each is,
## what is said when (subtitles), whether it is said only once ever (a first
## meeting) or every time it happens (the Bird interrupted on stage), and
## which of the once-only lines Danny has already heard. Saved with the game.
##
## The recordings are the user's, shipped byte for byte under
## res://assets/audio/voice/ and replaceable through custom/audio/voice/.
## Subtitles were transcribed from them by two speech-recognition models
## (faster-whisper small.en and medium.en) that agreed word for word; the
## times come from their word timestamps. They are shown only for the
## shipped recordings. `gain_db` evens out their loudness (measured with
## FFmpeg's EBU R128 meter, brought to about -19 LUFS) without re-encoding.

const LINES := {
	"augie_greeting": {"who": "augie", "once": true, "gain_db": -0.1, "cues": [
		[0.0, 2.6, "Welcome to the Copper Owl. Name's Augie."],
		[2.84, 5.7, "Best drinks in Chicago, worst customers in Illinois."],
		[6.1, 7.6, "Ha! Don't tell him I said that."],
		[7.96, 9.3, "Now, what'll it be, pal?"],
	]},
	"rourke_greeting": {"who": "rourke", "once": true, "gain_db": -1.6, "cues": [
		[0.0, 2.8, "Well, well! Danny Mercer!"],
		[3.56, 5.6, "Look what the wind dragged back into Chicago."],
		[6.32, 8.9, "How long's it been, kid? Two years? Three?"],
		[10.28, 12.4, "Never mind. Good to see you breathing."],
		[13.12, 14.7, "Come on, sit down. Have a drink."],
		[15.54, 18.85, "Now, you and me got some catching up to do."],
		[19.12, 21.2, "And I've got a little work that needs doing."],
	]},
	"eddie_greeting": {"who": "eddie", "once": true, "gain_db": -1.0, "cues": [
		[0.0, 0.95, "Eddie's the name."],
		[1.54, 4.9, "Hardware's out front, but you didn't come here for a hammer, did you?"],
		[5.48, 10.6, "I don't ask questions, I don't give refunds, and I sure as hell don't sell to cops."],
	]},
	"eddie_sales": {"who": "eddie", "once": true, "gain_db": -1.7, "cues": [
		[0.0, 4.2, "You want something that'll make a noise, or something that'll finish an argument?"],
	]},
	"bird_greeting": {"who": "bird", "once": true, "gain_db": 0.1, "cues": [
		[0.0, 3.0, "They call me the Bird. Don't ask why, honey."],
		[3.58, 7.4, "I've been singing at the Copper Owl long enough to know everybody's secrets."],
		[7.96, 12.1, "And believe me, some of them are worth a whole lot more than the drinks."],
	]},
	"bird_interrupted": {"who": "bird", "once": false, "gain_db": 0.6, "cues": [
		[0.0, 2.65, "Well, well, Mercer."],
		[3.58, 6.9, "Ever heard of waiting till a lady finishes her song, sweetheart?"],
		[7.58, 9.45, "Ah, forget it. What do you want?"],
	]},
}

## Once-only lines already heard (id -> true).
var heard := {}


## The audio logical name of a line ("voice/augie_greeting").
static func logical(id: String) -> String:
	return "voice/" + id


static func has_line(id: String) -> bool:
	return LINES.has(id)


## Whether a line should be said now: always for an every-time line, only
## until it has been heard for a once-only line.
func due(id: String) -> bool:
	if not LINES.has(id):
		return false
	return not (LINES[id].once and heard.has(id))


func mark(id: String) -> void:
	if LINES.has(id) and LINES[id].once:
		heard[id] = true


## The subtitle of a line at time t ("" between sentences and after the end).
static func cue_at(id: String, t: float) -> String:
	if not LINES.has(id):
		return ""
	for c in LINES[id].cues:
		if t >= float(c[0]) and t < float(c[1]):
			return c[2]
	return ""


## The whole of a line as written (all its subtitles).
static func text(id: String) -> String:
	if not LINES.has(id):
		return ""
	return " ".join(LINES[id].cues.map(func(c: Array) -> String: return c[2]))


func to_dict() -> Dictionary:
	var ids := heard.keys()
	ids.sort()
	return {"heard": ids}


func from_dict(d: Dictionary) -> void:
	heard = {}
	for id in d.get("heard", []):
		if LINES.has(String(id)):
			heard[String(id)] = true


## A game saved before the voices came (M006): Danny already knows the
## people he had been dealing with, so their first-meeting lines count as
## heard; the Bird is new to him.
func assume_old_acquaintances() -> void:
	for id in ["augie_greeting", "rourke_greeting", "eddie_greeting", "eddie_sales"]:
		heard[id] = true
