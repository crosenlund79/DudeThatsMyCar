class_name GunSight
extends RefCounted
## M015 (pure): a gun in Danny's hand, out in the open - how far it is noticed
## and what people make of it. It makes for unease, not for a fight: passers-by
## keep their distance and run if he comes too close with it; the people who
## keep a place of business won't do ordinary business with it out (they ask
## him to put it away first); a copper who sees it tells him to put it away
## and, if he doesn't, comes after him (unarmed: carrying is not a violent
## crime); Lefty Moran, a gangster, tells him where to point it - and a Tommy
## gun pointed his way is a fight. A Thompson is noticed farther off, frightens
## more and gets less patience than a handgun.

const NONE := 0
const HANDGUN := 1
const THOMPSON := 2

## Passers-by keep their distance within WARY and run within FLEE (px), by gun.
const PASSER_WARY: Array[float] = [0.0, 230.0, 380.0]
const PASSER_FLEE: Array[float] = [0.0, 110.0, 210.0]
## A copper notices it this far off (with a clear view), and gives him this
## long to put it away before he comes for him (s).
const COPPER_SEES: Array[float] = [0.0, 300.0, 480.0]
const COPPER_GRACE: Array[float] = [0.0, 6.0, 3.0]
## Lefty Moran: warns within LEFTY_WARNS; a Thompson within LEFTY_FIGHTS and he goes for his gun.
const LEFTY_WARNS := 200.0
const LEFTY_FIGHTS := 240.0
## Someone in the room Danny walks into with it out says so, this close.
const ROOM_NOTICE := 320.0

## Who won't do business with a gun out, and what they say (handgun, Thompson).
const SHY := {
	"augie": ["Whoa, whoa - put that away, Dimes. Not in the Owl. I've got customers.",
		"A Tommy gun? In my bar? Put it away before somebody faints."],
	"sal": ["Madonna! Put that thing away before I nick somebody's ear.",
		"A Tommy gun in a barber shop. Put it away, Danny, please - my hands are shaking."],
	"novak": ["Please, Mr. Mercer - not with that in your hand. Not in my store.",
		"Mr. Mercer! A machine gun? Put it away, I beg you. I have a family."],
	"lindqvist": ["Put that away or take your business somewhere else, Mercer.",
		"Not with that thing in my store. Put it away. Now."],
	"rourke": ["Put it away, Dimes. You're the only fella in here dumb enough to wave one.",
		"Eddie's Thompson, out in my club? Put it away before I take it off you."],
	"bird": ["You come up to my stage with that? Put it away, or go away.",
		"Honey, I sing for the room, not for a Tommy gun. Put it away."],
	"pettibone": ["No guns on my table. Put it away or bleed somewhere else.",
		"No guns on my table - and that one least of all. Put it away."],
	"nightclerk": ["Put that away, mister, or I ring for the desk sergeant.",
		"Put that away, mister, or I ring for the desk sergeant. Right now."],
	"quilty": ["Put that thing away. This is a public office.",
		"A machine gun in an alderman's office? Put it away, Mercer, and we'll pretend I never saw it."],
	"steward": ["Gentlemen don't carry them openly in the Regulars', Mr. Mercer. Put it away.",
		"Put that away, sir. This is a club, not a shooting gallery."],
	"feeney": ["Good heavens. Put that away, please - this is a picture house.",
		"Good heavens - a machine gun! Put it away, please."],
	"leon": ["Put that away. I've got enough trouble without a gun in my office.",
		"Put the Tommy gun away, Mercer. This is a freight office."],
	# M015.12: the new quarters' keepers
	"hrabal": ["Put it away. I have a cleaver and I'm faster than you think.",
		"A machine gun, in the market? Put it away before the whole hall runs out into the street."],
	"dvorak": ["Put that away, darling. Nobody gets coffee with a pistol in his hand.",
		"Jezismarja! Put it away - put it away, I can't pour with my hands shaking."],
	"chu": ["Not at my tables, Mr. Mercer. Put it away and sit down.",
		"Please. My customers are leaving through the kitchen. Put it away."],
	"feld": ["I buy guns, young man. I don't talk to them. Put it away.",
		"That I couldn't sell if I wanted to. Put it away before my heart stops."],
	"pratt": ["Sir. Put that away, or I ring for the house detective and then for the police.",
		"Put that away at once. The Belvedere is not a shooting gallery."],
	"ruby": ["Put that away, handsome. The girls only dance with one kind of rod.",
		"A Tommy gun at a tea dance? Put it away before the band packs up."],
	"bandleader": ["Whoa, pal - put that away. We play requests, not hold-ups.",
		"Put it away, mister! The drummer's under the piano already."],
	"kaz": ["Put that away, Riverside. In this place you'll get soy sauce on it.",
		"A Tommy gun at the Lantern? Put it away before Chu calls his cousins."],
}


## What `who` says to a gun of `level` (1 handgun, 2 Thompson; "" if they don't mind).
static func line(who: String, level: int) -> String:
	if level <= NONE or not SHY.has(who):
		return ""
	return String(SHY[who][clampi(level, HANDGUN, THOMPSON) - 1])


## What a copper who has seen it for `seconds` does: "warn" (the first look:
## put it away), "watch" (still giving him time), "come" (time's up: he comes for him).
static func copper(seconds: float, level: int) -> String:
	if level <= NONE:
		return ""
	if seconds <= 0.0:
		return "warn"
	return "come" if seconds >= COPPER_GRACE[clampi(level, HANDGUN, THOMPSON)] else "watch"


## What a passer-by `distance` px from a gun of `level` does: "flee", "wary" or "".
static func passer(distance: float, level: int) -> String:
	if level <= NONE:
		return ""
	var l := clampi(level, HANDGUN, THOMPSON)
	if distance < PASSER_FLEE[l]:
		return "flee"
	return "wary" if distance < PASSER_WARY[l] else ""
