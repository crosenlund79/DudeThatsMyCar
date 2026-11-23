extends GutTest
## M015 somebody struck by Danny's car (pure parts): how badly by how fast -
## a clip bruises, a hard knock badly hurts, a fast town speed kills, and
## harder is never better; a named person remembers it as a run-down (not a
## shooting), Rourke hears it, and the talk goes round; a stranger's talk
## starts with the local who saw it ("a car like yours").


func _hurt(impact: float) -> BodyCondition:
	var c := BodyCondition.new()
	var inj := BodyCondition.car_injuries(impact, true)
	for region in inj:
		c.hurt(region, inj[region])
	return c


func test_how_badly_by_how_fast() -> void:
	var clip := _hurt(80.0)
	assert_true(clip.is_hurt())
	assert_eq(clip.worst(), BodyCondition.Level.GRAZED, "a clip: bruised")
	assert_false(clip.is_fatal())
	var knock := _hurt(200.0)
	assert_eq(knock.worst(), BodyCondition.Level.WOUNDED, "a hard knock: badly hurt")
	assert_lt(knock.speed_factor(), 1.0, "and limping")
	assert_false(knock.is_fatal())
	assert_true(_hurt(280.0).is_fatal(), "a fast town speed")
	assert_true(_hurt(330.0).is_fatal(), "flat out")
	var before := 0
	for speed in range(70, 400, 10):
		var t := _hurt(float(speed)).total()
		assert_gte(t, before, "never better for going faster (%d px/s)" % speed)
		before = t


func test_the_near_side_takes_it() -> void:
	var right := BodyCondition.car_injuries(150.0, true)
	var left := BodyCondition.car_injuries(150.0, false)
	assert_gt(int(right.right_leg), int(right.left_leg))
	assert_gt(int(left.left_leg), int(left.right_leg))


func test_a_named_person_remembers_a_run_down_not_a_shooting() -> void:
	var r := Rackets.new(EconomyRules.new())
	var trust := r.boss.trust
	r.ran_down("dutch", false)
	assert_eq(r.memory.recent("dutch", "run_down", r.night), 1)
	assert_eq(r.memory.recent("dutch", "shot", r.night), 0)
	assert_lt(r.boss.trust, trust, "Rourke thinks less of it")
	assert_true((r.boss.heard as Array).any(func(h: Dictionary) -> bool: return String(h.text).contains("ran Dutch down")))
	assert_eq(r.rumours.known_to("dutch", "ran_down").size(), 1, "and the talk starts")
	var talk := Conversations.new(r)
	assert_string_contains(talk._talk_line(r.rumours.known_to("dutch", "ran_down")[0]), "ran Dutch down")


func test_a_strangers_talk_starts_with_the_local_who_saw_it() -> void:
	var r := Rackets.new(EconomyRules.new())
	r.ran_down_stranger("augie", "on Marlowe Avenue", false)
	r.ran_down_stranger("novak", "on Kessler Street", true)
	var talk := Conversations.new(r)
	var hurt: Dictionary = r.rumours.known_to("augie", "ran_down_street")[0]
	assert_string_contains(talk._talk_line(hurt), "on Marlowe Avenue")
	assert_string_contains(talk._talk_line(hurt), "looked a lot like you")
	var dead: Dictionary = r.rumours.known_to("novak", "ran_down_dead")[0]
	assert_string_contains(talk._talk_line(dead), "never got up")
	r.rumours.spread()
	assert_false(r.rumours.known_to("augie", "ran_down_dead").is_empty(), "it gets about")
	assert_true(String(r.gossip("sal").get("kind", "")).begins_with("ran_down"), "and Sal passes it on - talk about Danny")
