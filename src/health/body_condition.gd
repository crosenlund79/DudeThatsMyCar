class_name BodyCondition
extends RefCounted
## Where a person is hurt and how badly (pure, no scene), for Danny and for
## everybody else who can be shot. Six regions - head, torso, both arms, both
## legs - each with damage 0..100, read as fine, grazed, wounded or badly
## hurt. A .45 round lands in one region (the side it came from decides left
## or right); a bad head wound, a torso at 90 or a body that has taken 200 in
## all is fatal (about one round to the head, two to the body, four or five
## to the arms and legs). Wounded legs slow a person down; a wounded gun arm spoils the aim.
## Nothing is random beyond the draw passed in, so tests can repeat it.

const REGIONS: Array[String] = ["head", "torso", "left_arm", "right_arm", "left_leg", "right_leg"]
const NAMES := {"head": "head", "torso": "body", "left_arm": "left arm", "right_arm": "right arm",
	"left_leg": "left leg", "right_leg": "right leg"}
## Wound levels and where they begin (damage).
enum Level { FINE, GRAZED, WOUNDED, CRITICAL }
const GRAZED := 1
const WOUNDED := 40
const CRITICAL := 75
const MAX := 100
const FATAL_TORSO := 90
const FATAL_TOTAL := 200
## A pistol round, and how much more or less each region takes of it.
const ROUND := 46.0
const MULTIPLIER := {"head": 1.7, "torso": 1.0, "left_arm": 0.9, "right_arm": 0.9, "left_leg": 0.9, "right_leg": 0.9}

var damage := {}


func _init() -> void:
	for r in REGIONS:
		damage[r] = 0


## The region a round strikes: `side` > 0 when it hits the person's right
## side (relative to where they face), `u` a draw in [0, 1) for the height.
static func region_for(side: float, u: float) -> String:
	var right := side > 0.0
	if u < 0.12:
		return "head"
	if u < 0.55:
		return "torso"
	if u < 0.8:
		return "right_arm" if right else "left_arm"
	return "right_leg" if right else "left_leg"


## A round in `region`; `u` in [0, 1) varies it by up to 15%. Returns the damage done.
func shoot(region: String, u: float = 0.5) -> int:
	var amount := int(round(ROUND * float(MULTIPLIER[region]) * (0.85 + 0.3 * u)))
	return hurt(region, amount)


## M015: what a car does to a person it strikes at `impact` px/s (closing
## speed), the near side `right` (the side it came from): {region: damage}.
## A clip at a crawl bruises the near leg; a hard knock hurts both legs and
## the body; at a fast town speed (about 250 px/s and up) the blow is
## fatal - the head and an arm too.
const CAR_GENTLE := 70.0
const CAR_FATAL := 300.0
static func car_injuries(impact: float, right: bool) -> Dictionary:
	var k := clampf((impact - CAR_GENTLE) / (CAR_FATAL - CAR_GENTLE), 0.0, 1.4)
	var near := "right_leg" if right else "left_leg"
	var far := "left_leg" if right else "right_leg"
	var out := {near: int(round(22.0 + 66.0 * k)), far: int(round(8.0 + 40.0 * k)), "torso": int(round(6.0 + 88.0 * k))}
	if k > 0.75:
		out["head"] = int(round(60.0 * (k - 0.75) / 0.65 * 1.4))
		out["right_arm" if right else "left_arm"] = int(round(30.0 * k))
	return out


func hurt(region: String, amount: int) -> int:
	var before: int = damage[region]
	damage[region] = mini(MAX, before + maxi(0, amount))
	return damage[region] - before


static func level_of(amount: int) -> int:
	if amount >= CRITICAL:
		return Level.CRITICAL
	if amount >= WOUNDED:
		return Level.WOUNDED
	if amount >= GRAZED:
		return Level.GRAZED
	return Level.FINE


func level(region: String) -> int:
	return level_of(damage[region])


## "fine", "grazed", "wounded", "badly hurt".
static func label(lvl: int) -> String:
	return ["fine", "grazed", "wounded", "badly hurt"][lvl]


func total() -> int:
	var t := 0
	for r in REGIONS:
		t += int(damage[r])
	return t


func is_fatal() -> bool:
	return damage.head >= CRITICAL or damage.torso >= FATAL_TORSO or total() >= FATAL_TOTAL


func is_hurt() -> bool:
	return total() > 0


## The worst wound anywhere.
func worst() -> int:
	var w := 0
	for r in REGIONS:
		w = maxi(w, level(r))
	return w


## How fast they can still walk (1 = unhurt): each wounded leg slows them.
func speed_factor() -> float:
	var f := 1.0
	for leg in ["left_leg", "right_leg"]:
		match level(leg):
			Level.WOUNDED:
				f -= 0.2
			Level.CRITICAL:
				f -= 0.35
	return maxf(f, 0.45)


## Extra spread on their shots (degrees): the gun hand is the right one.
func aim_spread() -> float:
	var s := 0.0
	s += [0.0, 0.0, 3.0, 6.0][level("right_arm")]
	s += [0.0, 0.0, 1.0, 2.0][level("left_arm")]
	return s


## A night's sleep: grazes heal, wounds stay until someone treats them.
func rest() -> void:
	for r in REGIONS:
		if int(damage[r]) < WOUNDED:
			damage[r] = 0


## Patched up properly (the vet): good as new.
func heal_all() -> void:
	for r in REGIONS:
		damage[r] = 0


## Patched up in a hurry after going down: everything back to a graze at most.
func patch_up() -> void:
	for r in REGIONS:
		damage[r] = mini(int(damage[r]), WOUNDED - 1)


## What Doc Pettibone charges to patch all of it up (cents): a visit, and
## each region by how bad it is (provisional prices).
const VISIT := 200
const PRICE := [0, 150, 400, 800]


func treatment_price() -> int:
	if not is_hurt():
		return 0
	var cents := VISIT
	for r in REGIONS:
		cents += PRICE[level(r)]
	return cents


func to_dict() -> Dictionary:
	return damage.duplicate()


func from_dict(d: Dictionary) -> void:
	for r in REGIONS:
		damage[r] = clampi(int(d.get(r, 0)), 0, MAX)
