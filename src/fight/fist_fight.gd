class_name FistFight
extends RefCounted
## A fistfight as five timing checks on a dial (pure, no scene; reusable for
## any opponent). For each check a needle sweeps round from the top and a zone
## is lit somewhere on the far side; press when the needle is in the zone and
## the punch lands (or the block holds); press early, late or not at all and
## it is the other man's turn. Win `wins_needed` of `checks` and the fight is
## Danny's. Each check's zone and speed are drawn from a seeded generator, so
## the same fight can be replayed exactly (tests).
##
## `zone_bonus` widens (or, negative, narrows) the zone - a tip about the
## other man's habits, Danny's own wounds; `speed_scale` slows or quickens the
## needle (a hurt opponent is slower).

enum Phase { LEAD_IN, RUNNING, FEEDBACK, OVER }

var rules: FightRules
var phase := Phase.LEAD_IN
## The check under way (0-based), the needle (degrees from the top,
## clockwise), the zone (start, width) and the needle's speed.
var index := 0
var needle := 0.0
var zone_start := 0.0
var zone_width := 0.0
var speed := 0.0
## true / false per finished check.
var results: Array[bool] = []
var zone_bonus := 0.0
var speed_scale := 1.0
var _timer := 0.0
var _rng := RandomNumberGenerator.new()


func _init(p_rules: FightRules = null, seed_value: int = 1932, p_zone_bonus := 0.0, p_speed_scale := 1.0) -> void:
	rules = p_rules if p_rules != null else FightRules.new()
	_rng.seed = seed_value
	zone_bonus = p_zone_bonus
	speed_scale = p_speed_scale
	_prepare()


func _prepare() -> void:
	phase = Phase.LEAD_IN
	_timer = rules.lead_in
	needle = 0.0
	zone_width = clampf(rules.zone_width + zone_bonus, 24.0, 120.0)
	zone_start = _rng.randf_range(rules.zone_earliest, rules.zone_latest - zone_width * 0.5)
	speed = rules.needle_speed * speed_scale * (1.0 + _rng.randf_range(-rules.speed_variation, rules.speed_variation))


## Whether an angle (degrees) lies in the lit zone.
func in_zone(angle: float = needle) -> bool:
	return angle >= zone_start and angle <= zone_start + zone_width


func wins() -> int:
	return results.count(true)


func is_over() -> bool:
	return phase == Phase.OVER


func won() -> bool:
	return wins() >= rules.wins_needed


## Space pressed. Returns "hit", "miss" or "" (nothing to press for right now).
func press() -> String:
	if phase != Phase.RUNNING:
		return ""
	return _finish(in_zone())


## Time passes. Returns what happened: "start" (a check begins), "miss" (the
## needle swept past the zone), "next" (the result has shown), "over", or "".
func update(dt: float) -> String:
	match phase:
		Phase.LEAD_IN:
			_timer -= dt
			if _timer <= 0.0:
				phase = Phase.RUNNING
				return "start"
		Phase.RUNNING:
			needle += speed * dt
			if needle > zone_start + zone_width:
				return _finish(false)
		Phase.FEEDBACK:
			_timer -= dt
			if _timer <= 0.0:
				index += 1
				if index >= rules.checks:
					phase = Phase.OVER
					return "over"
				_prepare()
				return "next"
	return ""


func _finish(hit: bool) -> String:
	results.append(hit)
	phase = Phase.FEEDBACK
	_timer = rules.feedback
	return "hit" if hit else "miss"


## How long a check gives you to react: from the start of the sweep to the
## zone (seconds) and the time the needle spends in the zone.
func reaction_time() -> float:
	return zone_start / speed


func window() -> float:
	return zone_width / speed
