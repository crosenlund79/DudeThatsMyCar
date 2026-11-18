extends GutTest
## M008 the beat cop's revolver (OfficerBrain with the shared Marksman rules):
## only a serious violent crime he has seen arms him - not gunfire he merely
## hears, not a stray round from somebody else; armed, he keeps his distance,
## fires within range with a clear shot and no faster than his cadence, steps
## aside when something is in the way, and loses you exactly as before.

const DT := 1.0 / 60.0
const BEAT := [Vector2(0, 0), Vector2(200, 0)]

var rules: PoliceRules


func before_each() -> void:
	rules = load("res://src/police/default_police.tres")


func _brain() -> OfficerBrain:
	return OfficerBrain.new(rules, PackedVector2Array(BEAT))


## Runs the brain for `seconds` with the player at `player` (seen or not);
## returns the times (s) at which he fired.
func _run(b: OfficerBrain, me: Vector2, seconds: float, sees: bool, player: Vector2, clear := true) -> Array:
	var shots := []
	for i in int(seconds / DT):
		var out := b.update(DT, me, sees, player, Vector2.ZERO, clear)
		if out.fire:
			shots.append(i * DT)
	return shots


func test_gunfire_he_only_hears_gets_the_unarmed_chase() -> void:
	var b := _brain()
	assert_true(b.hear_gunshot(Vector2.ZERO, Vector2(200, 0), 720.0))
	var shots := _run(b, Vector2.ZERO, 6.0, true, Vector2(250, 0))
	assert_true(b.is_hunting())
	assert_false(b.armed)
	assert_eq(shots, [], "he chases, he does not shoot")
	var out := b.update(DT, Vector2.ZERO, true, Vector2(250, 0), Vector2.ZERO)
	assert_false(out.draw, "the revolver stays in its holster")


func test_a_stray_round_from_somebody_else_does_not_arm_him() -> void:
	var b := _brain()
	b.shot_at(Vector2(100, 0), false)
	assert_true(b.is_hunting(), "he goes to look")
	assert_false(b.armed)
	b.shot_at(Vector2(100, 0), true)
	assert_true(b.armed, "shot at by you: he draws")


func test_a_crime_he_saw_arms_him_and_he_takes_aim_first() -> void:
	var b := _brain()
	b.witness_violence(Vector2(300, 0))
	assert_true(b.armed)
	var shots := _run(b, Vector2.ZERO, 8.0, true, Vector2(300, 0))
	assert_gt(shots.size(), 1)
	assert_gte(shots[0], rules.first_shot - 0.05, "a moment to draw and aim (and his warning) first")
	for i in range(1, shots.size()):
		assert_gte(shots[i] - shots[i - 1], rules.fire_gap - 0.02, "never faster than his cadence")
		assert_lte(shots[i] - shots[i - 1], rules.fire_gap + rules.fire_jitter + 0.05)


func test_out_of_range_he_closes_in_without_firing() -> void:
	var b := _brain()
	b.witness_violence(Vector2(600, 0))
	var far := Vector2(rules.fire_range + 80.0, 0)
	var shots := _run(b, Vector2.ZERO, 5.0, true, far)
	assert_eq(shots, [], "too far for a revolver")
	var out := b.update(DT, Vector2.ZERO, true, far, Vector2.ZERO)
	assert_eq(out.target, far, "he comes closer")
	assert_gt(out.speed, 0.0)
	assert_true(out.draw)


func test_no_clear_shot_no_shot_he_steps_aside() -> void:
	var b := _brain()
	b.witness_violence(Vector2(250, 0))
	var shots := _run(b, Vector2.ZERO, 5.0, true, Vector2(250, 0), false)
	assert_eq(shots, [], "a car or a person in the way: he holds his fire")
	var out := b.update(DT, Vector2.ZERO, true, Vector2(250, 0), Vector2.ZERO, false)
	assert_ne(out.target, Vector2(250, 0), "he moves for a better line")
	assert_gt(absf(out.target.y), 20.0, "sideways")
	assert_gt(out.speed, 0.0)


func test_out_of_sight_he_never_fires_and_loses_you_as_before() -> void:
	var b := _brain()
	b.witness_violence(Vector2(300, 0))
	_run(b, Vector2.ZERO, 3.0, true, Vector2(300, 0))
	var me := Vector2.ZERO
	var fired := false
	var gave_up := false
	for i in int(30.0 / DT):
		var out := b.update(DT, me, false, Vector2(300, 0), Vector2.ZERO)
		fired = fired or out.fire
		me = me.move_toward(out.target, out.speed * DT)
		if b.gave_up_now:
			gave_up = true
			break
	assert_false(fired, "not a shot at what he cannot see")
	assert_true(gave_up, "he searches, then gives up")
	var after := b.update(DT, me, false, Vector2(300, 0), Vector2.ZERO)
	assert_false(after.draw, "and puts the revolver away")


func test_standing_down() -> void:
	var b := _brain()
	b.witness_violence(Vector2(300, 0))
	_run(b, Vector2.ZERO, 2.0, true, Vector2(300, 0))
	b.stand_down()
	assert_false(b.is_hunting())
	assert_eq(b.state, OfficerBrain.State.RETURN)


func test_marksman_numbers_keep_their_distance() -> void:
	var m := Marksman.new({"keep_at": 200.0, "too_close": 100.0, "fire_range": 400.0})
	var close := m.engage(DT, Vector2.ZERO, Vector2(60, 0))
	assert_lt((close.goal as Vector2).x, 0.0, "too close: backs off")
	var held := m.engage(DT, Vector2.ZERO, Vector2(220, 0))
	assert_eq(held.goal, Vector2.ZERO, "at a gunfight's distance: stands and shoots")
	assert_true(Marksman.passes_near(Vector2(100, 10), Vector2.ZERO, Vector2.RIGHT))
	assert_false(Marksman.passes_near(Vector2(100, 80), Vector2.ZERO, Vector2.RIGHT))
	assert_false(Marksman.passes_near(Vector2(-100, 0), Vector2.ZERO, Vector2.RIGHT), "behind the muzzle")
