class_name CityInput
extends RefCounted
## Keyboard and mouse controls. On foot: WASD walk, the mouse aims, the left
## button is reserved for shooting, E interacts / gets into a car. Driving:
## W accelerate, S brake / reverse, A / D steer, Space handbrake, E get out.
## Arrow keys mirror WASD. Esc pauses, F1 shows the controls.
## Actions are created here unless the project already defines them.

const UP := "move_up"
const DOWN := "move_down"
const LEFT := "move_left"
const RIGHT := "move_right"
const INTERACT := "interact"
const HANDBRAKE := "handbrake"
const FIRE := "fire"
const MENU := "menu"
const HELP := "help"
const QUIT := "quit"

const KEYS := {
	UP: [KEY_W, KEY_UP], DOWN: [KEY_S, KEY_DOWN], LEFT: [KEY_A, KEY_LEFT], RIGHT: [KEY_D, KEY_RIGHT],
	INTERACT: [KEY_E], HANDBRAKE: [KEY_SPACE], MENU: [KEY_ESCAPE], HELP: [KEY_F1], QUIT: [KEY_Q],
}


static func ensure_actions() -> void:
	for action in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in KEYS[action]:
			var e := InputEventKey.new()
			e.physical_keycode = key
			InputMap.action_add_event(action, e)
	if not InputMap.has_action(FIRE):
		InputMap.add_action(FIRE)
		var m := InputEventMouseButton.new()
		m.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event(FIRE, m)


## The player's command for this physics tick from the real devices.
## aim: the world point under the mouse.
static func read(aim: Vector2) -> PlayerCommand:
	var c := PlayerCommand.new()
	c.move = Vector2(Input.get_axis(LEFT, RIGHT), Input.get_axis(UP, DOWN))
	c.aim = aim
	c.interact = Input.is_action_just_pressed(INTERACT)
	c.handbrake = Input.is_action_pressed(HANDBRAKE)
	c.fire = Input.is_action_pressed(FIRE)
	return c
