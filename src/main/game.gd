class_name Game
extends RefCounted
## M014: the running game's shared parts - the services and state that more
## than one system needs - handed to each director instead of the whole of
## main. Main makes one in _ready and fills it as it builds the game, in the
## same order as always (a part is null until it is built). Plain references:
## a director that needs the clock reads `game.clock`; it never reaches into
## main, and main keeps no state of a director's own.

## The composition root (for add_child, tweens, the tree and the viewport).
var root: Node2D

# ---- rules (main's exports)
var police_rules: PoliceRules
var gun_rules: GunRules
var thompson_rules: GunRules
var economy_rules: EconomyRules
var night_rules: NightRules
var roulette_rules: RouletteRules
var slot_rules: Array[SlotRules] = []
var fight_rules: FightRules

# ---- state and services, in the order main builds them
var settings: AudioSettings
## M015: the player's preferences (the wheel's pace), kept beside the sound levels.
var prefs: Preferences
var resolver: AssetResolver
var rackets: Rackets
var clock: NightClock
var talk: Conversations
var voice_lines: VoiceLines
var stage: StageAct
var layout: DistrictLayout
var city: City
var interiors: Interiors
var markers: PlaceMarkers
var plates: EntrancePlates
var highlight: InteractionHighlight
var overhead: OverheadLine
## M015: a few words over the heads of the street's regulars (StreetLife chatter).
var street_lines: RoomLines
var world: DistrictStreamer
## M014: every district's named places, doors, rooms and spots by a stable id.
var locations: CityLocations
var incidents: StreetIncidents
var weather: Weather
var walker: Walker
var camera: CityCamera
var player: PlayerController
var bullets: BulletWorld
var gunfire: GunfireView
var navigator: CityNavigator
var rival: Rival
var vehicle_audio: VehicleAudio
var soundscape: Soundscape
var voice: VoicePlayer
var bird_show: BirdPerformance
var hud: Hud
var incident_views: IncidentViews
var opportunity_views: OpportunityViews
var weather_view: WeatherView
var shake: ViewShake

# ---- the directors (each owns its own part of the game)
var back_rooms: BackRooms
var fleet: Fleet
var police: PoliceForce
var dialogue: Dialogue
var fights: Fights
var people: People
var casualties: Casualties
var districts: Districts
var incident_director: IncidentDirector
var films: Films
var club: Club
var armoury: Armoury
var night: NightCycle
var interactions: Interactions
var missions: Missions
var rourke_job: RourkeJobDirector
var errands: Errands
var freight: FreightJobDirector
var cafe: CafeJobDirector
var last_song: LastSong
var leftys_car: LeftysCarDirector  ## M015: Lefty Moran's speedster (src/rivals/)
var dev: DevTools  ## M015: the developer tools (src/dev/), for testing
var gun_watch: GunWatch  ## M015: who sees the gun in Danny's hand (src/people/)
var run_overs: RunOvers  ## M015: somebody knocked down by Danny's car (src/crime/)
var casework: Casework  ## M015: the case sheets and where the work points (src/jobs/)
var modals: Modals
var saves: Saves


## The game is saved (after a deal, a hand, a film...).
func save() -> void:
	root.call("save_game")


## The purse in the corner, with what Danny carries besides (M010: the parcel).
func show_purse() -> void:
	hud.carrying = "a parcel" if rackets.parcels > 0 else ""
	hud.set_purse(rackets.money, rackets.bottles, rackets.held)


## The mouse cursor shown (a table, a map, the menu) or hidden (the street) -
## left alone when a test drives the game (a scripted command source).
func mouse(visible: bool) -> void:
	if not (root.get("command_source") as Callable).is_valid():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_HIDDEN


## One of the ward's rooms by id (null if there is none).
func ward_plan(id: String) -> InteriorPlan:
	for p in layout.interiors:
		if (p as InteriorPlan).id == id:
			return p
	return null


## M010: a weather state held all night instead of the night's course (tests,
## screenshots): main's export, read when a night begins.
func weather_override() -> String:
	return String(root.get("weather_override"))


## M014: the scene is being freed: every reference let go. The directors refer
## to this object and to each other through it; RefCounted objects that refer
## to each other in a ring are never freed on their own, so without this a
## freed scene's game (its books, its layouts, every director) would stay in
## memory - once for every reload.
func release() -> void:
	if missions != null:
		missions.release()  # the jobs' own rings first (their views' signals)
	for p in get_property_list():
		if not (int(p.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		match int(p.type):
			TYPE_ARRAY:
				set(p.name, [])
			TYPE_DICTIONARY:
				set(p.name, {})
			TYPE_OBJECT, TYPE_NIL:
				set(p.name, null)



## M014: makes the director `script` on this game (`args` after the game),
## keeps it as `part` and returns it; main makes them in its build order.
## Through the script on purpose: `Fleet.new(game)` written in main.gd makes
## Godot analyse Game and every director over again for main.gd and keep it
## all (about 42 MB more memory at start-up, measured in M014); this costs
## nothing and makes the same object.
func make(part: StringName, script: Script, args := []) -> Variant:
	assert(part in self and get(part) == null, "game.%s is made once" % part)
	var director: Object = script.callv("new", [self] + args)
	set(part, director)
	return director
