extends Node2D
## Composition root: builds the district, parks the cars, puts the player on
## the street at night and wires the modules together through explicit calls
## and signals. No Autoloads. Tests run this scene with a scripted command
## source instead of the keyboard and mouse.

## M009: an incident began, moved on or ended ("started", "phase", "over").
signal incident_event(event: String, incident: Dictionary)
## M012: the game menu asked to go back to the last save (the scene is
## reloaded when it is the running scene; a test listens instead).
signal reload_requested

## M014: the running game's shared parts, handed to the directors (src/main/game.gd).
var game := Game.new()
## Optional command source for tests: func(controller) -> PlayerCommand.
var command_source: Callable
## Override folder for replaceable art (tests); "" = the normal custom/ folder.
var override_root := ""
## Where progress is saved ("" = never; tests and screenshots).
var save_path := SaveGame.DEFAULT_PATH
## Whether a new game (no saved game) begins with Danny's monologue over the
## ward (tests switch it off).
var opening_enabled := true
## M012: whether the people Danny knows call out to him (scene tests switch it
## off unless they are about it, like the opening).
var callouts_enabled := true
## Where the sound levels are kept ("" = never saved; tests and screenshots).
var settings_path := AudioSettings.DEFAULT_PATH

var resolver: AssetResolver:
	get: return game.resolver
	set(v): game.resolver = v
var settings: AudioSettings:
	get: return game.settings
	set(v): game.settings = v
var layout: DistrictLayout:
	get: return game.layout
	set(v): game.layout = v
var city: City:
	get: return game.city
	set(v): game.city = v
var interiors: Interiors:
	get: return game.interiors
	set(v): game.interiors = v
var markers: PlaceMarkers:
	get: return game.markers
	set(v): game.markers = v
## M012: the brass plates at the street doors and the ring under what E would act on.
var plates: EntrancePlates:
	get: return game.plates
	set(v): game.plates = v
var highlight: InteractionHighlight:
	get: return game.highlight
	set(v): game.highlight = v
var overhead: OverheadLine:
	get: return game.overhead
	set(v): game.overhead = v
## M014: talking (src/talk/dialogue.gd), fistfights (src/fight/fights.gd) and the
## people who call out to Danny or keep their own hours (src/people/people.gd).
var dialogue: Dialogue
var fights: Fights
var people: People
## M014: every parked car and what is known about it (src/driving/fleet.gd),
## and the beat cops of every built district (src/police/police_force.gd).
var fleet: Fleet
var police: PoliceForce
var walker: Walker:
	get: return game.walker
	set(v): game.walker = v
var player: PlayerController:
	get: return game.player
	set(v): game.player = v
var camera: CityCamera:
	get: return game.camera
	set(v): game.camera = v
var hud: Hud:
	get: return game.hud
	set(v): game.hud = v
var vehicle_audio: VehicleAudio:
	get: return game.vehicle_audio
	set(v): game.vehicle_audio = v
var soundscape: Soundscape:
	get: return game.soundscape
	set(v): game.soundscape = v
## The people's recorded lines: which first-meeting lines Danny has heard
## (saved), and the player that says them one at a time (M006).
var voice_lines: VoiceLines:
	get: return game.voice_lines
	set(v): game.voice_lines = v
var voice: VoicePlayer:
	get: return game.voice
	set(v): game.voice = v
## The Bird's act on the bandstand and how she moves (M006).
var stage: StageAct:
	get: return game.stage
	set(v): game.stage = v
var bird_show: BirdPerformance:
	get: return game.bird_show
	set(v): game.bird_show = v
## The opening narration while it runs (null otherwise).
var opening: Opening
var _follow_rate := 7.0
var bullets: BulletWorld:
	get: return game.bullets
	set(v): game.bullets = v
var gunfire: GunfireView:
	get: return game.gunfire
	set(v): game.gunfire = v
var navigator: CityNavigator:
	get: return game.navigator
	set(v): game.navigator = v
## M008: the districts of the city in one world: the Riverside Ward (built at
## start-up, pinned) and its neighbours, streamed in as Danny comes near.
var world: DistrictStreamer:
	get: return game.world
	set(v): game.world = v
## M009: the city's own small troubles (they run on the clock wherever Danny is),
## and their people where he can see them.
var incidents: StreetIncidents:
	get: return game.incidents
	set(v): game.incidents = v
var incident_views: IncidentViews
## M009: the people Danny can take his own work from, and their errands.
var opportunity_views: OpportunityViews
## M009: what stepping in brings or costs (cents).
const HUSH_MONEY := 200
const HANDOFF_TAKE := 600
## M008: what belongs to each neighbouring district while it is loaded:
## id -> {street: StreetLife, officer: PoliceOfficer (or null), cars_made: bool}.
var _districts := {}
## Tests: no passers-by or traffic in the neighbouring districts either.
var quiet_streets := false
var officer: PoliceOfficer
## M006: Lefty Moran, the North Side gangster outside Doyle's Garage.
var rival: Rival:
	get: return game.rival
	set(v): game.rival = v
## Named people carried off to the Doc's: id -> the night it happened.
var ward_out := {}
## Times Danny went down (for tests).
var collapses := 0
const RIVAL_POST: Array[Vector2] = [Vector2(1180, 1392), Vector2(1330, 1392)]
var street: StreetLife
@export var police_rules: PoliceRules = preload("res://src/police/default_police.tres")
## The player's handgun.
@export var gun_rules: GunRules = preload("res://src/weapons/default_pistol.tres")
## M010: Eddie's Thompson, on loan (thompson: the gun while Danny has it).
@export var thompson_rules: GunRules = preload("res://src/weapons/thompson.tres")
var thompson: Gun = null
## Danny's own .45 (whichever gun is in his hand).
var pistol: Gun = null
var _kick := Vector2.ZERO
var _shake := 0.0
## Prices and nightly limits of the bootleg trade and the protection racket.
@export var economy_rules: EconomyRules = preload("res://src/economy/default_economy.tres")
## The hours of the night (start, time to go home, dawn) and how fast it runs.
@export var night_rules: NightRules = preload("res://src/night/default_night.tres")
var clock: NightClock:
	get: return game.clock
	set(v): game.clock = v
## Reminders given tonight: 0 none, 1 "get home", 2 "dawn".
var _warned := 0
var paused := false
## M006: the ward map, or the status screen, is open (the world is paused under it).
var map_open := false
var status_open := false
## M011: the gaming room's wheel (single-zero roulette) and its limits; the
## three machines' rules (M011, M013). The back rooms in play: `back_rooms`.
@export var roulette_rules: RouletteRules = preload("res://src/gaming/default_roulette.tres")
@export var slot_rules: Array[SlotRules] = [preload("res://src/gaming/slot_owl.tres"),
	preload("res://src/gaming/slot_bell.tres"), preload("res://src/gaming/slot_star.tres")]
## M014: the Copper Owl's back rooms in play - the card table, Leo's wheel, the
## machines and the gaming room's evening (src/gaming/back_rooms.gd).
var back_rooms: BackRooms
## M010: Rosie's Café (Rourke's job): the scene, and the blast's short film while it plays.
var cafe_scene: CafeScene
var cafe_film: Cinematic
## M012 "After the Last Song": the Bird's scene ("" none tonight; "asking" -
## her last song over, she asks Danny to stay; "film" - the scene playing),
## its film, and how long she waits for an answer.
var bird_film: Cinematic
var bird_scene := ""
var _bird_ask_left := 0.0
## After this hour (1:30 AM) her next song is her last, if Danny is in the club.
const BIRD_LAST_SONG := 25 * 60 + 30.0
## Where she sits after it: the end of the bar.
const BIRD_SEAT := Vector2(2334, 262)
## M010: the police car, the fire engine and the ambulance that come to it.
var emergency := EmergencyResponse.new()
var emergency_views: EmergencyViews
## Doc Pettibone's fee for patching Danny up after he went down (cents, at most).
const COLLAPSE_FEE := 500
## M007: the fistfight's rules (the fights themselves: `fights`).
@export var fight_rules: FightRules = preload("res://src/fight/default_fight.tres")
## M010: the night's weather (Weather), and how it is shown; a state here
## ("clear", "rain", "fog", "rain_fog") holds all night instead of the course
## (tests, screenshots).
@export var weather_override := ""
var weather: Weather:
	get: return game.weather
	set(v): game.weather = v
var weather_view: WeatherView
## M010: Danny's eyes growing heavy towards dawn.
var drowsy: DrowsyView
## M010: sitting down - the seats of each built district, and how fast time
## passes while he sits with Space held (game minutes per game minute).
const FAST_TIME := 20.0
var _seats := {}
const FIGHT_TIP_BONUS := 14.0
const FIGHT_HURT_PACE := 0.85
## The sound level chosen on the pause screen (index into AudioSettings.BUSES).
var sound_row := 0
var rackets: Rackets:
	get: return game.rackets
	set(v): game.rackets = v
var talk: Conversations:
	get: return game.talk
	set(v): game.talk = v
var _saved := {}


func _init() -> void:
	game.root = self
	game.voice_lines = VoiceLines.new()
	game.stage = StageAct.new()


func _ready() -> void:
	CityInput.ensure_actions()
	game.police_rules = police_rules
	game.gun_rules = gun_rules
	game.thompson_rules = thompson_rules
	game.economy_rules = economy_rules
	game.night_rules = night_rules
	game.roulette_rules = roulette_rules
	game.slot_rules = slot_rules
	game.fight_rules = fight_rules
	settings = AudioSettings.new(settings_path)
	settings.load_settings()
	settings.apply()
	resolver = AssetResolver.new(override_root)
	rackets = Rackets.new(economy_rules)
	clock = NightClock.new(night_rules)
	rackets.town.night_minutes = float(night_rules.dawn_minute - night_rules.start_minute)
	talk = Conversations.new(rackets)
	dialogue = Dialogue.new(game)  # M014: talking in the game
	game.dialogue = dialogue
	dialogue.on_sleep = sleep
	people = People.new(game)  # M014: call-outs and routines
	game.people = people
	people.is_out = func(id: String) -> bool: return ward_out.has(id)
	fights = Fights.new(game)  # M014: fistfights
	game.fights = fights
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
	plates = EntrancePlates.new()
	add_child(plates)
	plates.setup(resolver)
	plates.add_district(layout, plates)
	highlight = InteractionHighlight.new()
	add_child(highlight)
	highlight.setup()
	overhead = OverheadLine.new()
	add_child(overhead)
	overhead.setup(load(Hud.FONT_PATH))
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
	weather = Weather.new()
	weather.begin_night(rackets.night, float(night_rules.start_minute))
	weather.force(weather_override)
	back_rooms = BackRooms.new(game)  # M014: the card game's state early, as M010 had it
	back_rooms.name = "BackRooms"
	game.back_rooms = back_rooms
	back_rooms.load_poker(_saved.get("poker", {}), rackets.night)
	fleet = Fleet.new(game)  # M014: the parked cars and their owners
	game.fleet = fleet
	fleet.park(layout)
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
	player.setup(walker, fleet.cars, world)
	pistol = walker.gun
	player.carry(pistol, resolver.get_texture(gun_rules.look))
	if rackets.loan.out:
		_arm_thompson(true)  # M010: still on loan from Eddie
	for v in interiors.views:
		v.visitors = [walker]
	bullets = BulletWorld.new()
	bullets.name = "Bullets"
	add_child(bullets)
	player.bullets = bullets
	gunfire = GunfireView.new()
	add_child(gunfire)
	gunfire.setup(resolver, bullets)
	player.fired.connect(func(muzzle: Vector2, dir: Vector2) -> void:
		gunfire.on_fired(muzzle, dir, walker.gun.rules.sound)
		if walker.gun.rules.automatic:
			_kick -= dir * 2.2)  # M010: the Thompson climbs and shakes the view a little
	player.gun_event.connect(gunfire.on_gun_event)
	player.gun_event.connect(func(e: String, _at: Vector2) -> void:
		if e == "empty" and walker.gun == thompson:
			hud.show_notice("Click. The Thompson's dry. Eddie loads her again when she's back home.")
		elif e == "empty":
			hud.show_notice("Click. Out of rounds. Eddie sells them, in the back of Lindqvist Hardware.")
		elif e == "switched":
			hud.show_notice("The Thompson in your hands." if walker.gun == thompson else "Your .45 in your hand."))
	bullets.impact.connect(gunfire.on_impact)
	bullets.impact.connect(func(_p: Vector2, _n: Vector2, _c: Object, _d: Vector2) -> void:
		people.gunfire())  # M012: nobody calls out with guns going off
	player.fired.connect(func(_m: Vector2, _d: Vector2) -> void: people.gunfire())
	navigator = CityNavigator.new(layout, Walker.RADIUS + 3.0)
	world.adopt(layout.id, city, navigator)
	officer = PoliceOfficer.new()
	add_child(officer)
	officer.setup(resolver, police_rules, layout.police_beat, navigator, player.body, bullets)
	police = PoliceForce.new(game, streets)  # M014: the beat cops of every built district
	game.police = police
	police.add_ward_officer(officer)
	bullets.struck.connect(police.bullet_struck)
	player.fired.connect(_on_player_fired)
	street = StreetLife.new()
	add_child(street)
	street.setup(layout, resolver, clock, Fleet.CAR_SCENE, Fleet.VEHICLES, fleet.cars, [walker, officer.body] as Array[Walker])
	street.view = camera.view_rect()
	rival = Rival.new()
	add_child(rival)
	rival.setup(resolver, gun_rules, RIVAL_POST, navigator, bullets, player.body)
	rival.danny = walker
	rival.fired.connect(gunfire.on_fired)
	rival.fired.connect(func(muzzle: Vector2, _dir: Vector2) -> void:
		police.hear_gunshot(muzzle, gun_rules.noise_radius)
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
	interiors.rooms_added.connect(_wire_rooms)  # M012: rooms in the streamed districts
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
	back_rooms.sync_card_players()  # M010: Moe comes in late
	hud = Hud.new()
	add_child(hud)
	hud.setup(resolver, layout.name)
	hud.add_minimap(layout)
	hud.game_menu.action.connect(menu_action)  # M012: a click in the menu
	incident_views = IncidentViews.new()
	add_child(incident_views)
	incident_views.setup(resolver, incidents, load(Hud.FONT_PATH))
	incident_views.is_shown = world.is_ready
	incident_views.officer_for = police.officer_of
	incident_views.person_struck.connect(func(id: String) -> void: _end_incident(incidents.break_off(id, "shooting")))
	incident_views.process_mode = Node.PROCESS_MODE_PAUSABLE
	drowsy = DrowsyView.new()  # M010
	add_child(drowsy)
	drowsy.setup()
	weather_view = WeatherView.new()  # M010
	add_child(weather_view)
	weather_view.setup(weather, resolver.get_texture("fx/fog"))
	cafe_scene = CafeScene.new()  # M010
	add_child(cafe_scene)
	cafe_scene.setup(world.layouts.halloran, resolver, rackets.cafe)
	emergency_views = EmergencyViews.new()
	add_child(emergency_views)
	emergency_views.setup(resolver, emergency)
	emergency_views.fire_out.connect(cafe_scene.extinguish)
	opportunity_views = OpportunityViews.new()
	opportunity_views.setup(resolver, rackets)
	opportunity_views.is_out = func(id: String) -> bool: return ward_out.has(id)
	opportunity_views.contact_hurt.connect(_on_contact_hurt)
	opportunity_views.contact_down.connect(func(id: String, _w: Walker) -> void:
		ward_out[id] = rackets.night
		if dialogue.talking == id:
			dialogue.end()
		hud.show_notice("%s goes down, badly hurt. Somebody runs for the Doc." % talk.speaker(id)))
	var morgue := layout.building_named("The Morgue")
	if morgue >= 0:
		hud.city_map.add_landmark(layout.buildings[morgue].rect.get_center(), "The Morgue", resolver.get_texture("ui/marker_morgue"))
	# M008: the neighbouring districts on the maps, painted from their plans (not built)
	for id in world.order:
		if id != layout.id:
			hud.minimap.add_district(world.layouts[id])
	hud.city_map.refresh_districts()
	player.interaction = _interact
	player.conversation = dialogue.converse
	hud.dialogue_choice.connect(dialogue.answer)
	_wire_dialogue()
	add_child(back_rooms)  # M014: the tables, the room and their screens (where the room's lines were)
	back_rooms.setup(_saved.get("slots", []))
	_show_purse()
	player.entered_car.connect(fleet.entered)
	player.exited_car.connect(fleet.exited)
	player.notice.connect(hud.show_notice)
	police.wire_hud(officer)
	# Esc must still work while the world is paused: the root always runs,
	# the world itself stops.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for node in [city, interiors, walker, camera, player, vehicle_audio, soundscape, voice, bullets, gunfire, officer, street, rival, world] + fleet.cars:
		(node as Node).process_mode = Node.PROCESS_MODE_PAUSABLE
	if not command_source.is_valid():
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_resume_place()  # M012: a game saved mid-night goes on where and when it was saved
	_update_view(0.0)
	if opening_enabled and _saved.is_empty():
		_start_opening()


## M012: the people of the city, a little more alive: who is where at this
## hour (Routines), the Bird's last song, and who calls out to Danny
## (Callouts) - checked a few times a second, never every person every frame.
func _people_update(delta: float) -> void:
	people.apply_routines()
	_bird_after_last_song(delta)
	people.update_callouts(delta, callouts_enabled, _busy)


## What Danny is in the middle of, for whoever might call out to him (M012).
func _busy() -> Dictionary:
	return {"talking": dialogue.talking != "", "busy": back_rooms.at_a_table() or not player.seat.is_empty(),
		"film": cafe_film != null or opening != null or bird_film != null or bird_scene != "", "fighting": fights.fighting,
		"menu": paused or map_open or status_open}


## M014: what a talk's pages do, each to the part of the game that owns it (in
## the order M003-M012 applied them), and what happens as a talk ends.
func _wire_dialogue() -> void:
	dialogue.on_context(func() -> Dictionary: return {"crate_outside": fleet.crate_car_at(_novak_door()) != null})
	dialogue.on_effect("incident", func(v: Variant, _e: Dictionary) -> void: _step_in(String(v)))
	dialogue.on_effect("opportunity", func(v: Variant, _e: Dictionary) -> void: _opportunity(String(v)))
	dialogue.on_effect("fight", func(v: Variant, _e: Dictionary) -> void: _request_fight(String(v)))  # starts when Danny raises his fists
	dialogue.on_effect("bird_scene", func(v: Variant, _e: Dictionary) -> void: _bird_said(String(v)))  # M012: what he told the Bird
	dialogue.on_effect("freight", func(v: Variant, _e: Dictionary) -> void: _freight_effect(String(v)))  # M012: Freight Doesn't Walk
	dialogue.on_effect("job", func(_v: Variant, _e: Dictionary) -> void: _job_step())
	dialogue.on_effect("heal", func(v: Variant, _e: Dictionary) -> void: _healed(v))
	dialogue.on_effect("rounds", func(v: Variant, _e: Dictionary) -> void:
		if pistol != null:
			pistol.add_spare(int(v)))
	dialogue.on_effect("thompson", func(v: Variant, _e: Dictionary) -> void: _thompson_effect(String(v)))  # M010
	dialogue.on_effect("parcel", func(_v: Variant, _e: Dictionary) -> void: _show_purse())
	dialogue.on_effect("cafe", func(v: Variant, _e: Dictionary) -> void:
		if String(v) == "reported":
			_show_purse())
	dialogue.on_effect("police", func(v: Variant, _e: Dictionary) -> void:
		if v and interiors.current != null:
			# the shopkeeper waits until you have gone, then runs out for the copper
			police.report_after(interiors.current, talk.speaker(dialogue.talking)))
	dialogue.on_end(fights.talk_ended)  # M007: a fight agreed in the talk starts
	dialogue.on_end(_bird_talk_ended)  # the band counts her back in; M012: her question walked away from


func _job_step() -> void:
	var step := rackets.job.objective()
	if not step.is_empty():
		hud.show_notice(step.text)


func _healed(v: Variant) -> void:
	if v:
		walker.condition.heal_all()
		hud.show_notice("Patched up. Good as new, near enough.")


func _thompson_effect(what: String) -> void:
	match what:
		"lent":
			_arm_thompson(true)
			hud.show_notice("Eddie's Thompson is under your coat. Tab takes it in hand.")
		"returned":
			_arm_thompson(false)


## M007, M012: a fight agreed in a talk (Lefty, Walt), started when the talk ends.
func _request_fight(who: String) -> void:
	var start_it: Callable = {"lefty": _fight_lefty, "walt": _fight_walt}.get(who, Callable())
	fights.request(who, start_it)


func _bird_talk_ended(who: String) -> void:
	if who == "bird":
		stage.release()
	if who == "bird_scene" and bird_film != null:
		if rackets.bird_scene == "":
			_bird_said("silent")  # walked away from her question: that is an answer too
		bird_film.release()  # the bars slide away, the camera comes back


## M012: a person's ring is wider than his figure (drawn under it).
const PERSON_RING := 24.0


## M012: what the ring goes under - the thing E would act on now (the spot
## the prompt names, or the car he would get into) - or {} for nothing.
func _highlight_for(spot: Dictionary, c: Car) -> Dictionary:
	if spot.is_empty():
		if c != null and not _scenery_truck_near(walker.global_position):
			return {"kind": "car", "xform": c.global_transform, "size": c.vehicle.size}
		return {}
	var id := String(spot.id)
	match id:
		"door":
			var plan: InteriorPlan = spot.plan
			var i: int = spot.index
			var side: Vector2 = plan.doors[i].side
			var centre := plan.door_centre(i) + side * InteriorPlan.WALL * 0.5
			var along := side.orthogonal() * float(plan.doors[i].width) * 0.5
			return {"kind": "door", "a": centre - along, "b": centre + along}
		"locked":
			return {"kind": "ring", "pos": spot.pos, "radius": 13.0, "cold": String(spot.get("talk", "")) == ""}
		"lefty":
			return {"kind": "ring", "pos": rival.body.global_position, "radius": PERSON_RING}
		"seat":
			return {"kind": "ring", "pos": spot.seat.pos, "radius": 16.0}
		"stand":
			return {}
		"plant":
			return {"kind": "ring", "pos": cafe_scene.car_pos, "radius": 30.0}
	if spot.get("kind", "") == "contact":
		var w := opportunity_views.contact(id)
		return {"kind": "ring", "pos": w.global_position, "radius": PERSON_RING} if w != null else {}
	if interiors.current != null:
		var person := interiors.person(interiors.current.id, id)
		if person != null:
			return {"kind": "ring", "pos": person.global_position, "radius": PERSON_RING}
	if spot.has("pos"):
		return {"kind": "ring", "pos": spot.pos, "radius": 12.0}
	return {}


## M012: a streamed district's rooms were built: whoever may push their doors,
## who goes down in them, and who is out tonight (from the save or from earlier).
func _wire_rooms(new_views: Array) -> void:
	for nv in new_views:
		var v: InteriorView = nv
		if walker != null:
			v.visitors = [walker]
		v.person_down.connect(_on_person_down.bind(v))
		var still := _still_out(v.plan)
		if not still.is_empty():
			v.reset_people(still)
	interiors.update_player(player.body().global_position if player != null and player.on_foot() else Vector2.INF)
	interiors.snap()
	_sync_freight()  # the shed as the job left it


## M012: who in a room is out tonight: the named people carried off (by id)
## and anybody else struck down there (by room and id).
func _still_out(plan: InteriorPlan) -> Array:
	var out := []
	for p in plan.people:
		if ward_out.has(p.id) or ward_out.has(plan.id + "/" + String(p.id)):
			out.append(p.id)
	return out


## M012: where and when the game was saved, if it was this same night: the
## clock set back to that minute, the district built and Danny put back - in
## the street or inside a room, in any district. (A game saved at the start
## of a night - after sleeping - begins at home as always.)
func _resume_place() -> void:
	var place: Dictionary = _saved.get("place", {})
	if place.is_empty() or int(place.get("night", -1)) != rackets.night:
		_crate_without_a_car()
		return
	var at := Vector2(float(place.get("x", 0.0)), float(place.get("y", 0.0)))
	var seat: Car = null
	var saved_cars: Dictionary = _saved.get("cars", {})
	if saved_cars.is_empty() or int(saved_cars.get("night", -1)) != rackets.night:
		_crate_without_a_car()
	else:
		seat = fleet.restore(saved_cars, layout.id)  # M013: the cars where they stood; the one he sat in
		_crate_without_a_car()
	if seat != null:
		at = seat.global_position  # in his car (put back at its own place if it could not stand where it was saved)
	var id := world.district_at(at)
	if id == "":
		return
	clock.set_time(float(place.get("minute", clock.minute)))
	if id != layout.id:
		world.load_now(id)
	walker.place(at, float(place.get("facing", 0.0)))
	if seat != null and not seat.has_meta("away"):
		fleet.restoring = true
		player.enter(seat)  # behind the wheel, the engine running, standing still
		fleet.restoring = false
	interiors.update_player(at if seat == null else Vector2.INF)
	interiors.snap()
	camera.snap_to(walker if seat == null else seat)


## M013: a game saved before the cars were (or with no car carrying it): Dutch's
## crate loaded into a boot that is not there any more goes back to the kerb, to
## be loaded again, rather than being lost.
func _crate_without_a_car() -> void:
	if rackets.opportunities.crate == "loaded" and not fleet.any_cargo():
		rackets.opportunities.crate = "taken"


## Danny fired: every beat cop in earshot hears it (and takes a close one
## personally), passers-by scatter.
func _on_player_fired(muzzle: Vector2, dir: Vector2) -> void:
	police.player_fired(muzzle, dir)
	for s in streets():
		s.hear_gunshot(muzzle)
	if incident_views != null:
		for e in incident_views.hear_gunshot(muzzle):  # M009: they break off and run
			_end_incident(e)


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
	return [_district_street.bind(l, node), fleet.district_cars.bind(l)]


func _district(id: String) -> Dictionary:
	if not _districts.has(id):
		_districts[id] = {"street": null, "officer": null, "cars_made": false}
	return _districts[id]


func _district_street(l: DistrictLayout, node: Node2D) -> void:
	var s := StreetLife.new()
	node.add_child(s)
	var others: Array[Walker] = [walker]
	for o in police.officers():
		others.append(o.body)
	s.setup(l, resolver, clock, Fleet.CAR_SCENE, Fleet.VEHICLES, fleet.cars, others)
	s.name = "StreetLife"
	if quiet_streets:
		s.clear()
	s.view = camera.view_rect()
	soundscape.track_traffic(s.traffic)
	_district(l.id).street = s


## A district is complete: the camera may show it, the cars parked in it come
## back out, and its beat cop takes up his round (or lies where he fell
## tonight, if Danny shot him).
func _on_district_ready(id: String) -> void:
	camera.set_bounds(world.bounds())
	if id == layout.id:
		return
	var l: DistrictLayout = world.layouts[id]
	fleet.district_ready(l)
	opportunity_views.district_ready(id, l, world.loaded[id].node)  # M009
	interiors.add_district(l, world.city_of(id), world.loaded[id].node)  # M012: its rooms
	plates.add_district(l, world.loaded[id].node)  # and the plates at its doors
	if l.police_beat.is_empty():
		return
	var o := PoliceOfficer.new()
	world.loaded[id].node.add_child(o)
	o.setup(resolver, police_rules, l.police_beat, world.navigator_of(id), player.body, bullets)
	o.home_area = l.play_area
	police.wire(o)
	police.wire_hud(o)
	var st: Dictionary = world.state.get(id, {})
	var past: Dictionary = st.get("officer", {})
	if past.get("down", false) and int(past.get("night", -1)) == rackets.night:
		o.body.place(past.pos, 0.0)
		o.body.condition.damage["torso"] = BodyCondition.MAX
		o.body.down = true
		o.body.lie_down()
		o.torch.visible = false
	_district(id)
	police.set_district_officer(id, o)
	for s in streets():
		if not s.others.has(o.body):
			s.others.append(o.body)


## A district is about to be freed: remember whether its beat cop is down
## tonight, put away the cars parked in it (not the one Danny drives) and
## let go of bullets still flying there.
func _on_district_unloading(id: String) -> void:
	interiors.remove_district(id)  # M012: its rooms go with it
	people.district_unloading(id)  # M012: Leon at Dutch's goes with the yards, a call-out with its room
	plates.remove_district(id)
	if not _districts.has(id):
		return
	var e: Dictionary = _districts[id]
	var o: PoliceOfficer = police.district_officer(id)
	if o != null and is_instance_valid(o):
		if not world.state.has(id):
			world.state[id] = {}
		world.state[id]["officer"] = {"down": o.is_down(), "pos": o.body.global_position, "night": rackets.night}
		for s in streets():
			s.others.erase(o.body)
	police.set_district_officer(id, null)
	e.street = null
	var b: Rect2 = world.layouts[id].bounds
	fleet.district_unloading(b)
	if incident_views != null:
		incident_views.drop_district(b)  # its incidents go on as state
	if opportunity_views != null:
		opportunity_views.district_gone(id)
	bullets.drop_in(b)
	camera.set_bounds.call_deferred(world.bounds())


func _on_district_entered(id: String) -> void:
	var l: DistrictLayout = world.layouts[id]
	if hud != null:
		hud.set_district(l.name)
	if soundscape != null:
		soundscape.layout = l


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


## The interaction spot the player stands at (on foot): someone to talk to or
## the bed inside a room, else a door to go in or out by; {} when none.
## M006: nobody to talk to who is down or carried off; Lefty in the street.
func _spot() -> Dictionary:
	if not player.on_foot():
		return {}
	# M012: the Bird off the bandstand, asking him to stay (before the room's own spots)
	if bird_scene == "asking" and bird_show != null and walker.global_position.distance_to(bird_show.bird.global_position) < 60.0:
		return {"id": "bird_scene", "prompt": "Stay a minute with the Bird", "pos": bird_show.bird.global_position}
	if interiors.current != null:
		var s := interiors.current.spot_at(walker.global_position)
		if not s.is_empty() and (s.id == "bed" or s.id == "poker" or Conversations.is_readable(s.id) or interiors.view_of(interiors.current.id).person_ok(s.id)):
			return s
		if not s.is_empty() and (s.id == "roulette" or String(s.id).begins_with("slot_")):
			return s  # M011: the wheel (whether Leo is there to spin it is said when you step up), the machines
	if rival != null and not rival.is_down() and not rival.is_hostile() \
			and walker.global_position.distance_to(rival.body.global_position) < 40.0:
		return {"id": "lefty", "prompt": "Talk to Lefty Moran"}
	# M010: sitting: up again, or a seat to sit on
	if not player.seat.is_empty():
		return {"id": "stand", "prompt": "Stand up      Space (hold)   Let the time pass"}
	var seat := Seats.near(_seats_near(), walker.global_position)
	if not seat.is_empty():
		return {"id": "seat", "seat": seat, "prompt": "Sit down"}
	# M010: Duggan's Packard, with the parcel in Danny's coat
	if cafe_scene != null and rackets.parcels > 0 and rackets.cafe.stage == CafeJob.Stage.ACCEPTED \
			and cafe_scene.near_car(walker.global_position):
		return {"id": "plant", "prompt": "Slip the parcel under the Packard"}
	# M012: Leon at Dutch's counter, his coffee after midnight
	var leon := people.leon_spot(walker.global_position)
	if not leon.is_empty():
		return leon
	# M009: Dutch, Mr. Feeney and their errands
	var op := opportunity_views.near(walker.global_position) if opportunity_views != null else {}
	if not op.is_empty():
		op["prompt"] = {"dutch": "Talk to Dutch", "feeney": "Talk to Mr. Feeney", "crate": "Load the crate into a car",
			"film_can": "Pick up the film can"}.get(op.id, "Talk")
		return op
	# M009: one of the city's incidents going on right here
	var inc := incident_views.incident_near(walker.global_position, 48.0) if incident_views != null else {}
	if not inc.is_empty() and inc.mercer == "" and inc.phase < (StreetIncidents.PHASES[inc.kind] as Array).size() - 1:
		return {"id": "incident", "incident": inc.id,
			"prompt": {"argument": "Step in", "exchange": "Walk over", "stop": "Have a word with the officer"}[inc.kind]}
	var door := interiors.door_at(walker.global_position)
	if not door.is_empty():
		door["id"] = "door"
		return door
	# M011: a door shut for the night that can be tried (City Hall, the mayor's gate, the aldermen)
	var here := world.layout_at(walker.global_position) if world != null else layout
	var locked := here.locked_door_at(walker.global_position) if here != null else {}
	if not locked.is_empty():
		return {"id": "locked", "prompt": locked.prompt, "text": locked.text, "talk": locked.get("talk", ""), "pos": locked.pos}
	return door


## E on foot at a spot: talk to whoever is there (or go to bed). Returns true when used.
func _interact(_at: Vector2) -> bool:
	var spot := _spot()
	if spot.is_empty():
		if player.enterable_car() == null and _scenery_truck_near(walker.global_position):
			# M010: the yards' works trucks are scenery; say so, and where a truck can be had
			hud.show_notice("The cab's chained and padlocked for the night. Brennan's coal truck on Wharf Street is another story.")
			return true
		return false
	if spot.id == "door":
		soundscape.play_door(spot.plan)
		interiors.step_through(walker, spot)
	elif spot.id == "bird":
		talk_to_bird()
	elif spot.id == "lefty":
		rival.body.aim_point = walker.global_position
		dialogue.open("lefty")
	elif spot.id == "seat":
		player.sit(spot.seat)
	elif spot.id == "poker":
		back_rooms.open_poker()
	elif spot.id == "roulette":
		back_rooms.open_roulette()
	elif String(spot.id).begins_with("slot_"):
		back_rooms.open_slot(int(String(spot.id).substr(5)))
	elif spot.id == "plant":
		_plant_parcel()
	elif spot.id == "locked" and spot.talk != "":
		dialogue.start(spot.talk)  # M012: the bell at the Mayor's gate brings someone down the path
	elif spot.id == "locked":
		soundscape.play("places/door", -10.0)  # the handle rattles; nobody comes
		hud.show_notice(spot.text)
	elif spot.id == "stand":
		player.stand()
	elif spot.get("routine", false):
		dialogue.start(spot.id)  # M012: Leon at Dutch's
	elif spot.id == "bird_scene":
		_start_bird_film()
	elif spot.get("kind", "") == "contact":
		var w := opportunity_views.contact(spot.id)
		if w != null:
			w.aim_point = walker.global_position
		dialogue.open(spot.id)
	elif spot.get("kind", "") == "errand":
		_take_errand(spot.id, spot.pos)
	elif spot.id == "incident":
		dialogue.incident_talking = spot.incident
		dialogue.open("incident")
	elif spot.id == "bed" or Conversations.is_readable(spot.id) or not interiors.current.person(spot.id).is_empty():
		dialogue.start(spot.id)
	return true


## E at the Bird's microphone: if she is singing, the needle scratches off the
## record, the song stops and she gives Danny a piece of her mind; between
## songs she just waits for him. Either way they talk, and when he walks away
## the band counts her back in.
func talk_to_bird() -> void:
	var interrupted := stage.interrupt()
	if interrupted:
		soundscape.interrupt_music()
		rackets.memory.remember("bird", "interrupted", rackets.night)  # M012: she remembers who stopped her song
	else:
		stage.hold()
	dialogue.start("bird", {"interrupted": interrupted})


## M010: Eddie's Thompson goes under Danny's coat (on loan, with its own
## rounds) or back to Eddie (the .45 in hand again).
func _arm_thompson(on: bool) -> void:
	var look := resolver.get_texture(thompson_rules.look)
	if on and thompson == null:
		thompson = Gun.new(thompson_rules)
		thompson.ammo = clampi(rackets.loan.ammo, 0, thompson_rules.magazine)
		thompson.spare = maxi(0, rackets.loan.spare)
		player.carry(thompson, look)
	elif not on and thompson != null:
		player.carry(thompson, look, false)
		thompson = null


## The purse in the corner, with what Danny carries besides (M010: the parcel).
func _show_purse() -> void:
	game.show_purse()


## M010: the parcel goes under Duggan's Packard. A copper who could see the
## car from where he stands saw Danny at it (a credible reason to suspect him
## later); otherwise nobody knows who did it. The quarter hour starts.
func _plant_parcel() -> void:
	var at := cafe_scene.car_pos
	var witnessed := police.saw_danny_at(at)
	if not rackets.plant_parcel(clock.minute, witnessed):
		return
	moments.append(rackets.cafe.due(rackets.night))  # sitting and letting the time pass slows for it
	_show_purse()
	hud.show_notice("You stoop by the running board as if to tie a shoelace, and stand up without the parcel. "
		+ "A quarter of an hour, Eddie said. Somewhere to watch from - not too close.")
	save_game()


## M010: the quarter hour is up. Danny near enough to see it (and free to):
## the short film; otherwise it simply goes off, and he hears it if he is close.
func _cafe_due() -> void:
	var at := cafe_scene.car_pos
	var me := player.body().global_position
	if not rackets.cafe_blasted(clock.minute):
		return
	moments.erase(rackets.cafe.blast_minute)
	var watching := me.distance_to(at) <= CafeJob.WATCH and opening == null and not fights.fighting \
		and not hud.poker_view.is_open() and (interiors.current == null or not player.on_foot())
	if watching:
		_start_cafe_film(at)
	else:
		_cafe_goes_off()
		if me.distance_to(at) <= 2600.0:
			hud.show_notice("A heavy boom rolls over the rooftops from somewhere toward Halloran Square.")


## The short film (in the game itself, like the opening): bars in, the camera
## leaves Danny for the café across the avenue, a hush, the flash, the street
## shaking, the people spilling out, and back to Danny as a siren starts up.
func _start_cafe_film(at: Vector2) -> void:
	dialogue.end()
	player.passing_time = false  # the night goes at its own pace while it plays
	var me := player.body().global_position
	var z := camera.zoom.x
	var keys := [
		{"t": 0.0, "pos": me, "zoom": z},
		{"t": 2.6, "pos": at.lerp(me, 0.25), "zoom": z * 1.25},
		{"t": 4.2, "pos": at, "zoom": z * 1.4},
		{"t": 6.0, "pos": at + Vector2(0, -20), "zoom": z * 1.2},
		{"t": 9.5, "pos": at.lerp(me, 0.2), "zoom": z * 1.1},
		{"t": 12.0, "pos": me, "zoom": z},
	]
	var captions := [
		{"t": 0.3, "text": "Through Rosie's window Vince Duggan is on his second cup, his back to the street."},
		{"t": 2.8, "text": "Marlowe Avenue goes quiet. Somewhere a streetcar bell. A dog."},
		{"t": 4.0, "text": ""},
		{"t": 5.2, "text": "Every window on the block comes in at once."},
		{"t": 7.6, "text": "Duggan comes out with his napkin still tucked in his collar. He doesn't say a word."},
		{"t": 10.2, "text": "Over toward Halloran Avenue, a siren starts up."},
	]
	var cues := [{"t": 3.4, "id": "hush"}, {"t": 4.0, "id": "blast"}, {"t": 10.0, "id": "siren"}]
	cafe_film = Cinematic.new()
	add_child(cafe_film)
	cafe_film.start(keys, captions, cues, load(Hud.FONT_PATH))
	cafe_film.cue.connect(_on_film_cue)
	cafe_film.finished.connect(_end_cafe_film)
	hud.visible = false
	markers.visible = false
	player.set_physics_process(false)
	walker.move = Vector2.ZERO
	_follow_rate = camera.follow_rate
	camera.follow_rate = 3.0
	camera.target = cafe_film.rig


func _on_film_cue(id: String) -> void:
	match id:
		"hush":
			soundscape.set_duck(true)
		"blast":
			soundscape.set_duck(false)
			cafe_film.white_flash(0.85)
			_shake = 1.0
			_cafe_goes_off()


func _end_cafe_film() -> void:
	hud.visible = true
	markers.visible = true
	player.set_physics_process(true)
	camera.target = player.body()
	camera.follow_rate = _follow_rate
	camera.zoom_override = 0.0
	soundscape.set_duck(false)
	cafe_film.queue_free()
	cafe_film = null
	save_game()


## It goes: the flash and the fire, the street scatters, the coppers in
## earshot come running (the one who saw Danny at the car goes after him),
## and anyone standing too close is hurt.
func _cafe_goes_off() -> void:
	var at := cafe_scene.car_pos
	cafe_scene.play_blast()
	_dispatch_emergency(at)
	for s in streets():
		s.hear_gunshot(at)
	for o in police.officers():
		if o.is_down() or o.body.global_position.distance_to(at) > 1600.0:
			continue
		if rackets.cafe.seen:
			o.brain.suspect(walker.global_position)  # he saw Danny at the car: a credible reason
		else:
			o.duty = {"pos": at + Vector2(-70, 70), "face": at}  # he comes to look at it, nobody to blame
	if player.on_foot() and walker.global_position.distance_to(at) <= CafeJob.DANGER:
		rackets.cafe.caught_in_it = true
		walker.condition.hurt("torso", 30)
		walker.condition.hurt("left_arm", 20)
		walker.hurt.emit("torso", walker.condition.level("torso"))
	save_game()


## M010: the police car, the fire engine and the ambulance set off for the
## scene along Marlowe Avenue (one after the other) and stay there tonight.
func _dispatch_emergency(at: Vector2) -> void:
	var h: DistrictLayout = world.layouts.halloran
	var stops := {}
	for id in ["police", "fire", "ambulance"]:
		stops[id] = h.cafe_point("stop_" + id).pos
	emergency.dispatch(rackets.night, clock.minute, at, EmergencyResponse.routes_for(h.cafe_point("approach").pos, stops))


## M006: Danny is hit. Where, and how bad, on screen.
func _on_danny_hurt(region: String, level: int) -> void:
	player.stand()  # M010: nobody stays sitting when he is hit
	back_rooms.danny_hurt()  # M011: nor at the wheel, nor at a machine
	hud.show_notice("Hit in the %s - %s." % [BodyCondition.NAMES[region], BodyCondition.label(level)])


## M006: Danny goes down. He is not killed: somebody drags him to Doc
## Pettibone's, and he comes to on the examining table an hour later, patched
## up in a hurry (his wounds are grazes now), the Doc's fee taken from his
## pocket (as far as it goes). The night goes on.
func _danny_down() -> void:
	collapses += 1
	dialogue.end()
	if not player.on_foot():
		player.eject()  # M008: shot at the wheel
	police.stand_down()  # he thinks he got you
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
	back_rooms.person_down(view.plan.id, id, named)  # M010-M013: the tables
	if not named:
		ward_out[view.plan.id + "/" + id] = rackets.night  # M012: stays down tonight, whatever is unloaded or loaded
		return
	ward_out[id] = rackets.night
	if w != null and w.last_shooter == walker:
		rackets.shot_person(id)
	if id == "bird":
		stage.knock_out()
		soundscape.stop_music()
	if dialogue.talking == id:
		dialogue.end()
	hud.show_notice("%s goes down, badly hurt. Somebody runs for the Doc." % talk.speaker(id))
	save_game()


## Sleeps through the day: the next evening begins at home with everything
## you carry (money, bottles, rounds); the streets, the cars and the copper
## are back as they are at the start of every night, and tonight's deals reset.
func sleep() -> void:
	dialogue.end()
	stage.reset()  # the Bird is singing when the club opens
	if bird_show != null:
		bird_show.off_stage = false  # M012: back at her microphone
	bird_scene = ""
	var owl := interiors.view_of("copper_owl")
	if owl != null:
		owl.dim(1.0)  # the house lights up for a new night
	ward_out.clear()  # back from the Doc's, patched up (and they remember)
	fleet.new_night()  # the cars are back with their owners, nothing in a boot (M009)
	for v in interiors.views:
		v.reset_people()
	rival.reset()
	walker.condition.rest()  # grazes heal overnight; wounds wait for the Doc
	rackets.end_night()
	clock.reset()
	incidents.begin_night(rackets.night, float(night_rules.start_minute), float(night_rules.dawn_minute))
	weather.begin_night(rackets.night, float(night_rules.start_minute))
	weather.force(weather_override)
	rackets.money += back_rooms.begin_night(rackets.night)  # M010-M013: fresh money at the tables, the wheel's cover off
	moments.clear()
	emergency.clear()  # the street is cleared by morning
	_warned = 0
	police.cancel_report()
	fleet.back_to_places()
	police.new_night()
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
		clock.advance(delta * _time_scale())
		rackets.town.advance(clock.minute - before)  # the club serves its customers as the night goes on
		_advance_incidents()
		weather.advance(clock.minute)  # M010
		var claps := weather.thunder_between(before, clock.minute)  # M012: thunder in a downpour
		if not claps.is_empty():  # one at a time, however fast the night runs
			soundscape.thunder(claps[-1].near)
			weather_view.lightning(claps[-1].near)
		for e in rackets.opportunities.advance(clock.minute):  # M009: too late is too late
			_opportunity_over(e)
		if rackets.freight.advance(rackets, clock.minute) == "lapsed":  # M012: the truck came; Leon sorted it himself
			_sync_freight()
			save_game()
		if cafe_scene != null:  # M010: Rosie's Café
			cafe_scene.job = rackets.cafe
			if clock.minute >= rackets.cafe.due(rackets.night) and cafe_film == null:
				_cafe_due()
			cafe_scene.refresh(rackets.night, clock.minute)
			emergency_views.update(rackets.night, clock.minute, delta)
	if clock.minute >= float(night_rules.home_minute):
		back_rooms.closing_time()  # M010: the card game breaks up at the hour to go home; M013: the wheel's last round
	if clock.is_dawn() and _warned < 2:
		_warned = 2
		hud.show_notice("Dawn's breaking. Get home to bed before the city wakes up.")
	elif clock.is_late() and _warned < 1:
		_warned = 1
		hud.show_notice("It's getting late. Time to head home to bed.")
	hud.set_clock(rackets.night, clock.text(), clock.is_late())


func save_game() -> void:
	var data := {"rackets": rackets.to_dict(), "voices": voice_lines.to_dict(), "poker": {}}
	back_rooms.save_into(data)  # the tables: the card game, the machines, his chips counted as his money
	if walker != null:
		data["danny"] = walker.condition.to_dict()
	if rival != null:
		data["ward"] = {"out": ward_out.duplicate(), "rival": rival.to_dict()}
	if pistol != null:
		data["gun"] = {"ammo": pistol.ammo, "spare": pistol.spare}
	if thompson != null:  # M010: the Thompson's rounds go with the loan
		data.rackets.loan.ammo = thompson.ammo
		data.rackets.loan.spare = thompson.spare
	if world != null:
		data["districts"] = _districts_to_save()
	if fleet != null and fleet.thefts != null:
		data["cars"] = fleet.to_save()  # M013: where the cars stand, which are taken, the one he sits in
	if walker != null and clock != null:  # M012: where and when (in the street or in a room, any district)
		var at: Vector2 = walker.global_position if player == null or player.on_foot() else player.body().global_position
		data["place"] = {"night": rackets.night, "minute": clock.minute, "x": at.x, "y": at.y, "facing": walker.model.facing}
	if incidents != null:
		data["incidents"] = incidents.to_dict()
	SaveGame.write(save_path, data)


## M009: the city's incidents move on with the clock; one that ends is
## talked about by whoever saw it. A stop breaks off if its copper is called
## away (gunfire) or down.
## M010: the incidents Danny has noticed (by noise or sight), so the minimap
## can point them out: a ping when he first notices one in its range, an arrow
## on its rim while one in this district goes on out of it.
var _noticed := {}


func _notice_incidents() -> void:
	if hud == null or hud.minimap == null:
		return
	var danny := player.body().global_position
	var arrows: Array[Vector2] = []
	for inc in incidents.active:
		if String(inc.spot.district) != world.current:
			continue
		if not _noticed.has(inc.id) and IncidentNotice.noticed(inc, incidents.phase_name(inc), danny):
			_noticed[inc.id] = true
			if hud.minimap.place_on_map(inc.spot.pos).on_map:
				hud.minimap.ping(inc.spot.pos)
		if _noticed.has(inc.id) and not hud.minimap.place_on_map(inc.spot.pos).on_map:
			arrows.append(inc.spot.pos)
	hud.minimap.set_arrows(arrows)
	for id in _noticed.keys():
		if incidents.get_incident(id).is_empty():
			_noticed.erase(id)


func _advance_incidents() -> void:
	var danny := player.body().global_position if player != null else Vector2.INF
	for inc in incidents.active.duplicate():
		if inc.kind == "stop" and inc.mercer == "" and incidents.phase_name(inc) != "leaving" \
				and world.is_ready(inc.spot.district):
			var cop := police.officer_of(inc.spot.district)
			if cop == null or cop.brain.is_hunting():
				if cop != null:
					cop.duty = {}
				_end_incident(incidents.break_off(inc.id, "broken_off"))
	for e in incidents.advance(clock.minute, danny, police.can_stop):
		if e.event == "over":
			rackets.street_incident_over(e.incident)
		incident_event.emit(e.event, e.incident)


## An incident ended early (broken off): talked about like any other.
func _end_incident(e: Dictionary) -> void:
	if e.is_empty():
		return
	rackets.street_incident_over(e.incident)
	incident_event.emit("over", e.incident)


## Danny steps into the incident he is talking his way into (see Conversations).
func _step_in(choice: String) -> void:
	var inc := incidents.get_incident(dialogue.incident_talking)
	if inc.is_empty():
		return
	var out := incidents.intervene(inc.id, choice, dialogue.context())
	if not out.ok:
		return
	match out.outcome:
		"hushed":
			rackets.money += HUSH_MONEY
		"robbed":
			rackets.money += HANDOFF_TAKE
			police.witness_violence(walker.global_position, walker.global_position)  # a hold-up at gunpoint, if a copper saw it
		"bribed":
			rackets.money -= mini(Conversations.STOP_BRIBE, rackets.money)
		"vouched":
			var cop := police.officer_of(inc.spot.district)
			if cop != null:
				cop.duty = {}
				cop.brain.suspect(walker.global_position)
	incident_event.emit("phase", inc)


## M008: what each neighbouring district keeps for tonight - whether its beat
## cop is down, and where - from the live district if it is loaded.
func _districts_to_save() -> Dictionary:
	var out := {}
	for id in world.order:
		if id == layout.id:
			continue
		var o: PoliceOfficer = police.district_officer(id)
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
		var still := _still_out(v.plan)
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
	if fights.fighting:
		# only Space, for the dial; no walking, shooting, maps or menus mid-fight
		if event.is_action_pressed(CityInput.HANDBRAKE):
			fights.press()
		return
	if back_rooms.handle_key(event):
		return  # M010, M011: at a table only the table's keys
	if cafe_film != null:
		if event.is_action_pressed(CityInput.MENU) or event.is_action_pressed(CityInput.INTERACT) \
				or event.is_action_pressed(CityInput.HANDBRAKE) or (event is InputEventMouseButton and event.pressed):
			cafe_film.skip()
		return
	if bird_film != null and dialogue.talking == "":  # M012: E, Esc, Space or a click skips to her question
		if event.is_action_pressed(CityInput.MENU) or event.is_action_pressed(CityInput.INTERACT) \
				or event.is_action_pressed(CityInput.HANDBRAKE) or (event is InputEventMouseButton and event.pressed):
			bird_film.skip()
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
	if event.is_action_pressed(CityInput.MAP) and not paused and dialogue.talking == "":
		show_map(true)
		return
	if event.is_action_pressed(CityInput.STATUS) and not paused and dialogue.talking == "":
		show_status(true)
		return
	if event.is_action_pressed(CityInput.MENU) and dialogue.talking != "":
		dialogue.end()
	elif paused:
		var what := hud.game_menu.handle_key(event)  # M012: the game menu has the keys
		if what == "sound":
			_sound_input(event)
		else:
			menu_action(what)
	elif event.is_action_pressed(CityInput.MENU):
		open_menu(true)
	elif event.is_action_pressed(CityInput.HELP):
		hud.toggle_help()


## M012: the game menu open (Esc) or shut: the world waits under it - the
## clock, the cards, the coppers, every timer - and nothing it does reaches
## the street (the click that closes it never fires the gun).
func open_menu(on: bool) -> void:
	paused = on
	get_tree().paused = on
	if on:
		hud.game_menu.notebook = Notebook.entries(rackets, clock.minute)
		hud.game_menu.can_load = save_path != "" and FileAccess.file_exists(save_path)
	hud.set_paused(on)
	hud.show_sound(settings, sound_row)
	if not command_source.is_valid():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if on else Input.MOUSE_MODE_HIDDEN
	if not on:
		player.fire_lock = true


## M012: what the game menu asked for ("resume", "save", "load", "quit"; "" nothing).
func menu_action(what: String) -> void:
	match what:
		"resume":
			open_menu(false)
		"save":
			save_game()
			var here_l := world.layout_at(player.body().global_position)
			var at: String = interiors.current.name if interiors.current != null else (here_l.name if here_l != null else layout.name)
			hud.game_menu.say("Saved - Night %d, %s, %s." % [rackets.night, clock.text(), at] if save_path != ""
				else "Nothing written: this game is not being saved.")
			hud.game_menu.can_load = save_path != "" and FileAccess.file_exists(save_path)
		"load":
			if save_path == "" or not FileAccess.file_exists(save_path):
				return
			reload_requested.emit()
			if get_tree().current_scene == self:
				get_tree().paused = false
				get_tree().reload_current_scene()
		"quit":
			save_game()
			get_tree().quit()


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
# ------------------------------------------------------------------ M009: Danny's own work

## E at an errand: Dutch's crate goes into the boot of the car at the kerb;
## the Bijou's film can into Danny's coat.
func _take_errand(id: String, at: Vector2) -> void:
	match id:
		"crate":
			var best := fleet.loadable_car_near(at, OpportunityViews.LOAD_REACH)
			if best == null:
				hud.show_notice("You'll want a car up at the kerb for that. It's a heavy crate.")
				return
			if rackets.opportunities.load_crate():
				fleet.set_cargo(best, true)
				soundscape.play("vehicles/door", -3.0)
				hud.show_notice("You and Dutch heave the crate into the boot. Novak's Grocery, before two.")
				save_game()
		"film_can":
			if rackets.opportunities.find_reel():
				hud.show_notice("A flat tin film can, \"BIJOU - LATE\" chalked on the lid. Mr. Feeney's reel.")
				save_game()


func _opportunity(what: String) -> void:
	match what:
		"take_crate":
			rackets.opportunities.take_crate()
		"take_reel":
			rackets.opportunities.take_reel()
		"deliver_crate":
			var c := fleet.crate_car_at(_novak_door())
			if c != null and rackets.deliver_crate() >= 0:
				fleet.set_cargo(c, false)
				hud.show_notice("Dutch's crate delivered.")
		"return_reel":
			if rackets.return_reel() > 0:
				hud.show_notice("The late show goes on at the Bijou.")


## An opportunity ran out on its own (the clock): remembered and talked about;
## if Danny had taken it on, he is told.
func _opportunity_over(e: Dictionary) -> void:
	var promised: bool = e.what == "crate" and e.outcome == "dropped" or e.what == "reel" and rackets.opportunities.reel_promised
	rackets.opportunity_over(e)
	match [e.what, e.outcome]:
		["crate", "dropped"]:
			for c in fleet.cars:
				fleet.set_cargo(c, false)
			hud.show_notice("Two o'clock. Novak's shut - Dutch's nephew will be fetching his crate.")
		["reel", "cancelled"]:
			if promised:
				hud.show_notice("Eleven o'clock. No reel at the Bijou - the late show's off.")


func _novak_door() -> Vector2:
	var g := _plan("grocery")
	return g.outside_door(0, 20.0) if g != null else Vector2.INF


## M009: Dutch or Mr. Feeney hit: if Danny did it, they (and the talk) remember.
func _on_contact_hurt(id: String, w: Walker) -> void:
	if w.last_shooter == walker and rackets.memory.recent(id, "shot", rackets.night, 1) == 0:
		rackets.shot_person(id)


## M010: the parked works trucks (scenery, not drivable) of every district, gathered once.
var _scenery_trucks: Array[Vector2] = []


## M010: one of the parked works trucks within reach of p (in a built district).
func _scenery_truck_near(p: Vector2) -> bool:
	if _scenery_trucks.is_empty() and world != null:
		for id in world.order:
			for pr in (world.layouts[id] as DistrictLayout).props:
				if String(pr.kind).begins_with("props/truck"):
					_scenery_trucks.append(pr.pos)
		_scenery_trucks.append(Vector2.INF)  # gathered (even if there are none)
	for t in _scenery_trucks:
		if t.distance_to(p) < 72.0 and world.is_ready(world.district_at(t)):
			return true
	return false


## M010: the seats of the built districts (benches in the street and the park, in the rooms).
func _seats_near() -> Array:
	var out := []
	for id in world.ready_ids():
		if not _seats.has(id):
			_seats[id] = Seats.of(world.layouts[id])
		out.append_array(_seats[id])
	return out


## M010: sitting with Space held, the night passes FAST_TIME times as fast -
## but never past the next moment that must not be missed (it slows to normal
## a couple of minutes before).
func _time_scale() -> float:
	if player.seat.is_empty() or not player.passing_time or cafe_film != null:
		return 1.0
	if next_moment() - clock.minute < 2.0:
		return 1.0
	return FAST_TIME


## Game minutes of moments fast time must not skip (the café job's blast, ...).
var moments: Array[float] = []


## The game minute of the next moment fast time must not skip (INF: none).
func next_moment() -> float:
	var next := INF
	for m in moments:
		if m >= clock.minute - 0.01:
			next = minf(next, m)
	return next


## M010: while the drowsiness must keep out of the way (talk, a scene, the maps, a fight).
func _drowsy_held() -> bool:
	return dialogue.talking != "" or opening != null or map_open or status_open or fights.fighting or back_rooms.at_a_table() \
		or cafe_film != null


## M007: Lefty put up his fists ("Raise your fists" or walking away from the
## line starts it). Knowing how he fights (Eddie's tip) widens the zone; a
## wounded Lefty is slower.
func _fight_lefty() -> void:
	fights.clear_pending()
	if rival == null or rival.is_down() or walker.global_position.distance_to(rival.body.global_position) > 90.0:
		return
	var bonus := FIGHT_TIP_BONUS if rackets.job.learned.has("tip") else 0.0
	var pace := FIGHT_HURT_PACE if rival.body.condition.worst() >= BodyCondition.Level.WOUNDED else 1.0
	fights.start(rival.body, Rival.NAME, _on_lefty_fight, bonus, pace)


## M012 "After the Last Song": once, on a night Danny is in the Copper Owl
## after half past one and has met her, the Bird's next song is her last: the
## song ends, she steps down from the bandstand to the end of the bar and asks
## him to stay. He can let her be (she waits a while, then goes up), or answer.
func _bird_after_last_song(delta: float) -> void:
	if bird_scene == "asking":
		var b: Walker = bird_show.bird if bird_show != null else null
		if b == null or b.down:
			bird_scene = ""
			return
		var to := BIRD_SEAT - b.global_position
		b.move = to.normalized() * 0.5 if to.length() > 4.0 else Vector2.ZERO
		if to.length() <= 4.0:
			b.aim_point = walker.global_position
		_bird_ask_left -= delta
		var away: bool = interiors.current == null or interiors.current.id != "copper_owl"
		if _bird_ask_left <= 0.0 or away:
			bird_scene = ""  # she let it be; she'll sing again tomorrow and ask another night
			overhead.hush()
			b.move = Vector2.ZERO
		return
	if bird_scene != "" or not callouts_enabled or rackets.bird_scene != "" or clock.minute < BIRD_LAST_SONG:
		return
	if not stage.singing() or ward_out.has("bird") or bird_show == null:
		return
	if interiors.current == null or interiors.current.id != "copper_owl" or not player.on_foot():
		return
	if voice_lines.due("bird_greeting") or dialogue.talking != "" or fights.fighting or back_rooms.at_a_table() \
			or people.since_gunfire() < 30.0 or not player.seat.is_empty():
		return  # they have not met yet, or Danny is busy
	stage.finish()
	soundscape.stop_music()
	bird_show.off_stage = true
	bird_scene = "asking"
	_bird_ask_left = 40.0
	overhead.say(bird_show.bird, "That's the last one, folks. ...Stay a minute, Mercer?")
	hud.show_notice("The last song of the night. The Bird steps down from the bandstand.")


## The scene itself, in the game (like the café's film): the bars in, the
## camera leaving Danny for the end of the bar, the club's lamps low and the
## room hushed, a few lines - then her question, and his answer.
func _start_bird_film() -> void:
	dialogue.end()
	bird_scene = "film"
	overhead.hush()
	var me := walker.global_position
	var her := BIRD_SEAT
	var bird: Walker = bird_show.bird
	bird.move = Vector2.ZERO  # at the end of the bar, turned to him
	bird.place(her, (me - her).angle())
	bird.aim_point = me
	var z := camera.zoom.x
	walker.aim_point = her
	var keys := [
		{"t": 0.0, "pos": me, "zoom": z},
		{"t": 3.0, "pos": me.lerp(her, 0.5), "zoom": z * 1.2},
		{"t": 6.5, "pos": her + Vector2(0, 10), "zoom": z * 1.55},
		{"t": 13.0, "pos": her + Vector2(-6, 4), "zoom": z * 1.65},
	]
	var captions := [
		{"t": 0.3, "text": "The band packs up. Somebody starts stacking chairs on the tables."},
		{"t": 3.4, "text": "The Bird sits at the end of the bar with a glass of water dressed up as gin."},
		{"t": 7.4, "text": "\"Every night a man at that corner table decides what I'm worth,\" she says. \"Tonight it was Rourke.\""},
	]
	var cues := [{"t": 0.4, "id": "lamps"}, {"t": 1.0, "id": "hush"}]
	bird_film = Cinematic.new()
	add_child(bird_film)
	bird_film.hold = true
	bird_film.start(keys, captions, cues, load(Hud.FONT_PATH))
	bird_film.cue.connect(_on_bird_cue)
	bird_film.held.connect(_on_bird_question)
	bird_film.finished.connect(_end_bird_film)
	hud.visible = false
	markers.visible = false
	player.set_physics_process(false)
	walker.move = Vector2.ZERO
	_follow_rate = camera.follow_rate
	camera.follow_rate = 2.2
	camera.target = bird_film.rig


func _on_bird_cue(id: String) -> void:
	match id:
		"lamps":
			var owl := interiors.view_of("copper_owl")
			if owl != null:
				owl.dim(0.55)  # the house lights down after the last number
		"hush":
			soundscape.set_duck(true)


## The film has reached her: the question, and his answer (a talk inside the film).
func _on_bird_question() -> void:
	bird_film.captions = []  # her words go to the talk below; the film's line and its "skip" make room
	bird_film.caption.text = ""
	bird_film.hint.visible = false
	hud.visible = true
	player.set_physics_process(true)
	dialogue.start("bird_scene")


func _bird_said(what: String) -> void:
	if rackets.bird_scene != "":
		return
	rackets.bird_scene = what
	rackets.bird_scene_night = rackets.night
	var kind: String = {"truth": "told_truth", "kind": "kept_quiet", "guard": "held_back"}.get(what, "")
	if kind != "":
		rackets.memory.remember("bird", kind, rackets.night)
	save_game()


func _end_bird_film() -> void:
	hud.visible = true
	markers.visible = true
	player.set_physics_process(true)
	camera.target = player.body()
	camera.follow_rate = _follow_rate
	camera.zoom_override = 0.0
	soundscape.set_duck(false)
	var owl := interiors.view_of("copper_owl")
	if owl != null:
		owl.dim(0.85)  # after hours: the house lights stay a little low tonight
	bird_film.queue_free()
	bird_film = null
	bird_scene = ""
	save_game()


## M012: the fistfight with Walt Haney in the freight shed (the M007 dial).
func _fight_walt() -> void:
	fights.clear_pending()
	var walt := interiors.person("freight_shed", "walt")
	if walt == null or walt.down or walker.global_position.distance_to(walt.global_position) > 120.0:
		return
	fights.start(walt, "Walt Haney", _on_walt_fight)


func _on_walt_fight(won: bool, _results: Array) -> void:
	rackets.freight.fought(rackets, won)
	dialogue.start("walt")
	dialogue.show(talk.choose("walt", "fight_won" if won else "fight_lost", dialogue.context()))
	_freight_effect("settled" if won else "")
	save_game()


## M012: what a step of the freight job changes in the game: the crates in the
## shed, a word on the notebook, the purse.
func _freight_effect(what: String) -> void:
	var f := rackets.freight
	match what:
		"accepted", "learned", "leon_agrees":
			hud.show_notice(f.objective())
		"settled":
			if f.crates_out:
				soundscape.play("places/door", -6.0)
				hud.show_notice("The Hartmann's crates are going out on the truck. Leon owes you ten dollars.")
		"fee":
			_show_purse()
	_sync_freight()


## M012: the held crates in the shed while they are held; gone once they went.
func _sync_freight() -> void:
	interiors.set_furniture_present("freight_shed", "interiors/freight_crates", not rackets.freight.crates_out)


func _on_lefty_fight(won: bool, _results: Array) -> void:
	dialogue.talking = "lefty"
	rival.body.aim_point = walker.global_position
	dialogue.show(talk.choose("lefty", "job_fight_won" if won else "job_fight_lost", dialogue.context()))
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
	var mine := fleet.my_car()
	var body := player.body()
	var cops := []
	for o in police.officers():
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
	back_rooms.update(delta, paused)  # the card players in their chairs; Leo's wheel and the regulars (not under the menu)
	if not paused and stage.update(delta):
		soundscape.resume_music()  # the band counts her back in
		if bird_show != null:
			bird_show.restart()
	_update_clock(delta)
	if not paused:
		_people_update(delta)  # M012: routines and call-outs
	if not get_tree().paused:
		world.update(player.body().global_position)  # M008: neighbours streamed in and out
	_update_view(delta)
	police.update_report(delta)


func _update_view(delta: float) -> void:
	camera.update_camera(delta)
	# M010: drowsy before dawn - kept out of the way of talk, cards and scenes
	camera.offset = drowsy.update(clock.drowsiness(), _drowsy_held(), not player.on_foot(), delta) + _kick
	_kick = _kick.move_toward(Vector2.ZERO, delta * 40.0).limit_length(8.0)
	if _shake > 0.0:  # M010: the blast shakes the view
		_shake = maxf(0.0, _shake - delta * 0.9)
		camera.offset += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 14.0 * _shake * _shake
	if cafe_film != null:
		camera.zoom_override = cafe_film.zoom
	if bird_film != null:
		camera.zoom_override = bird_film.zoom
	city.update_view(camera.eye(), camera.eye_height(), camera.view_rect())
	world.update_view(camera.eye(), camera.eye_height(), camera.view_rect())
	interiors.update_player(walker.global_position if player.on_foot() else Vector2.INF)
	for s in streets():
		s.view = camera.view_rect()
	# M010: the weather over the built districts
	var cities := [city]
	for id in world.ready_ids():
		if id != layout.id:
			cities.append(world.city_of(id))
	# M012: no rain and no fog in the building whose room he is in (its roof is off)
	var open_room: InteriorView = interiors.view_of(interiors.current.id) if interiors.current != null else null
	weather_view.indoors = open_room.host.rect if open_room != null and open_room.host != null else Rect2()
	weather_view.refresh(camera.view_rect(), camera.eye(), camera.zoom.x, cities, delta)
	if not get_tree().paused:
		incident_views.refresh(camera.eye(), player.body().global_position, delta)  # M009
		opportunity_views.refresh(player.body().global_position)
	var prompt := ""
	var target := {}
	hud.minimap.visible = not back_rooms.at_a_table() and bird_film == null  # M010: the card table has the screen
	if back_rooms.at_a_table():
		pass
	elif player.on_foot():
		var spot := _spot()
		var c := player.enterable_car()
		if dialogue.talking == "" and player.seat.is_empty():
			target = _highlight_for(spot, c)  # M012
		if not spot.is_empty():
			prompt = "E   %s" % ("Interrupt the Bird" if spot.id == "bird" and stage.singing() else spot.prompt)
		elif c == null and _scenery_truck_near(walker.global_position):
			prompt = "A works truck - chained up for the night"
		elif c != null:
			prompt = fleet.prompt_for(c)
	elif player.car.speed() < 30.0:
		prompt = "E   Get out"
	highlight.show_target(target)
	plates.update(walker.global_position if player.on_foot() else Vector2.INF)
	var focus := player.body().global_position
	var door := interiors.door_at(walker.global_position) if player.on_foot() else {}
	var facing := walker.model.facing if player.on_foot() else player.car.model.heading
	var speed := 0.0 if player.on_foot() else player.car.speed() / player.car.model.params.max_speed
	var others := []
	for o in police.officers():
		if o != officer and not o.is_down():
			others.append({"pos": o.body.global_position, "hunting": o.brain.is_hunting()})
	hud.minimap.other_police = others
	hud.minimap.set_view(focus, facing, speed, officer.body.global_position if not officer.is_down() else Vector2.INF,
		officer.brain.is_hunting(), delta)
	if not get_tree().paused:
		_notice_incidents()  # M010: after the minimap knows where Danny is
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
	soundscape.rain = weather.rain_strength()  # M010
	soundscape.downpour = weather.downpour()  # M012
	if opening != null:
		camera.zoom_override = opening.zoom
		# the camera is the listener: the night as it drifts past
		var eye := camera.eye()
		soundscape.update_listener(eye, _room_containing(eye), false, clock.activity(), delta)
	else:
		soundscape.update_listener(focus, interiors.current if player.on_foot() else null, not player.on_foot(),
			clock.activity(), delta)
