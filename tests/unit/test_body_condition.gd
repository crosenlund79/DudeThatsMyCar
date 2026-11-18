extends GutTest
## M006 where a person is hurt (BodyCondition, pure): rounds land in a region
## by side and height, wounds read as grazed / wounded / badly hurt, a head
## or torso at its limit (or a body shot to pieces) is fatal, wounded legs
## slow, a wounded gun arm spoils the aim, sleep heals grazes, the vet the rest.


func test_where_a_round_lands() -> void:
	assert_eq(BodyCondition.region_for(1.0, 0.05), "head")
	assert_eq(BodyCondition.region_for(-1.0, 0.3), "torso")
	assert_eq(BodyCondition.region_for(1.0, 0.7), "right_arm", "from the right: the right arm")
	assert_eq(BodyCondition.region_for(-1.0, 0.7), "left_arm")
	assert_eq(BodyCondition.region_for(1.0, 0.9), "right_leg")
	assert_eq(BodyCondition.region_for(-1.0, 0.9), "left_leg")


func test_wound_levels() -> void:
	var b := BodyCondition.new()
	assert_eq(b.worst(), BodyCondition.Level.FINE)
	b.shoot("left_arm", 0.5)
	assert_eq(b.level("left_arm"), BodyCondition.Level.WOUNDED, "a .45 in the arm wounds it")
	assert_eq(BodyCondition.label(b.level("left_arm")), "wounded")
	b.hurt("left_leg", 10)
	assert_eq(BodyCondition.label(b.level("left_leg")), "grazed")
	assert_false(b.is_fatal(), "an arm and a graze: he walks away")
	b.shoot("head", 0.5)
	assert_eq(b.level("head"), BodyCondition.Level.CRITICAL, "a head wound is serious")
	assert_true(b.is_fatal(), "and usually the end")


func test_what_is_fatal() -> void:
	var b := BodyCondition.new()
	b.shoot("torso", 0.5)
	assert_false(b.is_fatal(), "one in the body: wounded")
	b.shoot("torso", 0.5)
	assert_true(b.is_fatal(), "two is the end")
	var c := BodyCondition.new()
	for r in ["left_arm", "right_arm", "left_leg"]:
		c.shoot(r, 0.5)
	assert_false(c.is_fatal(), "three in the arms and legs: still standing")
	c.shoot("right_leg", 0.9)
	c.shoot("left_arm", 0.9)
	assert_true(c.is_fatal(), "shot to pieces")
	c.hurt("left_arm", 500)
	assert_eq(c.damage.left_arm, BodyCondition.MAX, "no region goes past its limit")


func test_wounds_slow_and_spoil_the_aim() -> void:
	var b := BodyCondition.new()
	assert_eq(b.speed_factor(), 1.0)
	assert_eq(b.aim_spread(), 0.0)
	b.shoot("left_leg", 0.5)
	assert_almost_eq(b.speed_factor(), 0.8, 0.001, "a wounded leg slows him")
	b.hurt("right_leg", 90)
	assert_almost_eq(b.speed_factor(), 0.45, 0.001, "but he can still limp")
	b.shoot("right_arm", 0.5)
	assert_gt(b.aim_spread(), 2.0, "the gun arm")


func test_healing() -> void:
	var b := BodyCondition.new()
	b.hurt("left_arm", 20)
	b.shoot("torso", 0.5)
	b.rest()
	assert_eq(b.damage.left_arm, 0, "a night's sleep heals a graze")
	assert_eq(b.level("torso"), BodyCondition.Level.WOUNDED, "a wound waits for the Doc")
	b.hurt("torso", 60)
	b.patch_up()
	assert_eq(b.level("torso"), BodyCondition.Level.GRAZED, "patched up in a hurry")
	b.heal_all()
	assert_false(b.is_hurt(), "good as new")


func test_saved_and_loaded() -> void:
	var b := BodyCondition.new()
	b.shoot("right_leg", 0.2)
	var c := BodyCondition.new()
	c.from_dict(JSON.parse_string(JSON.stringify(b.to_dict())))
	assert_eq(c.damage.right_leg, b.damage.right_leg)
	c.from_dict({"torso": 999})
	assert_eq(c.damage.torso, BodyCondition.MAX, "clamped")


func test_what_the_doc_charges() -> void:
	var b := BodyCondition.new()
	assert_eq(b.treatment_price(), 0, "nothing to patch")
	b.hurt("left_arm", 10)
	var graze := b.treatment_price()
	assert_eq(graze, BodyCondition.VISIT + BodyCondition.PRICE[1])
	b.shoot("torso", 0.5)
	assert_gt(b.treatment_price(), graze, "a wound costs more")
	b.hurt("torso", 60)
	assert_eq(b.treatment_price(), BodyCondition.VISIT + BodyCondition.PRICE[1] + BodyCondition.PRICE[3])
