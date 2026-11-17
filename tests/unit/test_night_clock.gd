extends GutTest
## M003 the night clock: every night starts in the evening, runs while you
## play, tells you to go home in the small hours and stops at dawn (no
## daytime); the streets get quieter towards morning. Hours are configurable.


func test_a_night_starts_in_the_evening() -> void:
	var c := NightClock.new()
	assert_eq(c.text(), "7:30 PM")
	assert_false(c.is_late())
	assert_eq(c.activity(), 1.0, "a lively evening")


func test_time_runs_and_reads_like_a_clock() -> void:
	var c := NightClock.new()
	c.advance(30.0 / c.rules.minutes_per_second)  # thirty game minutes
	assert_eq(c.text(), "8:00 PM")
	c.set_time(24 * 60 + 5)
	assert_eq(c.text(), "12:05 AM")
	c.set_time(24 * 60 + 60 + 10)
	assert_eq(c.text(), "1:10 AM")


func test_late_at_night_it_is_time_to_go_home() -> void:
	var c := NightClock.new()
	c.set_time(c.rules.home_minute - 1)
	assert_false(c.is_late())
	c.advance(2.0 / c.rules.minutes_per_second)
	assert_true(c.is_late())
	assert_false(c.is_dawn())


func test_the_clock_stops_at_dawn() -> void:
	var c := NightClock.new()
	c.advance(1e6)
	assert_true(c.is_dawn())
	assert_eq(c.minute, float(c.rules.dawn_minute), "no daytime")
	c.advance(600.0)
	assert_eq(c.minute, float(c.rules.dawn_minute))
	c.reset()
	assert_eq(c.text(), "7:30 PM", "and the next night starts in the evening")


func test_the_streets_quieten_towards_morning() -> void:
	var c := NightClock.new()
	var last := 2.0
	for m in [21 * 60, 23 * 60, 24 * 60 + 60, 24 * 60 + 180, c.rules.dawn_minute]:
		c.set_time(m)
		assert_lte(c.activity(), last)
		last = c.activity()
	assert_lt(last, 0.4, "nearly empty before dawn")
	assert_gt(last, 0.0, "but never dead")


func test_the_hours_are_configurable() -> void:
	var r := NightRules.new()
	r.start_minute = 21 * 60
	r.home_minute = 24 * 60 + 2 * 60
	r.minutes_per_second = 2.0
	var c := NightClock.new(r)
	assert_eq(c.text(), "9:00 PM")
	c.advance(30.0)
	assert_eq(c.text(), "10:00 PM")
