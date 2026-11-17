class_name Gun
extends RefCounted
## A handgun's state (pure, deterministic, no scene): under the coat until the
## trigger is pulled, drawn, one shot per pull, reloads by itself when empty,
## back under the coat after a while without shooting. step() advances it by
## one tick and reports what happened ("drawn", "fired", "reload", "reloaded",
## "holstered") so the game can fire the bullet and play the sounds.

enum State { HOLSTERED, DRAWING, READY, RELOADING }

var rules: GunRules
var state := State.HOLSTERED
var ammo := 0
var _timer := 0.0
var _cooldown := 0.0
## Seconds a trigger pull keeps waiting to be fired (-1: none waiting).
var _pull := -1.0
var _idle := 0.0


func _init(p_rules: GunRules) -> void:
	rules = p_rules
	ammo = rules.magazine


func is_drawn() -> bool:
	return state != State.HOLSTERED


func is_reloading() -> bool:
	return state == State.RELOADING


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
				ammo = rules.magazine
				state = State.READY
				_idle = 0.0
				events.append("reloaded")
	if state == State.READY:
		if _pull >= 0.0 and _cooldown <= 0.0 and ammo > 0:
			ammo -= 1
			_cooldown = rules.fire_interval
			_pull = -1.0
			_idle = 0.0
			events.append("fired")
			if ammo == 0:
				state = State.RELOADING
				_timer = rules.reload_time
				events.append("reload")
		else:
			_idle += dt
			if _idle >= rules.holster_after and _pull < 0.0:
				state = State.HOLSTERED
				events.append("holstered")
	return events
