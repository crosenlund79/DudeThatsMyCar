extends GutTest
## Vehicle condition (DamageRules / DamageWorld), retained from HyperCars as a
## pure model for a later milestone: impacts wear a car down, armour reduces
## damage, one contact between two cars counts once per tick.

var _rules: DamageRules


func before_each() -> void:
	_rules = load("res://src/damage/default_damage_rules.tres")


func _world(n := 3) -> DamageWorld:
	return DamageWorld.new(_rules, n)


func test_minor_impacts_cost_nothing_and_severe_ones_are_capped() -> void:
	assert_eq(_rules.wall_damage(60.0), 0.0, "a scrape")
	assert_eq(_rules.wall_damage(_rules.wall_threshold), 0.0)
	assert_almost_eq(_rules.wall_damage(210.0), (210.0 - _rules.wall_threshold) * _rules.wall_damage_per_speed, 0.001)
	assert_eq(_rules.wall_damage(5000.0), _rules.wall_max_damage, "capped")
	assert_eq(_rules.car_damage(90.0), 0.0, "a nudge")
	assert_gt(_rules.car_damage(300.0), _rules.car_damage(200.0), "harder contacts hurt more")
	assert_eq(_rules.car_damage(5000.0), _rules.car_max_damage)


func test_one_hard_impact_never_wrecks_a_healthy_car() -> void:
	var d := _world(1)
	assert_false(d.wall_impact(0, 5000.0))
	assert_almost_eq(d.condition[0], _rules.max_condition - _rules.wall_max_damage, 0.001)


func test_repeated_impacts_wear_the_car_down_to_a_wreck() -> void:
	var d := _world(1)
	var hits := 0
	while not d.is_retired(0):
		d.wall_impact(0, 5000.0)
		hits += 1
	assert_eq(hits, int(ceil(_rules.max_condition / _rules.wall_max_damage)))
	assert_eq(d.condition[0], 0.0)
	assert_false(d.damage(0, 50.0), "no more damage once wrecked")
	assert_false(d.is_critical(0), "wrecked, not critical")


func test_critical_threshold() -> void:
	var d := _world(1)
	d.set_start(0, _rules.critical_condition + 1.0, 0.0)
	assert_false(d.is_critical(0))
	d.damage(0, 1.0)
	assert_true(d.is_critical(0))


func test_armour_reduces_damage_without_invulnerability() -> void:
	var plain := _world(1)
	var armoured := _world(1)
	armoured.set_start(0, 100.0, 0.35)
	plain.damage(0, 12.0)
	armoured.damage(0, 12.0)
	assert_almost_eq(100.0 - armoured.condition[0], (100.0 - plain.condition[0]) * 0.65, 0.001)
	var hits := 0
	while not armoured.is_retired(0) and hits < 100:
		armoured.damage(0, 12.0)
		hits += 1
	assert_true(armoured.is_retired(0), "armour delays a wreck, it does not prevent it")
	armoured.set_start(0, 100.0, 5.0)
	assert_lte(armoured.armour[0], 0.95, "reduction is capped below 100 %")


func test_car_contact_hurts_both_once_per_tick() -> void:
	var d := _world(3)
	var amount := _rules.car_damage(320.0)
	d.car_impact(0, 1, 320.0)
	d.car_impact(1, 0, 320.0)  # the other car reporting the same contact
	assert_almost_eq(d.condition[0], 100.0 - amount, 0.001)
	assert_almost_eq(d.condition[1], 100.0 - amount, 0.001)
	assert_eq(d.condition[2], 100.0)
	d.step(1.0 / 60.0)
	d.car_impact(0, 1, 320.0)
	assert_almost_eq(d.condition[0], 100.0 - 2.0 * amount, 0.001, "next tick counts again")
	d.car_impact(0, 2, 320.0, true, false)
	assert_eq(d.condition[2], 100.0, "a car that cannot be hurt is spared")


func test_reset_restores_everyone() -> void:
	var d := _world(2)
	d.set_start(1, 40.0, 0.2)
	d.damage(1, 60.0)
	assert_true(d.is_retired(1))
	d.reset()
	assert_false(d.is_retired(1))
	assert_eq(d.condition[1], 100.0)
	assert_eq(d.armour[1], 0.0)
