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
var world: DistrictStreamer
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
