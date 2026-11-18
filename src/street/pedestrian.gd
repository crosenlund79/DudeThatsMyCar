class_name Pedestrian
extends Node2D
## A passer-by in the street: a Walker body moved by a PedestrianBrain.
## Hidden and out of the physics while the late hour keeps them indoors.

var brain: PedestrianBrain
var body: Walker
var active := true
var start := Vector2.ZERO


func setup(resolver: AssetResolver, look: String, route: PackedVector2Array, at: Vector2, seed: int) -> void:
	name = "Pedestrian%d" % seed
	start = at
	brain = PedestrianBrain.new(route, seed)
	brain.nearest_on_route(at)
	body = Walker.create(resolver, look, {"glow": false})
	body.name = "Body"
	body.rng.seed = seed
	add_child(body)
	body.place(at, 0.0)
	body.shot_at.connect(func(hit: Vector2, direction: Vector2) -> void: brain.hear_gunshot(body.global_position, hit - direction * 200.0))


func set_active(on: bool) -> void:
	active = on
	body.active = on
	body.visible = on
	for child in body.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", not on)
	if not on:
		body.velocity = Vector2.ZERO
		body.move = Vector2.ZERO


## Back where they started the evening, walking.
func reset() -> void:
	brain = PedestrianBrain.new(brain.route, brain._rng.seed)
	brain.nearest_on_route(start)
	body.revive()  # M006: if shot last night, another passer-by walks this way
	body.place(start, 0.0)
	set_active(true)


func hear_gunshot(at: Vector2) -> void:
	if active:
		brain.hear_gunshot(body.global_position, at)


## One physics tick; cars: [{pos, vel}].
func tick(dt: float, cars: Array) -> void:
	if not active or body.down:
		return
	var me := body.global_position
	var out := brain.update(dt, me, cars)
	body.model.walk_speed = out.speed
	body.move = out.dir
	body.aim_point = out.look if (out.look as Vector2).distance_to(me) > 4.0 else me + (out.dir as Vector2) * 40.0
