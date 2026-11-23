class_name StreetLife
extends Node2D
## The few people and cars out in the Riverside Ward at night: passers-by on
## the sidewalks and a handful of cars going round the blocks on the
## right-hand lanes. Fewer of them as the night gets late (NightClock
## activity); they come and go only out of sight. Gunfire sends people
## running; sleeping puts everyone back where the evening began.

## Seconds between checks of how many should be out.
const RECOUNT := 2.0
## Never appear or vanish this close to the edge of the view (px).
const VIEW_MARGIN := 140.0

var layout: DistrictLayout
var clock: NightClock
var pedestrians: Array[Pedestrian] = []
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
	for p in pedestrians:
		p.hear_gunshot(at)


## Empties the streets: everyone indoors, every car off the road.
func clear() -> void:
	enabled = false
	for p in pedestrians:
		p.set_active(false)
	for i in traffic.size():
		_set_traffic(i, false)


## Everyone back where the evening began.
func reset() -> void:
	if not enabled:
		return
	for p in pedestrians:
		p.reset()
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


func _physics_process(dt: float) -> void:
	_recount -= dt
	if _recount <= 0.0:
		_recount = RECOUNT
		recount()
	var movers := []
	for c in parked + traffic:
		if c.visible:
			movers.append({"pos": c.global_position, "vel": c.model.velocity if c.model != null else Vector2.ZERO})
	var danny: Dictionary = gun_shown.call() if gun_shown.is_valid() else {}
	for p in pedestrians:
		p.tick(dt, movers, danny)
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
	for c in parked + traffic:
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
	for p in pedestrians:
		if p.active:
			out.append({"pos": p.body.global_position, "radius": 12.0, "owner": p.body})
	return out


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
