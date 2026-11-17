class_name Walker
extends CharacterBody2D
## A person on foot (the player, the police officer): WalkerModel movement,
## collides with the world and with cars, faces the aim point, plays the walk
## cycle from a character sheet (frame 0 idle, frames 1-4 walking). Armed
## people switch to their armed sheet and show the pistol while it is drawn.

const RADIUS := 9.0
## World px walked per animation frame.
const STRIDE := 9.0

## A bullet struck this person (position, direction of travel).
signal shot_at(at: Vector2, direction: Vector2)

var model := WalkerModel.new()
## Command for this tick (set by the player controller or tests).
var move := Vector2.ZERO
var aim_point := Vector2.ZERO
var active := true
var sprite: Sprite2D
## The handgun (null: unarmed), its rules and how it looks.
var gun: Gun = null
var pistol: Sprite2D
var _sheet: Texture2D
var _armed_sheet: Texture2D
var _walked := 0.0


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
	shadow.scale = Vector2(36, 36) / Vector2(shadow.texture.get_size())
	shadow.position = Vector2(2, 3)
	shadow.modulate = Color(1, 1, 1, 0.8)
	w.add_child(shadow)
	w.sprite = Sprite2D.new()
	w.sprite.name = "Sprite"
	var tex := resolver.get_texture(logical)
	var frames: int = AssetCatalog.SPECS[logical].frames
	w.sprite.texture = tex
	w.sprite.hframes = frames
	w.sprite.scale = AssetCatalog.scale_for(tex, AssetCatalog.display_size(logical) * Vector2(frames, 1))
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


func hit_by_bullet(at: Vector2, direction: Vector2) -> void:
	shot_at.emit(at, direction)


## Shows the drawn pistol (or puts it away) to match the gun.
func _pose() -> void:
	var drawn := gun != null and gun.is_drawn()
	if _armed_sheet != null:
		sprite.texture = _armed_sheet if drawn else _sheet
	if pistol != null:
		pistol.visible = drawn
		var size := AssetCatalog.display_size("weapons/pistol")
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
	velocity = model.update(delta, move)
	var before := global_position
	move_and_slide()
	model.velocity = velocity
	sprite.rotation = model.facing
	_pose()
	var moved := global_position.distance_to(before)
	if model.speed() > 8.0:
		_walked += moved
		sprite.frame = 1 + int(_walked / STRIDE) % (sprite.hframes - 1)
	else:
		_walked = 0.0
		sprite.frame = 0
