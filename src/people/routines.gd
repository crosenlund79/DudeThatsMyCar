class_name Routines
extends RefCounted
## M012: where a few named people are at this hour of the night (pure, by the
## clock alone - nothing is simulated while Danny is elsewhere; what he finds
## when he gets there is simply where they would be by now).
## Alderman Quilty keeps his office until one, then goes home to bed; Leon
## Sobczak at North Branch Freight takes his coffee at Dutch's counter for a
## while after midnight. Everyone else keeps to their place as before.

## Quilty goes home at this minute (1 AM).
const QUILTY_HOME := 25 * 60.0
## Leon's coffee at Dutch's (12:00 to 12:25 AM).
const LEON_COFFEE := [24 * 60.0, 24 * 60.0 + 25.0]
## (Where Leon stands at Dutch's counter: the yards' named place "leon_at_dutch".)


## Where `who` is at `minute`: "room" (in their own room), "dutch" (Leon at
## the night lunch), "home" (gone for the night).
static func where(who: String, minute: float) -> String:
	match who:
		"quilty":
			return "home" if minute >= QUILTY_HOME else "room"
		"leon":
			return "dutch" if minute >= LEON_COFFEE[0] and minute < LEON_COFFEE[1] else "room"
	return "room"


## Whether `who` is in their room now.
static func in_room(who: String, minute: float) -> bool:
	return where(who, minute) == "room"
