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

## M009: an incident began, moved on or ended ("started", "phase", "over").
signal incident_event(event: String, incident: Dictionary)

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
## The people's recorded lines: which first-meeting lines Danny has heard
## (saved), and the player that says them one at a time (M006).
var voice_lines := VoiceLines.new()
var voice: VoicePlayer
## The Bird's act on the bandstand and how she moves (M006).
var stage := StageAct.new()
var bird_show: BirdPerformance
## The opening narration while it runs (null otherwise).
var opening: Opening
var _follow_rate := 7.0
var bullets: BulletWorld
var gunfire: GunfireView
var navigator: CityNavigator
## M008: the districts of the city in one world: the Riverside Ward (built at
## start-up, pinned) and its neighbours, streamed in as Danny comes near.
var world: DistrictStreamer
## M009: the city's own small troubles (they run on the clock wherever Danny is).
var incidents: StreetIncidents
## M008: what belongs to each neighbouring district while it is loaded:
## id -> {street: StreetLife, officer: PoliceOfficer (or null), cars_made: bool}.
var _districts := {}
## M008: the layout entry of every car in `cars` (the ward's first, then each
## district's as it is first built: `cars` only ever grows, a car in a freed
## district is put away, not freed, so nothing is ever duplicated).
var car_specs: Array = []
## Tests: no passers-by or traffic in the neighbouring districts either.
var quiet_streets := false
var officer: PoliceOfficer
## M006: Lefty Moran, the North Side gangster outside Doyle's Garage.
var rival: Rival
## M006: whose car is whose and which Danny has taken tonight.
var thefts: CarThefts
## Cars stolen tonight, and how many of those the police saw (for tests and notices).
var theft_incidents := 0
var thefts_witnessed := 0
## Named people carried off to the Doc's: id -> the night it happened.
var ward_out := {}
## Times Danny went down (for tests).
var collapses := 0
## M008: the chance a round that hits the car Danny drives goes through to him.
const DRIVER_HIT_CHANCE := 0.25
var _luck := RandomNumberGenerator.new()
const RIVAL_POST: Array[Vector2] = [Vector2(1180, 1392), Vector2(1330, 1392)]
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
## M006: the ward map, or the status screen, is open (the world is paused under it).
var map_open := false
var status_open := false
## Doc Pettibone's fee for patching Danny up after he went down (cents, at most).
const COLLAPSE_FEE := 500
## M007: a fistfight under way (the dial is up; nothing else moves Danny), its
## rules, the man he is fighting and what to do when it is over.
@export var fight_rules: FightRules = preload("res://src/fight/default_fight.tres")
var fighting := false
var fight_opponent: Walker
var _fight_done: Callable
## M007: a fight agreed in a talk, started when the talk ends ("lefty" or "").
var _fight_pending := ""
const FIGHT_TIP_BONUS := 14.0
const FIGHT_HURT_PACE := 0.85
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
	_luck.seed = 1932008
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
	world = DistrictStreamer.new()
	add_child(world)
	world.setup(resolver, CityPlan.layouts(layout))
	world.clearance = Walker.RADIUS + 3.0
	world.extra_steps = _district_steps
	world.district_ready.connect(_on_district_ready)
	world.district_unloading.connect(_on_district_unloading)
	world.district_entered.connect(_on_district_entered)
	_load_districts()
	var all_layouts := world.order.map(func(id: String) -> DistrictLayout: return world.layouts[id])
	incidents = StreetIncidents.new(StreetIncidents.spots_of(all_layouts))
	incidents.begin_night(rackets.night, float(night_rules.start_minute), float(night_rules.dawn_minute),
		StreetIncidents.saved_history(_saved.get("incidents", {}), rackets.night))
	_park_cars()
	thefts = CarThefts.new(layout.cars)
	walker = Walker.create(resolver, "characters/gangster", {"armed_sheet": "characters/gangster_armed", "gun": gun_rules})
	add_child(walker)
	walker.place(layout.spawn, layout.spawn_facing)
	walker.falls = false  # M006: Danny goes down, but the game decides what that means
	walker.rng.seed = 1932001
	walker.hurt.connect(_on_danny_hurt)
	walker.struck_down.connect(_danny_down)
	_load_gun()
	interiors.update_player(walker.global_position)
	interiors.snap()
	walker.aim_point = layout.spawn + Vector2.from_angle(layout.spawn_facing) * 60.0
	camera = CityCamera.new()
	camera.name = "Camera"
	add_child(camera)
	camera.set_bounds(layout.bounds)  # widened as neighbouring districts load (M008)
	camera.snap_to(walker)
	camera.make_current()
	player = PlayerController.new()
	player.name = "Player"
	player.command_source = command_source
	add_child(player)
	player.setup(walker, cars, world)
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
	world.adopt(layout.id, city, navigator)
	officer = PoliceOfficer.new()
	add_child(officer)
	officer.setup(resolver, police_rules, layout.police_beat, navigator, player.body, bullets)
	_wire_officer(officer)
	bullets.struck.connect(_on_bullet_struck)
	player.fired.connect(_on_player_fired)
	street = StreetLife.new()
	add_child(street)
	street.setup(layout, resolver, clock, CAR_SCENE, VEHICLES, cars, [walker, officer.body] as Array[Walker])
	street.view = camera.view_rect()
	rival = Rival.new()
	add_child(rival)
	rival.setup(resolver, gun_rules, RIVAL_POST, navigator, bullets, player.body)
	rival.danny = walker
	rival.fired.connect(gunfire.on_fired)
	rival.fired.connect(func(muzzle: Vector2, _dir: Vector2) -> void:
		for o in officers():
			o.hear_gunshot(muzzle, gun_rules.noise_radius)
		for s in streets():
			s.hear_gunshot(muzzle))
	rival.provoked.connect(func() -> void: hud.show_notice("Lefty Moran goes for his gun!"))
	rival.struck_down.connect(func() -> void: hud.show_notice("Lefty Moran goes down and stays down."))
	# M007: Danny's gun settles Rourke's job too (the M006 rules handle the shooting)
	rival.body.hurt.connect(func(_region: String, _level: int) -> void:
		if rival.body.last_shooter == walker:
			_lefty_shot(false))
	rival.struck_down.connect(func() -> void:
		if rival.body.last_shooter == walker:
			_lefty_shot(true))
	player.fired.connect(func(muzzle: Vector2, dir: Vector2) -> void:
		if not rival.is_down() and rival.near_miss(muzzle, dir):
			rival.provoke())
	for v in interiors.views:
		v.person_down.connect(_on_person_down.bind(v))
	vehicle_audio = VehicleAudio.new()
	add_child(vehicle_audio)
	vehicle_audio.setup(resolver)
	soundscape = Soundscape.new()
	add_child(soundscape)
	soundscape.setup(resolver, layout, _plan("copper_owl"))
	soundscape.track_traffic(street.traffic)
	voice = VoicePlayer.new()
	add_child(voice)
	voice.setup(resolver, voice_lines)
	var bird := interiors.person("copper_owl", "bird")
	if bird != null:
		bird_show = BirdPerformance.new()
		add_child(bird_show)
		bird_show.setup(bird, stage)
	_load_ward()
	hud = Hud.new()
	add_child(hud)
	hud.setup(resolver, layout.name)
	hud.add_minimap(layout)
	var morgue := layout.building_named("The Morgue")
	if morgue >= 0:
		hud.city_map.add_landmark(layout.buildings[morgue].rect.get_center(), "The Morgue", resolver.get_texture("ui/marker_morgue"))
	# M008: the neighbouring districts on the maps, painted from their plans (not built)
	for id in world.order:
		if id != layout.id:
			hud.minimap.add_district(world.layouts[id])
	hud.city_map.refresh_districts()
	player.interaction = _interact
	player.conversation = _converse
	hud.dialogue_choice.connect(_answer)
	hud.set_purse(rackets.money, rackets.bottles, rackets.held)
	player.entered_car.connect(_on_entered_car)
	player.exited_car.connect(_on_exited_car)
	player.notice.connect(hud.show_notice)
	_wire_officer_hud(officer)
	# Esc must still work while the world is paused: the root always runs,
	# the world itself stops.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for node in [city, interiors, walker, camera, player, vehicle_audio, soundscape, voice, bullets, gunfire, officer, street, rival, world] + cars:
		(node as Node).process_mode = Node.PROCESS_MODE_PAUSABLE
	if not command_source.is_valid():
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_update_view(0.0)
	if opening_enabled and _saved.is_empty():
		_start_opening()


## M008: a beat cop in the game: his own revolver is seen and heard like
## anybody's (Danny's shots reach him through _on_player_fired).
func _wire_officer(o: PoliceOfficer) -> void:
	o.player_walker = walker
	o.fired.connect(gunfire.on_fired)
	o.fired.connect(func(muzzle: Vector2, _dir: Vector2) -> void:
		for s in streets():
			s.hear_gunshot(muzzle))


## Danny fired: every beat cop in earshot hears it (and takes a close one
## personally), passers-by scatter.
func _on_player_fired(muzzle: Vector2, dir: Vector2) -> void:
	for o in officers():
		if not o.near_miss(muzzle, dir):
			o.hear_gunshot(muzzle, gun_rules.noise_radius)
	for s in streets():
		s.hear_gunshot(muzzle)


func _wire_officer_hud(o: PoliceOfficer) -> void:
	o.state_changed.connect(func(s: int) -> void: hud.set_police_status(s, _any_officer_armed()))
	o.gave_up.connect(func() -> void: hud.show_notice("You lost him."))
	o.drew_gun.connect(func() -> void:
		hud.show_notice("The copper draws his revolver!")
		hud.set_police_status(o.brain.state, true))


## The beat cops in the loaded districts (M008).
func officers() -> Array[PoliceOfficer]:
	var out: Array[PoliceOfficer] = [officer]
	for id in _districts:
		var o: PoliceOfficer = _districts[id].get("officer")
		if o != null and is_instance_valid(o):
			out.append(o)
	return out


## The street life of the loaded districts (M008).
func streets() -> Array[StreetLife]:
	var out: Array[StreetLife] = []
	if street != null:
		out.append(street)
	for id in _districts:
		var s: StreetLife = _districts[id].get("street")
		if s != null and is_instance_valid(s):
			out.append(s)
	return out


# ------------------------------------------------------------------ M008: the neighbouring districts

## What the streamer builds for a district besides its city, a slice at a
## time: its passers-by and traffic, and (the first time) its parked cars.
func _district_steps(l: DistrictLayout, node: Node2D) -> Array[Callable]:
	return [_district_street.bind(l, node), _district_cars.bind(l)]


func _district(id: String) -> Dictionary:
	if not _districts.has(id):
		_districts[id] = {"street": null, "officer": null, "cars_made": false}
	return _districts[id]


func _district_street(l: DistrictLayout, node: Node2D) -> void:
	var s := StreetLife.new()
	node.add_child(s)
	var others: Array[Walker] = [walker]
	for o in officers():
		others.append(o.body)
	s.setup(l, resolver, clock, CAR_SCENE, VEHICLES, cars, others)
	s.name = "StreetLife"
	if quiet_streets:
		s.clear()
	s.view = camera.view_rect()
	soundscape.track_traffic(s.traffic)
	_district(l.id).street = s


## A district's parked cars join `cars` the first time it is built (later
## they are only put away and brought back).
func _district_cars(l: DistrictLayout) -> void:
	var e := _district(l.id)
	if e.cars_made:
		return
	e.cars_made = true
	for spec in l.cars:
		_make_car(spec)


## A district is complete: the camera may show it, the cars parked in it come
## back out, and its beat cop takes up his round (or lies where he fell
## tonight, if Danny shot him).
func _on_district_ready(id: String) -> void:
	camera.set_bounds(world.bounds())
	if id == layout.id:
		return
	var l: DistrictLayout = world.layouts[id]
	for c in cars:
		if c.has_meta("away") and l.bounds.has_point(c.global_position):
			_put_away(c, false)
	if l.police_beat.is_empty():
		return
	var o := PoliceOfficer.new()
	world.loaded[id].node.add_child(o)
	o.setup(resolver, police_rules, l.police_beat, world.navigator_of(id), player.body, bullets)
	o.home_area = l.play_area
	_wire_officer(o)
	_wire_officer_hud(o)
	var st: Dictionary = world.state.get(id, {})
	var past: Dictionary = st.get("officer", {})
	if past.get("down", false) and int(past.get("night", -1)) == rackets.night:
		o.body.place(past.pos, 0.0)
		o.body.condition.damage["torso"] = BodyCondition.MAX
		o.body.down = true
		o.body.lie_down()
		o.torch.visible = false
	_district(id).officer = o
	for s in streets():
		if not s.others.has(o.body):
			s.others.append(o.body)


## A district is about to be freed: remember whether its beat cop is down
## tonight, put away the cars parked in it (not the one Danny drives) and
## let go of bullets still flying there.
func _on_district_unloading(id: String) -> void:
	if not _districts.has(id):
		return
	var e: Dictionary = _districts[id]
	var o: PoliceOfficer = e.get("officer")
	if o != null and is_instance_valid(o):
		if not world.state.has(id):
			world.state[id] = {}
		world.state[id]["officer"] = {"down": o.is_down(), "pos": o.body.global_position, "night": rackets.night}
		for s in streets():
			s.others.erase(o.body)
	e.officer = null
	e.street = null
	var b: Rect2 = world.layouts[id].bounds
	for c in cars:
		if c != player.car and b.has_point(c.global_position):
			_put_away(c, true)
	bullets.drop_in(b)
	camera.set_bounds.call_deferred(world.bounds())


func _on_district_entered(id: String) -> void:
	var l: DistrictLayout = world.layouts[id]
	if hud != null:
		hud.set_district(l.name)
	if soundscape != null:
		soundscape.layout = l


## A car in a district that is not loaded is put away (hidden, out of the
## physics, not moving) - and brought back as it was.
func _put_away(c: Car, away: bool) -> void:
	if away == c.has_meta("away"):
		return
	if away:
		c.set_meta("away", [c.collision_layer, c.collision_mask])
		c.collision_layer = 0
		c.collision_mask = 0
		c.visible = false
		c.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		var layers: Array = c.get_meta("away")
		c.collision_layer = layers[0]
		c.collision_mask = layers[1]
		c.visible = true
		c.process_mode = Node.PROCESS_MODE_PAUSABLE
		c.remove_meta("away")


func _any_officer_armed() -> bool:
	return officers().any(func(o: PoliceOfficer) -> bool: return o.is_armed() and o.brain.is_hunting())


## M008: a round struck something. Danny's rounds in a person are a crime any
## beat cop who could see it will answer with his revolver; somebody else's
## round in the car Danny is driving may go through to him.
func _on_bullet_struck(collider: Object, at: Vector2, direction: Vector2, shooter: Node) -> void:
	if shooter == walker and collider is Walker and collider != walker:
		for o in officers():
			if o.body != collider:
				o.witness_violence((collider as Walker).global_position, walker.global_position)
	elif shooter != null and shooter != walker and not player.on_foot() and collider == player.car:
		if _luck.randf() < DRIVER_HIT_CHANCE:
			walker.hit_by_bullet(walker.global_position + direction * -2.0, direction, shooter)


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
	opening.finished.connect(_end_opening)


## The monologue is over (or skipped): Danny is yours.
func _end_opening() -> void:
	hud.visible = true
	markers.visible = true
	player.set_physics_process(true)
	camera.target = walker
	camera.follow_rate = _follow_rate
	camera.zoom_override = 0.0
	opening.queue_free()
	opening = null
	save_game()  # the game is under way: a later start loads it, without the opening


func _park_cars() -> void:
	for spec in layout.cars:
		_make_car(spec)


## A parked car from a layout entry (M008: any district's), added to `cars`,
## its owner to `thefts` (once that exists).
func _make_car(spec: Dictionary) -> Car:
	var vehicle: VehicleType = VEHICLES[spec.type]
	var c: Car = CAR_SCENE.instantiate()
	c.position = spec.pos
	c.rotation = spec.rot
	c.z_index = Layers.Z_ACTOR
	add_child(c)
	var paint: String = vehicle.paints[int(spec.paint) % vehicle.paints.size()]
	c.setup(vehicle, resolver.get_texture(paint), paint)
	var lights := VehicleLights.new()
	lights.setup(c, resolver.get_texture("fx/glow"))
	CarWheels.new().setup(c, resolver.get_texture(CarWheels.LOGICAL))
	if process_mode == Node.PROCESS_MODE_ALWAYS:
		c.process_mode = Node.PROCESS_MODE_PAUSABLE
	cars.append(c)
	car_specs.append(spec)
	if thefts != null:
		thefts.add(String(spec.get("owner", "")))
	return c


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
	var i := cars.find(c)
	if thefts.get_in(i):
		theft_incidents += 1
		if officers().any(func(o: PoliceOfficer) -> bool: return o.witness_theft(c.global_position)):
			thefts_witnessed += 1
			hud.show_notice("The beat cop saw you take it!")
		else:
			hud.show_notice("Not your car. Nobody saw you take it.")
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
## M006: nobody to talk to who is down or carried off; Lefty in the street.
func _spot() -> Dictionary:
	if not player.on_foot():
		return {}
	if interiors.current != null:
		var s := interiors.current.spot_at(walker.global_position)
		if not s.is_empty() and (s.id == "bed" or interiors.view_of(interiors.current.id).person_ok(s.id)):
			return s
	if rival != null and not rival.is_down() and not rival.is_hostile() \
			and walker.global_position.distance_to(rival.body.global_position) < 40.0:
		return {"id": "lefty", "prompt": "Talk to Lefty Moran"}
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
	elif spot.id == "bird":
		talk_to_bird()
	elif spot.id == "lefty":
		talking = "lefty"
		rival.body.aim_point = walker.global_position
		_show(talk.open("lefty", _talk_context()))
	elif spot.id == "bed" or not interiors.current.person(spot.id).is_empty():
		start_talk(spot.id)
	return true


func start_talk(who: String, extra: Dictionary = {}) -> void:
	talking = who
	if interiors.current != null:
		interiors.view_of(interiors.current.id).face(who, walker.global_position)
	_show(talk.open(who, _talk_context().merged(extra, true)))


## E at the Bird's microphone: if she is singing, the needle scratches off the
## record, the song stops and she gives Danny a piece of her mind; between
## songs she just waits for him. Either way they talk, and when he walks away
## the band counts her back in.
func talk_to_bird() -> void:
	var interrupted := stage.interrupt()
	if interrupted:
		soundscape.interrupt_music()
	else:
		stage.hold()
	start_talk("bird", {"interrupted": interrupted})


## M006: Danny is hit. Where, and how bad, on screen.
func _on_danny_hurt(region: String, level: int) -> void:
	hud.show_notice("Hit in the %s - %s." % [BodyCondition.NAMES[region], BodyCondition.label(level)])


## M006: Danny goes down. He is not killed: somebody drags him to Doc
## Pettibone's, and he comes to on the examining table an hour later, patched
## up in a hurry (his wounds are grazes now), the Doc's fee taken from his
## pocket (as far as it goes). The night goes on.
func _danny_down() -> void:
	collapses += 1
	end_talk()
	if not player.on_foot():
		player.eject()  # M008: shot at the wheel
	for o in officers():
		o.stand_down()  # he thinks he got you
	walker.condition.patch_up()
	walker.down = false
	if walker.gun != null:
		walker.gun.holster()
	clock.set_time(minf(clock.minute + 60.0, float(night_rules.dawn_minute)))
	rival.brain.state = RivalBrain.State.IDLE if not rival.is_down() else rival.brain.state  # he thinks he got you
	var fee := rackets.pay_doctor(COLLAPSE_FEE)
	var vet := _plan("vet")
	var spot: Vector2 = vet.spots[0].pos if vet != null else layout.spawn
	walker.place(spot, -PI / 2)
	interiors.update_player(walker.global_position)
	interiors.snap()
	camera.snap_to(walker)
	hud.set_purse(rackets.money, rackets.bottles, rackets.held)
	hud.wake_up(rackets.night, clock.text(), "You came to on Doc Pettibone's table.\nSomebody dragged you in. He took %s for his trouble." % Rackets.dollars(fee))
	save_game()


## M006: someone in a room was struck down. One of the ward's own people (named)
## is carried off to the Doc's for the night - and if Danny did it, the ward
## and Rourke will remember. The Bird down means no more music tonight.
func _on_person_down(id: String, named: bool, view: InteriorView) -> void:
	var w: Walker = view.people.get(id)
	if not named:
		return
	ward_out[id] = rackets.night
	if w != null and w.last_shooter == walker:
		rackets.shot_person(id)
	if id == "bird":
		stage.knock_out()
		soundscape.stop_music()
	if talking == id:
		end_talk()
	hud.show_notice("%s goes down, badly hurt. Somebody runs for the Doc." % talk.speaker(id))
	save_game()


func _talk_context() -> Dictionary:
	return {"gun_drawn": walker.gun != null and walker.gun.is_drawn(), "spare": walker.gun.spare if walker.gun != null else 0,
		"time": clock.text(), "late": clock.is_late(), "first_meeting": voice_lines.due(Conversations.greeting_line(talking)),
		"treatment": walker.condition.treatment_price(), "lefty_dead": rival != null and rival.is_down(),
		"lefty_hurt": rival != null and rival.body.condition.worst() >= BodyCondition.Level.WOUNDED,
		"danny_worst": walker.condition.worst(), "night": rackets.night}


func _show(page: Dictionary) -> void:
	if page.is_empty():
		end_talk()
		return
	_page = page
	hud.show_dialogue(page)
	if page.has("voice") and not voice.say(page.voice).is_empty():
		save_game()  # a first meeting is remembered even if the game is quit at once


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
	if effects.has("fight"):
		_fight_pending = String(effects.fight)  # starts when Danny raises his fists
	if effects.has("job"):
		var step := rackets.job.objective()
		if not step.is_empty():
			hud.show_notice(step.text)
	if effects.get("heal", false):
		walker.condition.heal_all()
		hud.show_notice("Patched up. Good as new, near enough.")
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
	if _fight_pending == "lefty":
		call_deferred("_fight_lefty")
	if talking == "bird":
		stage.release()
	talking = ""
	_page = {}
	if voice != null:
		voice.stop()
	hud.hide_dialogue()
	for v in interiors.views:
		v.face_home()


## Sleeps through the day: the next evening begins at home with everything
## you carry (money, bottles, rounds); the streets, the cars and the copper
## are back as they are at the start of every night, and tonight's deals reset.
func sleep() -> void:
	end_talk()
	stage.reset()  # the Bird is singing when the club opens
	ward_out.clear()  # back from the Doc's, patched up (and they remember)
	thefts.clear()  # the cars are back with their owners
	for v in interiors.views:
		v.reset_people()
	rival.reset()
	walker.condition.rest()  # grazes heal overnight; wounds wait for the Doc
	rackets.end_night()
	clock.reset()
	incidents.begin_night(rackets.night, float(night_rules.start_minute), float(night_rules.dawn_minute))
	_warned = 0
	_report_from = null
	for i in cars.size():
		var spec: Dictionary = car_specs[i]
		cars[i].place(Transform2D(spec.rot, spec.pos))
		cars[i].driven = false
		_put_away(cars[i], not world.is_ready(world.district_at(spec.pos)))
	for o in officers():
		o.reset()
	for s in streets():
		s.reset()
	for id in world.state:
		world.state[id].erase("officer")  # a new man on every beat
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
		_advance_incidents()
	if clock.is_dawn() and _warned < 2:
		_warned = 2
		hud.show_notice("Dawn's breaking. Get home to bed before the city wakes up.")
	elif clock.is_late() and _warned < 1:
		_warned = 1
		hud.show_notice("It's getting late. Time to head home to bed.")
	hud.set_clock(rackets.night, clock.text(), clock.is_late())


func save_game() -> void:
	var data := {"rackets": rackets.to_dict(), "voices": voice_lines.to_dict()}
	if walker != null:
		data["danny"] = walker.condition.to_dict()
	if rival != null:
		data["ward"] = {"out": ward_out.duplicate(), "rival": rival.to_dict()}
	if walker != null and walker.gun != null:
		data["gun"] = {"ammo": walker.gun.ammo, "spare": walker.gun.spare}
	if world != null:
		data["districts"] = _districts_to_save()
	if incidents != null:
		data["incidents"] = incidents.to_dict()
	SaveGame.write(save_path, data)


## M009: the city's incidents move on with the clock; one that ends is
## talked about by whoever saw it.
func _advance_incidents() -> void:
	var danny := player.body().global_position if player != null else Vector2.INF
	for e in incidents.advance(clock.minute, danny, _can_stop):
		if e.event == "over":
			rackets.street_incident_over(e.incident)
		incident_event.emit(e.event, e.incident)


## Whether a district's beat cop is free to stop somebody (an unloaded
## district's man is, in the abstract; a loaded one not while he is after Danny).
func _can_stop(district: String) -> bool:
	if not world.is_ready(district):
		return true
	var o: PoliceOfficer = officer if district == layout.id else _districts.get(district, {}).get("officer")
	return o != null and is_instance_valid(o) and not o.is_down() and not o.brain.is_hunting()


## M008: what each neighbouring district keeps for tonight - whether its beat
## cop is down, and where - from the live district if it is loaded.
func _districts_to_save() -> Dictionary:
	var out := {}
	for id in world.order:
		if id == layout.id:
			continue
		var o: PoliceOfficer = _districts.get(id, {}).get("officer")
		var past: Dictionary = world.state.get(id, {}).get("officer", {})
		if o != null and is_instance_valid(o):
			past = {"down": o.is_down(), "pos": o.body.global_position, "night": rackets.night}
		if past.get("down", false):
			out[id] = {"officer": {"down": true, "x": past.pos.x, "y": past.pos.y, "night": int(past.night)}}
	return out


## M008: tonight's district state from the save (an earlier night's is forgotten).
func _load_districts() -> void:
	var ds: Dictionary = _saved.get("districts", {})
	for id in ds:
		var o: Dictionary = ds[id].get("officer", {})
		if world.layouts.has(id) and int(o.get("night", -1)) == rackets.night and o.get("down", false):
			world.state[id] = {"officer": {"down": true, "pos": Vector2(float(o.x), float(o.y)), "night": rackets.night}}


func _load_game() -> void:
	_saved = SaveGame.read(save_path)
	if _saved.has("rackets"):
		rackets.from_dict(_saved.rackets)
	if _saved.has("voices"):
		voice_lines.from_dict(_saved.voices)
	elif _saved.has("rackets"):
		voice_lines.assume_old_acquaintances()  # a game from before the voices


## M006: Danny's wounds, Lefty's fate and who is out tonight, from the save.
func _load_ward() -> void:
	if _saved.has("danny"):
		walker.condition.from_dict(_saved.danny)
	var ward: Dictionary = _saved.get("ward", {})
	rival.from_dict(ward.get("rival", {}))
	ward_out = {}
	for id in ward.get("out", {}):
		if int(ward.out[id]) == rackets.night:
			ward_out[id] = rackets.night
	for v in interiors.views:
		var still := v.plan.people.map(func(p: Dictionary) -> String: return p.id).filter(func(id: String) -> bool: return ward_out.has(id))
		if not still.is_empty():
			v.reset_people(still)
	if ward_out.has("bird"):
		stage.knock_out()
		soundscape.stop_music()


## Puts the saved rounds back in the gun (after the player exists).
func _load_gun() -> void:
	if _saved.has("gun") and walker.gun != null:
		walker.gun.ammo = clampi(int(_saved.gun.get("ammo", walker.gun.ammo)), 0, gun_rules.magazine)
		if walker.gun.spare >= 0:
			walker.gun.spare = maxi(0, int(_saved.gun.get("spare", walker.gun.spare)))


func _unhandled_input(event: InputEvent) -> void:
	if fighting:
		# only Space, for the dial; no walking, shooting, maps or menus mid-fight
		if event.is_action_pressed(CityInput.HANDBRAKE):
			hud.fight_dial.press()
		return
	if opening != null:
		if event.is_action_pressed(CityInput.MENU) or event.is_action_pressed(CityInput.INTERACT) \
				or event.is_action_pressed(CityInput.HANDBRAKE) or event.is_action_pressed("ui_accept") \
				or (event is InputEventMouseButton and event.pressed):
			opening.skip()
		return
	if map_open and event.is_action_pressed(CityInput.RECENTRE):
		hud.city_map.recentre()
		return
	if map_open and (event.is_action_pressed(CityInput.MAP) or event.is_action_pressed(CityInput.MENU)):
		show_map(false)
		return
	if status_open and (event.is_action_pressed(CityInput.STATUS) or event.is_action_pressed(CityInput.MENU)):
		show_status(false)
		return
	if map_open or status_open:
		return  # nothing else while one is open
	if event.is_action_pressed(CityInput.MAP) and not paused and talking == "":
		show_map(true)
		return
	if event.is_action_pressed(CityInput.STATUS) and not paused and talking == "":
		show_status(true)
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


## M006: the map of the whole ward, on (M) or off (M or Esc). The world waits
## under it: no walking, driving or shooting while it is open.
func show_map(on: bool) -> void:
	map_open = on
	get_tree().paused = on
	var here := world.layout_at(player.body().global_position)
	hud.show_map(on, player.body().global_position, here.bounds if here != null else layout.bounds)
	if on:
		_job_on_map()
		_update_map()
	# M008: the mouse drags the city map round while it is open
	if not command_source.is_valid():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if on else Input.MOUSE_MODE_HIDDEN


## Danny's own car (null if there is none).
func my_car() -> Car:
	for i in cars.size():
		if thefts.is_dannys(i):
			return cars[i]
	return null


## M007: a fistfight with `opponent` (a Walker) - the dial over the street,
## five checks; `done` is called with (won, results) once it is over, after the
## bruises are dealt out. False (and nothing happens) when a fight is already
## on, Danny is not on foot or either man is down. Reusable for any opponent.
func start_fight(opponent: Walker, opponent_name: String, done: Callable, zone_bonus: float = 0.0,
		speed_scale: float = 1.0) -> bool:
	if fighting or not player.on_foot() or walker.down or opponent == null or opponent.down:
		return false
	end_talk()
	fighting = true
	fight_opponent = opponent
	_fight_done = done
	player.set_physics_process(false)
	walker.move = Vector2.ZERO
	walker.velocity = Vector2.ZERO
	if walker.gun != null:
		walker.gun.holster()
	walker.aim_point = opponent.global_position
	opponent.aim_point = walker.global_position
	opponent.move = Vector2.ZERO
	if rival != null and opponent == rival.body:
		rival.held = true
	var seed_value := rackets.night * 1000 + int(walker.global_position.x) % 997
	var f := FistFight.new(fight_rules, seed_value, zone_bonus - walker.condition.aim_spread() * 2.0, speed_scale)
	hud.fight_dial.start(f, opponent_name)
	if not hud.fight_dial.check_done.is_connected(_on_fight_check):
		hud.fight_dial.check_done.connect(_on_fight_check)
		hud.fight_dial.finished.connect(_on_fight_over)
	return true


## M007: Lefty put up his fists ("Raise your fists" or walking away from the
## line starts it). Knowing how he fights (Eddie's tip) widens the zone; a
## wounded Lefty is slower.
func _fight_lefty() -> void:
	_fight_pending = ""
	if rival == null or rival.is_down() or walker.global_position.distance_to(rival.body.global_position) > 90.0:
		return
	var bonus := FIGHT_TIP_BONUS if rackets.job.learned.has("tip") else 0.0
	var pace := FIGHT_HURT_PACE if rival.body.condition.worst() >= BodyCondition.Level.WOUNDED else 1.0
	start_fight(rival.body, Rival.NAME, _on_lefty_fight, bonus, pace)


func _on_lefty_fight(won: bool, _results: Array) -> void:
	talking = "lefty"
	rival.body.aim_point = walker.global_position
	_show(talk.choose("lefty", "job_fight_won" if won else "job_fight_lost", _talk_context()))
	if won:
		soundscape.play_deal("lefty", rackets.job.recovered, 0)
	hud.set_purse(rackets.money, rackets.bottles, rackets.held)
	hud.show_notice(rackets.job.objective().get("text", ""))


## M007: Danny shot Lefty (`dead`: and killed him).
func _lefty_shot(dead: bool) -> void:
	var was := rackets.job.outcome
	rackets.job.shot_lefty(rackets, dead)
	if was == "" and rackets.job.outcome == "killed":
		hud.show_notice("Lefty Moran won't be collecting at Lindqvist's again. " + rackets.job.objective().get("text", ""))
	save_game()


func _on_fight_check(hit: bool, _index: int) -> void:
	soundscape.play("fight/punch_landed" if hit else "fight/punch_taken", -2.0)
	var who: Walker = fight_opponent if hit else walker
	var other: Walker = walker if hit else fight_opponent
	if who != null and other != null:
		var away := (who.global_position - other.global_position).normalized()
		who.sprite.position = away * 4.0
		var t := create_tween()
		t.tween_property(who.sprite, "position", Vector2.ZERO, 0.18)


func _on_fight_over(won: bool, results: Array) -> void:
	fighting = false
	if rival != null:
		rival.held = false
	player.set_physics_process(true)
	FightInjuries.apply_to_danny(walker.condition, results, won)
	if fight_opponent != null:
		FightInjuries.apply_to_opponent(fight_opponent.condition, results, won)
	hud.show_notice("You won the fight." if won else "You lost the fight. C shows the damage.")
	var done := _fight_done
	_fight_done = Callable()
	if done.is_valid():
		done.call(won, results)
	save_game()


## M006: how Danny is (C or Esc closes). The world waits meanwhile.
func show_status(on: bool) -> void:
	status_open = on
	get_tree().paused = on
	hud.show_status(on, walker.condition)


## M007: Rourke's job on the map - what next, and the place it concerns.
func _job_on_map() -> void:
	var step := rackets.job.objective()
	var at := Vector2.INF
	var lefty_at := Vector2.INF
	if rackets.job.knows_culprit() and not rival.is_down():
		lefty_at = RIVAL_POST[0]
	match String(step.get("where", "")):
		"lefty":
			at = lefty_at
		"copper_owl", "hardware":
			for pl in hud.minimap.places:
				if pl.id == step.where:
					at = pl.pos
	hud.city_map.set_job(String(step.get("text", "")), at, lefty_at)


func _update_map() -> void:
	var mine := my_car()
	var body := player.body()
	var cops := []
	for o in officers():
		if not o.is_down():
			cops.append(o.body.global_position)
	hud.city_map.set_state(body.global_position, walker.model.facing if player.on_foot() else player.car.model.heading,
		mine.global_position if mine != null and mine != player.car else Vector2.INF, mine.rotation if mine != null else 0.0, cops)


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
	if not paused and stage.update(delta):
		soundscape.resume_music()  # the band counts her back in
		if bird_show != null:
			bird_show.restart()
	_update_clock(delta)
	if not get_tree().paused:
		world.update(player.body().global_position)  # M008: neighbours streamed in and out
	_update_view(delta)
	_update_report(delta)


func _update_view(delta: float) -> void:
	camera.update_camera(delta)
	city.update_view(camera.eye(), camera.eye_height(), camera.view_rect())
	world.update_view(camera.eye(), camera.eye_height(), camera.view_rect())
	interiors.update_player(walker.global_position if player.on_foot() else Vector2.INF)
	for s in streets():
		s.view = camera.view_rect()
	var prompt := ""
	if player.on_foot():
		var spot := _spot()
		var c := player.enterable_car()
		if not spot.is_empty():
			prompt = "E   %s" % ("Interrupt the Bird" if spot.id == "bird" and stage.singing() else spot.prompt)
		elif c != null:
			var i := cars.find(c)
			prompt = "E   Get in your %s" % c.vehicle.params.display_name if thefts.is_dannys(i) \
				else "E   Take the %s (%s)" % [c.vehicle.params.display_name, "taken" if thefts.is_stolen(i) else "not yours"]
	elif player.car.speed() < 30.0:
		prompt = "E   Get out"
	var focus := player.body().global_position
	var door := interiors.door_at(walker.global_position) if player.on_foot() else {}
	var facing := walker.model.facing if player.on_foot() else player.car.model.heading
	var speed := 0.0 if player.on_foot() else player.car.speed() / player.car.model.params.max_speed
	var others := []
	for o in officers():
		if o != officer and not o.is_down():
			others.append({"pos": o.body.global_position, "hunting": o.brain.is_hunting()})
	hud.minimap.other_police = others
	hud.minimap.set_view(focus, facing, speed, officer.body.global_position if not officer.is_down() else Vector2.INF,
		officer.brain.is_hunting(), delta)
	var in_room: InteriorPlan = null
	if player.on_foot() and interiors.current != null and interiors.current.contains(walker.global_position):
		in_room = interiors.current
	markers.update_markers(delta, camera.eye(), camera.eye_height(), focus, in_room,
		door.plan if not door.is_empty() and door.outside else null)
	var here := world.layout_at(focus) if world != null else null
	var place := interiors.current.name if interiors.current != null else (here if here != null else layout).place_name(focus)
	hud.refresh(delta, place, prompt, player.car, get_viewport().get_mouse_position(),
		player.on_foot() and not paused)
	hud.show_gun(walker.gun if player.on_foot() else null)
	if map_open:
		_update_map()
	soundscape.set_speech(opening != null or voice.speaking())
	if opening != null:
		camera.zoom_override = opening.zoom
		# the camera is the listener: the night as it drifts past
		var eye := camera.eye()
		soundscape.update_listener(eye, _room_containing(eye), false, clock.activity(), delta)
	else:
		soundscape.update_listener(focus, interiors.current if player.on_foot() else null, not player.on_foot(),
			clock.activity(), delta)
