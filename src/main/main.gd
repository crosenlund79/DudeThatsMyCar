extends Node2D
## Composition root (M001-M014): builds the city at night - the ward, its
## rooms, the streamer for its neighbours, Danny, the camera, the HUD - in a
## fixed order, makes the directors that run each part of the game
## (src/main/game.gd lists them) and connects them, then runs every frame in
## a fixed order (_process) and routes the keys by what is on screen
## (_unhandled_input). It owns no feature's behaviour or state: a job, a table,
## a film or a district's content lives in its own director. No Autoloads.
## Tests run this scene with a scripted command source instead of the keyboard
## and mouse.

## M012: the game menu asked to go back to the last save (the scene is
## reloaded when it is the running scene; a test listens instead).
signal reload_requested

# ------------------------------------------------------------------ configuration (set before the scene starts)

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
## Tests: no passers-by or traffic in the neighbouring districts either.
var quiet_streets := false
## M010: a weather state ("clear", "rain", "fog", "rain_fog") held all night
## instead of the night's course (tests, screenshots).
@export var weather_override := ""

# ------------------------------------------------------------------ rules

@export var police_rules: PoliceRules = preload("res://src/police/default_police.tres")
## The player's handgun; M010: Eddie's Thompson.
@export var gun_rules: GunRules = preload("res://src/weapons/default_pistol.tres")
@export var thompson_rules: GunRules = preload("res://src/weapons/thompson.tres")
## Prices and nightly limits of the bootleg trade and the protection racket.
@export var economy_rules: EconomyRules = preload("res://src/economy/default_economy.tres")
## The hours of the night (start, time to go home, dawn) and how fast it runs.
@export var night_rules: NightRules = preload("res://src/night/default_night.tres")
## M011: the wheel's limits; the three machines' rules (M011, M013).
@export var roulette_rules: RouletteRules = preload("res://src/gaming/default_roulette.tres")
@export var slot_rules: Array[SlotRules] = [preload("res://src/gaming/slot_owl.tres"),
	preload("res://src/gaming/slot_bell.tres"), preload("res://src/gaming/slot_star.tres")]
## M007: the fistfight's rules.
@export var fight_rules: FightRules = preload("res://src/fight/default_fight.tres")

# ------------------------------------------------------------------ the game's shared parts (kept in `game`)

## M014: the running game's shared parts, handed to the directors (src/main/game.gd).
## The fields below read and write the same references (tests and tools use them).
var game := Game.new()
var settings: AudioSettings:
	get: return game.settings
	set(v): game.settings = v
var resolver: AssetResolver:
	get: return game.resolver
	set(v): game.resolver = v
var rackets: Rackets:
	get: return game.rackets
	set(v): game.rackets = v
var clock: NightClock:
	get: return game.clock
	set(v): game.clock = v
var talk: Conversations:
	get: return game.talk
	set(v): game.talk = v
## The people's recorded lines: which first-meeting lines Danny has heard (saved).
var voice_lines: VoiceLines:
	get: return game.voice_lines
	set(v): game.voice_lines = v
## The Bird's act on the bandstand (M006).
var stage: StageAct:
	get: return game.stage
	set(v): game.stage = v
## The Riverside Ward's layout (the district at the world's origin).
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
var incident_views: IncidentViews:
	get: return game.incident_views
	set(v): game.incident_views = v
## M010: the night's weather, and how it is shown.
var weather: Weather:
	get: return game.weather
	set(v): game.weather = v
var weather_view: WeatherView:
	get: return game.weather_view
	set(v): game.weather_view = v
var walker: Walker:
	get: return game.walker
	set(v): game.walker = v
var camera: CityCamera:
	get: return game.camera
	set(v): game.camera = v
var player: PlayerController:
	get: return game.player
	set(v): game.player = v
var bullets: BulletWorld:
	get: return game.bullets
	set(v): game.bullets = v
var gunfire: GunfireView:
	get: return game.gunfire
	set(v): game.gunfire = v
var navigator: CityNavigator:
	get: return game.navigator
	set(v): game.navigator = v
## M006: Lefty Moran, the North Side gangster outside Doyle's Garage.
var rival: Rival:
	get: return game.rival
	set(v): game.rival = v
var vehicle_audio: VehicleAudio:
	get: return game.vehicle_audio
	set(v): game.vehicle_audio = v
var soundscape: Soundscape:
	get: return game.soundscape
	set(v): game.soundscape = v
## The player that says the recorded lines one at a time (M006).
var voice: VoicePlayer:
	get: return game.voice
	set(v): game.voice = v
## How the Bird moves to her song (M006).
var bird_show: BirdPerformance:
	get: return game.bird_show
	set(v): game.bird_show = v
var hud: Hud:
	get: return game.hud
	set(v): game.hud = v
## The ward's beat cop and street life (made at start-up; the neighbours' come
## with their districts).
var officer: PoliceOfficer
var street: StreetLife
## M010: Danny's eyes growing heavy towards dawn.
var drowsy: DrowsyView

# ------------------------------------------------------------------ the directors (M014: each owns its part of the game)

var dialogue: Dialogue  ## talking (src/talk/)
var people: People  ## call-outs and routines (src/people/)
var fights: Fights  ## fistfights (src/fight/)
var casualties: Casualties  ## who is hurt or out tonight (src/health/)
var districts: Districts  ## what a district holds while it is built (src/world/)
var incident_director: IncidentDirector  ## the city's incidents in the game (src/incidents/)
var films: Films  ## the opening, the cafe's and the Bird's films (src/presentation/)
var club: Club  ## the bandstand (src/club/)
var armoury: Armoury  ## Danny's guns (src/weapons/)
var night: NightCycle  ## the night and sleeping (src/night/)
var interactions: Interactions  ## what E does (src/player/)
var missions: Missions  ## every authored job the same way (src/jobs/)
var rourke_job: RourkeJobDirector
var errands: Errands
var freight: FreightJobDirector
var cafe: CafeJobDirector
var last_song: LastSong
var leftys_car: LeftysCarDirector  ## M015: Lefty's speedster (src/rivals/)
var dev: DevTools  ## M015: the developer tools (src/dev/)
var gun_watch: GunWatch  ## M015: who sees the gun in his hand (src/people/)
var run_overs: RunOvers  ## M015: somebody knocked down by Danny's car (src/crime/)
var casework: Casework  ## M015: the case sheets and where the work points (src/jobs/)
var work_markers: WorkMarkers  ## M015: the work's marks in the street
var back_rooms: BackRooms  ## the card table, the wheel, the machines (src/gaming/)
var fleet: Fleet  ## the parked cars (src/driving/)
var police: PoliceForce  ## the beat cops of every built district (src/police/)
var shake := ViewShake.new()  ## what jolts the view (src/camera/)
var modals: Modals  ## what is over the street and has the keys: the menu, the maps, a table, a film (src/ui/)
var saves: Saves  ## the save read, checked and written by sections (src/save/)


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
	game.shake = shake
	settings = AudioSettings.new(settings_path)
	settings.load_settings()
	settings.apply()
	game.prefs = Preferences.new(settings_path)  # M015: the player's own preferences (not the save)
	game.prefs.load_prefs()
	resolver = AssetResolver.new(override_root)
	rackets = Rackets.new(economy_rules)
	clock = NightClock.new(night_rules)
	rackets.town.night_minutes = float(night_rules.dawn_minute - night_rules.start_minute)
	talk = Conversations.new(rackets)
	saves = game.make(&"saves", Saves)  # M014: the save by sections, at the current format
	modals = game.make(&"modals", Modals)  # M014: what has the keys
	dialogue = game.make(&"dialogue", Dialogue)  # M014: talking in the game
	people = game.make(&"people", People)  # M014: call-outs and routines
	fights = game.make(&"fights", Fights)  # M014: fistfights
	casualties = game.make(&"casualties", Casualties)  # M014: who is hurt or out tonight
	people.is_out = casualties.is_out
	districts = game.make(&"districts", Districts)  # M014: what each district holds while it is built
	districts.quiet_streets = quiet_streets
	incident_director = game.make(&"incident_director", IncidentDirector)  # M014: the city's incidents in the game
	films = game.make(&"films", Films)  # M014: the films, one at a time
	club = game.make(&"club", Club)  # M014: the bandstand
	armoury = game.make(&"armoury", Armoury)  # M014: Danny's guns
	night = game.make(&"night", NightCycle)  # M014: the night and sleeping through the day
	dialogue.on_sleep = night.sleep
	interactions = game.make(&"interactions", Interactions)  # M014: what E does
	missions = game.make(&"missions", Missions)  # M014: every authored job the same way (clock order)
	rourke_job = missions.add(game.make(&"rourke_job", RourkeJobDirector))
	errands = missions.add(game.make(&"errands", Errands))
	freight = missions.add(game.make(&"freight", FreightJobDirector))
	cafe = missions.add(game.make(&"cafe", CafeJobDirector))
	last_song = missions.add(game.make(&"last_song", LastSong))
	leftys_car = missions.add(game.make(&"leftys_car", LeftysCarDirector))  # M015
	run_overs = missions.add(game.make(&"run_overs", RunOvers))  # M015
	dev = game.make(&"dev", DevTools)  # M015: for testing, from the game menu
	gun_watch = game.make(&"gun_watch", GunWatch)  # M015
	casework = game.make(&"casework", Casework)  # M015
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
	work_markers = WorkMarkers.new()  # M015
	add_child(work_markers)
	work_markers.setup(load(Hud.FONT_PATH))
	casework.attach(work_markers)
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
	game.locations = CityLocations.of(world.order.map(func(id: String) -> DistrictLayout: return world.layouts[id]))
	world.clearance = Walker.RADIUS + 3.0
	world.extra_steps = districts.steps
	world.district_ready.connect(districts.ready)
	world.district_unloading.connect(districts.unloading)
	world.district_entered.connect(districts.entered)
	districts.load_saved(saves.section("districts"))
	var all_layouts := world.order.map(func(id: String) -> DistrictLayout: return world.layouts[id])
	incidents = StreetIncidents.new(StreetIncidents.spots_of(all_layouts))
	incidents.begin_night(rackets.night, float(night_rules.start_minute), float(night_rules.dawn_minute),
		StreetIncidents.saved_history(saves.section("incidents"), rackets.night))
	weather = Weather.new()
	weather.begin_night(rackets.night, float(night_rules.start_minute))
	weather.force(weather_override)
	back_rooms = game.make(&"back_rooms", BackRooms)  # M014: the card game's state early, as M010 had it
	back_rooms.name = "BackRooms"
	back_rooms.load_poker(saves.section("poker"), rackets.night)
	fleet = game.make(&"fleet", Fleet)  # M014: the parked cars and their owners
	fleet.park(layout)
	walker = Walker.create(resolver, "characters/gangster", {"armed_sheet": "characters/gangster_armed", "gun": gun_rules})
	add_child(walker)
	walker.place(layout.spawn, layout.spawn_facing)
	walker.falls = false  # M006: Danny goes down, but the game decides what that means
	walker.rng.seed = 1932001
	walker.hurt.connect(casualties.danny_hurt)
	walker.struck_down.connect(casualties.danny_down)
	armoury.load_gun(saves.section("gun"))
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
	armoury.arm()  # the .45 in his hand; M010: the Thompson under his coat while it is on loan
	for v in interiors.views:
		v.visitors = [walker]
	bullets = BulletWorld.new()
	bullets.name = "Bullets"
	add_child(bullets)
	player.bullets = bullets
	gunfire = GunfireView.new()
	add_child(gunfire)
	gunfire.setup(resolver, bullets)
	armoury.wire()  # each round seen and heard (the Thompson's climb); a dry click, a gun changing hands
	bullets.impact.connect(gunfire.on_impact)
	bullets.impact.connect(func(_p: Vector2, _n: Vector2, _c: Object, _d: Vector2) -> void:
		people.gunfire())  # M012: nobody calls out with guns going off
	player.fired.connect(func(_m: Vector2, _d: Vector2) -> void: people.gunfire())
	navigator = CityNavigator.new(layout, Walker.RADIUS + 3.0)
	world.adopt(layout.id, city, navigator)
	officer = PoliceOfficer.new()
	add_child(officer)
	officer.setup(resolver, police_rules, layout.police_beat, navigator, player.body, bullets)
	police = game.make(&"police", PoliceForce, [districts.streets])  # M014: the beat cops of every built district
	police.add_ward_officer(officer)
	bullets.struck.connect(police.bullet_struck)
	player.fired.connect(_on_player_fired)
	street = StreetLife.new()
	add_child(street)
	districts.add_ward_street(street)
	street.setup(layout, resolver, clock, Fleet.CAR_SCENE, Fleet.VEHICLES, fleet.cars, [walker, officer.body] as Array[Walker])
	street.gun_shown = armoury.shown  # M015: a gun in his hand where passers-by can see it
	street.view = camera.view_rect()
	rival = Rival.new()
	add_child(rival)
	rival.setup(resolver, gun_rules, rourke_job.post(), navigator, bullets, player.body)
	rival.danny = walker
	rival.fired.connect(gunfire.on_fired)
	rival.fired.connect(func(muzzle: Vector2, _dir: Vector2) -> void:
		police.hear_gunshot(muzzle, gun_rules.noise_radius)
		for s in districts.streets():
			s.hear_gunshot(muzzle))
	rival.provoked.connect(func() -> void: hud.show_notice("Lefty Moran goes for his gun!"))
	rival.struck_down.connect(func() -> void: hud.show_notice("Lefty Moran goes down and stays down."))
	missions.setup()  # M007: Danny's gun settles Rourke's job too; M009: Dutch's crate at Novak's in a talk
	player.fired.connect(func(muzzle: Vector2, dir: Vector2) -> void:
		if not rival.is_down() and rival.near_miss(muzzle, dir):
			rival.provoke())
	for v in interiors.views:
		v.person_down.connect(casualties.person_down.bind(v))
	interiors.rooms_added.connect(_wire_rooms)  # M012: rooms in the streamed districts
	vehicle_audio = VehicleAudio.new()
	add_child(vehicle_audio)
	vehicle_audio.setup(resolver)
	soundscape = Soundscape.new()
	add_child(soundscape)
	soundscape.setup(resolver, layout, game.ward_plan("copper_owl"))
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
	hud.game_menu.action.connect(modals.menu_action)  # M012: a click in the menu
	incident_views = IncidentViews.new()
	add_child(incident_views)
	incident_views.setup(resolver, incidents, load(Hud.FONT_PATH))
	incident_views.is_shown = world.is_ready
	incident_views.officer_for = police.officer_of
	game.incident_views = incident_views
	incident_views.person_struck.connect(func(id: String) -> void: incident_director.end(incidents.break_off(id, "shooting")))
	incident_views.process_mode = Node.PROCESS_MODE_PAUSABLE
	drowsy = DrowsyView.new()  # M010
	add_child(drowsy)
	drowsy.setup()
	weather_view = WeatherView.new()  # M010
	add_child(weather_view)
	weather_view.setup(weather, resolver.get_texture("fx/fog"))
	cafe.build()  # M010: Rosie's Cafe, and the emergency's vehicles
	game.opportunity_views = errands.build()  # M009: Dutch, Mr. Feeney and their errands
	var morgue := layout.building_named("The Morgue")
	if morgue >= 0:
		hud.city_map.add_landmark(layout.buildings[morgue].rect.get_center(), "The Morgue", resolver.get_texture("ui/marker_morgue"))
	# M008: the neighbouring districts on the maps, painted from their plans (not built)
	for id in world.order:
		if id != layout.id:
			hud.minimap.add_district(world.layouts[id])
	hud.city_map.refresh_districts()
	player.interaction = interactions.use
	player.conversation = dialogue.converse
	hud.dialogue_choice.connect(dialogue.answer)
	_wire_dialogue()
	add_child(back_rooms)  # M014: the tables, the room and their screens (where the room's lines were)
	back_rooms.setup(saves.section("slots", []))
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
	if opening_enabled and saves.is_new_game():
		films.start_opening(game.ward_plan("copper_owl"))


## M012: the people of the city, a little more alive: who is where at this
## hour (Routines), the Bird's last song, and who calls out to Danny
## (Callouts) - checked a few times a second, never every person every frame.
func _people_update(delta: float) -> void:
	people.apply_routines()
	last_song.update(delta, callouts_enabled)  # M012: after half past one, her last song
	people.update_callouts(delta, callouts_enabled, modals.busy)


## M014: what a talk's pages do, each to the part of the game that owns it
## (Dialogue applies them in the M003-M012 order whatever the order here; the
## jobs' own effects are registered by Missions), and what happens as a talk ends.
func _wire_dialogue() -> void:
	dialogue.on_effect("incident", func(v: Variant, _e: Dictionary) -> void: incident_director.step_in(String(v)))
	dialogue.on_effect("fight", func(v: Variant, _e: Dictionary) -> void:  # starts when Danny raises his fists
		fights.request(String(v), missions.fight_starter(String(v))))
	dialogue.on_effect("heal", func(v: Variant, _e: Dictionary) -> void: casualties.heal(v))
	dialogue.on_effect("police", func(v: Variant, _e: Dictionary) -> void: police.report_effect(v))
	armoury.wire_dialogue()  # Eddie's rounds; M010: the Thompson lent and back
	dialogue.on_end(fights.talk_ended)  # M007: a fight agreed in the talk starts
	dialogue.on_end(club.talk_ended)  # the band counts her back in
	dialogue.on_end(last_song.talk_ended)  # M012: her question walked away from


## M012: a streamed district's rooms were built: whoever may push their doors,
## who goes down in them, and who is out tonight (from the save or from earlier).
func _wire_rooms(new_views: Array) -> void:
	for nv in new_views:
		var v: InteriorView = nv
		if walker != null:
			v.visitors = [walker]
		casualties.wire_room(v)  # who goes down in it; who is out tonight
	interiors.update_player(player.body().global_position if player != null and player.on_foot() else Vector2.INF)
	interiors.snap()
	missions.rooms_built()  # M012: the freight shed as the job left it


## M012: where and when the game was saved, if it was this same night: the
## clock set back to that minute, the district built and Danny put back - in
## the street or inside a room, in any district. (A game saved at the start
## of a night - after sleeping - begins at home as always.)
func _resume_place() -> void:
	var place: Dictionary = saves.section("place")
	if place.is_empty() or int(place.get("night", -1)) != rackets.night:
		missions.restored()  # M013: Dutch's crate back at the kerb if its car is not there
		return
	var at := Vector2(float(place.get("x", 0.0)), float(place.get("y", 0.0)))
	var seat: Car = null
	var saved_cars: Dictionary = saves.section("cars")
	if saved_cars.is_empty() or int(saved_cars.get("night", -1)) != rackets.night:
		missions.restored()
	else:
		seat = fleet.restore(saved_cars, layout.id)  # M013: the cars where they stood; the one he sat in
		missions.restored()
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


## Danny fired: every beat cop in earshot hears it (and takes a close one
## personally), passers-by scatter.
func _on_player_fired(muzzle: Vector2, dir: Vector2) -> void:
	police.player_fired(muzzle, dir)
	for s in districts.streets():
		s.hear_gunshot(muzzle)
	if incident_views != null:
		incident_director.hear_gunshot(muzzle)  # M009: they break off and run


## The room containing p (not its doorway), or null.
func _room_containing(p: Vector2) -> InteriorPlan:
	for plan in layout.interiors:
		if (plan as InteriorPlan).contains(p):
			return plan
	return null


## The purse in the corner, with what Danny carries besides (M010: the parcel).
func _show_purse() -> void:
	game.show_purse()


## The night moves on (not under the menu, not during the opening narration).
func _update_clock(delta: float) -> void:
	night.update(delta, not modals.paused and films.of("opening") == null)


## The game written to the save file, section by section (src/save/saves.gd).
func save_game() -> void:
	saves.write(save_path)


## The save read (migrated and checked), and the books and the voices put back
## first (SaveSchema.RESTORE_ORDER): everything after is built around them.
func _load_game() -> void:
	saves.read(save_path)
	if saves.has("rackets"):
		rackets.from_dict(saves.section("rackets"))
	if saves.has("voices"):
		voice_lines.from_dict(saves.section("voices"))  # (M006: a game from before the voices knows its old acquaintances)


## M006: Danny's wounds, Lefty's fate and who is out tonight, from the save.
func _load_ward() -> void:
	if saves.has("danny"):
		walker.condition.from_dict(saves.section("danny"))
	var ward: Dictionary = saves.section("ward")
	rival.from_dict(ward.get("rival", {}))
	casualties.load_out(ward.get("out", {}), rackets.night)
	for v in interiors.views:
		var still := casualties.still_out(v.plan)
		if not still.is_empty():
			v.reset_people(still)
	if casualties.is_out("bird"):
		stage.knock_out()
		soundscape.stop_music()


## Keys and clicks no control took: to whatever is over the street (src/ui/modals.gd).
func _unhandled_input(event: InputEvent) -> void:
	modals.route(event)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
	elif what == NOTIFICATION_PREDELETE:
		game.release()  # M014: the directors and the Game refer to each other: let them all go


func _process(delta: float) -> void:
	var paused := modals.paused
	back_rooms.update(delta, paused)  # the card players in their chairs; Leo's wheel and the regulars (not under the menu)
	if not paused:
		club.update(delta)  # the band counts her back in
	_update_clock(delta)
	if not paused:
		_people_update(delta)  # M012: routines and call-outs
	if not get_tree().paused:
		world.update(player.body().global_position)  # M008: neighbours streamed in and out
	_update_view(delta)
	police.update_report(delta)
	if not paused:
		gun_watch.update(delta)  # M015: a gun in his hand, out in the open
		casework.update(delta)  # M015: where the work points


func _update_view(delta: float) -> void:
	camera.update_camera(delta)
	# M010: drowsy before dawn - kept out of the way of talk, cards and scenes
	camera.offset = shake.offset(drowsy.update(clock.drowsiness(), modals.drowsy_held(), not player.on_foot(), delta), delta)
	if films.kind == "cafe" or films.kind == "bird":
		camera.zoom_override = films.current.zoom
	city.update_view(camera.eye(), camera.eye_height(), camera.view_rect())
	world.update_view(camera.eye(), camera.eye_height(), camera.view_rect())
	interiors.update_player(walker.global_position if player.on_foot() else Vector2.INF)
	for s in districts.streets():
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
		errands.views.refresh(player.body().global_position)
	hud.minimap.visible = not back_rooms.at_a_table() and films.of("bird") == null  # M010: the card table has the screen
	var prompt := interactions.prompt()  # M012: and the ring under what E would act on
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
		incident_director.notice()  # M010: after the minimap knows where Danny is
	var in_room: InteriorPlan = null
	if player.on_foot() and interiors.current != null and interiors.current.contains(walker.global_position):
		in_room = interiors.current
	markers.update_markers(delta, camera.eye(), camera.eye_height(), focus, in_room,
		door.plan if not door.is_empty() and door.outside else null)
	var here := world.layout_at(focus) if world != null else null
	var place := interiors.current.name if interiors.current != null else (here if here != null else layout).place_name(focus)
	hud.refresh(delta, place, prompt, player.car, get_viewport().get_mouse_position(),
		player.on_foot() and not modals.paused)
	hud.show_gun(walker.gun if player.on_foot() else null)
	if modals.map_open:
		modals.update_map()
	soundscape.set_speech(films.of("opening") != null or voice.speaking())
	soundscape.rain = weather.rain_strength()  # M010
	soundscape.downpour = weather.downpour()  # M012
	var opening := films.of("opening") as Opening
	if opening != null:
		camera.zoom_override = opening.zoom
		# the camera is the listener: the night as it drifts past
		var eye := camera.eye()
		soundscape.update_listener(eye, _room_containing(eye), false, clock.activity(), delta)
	else:
		soundscape.update_listener(focus, interiors.current if player.on_foot() else null, not player.on_foot(),
			clock.activity(), delta)
