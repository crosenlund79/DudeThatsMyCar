extends GutTest
## M006 Lefty Moran's decisions (RivalBrain, pure): he minds his own business
## until provoked, then keeps a gunfight's distance and fires now and then,
## follows to where he lost Danny, cools off after a while, goes for him again
## on sight that night, runs when badly hurt, and stays down when shot down.

const POST: Array[Vector2] = [Vector2(0, 0), Vector2(100, 0)]
const DT := 1.0 / 60.0


func _run(b: RivalBrain, seconds: float, me: Vector2, danny: Vector2, sees: bool, hurt := false) -> Array:
	var outs := []
	var t := 0.0
	while t < seconds:
		outs.append(b.update(DT, me, danny, sees, hurt))
		t += DT
	return outs


func test_neutral_until_provoked() -> void:
	var b := RivalBrain.new(POST)
	var outs := _run(b, 20.0, Vector2(0, 0), Vector2(60, 0), true)
	assert_false(outs.any(func(o: Dictionary) -> bool: return o.fire), "Danny walks right past him: nothing")
	assert_eq(b.state, RivalBrain.State.IDLE)


func test_provoked_he_fights_at_a_distance() -> void:
	var b := RivalBrain.new(POST)
	b.provoke(Vector2(300, 0))
	assert_true(b.is_hostile())
	var outs := _run(b, 6.0, Vector2(0, 0), Vector2(150, 0), true)
	var shots := outs.filter(func(o: Dictionary) -> bool: return o.fire).size()
	assert_between(shots, 2, 6, "a shot every second or two, not a hail")
	assert_eq(outs[0].look, Vector2(150, 0), "facing Danny")
	var far := b.update(DT, Vector2(0, 0), Vector2(600, 0), true, false)
	assert_eq(far.goal, Vector2(600, 0), "closes in when Danny is far")
	var near := b.update(DT, Vector2(0, 0), Vector2(50, 0), true, false)
	assert_lt(near.goal.x, 0.0, "backs off when he is too close")


func test_he_loses_danny_and_cools_off_but_holds_a_grudge() -> void:
	var b := RivalBrain.new(POST)
	b.provoke(Vector2(200, 0))
	var o := b.update(DT, Vector2(0, 0), Vector2(900, 0), false, false)
	assert_eq(o.goal, Vector2(200, 0), "to where he saw him last")
	assert_false(o.fire, "no shooting at what he can't see")
	_run(b, RivalBrain.CALM_AFTER + 1.0, Vector2(0, 0), Vector2(900, 0), false)
	assert_eq(b.state, RivalBrain.State.IDLE, "cooled off")
	b.update(DT, Vector2(0, 0), Vector2(200, 0), true, false)
	assert_true(b.is_hostile(), "sees him again close by: back at it")
	b.reset()
	assert_false(b.grudge, "a new night")


func test_badly_hurt_he_runs_and_shot_down_he_stays_down() -> void:
	var b := RivalBrain.new(POST)
	b.provoke(Vector2(200, 0))
	var o := b.update(DT, Vector2(0, 0), Vector2(200, 0), true, true)
	assert_eq(b.state, RivalBrain.State.FLEEING)
	assert_lt(o.goal.x, 0.0, "away from Danny")
	assert_false(o.fire)
	b.fall()
	b.provoke(Vector2(0, 0))
	assert_eq(b.state, RivalBrain.State.DOWN)
	b.reset()
	assert_eq(b.state, RivalBrain.State.DOWN, "a dead man stays dead")
