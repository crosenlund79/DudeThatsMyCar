class_name Opportunities
extends RefCounted
## M009: two small pieces of work Danny can take or leave, from people who
## are not Rourke - his own earnings, on his own time. Plain state on the
## night clock; Rackets moves the money, the memories and the talk.
##
## DUTCH'S CRATE (the Riverfront Yards): two nights in three, Dutch at the
## night lunch counter on Foundry Street has a crate "off a boxcar" for
## Novak's Grocery in the ward. A driver takes it (the crate goes into the
## boot of a car brought up to the counter) and brings it to Novak's before
## two; Novak pays on delivery. Nobody takes it by half past eleven and Dutch
## sends it with his nephew instead; taken and not delivered by two, the
## nephew has to fetch it, and Dutch remembers.
##
## THE BIJOU'S REEL (Halloran Square): one night in four, the film exchange's
## boy loses the late show's reel; it lies behind St. Brendan's. Mr. Feeney,
## the manager, cannot leave his lobby. Brought to him before eleven, the show
## goes on and he pays; otherwise the late show is cancelled - whether Danny
## heard of it or not.
##
## Either way it resolves the same night; the next night is a new one.

const CRATE_UNTIL := 23 * 60 + 30.0
const CRATE_DELIVER_BY := 26 * 60.0
const CRATE_PAY := 400
const CRATE_STOCK := 4
const REEL_SHOW := 23 * 60.0
const REEL_PAY := 300

## Dutch's crate: "none" (nothing tonight), "waiting" (he has one), "taken"
## (Danny said yes), "loaded" (in a car's boot), "delivered", "gone" (sent
## with the nephew), "dropped" (taken and not delivered in time).
var crate := "none"
## The Bijou's reel: "none", "lost", "looking" (Danny said he'd find it),
## "found" (Danny has the can), "returned", "cancelled".
var reel := "none"
## Whether Danny took the reel job (a cancelled show is then a broken promise).
var reel_promised := false
var night := 0
## What happened on earlier nights: {night, what, outcome}.
var history: Array = []


static func crate_tonight(n: int) -> bool:
	return n % 3 != 0


static func reel_lost_tonight(n: int) -> bool:
	return n % 4 == 1


func begin_night(n: int) -> void:
	night = n
	crate = "waiting" if crate_tonight(n) else "none"
	reel = "lost" if reel_lost_tonight(n) else "none"
	reel_promised = false


## The clock reached `minute`: what was not done in time resolves.
## Returns [{what, outcome}].
func advance(minute: float) -> Array:
	var out := []
	if crate == "waiting" and minute >= CRATE_UNTIL:
		crate = "gone"
		out.append(_done("crate", "gone"))
	elif crate in ["taken", "loaded"] and minute >= CRATE_DELIVER_BY:
		crate = "dropped"
		out.append(_done("crate", "dropped"))
	if reel in ["lost", "looking", "found"] and minute >= REEL_SHOW:
		reel = "cancelled"
		out.append(_done("reel", "cancelled"))
	return out


func _done(what: String, outcome: String) -> Dictionary:
	var e := {"night": night, "what": what, "outcome": outcome}
	history.append(e)
	if history.size() > 12:
		history.pop_front()
	return e


func take_crate() -> bool:
	if crate != "waiting":
		return false
	crate = "taken"
	return true


func load_crate() -> bool:
	if crate != "taken":
		return false
	crate = "loaded"
	return true


func deliver_crate() -> bool:
	if crate != "loaded":
		return false
	crate = "delivered"
	_done("crate", "delivered")
	return true


func take_reel() -> bool:
	if reel != "lost":
		return false
	reel = "looking"
	reel_promised = true
	return true


## Danny picks up the film can (whether or not Feeney asked him yet).
func find_reel() -> bool:
	if not reel in ["lost", "looking"]:
		return false
	reel = "found"
	return true


func return_reel() -> bool:
	if reel != "found":
		return false
	reel = "returned"
	_done("reel", "returned")
	return true


## What Danny did with this one, the last time it came up: "" or an outcome.
func last(what: String) -> String:
	for i in range(history.size() - 1, -1, -1):
		if history[i].what == what:
			return history[i].outcome
	return ""


func to_dict() -> Dictionary:
	return {"night": night, "crate": crate, "reel": reel, "reel_promised": reel_promised, "history": history.duplicate(true)}


## A saved game always starts at dusk: tonight's work as it stood at dusk,
## the earlier nights remembered.
func from_dict(d: Dictionary) -> void:
	history = []
	for h in d.get("history", []):
		history.append({"night": int(h.night), "what": String(h.what), "outcome": String(h.outcome)})
	begin_night(int(d.get("night", night)))
	# what was already over tonight stays over
	for h in history:
		if int(h.night) == night:
			if h.what == "crate":
				crate = h.outcome
			else:
				reel = h.outcome
