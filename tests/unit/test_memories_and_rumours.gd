extends GutTest
## M005 what people remember (threats, favours, disputes, deals, lies,
## promises) and how it fades; and talk that moves one person a night along
## who talks to whom, so Novak's news reaches Rourke two nights later.


func test_memories_shape_attitude_and_fade() -> void:
	var m := Memories.new()
	m.remember("novak", "threat", 1)
	var fresh: Dictionary = m.attitude("novak", 1)
	assert_gt(fresh.fear, 2.0)
	assert_lt(fresh.goodwill, 0.0)
	var old: Dictionary = m.attitude("novak", 5)
	assert_lt(old.fear, fresh.fear * 0.5, "an old threat counts less")
	m.remember("novak", "favour", 5)
	assert_gt(m.attitude("novak", 5).goodwill, 0.0, "a favour outweighs an old threat")
	assert_eq(m.recent("novak", "threat", 2, 3), 1)
	assert_eq(m.recent("novak", "threat", 5, 3), 0)


func test_promises_kept_and_broken() -> void:
	var m := Memories.new()
	m.promise("danny", "rourke", "pay", 1500, 2)
	assert_true(m.end_night(2).is_empty(), "not due yet")
	assert_true(m.keep("danny", "pay", 2))
	assert_eq(m.recent("rourke", "kept_promise", 2), 1)
	m.promise("danny", "rourke", "pay", 1500, 3)
	var broken := m.end_night(4)
	assert_eq(broken.size(), 1)
	assert_eq(m.recent("rourke", "broken_promise", 4), 1, "Rourke holds it against Danny")
	m.promise("novak", "danny", "repay", 800, 4)
	m.end_night(5)
	assert_eq(m.recent("novak", "dispute", 5), 1, "Novak's broken word is a dispute between them")


func test_memories_survive_a_save() -> void:
	var m := Memories.new()
	m.remember("sal", "deal", 3, "six bottles")
	m.promise("novak", "danny", "repay", 900, 5)
	var c := Memories.new()
	c.from_dict(JSON.parse_string(JSON.stringify(m.to_dict())))
	assert_eq(JSON.stringify(c.to_dict()), JSON.stringify(m.to_dict()))


func test_talk_moves_one_person_a_night() -> void:
	var t := Rumours.new()
	var r := t.start("paid", "novak", 1, {"business": "grocery", "cents": 750, "seq": 3})
	assert_true(t.knows("novak", r))
	assert_false(t.knows("rourke", r))
	var first := t.spread()
	assert_true(t.knows("augie", r) and t.knows("sal", r) and t.knows("lindqvist", r), "Novak's neighbours")
	assert_false(t.knows("rourke", r), "not yet")
	assert_true(first.any(func(l: Dictionary) -> bool: return l.to == "augie"))
	t.spread()
	assert_true(t.knows("rourke", r), "Augie told Rourke the next night")
	assert_eq(t.known_to("rourke", "paid").size(), 1)
	t.forget(9)
	assert_true(t.items.is_empty(), "old talk is forgotten")


func test_talk_survives_a_save() -> void:
	var t := Rumours.new()
	t.start("short", "novak", 2, {"business": "grocery"})
	t.spread()
	var c := Rumours.new()
	c.from_dict(JSON.parse_string(JSON.stringify(t.to_dict())))
	assert_eq(JSON.stringify(c.to_dict()), JSON.stringify(t.to_dict()))
