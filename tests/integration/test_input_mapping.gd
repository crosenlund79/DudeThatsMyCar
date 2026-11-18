extends GutTest
## The real controls: WASD, E, Space and the left mouse button are bound, and
## pressing them through Godot's input actually walks and drives (the game
## scene here uses its normal keyboard-and-mouse command source).

const MAIN := preload("res://src/main/main.tscn")

var main: Node2D


func before_each() -> void:
	main = MAIN.instantiate()
	main.save_path = ""  # never touch the player's real save
	main.settings_path = ""
	main.opening_enabled = false  # M005: straight into the night
	add_child_autofree(main)
	await wait_physics_frames(2)


func after_each() -> void:
	for a in [CityInput.UP, CityInput.DOWN, CityInput.LEFT, CityInput.RIGHT, CityInput.HANDBRAKE, CityInput.SPRINT]:
		Input.action_release(a)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _keys(action: String) -> Array:
	var out := []
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			out.append((e as InputEventKey).physical_keycode)
	return out


func test_keyboard_and_mouse_bindings() -> void:
	assert_has(_keys(CityInput.UP), KEY_W)
	assert_has(_keys(CityInput.DOWN), KEY_S)
	assert_has(_keys(CityInput.LEFT), KEY_A)
	assert_has(_keys(CityInput.RIGHT), KEY_D)
	assert_has(_keys(CityInput.INTERACT), KEY_E)
	assert_has(_keys(CityInput.HANDBRAKE), KEY_SPACE)
	var mouse := InputMap.action_get_events(CityInput.FIRE).filter(func(e: InputEvent) -> bool:
		return e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	assert_eq(mouse.size(), 1, "left mouse button is reserved for shooting")
	for i in 4:
		assert_has(_keys(CityInput.CHOICES[i]), KEY_1 + i, "M003: number keys answer when talking")
	var shift := InputMap.action_get_events(CityInput.SPRINT).filter(func(e: InputEvent) -> bool:
		return e is InputEventKey and (e as InputEventKey).physical_keycode == KEY_SHIFT and (e as InputEventKey).location == KEY_LOCATION_LEFT)
	assert_eq(shift.size(), 1, "M010: Left Shift runs")


func test_left_shift_with_d_runs_right() -> void:
	var w: Walker = main.walker
	var start := w.global_position
	Input.action_press(CityInput.RIGHT)
	Input.action_press(CityInput.SPRINT)
	await wait_physics_frames(40)
	Input.action_release(CityInput.SPRINT)
	Input.action_release(CityInput.RIGHT)
	assert_gt(w.global_position.x - start.x, 40.0 * 108.0 / 60.0 * 1.12, "running through the real input (faster than a walk)")


func test_d_walks_right() -> void:
	var w: Walker = main.walker
	var start := w.global_position
	Input.action_press(CityInput.RIGHT)
	await wait_physics_frames(20)
	Input.action_release(CityInput.RIGHT)
	assert_gt(w.global_position.x, start.x + 10.0)
	assert_almost_eq(w.global_position.y, start.y, 1.0)


func test_w_and_space_drive_the_car() -> void:
	var c: Car = main.cars[0]
	main.walker.place(c.global_position + Vector2(0, -40), 0.0)
	await wait_physics_frames(1)
	main.player.enter(c)
	Input.action_press(CityInput.UP)
	await wait_physics_frames(30)
	assert_true(c.throttle)
	assert_gt(c.model.forward_speed(), 50.0)
	Input.action_press(CityInput.HANDBRAKE)
	await wait_physics_frames(2)
	assert_true(c.handbrake)
