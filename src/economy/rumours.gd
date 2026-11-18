class_name Rumours
extends RefCounted
## Talk about town (pure, deterministic): what one person knows, the people
## they talk to hear the next night - one step a night along who actually
## talks to whom on Marlowe Avenue. Novak tells Sal, Augie and Lindqvist; Sal
## and Augie talk over the rye; Augie tells Rourke everything; Eddie drinks at
## the club and sits in Lindqvist's back room. So what Danny does at Novak's
## reaches Rourke two nights later, and what he does in the club, at once.

const LINKS := {
	"novak": ["sal", "augie", "lindqvist"],
	"sal": ["novak", "augie"],
	"augie": ["sal", "rourke", "eddie", "novak"],
	"rourke": ["augie"],
	"lindqvist": ["novak", "eddie"],
	"eddie": ["lindqvist", "augie"],
	# M007: Lefty Moran talks to Eddie (who sells to everybody), and Eddie talks to Augie
	"lefty": ["eddie"],
	# M009: Dutch at the yards' night lunch sells Novak his tinned goods; Mr. Feeney
	# of the Bijou gets his shave at Sal's
	"dutch": ["novak"],
	"feeney": ["sal"],
}

## {id, kind, about, business, cents, night, seq, text, known: [people]}
var items: Array = []
var _next := 1


## Something someone knows starts going round. Returns it.
func start(kind: String, origin: String, night: int, data: Dictionary = {}) -> Dictionary:
	var r := {"id": _next, "kind": kind, "business": String(data.get("business", "")), "cents": int(data.get("cents", 0)),
		"night": night, "seq": int(data.get("seq", 0)), "text": String(data.get("text", "")), "known": [origin],
		"origin": origin}
	_next += 1
	items.append(r)
	return r


## A night of talk: everyone tells the people they talk to what they knew
## this morning. Returns who learnt what: [{to, rumour}].
func spread() -> Array:
	var learnt := []
	for r in items:
		var before: Array = (r.known as Array).duplicate()
		for person in before:
			for other in LINKS.get(person, []):
				if not (r.known as Array).has(other):
					(r.known as Array).append(other)
					learnt.append({"to": other, "rumour": r})
	return learnt


func knows(person: String, rumour: Dictionary) -> bool:
	return (rumour.known as Array).has(person)


## What a person knows, newest first (optionally only of one kind).
func known_to(person: String, kind: String = "") -> Array:
	var out := []
	for i in range(items.size() - 1, -1, -1):
		var r: Dictionary = items[i]
		if (r.known as Array).has(person) and (kind == "" or r.kind == kind):
			out.append(r)
	return out


## Old talk is forgotten after a week.
func forget(night: int) -> void:
	items = items.filter(func(r: Dictionary) -> bool: return night - int(r.night) <= 7)


func to_dict() -> Dictionary:
	return {"items": items.duplicate(true), "next": _next}


func from_dict(d: Dictionary) -> void:
	items = []
	for r in d.get("items", []):
		var known := []
		for p in r.get("known", []):
			known.append(String(p))
		items.append({"id": int(r.id), "kind": String(r.kind), "business": String(r.get("business", "")),
			"cents": int(r.get("cents", 0)), "night": int(r.night), "seq": int(r.get("seq", 0)),
			"text": String(r.get("text", "")), "known": known, "origin": String(r.get("origin", ""))})
	_next = int(d.get("next", items.size() + 1))
