class_name GamingRoom
extends RefCounted
## M013: the gaming room's evening (pure, no scene): which of the regulars
## (Patrons.ROSTER) is in at a given minute and where - at the wheel's rail,
## at a machine, with a drink, watching - so the room is quiet early, fuller
## late, and thins out towards closing; nobody after four. The same night
## always goes the same way (seeded by the night), and other nights a little
## differently. Nothing is simulated while Danny is elsewhere: the room as he
## walks in is simply the schedule at that minute.
##
## Each regular keeps his own places (RiversideInteriors.ROOM_SPOTS), so no
## two ever want the same one; the Bell is left free for Danny.

## When the room closes (game minutes after the evening's midnight: 4 am).
const CLOSE := 28 * 60.0
## Each regular: when he usually comes in and goes home, and what he does in
## between - his places, each with a weight (how much of his night).
const PLAN := {
	"edna": {"in": 19 * 60 + 50.0, "out": 26 * 60 + 30.0, "places": [["rail_edna", 0.8], ["sideboard", 0.2]]},
	"bertie": {"in": 20 * 60 + 10.0, "out": 27 * 60 + 50.0, "places": [["table1_l", 0.55], ["rail_east", 0.45]]},
	"stan": {"in": 21 * 60 + 15.0, "out": 27 * 60 + 40.0, "places": [["rail_stan", 0.75], ["watch_ne", 0.25]]},
	"dolly": {"in": 21 * 60 + 40.0, "out": 27 * 60 + 0.0, "places": [["slot_0", 0.7], ["table1_r", 0.3]]},
	"mick": {"in": 23 * 60 + 0.0, "out": 26 * 60 + 45.0, "places": [["slot_2", 0.65], ["table2", 0.35]]},
}
## How long a regular keeps to one thing (game minutes).
const STAY := Vector2(8.0, 24.0)
## How far from his usual times a night may put him (game minutes).
const JITTER := 20.0

var night := -1
## id -> {"in", "out", "blocks": [{from, to, spot}]}
var nights := {}


func begin_night(n: int) -> void:
	night = n
	nights = {}
	for id in PLAN:
		var p: Dictionary = PLAN[id]
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([n, id, "gaming room"])
		var come := float(p.in) + rng.randf_range(-JITTER, JITTER)
		var go := minf(float(p.out) + rng.randf_range(-JITTER, JITTER), CLOSE - 2.0)
		var blocks := []
		var t := come
		var last := ""
		while t < go:
			var spot := _pick(p.places, rng, last)
			var stay := rng.randf_range(STAY.x, STAY.y)
			blocks.append({"from": t, "to": minf(t + stay, go), "spot": spot})
			last = spot
			t += stay
		nights[id] = {"in": come, "out": go, "blocks": blocks}


func _pick(places: Array, rng: RandomNumberGenerator, last: String) -> String:
	# a weighted choice, rarely the same thing twice running
	var total := 0.0
	for pl in places:
		total += float(pl[1]) * (0.35 if pl[0] == last else 1.0)
	var x := rng.randf() * total
	for pl in places:
		x -= float(pl[1]) * (0.35 if pl[0] == last else 1.0)
		if x <= 0.0:
			return String(pl[0])
	return String(places[-1][0])


## Where `id` is at `minute` ("" when he is not in).
func spot_of(id: String, minute: float) -> String:
	var d: Dictionary = nights.get(id, {})
	if d.is_empty() or minute < float(d.in) or minute >= float(d.out) or minute >= CLOSE:
		return ""
	for b in d.blocks:
		if minute >= float(b.from) and minute < float(b.to):
			return String(b.spot)
	return ""


## Who is in at `minute`.
func present(minute: float) -> Array:
	var out := []
	for id in PLAN:
		if spot_of(id, minute) != "":
			out.append(id)
	return out


## The next minute (after `minute`) at which anything changes for `id`.
func next_change(id: String, minute: float) -> float:
	var d: Dictionary = nights.get(id, {})
	if d.is_empty():
		return INF
	if minute < float(d.in):
		return float(d.in)
	for b in d.blocks:
		if float(b.to) > minute:
			return float(b.to)
	return INF


## What a place is for: "wheel", "slots" or "idle".
static func kind_of(spot: String) -> String:
	if spot.begins_with("rail_"):
		return "wheel"
	if spot.begins_with("slot_"):
		return "slots"
	return "idle"
