class_name OpportunityViews
extends RefCounted
## M009: the people Danny can take work from - Dutch outside his night lunch,
## Mr. Feeney under the Bijou's marquee - and their errands (Dutch's crate by
## his door, the lost film can behind St. Brendan's), made when their district
## is built and freed with it (they are children of the district's node).
## Presentation only: it reads Opportunities and says who or what is within
## reach; main does what E does.

const TALK_REACH := 40.0
const ERRAND_REACH := 34.0
## Dutch's crate goes into a car this close to it.
const LOAD_REACH := 140.0

signal contact_hurt(id: String, body: Walker)
signal contact_down(id: String, body: Walker)

var resolver: AssetResolver
var rackets: Rackets
## func(id) -> bool: the contact has been carried off tonight (not put out again).
var is_out: Callable
## district id -> {contacts: {id: Walker}, errands: {id: Sprite2D}, faces: {id: angle}}
var shown := {}


func setup(p_resolver: AssetResolver, p_rackets: Rackets) -> void:
	resolver = p_resolver
	rackets = p_rackets


## A district has been built: its contacts and errands, under its node.
func district_ready(id: String, layout: DistrictLayout, parent: Node) -> void:
	if layout.contacts.is_empty() and layout.errands.is_empty():
		return
	var entry := {"contacts": {}, "errands": {}, "faces": {}}
	for c in layout.contacts:
		if is_out.is_valid() and is_out.call(c.id):
			continue  # carried off to the Doc's for the night
		var w := Walker.create(resolver, c.look, {"glow": false})
		w.name = "Contact_%s" % c.id
		w.set_meta("person", String(c.id))  # M015: who a car knocked down
		parent.add_child(w)
		w.place(c.pos, float(c.face))
		entry.contacts[c.id] = w
		entry.faces[c.id] = float(c.face)
		var cid: String = c.id
		w.hurt.connect(func(_r: String, _l: int) -> void: contact_hurt.emit(cid, w))
		w.struck_down.connect(func() -> void: contact_down.emit(cid, w))
	for e in layout.errands:
		var s := Sprite2D.new()
		s.name = "Errand_%s" % e.id
		s.texture = resolver.get_texture("props/crate" if e.id == "crate" else "props/film_can")
		s.scale = AssetCatalog.scale_for(s.texture, Vector2(24, 24) if e.id == "crate" else AssetCatalog.display_size("props/film_can"))
		s.position = e.pos
		s.rotation = 0.15
		s.z_index = Layers.Z_ACTOR - 1
		s.z_as_relative = false
		parent.add_child(s)
		entry.errands[e.id] = s
	shown[id] = entry
	refresh(Vector2.INF)


func district_gone(id: String) -> void:
	shown.erase(id)


## Every frame (cheap: a handful of nodes): errands shown while they are
## still lying there; a contact turns to Danny when he comes close.
func refresh(danny: Vector2) -> void:
	for id in shown:
		var entry: Dictionary = shown[id]
		for e in entry.errands:
			var s: Sprite2D = entry.errands[e]
			if is_instance_valid(s):
				s.visible = errand_open(e)
		for c in entry.contacts:
			var w: Walker = entry.contacts[c]
			if not is_instance_valid(w) or w.down:
				continue
			var near := danny != Vector2.INF and w.global_position.distance_to(danny) < 120.0
			w.aim_point = danny if near else w.global_position + Vector2.from_angle(float(entry.faces[c])) * 40.0


## Whether an errand's thing is lying there to be taken.
func errand_open(id: String) -> bool:
	match id:
		"crate":
			return rackets.opportunities.crate in ["waiting", "taken"]
		"film_can":
			return rackets.opportunities.reel in ["lost", "looking"]
	return false


## The contact or errand Danny is standing at: {id, kind ("contact" | "errand"), pos} or {}.
func near(p: Vector2) -> Dictionary:
	for id in shown:
		var entry: Dictionary = shown[id]
		for c in entry.contacts:
			var w: Walker = entry.contacts[c]
			if is_instance_valid(w) and not w.down and w.global_position.distance_to(p) < TALK_REACH:
				return {"id": c, "kind": "contact", "pos": w.global_position}
		for e in entry.errands:
			var s: Sprite2D = entry.errands[e]
			if is_instance_valid(s) and s.visible and s.global_position.distance_to(p) < ERRAND_REACH:
				# the crate is only for loading once Dutch has given it to Danny
				if e == "crate" and rackets.opportunities.crate != "taken":
					continue
				return {"id": e, "kind": "errand", "pos": s.global_position}
	return {}


func contact(id: String) -> Walker:
	for d in shown:
		var w = (shown[d].contacts as Dictionary).get(id)
		if w != null and is_instance_valid(w):
			return w
	return null


func errand(id: String) -> Sprite2D:
	for d in shown:
		var s = (shown[d].errands as Dictionary).get(id)
		if s != null and is_instance_valid(s):
			return s
	return null
