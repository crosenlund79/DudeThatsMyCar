class_name BulletWorld
extends Node2D
## Bullets in flight. Each physics tick every bullet moves on and checks the
## stretch it travelled with a ray against buildings and other solid things,
## cars and people, so a fast bullet can never skip through a wall. A bullet
## stops at the first thing it meets (impact) or when it runs out of range
## (spent). Whatever it hits may react through hit_by_bullet(position, direction).
## The tracers and sounds are drawn by GunfireView.

signal impact(position: Vector2, normal: Vector2, collider: Object, direction: Vector2)
## M008: the same moment, with who fired it (null: unknown) - for witnesses and the driver of a hit car.
signal struck(collider: Object, position: Vector2, direction: Vector2, shooter: Node)
signal spent(position: Vector2)

const MASK := Layers.WORLD | Layers.CARS | Layers.PEOPLE

## {pos, dir, speed, left, exclude, shooter}
var bullets: Array = []
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 1932


## Fires from a shooter at body_pos whose muzzle is at muzzle, along direction.
## A muzzle pressed into a wall fires into the wall. M006: `extra_spread`
## (degrees) for a wounded gun arm; `shooter` is told to whatever is hit.
func fire(body_pos: Vector2, muzzle: Vector2, direction: Vector2, rules: GunRules, exclude: Array[RID] = [],
		extra_spread: float = 0.0, shooter: Node = null) -> void:
	var spread := deg_to_rad(rules.spread_degrees + extra_spread)
	var dir := direction.normalized().rotated(rng.randf_range(-spread, spread))
	var blocked := ray(body_pos, muzzle, exclude, Layers.WORLD)
	if not blocked.is_empty():
		_hit(blocked, dir, shooter)
		return
	bullets.append({"pos": muzzle, "dir": dir, "speed": rules.bullet_speed, "left": rules.bullet_range, "exclude": exclude,
		"shooter": shooter})


func ray(from: Vector2, to: Vector2, exclude: Array[RID], mask: int = MASK) -> Dictionary:
	var q := PhysicsRayQueryParameters2D.create(from, to, mask, exclude)
	q.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(q)


func _physics_process(delta: float) -> void:
	var still: Array = []
	for b in bullets:
		var travel := minf(b.speed * delta, b.left)
		var to: Vector2 = b.pos + b.dir * travel
		var hit := ray(b.pos, to, b.exclude)
		if not hit.is_empty():
			_hit(hit, b.dir, b.get("shooter"))
			continue
		b.pos = to
		b.left -= travel
		if b.left <= 0.0:
			spent.emit(b.pos)
			continue
		still.append(b)
	bullets = still


func _hit(hit: Dictionary, dir: Vector2, shooter: Node = null) -> void:
	var collider: Object = hit.collider
	var who: Node = shooter if is_instance_valid(shooter) else null
	if collider != null and collider.has_method("hit_by_bullet"):
		collider.hit_by_bullet(hit.position, dir, who)
	impact.emit(hit.position, hit.normal, collider, dir)
	struck.emit(collider, hit.position, dir, who)
