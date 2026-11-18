class_name IncidentViews
extends Node2D
## The city's incidents (M009) where Danny can see them: only an incident in
## a built district near the camera gets people - two passers-by arguing at a
## kerb, a pair in an alley with a package, the district's own beat cop
## questioning somebody - posed for the phase it has reached on the clock
## (coming upon an exchange half way through, the second man is already half
## way there), facing each other, saying a short line now and then when Danny
## is close enough to hear. When it ends they walk off (or run), and are let
## go once out of sight. Far away or in a district that is not built, an
## incident is only its state (StreetIncidents); nothing here keeps it going.
## Presentation only, apart from telling the model when its people are shot,
## scared off by gunfire, or its copper is called away.

signal person_struck(incident_id: String)

## Incidents this close to the camera get people; their words show this close to Danny.
const REACH := 1100.0
const TALK_REACH := 520.0
## Two people this far either side of the spot; the second man of an exchange
## comes from this far off.
const PAIR := 22.0
const CLOSE := 13.0
const APPROACH := 260.0
const LINE_TIME := 2.6
const WALK := 62.0
const RUN := 150.0
## People who have finished walk this long before they are let go anyway.
const LEAVE_TIME := 14.0
## What people say, by kind and phase (index into the incident's people) -
## the last phase by outcome.
const LINES := {
	"argument": {
		"talking": [[0, "You backed into my fender, pal."], [1, "That dent was there before I parked."], [0, "Like hell it was."]],
		"heated": [[1, "Say that again!"], [0, "You want a sock in the jaw?"], [1, "Go on, I dare you!"]],
		"settled": [[0, "Aw, forget it."], [1, "...Yeah. Forget it."]],
		"blows": [[0, "That's for the fender!"], [1, "My nose! You broke my nose!"]],
		"broken_up": [[1, "Fine. Fine!"], [0, "This ain't over."]],
		"scattered": [[0, "We're going, we're going!"]],
	},
	"exchange": {
		"waiting": [[0, "Come on, come on..."]],
		"handing": [[0, "You got it?"], [1, "Count it later."]],
		"done": [[1, "Same time Thursday."]],
		"spoiled": [[0, "Scram!"], [1, "Some other night."]],
		"hushed": [[0, "Here. Now beat it."]],
		"robbed": [[1, "Don't shoot!"], [0, "You'll pay for this, mister."]],
	},
	"stop": {
		"questioning": [[0, "Evening. Where you headed, mister?"], [1, "Just going home, officer."], [0, "Let's see some identification."]],
		"searching": [[0, "Turn out your pockets."], [1, "That's my lunch!"], [0, "What's this, then?"]],
		"released": [[0, "Go on home."]],
		"taken_in": [[0, "You're coming with me."], [1, "I ain't done nothing!"]],
		"vouched": [[0, "Move along. Both of you."]],
		"bribed": [[0, "...Go on home, then."]],
	},
}
const LOOKS := {
	"argument": [["characters/worker", "characters/patron_man"], ["characters/clerk", "characters/worker"]],
	"exchange": [["characters/worker", "characters/patron_man"], ["characters/patron_man", "characters/worker"]],
	"stop": [["characters/worker"], ["characters/lady"], ["characters/patron_man"]],
}

var resolver: AssetResolver
var model: StreetIncidents
var font: Font
## func(district id) -> bool: the district is built (its incidents can be shown).
var is_shown: Callable
## func(district id) -> PoliceOfficer or null: the district's beat cop, if built and on his feet.
var officer_for: Callable
## id -> {people: [Walker] (for a stop the civilian only), officer, label, line, line_left, done, outcome, leave_left, package}
var views := {}


func setup(p_resolver: AssetResolver, p_model: StreetIncidents, p_font: Font) -> void:
	name = "IncidentViews"
	resolver = p_resolver
	model = p_model
	font = p_font


## Every frame: people for the incidents near the camera, posed for where
## each incident has got to; those that have ended walk off.
func refresh(view_centre: Vector2, danny: Vector2, delta: float) -> void:
	for inc in model.active:
		if inc.kind == "stop" and model.phase_name(inc) != "leaving":
			_officer_on_duty(inc)  # a built district's beat cop goes to his stop, seen or not
		var near: bool = (not is_shown.is_valid() or is_shown.call(inc.spot.district)) \
			and view_centre.distance_to(inc.spot.pos) < REACH
		if near and not views.has(inc.id):
			_make(inc)
		elif not near and views.has(inc.id):
			_drop(inc.id)
		if views.has(inc.id):
			inc.seen = true
			_pose(inc, views[inc.id], danny, delta)
	for id in views.keys():
		var v: Dictionary = views[id]
		if not v.done and model.get_incident(id).is_empty():
			_ended(id, v)
		if v.done:
			_walk_off(id, v, view_centre, danny, delta)


## The people of an incident (for E and tests): [Walker] (for a stop the officer first).
func people_of(id: String) -> Array:
	if not views.has(id):
		return []
	var v: Dictionary = views[id]
	var out := []
	if v.officer != null and is_instance_valid(v.officer):
		out.append((v.officer as PoliceOfficer).body)
	for p in v.people:
		if is_instance_valid(p):
			out.append(p)
	return out


## The incident going on whose people are within `reach` of p ({} if none).
func incident_near(p: Vector2, reach: float) -> Dictionary:
	for id in views:
		var v: Dictionary = views[id]
		if v.done:
			continue
		for w in people_of(id):
			if (w as Walker).global_position.distance_to(p) <= reach and not (w as Walker).down:
				return model.get_incident(id)
	return {}


## A shot rang out at `at`: anybody arguing or dealing close by breaks off and runs.
func hear_gunshot(at: Vector2, reach: float = 350.0) -> Array:
	var ended := []
	for inc in model.active.duplicate():
		if views.has(inc.id) and (inc.spot.pos as Vector2).distance_to(at) < reach and inc.kind != "stop":
			var e := model.break_off(inc.id, "fled")
			if not e.is_empty():
				ended.append(e)
	return ended


# ------------------------------------------------------------------ people

func _make(inc: Dictionary) -> void:
	var looks: Array = LOOKS[inc.kind]
	var pick: Array = looks[absi(hash(inc.id)) % looks.size()]
	var v := {"people": [], "officer": null, "label": null, "line": 0, "line_left": 0.0, "done": false, "outcome": "",
		"leave_left": LEAVE_TIME, "package": null, "shove": 0.0}
	var place := _places(inc)
	for i in pick.size():
		var w := Walker.create(resolver, pick[i], {"glow": false})
		w.name = "Incident_%s_%d" % [inc.id, i]
		w.add_to_group("incident_people")
		add_child(w)
		w.place(place[i], 0.0)
		w.model.walk_speed = WALK
		w.struck_down.connect(func() -> void: person_struck.emit(inc.id))
		w.hurt.connect(func(_r: String, _l: int) -> void: person_struck.emit(inc.id))
		v.people.append(w)
	if inc.kind == "exchange":
		var pkg := Sprite2D.new()
		pkg.texture = resolver.get_texture("props/crate")
		pkg.scale = AssetCatalog.scale_for(pkg.texture, Vector2(11, 11))
		pkg.z_index = Layers.Z_ACTOR + 2
		pkg.z_as_relative = false
		pkg.visible = false
		add_child(pkg)
		v.package = pkg
	var label := Label.new()
	label.z_index = Layers.Z_MIST + 3
	label.z_as_relative = false
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("f3e3c0"))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 5)
	var back := StyleBoxFlat.new()  # a soft dark backing: readable over a lit facade
	back.bg_color = Color(0.05, 0.04, 0.04, 0.6)
	back.set_corner_radius_all(4)
	back.content_margin_left = 5.0
	back.content_margin_right = 5.0
	back.content_margin_top = 1.0
	back.content_margin_bottom = 1.0
	label.add_theme_stylebox_override("normal", back)
	label.visible = false
	add_child(label)
	v.label = label
	views[inc.id] = v


## Where the people stand for the incident's phase and progress (the
## officer's own place is his duty, not here).
func _places(inc: Dictionary) -> Array:
	var pos: Vector2 = inc.spot.pos
	var along: Vector2 = inc.spot.along
	var phase := model.phase_name(inc)
	match inc.kind:
		"argument":
			return [pos - along * PAIR, pos + along * PAIR]
		"exchange":
			if phase == "waiting":
				return [pos - along * CLOSE, pos + along * (CLOSE + APPROACH * (1.0 - model.progress(inc)))]
			return [pos - along * CLOSE, pos + along * CLOSE]
		"stop":
			return [pos + along * 6.0]
	return [pos]


func _pose(inc: Dictionary, v: Dictionary, danny: Vector2, delta: float) -> void:
	var people: Array = v.people
	var phase := model.phase_name(inc)
	var last: bool = inc.phase >= (StreetIncidents.PHASES[inc.kind] as Array).size() - 1
	if last:
		# how it ends is settled: they say so (they walk off once it is over, _ended)
		_speak(inc, v, String(inc.outcome), danny, delta)
		return
	var targets := _places(inc)
	var other_of := func(i: int) -> Vector2:
		if inc.kind == "stop":
			return (v.officer as PoliceOfficer).body.global_position if v.officer != null and is_instance_valid(v.officer) else inc.spot.pos
		return (people[1 - i] as Walker).global_position if people.size() > 1 else inc.spot.pos
	for i in people.size():
		var w: Walker = people[i]
		if w.down:
			continue
		_hold(w, targets[i], other_of.call(i))
	if inc.kind == "stop":
		v.officer = officer_for.call(inc.spot.district) if officer_for.is_valid() else null
	if inc.kind == "exchange" and v.package != null:
		v.package.visible = phase == "handing"
		if phase == "handing" and people.size() > 1:
			var t := fmod(model.progress(inc) * 3.0, 1.0)
			v.package.global_position = (people[1] as Walker).global_position.lerp((people[0] as Walker).global_position, t) + Vector2(0, -4)
	if inc.kind == "argument" and phase == "heated" and people.size() > 1:
		v.shove -= delta
		if v.shove <= 0.0:
			v.shove = 1.3
			var w2: Walker = people[int(Time.get_ticks_msec() / 1300) % 2]
			_recoil(w2, (w2.global_position - inc.spot.pos).normalized())
	_speak(inc, v, phase, danny, delta)


## A person walks to `target` and faces `face`.
func _hold(w: Walker, target: Vector2, face: Vector2) -> void:
	var to := target - w.global_position
	w.model.walk_speed = WALK
	w.move = to.normalized() if to.length() > 4.0 else Vector2.ZERO
	w.aim_point = face if to.length() <= 30.0 else target


func _recoil(w: Walker, away: Vector2) -> void:
	w.sprite.position = away * 4.0
	var t := create_tween()
	t.tween_property(w.sprite, "position", Vector2.ZERO, 0.2)


## The district's beat cop questions the civilian (his own body, sent there on duty).
func _officer_on_duty(inc: Dictionary) -> void:
	if is_shown.is_valid() and not is_shown.call(inc.spot.district):
		return
	var cop: PoliceOfficer = officer_for.call(inc.spot.district) if officer_for.is_valid() else null
	if cop == null:
		return
	cop.duty = {"pos": (inc.spot.pos as Vector2) - (inc.spot.along as Vector2) * 24.0,
		"face": (inc.spot.pos as Vector2) + (inc.spot.along as Vector2) * 6.0}


func _speak(inc: Dictionary, v: Dictionary, key: String, danny: Vector2, delta: float) -> void:
	var label: Label = v.label
	var lines: Array = (LINES[inc.kind] as Dictionary).get(key, [])
	var hear := danny.distance_to(inc.spot.pos) < TALK_REACH and not lines.is_empty()
	v.line_left = float(v.line_left) - delta
	if v.line_left <= 0.0 or label.get_meta("key", "") != key:
		if label.get_meta("key", "") != key:
			v.line = 0
		label.set_meta("key", key)
		v.line_left = LINE_TIME
		if not lines.is_empty():
			var line: Array = lines[int(v.line) % lines.size()]
			v.line = int(v.line) + 1
			label.text = line[1]
			label.set_meta("who", line[0])
	label.visible = hear
	if hear:
		var speakers := people_of(inc.id)
		var who: int = label.get_meta("who", 0)
		if inc.kind == "stop" and (v.officer == null or not is_instance_valid(v.officer)):
			who = 0 if who == 1 else -1  # no officer drawn: only the civilian speaks
		if who >= 0 and who < speakers.size():
			var at: Vector2 = (speakers[who] as Walker).global_position
			label.reset_size()
			label.global_position = at + Vector2(-label.size.x * 0.5, -46)
		else:
			label.visible = false


## It is over: they go their ways (run, if scared), the officer back to his beat.
func _ended(id: String, v: Dictionary) -> void:
	v.done = true
	var h: Array = model.history.filter(func(x: Dictionary) -> bool: return x.id == id)
	v.outcome = h[0].outcome if not h.is_empty() else "over"
	if v.package != null:
		v.package.visible = false
	if v.officer != null and is_instance_valid(v.officer):
		(v.officer as PoliceOfficer).duty = {}


func _walk_off(id: String, v: Dictionary, view_centre: Vector2, danny: Vector2, delta: float) -> void:
	v.leave_left = float(v.leave_left) - delta
	var spot_pos := Vector2.ZERO
	var along := Vector2.RIGHT
	var kind := ""
	for s in model.history:
		if s.id == id:
			var sp := model.spot(s.spot)
			spot_pos = sp.pos
			along = sp.along
			kind = s.kind
	var running: bool = v.outcome in ["scattered", "spoiled", "robbed", "fled", "shooting"]
	var gone := true
	for i in v.people.size():
		var w: Walker = v.people[i]
		if not is_instance_valid(w) or w.down:
			continue
		var dir := along * (-1.0 if i == 0 else 1.0)
		if kind == "stop":
			dir = along
			if v.outcome == "taken_in" and v.officer != null and is_instance_valid(v.officer):
				var cop_at: Vector2 = (v.officer as PoliceOfficer).body.global_position
				dir = (cop_at - w.global_position).normalized() if w.global_position.distance_to(cop_at) > 30.0 else Vector2.ZERO
		w.model.walk_speed = RUN if running else WALK
		w.move = dir
		w.aim_point = w.global_position + dir * 40.0
		if view_centre.distance_to(w.global_position) < REACH * 0.8:
			gone = false
	_speak({"kind": kind if kind != "" else "argument", "id": id, "spot": {"pos": spot_pos}}, v, v.outcome, danny, delta)
	if v.leave_left <= 0.0 or gone:
		_drop(id)


func _drop(id: String) -> void:
	var v: Dictionary = views[id]
	for w in v.people:
		if is_instance_valid(w):
			(w as Node).queue_free()
	for n in [v.label, v.package]:
		if n != null and is_instance_valid(n):
			(n as Node).queue_free()
	views.erase(id)


## A district is let go: its incidents' people go with it (the incidents go on as state).
func drop_district(rect: Rect2) -> void:
	for id in views.keys():
		var v: Dictionary = views[id]
		var people: Array = v.people
		if not people.is_empty() and is_instance_valid(people[0]) and rect.has_point((people[0] as Walker).global_position):
			_drop(id)
