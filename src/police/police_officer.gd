class_name PoliceOfficer
extends Node2D
## The beat cop in the street: a Walker body in uniform, moved by an
## OfficerBrain. Every tick he looks for the player (within sight range and a
## clear line of sight past the buildings), asks his brain what to do and walks
## or runs there along a CityNavigator route, sliding round parked cars and
## sidestepping when stuck. He carries a torch, shows "!" over his cap when he
## has noticed you and "?" while he searches, and blows his whistle.
## M008: he carries a revolver. Once he has seen you shoot somebody (or been
## shot at by you) he draws it in a chase and fires through the BulletWorld
## when he has you in sight with nothing in the way - never through a
## building, never faster than his cadence.

signal noticed_player
signal gave_up
signal state_changed(state: int)
## M008: a round from his revolver (for the flash, the sound and who hears it).
signal fired(muzzle: Vector2, direction: Vector2)
## M008: he has drawn on you (once per draw).
signal drew_gun

const TORCH_RANGE := 260.0
## The badge floats this far above him on screen.
const ICON_LIFT := 34.0

var rules: PoliceRules
var brain: OfficerBrain
var body: Walker
var navigator: CityNavigator
## Returns the node the player currently is (on foot or the car he drives).
var target_source: Callable
var torch: PointLight2D
var icon: Sprite2D
var whistle: AudioStreamPlayer2D
var _icons := {}
var _icon_kind := ""
var _icon_pop := 0.0
var _walker: RouteFollower
var _last_state := -1
## M008: the bullets his revolver fires into, and Danny on foot (whose rounds count as yours).
var bullets: BulletWorld
var player_walker: Node
var _drawn := false
## M008: his district's ground. Across its border he does not follow (his
## beat ends there): he watches from the edge and then gives up as usual.
var home_area := Rect2()


const REVOLVER := preload("res://src/police/police_revolver.tres")


func setup(resolver: AssetResolver, p_rules: PoliceRules, beat: PackedVector2Array, p_navigator: CityNavigator,
		p_target_source: Callable, p_bullets: BulletWorld = null, revolver: GunRules = REVOLVER) -> void:
	rules = p_rules
	navigator = p_navigator
	target_source = p_target_source
	bullets = p_bullets
	name = "PoliceOfficer"
	brain = OfficerBrain.new(rules, beat)
	body = Walker.create(resolver, "characters/police", {"glow": true, "armed_sheet": "characters/police_armed", "gun": revolver})
	body.name = "Body"
	add_child(body)
	body.place(beat[0] if not beat.is_empty() else Vector2.ZERO, PI * 0.5)
	body.model.walk_speed = rules.patrol_speed
	body.shot_at.connect(func(at: Vector2, direction: Vector2) -> void:
		brain.shot_at(at - direction * 240.0, player_walker != null and body.last_shooter == player_walker))
	torch = PointLight2D.new()
	torch.texture = VehicleLights.cone_texture()
	torch.texture_scale = TORCH_RANGE * 2.0 / 256.0
	torch.color = Color(1.0, 0.93, 0.74)
	torch.energy = 1.3
	torch.range_item_cull_mask = Layers.LIGHT_STREET
	body.add_child(torch)
	for kind in ["alert", "search"]:
		_icons[kind] = resolver.get_texture("ui/" + kind)
	icon = Sprite2D.new()
	icon.z_index = Layers.Z_MIST + 2
	icon.z_as_relative = false
	icon.visible = false
	add_child(icon)
	whistle = AudioStreamPlayer2D.new()
	whistle.stream = resolver.get_audio("police/whistle")
	whistle.bus = "Effects" if AudioServer.get_bus_index("Effects") >= 0 else "Master"
	whistle.max_distance = 2400.0
	body.add_child(whistle)
	_walker = RouteFollower.new(navigator)
	_walker.reset(body.global_position)
	body.rng.seed = 1932002
	body.struck_down.connect(_on_struck_down)


## Back on his beat at the start of a night: patrolling, nothing on his mind.
## M006: if he was shot dead last night, this is the new man on the beat.
func reset() -> void:
	brain = OfficerBrain.new(rules, brain.beat)
	body.revive()
	body.gun.holster()
	_drawn = false
	torch.visible = true
	body.place(brain.beat[0] if not brain.beat.is_empty() else body.global_position, PI * 0.5)
	body.model.walk_speed = rules.patrol_speed
	_walker.reset(body.global_position)
	_set_icon("")
	_last_state = brain.state
	state_changed.emit(brain.state)


## The player fired at `at`; the shot carries `loudness` px.
func hear_gunshot(at: Vector2, loudness: float) -> bool:
	if body.down:
		return false
	return brain.hear_gunshot(body.global_position, at, loudness)


## M006: someone breaks into a car at `car`. If he could see it (close
## enough, no building between) he investigates; returns whether he saw it.
func witness_theft(car: Vector2) -> bool:
	if body.down:
		return false
	var me := body.global_position
	var q := PhysicsRayQueryParameters2D.create(me, car, Layers.WORLD)
	var clear := body.get_world_2d().direct_space_state.intersect_ray(q).is_empty()
	if not CarThefts.witnessed(me, car, clear):
		return false
	brain.witness_theft(car)
	return true


## M008: Danny shot `victim` (Danny at `shooter`). If he could see it - the
## victim or the shooter in his sight - he draws and comes after Danny.
## Returns whether he saw it.
func witness_violence(victim: Vector2, shooter: Vector2) -> bool:
	if body.down:
		return false
	if not (can_see(victim) or can_see(shooter)):
		return false
	brain.witness_violence(shooter)
	return true


## M008: Danny fired from `muzzle` along `direction` and the round passed close by him.
func near_miss(muzzle: Vector2, direction: Vector2) -> bool:
	if body.down or not Marksman.passes_near(body.global_position, muzzle, direction):
		return false
	brain.shot_at(muzzle, true)
	return true


## M008: Danny is down (or the night is over for this fight): he stops shooting and walks back.
func stand_down() -> void:
	brain.stand_down()
	body.gun.holster()
	_drawn = false


func is_armed() -> bool:
	return brain.armed and not body.down


## M008: nothing but Danny in the line from the revolver to him (no building,
## no car, no other person).
func clear_shot(t: Node2D) -> bool:
	var me := body.global_position
	var q := PhysicsRayQueryParameters2D.create(me, t.global_position, Layers.WORLD | Layers.CARS | Layers.PEOPLE,
		[body.get_rid()])
	var hit := body.get_world_2d().direct_space_state.intersect_ray(q)
	return hit.is_empty() or hit.collider == t


## M006: shot down, he lies where he fell; his torch goes out.
func _on_struck_down() -> void:
	torch.visible = false
	_set_icon("")
	brain.state = OfficerBrain.State.PATROL
	state_changed.emit(brain.state)


func is_down() -> bool:
	return body.down


## He sees `p` when it is within sight range and no building stands between.
func can_see(p: Vector2) -> bool:
	var me := body.global_position
	if me.distance_to(p) > rules.sight_range:
		return false
	var q := PhysicsRayQueryParameters2D.create(me, p, Layers.WORLD)
	return body.get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _target() -> Node2D:
	return target_source.call() if target_source.is_valid() else null


static func velocity_of(n: Node2D) -> Vector2:
	if n is Car and (n as Car).model != null:
		return (n as Car).model.velocity
	if n is CharacterBody2D:
		return (n as CharacterBody2D).velocity
	return Vector2.ZERO


func _physics_process(_delta: float) -> void:
	if body.down:
		return
	var dt := Car.FIXED_STEP
	var me := body.global_position
	var t := _target()
	var player := t.global_position if t != null else me
	var sees := t != null and brain.is_hunting() and can_see(player)
	if sees and home_area.has_area() and not home_area.grow(200.0).has_point(player):
		sees = false  # M008: off his district's ground: he lets it go at the edge
	var clear := sees and brain.armed and clear_shot(t)
	var out := brain.update(dt, me, sees, player, velocity_of(t) if t != null else Vector2.ZERO, clear)
	if brain.noticed_now:
		_icon_pop = 0.3
		if whistle.stream != null:
			whistle.play()
		noticed_player.emit()
	if brain.gave_up_now:
		gave_up.emit()
	if brain.state != _last_state:
		_last_state = brain.state
		state_changed.emit(brain.state)
	_walk_to(out.target, out.speed, dt)
	body.aim_point = out.look
	_set_icon(out.icon)
	_handle_gun(out, player, dt)


## M008: the revolver - out while he is after an armed man, fired when his
## brain says so; put away when he gives up.
func _handle_gun(out: Dictionary, player: Vector2, dt: float) -> void:
	var gun := body.gun
	if out.draw:
		if not gun.is_drawn():
			gun.draw()
		if not _drawn:
			_drawn = true
			drew_gun.emit()
		if out.fire:
			gun.trigger()
	elif gun.is_drawn():
		gun.holster()
		_drawn = false
	for e in gun.step(dt):
		if e == "fired" and bullets != null:
			var muzzle := body.muzzle_position()
			var dir := (player - muzzle).normalized()
			bullets.fire(body.global_position, muzzle, dir, gun.rules, [body.get_rid()], body.condition.aim_spread(), body)
			fired.emit(muzzle, dir)


func _walk_to(goal: Vector2, speed: float, dt: float) -> void:
	_walker.step(body, goal, speed, dt)


func _set_icon(kind: String) -> void:
	if kind != _icon_kind:
		_icon_kind = kind
		if kind != "":
			icon.texture = _icons[kind]
			_icon_pop = maxf(_icon_pop, 0.2)
	icon.visible = kind != ""


func _process(delta: float) -> void:
	torch.rotation = body.sprite.rotation
	if icon.visible:
		_icon_pop = maxf(0.0, _icon_pop - delta)
		var size := AssetCatalog.display_size("ui/" + _icon_kind)
		var pop := 1.0 + _icon_pop * 2.0
		icon.scale = AssetCatalog.scale_for(icon.texture, size) * pop
		icon.global_position = body.global_position + Vector2(0, -ICON_LIFT)
