extends GutTest
## M015 (LeftysCar, pure): what Lefty knows about his speedster - nothing, that
## it is gone, or that Danny took it (how he learnt it); a grudge while he
## knows it was Danny and it is not back; back at his kerb he forgives (and a
## car merely missing is simply found); saved and loaded as it stands.


func test_from_nothing_to_a_grudge_and_back() -> void:
	var m := LeftysCar.new()
	assert_false(m.grudge())
	assert_true(m.learn_gone(3))
	assert_false(m.learn_gone(3), "news once")
	assert_eq(m.knows, "gone")
	assert_false(m.grudge(), "he doesn't know who")
	assert_true(m.learn_danny("word", 4))
	assert_true(m.grudge())
	assert_eq([m.how, m.since], ["word", 4])
	assert_false(m.learn_danny("saw_driving", 4), "he knew already")
	assert_true(m.bring_back())
	assert_false(m.grudge(), "the car back on his kerb")
	assert_false(m.bring_back(), "once")
	assert_true(m.learn_danny("saw_taken", 6), "taken again: he knows again")
	assert_true(m.grudge())


func test_a_car_merely_missing_is_found() -> void:
	var m := LeftysCar.new()
	m.learn_gone(2)
	assert_false(m.bring_back(), "nothing to forgive")
	assert_eq(m.knows, "", "his car is back where he left it")


func test_saved_and_loaded() -> void:
	var m := LeftysCar.new()
	m.learn_danny("saw_taken", 5)
	m.word = true
	var again := LeftysCar.new()
	again.from_dict(JSON.parse_string(JSON.stringify(m.to_dict())))
	assert_eq(again.to_dict(), m.to_dict())
	var bad := LeftysCar.new()
	bad.from_dict({"knows": "everything"})
	assert_eq(bad.knows, "", "nonsense in a save is nothing")
	var r := Rackets.new(load("res://src/economy/default_economy.tres"))
	r.lefty_car.learn_danny("word", 2)
	var r2 := Rackets.new(load("res://src/economy/default_economy.tres"))
	r2.from_dict(JSON.parse_string(JSON.stringify(r.to_dict())))
	assert_eq(r2.lefty_car.knows, "danny", "kept in the books' save")
	var old := r.to_dict()
	old.erase("lefty_car")
	var r3 := Rackets.new(load("res://src/economy/default_economy.tres"))
	r3.from_dict(old)
	assert_eq(r3.lefty_car.knows, "", "an older save: nothing amiss")
