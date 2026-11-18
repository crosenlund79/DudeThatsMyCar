extends GutTest
## M010 one light for every shadow: cast the same way, from the faces turned
## away from it, no longer than the cap; lighter under the street lamps.


func test_cast_from_the_faces_away_from_the_light() -> void:
	var r := Rect2(100, 100, 200, 120)
	var quads := Shadows.cast_quads(r, 50.0)
	assert_eq(quads.size(), 2)
	for q in quads:
		for i in 2:
			assert_almost_eq(q[3 - i].distance_to(q[i]), 50.0, 0.01, "as long as asked")
			assert_almost_eq((q[3 - i] - q[i]).angle_to(Shadows.DIR), 0.0, 0.001, "the way every shadow falls")
		var mid: Vector2 = (q[0] + q[1]) * 0.5
		assert_true(mid.x >= r.end.x - 0.01 or mid.y >= r.end.y - 0.01, "from the right or the bottom face")
	assert_gt(Shadows.DIR.x, 0.0)
	assert_gt(Shadows.DIR.y, 0.0)
	assert_eq(Shadows.length_for(10000.0), Shadows.MAX_LENGTH, "a tall building's shadow is capped")
	assert_lt(Shadows.length_for(40.0), Shadows.length_for(120.0))


func test_lighter_under_a_lamp() -> void:
	var grid := Shadows.lamp_grid([Vector2(500, 500), Vector2(2000, 300)])
	assert_almost_eq(Shadows.fill(Vector2(500, 500), grid), Shadows.UNDER_LAMP, 0.001)
	assert_eq(Shadows.fill(Vector2(1200, 900), grid), 1.0, "in the dark between the lamps")
	assert_gt(Shadows.fill(Vector2(600, 500), grid), Shadows.fill(Vector2(520, 500), grid))
