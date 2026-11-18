class_name Marksman
extends RefCounted
## How an armed person fights with a pistol once they mean to (pure, M008;
## Lefty Moran's M006 gunfight rules, now shared with the police): keep a
## gunfight's distance - close in when too far, back off when too close -
## fire only within range, with a clear shot and no faster than the cadence
## allows, and step aside to find a clear line when something is in the way.
## Who to fight and when is the owner's business (RivalBrain, OfficerBrain).

## Distance kept in a gunfight, and when to back off.
var keep_at := 190.0
var too_close := 110.0
var fire_range := 430.0
## Seconds between shots (plus up to `jitter`), and the delay before the
## first shot (drawing, taking aim).
var gap := 1.3
var jitter := 0.6
var first_shot := 0.8
## Speed when closing in, backing off or stepping aside.
var move_speed := 115.0
## How far to the side a blocked shooter steps, and how long before trying the other side.
var side_step := 60.0
var side_time := 1.4
var rng: RandomNumberGenerator
var cooldown := 0.0
var _side := 1.0
var _side_left := 0.0


func _init(settings: Dictionary = {}, p_rng: RandomNumberGenerator = null) -> void:
	for k in settings:
		set(k, settings[k])
	rng = p_rng if p_rng != null else RandomNumberGenerator.new()


## About to start shooting: the first shot comes after `first_shot` seconds.
func ready_up() -> void:
	cooldown = first_shot


## Not before `seconds` from now (taking aim again after losing sight).
func hold_fire(seconds: float) -> void:
	cooldown = maxf(cooldown, seconds)


## Time passes (call every tick while in a fight, in sight or not).
func cool(dt: float) -> void:
	cooldown -= dt


## One tick with the target in sight. `clear_shot`: nothing (a car, a person)
## stands in the line of fire. Returns {goal, speed, look, fire}.
func engage(dt: float, me: Vector2, target: Vector2, clear_shot: bool = true) -> Dictionary:
	var d := me.distance_to(target)
	if not clear_shot:
		# step out from behind whatever is in the way, edging closer; try the other side after a while
		_side_left -= dt
		if _side_left <= 0.0:
			_side = -_side
			_side_left = side_time
		var to := (target - me).normalized() if d > 1.0 else Vector2.RIGHT
		return {"goal": me + to.orthogonal() * _side * side_step + to * 30.0, "speed": move_speed, "look": target, "fire": false}
	var goal := me
	var speed := 0.0
	if d > keep_at + 60.0:
		goal = target
		speed = move_speed
	elif d < too_close:
		goal = me + (me - target).normalized() * 80.0
		speed = move_speed
	var fire := cooldown <= 0.0 and d < fire_range
	if fire:
		cooldown = gap + rng.randf() * jitter
	return {"goal": goal, "speed": speed, "look": target, "fire": fire}


## A shot from `muzzle` along `direction` passed within `near` px of `me`
## (counts as being shot at).
static func passes_near(me: Vector2, muzzle: Vector2, direction: Vector2, near: float = 36.0) -> bool:
	var to := me - muzzle
	var along := to.dot(direction.normalized())
	if along < 0.0 or along > 700.0:
		return false
	return (to - direction.normalized() * along).length() <= near
