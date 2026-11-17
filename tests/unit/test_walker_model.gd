extends GutTest
## On foot: moves where WASD points at walking pace, speeds up and stops
## quickly, never faster on the diagonal, and faces the aim independently.

const DT := 1.0 / 60.0


func _walk(m: WalkerModel, move: Vector2, seconds: float) -> void:
	for i in int(round(seconds / DT)):
		m.update(DT, move)


func test_walks_where_the_keys_point_at_walking_pace() -> void:
	var m := WalkerModel.new()
	_walk(m, Vector2.RIGHT, 1.0)
	assert_almost_eq(m.velocity, Vector2(m.walk_speed, 0), Vector2(0.01, 0.01))


func test_diagonals_are_not_faster() -> void:
	var m := WalkerModel.new()
	_walk(m, Vector2(1, 1), 1.0)
	assert_almost_eq(m.speed(), m.walk_speed, 0.01)


func test_starts_and_stops_quickly() -> void:
	var m := WalkerModel.new()
	_walk(m, Vector2.UP, 0.25)
	assert_almost_eq(m.speed(), m.walk_speed, 0.01, "up to pace within a quarter second")
	_walk(m, Vector2.ZERO, 0.2)
	assert_eq(m.velocity, Vector2.ZERO, "stops within a fifth of a second")


func test_aim_is_independent_of_movement() -> void:
	var m := WalkerModel.new()
	m.aim_at(Vector2.ZERO, Vector2(0, -100))
	_walk(m, Vector2.RIGHT, 0.5)
	assert_almost_eq(m.facing, -PI / 2, 0.0001, "walks right while looking up the street")
	m.aim_at(Vector2(10, 10), Vector2(10.5, 10.5))
	assert_almost_eq(m.facing, -PI / 2, 0.0001, "an aim point on top of the player changes nothing")
