class_name Memories
extends RefCounted
## What the people of the ward remember about Danny (pure): threats and
## intimidation, favours, payment disputes, good dealings, lies, and promises
## kept or broken - each with the night it happened. Memories fade (a quarter
## a night), so an old threat counts less than last night's. From them each
## person has an attitude: fear, goodwill and trust.

## kind -> [fear, goodwill, trust] it adds.
const WEIGHTS := {
	"threat": [3.0, -2.0, -1.0],
	"heard_threat": [1.0, -0.5, 0.0],
	"favour": [0.0, 3.0, 1.0],
	"heard_favour": [0.0, 1.0, 0.0],
	"deal": [0.0, 1.0, 0.5],
	"dispute": [0.0, -1.0, -0.5],
	"lie": [0.0, -1.0, -3.0],
	"kept_promise": [0.0, 0.5, 1.5],
	"broken_promise": [0.0, -1.5, -2.0],
	"shot": [5.0, -4.0, -3.0],
}
const FADE := 0.75

## person -> [{night, kind, note}] (newest last, at most 20 each)
var entries := {}
## Promises: {by, to, what, cents, due (night), done}
var promises: Array = []


func remember(person: String, kind: String, night: int, note: String = "") -> void:
	if not entries.has(person):
		entries[person] = []
	entries[person].append({"night": night, "kind": kind, "note": note})
	if entries[person].size() > 20:
		entries[person].pop_front()


## How many memories of this kind a person has from the last `nights` nights.
func recent(person: String, kind: String, night: int, nights: int = 3) -> int:
	var n := 0
	for e in entries.get(person, []):
		if e.kind == kind and night - int(e.night) < nights:
			n += 1
	return n


## {fear, goodwill, trust} towards Danny tonight, older memories counting less.
func attitude(person: String, night: int) -> Dictionary:
	var a := {"fear": 0.0, "goodwill": 0.0, "trust": 0.0}
	for e in entries.get(person, []):
		var w: Array = WEIGHTS.get(e.kind, [0.0, 0.0, 0.0])
		var f := pow(FADE, maxf(0.0, float(night - int(e.night))))
		a.fear += w[0] * f
		a.goodwill += w[1] * f
		a.trust += w[2] * f
	return a


## Someone promises something by a night ("pay", "repay").
func promise(by: String, to: String, what: String, cents: int, due: int) -> void:
	promises.append({"by": by, "to": to, "what": what, "cents": cents, "due": due, "done": false})


func open_promise(by: String, what: String) -> Dictionary:
	for p in promises:
		if p.by == by and p.what == what and not p.done:
			return p
	return {}


## A promise kept: the one it was made to remembers.
func keep(by: String, what: String, night: int) -> bool:
	var p := open_promise(by, what)
	if p.is_empty():
		return false
	p.done = true
	remember(p.to if p.by == "danny" else p.by, "kept_promise", night, what)
	return true


## Promises past their night are broken (and remembered). Returns them.
func end_night(night: int) -> Array:
	var broken := []
	for p in promises:
		if not p.done and night > int(p.due):
			p.done = true
			broken.append(p)
			# Danny's broken word is held against him by the one he promised;
			# someone else's broken word to Danny is a dispute Danny has with them
			remember(p.to if p.by == "danny" else p.by, "broken_promise" if p.by == "danny" else "dispute", night, p.what)
	promises = promises.filter(func(p: Dictionary) -> bool: return not p.done or night - int(p.due) < 4)
	return broken


func to_dict() -> Dictionary:
	return {"entries": entries.duplicate(true), "promises": promises.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	entries = {}
	var e: Dictionary = d.get("entries", {})
	for person in e:
		entries[person] = []
		for m in e[person]:
			entries[person].append({"night": int(m.night), "kind": String(m.kind), "note": String(m.get("note", ""))})
	promises = []
	for p in d.get("promises", []):
		promises.append({"by": String(p.by), "to": String(p.to), "what": String(p.what), "cents": int(p.cents),
			"due": int(p.due), "done": bool(p.done)})
