extends GutTest
## M013 the rain's motion (WeatherView.fall, what rain.gdshader draws from):
## M012's rain ran upwards and doubled because the fall was TIME times a speed
## that changed with the downpour. Now each depth's fall is integrated frame by
## frame: whatever the downpour does, the drops move down by speed x delta each
## frame - never up, never by a jump; they move with the street as the camera
## pans (the nearer depths a little more), not when it only zooms; and the
## numbers wrap at the pattern's period so they stay small all night.

var model: Weather
var view: WeatherView


func before_each() -> void:
	model = Weather.new()
	model.begin_night(1, 19 * 60 + 30.0)
	model.force("rain")
	view = WeatherView.new()
	add_child_autofree(view)
	view.setup(model)


## How far depth i moved down the screen (px) between two anchors, unwrapped.
func _down(before: Vector2, after: Vector2, i: int) -> float:
	var period := WeatherView.RAIN_CELL.y * WeatherView.RAIN_PERIOD
	var d := wrapf(before.y - after.y, -period * 0.5, period * 0.5)
	return d * float(WeatherView.RAIN_NEAR[i])


func test_the_drops_fall_down_steadily_while_a_downpour_swells_and_eases() -> void:
	var eye := Vector2(2350, 600)
	view.fall(eye, 1.0, 0.0)
	var dt := 1.0 / 60.0
	var worst_jump := 0.0
	var least_down := INF
	for frame in 60 * 600:  # ten minutes of play, the downpour coming and going
		model.minute = 19 * 60 + 30.0 + frame * dt * 6.0  # six game minutes a second: many swells
		var before := view.anchors.duplicate()
		view.fall(eye, 1.0, dt)
		for i in 3:
			var down := _down(before[i], view.anchors[i], i)
			var expect := (WeatherView.RAIN_SPEED + WeatherView.DOWNPOUR_SPEED * model.downpour()) * dt * float(WeatherView.RAIN_NEAR[i])
			least_down = minf(least_down, down)
			worst_jump = maxf(worst_jump, absf(down - expect))
	assert_gt(least_down, 0.0, "never up, never still")
	assert_lt(worst_jump, 0.01, "each frame exactly its speed, whatever the downpour did")
	var seen_heavy := false
	for m in range(0, 600):
		model.minute = 19 * 60 + 30.0 + m
		seen_heavy = seen_heavy or model.downpour() > 0.5
	assert_true(seen_heavy, "(the test went through a downpour)")


func test_heavier_rain_falls_faster() -> void:
	var eye := Vector2.ZERO
	view.fall(eye, 1.0, 0.0)
	model.force("rain")
	var calm := view.anchors[0]
	view.fall(eye, 1.0, 0.1)
	var steady := _down(calm, view.anchors[0], 0)
	for m in range(0, 2000):
		model.minute = 19 * 60 + 30.0 + m
		if model.downpour() > 0.95:
			break
	var before := view.anchors[0]
	view.fall(eye, 1.0, 0.1)
	assert_gt(_down(before, view.anchors[0], 0), steady * 1.3, "a downpour drives it down harder")


func test_moves_with_the_street_when_the_camera_pans_not_when_it_zooms() -> void:
	view.fall(Vector2(1000, 1000), 0.8, 0.0)
	var a0 := view.anchors.duplicate()
	view.fall(Vector2(1100, 1000), 0.8, 0.0)  # the camera 100 px east: the street slides 80 px west on screen
	for i in 3:
		var near: float = WeatherView.RAIN_NEAR[i]
		var on_screen: float = (view.anchors[i].x - (a0[i] as Vector2).x) * near
		assert_almost_eq(on_screen, 80.0 * float(WeatherView.RAIN_PARALLAX[i]), 0.01, "depth %d with the street" % i)
	assert_gt(float(WeatherView.RAIN_PARALLAX[0]), float(WeatherView.RAIN_PARALLAX[2]), "the nearer drops move more")
	var a1 := view.anchors.duplicate()
	view.fall(Vector2(1100, 1000), 0.6, 0.0)  # only zooming out
	for i in 3:
		assert_eq(view.anchors[i], a1[i], "a zoom does not throw the rain sideways")


func test_a_jump_of_the_camera_moves_nothing() -> void:
	view.fall(Vector2(0, 0), 1.0, 0.0)
	var a0 := view.anchors.duplicate()
	view.fall(Vector2(5000, 3000), 1.0, 0.0)  # loading a game, a snap across the city
	assert_eq(view.anchors, a0)


func test_the_numbers_stay_small_all_night() -> void:
	var eye := Vector2(-3000, 4000)
	for i in 60 * 60 * 3:  # three hours at 60 fps, driving about
		eye += Vector2(3.0, -2.0)
		view.fall(eye, 0.7, 1.0 / 60.0)
	var period := WeatherView.RAIN_CELL * WeatherView.RAIN_PERIOD
	for a in view.anchors:
		assert_true(a.x >= 0.0 and a.x < period.x and a.y >= 0.0 and a.y < period.y, "wrapped: %s" % a)
	assert_true(view.splash_time >= 0.0 and view.splash_time < 1.0)
