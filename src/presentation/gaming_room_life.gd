class_name GamingRoomLife
extends Node
## M013: the gaming room alive while Danny is in it (presentation only: the
## money and the games are elsewhere). The regulars (Patrons, GamingRoom) come
## in at the door from the card room, go where the evening's schedule puts
## them - the wheel's rail, a machine, a drink at a little table, a corner to
## watch from - along the room's walking graph (RiversideInteriors.ROOM_*),
## stand or sit there looking the right way, now and then turn, sip, pull
## their machine (its sounds where it stands, now and then a few coins and a
## word), talk to one another (a line, an answer, the murmur), and go home by
## the same door. A regular at a machine Danny comes up to steps away to his
## other place. Nobody is simulated while Danny is elsewhere: as he walks in
## everyone is simply where the schedule says (enter()).
##
## Also the room itself: the smoke drifting and breathing, the lamps never
## quite steady.

## A regular has stepped up to the wheel's rail (true) or left it (false).
signal at_wheel(id: String, on: bool)

const WALK := 0.5  # of a walker's pace
const MACHINE_TIMES := [1.1, 1.6, 2.15]

var view: InteriorView
var room: GamingRoom
var lines: RoomLines
var sound: Soundscape
var rng := RandomNumberGenerator.new()
## id -> the place he is going to or at ("door": going home); his remaining path.
var goal := {}
var path := {}
## id -> the place he stands at now ("" while walking).
var here := {}
## id -> a place given up for Danny until the schedule moves on.
var yielded := {}
var _stuck := {}
var _last_pos := {}
var _pull := {}
var _idle := {}
var _chat := 20.0
## Sounds and lines a little later: [{t, kind, ...}].
var _later: Array = []
var _smoke: Array = []
var _time := 0.0
var _graph := {}
var _danny := Vector2.INF


func setup(p_view: InteriorView, p_room: GamingRoom, p_lines: RoomLines, p_sound: Soundscape) -> void:
	name = "GamingRoomLife"
	view = p_view
	room = p_room
	lines = p_lines
	sound = p_sound
	rng.randomize()
	for leg in RiversideInteriors.ROOM_LINKS:
		for k in 2:
			var a: String = leg[k]
			var b: String = leg[1 - k]
			if not _graph.has(a):
				_graph[a] = []
			_graph[a].append(b)
	for c in view.get_children():
		if c is Sprite2D and String(c.name).begins_with("smoke"):
			_smoke.append({"node": c, "pos": (c as Sprite2D).position, "rot": (c as Sprite2D).rotation, "ph": rng.randf() * TAU})


static func spot_pos(spot: String) -> Vector2:
	if RiversideInteriors.ROOM_SPOTS.has(spot):
		return RiversideInteriors.ROOM_SPOTS[spot][0]
	return RiversideInteriors.ROOM_NODES.get(spot, RiversideInteriors.ROOM_NODES.door)


static func spot_facing(spot: String) -> float:
	return float(RiversideInteriors.ROOM_SPOTS[spot][1]) if RiversideInteriors.ROOM_SPOTS.has(spot) else 0.0


func _walker(id: String) -> Walker:
	return view.people.get(id)


## Whether a regular can be about (not struck down, not carried off).
func _able(id: String) -> bool:
	var w := _walker(id)
	return w != null and not w.down and not view.out.has(id)


## Danny walks in: everyone where the schedule has them at `minute`.
func enter(minute: float) -> void:
	_later.clear()
	for id in Patrons.ROSTER:
		if not _able(id):
			continue
		var spot := _wanted(id, minute)
		var was: String = here.get(id, "")
		if was != "" and GamingRoom.kind_of(was) == "wheel" and was != spot:
			at_wheel.emit(id, false)
		path.erase(id)
		if spot == "":
			view.set_away(id, true)
			goal.erase(id)
			here.erase(id)
			continue
		view.set_away(id, false)
		_stand(id, spot)


func _stand(id: String, spot: String) -> void:
	var w := _walker(id)
	w.move = Vector2.ZERO
	w.place(spot_pos(spot), spot_facing(spot))
	w.aim_point = spot_pos(spot) + Vector2.from_angle(spot_facing(spot)) * 50.0
	goal[id] = spot
	here[id] = spot
	path.erase(id)
	_pull[id] = rng.randf_range(1.0, 5.0)
	_idle[id] = rng.randf_range(4.0, 12.0)
	if GamingRoom.kind_of(spot) == "wheel":
		at_wheel.emit(id, true)


## Where `id` wants to be at `minute` (his other place if this one was given up for Danny).
func _wanted(id: String, minute: float) -> String:
	var spot := room.spot_of(id, minute)
	if spot != "" and yielded.get(id, "") == spot:
		for pl in GamingRoom.PLAN[id].places:
			if String(pl[0]) != spot:
				return String(pl[0])
	if yielded.get(id, "") != spot:
		yielded.erase(id)
	return spot


## A frame in the room: `danny` where Danny stands, `danny_machine` the
## machine he is playing (-1: none).
func update(delta: float, minute: float, danny: Vector2, danny_machine: int) -> void:
	_time += delta
	_danny = danny
	_room_breathes()
	_run_later(delta)
	for id in Patrons.ROSTER:
		if not _able(id):
			continue
		_give_way(id, danny, danny_machine)
		var want := _wanted(id, minute)
		var w := _walker(id)
		var visible := w.visible
		if want == "":
			if visible and goal.get(id, "") != "door":
				_head_for(id, "door")
			elif not visible:
				continue
		elif not visible:
			view.set_away(id, false)  # in at the door from the card room
			w.place(spot_pos("door"), PI)
			here[id] = ""
			_head_for(id, want)
		elif goal.get(id, "") != want:
			_head_for(id, want)
		_walk(id, delta)
		if here.get(id, "") != "":
			_while_there(id, delta)
	_chatter(delta)


func _give_way(id: String, danny: Vector2, danny_machine: int) -> void:
	var spot: String = goal.get(id, "")
	if not spot.begins_with("slot_"):
		return
	var k := int(spot.substr(5))
	var front: Vector2 = RiversideInteriors.SLOTS[k] + Vector2(0, 32)
	if danny_machine == k or danny.distance_to(front) < 64.0:
		yielded[id] = spot  # Danny wants that machine: off to his other place


func _head_for(id: String, spot: String) -> void:
	var was: String = here.get(id, "")
	if was != "" and GamingRoom.kind_of(was) == "wheel":
		at_wheel.emit(id, false)
	goal[id] = spot
	here[id] = ""
	path[id] = _route(_walker(id).global_position, was, spot)
	_stuck[id] = 0.0


## The points from where he is (at `from_spot`, or wherever) to `spot`.
func _route(at: Vector2, from_spot: String, spot: String) -> Array:
	var start := _node_of(from_spot) if from_spot != "" else _nearest_node(at)
	var end := _node_of(spot) if RiversideInteriors.ROOM_SPOTS.has(spot) else spot
	var prev := {start: ""}
	var queue := [start]
	while not queue.is_empty():
		var c: String = queue.pop_front()
		if c == end:
			break
		for n in _graph.get(c, []):
			if not prev.has(n) and RiversideInteriors.ROOM_NODES.has(n):
				prev[n] = c
				queue.append(n)
	var pts := []
	var k := end
	while k != "":
		pts.push_front(spot_pos(k))
		k = prev.get(k, "")
	if RiversideInteriors.ROOM_SPOTS.has(spot):
		pts.append(spot_pos(spot))
	return pts


func _node_of(spot: String) -> String:
	if RiversideInteriors.ROOM_NODES.has(spot):
		return spot
	for n in _graph.get(spot, []):
		if RiversideInteriors.ROOM_NODES.has(n):
			return n
	return "door"


func _nearest_node(at: Vector2) -> String:
	var best := "door"
	for n in RiversideInteriors.ROOM_NODES:
		if at.distance_to(RiversideInteriors.ROOM_NODES[n]) < at.distance_to(RiversideInteriors.ROOM_NODES[best]):
			best = n
	return best


func _walk(id: String, delta: float) -> void:
	var pts: Array = path.get(id, [])
	var w := _walker(id)
	if pts.is_empty():
		return
	var next: Vector2 = pts[0]
	var to := next - w.global_position
	if to.length() < 4.0:
		pts.pop_front()
		if pts.is_empty():
			_arrive(id)
		return
	w.move = to.normalized() * WALK
	w.aim_point = next + to.normalized() * 30.0
	# stuck behind somebody (Danny, another regular) for a while: on to the next point
	var moved := w.global_position.distance_to(_last_pos.get(id, w.global_position))
	_last_pos[id] = w.global_position
	_stuck[id] = float(_stuck.get(id, 0.0)) + delta if moved < 0.2 else 0.0
	if float(_stuck[id]) > 2.5 and next.distance_to(_danny) > 26.0:  # never onto Danny (he would be pushed)
		w.place(next, w.model.facing)
		_stuck[id] = 0.0


func _arrive(id: String) -> void:
	var spot: String = goal.get(id, "")
	path.erase(id)
	var w := _walker(id)
	w.move = Vector2.ZERO
	if spot == "door":
		view.set_away(id, true)  # home for the night
		here.erase(id)
		goal.erase(id)
		return
	_stand(id, spot)


## What a regular does at his place: a turn of the head, a sip, a pull of his machine.
func _while_there(id: String, delta: float) -> void:
	var spot: String = here[id]
	var w := _walker(id)
	var home_aim := spot_pos(spot) + Vector2.from_angle(spot_facing(spot)) * 50.0
	_idle[id] = float(_idle.get(id, 8.0)) - delta
	if float(_idle[id]) <= 0.0:
		_idle[id] = rng.randf_range(5.0, 13.0)
		if w.aim_point.distance_to(home_aim) > 1.0:
			w.aim_point = home_aim
		else:
			w.aim_point = spot_pos(spot) + Vector2.from_angle(spot_facing(spot) + rng.randf_range(-0.9, 0.9)) * 50.0
			if GamingRoom.kind_of(spot) == "idle" and rng.randf() < 0.35:
				sound.play_at("gaming/glass", spot_pos(spot), -17.0)  # a sip, the glass set down
	if GamingRoom.kind_of(spot) == "slots":
		_pull[id] = float(_pull.get(id, 4.0)) - delta
		if float(_pull[id]) <= 0.0:
			_pull[id] = rng.randf_range(4.5, 8.5)
			_machine_pull(id, int(spot.substr(5)))


## A regular pulls his machine: the lever, the three stops where it stands;
## now and then a few coins, and a word.
func _machine_pull(id: String, k: int) -> void:
	var at: Vector2 = RiversideInteriors.SLOTS[k]
	sound.play_at("slots/lever", at, -14.0)
	for i in 3:
		_later.append({"t": MACHINE_TIMES[i], "kind": "sound", "id": "slots/stop", "at": at, "db": -16.0})
	if rng.randf() < 0.18:
		for c in rng.randi_range(2, 6):
			_later.append({"t": 2.4 + c * 0.09, "kind": "sound", "id": "slots/coin", "at": at, "db": -18.0})
		if rng.randf() < 0.5:
			_later.append({"t": 2.6, "kind": "line", "who": id, "text": Patrons.line(id, "win", rng)})
	elif rng.randf() < 0.12:
		_later.append({"t": 2.4, "kind": "line", "who": id, "text": Patrons.line(id, "lose", rng)})


## Two regulars near each other pass the time now and then (a line, an answer, the murmur).
func _chatter(delta: float) -> void:
	_chat -= delta
	if _chat > 0.0:
		return
	_chat = rng.randf_range(30.0, 70.0)
	var pairs := Patrons.CHATTER.duplicate()
	pairs.shuffle()
	for c in pairs:
		var a := _walker(String(c[0]))
		var b := _walker(String(c[1]))
		if a == null or b == null or not a.visible or not b.visible or here.get(c[0], "") == "" or here.get(c[1], "") == "":
			continue
		if a.global_position.distance_to(b.global_position) > 150.0:
			continue
		lines.say(a, String(c[2]))
		_later.append({"t": 2.4, "kind": "line", "who": String(c[1]), "text": String(c[3])})
		sound.play_at("gaming/murmur", (a.global_position + b.global_position) * 0.5, -14.0)
		return
	_chat = 8.0  # nobody close enough: soon again


func _run_later(delta: float) -> void:
	var due := []
	for e in _later:
		e.t = float(e.t) - delta
		if float(e.t) <= 0.0:
			due.append(e)
	for e in due:
		_later.erase(e)
		match String(e.kind):
			"sound":
				sound.play_at(String(e.id), e.at, float(e.db))
			"line":
				var w := _walker(String(e.who))
				if w != null and w.visible and String(e.text) != "":
					lines.say(w, String(e.text))


## The room's air: the smoke drifting and breathing, the lamps never quite steady.
func _room_breathes() -> void:
	for sm in _smoke:
		var s: Sprite2D = sm.node
		if not is_instance_valid(s):
			continue
		var ph: float = sm.ph
		s.position = (sm.pos as Vector2) + Vector2(sin(_time * 0.13 + ph) * 7.0, cos(_time * 0.09 + ph) * 4.0)
		s.rotation = float(sm.rot) + sin(_time * 0.05 + ph) * 0.25
		s.modulate.a = 0.75 + 0.2 * sin(_time * 0.4 + ph)
	var mults := []
	for i in view.lights.size():
		mults.append(1.0 + 0.03 * sin(_time * 6.1 + i * 1.7) * sin(_time * 1.3 + i))
	view.flicker(mults)


## The regulars in their places at a glance (for tests and the probe).
func standing() -> Dictionary:
	var out := {}
	for id in here:
		if String(here[id]) != "":
			out[id] = here[id]
	return out
