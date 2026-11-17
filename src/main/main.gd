extends Node2D
## Composition root: builds the district, parks the cars, puts the player on
## the street at night and wires the modules together through explicit calls
## and signals. No Autoloads. Tests run this scene with a scripted command
## source instead of the keyboard and mouse.

const CAR_SCENE := preload("res://src/driving/car.tscn")
const VEHICLES := {
	"sedan": preload("res://src/driving/vehicles/sedan.tres"),
	"coupe": preload("res://src/driving/vehicles/coupe.tres"),
}

## Optional command source for tests: func(controller) -> PlayerCommand.
var command_source: Callable
## Override folder for replaceable art (tests); "" = the normal custom/ folder.
var override_root := ""

var resolver: AssetResolver
var settings: AudioSettings
var layout: DistrictLayout
var city: City
var cars: Array[Car] = []
var walker: Walker
var player: PlayerController
var camera: CityCamera
var hud: Hud
var vehicle_audio: VehicleAudio
var bullets: BulletWorld
var gunfire: GunfireView
var navigator: CityNavigator
var officer: PoliceOfficer
@export var police_rules: PoliceRules = preload("res://src/police/default_police.tres")
## The player's handgun.
@export var gun_rules: GunRules = preload("res://src/weapons/default_pistol.tres")
var paused := false


func _ready() -> void:
	CityInput.ensure_actions()
	settings = AudioSettings.new()
	settings.load_settings()
	settings.apply()
	resolver = AssetResolver.new(override_root)
	layout = RiversideWard.create()
	city = City.new()
	city.name = "City"
	add_child(city)
	city.build(layout, resolver)
	_park_cars()
	walker = Walker.create(resolver, "characters/gangster", {"armed_sheet": "characters/gangster_armed", "gun": gun_rules})
	add_child(walker)
	walker.place(layout.spawn, layout.spawn_facing)
	walker.aim_point = layout.spawn + Vector2.from_angle(layout.spawn_facing) * 60.0
	camera = CityCamera.new()
	camera.name = "Camera"
	add_child(camera)
	camera.set_bounds(layout.bounds)
	camera.snap_to(walker)
	camera.make_current()
	player = PlayerController.new()
	player.name = "Player"
	player.command_source = command_source
	add_child(player)
	player.setup(walker, cars, city)
	bullets = BulletWorld.new()
	bullets.name = "Bullets"
	add_child(bullets)
	player.bullets = bullets
	gunfire = GunfireView.new()
	add_child(gunfire)
	gunfire.setup(resolver, bullets)
	player.fired.connect(gunfire.on_fired)
	player.gun_event.connect(gunfire.on_gun_event)
	bullets.impact.connect(gunfire.on_impact)
	navigator = CityNavigator.new(layout, Walker.RADIUS + 3.0)
	officer = PoliceOfficer.new()
	add_child(officer)
	officer.setup(resolver, police_rules, layout.police_beat, navigator, player.body)
	player.fired.connect(func(muzzle: Vector2, _dir: Vector2) -> void: officer.hear_gunshot(muzzle, gun_rules.noise_radius))
	vehicle_audio = VehicleAudio.new()
	add_child(vehicle_audio)
	vehicle_audio.setup(resolver)
	hud = Hud.new()
	add_child(hud)
	hud.setup(resolver, layout.name)
	player.entered_car.connect(_on_entered_car)
	player.exited_car.connect(_on_exited_car)
	player.notice.connect(hud.show_notice)
	officer.state_changed.connect(hud.set_police_status)
	officer.gave_up.connect(func() -> void: hud.show_notice("You lost him."))
	# Esc must still work while the world is paused: the root always runs,
	# the world itself stops.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for node in [city, walker, camera, player, vehicle_audio, bullets, gunfire, officer] + cars:
		(node as Node).process_mode = Node.PROCESS_MODE_PAUSABLE
	if not command_source.is_valid():
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_update_view(0.0)


func _park_cars() -> void:
	var glow := resolver.get_texture("fx/glow")
	for spec in layout.cars:
		var vehicle: VehicleType = VEHICLES[spec.type]
		var c: Car = CAR_SCENE.instantiate()
		c.position = spec.pos
		c.rotation = spec.rot
		c.z_index = Layers.Z_ACTOR
		add_child(c)
		var paint: String = vehicle.paints[int(spec.paint) % vehicle.paints.size()]
		c.setup(vehicle, resolver.get_texture(paint), paint)
		var lights := VehicleLights.new()
		lights.setup(c, glow)
		cars.append(c)


func _on_entered_car(c: Car) -> void:
	camera.target = c
	(c.get_node("Lights") as VehicleLights).set_on(true)
	vehicle_audio.attach(c)


func _on_exited_car(c: Car) -> void:
	camera.target = walker
	(c.get_node("Lights") as VehicleLights).set_on(false)
	vehicle_audio.attach(null)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(CityInput.MENU):
		paused = not paused
		get_tree().paused = paused
		hud.set_paused(paused)
	elif event.is_action_pressed(CityInput.QUIT) and paused:
		get_tree().quit()
	elif event.is_action_pressed(CityInput.HELP):
		hud.toggle_help()


func _process(delta: float) -> void:
	_update_view(delta)


func _update_view(delta: float) -> void:
	camera.update_camera(delta)
	city.update_view(camera.eye(), camera.eye_height(), camera.view_rect())
	var prompt := ""
	if player.on_foot():
		var c := player.enterable_car()
		if c != null:
			prompt = "E   Get in the %s" % c.vehicle.params.display_name
	elif player.car.speed() < 30.0:
		prompt = "E   Get out"
	var focus := player.body().global_position
	hud.refresh(delta, layout.place_name(focus), prompt, player.car, get_viewport().get_mouse_position(),
		player.on_foot() and not paused)
	hud.show_gun(walker.gun if player.on_foot() else null)
