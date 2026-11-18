class_name Rival
extends Node2D
## Lefty Moran in the street (M006): a Walker body moved by a RivalBrain along
## CityNavigator routes. He looks for Danny like the beat cop does (in range,
## no building between), shoots at him through the BulletWorld once he has
## been provoked, can be wounded and killed under the same body rules as
## everybody else. Shot dead, he stays dead (saved).

signal fired(muzzle: Vector2, direction: Vector2)
signal provoked
signal struck_down

const NAME := "Lefty Moran"

var brain: RivalBrain
var body: Walker
var navigator: CityNavigator
var bullets: BulletWorld
## Returns the node Danny currently is (on foot or the car he drives).
var target_source: Callable
var _walker: RouteFollower
## M007: held in a fistfight (or a talk): he stands his ground facing Danny.
var held := false
## M008: Danny on foot (only his rounds provoke Lefty; null: anybody's).
var danny: Node


func setup(resolver: AssetResolver, gun_rules: GunRules, post: Array[Vector2], p_navigator: CityNavigator,
		p_bullets: BulletWorld, p_target_source: Callable) -> void:
	name = "Rival"
	navigator = p_navigator
	bullets = p_bullets
	target_source = p_target_source
	brain = RivalBrain.new(post)
	var rules := gun_rules.duplicate() as GunRules
	rules.spare_rounds = -1  # he came out with pockets full
	rules.spread_degrees = gun_rules.spread_degrees + 3.0  # and he is no marksman
	body = Walker.create(resolver, "characters/rival", {"armed_sheet": "characters/rival_armed", "gun": rules, "glow": false})
	body.name = "Body"
	body.rng.seed = 1932007
	add_child(body)
	body.place(post[0] if not post.is_empty() else Vector2.ZERO, PI * 0.5)
	body.aim_point = body.global_position + Vector2.DOWN * 40.0
	_walker = RouteFollower.new(navigator)
	_walker.reset(body.global_position)
	body.hurt.connect(func(_region: String, _level: int) -> void:
		# M008: only Danny's rounds make it personal (a stray police round does not)
		if body.last_shooter != null and body.last_shooter != body and (danny == null or body.last_shooter == danny):
			provoke())
	body.struck_down.connect(func() -> void:
		brain.fall()
		struck_down.emit())


func is_down() -> bool:
	return body.down


func is_hostile() -> bool:
	return brain.is_hostile()


## Danny shot at him (or close enough).
func provoke() -> void:
	var t := _target()
	var was := brain.is_hostile()
	brain.provoke(t.global_position if t != null else body.global_position)
	if not was and brain.is_hostile():
		provoked.emit()


## A shot from `muzzle` along `direction` passed within `near` px of him: that counts.
func near_miss(muzzle: Vector2, direction: Vector2, near: float = 36.0) -> bool:
	return Marksman.passes_near(body.global_position, muzzle, direction, near)


func can_see(p: Vector2) -> bool:
	var me := body.global_position
	if me.distance_to(p) > RivalBrain.SIGHT:
		return false
	var q := PhysicsRayQueryParameters2D.create(me, p, Layers.WORLD)
	return body.get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _target() -> Node2D:
	return target_source.call() if target_source.is_valid() else null


func _physics_process(_delta: float) -> void:
	if body.down:
		return
	if held:
		body.move = Vector2.ZERO
		var tt := _target()
		if tt != null:
			body.aim_point = tt.global_position
		return
	var dt := Car.FIXED_STEP
	var me := body.global_position
	var t := _target()
	var danny := t.global_position if t != null else me
	var sees := t != null and can_see(danny)
	var out := brain.update(dt, me, danny, sees, body.condition.worst() >= BodyCondition.Level.CRITICAL)
	_walker.step(body, out.goal, out.speed, dt)
	body.aim_point = out.look
	if out.fire:
		body.gun.trigger()
	for e in body.gun.step(dt):
		if e == "fired":
			var muzzle := body.muzzle_position()
			var dir := (danny - muzzle).normalized()
			bullets.fire(me, muzzle, dir, body.gun.rules, [body.get_rid()], body.condition.aim_spread(), body)
			fired.emit(muzzle, dir)


## A new night: back at his corner (a dead man stays dead).
func reset() -> void:
	if body.down:
		return
	brain.reset()
	body.condition.heal_all()
	body.gun.holster()
	body.place(brain.post[0] if not brain.post.is_empty() else body.global_position, PI * 0.5)
	_walker.reset(body.global_position)


func to_dict() -> Dictionary:
	return {"dead": body.down}


func from_dict(d: Dictionary) -> void:
	if bool(d.get("dead", false)):
		brain.fall()
		body.condition.damage["torso"] = BodyCondition.MAX
		body.lie_down()
