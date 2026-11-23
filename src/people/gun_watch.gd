class_name GunWatch
extends RefCounted
## M015: who sees the gun in Danny's hand, and what they do about it (the rules
## are GunSight's; passers-by see to themselves in StreetLife, the people who
## keep a place of business in their talk). Here, a few times a second:
## a copper with a clear view tells him to put it away and, if he doesn't
## within his patience, comes for him (unarmed, as for a man he suspects);
## Lefty Moran tells him where to point a handgun, and goes for his own gun at
## a Tommy gun; walking into a room with it out, the one who keeps the place
## says what they think of it (once a visit).

var game: Game
const LOOK_EVERY := 0.25
var _look := 0.0
## Copper -> {seen: seconds he has seen it since he warned Danny, away: seconds out of his sight}.
var _seen := {}
## The room a word has been said in this visit, and when Lefty last warned.
var _room_said := ""
var _lefty_said := -INF


func _init(p_game: Game) -> void:
	game = p_game


func update(delta: float) -> void:
	_look -= delta
	if _look > 0.0:
		return
	_look = LOOK_EVERY
	var level := game.armoury.shown_level()
	var me := game.walker.global_position
	_coppers(level, me)
	_lefty(level, me)
	_room(level, me)


## (A copper who loses sight of Danny for a moment - a lamp post, a newsstand
## between them - keeps counting; out of his sight longer than LOSE_AFTER, he
## lets it go. Put away, he says so.)
const LOSE_AFTER := 1.5


func _coppers(level: int, me: Vector2) -> void:
	for o in game.police.officers():
		if o.is_down() or o.brain.is_hunting():
			_seen.erase(o)
			continue
		var sees: bool = level > 0 and o.body.global_position.distance_to(me) <= GunSight.COPPER_SEES[level] and o.can_see(me)
		if not sees:
			if not _seen.has(o):
				continue
			if level == GunSight.NONE:
				game.overhead.say(o.body, "That's better. Keep it that way.")
				_seen.erase(o)
				continue
			var lost: Dictionary = _seen[o]
			lost.away = float(lost.away) + LOOK_EVERY
			if float(lost.away) > LOSE_AFTER:
				_seen.erase(o)
			continue
		var w: Dictionary = _seen.get(o, {})
		match GunSight.copper(float(w.seen) if not w.is_empty() else 0.0, level):
			"warn":
				game.overhead.say(o.body, "You there! Put that %s away!" % ("Tommy gun" if level == GunSight.THOMPSON else "gun"))
				o.body.aim_point = me
				_seen[o] = {"seen": LOOK_EVERY, "away": 0.0}
			"watch":
				w.seen = float(w.seen) + LOOK_EVERY
				w.away = 0.0
				o.body.aim_point = me
			"come":
				_seen.erase(o)
				o.brain.suspect(me)
				game.hud.show_notice("You didn't put it away. The copper's coming for you.")


func _lefty(level: int, me: Vector2) -> void:
	var rival := game.rival
	if rival == null or rival.is_down() or rival.is_hostile() or level == GunSight.NONE:
		return
	var d := rival.body.global_position.distance_to(me)
	if level == GunSight.THOMPSON and d <= GunSight.LEFTY_FIGHTS and rival.can_see(me):
		game.overhead.say(rival.body, "You point a Tommy gun at me, Mercer?")
		rival.provoke()
	elif d <= GunSight.LEFTY_WARNS and rival.can_see(me):
		var now := Time.get_ticks_msec() / 1000.0
		if now - _lefty_said > 20.0:
			_lefty_said = now
			game.overhead.say(rival.body, "Point that someplace else, Mercer.")


func _room(level: int, me: Vector2) -> void:
	var room := game.interiors.current
	if room == null:
		_room_said = ""
		return
	if level == GunSight.NONE or _room_said == room.id:
		return
	var view := game.interiors.view_of(room.id)
	if view == null:
		return
	for who in view.people:
		var w: Walker = view.people[who]
		if GunSight.SHY.has(who) and w != null and not w.down and view.person_ok(who) \
				and w.global_position.distance_to(me) <= GunSight.ROOM_NOTICE:
			_room_said = room.id
			game.overhead.say(w, GunSight.line(String(who), level))
			w.aim_point = me
			return
