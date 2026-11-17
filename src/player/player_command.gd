class_name PlayerCommand
extends RefCounted
## What the player asks for in one physics tick, whatever the device (or a test).

## WASD: x -1 left .. +1 right, y -1 up (W, accelerate) .. +1 down (S, brake / reverse).
var move := Vector2.ZERO
## World point under the mouse (aim, on foot).
var aim := Vector2.ZERO
## E pressed this tick: get in / get out.
var interact := false
## Space held (driving).
var handbrake := false
## Left mouse button held: reserved for shooting (no effect yet).
var fire := false


static func make(p_move: Vector2 = Vector2.ZERO, p_interact: bool = false, p_handbrake: bool = false,
		p_aim: Vector2 = Vector2.ZERO) -> PlayerCommand:
	var c := PlayerCommand.new()
	c.move = p_move
	c.interact = p_interact
	c.handbrake = p_handbrake
	c.aim = p_aim
	return c
