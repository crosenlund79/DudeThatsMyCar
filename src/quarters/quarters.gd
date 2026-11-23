class_name Quarters
extends RefCounted
## M015.12: Danny's dealings in the two new quarters (pure) - a cup of Mrs.
## Dvorak's coffee in the Canal Market Hall, a plate at Henry Chu's Golden
## Lantern, a box of rounds from under Abe Feld's counter, a dance ticket at
## the Paradise Ballroom and a tune for its band, a dollar for the Belvedere's
## night manager. Each is Danny's own money, paid once when the answer is
## chosen, with a limit a night; nothing is created, owed or given back, and
## the money leaves the ward's books for good (these are not the ward's
## businesses). Saved inside Rackets ("quarters").

## Prices in cents and limits a night.
const COFFEE := 5
const COFFEES := 2
const MEAL := 25
const MEALS := 1
## Abe Feld's box: as many rounds as Eddie's, at half as much again.
const FELD_BOX := 375
const FELD_BOXES := 1
const TICKET := 10
const DANCES := 3
## A dance with a hostess takes this long on the night's clock.
const DANCE_MINUTES := 4.0
const TUNE := 5
const TIP := 100

## Mrs. Dvorak's coffee holds the late-night heaviness off: COFFEE_LIFT game
## minutes at once, wearing off over COFFEE_WEARS (a second cup starts over).
const COFFEE_LIFT := 40.0
const COFFEE_WEARS := 90.0

## The Paradise band's tunes (fictional): name, and how fast the band takes
## it (a playback speed for the band's music).
const TUNES := [
	{"id": "two_bits", "name": "Two Bits a Dance", "pace": 1.0},
	{"id": "blue_canal", "name": "Blue Canal", "pace": 0.9},
	{"id": "lake_shore", "name": "Lake Shore Shuffle", "pace": 1.1},
	{"id": "after_midnight", "name": "Paradise After Midnight", "pace": 0.94},
]

var night := 1
var coffees := 0
var meals := 0
var feld_boxes := 0
var dances := 0
var tunes := 0
var tipped := false
## The minute of tonight's last coffee (-1: none tonight).
var coffee_at := -1.0
## The tune the band plays tonight (an id in TUNES).
var tune := "two_bits"
## Who Danny has met here: id -> the night they first met.
var met := {}
## How many dances Danny has had, all nights (the hostesses' lines go round).
var danced_total := 0


## A new evening: tonight's limits start afresh; the band opens with its usual.
func begin_night(n: int) -> void:
	night = n
	coffees = 0
	meals = 0
	feld_boxes = 0
	dances = 0
	tunes = 0
	tipped = false
	coffee_at = -1.0
	tune = TUNES[(n - 1) % 2].id  # the band opens with "Two Bits" or "Blue Canal"


## Whether `who` is meeting Danny for the first time (and remembers him from now on).
func meet(who: String) -> bool:
	if met.has(who):
		return false
	met[who] = night
	return true


func _pay(r: Rackets, cents: int) -> bool:
	if r.money < cents:
		return false
	r.money -= cents
	return true


func can_coffee(r: Rackets) -> bool:
	return coffees < COFFEES and r.money >= COFFEE


## A cup of coffee at `minute`: paid once; true when it was bought.
func buy_coffee(r: Rackets, minute: float) -> bool:
	if not can_coffee(r) or not _pay(r, COFFEE):
		return false
	coffees += 1
	coffee_at = minute
	return true


## How many game minutes of drowsiness tonight's coffee is holding off at `minute`.
func lift(minute: float) -> float:
	if coffee_at < 0.0 or minute < coffee_at:
		return 0.0
	return COFFEE_LIFT * clampf(1.0 - (minute - coffee_at) / COFFEE_WEARS, 0.0, 1.0)


func can_eat(r: Rackets) -> bool:
	return meals < MEALS and r.money >= MEAL


func buy_meal(r: Rackets) -> bool:
	if not can_eat(r) or not _pay(r, MEAL):
		return false
	meals += 1
	return true


## The rounds Abe Feld would sell Danny now (0: none - none left tonight, no
## money, or no room in his pockets): a box of Eddie's size, never more than
## he can carry.
func feld_rounds(r: Rackets, spare: int) -> int:
	if feld_boxes >= FELD_BOXES or r.money < FELD_BOX:
		return 0
	return mini(r.rules.ammo_box, maxi(0, r.rules.spare_limit - spare))


## Buys Feld's box; returns the rounds (0: no sale, no money taken).
func buy_feld_rounds(r: Rackets, spare: int) -> int:
	var k := feld_rounds(r, spare)
	if k <= 0 or not _pay(r, FELD_BOX):
		return 0
	feld_boxes += 1
	return k


func can_dance(r: Rackets) -> bool:
	return dances < DANCES and r.money >= TICKET


## A ticket and a dance: paid once; true when he danced.
func dance(r: Rackets) -> bool:
	if not can_dance(r) or not _pay(r, TICKET):
		return false
	dances += 1
	danced_total += 1
	return true


static func tune_named(id: String) -> Dictionary:
	for t in TUNES:
		if t.id == id:
			return t
	return TUNES[0]


## A nickel in the bandleader's cup for `id` (not the tune already playing).
func request(r: Rackets, id: String) -> bool:
	if id == tune or tune_named(id).id != id or not _pay(r, TUNE):
		return false
	tunes += 1
	tune = id
	return true


func can_tip(r: Rackets) -> bool:
	return not tipped and r.money >= TIP


func tip(r: Rackets) -> bool:
	if not can_tip(r) or not _pay(r, TIP):
		return false
	tipped = true
	return true


func to_dict() -> Dictionary:
	return {"night": night, "coffees": coffees, "meals": meals, "feld_boxes": feld_boxes, "dances": dances,
		"tunes": tunes, "tipped": tipped, "coffee_at": coffee_at, "tune": tune, "met": met.duplicate(),
		"danced_total": danced_total}


func from_dict(d: Dictionary) -> void:
	night = maxi(1, int(d.get("night", night)))
	coffees = clampi(int(d.get("coffees", 0)), 0, COFFEES)
	meals = clampi(int(d.get("meals", 0)), 0, MEALS)
	feld_boxes = clampi(int(d.get("feld_boxes", 0)), 0, FELD_BOXES)
	dances = clampi(int(d.get("dances", 0)), 0, DANCES)
	tunes = maxi(0, int(d.get("tunes", 0)))
	tipped = bool(d.get("tipped", false))
	coffee_at = float(d.get("coffee_at", -1.0))
	tune = tune_named(String(d.get("tune", tune))).id
	met = {}
	var m: Dictionary = d.get("met", {})
	for k in m:
		met[String(k)] = int(m[k])
	danced_total = maxi(0, int(d.get("danced_total", 0)))
