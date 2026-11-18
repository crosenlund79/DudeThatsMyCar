extends GutTest
## Base for tests that run the real game scene with scripted commands instead
## of the keyboard and mouse.

const MAIN := preload("res://src/main/main.tscn")

var main: Node2D
var cmd := PlayerCommand.new()
## One E press / one click waiting to be read by the controller (each delivered exactly once).
var _e_pending := false
var _fire_pending := false
var _choice_pending := 0
## Street life (passers-by, traffic) is cleared for tests about other things;
## a test script about the streets sets this to false.
var quiet_streets := true
## M006: Danny already knows everybody (their first-meeting lines count as
## heard) unless a script about meeting people sets this to true.
var meet_people := false


func _source(_c: PlayerController) -> PlayerCommand:
	var out := PlayerCommand.make(cmd.move, cmd.interact, cmd.handbrake, cmd.aim)
	out.sprint = cmd.sprint  # M010
	if _choice_pending > 0:
		out.choice = _choice_pending
		_choice_pending = 0
	if _e_pending:
		out.interact = true
		_e_pending = false
	if _fire_pending:
		out.fire_pressed = true
		out.fire = true
		_fire_pending = false
	return out


func before_each() -> void:
	cmd = PlayerCommand.new()
	_e_pending = false
	_fire_pending = false
	_choice_pending = 0
	main = MAIN.instantiate()
	main.command_source = _source
	main.save_path = ""  # never touch the player's real save
	main.settings_path = ""  # nor their sound levels
	main.opening_enabled = false  # straight into the night (test_opening covers the opening)
	main.quiet_streets = quiet_streets  # M008: the neighbouring districts' street life too
	add_child_autofree(main)
	if quiet_streets:
		main.street.clear()
	if not meet_people:
		for id in VoiceLines.LINES:
			main.voice_lines.mark(id)
	await wait_physics_frames(2)


func after_each() -> void:
	get_tree().paused = false


## The streetcar stop in the middle of Marlowe Avenue, between the Copper Owl
## and Hotel Marlowe, a few steps from the roadster (where M001 / M002 began).
const STREETCAR_STOP := Vector2(2350, 600)


## Steps out of the flat to the streetcar stop (most street tests start there).
func at_the_streetcar_stop() -> void:
	walker().place(STREETCAR_STOP, PI * 0.3)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)


func player() -> PlayerController:
	return main.player


func walker() -> Walker:
	return main.walker


func car_of_type(id: String) -> Car:
	for c in main.cars:
		if c.vehicle.id == id:
			return c
	return null


## The roadster parked by the hotel, next to the streetcar stop.
func roadster() -> Car:
	var best: Car = null
	for c in main.cars:
		if c.vehicle.id == "coupe" and (best == null or c.global_position.distance_to(STREETCAR_STOP) < best.global_position.distance_to(STREETCAR_STOP)):
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


## Drives `c` (the player must be in it) through waypoints using only the
## normal W / A / S / D command, like a careful driver: steer towards the
## next point, keep to `cruise`, slow down for sharp turns. Returns the
## number of ticks used (max_ticks when it never got there).
func drive_route(c: Car, points: Array, cruise: float, max_ticks: int = 900) -> int:
	var i := 0
	for t in max_ticks:
		var target: Vector2 = points[i]
		if c.global_position.distance_to(target) < 40.0:
			i += 1
			if i >= points.size():
				cmd = PlayerCommand.new()
				return t
			target = points[i]
		var diff := angle_difference(c.model.heading, (target - c.global_position).angle())
		var steer := 0.0
		if diff > 0.05:
			steer = 1.0
		elif diff < -0.05:
			steer = -1.0
		var speed := c.model.forward_speed()
		var want := cruise if absf(diff) < 0.45 else cruise * 0.5
		var pedal := 0.0
		if speed < want:
			pedal = -1.0
		elif speed > want + 50.0:
			pedal = 1.0
		cmd = PlayerCommand.make(Vector2(steer, pedal))
		await wait_physics_frames(1)
	cmd = PlayerCommand.new()
	return max_ticks


## Presses answer key n (1-4) once while talking.
func answer(n: int) -> void:
	cmd = PlayerCommand.new()
	_choice_pending = n
	for i in 10:
		await wait_physics_frames(1)
		if _choice_pending == 0:
			break
	await wait_physics_frames(1)


## Answers with the option whose id is `id` on the page on screen (fails the test if absent).
func answer_with(id: String) -> void:
	var opts: Array = main._page.get("options", [])
	for i in opts.size():
		if opts[i].id == id:
			await answer(i + 1)
			return
	fail_test("no answer '%s' on the page (%s)" % [id, opts.map(func(o: Dictionary) -> String: return o.id)])


## Walks up to a person's talk spot inside a room and presses E.
func talk_to(plan_id: String, person_id: String) -> void:
	var plan: InteriorPlan = main.interiors.view_of(plan_id).plan
	var spot := {}
	for s in plan.spots:
		if s.id == person_id:
			spot = s
	walker().place(spot.pos, 0.0)
	await wait_physics_frames(3)
	await press_e()


## A walking path inside a room from `from` to within reach of `to`, round
## the furniture (a breadth-first search on a 6 px grid, like a person
## looking where to step). Empty when there is no way.
func path_in_room(plan: InteriorPlan, from: Vector2, to: Vector2, reach: float = 20.0) -> Array:
	var step := 6.0
	var r := Walker.RADIUS + 1.0
	var walls := plan.wall_boxes()
	var free := func(q: Vector2) -> bool:
		if not plan.room.has_point(q):
			return false
		for b in walls:
			if b.grow(r).has_point(q):
				return false
		for f in plan.furniture:
			if f.has("radius") and q.distance_to(f.pos) < float(f.radius) + r:
				return false
			if f.has("box"):
				var local: Vector2 = (q - (f.pos as Vector2)).rotated(-float(f.get("rot", 0.0)))
				if Rect2(-(f.box as Vector2) * 0.5, f.box).grow(r).has_point(local):
					return false
		return true
	var start := Vector2i(roundi(from.x / step), roundi(from.y / step))
	var parent := {start: start}
	var queue := [start]
	var goal := Vector2i(-99999, -99999)
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		if (Vector2(c) * step).distance_to(to) <= reach:
			goal = c
			break
		for n in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
			var nc: Vector2i = c + n
			if not parent.has(nc) and free.call(Vector2(nc) * step):
				parent[nc] = c
				queue.append(nc)
	if goal.x == -99999:
		return []
	var cells := [goal]
	while cells[0] != start:
		cells.push_front(parent[cells[0]])
	var out := []
	for i in range(0, cells.size(), 3):  # every third cell is plenty for walk_to
		out.append(Vector2(cells[i]) * step)
	out.append(Vector2(goal) * step)
	return out


## Walks from the street in through door `door` of a room to the spot `spot_id`
## with the normal WASD movement (no teleporting inside). Returns true when
## the walker got there.
func walk_in_to(plan: InteriorPlan, spot_id: String, door: int = 0) -> bool:
	var spot := {}
	for s in plan.spots:
		if s.id == spot_id:
			spot = s
	walker().place(plan.outside_door(door, 40.0), (-(plan.doors[door].side as Vector2)).angle())
	main.camera.snap_to(walker())
	await wait_physics_frames(2)
	await walk_to(plan.outside_door(door, 14.0), 4.0, 240)
	await walk_to(plan.inside_door(door, 14.0), 4.0, 240)
	for p in path_in_room(plan, walker().global_position, spot.pos, float(spot.radius) - 10.0):
		await walk_to(p, 4.0, 120)
	await wait_physics_frames(3)
	return walker().global_position.distance_to(spot.pos) <= float(spot.radius)


## One left click with the mouse over `aim` (the aim stays there afterwards).
func click(aim: Vector2, move: Vector2 = Vector2.ZERO) -> void:
	cmd = PlayerCommand.make(move, false, false, aim)
	_fire_pending = true
	for i in 10:
		await wait_physics_frames(1)
		if not _fire_pending:
			break


## Keeps the mouse over `aim` (and walks `move`) for n ticks.
func aim_for(aim: Vector2, ticks: int, move: Vector2 = Vector2.ZERO) -> void:
	cmd = PlayerCommand.make(move, false, false, aim)
	await wait_physics_frames(ticks)
