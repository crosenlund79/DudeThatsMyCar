class_name QuarterLife
extends JobDirector
## M015.12: the new quarters' rooms in the game - what their talk does outside
## the money (Quarters), and the Paradise Ballroom alive while Lincoln Terrace
## is built: its band playing from the bandstand (full on the floor, muffled
## and quieter through the walls, fading with distance outside; at the pace of
## tonight's tune; packed up at three), its dancing couples turning slowly on
## the floor. A dance with a hostess lets four minutes of the night go by;
## Mrs. Dvorak's coffee is set down with a clink (its lift on the night's
## drowsiness is the clock's, from Quarters).

## The band packs up at three in the morning (the clock's minute).
const BAND_CLOSES := 27.0 * 60.0
## The band's level on the floor and from outside, and the walls' low-pass.
const INSIDE_DB := -5.0
const OUTSIDE_DB := -13.0
const OUTSIDE_CUTOFF := 700.0
## How fast the level and the filter follow Danny through the door (s).
const DOOR_TAU := 0.4
## The couples turn this fast (radians a second at the band's usual pace).
const TURN := 0.5

var game: Game
## The band's player, while the terrace is built (under its node).
var band: AudioStreamPlayer2D = null
## How often the band struck up (tests).
var band_starts := 0
## Its level and filter now (gliding to the target).
var level_db := OUTSIDE_DB
var cutoff := OUTSIDE_CUTOFF
## The dancing couples: [{a, b, mid, r, angle}].
var couples: Array = []
var _view: InteriorView = null


func _init(p_game: Game) -> void:
	game = p_game


func id() -> String:
	return "quarters"


func effects() -> Dictionary:
	return {"quarter": _on_effect}


func _on_effect(v: Variant, _effects: Dictionary) -> void:
	var d: Dictionary = v
	if d.get("coffee", false):
		game.soundscape.play("places/cup", -6.0)
	if d.get("dance", false):
		game.night.pass_minutes(Quarters.DANCE_MINUTES)  # four minutes on the floor
	if d.has("tune") and band != null:
		band.pitch_scale = pace()


## Tonight's tune's pace (the band's playback speed).
func pace() -> float:
	return float(Quarters.tune_named(game.rackets.quarters.tune).pace)


func district_ready(district: String, layout: DistrictLayout, node: Node2D) -> void:
	if district != "terrace":
		return
	var plan := _paradise(layout)
	if plan == null:
		return
	band = AudioStreamPlayer2D.new()
	band.name = "ParadiseBand"
	band.stream = game.resolver.get_audio("music/paradise_band", true)
	band.bus = Soundscape.BUS_ROOM_MUSIC
	band.max_distance = 1100.0
	band.attenuation = 1.4
	band.volume_db = OUTSIDE_DB
	for f in plan.furniture:
		if f.kind == "interiors/bandstand":
			band.position = f.pos
	node.add_child(band)


func district_unloading(district: String) -> void:
	if district == "terrace":
		band = null  # freed with the district's node
		couples.clear()
		_view = null


func rooms_built() -> void:
	var v := game.interiors.view_of("paradise") if game.interiors != null else null
	if v == null or v == _view:
		return
	_view = v
	couples.clear()
	for pair in [["dancer_a", "dancer_b"], ["dancer_c", "dancer_d"]]:
		var a: Walker = v.people.get(pair[0])
		var b: Walker = v.people.get(pair[1])
		if a == null or b == null:
			continue
		var mid := (a.global_position + b.global_position) * 0.5
		couples.append({"a": pair[0], "b": pair[1], "mid": mid, "r": a.global_position.distance_to(mid),
			"angle": (a.global_position - mid).angle()})


func _paradise(layout: DistrictLayout) -> InteriorPlan:
	for p in layout.interiors:
		if (p as InteriorPlan).id == "paradise":
			return p
	return null


## Whether the band is playing now (until three).
func band_on() -> bool:
	return band != null and game.clock.minute < BAND_CLOSES


func clock(minute: float, delta: float) -> void:
	if band == null or not is_instance_valid(band):
		band = null
		return
	if not band_on():
		if band.playing:
			band.stop()
		return
	if not band.playing:
		band.play()
		band_starts += 1
	band.pitch_scale = pace()
	var room := game.interiors.current
	var inside := room != null and room.id == "paradise"
	var k := 1.0 - exp(-maxf(delta, 0.0) / DOOR_TAU) if delta > 0.0 else 1.0
	level_db = lerpf(level_db, INSIDE_DB if inside else OUTSIDE_DB, k)
	cutoff = lerpf(cutoff, SoundscapeMix.OPEN if inside else OUTSIDE_CUTOFF, k)
	band.volume_db = level_db + SoundscapeMix.DUCK_DB * game.soundscape.duck
	Soundscape._filter(Soundscape.BUS_ROOM_MUSIC, cutoff, 0.0)
	_dance(delta)


## The couples turn about their spot on the floor, facing each other.
func _dance(delta: float) -> void:
	if _view == null or not is_instance_valid(_view):
		return
	for c in couples:
		if not (_view.person_ok(c.a) and _view.person_ok(c.b)):
			continue
		c.angle = fposmod(float(c.angle) + TURN * pace() * delta, TAU)
		var off := Vector2.from_angle(c.angle) * float(c.r)
		var a: Walker = _view.people[c.a]
		var b: Walker = _view.people[c.b]
		a.place(c.mid + off, (-off).angle())
		b.place(c.mid - off, off.angle())


func release() -> void:
	band = null
	_view = null
	couples.clear()
