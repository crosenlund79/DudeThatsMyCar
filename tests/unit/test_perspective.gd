extends GutTest
## The top-down camera's perspective: the street stays put, raised things lean
## away from the screen centre in proportion to height and distance, the
## centre never moves, reflections lean the other way, heights are bounded.

const EYE := Vector2(100, 200)
const H := 1000.0


func test_street_level_is_unchanged() -> void:
	assert_eq(Perspective.project(Vector2(400, -50), 0.0, EYE, H), Vector2(400, -50))


func test_raised_points_lean_away_from_the_centre() -> void:
	var p := Vector2(400, 200)
	var top := Perspective.project(p, 100.0, EYE, H)
	assert_gt(top.x, p.x)
	assert_almost_eq(top.y, p.y, 0.0001)
	assert_almost_eq(top.x - p.x, 300.0 * (H / (H - 100.0) - 1.0), 0.001)


func test_taller_and_farther_lean_more() -> void:
	var near := Perspective.project(EYE + Vector2(100, 0), 100.0, EYE, H)
	var far := Perspective.project(EYE + Vector2(300, 0), 100.0, EYE, H)
	var tall := Perspective.project(EYE + Vector2(100, 0), 200.0, EYE, H)
	assert_gt(far.x - (EYE.x + 300), near.x - (EYE.x + 100))
	assert_gt(tall.x, near.x)


func test_the_point_under_the_eye_never_moves() -> void:
	assert_eq(Perspective.project(EYE, 250.0, EYE, H), EYE)


func test_reflections_lean_towards_the_centre() -> void:
	var p := Vector2(400, 200)
	assert_lt(Perspective.project(p, -80.0, EYE, H).x, p.x)


func test_scale_grows_with_height_and_is_bounded() -> void:
	assert_eq(Perspective.scale_at(0.0, H), 1.0)
	assert_gt(Perspective.scale_at(100.0, H), 1.0)
	assert_eq(Perspective.scale_at(5000.0, H), Perspective.scale_at(H * Perspective.MAX_HEIGHT_SHARE, H), "clamped")
	assert_true(is_finite(Perspective.scale_at(H, H)))
