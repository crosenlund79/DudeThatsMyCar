extends GutTest
## M006 whose car is whose (CarThefts, pure): Danny owns the sedan outside his
## flat; taking any other car is a theft - once a night per car - and only an
## officer close enough, with no building in the way, can witness it.


func test_danny_owns_one_car() -> void:
	var layout := RiversideWard.create()
	var t := CarThefts.new(layout.cars)
	var mine := []
	for i in layout.cars.size():
		if t.is_dannys(i):
			mine.append(i)
		else:
			assert_ne(t.owner(i), "", "car %d belongs to somebody" % i)
	assert_eq(mine.size(), 1, "one car of his own")
	assert_lt((layout.cars[mine[0]].pos as Vector2).distance_to(layout.spawn), 200.0, "outside his flat")


func test_a_theft_counts_once() -> void:
	var t := CarThefts.new([{"owner": "danny"}, {"owner": "Doyle's"}])
	assert_false(t.get_in(0), "his own car")
	assert_true(t.get_in(1), "somebody else's: stolen")
	assert_false(t.get_in(1), "getting back into it is not a new theft")
	assert_true(t.is_stolen(1))
	t.clear()
	assert_false(t.is_stolen(1), "a new night: back with its owner")
	assert_true(t.get_in(1))


func test_who_could_have_seen_it() -> void:
	assert_true(CarThefts.witnessed(Vector2.ZERO, Vector2(300, 0), true))
	assert_false(CarThefts.witnessed(Vector2.ZERO, Vector2(300, 0), false), "a building in the way")
	assert_false(CarThefts.witnessed(Vector2.ZERO, Vector2(600, 0), true), "too far off")
