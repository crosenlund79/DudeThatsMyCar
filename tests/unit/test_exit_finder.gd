extends GutTest
## Getting out of a car: the driver's door first (left side), then the other
## door, behind, in front and the corners; only spots the caller finds clear.

const HALF := Vector2(40, 18)


func test_driver_door_first_then_the_other_side() -> void:
	var spots := ExitFinder.candidates(Transform2D.IDENTITY, HALF)
	assert_eq(spots.size(), 12)
	assert_lt(spots[0].y, -HALF.y, "nose to the right: the driver's (left) door is on the -Y side")
	assert_gt(spots[1].y, HALF.y, "then the passenger side")
	assert_lt(spots[2].x, -HALF.x, "then behind")
	assert_gt(spots[3].x, HALF.x, "then in front")


func test_every_spot_is_clear_of_the_body() -> void:
	for p in ExitFinder.candidates(Transform2D.IDENTITY, HALF):
		var outside := (p.abs() - HALF).max(Vector2.ZERO).length()
		assert_gte(outside, ExitFinder.CLEARANCE - 0.01, "%s stands beside the car, not inside it" % p)


func test_spots_turn_with_the_car() -> void:
	var t := Transform2D(PI / 2, Vector2(100, 50))  # nose pointing down the screen
	var first := ExitFinder.candidates(t, HALF)[0]
	assert_gt(first.x, 100.0 + HALF.y, "driver side is now to the right of the screen")
	assert_almost_eq(first.y, 54.0, 0.01)


func test_find_returns_the_first_clear_spot() -> void:
	var blocked_driver := func(p: Vector2) -> bool: return p.y > 0.0
	var spot: Variant = ExitFinder.find(Transform2D.IDENTITY, HALF, blocked_driver)
	assert_not_null(spot)
	assert_gt((spot as Vector2).y, HALF.y, "driver side blocked: out of the passenger door")


func test_no_room_anywhere_gives_null() -> void:
	assert_null(ExitFinder.find(Transform2D.IDENTITY, HALF, func(_p: Vector2) -> bool: return false))
