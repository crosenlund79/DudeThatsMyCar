class_name CafeJob
extends RefCounted
## M010: Rourke's job at Rosie's Café. Vince Duggan has been selling beer off
## Rourke's trucks in Halloran Square; every night from ten he takes his
## coffee at Rosie's on Marlowe Avenue with his green Packard at the kerb
## outside. Rourke wants a message, not a killing: the car gone while Duggan
## is inside. Eddie sells the parcel (an abstract item); under the car it
## goes off a quarter of an hour later, once. Danny is paid once, when he
## reports it done. Offered every night until he takes it on; "not tonight"
## leaves it open. Pure; saved inside Rackets.

enum Stage { NOT_OFFERED, OFFERED, ACCEPTED, PLANTED, DONE, REPORTED }

## Duggan's car stands outside Rosie's from ten until two (game minutes, past midnight +24 h).
const CAR_FROM := 22 * 60
const CAR_UNTIL := 24 * 60 + 2 * 60
## Minutes from the parcel going under the car to the blast.
const FUSE := 15.0
const REWARD := 1000
## How close to the car is too close when it goes (px).
const DANGER := 110.0
## How near Danny has to be for the scene to be shown (px).
const WATCH := 700.0
## The wreck stays at the kerb this many nights (the scorch on the road for good).
const WRECK_NIGHTS := 2

var stage := Stage.NOT_OFFERED
## The night and the game minute of the blast (set when the parcel goes under).
var blast_night := -1
var blast_minute := -1.0
## A copper saw Danny at the car (a credible reason to suspect him).
var seen := false
## Danny was right there when it went (hurt).
var caught_in_it := false
var paid := false


func offerable() -> bool:
	return stage == Stage.NOT_OFFERED or stage == Stage.OFFERED


func offer() -> void:
	if stage == Stage.NOT_OFFERED:
		stage = Stage.OFFERED


func accept() -> bool:
	if not offerable():
		return false
	stage = Stage.ACCEPTED
	return true


## Duggan's Packard at the kerb outside Rosie's at this minute of `night`
## (until the night it goes up).
func car_there(night: int, minute: float) -> bool:
	if stage == Stage.DONE or stage == Stage.REPORTED:
		return false
	if stage == Stage.PLANTED:
		return true  # he is still inside when it goes
	return minute >= CAR_FROM and minute < CAR_UNTIL


## The parcel goes under the car (Danny has it, the job is on, the car is there).
func plant(night: int, minute: float, witnessed: bool) -> bool:
	if stage != Stage.ACCEPTED or not car_there(night, minute):
		return false
	stage = Stage.PLANTED
	blast_night = night
	blast_minute = minute + FUSE
	seen = witnessed
	return true


## The minute it goes tonight (INF: not tonight).
func due(night: int) -> float:
	return blast_minute if stage == Stage.PLANTED and night == blast_night else INF


## It goes off (once). False when it is not due.
func blast(night: int, minute: float) -> bool:
	if minute < due(night):
		return false
	stage = Stage.DONE
	return true


## The burnt-out Packard still at the kerb on `night`.
func wreck_there(night: int) -> bool:
	return (stage == Stage.DONE or stage == Stage.REPORTED) and night >= blast_night and night < blast_night + WRECK_NIGHTS


func scorched() -> bool:
	return stage == Stage.DONE or stage == Stage.REPORTED


## Danny tells Rourke it is done: the reward, once (0 if not done or already paid).
func report() -> int:
	if stage != Stage.DONE or paid:
		return 0
	stage = Stage.REPORTED
	paid = true
	return REWARD


func to_dict() -> Dictionary:
	return {"stage": stage, "blast_night": blast_night, "blast_minute": blast_minute, "seen": seen,
		"caught_in_it": caught_in_it, "paid": paid}


func from_dict(d: Dictionary) -> void:
	stage = clampi(int(d.get("stage", Stage.NOT_OFFERED)), 0, Stage.REPORTED)
	blast_night = int(d.get("blast_night", -1))
	blast_minute = float(d.get("blast_minute", -1.0))
	seen = bool(d.get("seen", false))
	caught_in_it = bool(d.get("caught_in_it", false))
	paid = bool(d.get("paid", false))
	if stage == Stage.PLANTED:
		# a game saved with the parcel under the car: it went off that night
		stage = Stage.DONE
