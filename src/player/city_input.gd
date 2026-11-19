class_name CityInput
extends RefCounted
## Keyboard and mouse controls. On foot: WASD walk, the mouse aims, the left
## button shoots, E interacts / gets into a car. Driving:
## W accelerate, S brake / reverse, A / D steer, Space handbrake, E get out.
## Arrow keys mirror WASD. Esc pauses, F1 shows the controls. 1-4 answer
## when you talk to someone. M006: M opens the map of the ward, C how Danny is.
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
const MAP := "map"
const STATUS := "status"
## M008: on the city map, back to Danny.
const RECENTRE := "map_recentre"
## M010: Left Shift, held with WASD on foot: run.
const SPRINT := "sprint"
## M010: Tab on foot: the other gun (the pistol or Eddie's Thompson, while it is on loan).
const SWITCH := "switch_gun"
## M012: H on foot: draw the gun in hand and keep it out, or put it away.
const HOLSTER := "holster"
const CHOICES := ["choice_1", "choice_2", "choice_3", "choice_4"]

const KEYS := {
	UP: [KEY_W, KEY_UP], DOWN: [KEY_S, KEY_DOWN], LEFT: [KEY_A, KEY_LEFT], RIGHT: [KEY_D, KEY_RIGHT],
	INTERACT: [KEY_E], HANDBRAKE: [KEY_SPACE], MENU: [KEY_ESCAPE], HELP: [KEY_F1], QUIT: [KEY_Q], MAP: [KEY_M], STATUS: [KEY_C], RECENTRE: [KEY_R], SWITCH: [KEY_TAB], HOLSTER: [KEY_H],
	"choice_1": [KEY_1, KEY_KP_1], "choice_2": [KEY_2, KEY_KP_2], "choice_3": [KEY_3, KEY_KP_3], "choice_4": [KEY_4, KEY_KP_4],
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
	if not InputMap.has_action(SPRINT):
		InputMap.add_action(SPRINT)
		var shift := InputEventKey.new()
		shift.physical_keycode = KEY_SHIFT
		shift.location = KEY_LOCATION_LEFT
		InputMap.action_add_event(SPRINT, shift)
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
	c.sprint = Input.is_action_pressed(SPRINT)
	c.switch_gun = Input.is_action_just_pressed(SWITCH)
	c.holster = Input.is_action_just_pressed(HOLSTER)
	c.fire = Input.is_action_pressed(FIRE)
	c.fire_pressed = Input.is_action_just_pressed(FIRE)
	for i in CHOICES.size():
		if Input.is_action_just_pressed(CHOICES[i]):
			c.choice = i + 1
	return c
