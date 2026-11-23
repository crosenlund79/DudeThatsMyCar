class_name StreetLife
extends Node2D
## The few people and cars out in the Riverside Ward at night: passers-by on
## the sidewalks and a handful of cars going round the blocks on the
## right-hand lanes. Fewer of them as the night gets late (NightClock
## activity); they come and go only out of sight. Gunfire sends people
## running; sleeping puts everyone back where the evening began.
## M015: and the street's regulars (DistrictLayout.locals), each out for their
## own hours of the night: couples walking together, men hurrying home from a
## shift, a drunk weaving along late, people standing about in doorways and
## under the lamps, small knots of talkers outside the places that keep late
## hours, a copper on point duty, delivery men carrying crates from a van to a
## door (DistrictLayout.deliveries: the van parked at the kerb for its hours).
## Now and then one of them says something - a few words over their head,
## only near the camera.

## Seconds between checks of how many should be out.
const RECOUNT := 2.0
## Never appear or vanish this close to the edge of the view (px).
const VIEW_MARGIN := 140.0

var layout: DistrictLayout
var clock: NightClock
var pedestrians: Array[Pedestrian] = []
## M015: the street's regulars, out by their own hours; the delivery vans.
var locals: Array[Pedestrian] = []
var service: Array[Car] = []
var _service_hours: Array[Vector2] = []
## M015: (who: Node2D, text: String) -> void: says a few words over someone's head.
var say: Callable
var _chat := 6.0
var _rng := RandomNumberGenerator.new()
var traffic: Array[Car] = []
var drivers: Array[TrafficDriver] = []
## Everything else that moves or stands in the street: parked cars and the
## player's walker and the officer (for threats and obstacles).
var parked: Array[Car] = []
var others: Array[Walker] = []
## Where the camera looks (set by the game every frame).
var view := Rect2()
## M015: () -> {pos, level}: the gun Danny has out where people can see it (Armoury.shown).
var gun_shown: Callable
## False: nobody out at all (clear()).
var enabled := true
var _traffic_start: Array[Transform2D] = []
var _traffic_on: Array[bool] = []
var _recount := 0.0


func setup(p_layout: DistrictLayout, resolver: AssetResolver, p_clock: NightClock, car_scene: PackedScene,
		vehicles: Dictionary, p_parked: Array[Car], p_others: Array[Walker]) -> void:
	layout = p_layout
	clock = p_clock
	parked = p_parked
	others = p_others
	name = "StreetLife"
	var i := 0
	for spec in layout.walkers:
		var p := Pedestrian.new()
		add_child(p)
		var route: PackedVector2Array = layout.walk_routes[spec.route]
		p.setup(resolver, spec.look, route, point_along(route, spec.at), 101 + i)
		pedestrians.append(p)
		i += 1
	_make_locals(resolver, vehicles, car_scene)
	var glow := resolver.get_texture("fx/glow")
	var wheel := resolver.get_texture(CarWheels.LOGICAL)
	for spec in layout.traffic:
		var loop: PackedVector2Array = layout.drive_loops[spec.loop]
		var seg: int = spec.segment
		var a := loop[seg]
		var b := loop[(seg + 1) % loop.size()]
		var at := Transform2D((b - a).angle(), a.lerp(b, spec.at))
		var vehicle: VehicleType = vehicles[spec.type]
		var c: Car = car_scene.instantiate()
		c.name = "Traffic%d" % traffic.size()
		c.z_index = Layers.Z_ACTOR
		add_child(c)
		var paint: String = vehicle.paints[int(spec.paint) % vehicle.paints.size()]
		c.setup(vehicle, resolver.get_texture(paint), paint)
		c.place(at)
		var lights := VehicleLights.new()
		lights.setup(c, glow)
		lights.set_on(true)
		CarWheels.new().setup(c, wheel)
		c.driven = true
		traffic.append(c)
		drivers.append(TrafficDriver.new(loop, seg))
		_traffic_start.append(at)
		_traffic_on.append(true)


## M015: the street's regulars and the delivery vans with their carriers.
func _make_locals(resolver: AssetResolver, vehicles: Dictionary, car_scene: PackedScene) -> void:
	_rng.seed = hash(layout.id) + 1932
	var k := 0
	for spec in layout.locals:
		var p := Pedestrian.new()
		add_child(p)
		var route: PackedVector2Array
		var at: Vector2
		if spec.has("route"):
			route = layout.walk_routes[spec.route]
			at = point_along(route, float(spec.get("at", 0.5)))
		else:
			at = spec.pos
			route = PackedVector2Array([at])
		p.setup(resolver, spec.look, route, at, 501 + k)
		p.name = "Local%d" % k
		p.configure(spec, resolver)
		locals.append(p)
		k += 1
	for k2 in layout.locals.size():
		var spec2: Dictionary = layout.locals[k2]
		if spec2.has("with"):
			locals[k2].companion = locals[int(spec2.with)]
	for dv in layout.deliveries:
		var vehicle: VehicleType = vehicles[dv.vehicle]
		var c: Car = car_scene.instantiate()
		c.name = "Delivery%d" % service.size()
		c.z_index = Layers.Z_ACTOR
		add_child(c)
		var paint: String = vehicle.paints[int(dv.get("paint", 0)) % vehicle.paints.size()]
		c.setup(vehicle, resolver.get_texture(paint), paint)
		c.place(Transform2D(float(dv.rot), dv.pos))
		service.append(c)
		var hrs := Vector2(float(dv.hours[0]), float(dv.hours[1]))
		_service_hours.append(hrs)
		var back: Vector2 = (dv.pos as Vector2) - Vector2.from_angle(float(dv.rot)) * (vehicle.size.x * 0.5 + 12.0)
		var route2 := PackedVector2Array([back, dv.door])
		var looks: Array = dv.get("looks", ["characters/worker"])
		for j in looks.size():
			var p2 := Pedestrian.new()
			add_child(p2)
			p2.setup(resolver, looks[j], route2, back.lerp(dv.door, 0.35 + 0.4 * j), 601 + service.size() * 10 + j)
			p2.name = "Carrier%d_%d" % [service.size(), j]
			p2.configure({"kind": "carry", "hours": dv.hours, "lines": dv.get("lines", [])}, resolver)
			p2.brain.dir = 1 if j == 0 else -1
			p2.brain.index = 1 if j == 0 else 0
			p2.brain.carrying = j == 0
			locals.append(p2)
	recount_locals(true)  # each out (or not) as their hours say, from the start


## Everyone on foot in the street: the passers-by and the regulars.
func everyone() -> Array[Pedestrian]:
	var out: Array[Pedestrian] = pedestrians.duplicate()
	out.append_array(locals)
	return out


## The point a share t (0..1) of the way along a polyline.
static func point_along(route: PackedVector2Array, t: float) -> Vector2:
	var total := 0.0
	for k in range(route.size() - 1):
		total += route[k].distance_to(route[k + 1])
	var left := total * clampf(t, 0.0, 1.0)
	for k in range(route.size() - 1):
		var d := route[k].distance_to(route[k + 1])
		if left <= d:
			return route[k].lerp(route[k + 1], left / maxf(d, 0.001))
		left -= d
	return route[route.size() - 1]


## How many passers-by and cars should be out at this hour.
func wanted_pedestrians() -> int:
	return clampi(roundi(pedestrians.size() * clock.activity()), mini(1, pedestrians.size()), pedestrians.size())


func wanted_traffic() -> int:
	return clampi(roundi(traffic.size() * clock.activity()), mini(1, traffic.size()), traffic.size())


func active_pedestrians() -> int:
	return pedestrians.filter(func(p: Pedestrian) -> bool: return p.active).size()


func active_traffic() -> int:
	return _traffic_on.count(true)


func hear_gunshot(at: Vector2) -> void:
	for p in everyone():
		p.hear_gunshot(at)


## M015: a car knocked somebody down at `at`: the people near enough to see
## it scatter (the one knocked down runs once they are up again).
func scare(at: Vector2, radius: float) -> void:
	for p in everyone():
		if p.active and not p.body.down:
			p.brain.scare(p.body.global_position, at, radius, 3.0 + p.body.knocked)


## Empties the streets: everyone indoors, every car off the road.
func clear() -> void:
	enabled = false
	for p in everyone():
		p.set_active(false)
	for i in traffic.size():
		_set_traffic(i, false)
	for i in service.size():
		_set_service(i, false)


## Everyone back where the evening began.
func reset() -> void:
	if not enabled:
		return
	for p in everyone():
		p.reset()
	recount_locals(true)
	for i in traffic.size():
		traffic[i].place(_traffic_start[i])
		traffic[i].driven = true
		drivers[i] = TrafficDriver.new(drivers[i].route, _start_segment(i))
		_set_traffic(i, true)


func _start_segment(i: int) -> int:
	return int(layout.traffic[i].segment)


func _set_traffic(i: int, on: bool) -> void:
	_traffic_on[i] = on
	var c := traffic[i]
	c.active = on
	c.visible = on
	c.collision_layer = Layers.CARS if on else 0
	c.collision_mask = 7 if on else 0
	if not on:
		c.model.velocity = Vector2.ZERO


func _set_service(i: int, on: bool) -> void:
	var c := service[i]
	c.visible = on
	c.collision_layer = Layers.CARS if on else 0
	c.collision_mask = 7 if on else 0


## M015: the regulars out for their hours and the vans at the kerb for theirs
## (coming and going only where nobody sees it, unless `now`).
func recount_locals(now := false) -> void:
	if not enabled:
		return
	var minute := clock.minute
	for p in locals:
		var want := p.out_at(minute)
		if want != p.active and (now or _out_of_sight(p.body.global_position)):
			p.set_active(want)
	for i in service.size():
		var want2 := minute >= _service_hours[i].x and minute < _service_hours[i].y
		if want2 != service[i].visible and (now or _out_of_sight(service[i].global_position)):
			_set_service(i, want2)


func _out_of_sight(p: Vector2) -> bool:
	return not view.grow(VIEW_MARGIN).has_point(p)


## Sends people home (or out) as the hour changes, only where nobody sees it.
func recount() -> void:
	if not enabled:
		return
	var want_p := wanted_pedestrians()
	var have_p := active_pedestrians()
	for p in pedestrians:
		var pos := p.body.global_position
		if have_p > want_p and p.active and _out_of_sight(pos):
			p.set_active(false)
			have_p -= 1
		elif have_p < want_p and not p.active and _out_of_sight(pos):
			p.set_active(true)
			have_p += 1
	var want_t := wanted_traffic()
	var have_t := active_traffic()
	for i in traffic.size():
		var pos2 := traffic[i].global_position
		if have_t > want_t and _traffic_on[i] and _out_of_sight(pos2):
			_set_traffic(i, false)
			have_t -= 1
		elif have_t < want_t and not _traffic_on[i] and _out_of_sight(pos2):
			_set_traffic(i, true)
			have_t += 1
	recount_locals()


func _physics_process(dt: float) -> void:
	_recount -= dt
	if _recount <= 0.0:
		_recount = RECOUNT
		recount()
	var movers := []
	for c in parked + traffic + service:
		if c.visible:
			movers.append({"pos": c.global_position, "vel": c.model.velocity if c.model != null else Vector2.ZERO})
	var danny: Dictionary = gun_shown.call() if gun_shown.is_valid() else {}
	for p in pedestrians:
		p.tick(dt, movers, danny)
	for p in locals:
		p.tick(dt, movers, danny)
	_chatter(dt)
	var obstacles := _obstacles()
	for i in traffic.size():
		if not _traffic_on[i]:
			continue
		var c := traffic[i]
		var mine := obstacles.filter(func(o: Dictionary) -> bool: return o.owner != c)
		var cmd := drivers[i].decide(c.global_position, c.model.heading, c.model.forward_speed(), mine, _crossing_busy(c))
		c.steer = cmd.steer
		c.throttle = cmd.throttle
		c.brake = cmd.brake


## Cars as circles along their length (three for a car; M009: more, and a
## little wider, for a lorry or a bus), people as one.
func _obstacles() -> Array:
	var out := []
	for c in parked + traffic + service:
		if not c.visible:
			continue
		var reach := maxf(26.0, c.vehicle.size.x * 0.5 - 14.0)
		var n := ceili(reach / 26.0 - 0.001)
		var f := Vector2.from_angle(c.global_rotation) * (reach / n)
		var radius := maxf(17.0, c.vehicle.size.y * 0.5 - 1.0)
		for k in range(-n, n + 1):
			out.append({"pos": c.global_position + f * k, "radius": radius, "owner": c})
	for w in others:
		if w.visible:
			out.append({"pos": w.global_position, "radius": 12.0, "owner": w})
	for p in everyone():
		if p.active:
			out.append({"pos": p.body.global_position, "radius": 12.0, "owner": p.body})
	return out


## M015: every few seconds one of the regulars near the camera says something
## - the next in a knot of talkers, a drunk, a copper on point duty.
func _chatter(dt: float) -> void:
	_chat -= dt
	if _chat > 0.0 or not say.is_valid() or not enabled:
		return
	_chat = _rng.randf_range(4.0, 8.0)
	var near := view.grow(60.0)
	var talkers: Array[Pedestrian] = []
	for p in locals:
		if p.active and not p.body.down and not p.lines.is_empty() and near.has_point(p.body.global_position) \
				and p.brain.state != PedestrianBrain.State.FLEE:
			talkers.append(p)
	if talkers.is_empty():
		return
	var who: Pedestrian = talkers[_rng.randi() % talkers.size()]
	say.call(who.body, String(who.lines[_rng.randi() % who.lines.size()]))


## True when the crossing just ahead of `c` has another car in it (wait at the line).
func _crossing_busy(c: Car) -> bool:
	var fwd := Vector2.from_angle(c.model.heading)
	var probe := c.global_position + fwd * 70.0
	for j in layout.junctions:
		var box: Rect2 = j
		if box.has_point(c.global_position) or not box.has_point(probe):
			continue  # already in it (carry on), or not about to enter
		for other in parked + traffic:
			if other != c and other.visible and box.grow(6.0).has_point(other.global_position) \
					and other.model.velocity.length() > 8.0:
				return true
	return false
