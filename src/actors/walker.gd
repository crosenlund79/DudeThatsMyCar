class_name Walker
extends CharacterBody2D
## A person on foot (the player): WalkerModel movement, collides with the
## world and with cars, faces the aim point, plays the walk cycle from the
## character sheet (frame 0 idle, frames 1-4 walking).

const RADIUS := 9.0
## World px walked per animation frame.
const STRIDE := 9.0

var model := WalkerModel.new()
## Command for this tick (set by the player controller or tests).
var move := Vector2.ZERO
var aim_point := Vector2.ZERO
var active := true
var sprite: Sprite2D
var _walked := 0.0


static func create(resolver: AssetResolver, logical: String = "characters/gangster") -> Walker:
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
	# a faint glow round the player so he reads in the dark
	var glow := PointLight2D.new()
	glow.texture = LightTextures.radial()
	glow.texture_scale = 180.0 / 256.0
	glow.color = Color(0.95, 0.88, 0.75)
	glow.energy = 0.55
	glow.range_item_cull_mask = Layers.LIGHT_STREET
	w.add_child(glow)
	return w


func place(p: Vector2, facing: float) -> void:
	global_position = p
	model.velocity = Vector2.ZERO
	model.facing = facing
	sprite.rotation = facing
	move = Vector2.ZERO
	_walked = 0.0
	sprite.frame = 0


func _physics_process(delta: float) -> void:
	if not active:
		return
	model.aim_at(global_position, aim_point)
	velocity = model.update(delta, move)
	var before := global_position
	move_and_slide()
	model.velocity = velocity
	sprite.rotation = model.facing
	var moved := global_position.distance_to(before)
	if model.speed() > 8.0:
		_walked += moved
		sprite.frame = 1 + int(_walked / STRIDE) % (sprite.hframes - 1)
	else:
		_walked = 0.0
		sprite.frame = 0
