class_name FreightJob
extends RefCounted
## M012 "Freight Doesn't Walk" (pure): Danny's own job, not Rourke's.
## Leon Sobczak, North Branch Freight's night dispatcher, has twelve crates of
## radio cabinets for Hartmann's on State Street that must go out on the two
## o'clock truck, or the company puts it on him. They sit under a tarpaulin in
## the freight shed: Walt Haney's shed gang will not load them. Nobody tells
## the company man why - the company docked the gang six dollars for a crate
## dropped last week, and Walt is holding the freight until it is put right.
## Danny can find out (Walt, Dutch at the night lunch, the union hall's
## noticeboard) and settle it: talk Leon into putting the six back out of petty
## cash, pay the six himself, show Walt a gun, or beat him in a fistfight (and,
## losing, try another way). Leon pays Danny ten dollars when the truck is
## loaded, once. Left alone past the truck, Leon pays the six out of his own
## pocket and the freight goes late; Danny's part is over. Shooting is never
## needed (the game's own rules apply if it happens). Saved inside Rackets.

enum Stage { NOT_OFFERED, OFFERED, ACCEPTED, DECLINED, SETTLED, PAID, LAPSED }

## Leon's fee, the gang's docked pay (cents), and the trucks (minutes after
## midnight of the evening: 2 AM; 5 AM if Leon asks after one).
const FEE := 1000
const DOCKED := 600
const TRUCK := 26 * 60.0
const LATE_TRUCK := 29 * 60.0
const CONSIGNEE := "Hartmann's"

var stage := Stage.NOT_OFFERED
## The night it all happens, and when the truck comes.
var night := -1
var deadline := TRUCK
## What Danny has found out: "docked" (why the shed holds the freight),
## "consignee" (whose freight it is), "walt_said" (Walt owned up to it).
var learned := {}
## Leon will put the six back out of petty cash (Danny talked him round).
var leon_agreed := false
## How it was settled: "squared" (Leon paid it, on Danny's word), "paid"
## (Danny's own six), "leaned" (a gun shown), "beaten" (a fistfight won).
var how := ""
var walt_paid_by := ""
var fight_lost_night := -1
var threat_failed_night := -1
var fee_paid := false
## The consignment has gone (the shed's corner empty from now on).
var crates_out := false


func is_open() -> bool:
	return stage == Stage.OFFERED or stage == Stage.ACCEPTED


## Leon tells Danny his trouble (the first time they speak about it).
func offer(n: int, minute: float) -> void:
	if stage != Stage.NOT_OFFERED:
		return
	stage = Stage.OFFERED
	night = n
	deadline = TRUCK if minute < 25 * 60.0 else LATE_TRUCK


func accept() -> bool:
	if stage != Stage.OFFERED:
		return false
	stage = Stage.ACCEPTED
	return true


func decline() -> void:
	if stage == Stage.OFFERED:
		stage = Stage.DECLINED


func learn(fact: String) -> void:
	if is_open():
		learned[fact] = true


## Danny tells Leon why his shed won't move: he agrees to put the six back.
func talk_leon_round() -> bool:
	if stage != Stage.ACCEPTED or not learned.has("docked"):
		return false
	leon_agreed = true
	return true


## The freight goes out: `p_how` as above. Money, memory and talk in `r`.
func settle(r: Rackets, p_how: String) -> bool:
	if stage != Stage.ACCEPTED or crates_out:
		return false
	match p_how:
		"paid":
			if r.money < DOCKED:
				return false
			r.money -= DOCKED
			walt_paid_by = "danny"
			r.memory.remember("walt", "favour", r.night, "paid the gang's six")
			r.memory.remember("leon", "deal", r.night, "the Hartmann's freight")
		"squared":
			if not leon_agreed:
				return false
			walt_paid_by = "leon"
			r.memory.remember("walt", "deal", r.night, "the six put back")
			r.memory.remember("leon", "kept_promise", r.night, "the Hartmann's freight")
		"leaned":
			r.memory.remember("walt", "threat", r.night, "a gun in the shed")
			r.memory.remember("leon", "deal", r.night, "the Hartmann's freight")
		"beaten":
			r.memory.remember("walt", "threat", r.night, "a beating in the shed")
			r.memory.remember("leon", "deal", r.night, "the Hartmann's freight")
		_:
			return false
	how = p_how
	stage = Stage.SETTLED
	crates_out = true
	r.rumours.start("freight_" + p_how, "walt" if p_how != "squared" else "leon", r.night)
	return true


## A threat at Walt: with a gun in hand he loads; without, he laughs it off
## (and there is the fistfight). Returns whether it worked.
func threaten(r: Rackets, gun_drawn: bool) -> bool:
	if stage != Stage.ACCEPTED:
		return false
	if gun_drawn:
		return settle(r, "leaned")
	threat_failed_night = r.night
	return false


func can_fight(n: int) -> bool:
	return stage == Stage.ACCEPTED and fight_lost_night != n


## The fistfight with Walt: won, the freight goes out; lost, Walt stands his
## ground tonight (Danny can still pay or talk Leon round - never stuck).
func fought(r: Rackets, won: bool) -> void:
	if won:
		settle(r, "beaten")
	else:
		fight_lost_night = r.night
		r.memory.remember("walt", "dispute", r.night, "a fight in the shed")


## Leon pays Danny once the truck is loaded. Returns what was paid (0 if nothing).
func collect_fee(r: Rackets) -> int:
	if stage != Stage.SETTLED or fee_paid:
		return 0
	fee_paid = true
	stage = Stage.PAID
	r.money += FEE
	return FEE


## The clock: past the truck (or a later night) with it still open, Leon sorts
## it out himself. Returns "lapsed" when that happens now, else "".
func advance(r: Rackets, minute: float) -> String:
	if not is_open() or (r.night == night and minute < deadline):
		return ""
	var promised := stage == Stage.ACCEPTED
	stage = Stage.LAPSED
	crates_out = true
	walt_paid_by = "leon"
	if promised:
		r.memory.remember("leon", "broken_promise", r.night, "the Hartmann's freight")
		r.rumours.start("freight_lapsed", "leon", r.night)
	return "lapsed"


## What Danny's notebook says about it ("" when there is nothing to do).
func objective() -> String:
	match stage:
		Stage.OFFERED:
			return "Leon Sobczak at North Branch Freight wants twelve crates on the truck by %s. His shed won't load them. He's waiting on an answer." % _clock(deadline)
		Stage.ACCEPTED:
			if leon_agreed:
				return "Leon will put the shed gang's six dollars back. Tell Walt Haney in the freight shed - the truck comes at %s." % _clock(deadline)
			if learned.has("docked"):
				return "Walt Haney's shed gang were docked six dollars for a dropped crate. Square it - or settle it with Walt some other way - before %s." % _clock(deadline)
			return "Find out why the freight shed won't load the %s crates. Walt Haney runs the shed; Dutch hears the yards' talk. The truck comes at %s." % [CONSIGNEE, _clock(deadline)]
		Stage.SETTLED:
			return "The %s freight is loaded. Leon owes you ten dollars." % CONSIGNEE
	return ""


static func _clock(minute: float) -> String:
	var h := int(minute / 60.0) % 12
	return "%d o'clock" % (12 if h == 0 else h)


func to_dict() -> Dictionary:
	return {"stage": stage, "night": night, "deadline": deadline, "learned": learned.duplicate(), "leon_agreed": leon_agreed,
		"how": how, "walt_paid_by": walt_paid_by, "fight_lost_night": fight_lost_night,
		"threat_failed_night": threat_failed_night, "fee_paid": fee_paid, "crates_out": crates_out}


func from_dict(d: Dictionary) -> void:
	stage = int(d.get("stage", Stage.NOT_OFFERED)) as Stage
	night = int(d.get("night", -1))
	deadline = float(d.get("deadline", TRUCK))
	learned = (d.get("learned", {}) as Dictionary).duplicate()
	leon_agreed = bool(d.get("leon_agreed", false))
	how = String(d.get("how", ""))
	walt_paid_by = String(d.get("walt_paid_by", ""))
	fight_lost_night = int(d.get("fight_lost_night", -1))
	threat_failed_night = int(d.get("threat_failed_night", -1))
	fee_paid = bool(d.get("fee_paid", false))
	crates_out = bool(d.get("crates_out", false))
