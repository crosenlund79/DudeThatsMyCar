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
## Left mouse button held, and clicked this tick (one shot per click).
var fire := false
var fire_pressed := false
## M010: Left Shift held: run (on foot only).
var sprint := false
## Answer key pressed this tick (1-4; 0 = none), while talking to someone.
var choice := 0


static func make(p_move: Vector2 = Vector2.ZERO, p_interact: bool = false, p_handbrake: bool = false,
		p_aim: Vector2 = Vector2.ZERO, p_fire_pressed: bool = false) -> PlayerCommand:
	var c := PlayerCommand.new()
	c.move = p_move
	c.interact = p_interact
	c.handbrake = p_handbrake
	c.aim = p_aim
	c.fire_pressed = p_fire_pressed
	c.fire = p_fire_pressed
	return c
