class_name Interiors
extends Node2D
## Every room you can walk into in the districts that are built: each room's
## walls and solid furniture (physics layer WORLD) and its InteriorView; every
## frame the views are told where the player is, so the room he stands in
## opens up.
##
## M012: rooms in any district, not only the Riverside Ward. The ward's rooms
## are built at start-up (`build`); a streamed district's rooms are built when
## it is ready (`add_district`, under the district's own node, so they go with
## it) and dropped from here when it is let go (`remove_district`). The
## district Danny stands in is never let go (DistrictStreamer), so the room he
## is in never disappears under him. Nothing in a room is simulated while its
## district is not built; what must last (who was struck down, the jobs) lives
## in the game's own state, not in the views.

## The player stepped into a room / back out (null = the street).
signal changed(plan: InteriorPlan)
## M012: a district's rooms were built (their views, for wiring) or let go.
signal rooms_added(new_views: Array)
signal rooms_removed(district_id: String)

## The Riverside Ward (its rooms are always here).
var layout: DistrictLayout
## Every room of every built district, and its view.
var plans: Array[InteriorPlan] = []
var views: Array[InteriorView] = []
## The ward's walls (kept for code that asks for them).
var solids: StaticBody2D
## The room the player is in (null in the street).
var current: InteriorPlan = null
## district id -> {holder: Node2D, plans: Array, views: Array, layout}
var _districts := {}
var _resolver: AssetResolver


func build(p_layout: DistrictLayout, city: City, resolver: AssetResolver) -> void:
	layout = p_layout
	_resolver = resolver
	name = "Interiors"
	add_district(p_layout, city, self)
	if _districts.has(p_layout.id):
		solids = (_districts[p_layout.id].holder as Node).get_node("Walls")


## Builds the rooms of a district (its walls, the light at its doors and the
## doorways on its facades, the cut-away views) under `parent`. Returns the new views.
func add_district(l: DistrictLayout, city: City, parent: Node) -> Array:
	if _resolver == null or _districts.has(l.id) or l.interiors.is_empty():
		return []
	var holder := Node2D.new()
	holder.name = "Rooms_" + l.id
	parent.add_child(holder)
	var walls := StaticBody2D.new()
	walls.name = "Walls"
	walls.collision_layer = Layers.WORLD
	walls.collision_mask = 0
	holder.add_child(walls)
	var new_views: Array = []
	var new_plans: Array = []
	for plan in l.interiors:
		var p: InteriorPlan = plan
		for box in p.solid_boxes():
			_box(walls, box.get_center(), box.size, 0.0)
		for f in p.furniture:
			if f.has("box"):
				_box(walls, f.pos, f.box, f.get("rot", 0.0))
			elif f.has("radius"):
				var shape := CollisionShape2D.new()
				var circle := CircleShape2D.new()
				circle.radius = f.radius
				shape.shape = circle
				shape.position = f.pos
				walls.add_child(shape)
		var host: BuildingView = city.buildings[city.building_index(p.building)]
		# warm light on the pavement at every door you can walk through, and
		# the open door drawn in the wall so the entrance shows on the facade
		for i in p.doors.size():
			if p.doors[i].get("inner", false):
				continue  # M010: a door between two rooms: no light on a pavement, no doorway on a facade
			var side: Vector2 = p.doors[i].side
			var pool := Sprite2D.new()
			pool.texture = _resolver.get_texture("fx/glow")
			pool.material = DrawLayer.glow_material()
			pool.scale = AssetCatalog.scale_for(pool.texture, Vector2(p.doors[i].width * 3.0, 64))
			pool.rotation = side.orthogonal().angle()
			pool.position = p.outside_door(i, 16.0)
			pool.modulate = Color(1.0, 0.72, 0.42, 0.6)
			pool.z_index = Layers.Z_LIGHT_POOL
			holder.add_child(pool)
			var centre := p.door_centre(i) + side * InteriorPlan.WALL * 0.5
			var along := side.orthogonal() * float(p.doors[i].width) * 0.5
			host.add_doorway(centre - along, centre + along, side)
		var view := InteriorView.new()
		holder.add_child(view)
		view.setup(p, host, _resolver)
		new_views.append(view)
		new_plans.append(p)
	for v in new_views:  # rooms that share a building keep its roof off together
		var iv: InteriorView = v
		iv.siblings = new_views.filter(func(o: InteriorView) -> bool: return o != iv and o.plan.building == iv.plan.building)
	_districts[l.id] = {"holder": holder, "plans": new_plans, "views": new_views, "layout": l}
	for p in new_plans:
		plans.append(p)
	for v in new_views:
		views.append(v)
	rooms_added.emit(new_views)
	return new_views


## A district is let go: its rooms leave the lists (their nodes go with the
## district's own node; the ward's never go).
func remove_district(id: String) -> void:
	if not _districts.has(id) or (layout != null and id == layout.id):
		return
	var e: Dictionary = _districts[id]
	for p in e.plans:
		plans.erase(p)
	for v in e.views:
		views.erase(v)
	if current != null and e.plans.has(current):
		current = null
		changed.emit(null)
	var holder: Node = e.holder
	if is_instance_valid(holder) and holder.get_parent() == self:
		holder.queue_free()
	_districts.erase(id)
	rooms_removed.emit(id)


## The districts whose rooms are built.
func district_ids() -> Array:
	return _districts.keys()


## The district a room belongs to ("" if its district is not built).
func district_of(plan: InteriorPlan) -> String:
	for id in _districts:
		if (_districts[id].plans as Array).has(plan):
			return id
	return ""


func _box(body: StaticBody2D, pos: Vector2, size: Vector2, rot: float) -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	shape.shape = box
	shape.position = pos
	shape.rotation = rot
	body.add_child(shape)


## The room at p (doorways count as inside, so the roof opens as you step in).
func plan_at(p: Vector2) -> InteriorPlan:
	for ip in plans:
		if ip.contains(p):
			return ip
		for i in ip.doors.size():
			if p.distance_to(ip.door_centre(i)) <= InteriorPlan.WALL + 10.0:
				return ip
	return null


## The door within reach of p: {plan, index, outside (true: you are in the
## street), prompt}, or {} when none. Inside, only the doors of your room.
func door_at(p: Vector2, reach: float = 24.0) -> Dictionary:
	for ip in plans:
		for i in ip.doors.size():
			var inner: bool = ip.doors[i].get("inner", false)
			if p.distance_to(ip.outside_door(i, 10.0)) <= reach and not ip.contains(p):
				return {"plan": ip, "index": i, "outside": true, "prompt": ("Through to %s" if inner else "Enter %s") % ip.name}
			if ip == current and p.distance_to(ip.inside_door(i, 10.0)) <= reach:
				var beyond := plan_at(ip.outside_door(i, 18.0)) if inner else null
				return {"plan": ip, "index": i, "outside": false,
					"prompt": "Through to %s" % beyond.name if beyond != null else "Go out"}
	return {}


## Steps through a door (E at the door): just inside, or just outside.
func step_through(walker: Walker, door: Dictionary) -> void:
	var plan: InteriorPlan = door.plan
	var side: Vector2 = plan.doors[door.index].side
	if door.outside:
		walker.place(plan.inside_door(door.index, 16.0), (-side).angle())
	else:
		walker.place(plan.outside_door(door.index, 18.0), side.angle())
	walker.aim_point = walker.global_position + Vector2.from_angle(walker.model.facing) * 60.0
	update_player(walker.global_position)


func view_of(id: String) -> InteriorView:
	for v in views:
		if v.plan.id == id:
			return v
	return null


## The room with this id in any district's data, built or not (null if none).
func plan_named(id: String) -> InteriorPlan:
	for p in plans:
		if p.id == id:
			return p
	return null


func person(plan_id: String, person_id: String) -> Walker:
	var v := view_of(plan_id)
	return v.people.get(person_id) if v != null else null


## Called every frame with the player's position (on foot; INF in a car).
func update_player(p: Vector2) -> void:
	var now: InteriorPlan = null if p == Vector2.INF else plan_at(p)
	if now != current:
		current = now
		changed.emit(current)
	for v in views:
		v.set_inside(v.plan == current)


## Opens (or closes) the room at once, without the fade (start of play, tests).
func snap() -> void:
	for v in views:
		v.set_inside(v.plan == current, true)
