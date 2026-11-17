class_name Interiors
extends Node2D
## Every room in the district you can walk into: builds each plan's walls and
## solid furniture (physics layer WORLD) and its InteriorView, and every frame
## tells the views where the player is so the room he stands in opens up.

## The player stepped into a room / back out (null = the street).
signal changed(plan: InteriorPlan)

var layout: DistrictLayout
var views: Array[InteriorView] = []
var solids: StaticBody2D
## The room the player is in (null in the street).
var current: InteriorPlan = null


func build(p_layout: DistrictLayout, city: City, resolver: AssetResolver) -> void:
	layout = p_layout
	name = "Interiors"
	solids = StaticBody2D.new()
	solids.name = "Walls"
	solids.collision_layer = Layers.WORLD
	solids.collision_mask = 0
	add_child(solids)
	for plan in layout.interiors:
		var p: InteriorPlan = plan
		for box in p.solid_boxes():
			_box(box.get_center(), box.size, 0.0)
		for f in p.furniture:
			if f.has("box"):
				_box(f.pos, f.box, f.get("rot", 0.0))
			elif f.has("radius"):
				var shape := CollisionShape2D.new()
				var circle := CircleShape2D.new()
				circle.radius = f.radius
				shape.shape = circle
				shape.position = f.pos
				solids.add_child(shape)
		var host: BuildingView = city.buildings[city.building_index(p.building)]
		# warm light on the pavement at every door you can walk through, and
		# the open door drawn in the wall so the entrance shows on the facade
		for i in p.doors.size():
			var side: Vector2 = p.doors[i].side
			var pool := Sprite2D.new()
			pool.texture = resolver.get_texture("fx/glow")
			pool.material = DrawLayer.glow_material()
			pool.scale = AssetCatalog.scale_for(pool.texture, Vector2(p.doors[i].width * 3.0, 64))
			pool.rotation = side.orthogonal().angle()
			pool.position = p.outside_door(i, 16.0)
			pool.modulate = Color(1.0, 0.72, 0.42, 0.6)
			pool.z_index = Layers.Z_LIGHT_POOL
			add_child(pool)
			var centre := p.door_centre(i) + side * InteriorPlan.WALL * 0.5
			var along := side.orthogonal() * float(p.doors[i].width) * 0.5
			host.add_doorway(centre - along, centre + along, side)
		var view := InteriorView.new()
		add_child(view)
		view.setup(p, host, resolver)
		views.append(view)


func _box(pos: Vector2, size: Vector2, rot: float) -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	shape.shape = box
	shape.position = pos
	shape.rotation = rot
	solids.add_child(shape)


## The room at p (doorways count as inside, so the roof opens as you step in).
func plan_at(p: Vector2) -> InteriorPlan:
	for plan in layout.interiors:
		var ip: InteriorPlan = plan
		if ip.contains(p):
			return ip
		for i in ip.doors.size():
			if p.distance_to(ip.door_centre(i)) <= InteriorPlan.WALL + 10.0:
				return ip
	return null


## The door within reach of p: {plan, index, outside (true: you are in the
## street), prompt}, or {} when none. Inside, only the doors of your room.
func door_at(p: Vector2, reach: float = 24.0) -> Dictionary:
	for plan in layout.interiors:
		var ip: InteriorPlan = plan
		for i in ip.doors.size():
			if p.distance_to(ip.outside_door(i, 10.0)) <= reach and not ip.contains(p):
				return {"plan": ip, "index": i, "outside": true, "prompt": "Enter %s" % ip.name}
			if ip == current and p.distance_to(ip.inside_door(i, 10.0)) <= reach:
				return {"plan": ip, "index": i, "outside": false, "prompt": "Go out"}
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
