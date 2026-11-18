extends GutTest
## M007 the fistfight's timing checks (FistFight, pure): five checks, a zone
## somewhere on the far side of the dial, press in it to land the punch; early,
## late or not at all is a miss; three of five wins the fight. Zones and
## speeds vary a little, never unfairly; the numbers come from FightRules.

const DT := 1.0 / 60.0


## Runs a check until the needle is at `where` (a fraction across the zone; <0
## before it, >1 after it) and presses (or never presses, for "late").
func _play(f: FistFight, where: float) -> String:
	var guard := 0
	while f.phase != FistFight.Phase.RUNNING and guard < 600:
		f.update(DT)
		guard += 1
	if where > 1.0:
		var out := ""
		while out == "" and guard < 1200:
			out = f.update(DT)
			guard += 1
		return out
	var target := f.zone_start + f.zone_width * where
	while f.needle < target and f.phase == FistFight.Phase.RUNNING and guard < 1200:
		f.update(DT)
		guard += 1
	return f.press() if f.phase == FistFight.Phase.RUNNING else "miss"


func _finish_feedback(f: FistFight) -> void:
	var guard := 0
	while f.phase == FistFight.Phase.FEEDBACK and guard < 600:
		f.update(DT)
		guard += 1


func test_pressing_in_the_zone_lands_the_punch() -> void:
	var f := FistFight.new(null, 1)
	assert_eq(_play(f, 0.5), "hit")
	assert_eq(f.results, [true] as Array[bool])
	_finish_feedback(f)
	assert_eq(f.index, 1, "on to the next check")
	assert_eq(_play(f, 0.1), "hit", "near the start of the zone")


func test_early_late_or_never_is_a_miss() -> void:
	var f := FistFight.new(null, 2)
	assert_eq(_play(f, -0.3), "miss", "too early")
	_finish_feedback(f)
	assert_eq(_play(f, 1.5), "miss", "the needle swept past")
	assert_eq(f.press(), "", "one press per check")
	assert_eq(f.results, [false, false] as Array[bool])


func test_three_of_five_wins() -> void:
	for pattern in [[0.5, 0.5, 0.5, -1.0, 2.0], [0.5, -1.0, 0.5, 2.0, 0.5], [0.5, 0.5, -1.0, -1.0, 2.0], [-1.0, 2.0, -1.0, 2.0, 0.5]]:
		var f := FistFight.new(null, 3)
		for w in pattern:
			_play(f, w)
			_finish_feedback(f)
		assert_true(f.is_over(), "five checks and it is over")
		var hits: int = pattern.filter(func(w: float) -> bool: return w >= 0.0 and w <= 1.0).size()
		assert_eq(f.wins(), hits)
		assert_eq(f.won(), hits >= 3, "%s: %d landed" % [pattern, hits])


func test_fair_variation() -> void:
	var rules := FightRules.new()
	var zones := {}
	for seed in 20:
		var f := FistFight.new(rules, seed)
		for k in rules.checks:
			assert_gte(f.zone_start, rules.zone_earliest, "never right where the needle starts")
			assert_lte(f.zone_start + f.zone_width, 360.0)
			assert_gt(f.reaction_time(), 0.4, "time to see it coming")
			assert_gt(f.window(), 0.18, "a window a person can hit")
			assert_between(f.speed, rules.needle_speed * (1.0 - rules.speed_variation) - 0.01,
				rules.needle_speed * (1.0 + rules.speed_variation) + 0.01, "modest variation in speed")
			zones[int(f.zone_start / 30.0)] = true
			_play(f, 0.5)
			_finish_feedback(f)
	assert_gt(zones.size(), 3, "the zone moves about the dial")


func test_the_same_fight_replays_the_same() -> void:
	var a := FistFight.new(null, 77)
	var b := FistFight.new(null, 77)
	assert_eq(a.zone_start, b.zone_start)
	assert_eq(a.speed, b.speed)


func test_tips_and_wounds_change_the_odds() -> void:
	var plain := FistFight.new(null, 5)
	var tipped := FistFight.new(null, 5, 14.0)
	var hurt := FistFight.new(null, 5, -10.0, 1.0)
	assert_gt(tipped.zone_width, plain.zone_width, "knowing his habits widens the zone")
	assert_lt(hurt.zone_width, plain.zone_width, "a bad arm narrows it")
	var slow := FistFight.new(null, 5, 0.0, 0.85)
	assert_lt(slow.speed, plain.speed, "a hurt opponent is slower")
	var custom := FightRules.new()
	custom.checks = 3
	custom.wins_needed = 2
	var short := FistFight.new(custom, 9)
	for i in 3:
		_play(short, 0.5)
		_finish_feedback(short)
	assert_true(short.is_over() and short.won(), "the rules are configurable")
