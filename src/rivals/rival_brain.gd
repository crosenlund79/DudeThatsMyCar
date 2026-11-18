class_name RivalBrain
extends RefCounted
## What Lefty Moran, a North Side gangster, does (pure, no scene). He loiters
## outside Doyle's Garage minding his own business and lets Danny be. Shoot
## at him - hit him or put a round close by - and he turns on Danny: keeps a
## gunfight's distance, fires when he sees him, follows to where he lost him
## and, after a while without a sight of him, cools off (but goes for him
## again on sight that night). Badly hurt, he runs; shot down, he stays down.

enum State { IDLE, HOSTILE, FLEEING, DOWN }

const SIGHT := 520.0
## The distance he keeps in a gunfight, and when he backs off.
const KEEP_AT := 190.0
const TOO_CLOSE := 110.0
const FIRE_RANGE := 430.0
## Seconds between his shots (plus up to FIRE_JITTER), and his first shot's delay.
const FIRE_GAP := 1.3
const FIRE_JITTER := 0.6
const FIRST_SHOT := 0.8
## Seconds without a sight of Danny before he cools off, or stops running.
const CALM_AFTER := 12.0
const FLEE_FOR := 8.0
## Grudge: on sight again within this distance the same night, he goes for Danny.
const GRUDGE_RANGE := 320.0
const LOITER_SPEED := 55.0
const MOVE_SPEED := 115.0
const RUN_SPEED := 130.0

var state := State.IDLE
var post: Array[Vector2] = []
var post_index := 0
var grudge := false
var last_seen := Vector2.ZERO
var _pause := 0.0
var _lost := 0.0
var _rng := RandomNumberGenerator.new()
## M008: his gunfight (the shared Marksman rules, with his numbers).
var marksman: Marksman


func _init(p_post: Array[Vector2] = [], seed_value: int = 1932006) -> void:
	post = p_post
	_rng.seed = seed_value
	marksman = Marksman.new({"keep_at": KEEP_AT, "too_close": TOO_CLOSE, "fire_range": FIRE_RANGE, "gap": FIRE_GAP,
		"jitter": FIRE_JITTER, "first_shot": FIRST_SHOT, "move_speed": MOVE_SPEED}, _rng)


func is_hostile() -> bool:
	return state == State.HOSTILE


## Danny shot at him (Danny was at `danny`).
func provoke(danny: Vector2) -> void:
	if state == State.DOWN:
		return
	if state != State.HOSTILE:
		marksman.ready_up()
	state = State.HOSTILE
	grudge = true
	last_seen = danny
	_lost = 0.0


func fall() -> void:
	state = State.DOWN


## One tick. `sees`: Danny is in sight; `badly_hurt`: his wounds are serious.
## Returns {goal, speed, look, fire}.
func update(dt: float, me: Vector2, danny: Vector2, sees: bool, badly_hurt: bool) -> Dictionary:
	match state:
		State.DOWN:
			return {"goal": me, "speed": 0.0, "look": me + Vector2.RIGHT, "fire": false}
		State.IDLE:
			if grudge and sees and me.distance_to(danny) < GRUDGE_RANGE:
				provoke(danny)
				return update(dt, me, danny, sees, badly_hurt)
			return _loiter(dt, me)
		State.FLEEING:
			if sees:
				_lost = 0.0
			else:
				_lost += dt
			if _lost > FLEE_FOR:
				state = State.IDLE
				return _loiter(dt, me)
			var away := (me - danny).normalized() if me.distance_to(danny) > 1.0 else Vector2.RIGHT
			return {"goal": me + away * 300.0, "speed": RUN_SPEED, "look": me + away * 60.0, "fire": false}
	# hostile
	if badly_hurt:
		state = State.FLEEING
		_lost = 0.0
		return update(dt, me, danny, sees, badly_hurt)
	marksman.cool(dt)
	if not sees:
		_lost += dt
		if _lost > CALM_AFTER:
			state = State.IDLE
			return _loiter(dt, me)
		return {"goal": last_seen, "speed": MOVE_SPEED, "look": last_seen, "fire": false}
	_lost = 0.0
	last_seen = danny
	return marksman.engage(dt, me, danny)


## Minding his own business: strolls between his spots and stands a while at each.
func _loiter(dt: float, me: Vector2) -> Dictionary:
	if post.is_empty():
		return {"goal": me, "speed": 0.0, "look": me + Vector2.DOWN * 40.0, "fire": false}
	var target: Vector2 = post[post_index]
	if me.distance_to(target) < 8.0:
		_pause -= dt
		if _pause <= 0.0:
			post_index = (post_index + 1) % post.size()
			_pause = 5.0 + _rng.randf() * 4.0
		return {"goal": me, "speed": 0.0, "look": me + Vector2.DOWN * 40.0, "fire": false}
	return {"goal": target, "speed": LOITER_SPEED, "look": target, "fire": false}


## A new night: the grudge is forgotten, he is back at his corner (unless dead).
func reset() -> void:
	if state == State.DOWN:
		return
	state = State.IDLE
	grudge = false
	_lost = 0.0
	post_index = 0
