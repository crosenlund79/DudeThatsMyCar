extends GutTest
## M010 running and tiredness, pure: a run is faster than a walk and stops
## when Shift is let go; drowsiness waits for the small hours and grows to
## its fullest at dawn.


func test_a_run_is_faster_than_a_walk() -> void:
	var m := WalkerModel.new()
	for i in 60:
		m.update(1.0 / 60.0, Vector2.RIGHT)
	var walk := m.speed()
	m.running = true
	for i in 60:
		m.update(1.0 / 60.0, Vector2.RIGHT)
	assert_gt(m.speed(), walk * 1.6, "running")
	m.running = false
	for i in 60:
		m.update(1.0 / 60.0, Vector2.RIGHT)
	assert_almost_eq(m.speed(), walk, 0.5, "back to a walk")


func test_drowsy_only_in_the_small_hours() -> void:
	var rules := NightRules.new()
	var c := NightClock.new(rules)
	assert_eq(c.drowsiness(), 0.0, "fresh at dusk")
	c.set_time(float(rules.drowsy_minute) - 1.0)
	assert_eq(c.drowsiness(), 0.0)
	assert_lt(rules.drowsy_minute, rules.home_minute + 1, "it begins about when he is told to get home")
	c.set_time(float(rules.drowsy_minute + rules.dawn_minute) * 0.5)
	assert_almost_eq(c.drowsiness(), 0.5, 0.01, "half way to dawn")
	c.set_time(float(rules.dawn_minute))
	assert_almost_eq(c.drowsiness(), 1.0, 0.001, "heaviest at dawn")
	c.reset()
	assert_eq(c.drowsiness(), 0.0, "a night's sleep")
