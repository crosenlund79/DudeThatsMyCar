extends "res://tests/support/city_test.gd"
## The camera follows whoever the player is, smoothly; closer on foot, easing
## out with the car's speed (within modest limits); it never loses the player
## and stays inside the district.


func test_follows_the_walker_smoothly() -> void:
	var start: Vector2 = main.camera.global_position
	await hold(Vector2.RIGHT, 30)
	var moved: float = walker().global_position.x - main.layout.spawn.x
	assert_gt(moved, 20.0)
	await wait_process_frames(2)
	var cam_moved: float = main.camera.global_position.x - start.x
	assert_gt(cam_moved, 0.0, "follows")
	assert_true(main.camera.view_rect().has_point(walker().global_position), "the player stays on screen")


func test_zooms_out_gently_with_speed_and_back_in_on_foot() -> void:
	var cam: CityCamera = main.camera
	assert_almost_eq(cam.desired_zoom(), cam.foot_zoom, 0.001)
	var c := roadster()
	await park(c, Vector2(400, 1500), 0.0)
	await seat_in(c)
	assert_almost_eq(cam.desired_zoom(), cam.car_zoom_slow, 0.001)
	await hold(Vector2(0, -1), 90)
	assert_lt(cam.desired_zoom(), cam.car_zoom_slow, "a little wider at speed")
	assert_gte(cam.desired_zoom(), cam.car_zoom_fast, "but never far out")
	assert_gte(cam.car_zoom_fast, 0.8, "no extreme zoom")
	assert_lte(cam.foot_zoom, 1.5)
	for i in 30:
		await wait_process_frames(1)
	assert_true(cam.view_rect().grow(-40.0).has_point(c.global_position), "the car stays well on screen")


func test_stays_inside_the_district() -> void:
	var cam: CityCamera = main.camera
	var b: Rect2 = main.layout.bounds
	assert_eq(cam.limit_left, int(b.position.x))
	assert_eq(cam.limit_bottom, int(b.end.y))
	walker().place(Vector2(-780, 600), 0.0)
	cam.snap_to(walker())
	await wait_process_frames(3)
	assert_gte(cam.view_rect().position.x, b.position.x - 1.0)


func test_eye_height_rises_as_the_camera_zooms_out() -> void:
	var cam: CityCamera = main.camera
	cam.zoom = Vector2(1.2, 1.2)
	var close := cam.eye_height()
	cam.zoom = Vector2(0.9, 0.9)
	assert_gt(cam.eye_height(), close, "wider view, gentler lean")
