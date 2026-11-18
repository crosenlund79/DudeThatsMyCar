class_name Soundscape
extends Node
## The night as Danny hears it (presentation only; the levels come from
## SoundscapeMix): the Copper Owl's singer and its crowd, full inside the club
## and muffled through its walls outside; the street's bed, the alleys and the
## river under everything; now and then a horn a few streets off, a tug on the
## river or a lid in an alley; the engines of the cars going by; and the small
## sounds of Danny's dealings (doors, a shop bell, the till, bottles, car doors).
##
## The club's music is one player, started once and never restarted: walking
## in and out, driving away or sleeping through the day only change its level
## and filter. Outside it plays through the ClubMusic bus (a low-pass and a
## panner: the walls and which side the club is on); once the door's sweep has
## opened the filter inside, it moves to the plain Music bus, unfiltered (the
## AudioServer crossfades a bus change, so the move is seamless).

signal sound_played(logical: String)

const BUS_CLUB_MUSIC := "ClubMusic"
const BUS_CLUB_ROOM := "ClubRoom"
const BUS_STREET := "Street"
const MUSIC := "music/copper_owl_jazz"
const CROWD := "ambience/club_crowd"
const BEDS := {"street": "ambience/street_night", "alley": "ambience/alley", "river": "ambience/river"}
const DISTANT := {"horn": "ambience/horn", "foghorn": "ambience/foghorn", "clatter": "ambience/clatter"}
const DISTANT_DB := {"horn": -9.0, "foghorn": -7.0, "clatter": -11.0}
## Shops with a bell over the door.
const BELL_SHOPS := ["barber_shop", "grocery", "hardware"]
## Keepers with a till that rings when money changes hands.
const TILLS := ["sal", "augie", "novak", "lindqvist"]
## How fast levels follow the listener (s): through a door, and otherwise.
const DOOR_TAU := 0.4
const LEVEL_TAU := 0.3
const DUCK_TAU := 0.6
## Passing cars' engines (positional, on the street bus).
const TRAFFIC_DB := -15.0
const TRAFFIC_REACH := 1100.0

var layout: DistrictLayout
var club_plan: InteriorPlan
var music: AudioStreamPlayer
var crowd: AudioStreamPlayer
var beds := {}
## The smoothed levels and filters now (see SoundscapeMix.targets), and where
## the listener was last.
var level := {}
var listening := {}
## How many times the club's music has been started: once, for good.
var music_starts := 0
## 0..1: how far everything has stepped back under narration.
var duck := 0.0
var _duck_target := 0.0
var _speech := false
var _resolver: AssetResolver
var _sounds := {}
var _pool: Array[AudioStreamPlayer] = []
var _distant := {}
var _timers := {}
var _rng := RandomNumberGenerator.new()
var _traffic: Array = []
var _engine: AudioStream
## The last sounds played for Danny's dealings (newest last; for tests).
var played: Array[String] = []


## Creates the internal buses once: ClubMusic (to Music) and ClubRoom (to
## Ambience) with a low-pass and a panner, Street (to Ambience) with a low-pass.
static func ensure_buses() -> void:
	AudioSettings.ensure_buses()
	_ensure_bus(BUS_CLUB_MUSIC, "Music", true)
	_ensure_bus(BUS_CLUB_ROOM, "Ambience", true)
	_ensure_bus(BUS_STREET, "Ambience", false)


static func _ensure_bus(bus: String, send: String, with_panner: bool) -> void:
	if AudioServer.get_bus_index(bus) != -1:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, bus)
	AudioServer.set_bus_send(i, send)
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = SoundscapeMix.OPEN
	lp.resonance = 0.7
	lp.db = AudioEffectFilter.FILTER_12DB
	AudioServer.add_bus_effect(i, lp, 0)
	if with_panner:
		AudioServer.add_bus_effect(i, AudioEffectPanner.new(), 1)


func setup(resolver: AssetResolver, p_layout: DistrictLayout, club: InteriorPlan, seed_value: int = 1932) -> void:
	name = "Soundscape"
	ensure_buses()
	_resolver = resolver
	layout = p_layout
	club_plan = club
	_rng.seed = seed_value
	music = _loop(MUSIC, BUS_CLUB_MUSIC)
	crowd = _loop(CROWD, BUS_CLUB_ROOM)
	for k in BEDS:
		beds[k] = _loop(BEDS[k], BUS_STREET)
	for k in DISTANT:
		var p := AudioStreamPlayer2D.new()
		p.stream = _sound(DISTANT[k])
		p.bus = BUS_STREET
		p.max_distance = 2400.0
		p.attenuation = 0.8
		add_child(p)
		_distant[k] = p
		_timers[k] = SoundscapeMix.next_gap(k, 1.0, _rng.randf()) * 0.5
	for i in 3:
		var p := AudioStreamPlayer.new()
		p.bus = "Effects"
		add_child(p)
		_pool.append(p)
	_engine = resolver.get_audio("vehicles/engine_loop", true)
	for p in [music, crowd] + beds.values():
		var player := p as AudioStreamPlayer
		player.volume_db = SoundscapeMix.SILENT_DB
		if player.stream != null:
			player.play()
	if music.stream != null:
		music_starts += 1


func _loop(logical: String, bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = _resolver.get_audio(logical, true)
	p.bus = bus
	add_child(p)
	return p


func _sound(logical: String) -> AudioStream:
	if not _sounds.has(logical):
		_sounds[logical] = _resolver.get_audio(logical)
	return _sounds[logical]


## Puts a quiet engine on each car of the street's traffic.
func track_traffic(cars: Array[Car]) -> void:
	for c in cars:
		var p := AudioStreamPlayer2D.new()
		p.name = "EngineSound"
		p.stream = _engine
		p.bus = BUS_STREET
		p.max_distance = TRAFFIC_REACH
		p.attenuation = 1.6
		c.add_child(p)
		_traffic.append({"car": c, "player": p})


## Narration on (true) or off: the rest of the night steps back, smoothly.
func set_duck(on: bool) -> void:
	_duck_target = 1.0 if on else 0.0


## Someone speaking (the opening, a recorded line): the same step back, for
## as long as they talk (combined with set_duck).
func set_speech(on: bool) -> void:
	_speech = on


## Every frame: where the listener is (`p`), the room he is in (null outdoors),
## whether he drives, and the street activity of the hour.
func update_listener(p: Vector2, room: InteriorPlan, driving: bool, activity: float, delta: float) -> void:
	listening = SoundscapeMix.listen(layout, club_plan, p, room, driving, activity)
	var target := SoundscapeMix.targets(listening)
	if level.is_empty():
		level = target.duplicate()
	for k in target:
		if k.ends_with("_db"):
			level[k] = SoundscapeMix.glide_db(level[k], target[k], delta, DOOR_TAU if k.begins_with("music") or k.begins_with("crowd") else LEVEL_TAU)
		elif k.ends_with("cutoff"):
			level[k] = SoundscapeMix.glide_cutoff(level[k], target[k], delta, DOOR_TAU)
		else:
			level[k] = lerpf(level[k], target[k], 1.0 - exp(-delta / LEVEL_TAU))
	duck = move_toward(duck, maxf(_duck_target, 1.0 if _speech else 0.0), delta / DUCK_TAU)
	_apply()
	_update_traffic()
	_distant_sounds(p, delta)


func _apply() -> void:
	var back := SoundscapeMix.DUCK_DB * duck
	music.volume_db = _quiet(level.music_db + back)
	crowd.volume_db = _quiet(level.crowd_db + back)
	for k in beds:
		(beds[k] as AudioStreamPlayer).volume_db = _quiet(level[k + "_db"] + back)
	var open: bool = level.club_cutoff >= SoundscapeMix.OPEN * 0.9
	_route(music, "Music" if open else BUS_CLUB_MUSIC)
	_route(crowd, "Ambience" if open else BUS_CLUB_ROOM)
	_filter(BUS_CLUB_MUSIC, level.club_cutoff, level.club_pan)
	_filter(BUS_CLUB_ROOM, level.club_cutoff, level.club_pan)
	_filter(BUS_STREET, level.street_cutoff, 0.0)


static func _quiet(db: float) -> float:
	return db if db > SoundscapeMix.AUDIBLE_DB else SoundscapeMix.SILENT_DB


func _route(p: AudioStreamPlayer, bus: String) -> void:
	if p.bus != bus:
		p.bus = bus


static func _filter(bus: String, cutoff: float, pan: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	(AudioServer.get_bus_effect(i, 0) as AudioEffectLowPassFilter).cutoff_hz = clampf(cutoff, 20.0, SoundscapeMix.OPEN)
	if AudioServer.get_bus_effect_count(i) > 1:
		(AudioServer.get_bus_effect(i, 1) as AudioEffectPanner).pan = pan


## The low-pass on a bus now (tests).
static func cutoff_of(bus: String) -> float:
	var i := AudioServer.get_bus_index(bus)
	return (AudioServer.get_bus_effect(i, 0) as AudioEffectLowPassFilter).cutoff_hz


func _update_traffic() -> void:
	var back := SoundscapeMix.DUCK_DB * duck
	for t in _traffic:
		var c: Car = t.car
		var p: AudioStreamPlayer2D = t.player
		if not is_instance_valid(c):
			continue
		var on: bool = c.visible and c.active
		if on != p.playing:
			if on and _engine != null:
				p.play(_rng.randf() * maxf(_engine.get_length() - 0.1, 0.0))
			elif not on:
				p.stop()
		if on:
			var frac := clampf(c.speed() / maxf(c.model.params.max_speed, 1.0), 0.0, 1.0)
			p.pitch_scale = 0.62 + frac * 0.55
			p.volume_db = TRAFFIC_DB + frac * 6.0 + back


func _distant_sounds(p: Vector2, delta: float) -> void:
	for kind in DISTANT:
		_timers[kind] -= delta
		if _timers[kind] > 0.0:
			continue
		_timers[kind] = SoundscapeMix.next_gap(kind, listening.activity, _rng.randf())
		var player: AudioStreamPlayer2D = _distant[kind]
		if player.stream == null or not SoundscapeMix.can_hear(kind, listening):
			continue
		player.global_position = _distant_spot(kind, p)
		player.volume_db = DISTANT_DB[kind] + _rng.randf_range(-3.0, 1.0) + SoundscapeMix.DUCK_DB * duck
		player.pitch_scale = _rng.randf_range(0.9, 1.1)
		player.play()


## Where a distant sound comes from: a horn a few streets off, a tug out on
## the river, a lid somewhere along the alley.
func _distant_spot(kind: String, p: Vector2) -> Vector2:
	match kind:
		"foghorn":
			if not layout.water.is_empty():
				var w: Rect2 = layout.water[0]
				return Vector2(w.get_center().x, p.y + _rng.randf_range(-500.0, 500.0))
		"clatter":
			return p + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(160.0, 320.0)
	return p + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(550.0, 950.0)


## One of Danny's own sounds (a door, a till, a car door), close by.
func play(logical: String, volume_db: float = 0.0) -> void:
	var s := _sound(logical)
	if s == null:
		return
	var p := _pool[0]
	for q in _pool:
		if not q.playing:
			p = q
			break
	p.stream = s
	p.volume_db = volume_db + _rng.randf_range(-1.5, 0.5)
	p.pitch_scale = _rng.randf_range(0.96, 1.04)
	p.play()
	played.append(logical)
	if played.size() > 12:
		played.pop_front()
	sound_played.emit(logical)


## Through a door: the latch and hinges, and the bell over a shop's door.
func play_door(plan: InteriorPlan) -> void:
	play("places/door", -4.0)
	if plan != null and plan.id in BELL_SHOPS:
		play("places/shop_bell", -6.0)


## A deal done with `keeper`: bottles changing hands clink, money into or out
## of a shop's till rings it.
func play_deal(keeper: String, money_change: int, bottle_change: int) -> void:
	if bottle_change != 0:
		play("places/bottles", -4.0)
	if money_change != 0 and keeper in TILLS:
		play("places/register", -6.0)
