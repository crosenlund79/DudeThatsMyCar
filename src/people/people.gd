class_name People
extends RefCounted
## M014 (from main): the people of the city, a little more alive (M012) - who
## is where at this hour (Routines: Quilty home at one, Leon at Dutch's after
## midnight) and who calls out to Danny (Callouts), checked a few times a
## second, never every person every frame. The rules are the pure Callouts and
## Routines; this is their game side: the line over a head, a few steps his
## way, back to their place, Leon's figure at Dutch's counter.

## M012: who may call out to Danny, and the room they are in.
const CALLERS := {"rourke": "copper_owl", "augie": "copper_owl", "bird": "copper_owl", "eddie": "hardware",
	"quilty": "quilty_office", "leon": "dispatch_office"}
## Those who come over a few steps when they call, and where to (from their
## place: round the desk or the counter, clear of the furniture); the rest
## call from where they are.
const COME_OVER := {"eddie": Vector2(30, 0), "quilty": Vector2(-50, 8), "leon": Vector2(-58, 0)}

var game: Game
## M012: a call-out waiting for an answer: {id, who, walker, home, facing,
## left (s), answered, returning}; {} for none.
var callout := {}
var _callout_tick := 0.0
## When a gun last went off within earshot (s, engine time).
var last_gunfire := -1000.0
## M012: Leon at Dutch's counter after midnight (made with the yards, freed with them).
var leon_at_dutch: Walker
## Whether a named person is out tonight (carried off to the Doc's): `is_out(id)`.
var is_out: Callable


func _init(p_game: Game) -> void:
	game = p_game


## A gun went off (Danny's, or a round struck something): nobody calls out for a while.
func gunfire() -> void:
	last_gunfire = Time.get_ticks_msec() / 1000.0


func since_gunfire() -> float:
	return Time.get_ticks_msec() / 1000.0 - last_gunfire


## Who calls out (unless one is waiting for an answer). `enabled`: call-outs
## at all (scene tests switch them off); `busy()`: what Danny is in the middle
## of (see Callouts.pick), asked only when someone might call.
func update_callouts(delta: float, enabled: bool, busy: Callable) -> void:
	if not callout.is_empty():
		_callout_follow(delta)
		return
	_callout_tick -= delta
	if _callout_tick > 0.0 or not enabled:
		return
	_callout_tick = 0.25
	var player := game.player
	var interiors := game.interiors
	if not player.on_foot() or interiors.current == null:
		return
	var room := interiors.current.id
	var v := interiors.view_of(room)
	var r := game.rackets
	var ctx: Dictionary = (busy.call() as Dictionary).merged({"minute": game.clock.minute, "driving": not player.on_foot(),
		"since_gunfire": since_gunfire(), "rourke_business": r.job.rourke_has_business(r.night),
		"singing": game.stage.singing()})
	for who in CALLERS:
		if CALLERS[who] != room or v == null or not v.person_ok(who):
			continue
		var w: Walker = v.people.get(who)
		ctx["near"] = game.walker.global_position.distance_to(w.global_position)
		var id := r.callouts.pick(who, ctx, r)
		if id != "":
			_call_out(id, who, w)
			return


## M012: `who` calls out to Danny: the line over his head, a turn towards
## him, and (some of them) a few steps his way. E answers; walking on ignores it.
func _call_out(id: String, who: String, w: Walker) -> void:
	game.rackets.callouts.mark(id, game.clock.minute)
	game.overhead.say(w, String(Callouts.LINES[id].call))
	var home := w.global_position
	var facing := w.model.facing
	for v in game.interiors.views:
		for p in v.plan.people:
			if v.people.get(p.id) == w:
				home = p.pos
				facing = p.facing
	callout = {"id": id, "who": who, "walker": w, "home": home, "facing": facing,
		"left": Callouts.ANSWER_SECONDS, "answered": false, "returning": false}
	game.save()  # what was said stays said


## Danny opened a talk with `who`: answering a call-out waiting from him
## gives the talk its context (and marks it answered). {} when it is not one.
func answer(who: String) -> Dictionary:
	if not callout.is_empty() and callout.who == who and not callout.answered:
		callout.answered = true
		return {"callout": callout.id}
	return {}


func _callout_follow(delta: float) -> void:
	var w: Walker = callout.walker
	if not is_instance_valid(w) or w.down:
		callout = {}
		return
	var overhead := game.overhead
	if not w.is_visible_in_tree():  # out of sight (he left the room): back in their place at once
		w.move = Vector2.ZERO
		w.place(callout.home, callout.facing)
		w.aim_point = (callout.home as Vector2) + Vector2.from_angle(callout.facing) * 50.0
		overhead.hush()
		callout = {}
		return
	var home: Vector2 = callout.home
	if callout.returning:
		var back := home - w.global_position
		callout.left = float(callout.left) - delta
		if back.length() < 4.0 or not COME_OVER.has(callout.who) or callout.left <= 0.0:
			w.move = Vector2.ZERO
			w.place(home, callout.facing)
			w.aim_point = home + Vector2.from_angle(callout.facing) * 50.0
			callout = {}
		else:
			w.move = back.normalized() * 0.6
			w.aim_point = home
		return
	callout.left = float(callout.left) - delta
	var walker := game.walker
	var talking := game.dialogue.talking
	var to := walker.global_position - w.global_position
	w.aim_point = walker.global_position
	w.move = Vector2.ZERO
	if COME_OVER.has(callout.who) and talking != callout.who:  # a few steps his way, round the furniture
		var step: Vector2 = home + COME_OVER[callout.who] - w.global_position
		if step.length() > 3.0 and to.length() > 40.0:
			w.move = step.normalized() * 0.6
	var over: bool = callout.answered and talking != callout.who
	if over or callout.left <= 0.0 or to.length() > Callouts.RANGE * 1.6 or not game.player.on_foot():
		overhead.hush()
		callout.returning = true  # back to their place
		callout.left = 6.0  # however they get there (a chair in the way: they are back in it all the same)


## M012: Quilty goes home at one; Leon has his coffee at Dutch's after midnight.
func apply_routines() -> void:
	var interiors := game.interiors
	var minute := game.clock.minute
	var qv := interiors.view_of("quilty_office")
	if qv != null:
		qv.set_away("quilty", not Routines.in_room("quilty", minute))
	var lv := interiors.view_of("dispatch_office")
	if lv != null:
		lv.set_away("leon", not Routines.in_room("leon", minute))
	var world := game.world
	var at_dutch: bool = Routines.where("leon", minute) == "dutch" and world.is_ready("yards") \
		and not is_out.call("leon")
	if at_dutch and leon_at_dutch == null:
		leon_at_dutch = Walker.create(game.resolver, "characters/dispatcher", {"glow": false})
		leon_at_dutch.name = "LeonAtDutch"
		world.loaded["yards"].node.add_child(leon_at_dutch)
		var at := game.locations.at("yards/place/leon_at_dutch")
		leon_at_dutch.place(at, PI / 2)
		leon_at_dutch.aim_point = at + Vector2(0, 50)
	if leon_at_dutch != null and is_instance_valid(leon_at_dutch):
		leon_at_dutch.visible = at_dutch


## Leon at Dutch's counter, if he is there to be talked to near `p`: the spot.
func leon_spot(p: Vector2) -> Dictionary:
	if leon_at_dutch != null and leon_at_dutch.visible and p.distance_to(leon_at_dutch.global_position) < 40.0:
		return {"id": "leon", "prompt": "Talk to Leon Sobczak", "routine": true, "pos": leon_at_dutch.global_position}
	return {}


## A district is about to be freed: whoever was made with it goes with it.
func district_unloading(id: String) -> void:
	if id == "yards":
		leon_at_dutch = null  # freed with the yards
	if not callout.is_empty() and not is_instance_valid(callout.walker):
		callout = {}
