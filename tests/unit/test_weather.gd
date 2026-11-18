extends GutTest
## M010 the night's weather: four states as two levels; each night's own
## course, the same every time; changes come on gradually; the rain varies a
## little as it falls; a state can be forced at once (tests, screenshots).

const DUSK := 19 * 60 + 30.0


func test_four_states() -> void:
	var w := Weather.new()
	w.begin_night(1, DUSK)
	for s in Weather.STATES:
		w.force(s)
		assert_eq(w.state_name(), s)
	w.force("rain_fog")
	assert_gt(w.rain, 0.5)
	assert_gt(w.fog, 0.5, "rain and fog together")
	w.force("clear")
	assert_eq(w.rain, 0.0)
	assert_eq(w.fog, 0.0)


func test_each_night_its_own_course_the_same_every_time() -> void:
	var a := Weather.new()
	var b := Weather.new()
	for n in range(1, 12):
		a.begin_night(n, DUSK)
		b.begin_night(n, DUSK)
		for m in range(0, 600, 10):
			a.advance(DUSK + m)
			b.advance(DUSK + m)
			assert_eq(a.rain, b.rain)
			assert_eq(a.fog, b.fog)
	var w := Weather.new()
	w.begin_night(1, DUSK)
	assert_eq(w.state_name(), "rain", "the first night is a wet one")
	var seen := {}
	for n in range(1, 30):
		for step in Weather.course_of(n):
			seen[step[1]] = true
	assert_eq(seen.size(), 4, "every kind of night comes round")


func test_changes_come_on_gradually() -> void:
	var w := Weather.new()
	w.begin_night(1, DUSK)
	w.advance(DUSK + 149.0)
	assert_eq(w.fog, 0.0)
	w.advance(DUSK + 155.0)
	assert_gt(w.fog, 0.0, "the fog begins to come in")
	assert_lt(w.fog, 0.5, "but not all at once")
	w.advance(DUSK + 190.0)
	assert_almost_eq(w.fog, Weather.LEVELS.rain_fog[1], 0.001, "in full after a while")


func test_the_rain_varies_as_it_falls() -> void:
	var w := Weather.new()
	w.begin_night(1, DUSK)
	var lo := 1.0
	var hi := 0.0
	for m in range(0, 120, 3):
		w.advance(DUSK + m)
		lo = minf(lo, w.rain_strength())
		hi = maxf(hi, w.rain_strength())
	assert_gt(hi - lo, 0.1, "harder and softer")
	assert_lte(hi, 1.0)
	assert_gt(lo, 0.4, "but never stops while it rains")
