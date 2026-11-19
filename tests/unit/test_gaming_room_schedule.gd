extends GutTest
## M013.6 the gaming room's evening (GamingRoom, pure): quiet early, fuller
## towards midnight, thinning out before four, empty after; each regular at
## his own places only (never two at one, the Bell left for Danny); the same
## night always the same, other nights a little different.


func _count(n: int, minute: float) -> int:
	var g := GamingRoom.new()
	g.begin_night(n)
	return g.present(minute).size()


func _mean(minute: float) -> float:
	var t := 0
	for n in range(1, 21):
		t += _count(n, minute)
	return t / 20.0


func test_quiet_early_full_late_thin_at_closing() -> void:
	var early := _mean(19 * 60 + 40.0)
	var eight := _mean(20 * 60 + 30.0)
	var midnight := _mean(24 * 60.0)
	var late := _mean(27 * 60 + 30.0)
	gut.p("regulars in: 7:40 %.1f, 8:30 %.1f, midnight %.1f, 3:30 %.1f" % [early, eight, midnight, late])
	assert_lt(early, 1.5, "hardly anybody as the evening starts")
	assert_lt(eight, midnight, "fuller as the night goes on")
	assert_gte(midnight, 4.0, "a full room at midnight")
	assert_lt(late, midnight, "thinner before closing")
	for n in range(1, 21):
		assert_eq(_count(n, GamingRoom.CLOSE), 0, "nobody after four (night %d)" % n)
		assert_eq(_count(n, GamingRoom.CLOSE - 1.0), 0, "everybody gone by closing")


func test_everyone_in_his_own_places() -> void:
	for n in range(1, 11):
		var g := GamingRoom.new()
		g.begin_night(n)
		for m in range(19 * 60 + 30, 28 * 60, 2):
			var taken := {}
			for id in g.present(float(m)):
				var spot := g.spot_of(id, float(m))
				assert_true(RiversideInteriors.ROOM_SPOTS.has(spot), "%s is a place in the room" % spot)
				assert_false(taken.has(spot), "never two at %s (night %d, minute %d)" % [spot, n, m])
				taken[spot] = true
				var mine := (GamingRoom.PLAN[id].places as Array).map(func(pl: Array) -> String: return String(pl[0]))
				assert_has(mine, spot, "%s keeps to his own places" % id)
				assert_ne(spot, "slot_1", "the Bell is left for Danny")


func test_the_same_night_goes_the_same_way() -> void:
	var a := GamingRoom.new()
	var b := GamingRoom.new()
	a.begin_night(3)
	b.begin_night(3)
	assert_eq(a.nights, b.nights)
	b.begin_night(4)
	assert_ne(a.nights, b.nights, "another night, a little different")


func test_what_each_place_is_for() -> void:
	assert_eq(GamingRoom.kind_of("rail_edna"), "wheel")
	assert_eq(GamingRoom.kind_of("slot_0"), "slots")
	assert_eq(GamingRoom.kind_of("table2"), "idle")
	var g := GamingRoom.new()
	g.begin_night(1)
	var m := 24 * 60.0
	for id in g.present(m):
		assert_gt(g.next_change(id, m), m, "%s's next change is later" % id)
