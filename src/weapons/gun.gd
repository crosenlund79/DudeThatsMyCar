class_name Gun
extends RefCounted
## A handgun's state (pure, deterministic, no scene): under the coat until the
## trigger is pulled, drawn, one shot per pull, reloads by itself when empty,
## back under the coat after a while without shooting. step() advances it by
## one tick and reports what happened ("drawn", "fired", "reload", "reloaded",
## "holstered", "empty": a click with no rounds left anywhere) so the game can
## fire the bullet and play the sounds. Reloads come out of the spare rounds
## (M003); -1 spare rounds never run out.

enum State { HOLSTERED, DRAWING, READY, RELOADING }

var rules: GunRules
var state := State.HOLSTERED
var ammo := 0
## Rounds carried besides the magazine (-1 = never run out).
var spare := -1
var _timer := 0.0
var _cooldown := 0.0
## Seconds a trigger pull keeps waiting to be fired (-1: none waiting).
var _pull := -1.0
var _idle := 0.0


func _init(p_rules: GunRules) -> void:
	rules = p_rules
	ammo = rules.magazine
	spare = rules.spare_rounds


func is_drawn() -> bool:
	return state != State.HOLSTERED


func is_reloading() -> bool:
	return state == State.RELOADING


## Nothing in the magazine and nothing to reload with.
func is_dry() -> bool:
	return ammo == 0 and spare == 0


## More rounds in the pocket (a box from the dealer). An empty gun reloads.
func add_spare(n: int) -> void:
	if spare < 0 or n <= 0:
		return
	spare += n
	if ammo == 0 and state == State.READY:
		_start_reload()


func _start_reload() -> void:
	state = State.RELOADING
	_timer = rules.reload_time


## The player clicked. Draws the gun first if it is under the coat.
func trigger() -> void:
	if state == State.HOLSTERED:
		state = State.DRAWING
		_timer = rules.draw_time
		_pull = rules.draw_time + rules.trigger_buffer
	elif state == State.RELOADING:
		return
	else:
		_pull = rules.trigger_buffer
	_idle = 0.0


## M008: draws the gun without firing (someone who holds his fire until he has a shot).
func draw() -> void:
	if state == State.HOLSTERED:
		state = State.DRAWING
		_timer = rules.draw_time
		_pull = -1.0
		_idle = 0.0


## Puts the gun away at once (getting into a car). Ammunition is kept.
func holster() -> void:
	state = State.HOLSTERED
	_pull = -1.0
	_idle = 0.0


func step(dt: float) -> PackedStringArray:
	var events := PackedStringArray()
	_cooldown = maxf(0.0, _cooldown - dt)
	if _pull >= 0.0:
		_pull -= dt
	match state:
		State.DRAWING:
			_timer -= dt
			if _timer <= 0.0:
				state = State.READY
				events.append("drawn")
		State.RELOADING:
			_timer -= dt
			if _timer <= 0.0:
				var take := rules.magazine if spare < 0 else mini(rules.magazine, spare)
				ammo = take
				if spare >= 0:
					spare -= take
				state = State.READY
				_idle = 0.0
				events.append("reloaded")
	if state == State.READY:
		if _pull >= 0.0 and _cooldown <= 0.0 and ammo == 0:
			_pull = -1.0
			_idle = 0.0
			events.append("empty")
		elif _pull >= 0.0 and _cooldown <= 0.0 and ammo > 0:
			ammo -= 1
			_cooldown = rules.fire_interval
			_pull = -1.0
			_idle = 0.0
			events.append("fired")
			if ammo == 0 and spare != 0:
				_start_reload()
				events.append("reload")
		else:
			_idle += dt
			if _idle >= rules.holster_after and _pull < 0.0:
				state = State.HOLSTERED
				events.append("holstered")
	return events
