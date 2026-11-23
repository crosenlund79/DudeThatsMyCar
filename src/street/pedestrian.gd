class_name Pedestrian
extends Node2D
## A passer-by in the street: a Walker body moved by a PedestrianBrain.
## Hidden and out of the physics while the late hour keeps them indoors.

var brain: PedestrianBrain
var body: Walker
var active := true
var start := Vector2.ZERO
## M015: the night's hours they are out (minutes on the night clock; the
## whole night by default), whom they walk beside (a couple), what they say
## now and then, which group of talkers they stand with, the crate a carrier
## carries.
var hours := Vector2(-INF, INF)
var companion: Pedestrian = null
var lines: Array = []
var group := ""
var crate: Sprite2D = null


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


## M015: the kind of walker they are, from their layout entry: {kind, face,
## brave, hours: [from, until], lines, group}; a carrier gets a crate to carry.
func configure(spec: Dictionary, resolver: AssetResolver) -> void:
	_spec = spec
	if spec.has("hours"):
		hours = Vector2(float(spec.hours[0]), float(spec.hours[1]))
	lines = spec.get("lines", [])
	group = String(spec.get("group", ""))
	_apply_brain()
	if brain.kind == "carry" and crate == null:
		crate = Sprite2D.new()
		crate.name = "Crate"
		crate.texture = resolver.get_texture("props/crate")
		crate.scale = AssetCatalog.scale_for(crate.texture, Vector2(15, 15))
		crate.position = Vector2(9, 0)
		body.add_child(crate)


var _spec := {}


func _apply_brain() -> void:
	brain.kind = String(_spec.get("kind", "stroll"))
	brain.brave = bool(_spec.get("brave", false))
	brain.carrying = brain.kind == "carry"
	if brain.kind == "stand":
		brain.spot = start
		brain.face = Vector2.from_angle(float(_spec.get("face", PI * 0.5)))


## Out at this minute of the night.
func out_at(minute: float) -> bool:
	return minute >= hours.x and minute < hours.y


## Back where they started the evening, walking.
func reset() -> void:
	brain = PedestrianBrain.new(brain.route, brain._rng.seed)
	if not _spec.is_empty():
		_apply_brain()
	brain.nearest_on_route(start)
	body.revive()  # M006: if shot last night, another passer-by walks this way
	body.place(start, 0.0)
	set_active(true)


func hear_gunshot(at: Vector2) -> void:
	if active:
		brain.hear_gunshot(body.global_position, at)


## One physics tick; cars: [{pos, vel}]; M015 danny: {pos, level} (the gun he shows).
func tick(dt: float, cars: Array, danny: Dictionary = {}) -> void:
	if not active or body.down:
		return
	var me := body.global_position
	if crate != null:
		crate.visible = brain.carrying and brain.state != PedestrianBrain.State.FLEE
	if companion != null and companion.active and not companion.body.down and _follows():
		_beside(companion, cars, danny, dt)
		return
	if brain.state == PedestrianBrain.State.DODGE and _against_wall():
		brain.blocked()  # M015: no way through there - the other way
	var out := brain.update(dt, me, cars, danny)
	body.model.walk_speed = out.speed
	body.move = out.dir
	body.aim_point = out.look if (out.look as Vector2).distance_to(me) > 4.0 else me + (out.dir as Vector2) * 40.0


## M015: their last step ran into something that is not a car (a wall, a post).
func _against_wall() -> bool:
	for i in body.get_slide_collision_count():
		if not (body.get_slide_collision(i).get_collider() is Car):
			return true
	return false


var _side := 1.0
var _swap := 0.0


## M015: a couple walk together: while nothing has frightened this one, they
## keep to their companion's side (a step behind, a shoulder's width over).
func _follows() -> bool:
	return brain.state in [PedestrianBrain.State.WALK, PedestrianBrain.State.PAUSE, PedestrianBrain.State.RETURN]


func _beside(other: Pedestrian, cars: Array, danny: Dictionary, dt: float) -> void:
	var me := body.global_position
	brain.update(dt, me, cars, danny)  # (their own eyes: a car or a gun still moves them)
	if not _follows():
		return
	var lead := other.body
	var heading := Vector2.from_angle(lead.model.facing)
	_swap -= dt
	if _swap <= 0.0 and _against_wall():
		_side = -_side  # a lamp post, a hydrant, a wall on this side: the other side of him
		_swap = 1.5
	var want := lead.global_position + heading.orthogonal() * 16.0 * _side - heading * 5.0
	var gap := me.distance_to(want)
	body.model.walk_speed = clampf(gap * 2.5, 0.0, PedestrianBrain.BRISK)
	body.move = (want - me).normalized() if gap > 3.0 else Vector2.ZERO
	body.aim_point = me + heading * 40.0 if lead.model.speed() > 8.0 else lead.global_position + heading * 30.0
