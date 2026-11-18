extends Node2D
## Composition root: builds the district, parks the cars, puts the player on
## the street at night and wires the modules together through explicit calls
## and signals. No Autoloads. Tests run this scene with a scripted command
## source instead of the keyboard and mouse.

const CAR_SCENE := preload("res://src/driving/car.tscn")
const VEHICLES := {
	"sedan": preload("res://src/driving/vehicles/sedan.tres"),
	"coupe": preload("res://src/driving/vehicles/coupe.tres"),
	"police": preload("res://src/driving/vehicles/police.tres"),
}

## Optional command source for tests: func(controller) -> PlayerCommand.
var command_source: Callable
## Override folder for replaceable art (tests); "" = the normal custom/ folder.
var override_root := ""
## Where progress is saved ("" = never; tests and screenshots).
var save_path := SaveGame.DEFAULT_PATH
## Whether a new game (no saved game) begins with Danny's monologue over the
## ward (tests switch it off).
var opening_enabled := true
## Where the sound levels are kept ("" = never saved; tests and screenshots).
var settings_path := AudioSettings.DEFAULT_PATH

var resolver: AssetResolver
var settings: AudioSettings
var layout: DistrictLayout
var city: City
var interiors: Interiors
var markers: PlaceMarkers
var cars: Array[Car] = []
var walker: Walker
var player: PlayerController
var camera: CityCamera
var hud: Hud
var vehicle_audio: VehicleAudio
var soundscape: Soundscape
## The opening narration while it runs (null otherwise).
var opening: Opening
var _follow_rate := 7.0
var bullets: BulletWorld
var gunfire: GunfireView
var navigator: CityNavigator
var officer: PoliceOfficer
var street: StreetLife
@export var police_rules: PoliceRules = preload("res://src/police/default_police.tres")
## The player's handgun.
@export var gun_rules: GunRules = preload("res://src/weapons/default_pistol.tres")
## Prices and nightly limits of the bootleg trade and the protection racket.
@export var economy_rules: EconomyRules = preload("res://src/economy/default_economy.tres")
## The hours of the night (start, time to go home, dawn) and how fast it runs.
@export var night_rules: NightRules = preload("res://src/night/default_night.tres")
var clock: NightClock
## Reminders given tonight: 0 none, 1 "get home", 2 "dawn".
var _warned := 0
var paused := false
## The sound level chosen on the pause screen (index into AudioSettings.BUSES).
var sound_row := 0
var rackets: Rackets
var talk: Conversations
## Who the player is talking to ("" = nobody) and the page on screen.
var talking := ""
var _page := {}
## A shopkeeper going for the police (see _update_report).
const REPORT_DELAY := 6.0
const REPORT_RADIUS := 900.0
var _report_from: InteriorPlan = null
var _report_left := 0.0
var _report_who := ""
var _saved := {}


func _ready() -> void:
	CityInput.ensure_actions()
	settings = AudioSettings.new(settings_path)
	settings.load_settings()
	settings.apply()
	resolver = AssetResolver.new(override_root)
	rackets = Rackets.new(economy_rules)
	clock = NightClock.new(night_rules)
	rackets.town.night_minutes = float(night_rules.dawn_minute - night_rules.start_minute)
	talk = Conversations.new(rackets)
	_load_game()
	layout = RiversideWard.create()
	city = City.new()
	city.name = "City"
	add_child(city)
	city.build(layout, resolver)
	interiors = Interiors.new()
	add_child(interiors)
	interiors.build(layout, city, resolver)
	markers = PlaceMarkers.new()
	add_child(markers)
	markers.setup(layout, resolver)
	_park_cars()
	walker = Walker.create(resolver, "characters/gangster", {"armed_sheet": "characters/gangster_armed", "gun": gun_rules})
	add_child(walker)
	walker.place(layout.spawn, layout.spawn_facing)
	_load_gun()
	interiors.update_player(walker.global_position)
	interiors.snap()
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
	for v in interiors.views:
		v.visitors = [walker]
	bullets = BulletWorld.new()
	bullets.name = "Bullets"
	add_child(bullets)
	player.bullets = bullets
	gunfire = GunfireView.new()
	add_child(gunfire)
	gunfire.setup(resolver, bullets)
	player.fired.connect(gunfire.on_fired)
	player.gun_event.connect(gunfire.on_gun_event)
	player.gun_event.connect(func(e: String, _at: Vector2) -> void:
		if e == "empty":
			hud.show_notice("Click. Out of rounds. Eddie sells them, in the back of Lindqvist Hardware."))
	bullets.impact.connect(gunfire.on_impact)
	navigator = CityNavigator.new(layout, Walker.RADIUS + 3.0)
	officer = PoliceOfficer.new()
	add_child(officer)
	officer.setup(resolver, police_rules, layout.police_beat, navigator, player.body)
	player.fired.connect(func(muzzle: Vector2, _dir: Vector2) -> void: officer.hear_gunshot(muzzle, gun_rules.noise_radius))
	street = StreetLife.new()
	add_child(street)
	street.setup(layout, resolver, clock, CAR_SCENE, VEHICLES, cars, [walker, officer.body] as Array[Walker])
	street.view = camera.view_rect()
	player.fired.connect(func(muzzle: Vector2, _dir: Vector2) -> void: street.hear_gunshot(muzzle))
	vehicle_audio = VehicleAudio.new()
	add_child(vehicle_audio)
	vehicle_audio.setup(resolver)
	soundscape = Soundscape.new()
	add_child(soundscape)
	soundscape.setup(resolver, layout, _plan("copper_owl"))
	soundscape.track_traffic(street.traffic)
	hud = Hud.new()
	add_child(hud)
	hud.setup(resolver, layout.name)
	hud.add_minimap(layout)
	player.interaction = _interact
	player.conversation = _converse
	hud.dialogue_choice.connect(_answer)
	hud.set_purse(rackets.money, rackets.bottles, rackets.held)
	player.entered_car.connect(_on_entered_car)
	player.exited_car.connect(_on_exited_car)
	player.notice.connect(hud.show_notice)
	officer.state_changed.connect(hud.set_police_status)
	officer.gave_up.connect(func() -> void: hud.show_notice("You lost him."))
	# Esc must still work while the world is paused: the root always runs,
	# the world itself stops.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for node in [city, interiors, walker, camera, player, vehicle_audio, soundscape, bullets, gunfire, officer, street] + cars:
		(node as Node).process_mode = Node.PROCESS_MODE_PAUSABLE
	if not command_source.is_valid():
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_update_view(0.0)
	if opening_enabled and _saved.is_empty():
		_start_opening()


## A new game: Danny tells you who he is while the camera drifts over the ward
## at night, already alive; the HUD, the player and the clock wait, the night's
## sound steps back under his voice. Without the recording the game simply starts.
func _start_opening() -> void:
	var stream := resolver.get_audio("voice/danny_opening")
	opening = Opening.new()
	add_child(opening)
	var length := stream.get_length() if stream != null else 0.0
	var keys := OpeningScript.shots(layout, _plan("copper_owl"), walker.global_position, length)
	var subtitles := not resolver.has_audio_override("voice/danny_opening")
	if not opening.start(stream, keys, subtitles, load(Hud.FONT_PATH)):
		opening.queue_free()
		opening = null
		return
	hud.visible = false
	markers.visible = false
	player.set_physics_process(false)
	_follow_rate = camera.follow_rate
	camera.follow_rate = 2.4
	camera.zoom_override = opening.zoom
	camera.snap_to(opening.rig)
	soundscape.set_duck(true)
	opening.finished.connect(_end_opening)


## The monologue is over (or skipped): Danny is yours.
func _end_opening() -> void:
	hud.visible = true
	markers.visible = true
	player.set_physics_process(true)
	camera.target = walker
	camera.follow_rate = _follow_rate
	camera.zoom_override = 0.0
	soundscape.set_duck(false)
	opening.queue_free()
	opening = null
	save_game()  # the game is under way: a later start loads it, without the opening


func _park_cars() -> void:
	var glow := resolver.get_texture("fx/glow")
	var wheel := resolver.get_texture(CarWheels.LOGICAL)
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
		CarWheels.new().setup(c, wheel)
		cars.append(c)


## The room containing p (not its doorway), or null.
func _room_containing(p: Vector2) -> InteriorPlan:
	for plan in layout.interiors:
		if (plan as InteriorPlan).contains(p):
			return plan
	return null


func _plan(id: String) -> InteriorPlan:
	for p in layout.interiors:
		if (p as InteriorPlan).id == id:
			return p
	return null


func _on_entered_car(c: Car) -> void:
	soundscape.play("vehicles/door", -3.0)
	camera.target = c
	(c.get_node("Lights") as VehicleLights).set_on(true)
	vehicle_audio.attach(c)


func _on_exited_car(c: Car) -> void:
	soundscape.play("vehicles/door", -3.0)
	camera.target = walker
	(c.get_node("Lights") as VehicleLights).set_on(false)
	vehicle_audio.attach(null)


## The interaction spot the player stands at (on foot): someone to talk to or
## the bed inside a room, else a door to go in or out by; {} when none.
func _spot() -> Dictionary:
	if not player.on_foot():
		return {}
	if interiors.current != null:
		var s := interiors.current.spot_at(walker.global_position)
		if not s.is_empty():
			return s
	var door := interiors.door_at(walker.global_position)
	if not door.is_empty():
		door["id"] = "door"
	return door


## E on foot at a spot: talk to whoever is there (or go to bed). Returns true when used.
func _interact(_at: Vector2) -> bool:
	var spot := _spot()
	if spot.is_empty():
		return false
	if spot.id == "door":
		soundscape.play_door(spot.plan)
		interiors.step_through(walker, spot)
	elif spot.id == "bed" or not interiors.current.person(spot.id).is_empty():
		start_talk(spot.id)
	return true


func start_talk(who: String) -> void:
	talking = who
	if interiors.current != null:
		interiors.view_of(interiors.current.id).face(who, walker.global_position)
	_show(talk.open(who, _talk_context()))


func _talk_context() -> Dictionary:
	return {"gun_drawn": walker.gun != null and walker.gun.is_drawn(), "spare": walker.gun.spare if walker.gun != null else 0,
		"time": clock.text(), "late": clock.is_late()}


func _show(page: Dictionary) -> void:
	if page.is_empty():
		end_talk()
		return
	_page = page
	hud.show_dialogue(page)


## While talking, the player's keys answer (1-4) or walk away (E).
func _converse(cmd: PlayerCommand) -> bool:
	if talking == "":
		return false
	if cmd.choice > 0:
		_answer(cmd.choice - 1)
	elif cmd.interact:
		end_talk()
	return true


## Picks answer i (0-based) on the page on screen.
func _answer(i: int) -> void:
	if talking == "" or i < 0 or i >= (_page.options as Array).size():
		return
	var money := rackets.money
	var bottles := rackets.bottles
	var next := talk.choose(talking, _page.options[i].id, _talk_context())
	if next.get("effects", {}).get("sleep", false):
		sleep()
		return
	soundscape.play_deal(talking, rackets.money - money, rackets.bottles - bottles)
	_apply(next.get("effects", {}))
	hud.set_purse(rackets.money, rackets.bottles, rackets.held)
	save_game()
	_show(next)


## Effects of a conversation outside the money (police, rounds).
func _apply(effects: Dictionary) -> void:
	if effects.has("rounds") and walker.gun != null:
		walker.gun.add_spare(int(effects.rounds))
	if effects.get("police", false) and interiors.current != null:
		# the shopkeeper waits until you have gone, then runs out for the copper
		_report_from = interiors.current
		_report_who = talk.speaker(talking)
		_report_left = REPORT_DELAY


## Someone runs out of `_report_from` shouting for the police once the player
## has left it (or after REPORT_DELAY seconds, whichever comes first).
func _update_report(delta: float) -> void:
	if _report_from == null:
		return
	_report_left -= delta
	if interiors.current != _report_from or _report_left <= 0.0:
		var door := _report_from.outside_door(0, 30.0)
		_report_from = null
		officer.hear_gunshot(door, REPORT_RADIUS)
		hud.show_notice("%s runs into the street, shouting for the copper!" % _report_who)


func end_talk() -> void:
	talking = ""
	_page = {}
	hud.hide_dialogue()
	for v in interiors.views:
		v.face_home()


## Sleeps through the day: the next evening begins at home with everything
## you carry (money, bottles, rounds); the streets, the cars and the copper
## are back as they are at the start of every night, and tonight's deals reset.
func sleep() -> void:
	end_talk()
	rackets.end_night()
	clock.reset()
	_warned = 0
	_report_from = null
	for i in cars.size():
		var spec: Dictionary = layout.cars[i]
		cars[i].place(Transform2D(spec.rot, spec.pos))
		cars[i].driven = false
	officer.reset()
	street.reset()
	if walker.gun != null:
		walker.gun.holster()
	walker.place(layout.spawn, layout.spawn_facing)
	interiors.update_player(walker.global_position)
	interiors.snap()
	camera.snap_to(walker)
	hud.set_purse(rackets.money, rackets.bottles, rackets.held)
	var news := ""
	if rackets.collected > 0:
		news = "Rourke's boys were waiting on the stairs.\nThey took %s off you." % Rackets.dollars(rackets.collected)
	hud.wake_up(rackets.night, clock.text(), news)
	save_game()


func _update_clock(delta: float) -> void:
	if not paused and opening == null:
		var before := clock.minute
		clock.advance(delta)
		rackets.town.advance(clock.minute - before)  # the club serves its customers as the night goes on
	if clock.is_dawn() and _warned < 2:
		_warned = 2
		hud.show_notice("Dawn's breaking. Get home to bed before the city wakes up.")
	elif clock.is_late() and _warned < 1:
		_warned = 1
		hud.show_notice("It's getting late. Time to head home to bed.")
	hud.set_clock(rackets.night, clock.text(), clock.is_late())


func save_game() -> void:
	var data := {"rackets": rackets.to_dict()}
	if walker != null and walker.gun != null:
		data["gun"] = {"ammo": walker.gun.ammo, "spare": walker.gun.spare}
	SaveGame.write(save_path, data)


func _load_game() -> void:
	_saved = SaveGame.read(save_path)
	if _saved.has("rackets"):
		rackets.from_dict(_saved.rackets)


## Puts the saved rounds back in the gun (after the player exists).
func _load_gun() -> void:
	if _saved.has("gun") and walker.gun != null:
		walker.gun.ammo = clampi(int(_saved.gun.get("ammo", walker.gun.ammo)), 0, gun_rules.magazine)
		if walker.gun.spare >= 0:
			walker.gun.spare = maxi(0, int(_saved.gun.get("spare", walker.gun.spare)))


func _unhandled_input(event: InputEvent) -> void:
	if opening != null:
		if event.is_action_pressed(CityInput.MENU) or event.is_action_pressed(CityInput.INTERACT) \
				or event.is_action_pressed(CityInput.HANDBRAKE) or event.is_action_pressed("ui_accept") \
				or (event is InputEventMouseButton and event.pressed):
			opening.skip()
		return
	if event.is_action_pressed(CityInput.MENU) and talking != "":
		end_talk()
	elif event.is_action_pressed(CityInput.MENU):
		paused = not paused
		get_tree().paused = paused
		hud.set_paused(paused)
		hud.show_sound(settings, sound_row)
	elif paused and _sound_input(event):
		pass
	elif event.is_action_pressed(CityInput.QUIT) and paused:
		save_game()
		get_tree().quit()
	elif event.is_action_pressed(CityInput.HELP):
		hud.toggle_help()


## On the pause screen: Up / Down choose a sound level, Left / Right change it
## by a tenth (heard at once, kept for next time). True when the key was used.
func _sound_input(event: InputEvent) -> bool:
	var n := AudioSettings.BUSES.size()
	var bus: String = AudioSettings.BUSES[sound_row]
	if event.is_action_pressed("ui_up"):
		sound_row = (sound_row + n - 1) % n
	elif event.is_action_pressed("ui_down"):
		sound_row = (sound_row + 1) % n
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		var step := 0.1 if event.is_action_pressed("ui_right") else -0.1
		settings.set_volume(bus, snappedf(settings.volume[bus] + step, 0.1))
		if settings_path != "":
			settings.save_settings()
	else:
		return false
	hud.show_sound(settings, sound_row)
	return true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func _process(delta: float) -> void:
	_update_clock(delta)
	_update_view(delta)
	_update_report(delta)


func _update_view(delta: float) -> void:
	camera.update_camera(delta)
	city.update_view(camera.eye(), camera.eye_height(), camera.view_rect())
	interiors.update_player(walker.global_position if player.on_foot() else Vector2.INF)
	street.view = camera.view_rect()
	var prompt := ""
	if player.on_foot():
		var spot := _spot()
		var c := player.enterable_car()
		if not spot.is_empty():
			prompt = "E   %s" % spot.prompt
		elif c != null:
			prompt = "E   Get in the %s" % c.vehicle.params.display_name
	elif player.car.speed() < 30.0:
		prompt = "E   Get out"
	var focus := player.body().global_position
	var door := interiors.door_at(walker.global_position) if player.on_foot() else {}
	var facing := walker.model.facing if player.on_foot() else player.car.model.heading
	var speed := 0.0 if player.on_foot() else player.car.speed() / player.car.model.params.max_speed
	hud.minimap.set_view(focus, facing, speed, officer.body.global_position, officer.brain.is_hunting(), delta)
	var in_room: InteriorPlan = null
	if player.on_foot() and interiors.current != null and interiors.current.contains(walker.global_position):
		in_room = interiors.current
	markers.update_markers(delta, camera.eye(), camera.eye_height(), focus, in_room,
		door.plan if not door.is_empty() and door.outside else null)
	var place := interiors.current.name if interiors.current != null else layout.place_name(focus)
	hud.refresh(delta, place, prompt, player.car, get_viewport().get_mouse_position(),
		player.on_foot() and not paused)
	hud.show_gun(walker.gun if player.on_foot() else null)
	if opening != null:
		camera.zoom_override = opening.zoom
		# the camera is the listener: the night as it drifts past
		var eye := camera.eye()
		soundscape.update_listener(eye, _room_containing(eye), false, clock.activity(), delta)
	else:
		soundscape.update_listener(focus, interiors.current if player.on_foot() else null, not player.on_foot(),
			clock.activity(), delta)
