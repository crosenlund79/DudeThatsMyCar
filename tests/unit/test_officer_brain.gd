extends GutTest
## The beat cop's decisions: he walks his beat, hears gunfire within range,
## freezes and blows his whistle, then chases while he can see you; when he
## loses you he searches the last place he saw you and gives up after a while,
## walking back to his beat. He only learns where you are by seeing you.

const DT := 1.0 / 60.0
const BEAT := [Vector2(0, 0), Vector2(200, 0)]

var rules: PoliceRules


func before_each() -> void:
	rules = load("res://src/police/default_police.tres")


func _brain() -> OfficerBrain:
	return OfficerBrain.new(rules, PackedVector2Array(BEAT))


func _tick(b: OfficerBrain, me: Vector2, sees := false, player := Vector2.ZERO, vel := Vector2.ZERO) -> Dictionary:
	return b.update(DT, me, sees, player, vel)


func test_he_walks_his_beat_and_pauses_at_the_ends() -> void:
	var b := _brain()
	var out := _tick(b, Vector2(100, 0))
	assert_eq(out.target, BEAT[0])
	assert_almost_eq(out.speed, rules.patrol_speed, 0.001)
	assert_eq(out.icon, "")
	out = _tick(b, BEAT[0])
	assert_eq(out.speed, 0.0, "pauses at the end of the beat")
	for i in int(rules.beat_pause / DT) + 2:
		out = _tick(b, BEAT[0])
	assert_eq(out.target, BEAT[1], "then heads for the other end")


func test_seeing_you_on_his_beat_means_nothing_without_gunfire() -> void:
	var b := _brain()
	for i in 60:
		_tick(b, Vector2(100, 0), true, Vector2(150, 50))
	assert_eq(b.state, OfficerBrain.State.PATROL)


func test_a_shot_within_earshot_alerts_him_then_he_gives_chase() -> void:
	var b := _brain()
	assert_true(b.hear_gunshot(Vector2.ZERO, Vector2(500, 0), 720.0))
	assert_eq(b.state, OfficerBrain.State.ALERTED)
	assert_true(b.noticed_now, "whistle and '!'")
	var out := _tick(b, Vector2.ZERO)
	assert_eq(out.speed, 0.0, "he freezes for a moment")
	assert_eq(out.icon, "alert")
	assert_eq(out.look, Vector2(500, 0), "facing where the shot came from")
	for i in int(rules.alert_time / DT) + 2:
		out = _tick(b, Vector2.ZERO)
	assert_eq(b.state, OfficerBrain.State.CHASE)
	assert_eq(out.target, Vector2(500, 0), "running towards the shot")
	assert_almost_eq(out.speed, rules.chase_speed, 0.001)


func test_a_distant_shot_is_not_heard() -> void:
	var b := _brain()
	assert_false(b.hear_gunshot(Vector2.ZERO, Vector2(900, 0), 720.0))
	assert_false(b.hear_gunshot(Vector2.ZERO, Vector2(700, 0), 400.0), "a quiet gun carries less")
	assert_eq(b.state, OfficerBrain.State.PATROL)


func test_he_follows_you_while_he_sees_you() -> void:
	var b := _brain()
	b.hear_gunshot(Vector2.ZERO, Vector2(300, 0), 720.0)
	for i in 60:
		_tick(b, Vector2.ZERO)
	var out := _tick(b, Vector2(10, 0), true, Vector2(260, 120), Vector2(100, 0))
	assert_eq(out.target, Vector2(260, 120))
	assert_eq(b.last_known, Vector2(260, 120))


func test_out_of_sight_he_goes_to_the_last_place_he_saw_you_not_where_you_are() -> void:
	var b := _brain()
	b.hear_gunshot(Vector2.ZERO, Vector2(300, 0), 720.0)
	for i in 60:
		_tick(b, Vector2.ZERO)
	_tick(b, Vector2.ZERO, true, Vector2(300, 100), Vector2(0, 100))
	var out := _tick(b, Vector2.ZERO, false, Vector2(900, 900))  # you are far away now, unseen
	assert_eq(out.target, Vector2(300, 100), "no magic knowledge")


func test_losing_you_leads_to_a_search_then_he_gives_up_and_returns() -> void:
	var b := _brain()
	b.hear_gunshot(Vector2.ZERO, Vector2(300, 0), 720.0)
	for i in 60:
		_tick(b, Vector2.ZERO)
	_tick(b, Vector2.ZERO, true, Vector2(300, 100), Vector2(0, 100))
	_tick(b, Vector2(300, 100))  # reached the last sighting, nobody there
	assert_eq(b.state, OfficerBrain.State.SEARCH)
	var out := _tick(b, Vector2(300, 100))
	assert_eq(out.icon, "search")
	assert_gt((out.target as Vector2).y, 100.0, "follows the way you were heading")
	var gave_up := false
	for i in int(rules.search_time / DT) + 2:
		_tick(b, Vector2(300, 100))
		gave_up = gave_up or b.gave_up_now
	assert_true(gave_up)
	assert_eq(b.state, OfficerBrain.State.RETURN)
	out = _tick(b, Vector2(300, 100))
	assert_eq(out.icon, "")
	assert_eq(out.target, BEAT[1], "back to the nearest end of his beat")
	_tick(b, BEAT[1])
	assert_eq(b.state, OfficerBrain.State.PATROL)


func test_spotting_you_during_the_search_restarts_the_chase() -> void:
	var b := _brain()
	b.hear_gunshot(Vector2.ZERO, Vector2(300, 0), 720.0)
	for i in 60:
		_tick(b, Vector2.ZERO)
	_tick(b, Vector2(300, 0))
	assert_eq(b.state, OfficerBrain.State.SEARCH)
	_tick(b, Vector2(300, 0), true, Vector2(350, 40))
	assert_eq(b.state, OfficerBrain.State.CHASE)
	assert_true(b.noticed_now)


func test_he_stops_close_to_you() -> void:
	var b := _brain()
	b.hear_gunshot(Vector2.ZERO, Vector2(30, 0), 720.0)
	for i in 60:
		_tick(b, Vector2.ZERO)
	var out := _tick(b, Vector2.ZERO, true, Vector2(rules.close_distance - 2.0, 0))
	assert_eq(out.speed, 0.0, "no arrests yet: he keeps close")


func test_being_shot_at_alerts_him() -> void:
	var b := _brain()
	b.shot_at(Vector2(-200, 0))
	assert_eq(b.state, OfficerBrain.State.ALERTED)
	assert_eq(b.last_known, Vector2(-200, 0))
