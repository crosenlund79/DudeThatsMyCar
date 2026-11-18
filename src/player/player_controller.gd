class_name PlayerController
extends Node
## Who the player is right now: the person on foot, or the car they drive.
## Each physics tick it turns the player's command into walking (move + aim)
## or driving (throttle, brake / reverse, steer, handbrake), and handles E:
## get into the nearest parked car, or get out of the car once it has
## stopped, onto a clear spot beside it (never into a wall, a car, the river
## or out of the district).

signal entered_car(car: Car)
signal exited_car(car: Car)
## A short message for the player ("No room to get out here.").
signal notice(text: String)
## The player fired (muzzle position, direction). Anyone who cares about
## gunfire (the presentation, the police) listens to this.
signal fired(muzzle: Vector2, direction: Vector2)
## Other gun moments for sound and HUD: "drawn", "reload", "reloaded", "holstered".
signal gun_event(event: String, at: Vector2)

## How close (px from the car's body) the player must be to get in.
const ENTER_RANGE := 26.0
## A car moving faster than this cannot be entered (px/s).
const ENTER_MAX_SPEED := 40.0
## Below this speed the driver steps out at once; faster, the car stops first.
const EXIT_SPEED := 40.0

var walker: Walker
var cars: Array[Car] = []
## Where a person may stand (M008: the loaded districts - anything with
## is_open_ground(p, radius); a City or the DistrictStreamer).
var city: Object
## Where the player's bullets fly (set by the game; null: the gun cannot fire).
var bullets: BulletWorld
## Car being driven (null on foot).
var car: Car = null
## Supplies the command each tick: func(controller) -> PlayerCommand.
## Default: the real keyboard and mouse.
var command_source: Callable
## E on foot is offered here first (talk to someone, use the bed):
## func(position) -> bool, true when it did something. Otherwise E gets into a car.
var interaction: Callable
## While the player talks to someone this takes his command instead of
## walking and shooting: func(command) -> bool, true while talking.
var conversation: Callable
## True while the car brakes to a stop because the player asked to get out.
var leaving := false
var last_command := PlayerCommand.new()


func setup(p_walker: Walker, p_cars: Array[Car], p_city: Object) -> void:
	walker = p_walker
	cars = p_cars
	city = p_city
	if not command_source.is_valid():
		command_source = func(_c: PlayerController) -> PlayerCommand: return CityInput.read(walker.get_global_mouse_position())


func on_foot() -> bool:
	return car == null


## The node the camera follows.
func body() -> Node2D:
	return walker if car == null else car


func _physics_process(_delta: float) -> void:
	var cmd: PlayerCommand = command_source.call(self)
	last_command = cmd
	if car == null and conversation.is_valid() and conversation.call(cmd):
		walker.move = Vector2.ZERO
		return
	if car == null:
		_walk(cmd)
	else:
		_drive(cmd)


func _walk(cmd: PlayerCommand) -> void:
	walker.move = cmd.move
	walker.aim_point = cmd.aim
	if cmd.interact:
		if interaction.is_valid() and interaction.call(walker.global_position):
			return
		var c := enterable_car()
		if c != null:
			enter(c)
			return
	if walker.gun == null:
		return
	if cmd.fire_pressed:
		walker.gun.trigger()
	for e in walker.gun.step(Car.FIXED_STEP):
		if e == "fired":
			_shoot(cmd.aim)
		else:
			gun_event.emit(e, walker.global_position)


## Fires towards the aim point (straight ahead when the aim is on top of the gangster).
func _shoot(aim: Vector2) -> void:
	var muzzle := walker.muzzle_position()
	var dir := aim - muzzle
	if aim.distance_to(walker.global_position) < walker.gun.rules.muzzle_offset.length() + 4.0 or dir.length() < 1.0:
		dir = Vector2.from_angle(walker.model.facing)
	if bullets != null:
		bullets.fire(walker.global_position, muzzle, dir, walker.gun.rules, [walker.get_rid()], walker.condition.aim_spread(), walker)
	fired.emit(muzzle, dir.normalized())


func _drive(cmd: PlayerCommand) -> void:
	if cmd.interact:
		leaving = true
	if leaving:
		# both pedals: the car brakes to a stop whichever way it rolls
		car.steer = 0.0
		car.throttle = true
		car.brake = true
		car.handbrake = false
		if car.speed() <= EXIT_SPEED:
			exit_car()
		return
	car.steer = clampf(cmd.move.x, -1.0, 1.0)
	car.throttle = cmd.move.y < -0.3
	car.brake = cmd.move.y > 0.3
	car.handbrake = cmd.handbrake


## Distance from p to the car's body outline (0 inside).
static func distance_to_body(c: Car, p: Vector2) -> float:
	var local := c.global_transform.affine_inverse() * p
	var half := c.vehicle.size * 0.5
	return (local.abs() - half).max(Vector2.ZERO).length()


## The nearest parked car within reach, or null.
func enterable_car() -> Car:
	var best: Car = null
	var best_d := INF
	for c in cars:
		if c.driven or c.speed() > ENTER_MAX_SPEED or not c.visible:
			continue
		var dist := distance_to_body(c, walker.global_position)
		if dist <= ENTER_RANGE and dist < best_d:
			best = c
			best_d = dist
	return best


func enter(c: Car) -> void:
	car = c
	leaving = false
	c.driven = true
	c.clear_command()
	if walker.gun != null:
		walker.gun.holster()
	walker.active = false
	walker.visible = false
	walker.velocity = Vector2.ZERO
	_set_walker_solid(false)
	entered_car.emit(c)


## Steps out beside the car if there is room; otherwise stays in and says so.
func exit_car() -> bool:
	var c := car
	var spot: Variant = ExitFinder.find(c.global_transform, c.vehicle.size * 0.5, func(p: Vector2) -> bool: return spot_clear(p, c))
	leaving = false
	if spot == null:
		c.clear_command()
		notice.emit("No room to get out here.")
		return false
	c.driven = false
	c.clear_command()
	car = null
	walker.place(spot, (spot - c.global_position).angle())
	walker.aim_point = spot + ((spot as Vector2) - c.global_position)
	walker.visible = true
	walker.active = true
	_set_walker_solid(true)
	exited_car.emit(c)
	return true


## M008: out of the car at once, wherever it is (Danny went down at the wheel;
## the game puts him somewhere else straight after). The car stops where it is.
func eject() -> void:
	if car == null:
		return
	var c := car
	c.driven = false
	c.clear_command()
	car = null
	leaving = false
	walker.place(c.global_position, c.rotation)
	walker.visible = true
	walker.active = true
	_set_walker_solid(true)
	exited_car.emit(c)


## A spot is clear when it is open ground in the district, nothing solid
## (wall, prop, another car) is there, and no wall stands between the
## driver's seat and the spot.
func spot_clear(p: Vector2, from_car: Car) -> bool:
	if city != null and not city.is_open_ground(p, Walker.RADIUS):
		return false
	var space := walker.get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = Walker.RADIUS + 1.0
	q.shape = circle
	q.transform = Transform2D(0.0, p)
	q.collision_mask = Layers.WORLD | Layers.CARS | Layers.PEOPLE
	q.exclude = [from_car.get_rid(), walker.get_rid()]
	if not space.intersect_shape(q, 1).is_empty():
		return false
	var ray := PhysicsRayQueryParameters2D.create(from_car.global_position, p, Layers.WORLD)
	return space.intersect_ray(ray).is_empty()


func _set_walker_solid(on: bool) -> void:
	for child in walker.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", not on)
