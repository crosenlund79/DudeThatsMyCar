class_name Dialogue
extends RefCounted
## M014 (from main): talking in the game - who Danny is talking to, the page on
## screen, his answers, and what a page's effects do. The words and the
## bookkeeping are the pure Conversations; this is the game side. Effects are
## handed to the system that owns them, in one fixed order (EFFECTS), through
## handlers the systems register; a talk ending is announced the same way
## (end hooks, in the order registered). Neither list knows about missions.

## The effects a page can have, in the order they are applied (as M003-M012
## applied them). A handler gets (value, all effects).
const EFFECTS := ["incident", "opportunity", "fight", "bird_scene", "freight", "job", "heal", "rounds",
	"thompson", "parcel", "cafe", "police"]

var game: Game
## Who the player is talking to ("" = nobody) and the page on screen.
var talking := ""
var page := {}
## M009: the incident Danny is stepping into ("" for none).
var incident_talking := ""
var _effects := {}
var _end_hooks: Array[Callable] = []
var _context_parts: Array[Callable] = []
## What "sleep" on a page does (the night's end: main's sleep).
var on_sleep: Callable


func _init(p_game: Game) -> void:
	game = p_game


## `key` (one of EFFECTS) is handled by `handler(value, effects)`. One handler
## a key: a second, or a key Dialogue does not apply, is refused (false).
func on_effect(key: String, handler: Callable) -> bool:
	if not EFFECTS.has(key) or _effects.has(key):
		push_warning("Dialogue: effect '%s' %s" % [key, "already has a handler" if _effects.has(key) else "is not applied"])
		return false
	_effects[key] = handler
	return true


## `part()` returns more of a talk's context (keys a page may read), merged in
## the order parts were added.
func on_context(part: Callable) -> void:
	_context_parts.append(part)


## `hook(who)` is called as a talk with `who` ends (before it is cleared), in
## the order hooks were added.
func on_end(hook: Callable) -> bool:
	if _end_hooks.has(hook):
		push_warning("Dialogue: the same end hook twice")
		return false
	_end_hooks.append(hook)
	return true


func context() -> Dictionary:
	var walker := game.walker
	var clock := game.clock
	var rival := game.rival
	var r := game.rackets
	var out := {"gun_drawn": walker.gun != null and walker.gun.is_drawn(), "spare": walker.gun.spare if walker.gun != null else 0,
		"time": clock.text(), "minute": clock.minute, "late": clock.is_late(), "done": game.stage.done,
		"first_meeting": game.voice_lines.due(Conversations.greeting_line(talking)),
		"treatment": walker.condition.treatment_price(), "lefty_dead": rival != null and rival.is_down(),
		"lefty_hurt": rival != null and rival.body.condition.worst() >= BodyCondition.Level.WOUNDED,
		"danny_worst": walker.condition.worst(), "night": r.night, "money": r.money,
		"incident_kind": game.incidents.get_incident(incident_talking).get("kind", "") if incident_talking != "" else ""}
	for part in _context_parts:
		out.merge(part.call(), true)
	return out


## Talks to `who` in the room Danny is in (they turn to him); answering a
## call-out from them if one is waiting.
func start(who: String, extra: Dictionary = {}) -> void:
	extra = extra.merged(game.people.answer(who))  # M012: answering a call-out
	talking = who
	var interiors := game.interiors
	if interiors.current != null:
		interiors.view_of(interiors.current.id).face(who, game.walker.global_position)
	show(game.talk.open(who, context().merged(extra, true)))


## Talks to someone outside a room (Lefty, a contact, an incident): no turning
## round, no call-out.
func open(who: String) -> void:
	talking = who
	show(game.talk.open(who, context()))


func show(p: Dictionary) -> void:
	if p.is_empty():
		end()
		return
	page = p
	game.hud.show_dialogue(p)
	if p.has("voice") and not game.voice.say(p.voice).is_empty():
		game.save()  # a first meeting is remembered even if the game is quit at once


## While talking, the player's keys answer (1-4) or walk away (E).
func converse(cmd: PlayerCommand) -> bool:
	if game.back_rooms.at_a_table():
		return true  # M010: sitting in at the card table; M011: at the wheel or a machine
	if talking == "":
		return false
	if cmd.choice > 0:
		answer(cmd.choice - 1)
	elif cmd.interact:
		end()
	return true


## Picks answer i (0-based) on the page on screen.
func answer(i: int) -> void:
	if talking == "" or i < 0 or i >= (page.options as Array).size():
		return
	var r := game.rackets
	var money := r.money
	var bottles := r.bottles
	var next := game.talk.choose(talking, page.options[i].id, context())
	if next.get("effects", {}).get("sleep", false):
		on_sleep.call()
		return
	game.soundscape.play_deal(talking, r.money - money, r.bottles - bottles)
	apply(next.get("effects", {}))
	game.hud.set_purse(r.money, r.bottles, r.held)
	game.save()
	show(next)


## What a page does outside the money: each effect to the system that owns it.
func apply(effects: Dictionary) -> void:
	for key in EFFECTS:
		if effects.has(key) and _effects.has(key):
			(_effects[key] as Callable).call(effects[key], effects)


func end() -> void:
	incident_talking = ""
	for hook in _end_hooks:
		hook.call(talking)
	talking = ""
	page = {}
	if game.player != null:
		game.player.fire_lock = true  # M012: the click on the last answer is not a shot
	if game.voice != null:
		game.voice.stop()
	game.hud.hide_dialogue()
	for v in game.interiors.views:
		v.face_home()
