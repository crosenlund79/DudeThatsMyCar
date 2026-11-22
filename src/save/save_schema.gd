class_name SaveSchema
extends RefCounted
## M014: the save file's format - its version, its sections and who owns each,
## the migrations from every earlier format, and the checks a file read back
## must pass before the game uses it. Pure (no scene).
##
## Versions: 1 - every save from M003 to M013 (the field was written as 1 and
## never changed while sections were added; a section a build did not know is
## simply absent, and each owner's from_dict fills in its defaults). 2 - M014:
## the same sections, the version meaning what it says, and what a version-1
## save left to code at load time made explicit by the migration below.

const VERSION := 2

## The sections, in the order they are written: name -> {type, owner}.
const SECTIONS := {
	"rackets": {"type": TYPE_DICTIONARY, "owner": "Rackets: money, bottles, the ward's businesses, Rourke, memories, talk, every job"},
	"voices": {"type": TYPE_DICTIONARY, "owner": "VoiceLines: the recorded lines heard"},
	"poker": {"type": TYPE_DICTIONARY, "owner": "BackRooms (PokerNight): the card game's books and stakes"},
	"slots": {"type": TYPE_ARRAY, "owner": "BackRooms (SlotMachine): each machine's reels, lamps, holds and stake"},
	"danny": {"type": TYPE_DICTIONARY, "owner": "Danny's BodyCondition: his wounds"},
	"ward": {"type": TYPE_DICTIONARY, "owner": "Casualties (who is out tonight) and Rival (Lefty)"},
	"gun": {"type": TYPE_DICTIONARY, "owner": "Armoury: the .45's rounds"},
	"districts": {"type": TYPE_DICTIONARY, "owner": "Districts: each neighbour's state tonight (its beat cop down)"},
	"cars": {"type": TYPE_DICTIONARY, "owner": "Fleet: the cars moved, taken, loaded, driven tonight"},
	"place": {"type": TYPE_DICTIONARY, "owner": "main: where and when Danny was saved"},
	"incidents": {"type": TYPE_DICTIONARY, "owner": "StreetIncidents: tonight's incidents and their history"},
}

## The order the game puts a save back (each when the part it belongs to has
## been built - see main._ready): the books first, the place last.
const RESTORE_ORDER := ["rackets", "voices", "districts", "incidents", "poker", "gun", "danny", "ward", "slots",
	"place", "cars"]

## M006: who Danny already knew in a game saved before the voices existed.
const OLD_ACQUAINTANCES := ["augie_greeting", "rourke_greeting", "eddie_greeting", "eddie_sales"]


## The version a save says it is (a save with none is a version-1 save; a
## new game's empty data is version 0).
static func version_of(data: Dictionary) -> int:
	if data.is_empty():
		return 0
	return int(data.get("version", 1)) if typeof(data.get("version", 1)) in [TYPE_INT, TYPE_FLOAT] else 1


## `data` brought up to VERSION (a copy; {} stays {}). A save from a later
## version than this build knows is used as it is, as far as it goes.
static func migrate(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return {}
	var out := data.duplicate(true)
	var from := version_of(out)
	if from < 2:
		out = _from_1(out)
	if from <= VERSION:
		out["version"] = VERSION
	return out


## Version 1 -> 2. A game saved before M006 had no record of the recorded
## lines; the game counted Augie, Rourke and Eddie as already met (their
## greetings and Eddie's sales line heard) - written down here instead of
## being worked out at load time.
static func _from_1(d: Dictionary) -> Dictionary:
	if not d.has("voices") and d.has("rackets"):
		d["voices"] = {"heard": OLD_ACQUAINTANCES.duplicate()}
	return d


## The sections of `data` the game can use: a section of the wrong kind is
## dropped (the game then starts that part afresh, as for a save that never had
## it) and named in `problems`. Returns {data, problems}.
static func validate(data: Variant) -> Dictionary:
	var problems: Array[String] = []
	if not data is Dictionary:
		problems.append("the save is not a set of sections (%s): starting a new game" % type_string(typeof(data)))
		return {"data": {}, "problems": problems}
	var out: Dictionary = (data as Dictionary).duplicate(true)
	for key in SECTIONS:
		if out.has(key) and typeof(out[key]) != int(SECTIONS[key].type):
			problems.append("section '%s' is %s, not %s: dropped" % [key, type_string(typeof(out[key])),
				type_string(int(SECTIONS[key].type))])
			out.erase(key)
	for key in ["place", "cars"]:  # these must say which night they belong to
		if out.has(key) and typeof((out[key] as Dictionary).get("night")) not in [TYPE_INT, TYPE_FLOAT]:
			problems.append("section '%s' has no night: dropped" % key)
			out.erase(key)
	if out.has("rackets") and typeof(out.rackets.get("money", 0)) not in [TYPE_INT, TYPE_FLOAT]:
		problems.append("the money is not a number: the books dropped")
		out.erase("rackets")
	return {"data": out, "problems": problems}
