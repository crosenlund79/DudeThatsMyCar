class_name Walker
extends CharacterBody2D
## A person on foot (the player, the police officer): WalkerModel movement,
## collides with the world and with cars, faces the aim point, plays the walk
## cycle from a character sheet (frame 0 idle, frames 1-4 walking). Armed
## people switch to their armed sheet and show the pistol while it is drawn.

const RADIUS := 9.0
## World px walked per animation frame (frames 1-4: a step every two frames).
## M006: was 9 px, which at the walking pace of 108 px/s gave about six steps
## a second - feet running while he walks. 24 px gives about 2.25 steps a
## second at that pace, a walking cadence, and stays proportional to speed
## (the officer's run steps faster).
const STRIDE := 24.0

## A bullet struck this person (position, direction of travel).
signal shot_at(at: Vector2, direction: Vector2)
## M006: the round left a wound (region, BodyCondition.Level) - and a fatal one.
signal hurt(region: String, level: int)
signal struck_down

var model := WalkerModel.new()
## Command for this tick (set by the player controller or tests).
var move := Vector2.ZERO
var aim_point := Vector2.ZERO
var active := true
## False when something else poses the sprite (the Bird performing).
var animate := true
var sprite: Sprite2D
## The sprite's scale for its display size.
var base_scale := Vector2.ONE
## The handgun (null: unarmed), its rules and how it looks.
var gun: Gun = null
var pistol: Sprite2D
var _sheet: Texture2D
var _armed_sheet: Texture2D
var _walked := 0.0
## M006: where this person is hurt, who shot them last, and whether a fatal
## wound lays them down (false for Danny: the game decides what happens to him).
var condition := BodyCondition.new()
var last_shooter: Node = null
var falls := true
var down := false
var rng := RandomNumberGenerator.new()
var _stain: Sprite2D
var _layer := 0


## options: "glow" (bool, a faint light round the person, default true),
## "armed_sheet" (logical name of the sheet drawn while the gun is out),
## "gun" (GunRules).
static func create(resolver: AssetResolver, logical: String = "characters/gangster", options: Dictionary = {}) -> Walker:
	var w := Walker.new()
	w.name = "Walker"
	w.collision_layer = Layers.PEOPLE
	w.collision_mask = Layers.WORLD | Layers.CARS
	w.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	w.z_index = Layers.Z_ACTOR + 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	w.add_child(shape)
	var shadow := Sprite2D.new()
	shadow.texture = SoftShadow.texture()
	# M010: a little longer than wide, cast the way every shadow falls (Shadows.DIR)
	shadow.scale = Vector2(42, 28) / Vector2(shadow.texture.get_size())
	shadow.rotation = Shadows.DIR.angle()
	shadow.position = Shadows.DIR * 6.0
	shadow.modulate = Color(1, 1, 1, 0.85)
	w.add_child(shadow)
	w.sprite = Sprite2D.new()
	w.sprite.name = "Sprite"
	var tex := resolver.get_texture(logical)
	var frames: int = AssetCatalog.SPECS[logical].frames
	w.sprite.texture = tex
	w.sprite.hframes = frames
	w.sprite.scale = AssetCatalog.scale_for(tex, AssetCatalog.display_size(logical) * Vector2(frames, 1))
	w.base_scale = w.sprite.scale
	w.add_child(w.sprite)
	w._sheet = tex
	if options.has("armed_sheet"):
		w._armed_sheet = resolver.get_texture(options.armed_sheet)
	if options.has("gun"):
		w.gun = Gun.new(options.gun)
		w.pistol = Sprite2D.new()
		w.pistol.name = "Pistol"
		w.pistol.texture = resolver.get_texture("weapons/pistol")
		w.pistol.scale = AssetCatalog.scale_for(w.pistol.texture, AssetCatalog.display_size("weapons/pistol"))
		w.pistol.visible = false
		w.add_child(w.pistol)
	if options.get("glow", true):
		# a faint glow round the player so he reads in the dark
		var glow := PointLight2D.new()
		glow.texture = LightTextures.radial()
		glow.texture_scale = 180.0 / 256.0
		glow.color = Color(0.95, 0.88, 0.75)
		glow.energy = 0.55
		glow.range_item_cull_mask = Layers.LIGHT_STREET
		w.add_child(glow)
	return w


## Where the bullet leaves the gun, in the world.
func muzzle_position() -> Vector2:
	return global_position + gun.rules.muzzle_offset.rotated(model.facing)


func hit_by_bullet(at: Vector2, direction: Vector2, shooter: Node = null) -> void:
	if not down:
		last_shooter = shooter  # M008: known to whoever hears about the shot below
	shot_at.emit(at, direction)
	if down:
		return
	var right := Vector2.from_angle(model.facing + PI * 0.5)
	var region := BodyCondition.region_for((at - global_position).dot(right), rng.randf())
	condition.shoot(region, rng.randf())
	_flash()
	hurt.emit(region, condition.level(region))
	if condition.is_fatal():
		down = true
		struck_down.emit()
		if falls:
			lie_down()


## A brief red flush where the round went in (no gore).
func _flash() -> void:
	if sprite == null:
		return
	sprite.modulate = Color(1.7, 0.55, 0.5)
	var t := create_tween()
	t.tween_property(sprite, "modulate", Color(0.6, 0.56, 0.54) if down else Color.WHITE, 0.3)


## Struck down: they fall where they stood and lie still - turned on their
## side, darker, a dark patch on the ground beneath (no gore) - no longer in
## the way of bullets, people or cars.
func lie_down() -> void:
	down = true
	active = false
	velocity = Vector2.ZERO
	move = Vector2.ZERO
	if _layer == 0:
		_layer = collision_layer
	collision_layer = 0
	sprite.frame = 0
	sprite.rotation = model.facing + PI * 0.5
	sprite.scale = base_scale * Vector2(1.4, 0.78)
	sprite.position = Vector2.from_angle(model.facing) * -5.0
	sprite.modulate = Color(0.6, 0.56, 0.54)
	if pistol != null:
		pistol.visible = false
	if _stain == null:
		_stain = Sprite2D.new()
		_stain.name = "Stain"
		_stain.texture = SoftShadow.texture()
		_stain.modulate = Color(0.16, 0.02, 0.02, 1.0)
		_stain.z_as_relative = false
		_stain.z_index = Layers.Z_REFLECTION + 1  # above the lamps' light pools, under people
		add_child(_stain)
		move_child(_stain, 0)
	_stain.scale = Vector2(74, 50) / Vector2(_stain.texture.get_size())
	_stain.rotation = model.facing + PI * 0.5
	_stain.position = Vector2.from_angle(model.facing) * 9.0 + Vector2(2, 3)
	_stain.visible = true


## Up again, unhurt (a new night).
func revive() -> void:
	condition.heal_all()
	down = false
	active = true
	if _layer != 0:
		collision_layer = _layer
	sprite.scale = base_scale
	sprite.position = Vector2.ZERO
	sprite.modulate = Color.WHITE
	sprite.rotation = model.facing
	if _stain != null:
		_stain.visible = false
	last_shooter = null


## M010: takes another gun in hand (the one he had goes back under the coat):
## its sprite, its muzzle, its rounds.
func equip(p_gun: Gun, look: Texture2D) -> void:
	if gun != null and gun != p_gun:
		gun.holster()
	gun = p_gun
	if pistol != null:
		pistol.texture = look
		pistol.scale = AssetCatalog.scale_for(look, AssetCatalog.display_size(p_gun.rules.look))


## Shows the drawn pistol (or puts it away) to match the gun.
func _pose() -> void:
	var drawn := gun != null and gun.is_drawn()
	if _armed_sheet != null:
		sprite.texture = _armed_sheet if drawn else _sheet
	if pistol != null:
		pistol.visible = drawn
		var size := AssetCatalog.display_size(gun.rules.look)
		pistol.position = (gun.rules.hand_offset + Vector2(size.x * 0.4, 0)).rotated(model.facing)
		pistol.rotation = model.facing


func place(p: Vector2, facing: float) -> void:
	global_position = p
	model.velocity = Vector2.ZERO
	model.facing = facing
	sprite.rotation = facing
	move = Vector2.ZERO
	_walked = 0.0
	sprite.frame = 0
	if sprite.texture != null:
		_pose()


func _physics_process(delta: float) -> void:
	if not active:
		return
	model.aim_at(global_position, aim_point)
	velocity = model.update(delta, move * condition.speed_factor())
	var before := global_position
	move_and_slide()
	model.velocity = velocity
	if not animate:
		return
	sprite.rotation = model.facing
	_pose()
	var moved := global_position.distance_to(before)
	if model.speed() > 8.0:
		_walked += moved
		# M010: running, the stride is longer (the steps still keep pace with the ground covered)
		var stride := STRIDE * (1.45 if model.running else 1.0)
		sprite.frame = 1 + int(_walked / stride) % (sprite.hframes - 1)
	else:
		_walked = 0.0
		sprite.frame = 0
