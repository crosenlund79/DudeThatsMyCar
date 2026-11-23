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
## M015.12: a room's own music heard from outside (the Paradise's band), low-passed.
const BUS_ROOM_MUSIC := "RoomMusic"
const BUS_CLUB_ROOM := "ClubRoom"
const BUS_STREET := "Street"
const MUSIC := "music/copper_owl_jazz"
const CROWD := "ambience/club_crowd"
const BEDS := {"street": "ambience/street_night", "alley": "ambience/alley", "river": "ambience/river", "rain": "ambience/rain",
	"downpour": "ambience/downpour"}
const DISTANT := {"horn": "ambience/horn", "foghorn": "ambience/foghorn", "clatter": "ambience/clatter"}
const DISTANT_DB := {"horn": -9.0, "foghorn": -7.0, "clatter": -11.0}
## Shops with a bell over the door.
const BELL_SHOPS := ["barber_shop", "grocery", "hardware"]
## Keepers with a till that rings when money changes hands.
const TILLS := ["sal", "augie", "novak", "lindqvist", "dvorak", "chu", "feld", "ruby"]
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
## The record scratch when the Bird is interrupted (M006), and whether the song is stopped.
var scratch: AudioStreamPlayer
var music_stopped := false
var scratches := 0
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
## M011: the Copper Owl's back rooms: their bed (one player, started once), the
## odd sound of the room now and then (a laugh, chips, a shuffle, a glass, a
## chair) at a spot in the room, the game sounds that run on (the machines'
## reels) and positional one-shots (the wheel spun for somebody else).
const GAMING := "ambience/gaming_room"
const ROOM_EVENTS := {
	"back_room": ["gaming/chips_stack", "gaming/shuffle", "gaming/glass", "gaming/chair", "gaming/laugh"],
	"gaming_room": ["gaming/chips_stack", "gaming/glass", "gaming/chair", "gaming/laugh", "gaming/laugh"],
	# M015.12: the new quarters' rooms
	"market_hall": ["places/cleaver", "places/cleaver", "places/cup", "gaming/chair"],
	"golden_lantern": ["places/cup", "gaming/glass", "gaming/chair", "gaming/laugh"],
	"paradise": ["gaming/glass", "gaming/laugh", "gaming/chair", "gaming/glass"],
}
var gaming_bed: AudioStreamPlayer
var gaming_starts := 0
## The room events played (newest last; for tests).
var room_played: Array[String] = []
var _room: InteriorPlan = null
var _room_timer := 3.0
var _room_pool: Array[AudioStreamPlayer2D] = []
var _loops := {}


## Creates the internal buses once: ClubMusic (to Music) and ClubRoom (to
## Ambience) with a low-pass and a panner, Street (to Ambience) with a low-pass.
static func ensure_buses() -> void:
	AudioSettings.ensure_buses()
	_ensure_bus(BUS_CLUB_MUSIC, "Music", true)
	_ensure_bus(BUS_CLUB_ROOM, "Ambience", true)
	_ensure_bus(BUS_STREET, "Ambience", false)
	_ensure_bus(BUS_ROOM_MUSIC, "Music", false)


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
	scratch = AudioStreamPlayer.new()
	scratch.stream = _sound("music/record_scratch")
	scratch.bus = BUS_CLUB_MUSIC
	add_child(scratch)
	crowd = _loop(CROWD, BUS_CLUB_ROOM)
	for k in BEDS:
		beds[k] = _loop(BEDS[k], BUS_STREET)
	thunder_player = AudioStreamPlayer.new()  # M012: through the street's bus - dull indoors
	thunder_player.name = "Thunder"
	thunder_player.bus = BUS_STREET
	add_child(thunder_player)
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
	gaming_bed = _loop(GAMING, "Ambience")
	gaming_bed.volume_db = SoundscapeMix.SILENT_DB
	if gaming_bed.stream != null:
		gaming_bed.play()
		gaming_starts += 1
	for i in 3:
		var rp := AudioStreamPlayer2D.new()
		rp.bus = "Ambience"
		rp.max_distance = 900.0
		rp.attenuation = 1.2
		add_child(rp)
		_room_pool.append(rp)
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


## The Bird is interrupted (M006): the needle scratches off the record and the
## song stops. Nothing happens when it has stopped already (one scratch).
func interrupt_music() -> bool:
	if music_stopped:
		return false
	music_stopped = true
	scratches += 1
	if scratch.stream != null:
		scratch.bus = music.bus
		scratch.volume_db = _quiet(level.get("music_db", 0.0)) + 2.0
		scratch.play()
	music.stop()
	return true


## The song stops dead, no scratch (the singer shot on the bandstand).
func stop_music() -> void:
	music_stopped = true
	music.stop()


## The band counts her back in: the song starts again from the top (once).
func resume_music() -> bool:
	if not music_stopped:
		return false
	music_stopped = false
	if music.stream != null:
		music.play()
		music_starts += 1
	return true


## Narration on (true) or off: the rest of the night steps back, smoothly.
func set_duck(on: bool) -> void:
	_duck_target = 1.0 if on else 0.0


## Someone speaking (the opening, a recorded line): the same step back, for
## as long as they talk (combined with set_duck).
func set_speech(on: bool) -> void:
	_speech = on


## Every frame: where the listener is (`p`), the room he is in (null outdoors),
## whether he drives, and the street activity of the hour.
## M010: how hard it is raining (0..1), set by the weather.
var rain := 0.0
## M012: how much of a downpour it is (0..1), set by the weather.
var downpour := 0.0
var thunder_player: AudioStreamPlayer
## M012: the claps heard ({near, indoors, db}; tests).
var thunder_heard: Array = []


func update_listener(p: Vector2, room: InteriorPlan, driving: bool, activity: float, delta: float) -> void:
	listening = SoundscapeMix.listen(layout, club_plan, p, room, driving, activity)
	listening["rain"] = rain
	listening["downpour"] = downpour
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
	_room = room
	_apply()
	_update_traffic()
	_distant_sounds(p, delta)
	_room_events(delta)


func _apply() -> void:
	var back := SoundscapeMix.DUCK_DB * duck
	music.volume_db = _quiet(level.music_db + back)
	crowd.volume_db = _quiet(level.crowd_db + back)
	for k in beds:
		(beds[k] as AudioStreamPlayer).volume_db = _quiet(level[k + "_db"] + back)
	gaming_bed.volume_db = _quiet(float(level.get("gaming_db", SoundscapeMix.SILENT_DB)) + back)
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
	# M008: a district's traffic goes with the district
	_traffic = _traffic.filter(func(t: Dictionary) -> bool: return is_instance_valid(t.car))
	for t in _traffic:
		var c: Car = t.car
		var p: AudioStreamPlayer2D = t.player
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


## M012: a clap of thunder - the crack overhead or the roll over the roofs -
## on the street's bus, so a room's walls dull it (and take a little more off).
func thunder(near: bool) -> void:
	var indoors := _room != null
	var db := (-4.0 if near else -9.0) + (-6.0 if indoors else 0.0)
	thunder_player.stream = _sound("weather/thunder_near" if near else "weather/thunder_far")
	thunder_player.volume_db = db + _rng.randf_range(-1.5, 1.0)
	thunder_player.pitch_scale = _rng.randf_range(0.9, 1.05)
	thunder_player.play()
	thunder_heard.append({"near": near, "indoors": indoors, "db": db})
	sound_played.emit("weather/thunder_near" if near else "weather/thunder_far")


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


## M011: now and then, something in the back room Danny is in: a laugh,
## chips stacked, a shuffle, glasses, a chair - at a spot in the room, never
## outside it, never two at once.
func _room_events(delta: float) -> void:
	_room_timer -= delta
	if _room_timer > 0.0:
		return
	_room_timer = SoundscapeMix.next_gap("room", 1.0, _rng.randf())
	if _room == null or not SoundscapeMix.can_hear("room", listening) or not ROOM_EVENTS.has(_room.id):
		return
	var kinds: Array = ROOM_EVENTS[_room.id]
	var logical: String = kinds[_rng.randi_range(0, kinds.size() - 1)]
	var s := _sound(logical)
	if s == null:
		return
	var player := _room_pool[0]
	for q in _room_pool:
		if not q.playing:
			player = q
			break
	var r := _room.room.grow(-24.0)
	player.global_position = Vector2(_rng.randf_range(r.position.x, r.end.x), _rng.randf_range(r.position.y, r.end.y))
	player.stream = s
	player.volume_db = SoundscapeMix.ROOM_EVENT_DB + _rng.randf_range(-4.0, 1.0) + SoundscapeMix.DUCK_DB * duck
	player.pitch_scale = _rng.randf_range(0.92, 1.08)
	player.play()
	room_played.append(logical)
	if room_played.size() > 12:
		room_played.pop_front()


## M011: a sound that runs until it is stopped (a machine's reels), on its own
## player: started again while it runs, it is not restarted or doubled.
## Returns true when it started.
func start_loop(id: String, logical: String, volume_db: float = 0.0) -> bool:
	var p: AudioStreamPlayer = _loops.get(id)
	if p == null:
		p = AudioStreamPlayer.new()
		p.bus = "Effects"
		add_child(p)
		_loops[id] = p
	if p.playing:
		return false
	p.stream = _resolver.get_audio(logical, true)
	if p.stream == null:
		return false
	p.volume_db = volume_db
	p.play()
	played.append(logical)
	sound_played.emit(logical)
	return true


func stop_loop(id: String) -> void:
	var p: AudioStreamPlayer = _loops.get(id)
	if p != null:
		p.stop()


func loop_playing(id: String) -> bool:
	var p: AudioStreamPlayer = _loops.get(id)
	return p != null and p.playing


## M011: a one-shot from a place in the world (the wheel spun for somebody else).
func play_at(logical: String, at: Vector2, volume_db: float = 0.0) -> void:
	var s := _sound(logical)
	if s == null:
		return
	var player := _room_pool[_room_pool.size() - 1]
	for q in _room_pool:
		if not q.playing:
			player = q
			break
	player.global_position = at
	player.stream = s
	player.volume_db = volume_db + SoundscapeMix.DUCK_DB * duck
	player.pitch_scale = 1.0
	player.play()
	played.append(logical)
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
