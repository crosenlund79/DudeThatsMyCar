class_name StreetIncidents
extends RefCounted
## The city's own small troubles (M009), as plain state that runs on the night
## clock whether Danny is there or not. Three kinds: an ARGUMENT between two
## people at a kerb (talking, getting heated, parting), a suspicious EXCHANGE
## in a quiet spot (one waits, the other comes, a package changes hands, they
## go), and a police STOP (the district's beat cop questions somebody, searches
## him, lets him go or takes him in).
##
## Each night has its own plan, drawn from a seed: a few incidents at spaced
## times, each at an authored spot that suits its kind. When its time comes
## an incident begins - unless two are already going on, its spot is taken,
## or Danny is standing right there (it is put off a little instead: the city
## does not stage its troubles in front of him). It goes through its phases on
## the clock and ends with an outcome; ignored, the outcome is the city's own
## (deterministic per incident). Danny can step in while it is going on and
## change how it ends. What happened is kept for the night (so a reloaded
## night does not hand him the same thing twice) and, for the notable ends,
## passed on as talk by the named person who saw it.
## Pure: no scene. Its presentation is IncidentViews.

## Phases and their lengths (game minutes).
const PHASES := {
	"argument": [["talking", 12.0], ["heated", 14.0], ["parting", 5.0]],
	"exchange": [["waiting", 12.0], ["handing", 8.0], ["leaving", 5.0]],
	"stop": [["questioning", 14.0], ["searching", 10.0], ["leaving", 5.0]],
}
const KINDS := ["argument", "exchange", "stop"]
## The plan: the first incident this long after dusk, then one every so often.
const FIRST := 25.0
const GAP_MIN := 40.0
const GAP_MAX := 75.0
## Not within the last hour before dawn.
const LAST_BEFORE_DAWN := 60.0
const MAX_ACTIVE := 2
## A new incident never begins this close to Danny (it waits instead), and
## two never share a stretch of pavement.
const KEEP_CLEAR := 650.0
const APART := 240.0
const POSTPONE := 20.0
const MAX_POSTPONES := 3
## The notable endings (they become talk).
const NOTABLE := ["blows", "broken_up", "scattered", "robbed", "spoiled", "hushed", "taken_in", "vouched", "bribed", "shooting"]

var night := 0
## Every spot in the city: {id, district, kinds, pos, along, local, place}.
var spots: Array = []
## Tonight's plan: {id, kind, spot, at, tries}.
var plan: Array = []
## Going on now: {id, kind, spot (dict), phase, left, outcome, mercer, seen, started}
var active: Array = []
## Over tonight: {id, kind, spot, outcome, mercer}.
var history: Array = []
var minute := 0.0
var _start_minute := 0.0
var _dawn := 0.0


func _init(p_spots: Array = []) -> void:
	spots = p_spots


## A new night: tonight's plan from the night's seed (the same night always
## has the same plan). `done`: incidents already over tonight (a reloaded
## night), which do not happen again.
func begin_night(p_night: int, start_minute: float, dawn_minute: float, done: Array = []) -> void:
	night = p_night
	minute = start_minute
	_start_minute = start_minute
	_dawn = dawn_minute
	active.clear()
	history = done.duplicate(true)
	plan.clear()
	if spots.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 1932009 + p_night * 7919
	var t := start_minute + FIRST + rng.randf_range(0.0, 15.0)
	var last_kind := ""
	var k := 0
	while t < dawn_minute - LAST_BEFORE_DAWN:
		var kinds := KINDS.filter(func(x: String) -> bool: return x != last_kind)
		var kind: String = kinds[rng.randi_range(0, kinds.size() - 1)]
		var fits := spots.filter(func(s: Dictionary) -> bool: return (s.kinds as Array).has(kind))
		if not fits.is_empty():
			var spot: Dictionary = fits[rng.randi_range(0, fits.size() - 1)]
			var id := "n%d_%d" % [p_night, k]
			if not history.any(func(h: Dictionary) -> bool: return h.id == id):
				plan.append({"id": id, "kind": kind, "spot": spot.id, "at": t, "tries": 0})
			last_kind = kind
			k += 1
		t += rng.randf_range(GAP_MIN, GAP_MAX)


## Every district's spots, each marked with its district.
static func spots_of(layouts: Array) -> Array:
	var out := []
	for l in layouts:
		for s in (l as DistrictLayout).incident_spots:
			var c: Dictionary = s.duplicate()
			c["district"] = (l as DistrictLayout).id
			out.append(c)
	return out


## What the people round about make of how it ended: {kind of talk, memory
## kind for the named person who saw Danny's part (or "")}.
static func reading(inc: Dictionary) -> Dictionary:
	var memory := ""
	match String(inc.outcome):
		"broken_up", "vouched":
			memory = "favour"
		"scattered", "robbed":
			memory = "threat"
		"hushed", "bribed":
			memory = "deal"
	return {"talk": "street_%s_%s" % [inc.kind, inc.outcome] if NOTABLE.has(inc.outcome) else "", "memory": memory}


func spot(id: String) -> Dictionary:
	for s in spots:
		if s.id == id:
			return s
	return {}


func get_incident(id: String) -> Dictionary:
	for inc in active:
		if inc.id == id:
			return inc
	return {}


func phase_name(inc: Dictionary) -> String:
	var phases: Array = PHASES[inc.kind]
	return phases[mini(int(inc.phase), phases.size() - 1)][0]


## How far through its current phase an incident is (0..1).
func progress(inc: Dictionary) -> float:
	var phases: Array = PHASES[inc.kind]
	var length: float = phases[mini(int(inc.phase), phases.size() - 1)][1]
	return clampf(1.0 - float(inc.left) / length, 0.0, 1.0)


## Time passes to `p_minute`. `danny`: where he is (a new incident does not
## begin right by him; Vector2.INF: nowhere near). `can_stop`: func(district)
## -> bool, whether that district's beat cop is free for a stop (a loaded
## district's man may be busy chasing somebody). Returns what happened:
## [{event: "started" | "phase" | "over", incident}].
func advance(p_minute: float, danny: Vector2 = Vector2.INF, can_stop: Callable = Callable()) -> Array:
	var events := []
	var dt := maxf(0.0, p_minute - minute)
	minute = p_minute
	# what is going on moves on
	for inc in active.duplicate():
		var left := dt
		while left > 0.0 and inc.phase < (PHASES[inc.kind] as Array).size():
			var step := minf(left, float(inc.left))
			inc.left = float(inc.left) - step
			left -= step
			if inc.left <= 0.0:
				inc.phase = int(inc.phase) + 1
				if inc.phase >= (PHASES[inc.kind] as Array).size():
					events.append(_finish(inc))
					break
				if inc.phase == (PHASES[inc.kind] as Array).size() - 1 and inc.outcome == "":
					inc.outcome = _own_outcome(inc)
				inc.left = (PHASES[inc.kind] as Array)[inc.phase][1]
				events.append({"event": "phase", "incident": inc})
	# what is due begins (or waits)
	for p in plan.duplicate():
		if float(p.at) > minute:
			continue
		var s := spot(p.spot)
		var blocked: bool = active.size() >= MAX_ACTIVE or _taken(s) \
			or (danny != Vector2.INF and danny.distance_to(s.pos) < KEEP_CLEAR) \
			or (p.kind == "stop" and can_stop.is_valid() and not can_stop.call(s.district))
		if blocked:
			p.tries = int(p.tries) + 1
			p.at = float(p.at) + POSTPONE
			if p.tries > MAX_POSTPONES or float(p.at) > _dawn - LAST_BEFORE_DAWN:
				plan.erase(p)
			continue
		plan.erase(p)
		var inc := {"id": p.id, "kind": p.kind, "spot": s, "phase": 0, "left": (PHASES[p.kind] as Array)[0][1],
			"outcome": "", "mercer": "", "seen": false, "started": minute}
		active.append(inc)
		events.append({"event": "started", "incident": inc})
	return events


func _taken(s: Dictionary) -> bool:
	return active.any(func(inc: Dictionary) -> bool: return (inc.spot.pos as Vector2).distance_to(s.pos) < APART)


## How it ends when nobody steps in (the same incident always ends the same way).
func _own_outcome(inc: Dictionary) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(inc.id)
	var roll := rng.randf()
	match inc.kind:
		"argument":
			return "blows" if roll < 0.35 else "settled"
		"exchange":
			return "done"
		"stop":
			return "taken_in" if roll < 0.4 else "released"
	return "over"


func _finish(inc: Dictionary) -> Dictionary:
	if inc.outcome == "":
		inc.outcome = _own_outcome(inc)
	active.erase(inc)
	history.append({"id": inc.id, "kind": inc.kind, "spot": inc.spot.id, "outcome": inc.outcome, "mercer": inc.mercer})
	return {"event": "over", "incident": inc}


## Danny steps in (the incident must be going on and not settled yet).
## `choice` by kind - argument: "calm" (break it up) or "lean" (lean on
## them); exchange: "see" (asks to see the package), "cut" (asks for a cut)
## or "rob" (takes it, gun in hand); stop: "vouch" (he's with me) or "bribe"
## (a dollar for the officer). Returns {outcome, ok} and moves the incident
## on to its last phase (they part, go, or the officer lets go).
func intervene(id: String, choice: String, context: Dictionary = {}) -> Dictionary:
	var inc := get_incident(id)
	if inc.is_empty() or inc.mercer != "" or inc.phase >= (PHASES[inc.kind] as Array).size() - 1:
		return {"outcome": "", "ok": false}
	var gun: bool = context.get("gun_drawn", false)
	var outcome := ""
	match [inc.kind, choice]:
		["argument", "calm"]:
			outcome = "broken_up"
		["argument", "lean"]:
			outcome = "scattered"
		["exchange", "see"]:
			outcome = "spoiled"
		["exchange", "cut"]:
			outcome = "hushed"
		["exchange", "rob"]:
			outcome = "robbed" if gun else "spoiled"
		["stop", "vouch"]:
			outcome = "vouched"
		["stop", "bribe"]:
			outcome = "bribed"
	if outcome == "":
		return {"outcome": "", "ok": false}
	inc.mercer = choice
	inc.outcome = outcome
	inc.phase = (PHASES[inc.kind] as Array).size() - 1
	inc.left = (PHASES[inc.kind] as Array)[inc.phase][1]
	return {"outcome": outcome, "ok": true}


## Something broke it off (gunfire, the officer called away, a participant
## shot): it ends at once.
func break_off(id: String, outcome: String) -> Dictionary:
	var inc := get_incident(id)
	if inc.is_empty():
		return {}
	inc.outcome = outcome
	return _finish(inc)


## The incident going on at a spot near p (within `reach`), or {}.
func near(p: Vector2, reach: float) -> Dictionary:
	for inc in active:
		if (inc.spot.pos as Vector2).distance_to(p) <= reach:
			return inc
	return {}


func to_dict() -> Dictionary:
	return {"night": night, "history": history.duplicate(true)}


## The night's history (a reloaded night begins again at dusk with these
## incidents over already).
static func saved_history(d: Dictionary, p_night: int) -> Array:
	if int(d.get("night", -1)) != p_night:
		return []
	var out := []
	for h in d.get("history", []):
		out.append({"id": String(h.id), "kind": String(h.kind), "spot": String(h.spot), "outcome": String(h.outcome),
			"mercer": String(h.get("mercer", ""))})
	return out
