extends GutTest
## M007 what a fistfight leaves (FightInjuries, pure): bruises for every punch
## taken, a proper beating for the loser, never anything fatal.


func test_a_lost_fight_leaves_a_wound_but_never_kills() -> void:
	var c := BodyCondition.new()
	FightInjuries.apply_to_danny(c, [false, false, false, false, false], false)
	assert_eq(c.level("head"), BodyCondition.Level.WOUNDED, "a black eye, a split brow")
	assert_false(c.is_fatal())
	for i in 10:
		FightInjuries.apply_to_danny(c, [false, false, false, false, false], false)
	assert_false(c.is_fatal(), "however many fights he loses")


func test_a_won_fight_costs_a_bruise_or_two() -> void:
	var c := BodyCondition.new()
	FightInjuries.apply_to_danny(c, [true, false, true, true, false], true)
	assert_eq(c.worst(), BodyCondition.Level.GRAZED, "bruised, not wounded")
	var o := BodyCondition.new()
	FightInjuries.apply_to_opponent(o, [true, false, true, true, false], true)
	assert_eq(o.level("head"), BodyCondition.Level.WOUNDED, "the other man took the beating")
	assert_false(o.is_fatal())
