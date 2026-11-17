extends GutTest
## Base for tests that run the real game scene with scripted commands instead
## of the keyboard and mouse.

const MAIN := preload("res://src/main/main.tscn")

var main: Node2D
var cmd := PlayerCommand.new()
## One E press waiting to be read by the controller (delivered exactly once).
var _e_pending := false


func _source(_c: PlayerController) -> PlayerCommand:
	var out := PlayerCommand.make(cmd.move, cmd.interact, cmd.handbrake, cmd.aim)
	if _e_pending:
		out.interact = true
		_e_pending = false
	return out


func before_each() -> void:
	cmd = PlayerCommand.new()
	_e_pending = false
	main = MAIN.instantiate()
	main.command_source = _source
	add_child_autofree(main)
	await wait_physics_frames(2)


func after_each() -> void:
	get_tree().paused = false


func player() -> PlayerController:
	return main.player


func walker() -> Walker:
	return main.walker


func car_of_type(id: String) -> Car:
	for c in main.cars:
		if c.vehicle.id == id:
			return c
	return null


## The roadster parked by the hotel, next to the start.
func roadster() -> Car:
	var best: Car = null
	for c in main.cars:
		if c.vehicle.id == "coupe" and (best == null or c.global_position.distance_to(main.layout.spawn) < best.global_position.distance_to(main.layout.spawn)):
			best = c
	return best


## Holds a command for n physics ticks (E is a single tick press).
func hold(move: Vector2, ticks: int, handbrake := false) -> void:
	cmd = PlayerCommand.make(move, false, handbrake, walker().global_position + move * 50.0)
	await wait_physics_frames(ticks)
	cmd = PlayerCommand.new()


func press_e() -> void:
	cmd = PlayerCommand.new()
	_e_pending = true
	for i in 10:
		await wait_physics_frames(1)
		if not _e_pending:
			break
	await wait_physics_frames(1)


## Walks towards a point until within `near` px or out of time.
func walk_to(p: Vector2, near: float = 6.0, max_ticks: int = 600) -> void:
	for i in max_ticks:
		var to := p - walker().global_position
		if to.length() <= near:
			break
		cmd = PlayerCommand.make(to.normalized(), false, false, p)
		await wait_physics_frames(1)
	cmd = PlayerCommand.new()


## Puts the player in car c right away (bypassing the walk).
func seat_in(c: Car) -> void:
	walker().place(c.global_position + c.global_transform.y * -40.0, 0.0)
	await wait_physics_frames(1)
	player().enter(c)


## Moves a car to a spot at rest.
func park(c: Car, at: Vector2, rot: float) -> void:
	c.place(Transform2D(rot, at))
	c.model.position = at
	await wait_physics_frames(2)
