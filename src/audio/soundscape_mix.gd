class_name SoundscapeMix
extends RefCounted
## What the night sounds like from where Danny is (pure, no scene): how loud
## and how muffled the Copper Owl's band and crowd are through its walls, how
## much of the street, the alleys and the river reaches him, and when the
## city throws in a distant horn. The Soundscape node plays the sounds; this
## only decides the levels, so the rules can be tested without a sound card.
##
## Levels are in dB relative to each sound's own recording; "cutoff" is the
## low-pass the walls (or a car body) put on a sound, OPEN meaning no filter.

const SILENT_DB := -80.0
## Anything quieter than this is treated as silent.
const AUDIBLE_DB := -60.0
const OPEN := 20500.0

## Inside the club: the band at full (a little under the recording, for
## headroom under the crowd), the crowd under it.
const MUSIC_INSIDE_DB := -3.0
const CROWD_INSIDE_DB := -9.0
## Through the walls: what is left right outside them, and the low-pass there
## (the bass and the beat come through, the voice is a murmur).
const WALL_DB := -9.0
const WALL_CUTOFF := 700.0
const FAR_CUTOFF := 240.0
## Two walls (from another room) and a car's body take a little more off.
const OTHER_ROOM_DB := -10.0
const OTHER_ROOM_CUTOFF := 320.0
const IN_CAR_DB := -8.0
## The street's bed, the alley and the river at full (outdoors).
const STREET_DB := -12.0
const ALLEY_DB := -11.0
const RIVER_DB := -10.0
## M010: the rain at full (outdoors; through the windows indoors, dull - the street bus).
const RAIN_DB := -8.0
## M012: a downpour over the rain, at full.
const DOWNPOUR_DB := -7.0
## Indoors the street comes through the windows, dull; a closed car muffles less.
const INDOOR_STREET_CUTOFF := 650.0
const CAR_STREET_CUTOFF := 2800.0
## Narration over the city: everything else steps back this far.
const DUCK_DB := -10.0
## M011: the Copper Owl's back rooms (the card room, the gaming room): their own
## bed, quiet under the games, and the odd sound of the room now and then.
const BACK_ROOMS := ["back_room", "gaming_room"]
const GAMING_DB := -12.0
const ROOM_EVENT_DB := -11.0


## Where the listener stands, as plain numbers for `targets`. `room` is the
## room he is in (null outdoors), `activity` the street activity of the hour
## (NightClock.activity: 1 in the evening, down to 0.2 before dawn).
static func listen(layout: DistrictLayout, club: InteriorPlan, p: Vector2, room: InteriorPlan,
		driving: bool, activity: float) -> Dictionary:
	var club_rect: Rect2 = club.building_rect if club != null else Rect2()
	var alley := 0.0
	for a in layout.alleys:
		alley = maxf(alley, clampf(1.0 - rect_distance(a.rect, p) / 70.0, 0.0, 1.0))
	var river_d := INF
	for w in layout.water:
		river_d = minf(river_d, rect_distance(w, p))
	return {
		"in_club": club != null and room == club,
		"indoors": room != null,
		"back_room": room != null and room.id in BACK_ROOMS,
		"driving": driving,
		"club_distance": rect_distance(club_rect, p) if club != null else INF,
		"club_dx": club_rect.get_center().x - p.x,
		"alley": alley,
		"river": pow(clampf(1.0 - (river_d - 60.0) / 840.0, 0.0, 1.0), 1.5),
		"activity": clampf(activity, 0.0, 1.0),
	}


## Distance from p to the nearest point of r (0 inside it).
static func rect_distance(r: Rect2, p: Vector2) -> float:
	var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
	var dy := maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y)
	return Vector2(dx, dy).length()


## The level and filter of every layer for a listening context.
static func targets(l: Dictionary) -> Dictionary:
	var out := club(l)
	var act: float = l.activity
	var indoors: bool = l.indoors
	var street_lin := (0.45 + 0.55 * act) * (1.0 - 0.6 * float(l.alley))
	var alley_lin := float(l.alley) * (0.4 if indoors else 1.0)
	var river_lin := float(l.river) * (0.5 if l.driving else 1.0) * (0.4 if indoors else 1.0)
	if indoors:
		street_lin *= 0.5
	out.street_db = _db(STREET_DB, street_lin)
	out.alley_db = _db(ALLEY_DB, alley_lin)
	out.river_db = _db(RIVER_DB, river_lin)
	var rain_lin := float(l.get("rain", 0.0)) * (0.45 if indoors else (0.7 if l.driving else 1.0))
	out.rain_db = _db(RAIN_DB, rain_lin)
	var pour_lin := float(l.get("downpour", 0.0)) * (0.35 if indoors else (0.7 if l.driving else 1.0))
	out.downpour_db = _db(DOWNPOUR_DB, pour_lin)
	out.street_cutoff = INDOOR_STREET_CUTOFF if indoors else (CAR_STREET_CUTOFF if l.driving else OPEN)
	out.gaming_db = GAMING_DB if l.get("back_room", false) else SILENT_DB
	return out


## The Copper Owl's band and crowd: full inside; outside, through the walls,
## quieter and duller with every step away, and from the club's side.
static func club(l: Dictionary) -> Dictionary:
	var act: float = l.activity
	var crowd_inside := CROWD_INSIDE_DB + linear_to_db(0.6 + 0.4 * act)
	if l.in_club:
		return {"music_db": MUSIC_INSIDE_DB, "crowd_db": crowd_inside, "club_cutoff": OPEN, "club_pan": 0.0}
	var d: float = l.club_distance
	if d == INF:
		return {"music_db": SILENT_DB, "crowd_db": SILENT_DB, "club_cutoff": FAR_CUTOFF, "club_pan": 0.0}
	var through := WALL_DB - 20.0 * log(1.0 + d / 60.0) / log(10.0) - d * 0.02
	var cutoff := FAR_CUTOFF + (WALL_CUTOFF - FAR_CUTOFF) * exp(-d / 250.0)
	if l.indoors:
		through += OTHER_ROOM_DB
		cutoff = minf(cutoff, OTHER_ROOM_CUTOFF)
	if l.driving:
		through += IN_CAR_DB
		cutoff *= 0.8
	var pan := 0.75 * clampf(float(l.club_dx) / 260.0, -1.0, 1.0) * clampf((d + 20.0) / 140.0, 0.0, 1.0)
	return {
		"music_db": _cut(MUSIC_INSIDE_DB + through),
		"crowd_db": _cut(crowd_inside + through - 6.0),
		"club_cutoff": cutoff,
		"club_pan": pan,
	}


static func _db(full_db: float, linear: float) -> float:
	if linear <= 0.001:
		return SILENT_DB
	return _cut(full_db + linear_to_db(linear))


static func _cut(db: float) -> float:
	return db if db > AUDIBLE_DB else SILENT_DB


## Moves a level toward its target smoothly (time constant tau seconds): no
## jumps, whatever the frame rate. From silence it starts at the edge of
## hearing, so a sound fades in rather than waiting at -80 dB.
static func glide_db(current: float, target: float, delta: float, tau: float) -> float:
	if current <= SILENT_DB and target > SILENT_DB:
		current = AUDIBLE_DB
	var next := current + (target - current) * (1.0 - exp(-delta / maxf(tau, 0.001)))
	if target <= SILENT_DB and next < AUDIBLE_DB:
		return SILENT_DB
	return next


## The same for a filter cutoff, in octaves (so a door opening sweeps evenly).
static func glide_cutoff(current: float, target: float, delta: float, tau: float) -> float:
	var a := log(current) / log(2.0)
	var b := log(target) / log(2.0)
	return pow(2.0, a + (b - a) * (1.0 - exp(-delta / maxf(tau, 0.001))))


## Seconds until the next distant sound of a kind, given how busy the night is
## and a random draw u in [0, 1): horns thin out after midnight; the river and
## the alleys keep their own slow time.
static func next_gap(kind: String, activity: float, u: float) -> float:
	var base := 0.0
	match kind:
		"horn":
			base = 24.0 / maxf(activity, 0.2)
		"foghorn":
			base = 55.0
		"clatter":
			base = 38.0
		"room":
			base = 5.5  # M011: something in the back room every few seconds
		_:
			base = 30.0
	return base * (0.6 + 0.8 * u)


## Whether a distant sound of a kind would be heard here at all.
static func can_hear(kind: String, l: Dictionary) -> bool:
	if kind == "room":
		return l.get("back_room", false)  # M011
	if l.in_club:
		return false
	match kind:
		"horn":
			return true
		"foghorn":
			return float(l.river) > 0.15
		"clatter":
			return float(l.alley) > 0.3
	return false
