class_name PoliceForce
extends RefCounted
## M014 (from main): the beat cops in the game - the ward's (built at
## start-up) and each loaded district's - as one force: who hears a shot, who
## sees violence or a theft, whether any of them is armed and after Danny, and
## a shopkeeper's report after a shakedown. Each officer's own behaviour is
## his PoliceOfficer / OfficerBrain; this only reaches them all.

## M008: the chance a round that hits the car Danny drives goes through to him.
const DRIVER_HIT_CHANCE := 0.25
## A shopkeeper going for the police (M003).
const REPORT_DELAY := 6.0
const REPORT_RADIUS := 760.0  # M010: as far as it reached under the old 760 px hearing cap

var game: Game
## The ward's beat cop (always there).
var officer: PoliceOfficer
## M008: each loaded neighbouring district's beat cop: id -> PoliceOfficer.
var _beat := {}
var _luck := RandomNumberGenerator.new()
var _report_from: InteriorPlan = null
var _report_left := 0.0
var _report_who := ""
## The street life of the built districts (whose passers-by hear a copper's shots).
var _streets: Callable
## M015: each beat cop's mood tonight shows in what he says when Danny passes
## (once in a while); at certain hours he takes up a post (DistrictLayout.police_posts)
## - only when nothing else has him, and he leaves it when its hour is up.
const MOODS := {
	"keen": ["Evening. Keep it moving.", "Quiet night. Let's keep it that way.", "I've got my eye on you, Mercer."],
	"weary": ["Long night, Mac.", "Twenty years on this beat. Twenty years.", "Go home, fella. I wish I could."],
	"chatty": ["Cold one, eh?", "Hear the Cubs dropped another?", "My wife's sister's coming to stay. Pray for me."],
	"sour": ["What are you looking at?", "Move along.", "Don't make me write you up."],
}
const MOOD_ORDER := ["keen", "weary", "chatty", "sour"]
const WORD_NEAR := 150.0
const WORD_EVERY := 70.0
var _quiet := {}


func _init(p_game: Game, streets: Callable) -> void:
	game = p_game
	_streets = streets
	_luck.seed = 1932008


## The beat cops in the loaded districts (M008): the ward's first.
func officers() -> Array[PoliceOfficer]:
	var out: Array[PoliceOfficer] = [officer]
	for id in _beat:
		var o: PoliceOfficer = _beat[id]
		if o != null and is_instance_valid(o):
			out.append(o)
	return out


## A district's beat cop, if it is built and he is on his feet (else null).
func officer_of(district: String) -> PoliceOfficer:
	var o: PoliceOfficer = officer if district == game.layout.id else _beat.get(district)
	return o if o != null and is_instance_valid(o) and not o.is_down() else null


## Whether a district's beat cop is free to stop somebody (an unloaded
## district's man is, in the abstract; a loaded one not while he is after Danny).
func can_stop(district: String) -> bool:
	if not game.world.is_ready(district):
		return true
	var o: PoliceOfficer = officer if district == game.layout.id else _beat.get(district)
	return o != null and is_instance_valid(o) and not o.is_down() and not o.brain.is_hunting()


## The ward's man, at start-up.
func add_ward_officer(o: PoliceOfficer) -> void:
	officer = o
	wire(o)


## A district's man came (or went: null).
func set_district_officer(id: String, o: PoliceOfficer) -> void:
	if o == null:
		_beat.erase(id)
	else:
		_beat[id] = o


func district_officer(id: String) -> PoliceOfficer:
	return _beat.get(id)


## M008: a beat cop in the game: his own revolver is seen and heard like
## anybody's (Danny's shots reach him through player_fired).
func wire(o: PoliceOfficer) -> void:
	o.player_walker = game.walker
	o.fired.connect(game.gunfire.on_fired)
	o.fired.connect(func(muzzle: Vector2, _dir: Vector2) -> void:
		for s in _streets.call():
			s.hear_gunshot(muzzle))


func wire_hud(o: PoliceOfficer) -> void:
	var hud := game.hud
	o.state_changed.connect(func(s: int) -> void: hud.set_police_status(s, any_armed()))
	o.gave_up.connect(func() -> void: hud.show_notice("You lost him."))
	o.drew_gun.connect(func() -> void:
		hud.show_notice("The copper draws his revolver!")
		hud.set_police_status(o.brain.state, true))


func any_armed() -> bool:
	return officers().any(func(o: PoliceOfficer) -> bool: return o.is_armed() and o.brain.is_hunting())


## Danny fired: every beat cop in earshot hears it (and takes a close one
## personally).
func player_fired(muzzle: Vector2, dir: Vector2) -> void:
	for o in officers():
		if not o.near_miss(muzzle, dir):
			o.hear_gunshot(muzzle, game.walker.gun.rules.noise_radius)


## Somebody else's gun went off (Lefty's): every beat cop hears it.
func hear_gunshot(at: Vector2, radius: float) -> void:
	for o in officers():
		o.hear_gunshot(at, radius)


## M008: a round struck something. Danny's rounds in a person are a crime any
## beat cop who could see it will answer with his revolver; somebody else's
## round in the car Danny is driving may go through to him.
func bullet_struck(collider: Object, at: Vector2, direction: Vector2, shooter: Node) -> void:
	var walker := game.walker
	if shooter == walker and collider is Walker and collider != walker:
		for o in officers():
			if o.body != collider:
				o.witness_violence((collider as Walker).global_position, walker.global_position)
	elif shooter != null and shooter != walker and not game.player.on_foot() and collider == game.player.car:
		if _luck.randf() < DRIVER_HIT_CHANCE:
			walker.hit_by_bullet(walker.global_position + direction * -2.0, direction, shooter)


## Whether any beat cop on his feet could see Danny at `at` (the café's car, M010).
func saw_danny_at(at: Vector2) -> bool:
	var witnessed := false
	for o in officers():
		if not o.is_down() and o.body.global_position.distance_to(at) <= game.police_rules.sight_range \
				and o.can_see(game.walker.global_position):
			witnessed = true
	return witnessed


## A violent crime in sight of any copper (a hold-up at gunpoint).
func witness_violence(victim: Vector2, culprit: Vector2) -> void:
	for o in officers():
		o.witness_violence(victim, culprit)


## A talk's "police": the shopkeeper Danny leaned on waits until he has gone,
## then runs out for the copper (only from inside a room).
func report_effect(v: Variant) -> void:
	if v and game.interiors.current != null:
		report_after(game.interiors.current, game.talk.speaker(game.dialogue.talking))


## M003: the shopkeeper waits until Danny has gone, then runs out for the copper.
func report_after(room: InteriorPlan, who: String) -> void:
	_report_from = room
	_report_who = who
	_report_left = REPORT_DELAY


func cancel_report() -> void:
	_report_from = null


## Someone runs out of the room shouting for the police once the player has
## left it (or after REPORT_DELAY seconds, whichever comes first).
func update_report(delta: float) -> void:
	if _report_from == null:
		return
	_report_left -= delta
	if game.interiors.current != _report_from or _report_left <= 0.0:
		var door := _report_from.outside_door(0, 30.0)
		_report_from = null
		officer.hear_gunshot(door, REPORT_RADIUS)
		game.hud.show_notice("%s runs into the street, shouting for the copper!" % _report_who)


## Danny went down: every copper thinks he got him.
func stand_down() -> void:
	for o in officers():
		o.stand_down()


## M015: a district's beat cop's mood on night `night` (the same all night, a new one most nights).
static func mood_of(district: String, night: int) -> String:
	return MOOD_ORDER[absi(night * 3 + hash(district)) % MOOD_ORDER.size()]


func _district_of(o: PoliceOfficer) -> String:
	if o == officer:
		return game.layout.id
	for id in _beat:
		if _beat[id] == o:
			return id
	return ""


## M015: every frame of the night: the posts at their hours, and a word to Danny in passing.
func beat_life(delta: float) -> void:
	var minute := game.clock.minute
	var danny := game.player.body().global_position
	for o in officers():
		if o.is_down():
			continue
		var id := _district_of(o)
		var l: DistrictLayout = game.world.layouts.get(id) if game.world != null else null
		var post := {}
		if l != null:
			for pp in l.police_posts:
				if minute >= float(pp.from) and minute < float(pp.until):
					post = pp
		if not post.is_empty() and o.duty.is_empty() and not o.brain.is_hunting():
			o.duty = {"pos": post.pos, "face": post.face, "post": true}
		elif post.is_empty() and bool(o.duty.get("post", false)):
			o.duty = {}
		_quiet[o] = float(_quiet.get(o, 0.0)) - delta
		if float(_quiet[o]) > 0.0 or o.brain.is_hunting() or game.street_lines == null:
			continue
		if o.body.global_position.distance_to(danny) > WORD_NEAR or not o.can_see(danny):
			continue
		_quiet[o] = WORD_EVERY
		var words: Array = MOODS[mood_of(id, game.rackets.night)]
		var line: String = String(post.line) if bool(o.duty.get("post", false)) else String(words[_luck.randi() % words.size()])
		game.street_lines.say(o.body, line)


## A new night: every man back on his beat.
func new_night() -> void:
	for o in officers():
		o.reset()
