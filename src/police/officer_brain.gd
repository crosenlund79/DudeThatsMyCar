class_name OfficerBrain
extends RefCounted
## The beat cop's decisions (pure, deterministic, no scene). He walks his beat
## until he hears gunfire (or is shot at). Then he freezes for a moment
## (ALERTED), runs towards where it came from and after you while he can see
## you (CHASE), and when he loses you goes to the last place he saw you,
## follows the way you were heading and looks round (SEARCH). If he does not
## find you in time he gives up and walks back to his beat (RETURN).
## He only learns where you are by seeing you (or hearing a shot): never by magic.
## M008: once he has *seen* a serious violent crime tonight (you shot somebody
## where he could see it, or you shot at him) he is armed: in a chase he
## keeps a gunfight's distance and fires his revolver when he has a clear
## shot (Marksman rules: range, cadence, a moment to aim first, stepping
## aside when a car or a person is in the way). Gunfire he only hears still
## gets the unarmed pursuit. Losing you works exactly as before.

enum State { PATROL, ALERTED, CHASE, SEARCH, RETURN }

var rules: PoliceRules
var state := State.PATROL
## Where he believes you are (or the shot came from).
var last_known := Vector2.ZERO
## Which way you were heading when he last saw you.
var last_heading := Vector2.ZERO
var beat: PackedVector2Array = PackedVector2Array()
var beat_index := 0
var _timer := 0.0
var _pause := 0.0
var _search_points: Array[Vector2] = []
var _look_phase := 0.0
## True on the tick he notices you (for the whistle and the "!"); a shot heard
## between two updates is reported by the next one.
var noticed_now := false
var _noticed_pending := false
## True on the tick he gives up (for "You lost him").
var gave_up_now := false
## M008: he has seen a serious violent crime tonight and will shoot.
var armed := false
var marksman: Marksman
var _was_seeing := false


func _init(p_rules: PoliceRules, p_beat: PackedVector2Array, seed_value: int = 1932008) -> void:
	rules = p_rules
	beat = p_beat
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	marksman = Marksman.new({"keep_at": rules.armed_keep_at, "too_close": rules.armed_too_close,
		"fire_range": rules.fire_range, "gap": rules.fire_gap, "jitter": rules.fire_jitter,
		"first_shot": rules.first_shot, "move_speed": rules.armed_move_speed}, rng)


func is_hunting() -> bool:
	return state in [State.ALERTED, State.CHASE, State.SEARCH]


## A shot rang out at `at`, `loudness` px away at most. Returns true when he
## heard it (and reacts).
func hear_gunshot(me: Vector2, at: Vector2, loudness: float) -> bool:
	if me.distance_to(at) > minf(loudness, rules.hearing_range):
		return false
	_notice(at, state != State.CHASE)
	return true


## A bullet struck him (or right by him) coming from `from`; `by_player`:
## it was yours (M008: that is a crime he saw - he draws).
func shot_at(from: Vector2, by_player: bool = false) -> void:
	if by_player:
		_arm()
	_notice(from, state != State.CHASE)


## M009: Danny butted in where he was not wanted (at `at`): the copper takes
## a hard look at him - comes over, unarmed, and follows him while he sees him.
func suspect(at: Vector2) -> void:
	_notice(at, state != State.CHASE)


## M008: he saw you shoot somebody (you were at `at`): he draws and comes after you.
func witness_violence(at: Vector2) -> void:
	_arm()
	_notice(at, state != State.CHASE)


func _arm() -> void:
	if not armed:
		armed = true
		marksman.ready_up()


## M008: you are down (or out of the fight): he stops, puts the revolver away and walks back.
func stand_down() -> void:
	if is_hunting():
		state = State.RETURN
	_was_seeing = false


## M006: he saw somebody break into a car at `at`: he goes to look (and if he
## sees the thief, gives chase as for gunfire).
func witness_theft(at: Vector2) -> void:
	_notice(at, state != State.CHASE)


func _notice(at: Vector2, startle: bool) -> void:
	last_known = at
	last_heading = Vector2.ZERO
	if startle:
		state = State.ALERTED
		_timer = rules.alert_time
		noticed_now = true
		_noticed_pending = true


## One decision tick. sees_player: he has you in sight right now (range and
## clear line of sight, checked by his body); player / player_velocity: where
## you are and how you move (only used while he sees you); clear_shot (M008):
## nothing stands in his line of fire.
## Returns {target: where to go, speed, look: where to face, icon: "", "alert"
## or "search", fire: pull the trigger now, draw: have the revolver out}.
func update(dt: float, me: Vector2, sees_player: bool, player: Vector2, player_velocity: Vector2,
		clear_shot: bool = true) -> Dictionary:
	var out := _decide(dt, me, sees_player, player, player_velocity, clear_shot)
	if not out.has("fire"):
		out["fire"] = false
	out["draw"] = armed and is_hunting()
	return out


func _decide(dt: float, me: Vector2, sees_player: bool, player: Vector2, player_velocity: Vector2,
		clear_shot: bool) -> Dictionary:
	noticed_now = _noticed_pending
	_noticed_pending = false
	gave_up_now = false
	_look_phase += dt
	if armed:
		marksman.cool(dt)
		if sees_player and not _was_seeing:
			marksman.hold_fire(rules.first_shot * 0.6)  # takes aim again
		_was_seeing = sees_player and is_hunting()
	match state:
		State.PATROL:
			return _patrol(dt, me)
		State.ALERTED:
			_timer -= dt
			if sees_player:
				_saw(player, player_velocity)
			if _timer <= 0.0:
				state = State.CHASE
			return {"target": me, "speed": 0.0, "look": last_known, "icon": "alert"}
		State.CHASE:
			if sees_player and armed:
				_saw(player, player_velocity)
				var shot := marksman.engage(dt, me, player, clear_shot)
				return {"target": shot.goal, "speed": shot.speed, "look": player, "icon": "alert", "fire": shot.fire}
			if sees_player:
				_saw(player, player_velocity)
				var stop := me.distance_to(player) <= rules.close_distance
				return {"target": me if stop else player, "speed": 0.0 if stop else rules.chase_speed, "look": player, "icon": "alert"}
			if me.distance_to(last_known) <= 24.0:
				_begin_search()
			return {"target": last_known, "speed": rules.chase_speed, "look": last_known, "icon": "alert"}
		State.SEARCH:
			if sees_player:
				_saw(player, player_velocity)
				state = State.CHASE
				noticed_now = true
				return {"target": player, "speed": rules.chase_speed, "look": player, "icon": "alert"}
			_timer -= dt
			if _timer <= 0.0:
				state = State.RETURN
				gave_up_now = true
				return _return(me)
			if not _search_points.is_empty() and me.distance_to(_search_points[0]) <= 24.0:
				_search_points.remove_at(0)
			var goal: Vector2 = me if _search_points.is_empty() else _search_points[0]
			var look := goal if goal != me else me + Vector2.from_angle(_look_phase * 1.6) * 100.0
			return {"target": goal, "speed": rules.search_speed, "look": look, "icon": "search"}
		State.RETURN:
			return _return(me)
	return {"target": me, "speed": 0.0, "look": me, "icon": ""}


func _saw(player: Vector2, velocity: Vector2) -> void:
	last_known = player
	if velocity.length() > 20.0:
		last_heading = velocity.normalized()


## Lost you at last_known: follow the way you went a little, then look round.
func _begin_search() -> void:
	state = State.SEARCH
	_timer = rules.search_time
	_search_points.clear()
	var ahead := last_known + last_heading * rules.follow_through
	if last_heading != Vector2.ZERO:
		_search_points.append(ahead)
	for k in 3:
		_search_points.append(ahead + Vector2.from_angle(k * TAU / 3.0 + 0.5) * 90.0)


func _patrol(dt: float, me: Vector2) -> Dictionary:
	if beat.is_empty():
		return {"target": me, "speed": 0.0, "look": me + Vector2.DOWN * 100.0, "icon": ""}
	var goal := beat[beat_index]
	if me.distance_to(goal) <= 10.0:
		_pause += dt
		if _pause >= rules.beat_pause:
			_pause = 0.0
			beat_index = (beat_index + 1) % beat.size()
		# looks out over the street while he waits
		return {"target": me, "speed": 0.0, "look": me + Vector2.from_angle(PI * 0.5 + sin(_look_phase * 0.7) * 0.9) * 100.0, "icon": ""}
	return {"target": goal, "speed": rules.patrol_speed, "look": goal, "icon": ""}


func _return(me: Vector2) -> Dictionary:
	if beat.is_empty():
		state = State.PATROL
		return {"target": me, "speed": 0.0, "look": me, "icon": ""}
	var nearest := 0
	for i in beat.size():
		if me.distance_to(beat[i]) < me.distance_to(beat[nearest]):
			nearest = i
	if me.distance_to(beat[nearest]) <= 12.0:
		state = State.PATROL
		beat_index = nearest
		_pause = 0.0
	return {"target": beat[nearest], "speed": rules.patrol_speed, "look": beat[nearest], "icon": ""}
