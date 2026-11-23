class_name LeftysCar
extends RefCounted
## M015: what Lefty Moran knows about his own car (pure; saved inside Rackets).
## His speedster stands at the kerb by his corner. If it goes, he finds out -
## seeing it go, seeing it somewhere else or missing it at the start of a
## night - and he learns who took it only by his own eyes (Danny taking it or
## driving it past him) or by word getting round (a copper saw the theft).
## Knowing it was Danny he holds a grudge (he goes for him on sight) until the
## car is brought back to his kerb; that he remembers too.

## What he knows: "" nothing amiss, "gone" (his car is gone, he doesn't know
## who took it), "danny" (he knows Danny took it).
var knows := ""
## How he learnt it was Danny: "saw_taken", "saw_driving", "word".
var how := ""
## The night he learnt it.
var since := -1
## The car stands at his kerb again after he knew it was Danny.
var returned := false
## A copper saw Danny take it: the word reaches Lefty at the next evening.
var word := false


## His car is gone (he doesn't know who took it). True when this is news.
func learn_gone(night: int) -> bool:
	if knows != "":
		return false
	knows = "gone"
	since = night
	return true


## He knows it was Danny. True when this is news.
func learn_danny(p_how: String, night: int) -> bool:
	if knows == "danny" and not returned:
		return false
	knows = "danny"
	how = p_how
	since = night
	returned = false
	return true


## The car stands at his kerb again. True when it counts (he knew who took it, or that it was gone).
func bring_back() -> bool:
	if knows == "gone":
		knows = ""
		return false  # (he never knew who: nothing to forgive)
	if knows != "danny" or returned:
		return false
	returned = true
	return true


## He goes for Danny on sight (knows it was him, the car not back).
func grudge() -> bool:
	return knows == "danny" and not returned


func to_dict() -> Dictionary:
	return {"knows": knows, "how": how, "since": since, "returned": returned, "word": word}


func from_dict(d: Dictionary) -> void:
	knows = String(d.get("knows", ""))
	if not knows in ["", "gone", "danny"]:
		knows = ""
	how = String(d.get("how", ""))
	since = int(d.get("since", -1))
	returned = bool(d.get("returned", false))
	word = bool(d.get("word", false))
