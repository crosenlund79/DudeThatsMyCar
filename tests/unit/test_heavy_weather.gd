extends GutTest
## M012 heavier weather (pure): on a wet night the rain comes in downpours now
## and then and eases off again, never on a dry night; the wind's slant moves
## within bounds; thunder only in a downpour, now and then, the same minutes
## every time for the same night, never two claps on top of each other, some
## near and most far; the rain's hole is the open room's part of the screen.


func _wet_night(n: int = 1) -> Weather:
	var w := Weather.new()
	w.begin_night(n, 19 * 60 + 30.0)
	w.force("rain")
	return w


func test_downpours_come_and_go_on_a_wet_night_only() -> void:
	var w := _wet_night()
	var lo := 1.0
	var hi := 0.0
	var strength_lo := 1.0
	for m in range(19 * 60 + 30, 29 * 60, 2):
		w.minute = float(m)
		lo = minf(lo, w.downpour())
		hi = maxf(hi, w.downpour())
		strength_lo = minf(strength_lo, w.rain_strength())
		assert_lte(w.rain_strength(), 1.0)
	assert_eq(lo, 0.0, "the rain eases between downpours")
	assert_gt(hi, 0.8, "and comes down hard in them")
	assert_gt(strength_lo, 0.4, "it never stops while it rains")
	var dry := Weather.new()
	dry.begin_night(2, 19 * 60 + 30.0)
	dry.force("clear")
	for m in range(19 * 60 + 30, 29 * 60, 5):
		dry.minute = float(m)
		assert_eq(dry.downpour(), 0.0)


func test_the_wind_moves_the_slant_within_bounds() -> void:
	var w := _wet_night()
	var seen := {}
	for m in range(19 * 60 + 30, 29 * 60, 7):
		w.minute = float(m)
		assert_between(w.wind(), -0.1, 0.5)
		seen[snappedf(w.wind(), 0.1)] = true
	assert_gt(seen.size(), 3, "it shifts")


func test_thunder_only_in_a_downpour_now_and_then() -> void:
	var w := _wet_night()
	var claps := w.thunder_between(19 * 60 + 30.0, 29 * 60.0)
	assert_between(claps.size(), 2, 40, "now and then over a wet night")
	var near := 0
	var all := 0
	for n in range(1, 9):  # over several wet nights: mostly the far roll, now and then a crack overhead
		var each := _wet_night(n).thunder_between(19 * 60 + 30.0, 29 * 60.0)
		all += each.size()
		near += each.filter(func(c: Dictionary) -> bool: return c.near).size()
	assert_gt(near, 0, "now and then close by")
	assert_lt(float(near) / all, 0.5, "mostly far off")
	for i in claps.size():
		w.minute = float(claps[i].minute)
		assert_gte(w.downpour(), 0.35, "in a downpour")
		if i > 0:
			assert_gt(float(claps[i].minute) - float(claps[i - 1].minute), Weather.THUNDER_STEP * 0.25, "never on top of each other")
	# the same night thunders at the same minutes, and piecewise the same as all at once
	assert_eq(_wet_night().thunder_between(19 * 60 + 30.0, 29 * 60.0), claps)
	var pieces := []
	var m := 19 * 60 + 30.0
	while m < 29 * 60.0:
		pieces.append_array(w.thunder_between(m, m + 1.0))
		m += 1.0
	assert_eq(pieces.size(), claps.size(), "minute by minute, the same claps")
	# none on a clear night
	var dry := Weather.new()
	dry.begin_night(2, 19 * 60 + 30.0)
	dry.force("clear")
	assert_eq(dry.thunder_between(19 * 60 + 30.0, 29 * 60.0), [])


func test_the_rain_hole_is_the_rooms_part_of_the_screen() -> void:
	var v := WeatherView.new()
	add_child_autofree(v)
	v.setup(Weather.new())
	assert_eq(v.rain_hole(Rect2(0, 0, 1000, 500)), Vector4.ZERO, "in the street: none")
	v.indoors = Rect2(250, 100, 500, 250)
	var h := v.rain_hole(Rect2(0, 0, 1000, 500))
	assert_almost_eq(h.x, 0.25, 0.001)
	assert_almost_eq(h.y, 0.2, 0.001)
	assert_almost_eq(h.z, 0.5, 0.001)
	assert_almost_eq(h.w, 0.5, 0.001)
