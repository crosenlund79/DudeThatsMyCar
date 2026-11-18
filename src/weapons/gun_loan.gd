class_name GunLoan
extends RefCounted
## M010: Eddie's Thompson, out on loan. Eddie never sells it ("costs more than
## you make in a year"); he lends it for a deposit and keeps a dollar of it
## for his trouble when it comes back. While it is out, Danny carries it with
## its own magazine and spare rounds (never the pistol's); he can bring it
## back any night; after a few nights Eddie starts asking for it. It is never
## Danny's: no loan, no Thompson. Pure; saved inside Rackets.

const DEPOSIT := 500
const FEE := 100
## Rounds that go with it: one stick in the gun, two more in Danny's coat.
const LOADED := 20
const SPARE := 40
## Nights Eddie waits before he asks for it back.
const PATIENCE := 3

var out := false
## The night it went out.
var since := 0
## Rounds in its magazine and spare (kept here while it is out, for the save).
var ammo := 0
var spare := 0
## Times it has been lent and brought back (Eddie remembers).
var lent := 0
var returned := 0


## Lends it (the caller takes the deposit). False when it is already out.
func lend(night: int) -> bool:
	if out:
		return false
	out = true
	since = night
	ammo = LOADED
	spare = SPARE
	lent += 1
	return true


## Brings it back: the deposit less Eddie's fee (cents) to give back to Danny.
func give_back() -> int:
	if not out:
		return 0
	out = false
	ammo = 0
	spare = 0
	returned += 1
	return DEPOSIT - FEE


## Out for longer than Eddie likes.
func overdue(night: int) -> bool:
	return out and night - since >= PATIENCE


func to_dict() -> Dictionary:
	return {"out": out, "since": since, "ammo": ammo, "spare": spare, "lent": lent, "returned": returned}


func from_dict(d: Dictionary) -> void:
	out = bool(d.get("out", false))
	since = int(d.get("since", 0))
	ammo = int(d.get("ammo", 0))
	spare = int(d.get("spare", 0))
	lent = int(d.get("lent", 0))
	returned = int(d.get("returned", 0))
