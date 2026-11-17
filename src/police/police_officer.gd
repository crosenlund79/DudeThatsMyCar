class_name PoliceOfficer
extends Node2D
## The beat cop in the street: a Walker body in uniform, moved by an
## OfficerBrain. Every tick he looks for the player (within sight range and a
## clear line of sight past the buildings), asks his brain what to do and walks
## or runs there along a CityNavigator route, sliding round parked cars and
## sidestepping when stuck. He carries a torch, shows "!" over his cap when he
## has noticed you and "?" while he searches, and blows his whistle.

signal noticed_player
signal gave_up
signal state_changed(state: int)

## Seconds between route updates while moving.
const REPATH := 0.45
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
var _route := PackedVector2Array()
var _route_goal := Vector2.INF
var _repath := 0.0
var _stuck := 0.0
var _last_pos := Vector2.ZERO
var _sidestep := 0.0
var _sidestep_dir := Vector2.ZERO
var _sidestep_sign := 1.0
var _last_state := -1


func setup(resolver: AssetResolver, p_rules: PoliceRules, beat: PackedVector2Array, p_navigator: CityNavigator,
		p_target_source: Callable) -> void:
	rules = p_rules
	navigator = p_navigator
	target_source = p_target_source
	name = "PoliceOfficer"
	brain = OfficerBrain.new(rules, beat)
	body = Walker.create(resolver, "characters/police", {"glow": true})
	body.name = "Body"
	add_child(body)
	body.place(beat[0] if not beat.is_empty() else Vector2.ZERO, PI * 0.5)
	body.model.walk_speed = rules.patrol_speed
	body.shot_at.connect(func(at: Vector2, direction: Vector2) -> void: brain.shot_at(at - direction * 240.0))
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
	_last_pos = body.global_position


## Back on his beat at the start of a night: patrolling, nothing on his mind.
func reset() -> void:
	brain = OfficerBrain.new(rules, brain.beat)
	body.place(brain.beat[0] if not brain.beat.is_empty() else body.global_position, PI * 0.5)
	body.model.walk_speed = rules.patrol_speed
	_route = PackedVector2Array()
	_route_goal = Vector2.INF
	_stuck = 0.0
	_sidestep = 0.0
	_last_pos = body.global_position
	_set_icon("")
	_last_state = brain.state
	state_changed.emit(brain.state)


## The player fired at `at`; the shot carries `loudness` px.
func hear_gunshot(at: Vector2, loudness: float) -> bool:
	return brain.hear_gunshot(body.global_position, at, loudness)


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
	var dt := Car.FIXED_STEP
	var me := body.global_position
	var t := _target()
	var player := t.global_position if t != null else me
	var sees := t != null and brain.is_hunting() and can_see(player)
	var out := brain.update(dt, me, sees, player, velocity_of(t) if t != null else Vector2.ZERO)
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


func _walk_to(goal: Vector2, speed: float, dt: float) -> void:
	var me := body.global_position
	if speed <= 0.0 or me.distance_to(goal) < 6.0:
		body.move = Vector2.ZERO
		_stuck = 0.0
		_last_pos = me
		return
	body.model.walk_speed = speed
	_repath -= dt
	if _repath <= 0.0 or _route.is_empty() or goal.distance_to(_route_goal) > 40.0:
		_route = navigator.route(me, goal)
		_route_goal = goal
		_repath = REPATH
	while _route.size() > 1 and me.distance_to(_route[0]) < 14.0:
		_route.remove_at(0)
	var next: Vector2 = _route[0] if not _route.is_empty() else goal
	var dir := (next - me).normalized()
	if _sidestep > 0.0:
		_sidestep -= dt
		dir = (_sidestep_dir + dir * 0.35).normalized()
	elif me.distance_to(_last_pos) < speed * dt * 0.25:
		_stuck += dt
		if _stuck > 0.5:  # blocked (a parked car, a lamp post): step aside and try again
			_sidestep = 0.45
			_sidestep_sign = -_sidestep_sign
			_sidestep_dir = dir.orthogonal() * _sidestep_sign
			_stuck = 0.0
			_repath = 0.0
	else:
		_stuck = 0.0
	_last_pos = me
	body.move = dir


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
