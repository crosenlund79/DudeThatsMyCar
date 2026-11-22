class_name Fleet
extends RefCounted
## M014 (from main): every parked car in the city and what is known about it -
## its layout entry and lasting name (M013: "<district>/<n>"), whose it is and
## which Danny has taken tonight (M006 CarThefts), whether it is put away with
## an unloaded district (M008), what is in its boot (M009) - and the cars in the
## save (M013). The cars are children of the game's root, as they always were;
## the fleet keeps the lists and the rules.

const CAR_SCENE := preload("res://src/driving/car.tscn")
const VEHICLES := {
	"sedan": preload("res://src/driving/vehicles/sedan.tres"),
	"coupe": preload("res://src/driving/vehicles/coupe.tres"),
	"police": preload("res://src/driving/vehicles/police.tres"),
	"dump_truck": preload("res://src/driving/vehicles/dump_truck.tres"),  # M009
	"school_bus": preload("res://src/driving/vehicles/school_bus.tres"),
}
## M009: a car within this much of Novak's door counts as "out front" for Dutch's crate.
const CRATE_DROP_REACH := 280.0

var game: Game
## Every parked car (the ward's first, then each district's as it is first
## built: the list only ever grows; a car in a freed district is put away, not
## freed, so nothing is ever duplicated). Shared with the player and the street life.
var cars: Array[Car] = []
## M008: the layout entry of every car in `cars`.
var specs: Array = []
## M013: each car's lasting name, "<district>/<n>" (the district whose layout
## parks it and its place in that list) - the same in every session, whichever
## district happened to be built first. Parallel to `cars`.
var ids: Array[String] = []
## M006: whose car is whose and which Danny has taken tonight.
var thefts: CarThefts
## Cars stolen tonight, and how many of those the police saw (for tests and notices).
var theft_incidents := 0
var thefts_witnessed := 0
## M013: a car being put back as it was saved (no door slam, no theft).
var restoring := false
## The districts whose parked cars have been made.
var _made := {}


func _init(p_game: Game) -> void:
	game = p_game


## The ward's parked cars (at start-up), then the owners' book.
func park(layout: DistrictLayout) -> void:
	for j in layout.cars.size():
		make_car(layout.cars[j], "%s/%d" % [layout.id, j])
	_made[layout.id] = true
	thefts = CarThefts.new(layout.cars)


## A district's parked cars join `cars` the first time it is built (later
## they are only put away and brought back).
func district_cars(l: DistrictLayout) -> void:
	if _made.has(l.id):
		return
	_made[l.id] = true
	for j in l.cars.size():
		make_car(l.cars[j], "%s/%d" % [l.id, j])


## A parked car from a layout entry (M008: any district's), added to `cars`,
## its owner to `thefts` (once that exists). `id`: its lasting name (M013).
func make_car(spec: Dictionary, id: String = "") -> Car:
	var vehicle: VehicleType = VEHICLES[spec.type]
	var c: Car = CAR_SCENE.instantiate()
	c.position = spec.pos
	c.rotation = spec.rot
	c.z_index = Layers.Z_ACTOR
	game.root.add_child(c)
	var paint: String = vehicle.paints[int(spec.paint) % vehicle.paints.size()]
	c.setup(vehicle, game.resolver.get_texture(paint), paint)
	var lights := VehicleLights.new()
	lights.setup(c, game.resolver.get_texture("fx/glow"))
	CarWheels.new().setup(c, game.resolver.get_texture(CarWheels.LOGICAL))
	if game.root.process_mode == Node.PROCESS_MODE_ALWAYS:
		c.process_mode = Node.PROCESS_MODE_PAUSABLE
	cars.append(c)
	specs.append(spec)
	ids.append(id)
	if thefts != null:
		thefts.add(String(spec.get("owner", "")))
	return c


## A car in a district that is not loaded is put away (hidden, out of the
## physics, not moving) - and brought back as it was.
func put_away(c: Car, away: bool) -> void:
	if away == c.has_meta("away"):
		return
	if away:
		c.set_meta("away", [c.collision_layer, c.collision_mask])
		c.collision_layer = 0
		c.collision_mask = 0
		c.visible = false
		c.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		var layers: Array = c.get_meta("away")
		c.collision_layer = layers[0]
		c.collision_mask = layers[1]
		c.visible = true
		c.process_mode = Node.PROCESS_MODE_PAUSABLE
		c.remove_meta("away")


## A district is built: its cars come back out.
func district_ready(l: DistrictLayout) -> void:
	for c in cars:
		if c.has_meta("away") and l.bounds.has_point(c.global_position):
			put_away(c, false)


## A district is about to be freed: the cars standing in it are put away (not
## the one Danny drives).
func district_unloading(bounds: Rect2) -> void:
	for c in cars:
		if c != game.player.car and bounds.has_point(c.global_position):
			put_away(c, true)


## Danny's own car (null if there is none).
func my_car() -> Car:
	for i in cars.size():
		if thefts.is_dannys(i):
			return cars[i]
	return null


## Danny got in: a taken car is a theft (once a car a night), seen or not.
func entered(c: Car) -> void:
	if not restoring:
		game.soundscape.play("vehicles/door", -3.0)
	var i := cars.find(c)
	if thefts.get_in(i):
		theft_incidents += 1
		if game.police.officers().any(func(o: PoliceOfficer) -> bool: return o.witness_theft(c.global_position)):
			thefts_witnessed += 1
			game.hud.show_notice("The beat cop saw you take it!")
		else:
			game.hud.show_notice("Not your car. Nobody saw you take it.")
	game.camera.target = c
	(c.get_node("Lights") as VehicleLights).set_on(true)
	game.vehicle_audio.attach(c)


func exited(c: Car) -> void:
	game.soundscape.play("vehicles/door", -3.0)
	game.camera.target = game.walker
	(c.get_node("Lights") as VehicleLights).set_on(false)
	game.vehicle_audio.attach(null)


## What E would do at car `c` (the prompt).
func prompt_for(c: Car) -> String:
	var i := cars.find(c)
	return "E   Get in your %s" % c.vehicle.params.display_name if thefts.is_dannys(i) \
		else "E   Take the %s (%s)" % [c.vehicle.params.display_name, "taken" if thefts.is_stolen(i) else "not yours"]


## A new night: every car back at its parking place with its owner, nothing in
## a boot, put away where its district is not built.
func new_night() -> void:
	thefts.clear()  # the cars are back with their owners
	for c in cars:
		set_cargo(c, false)  # M009: whatever was in a boot was fetched in the night


## (after the night's other resets, as M013 had it)
func back_to_places() -> void:
	for i in cars.size():
		var spec: Dictionary = specs[i]
		cars[i].place(Transform2D(spec.rot, spec.pos))
		cars[i].driven = false
		put_away(cars[i], not game.world.is_ready(game.world.district_at(spec.pos)))


# ------------------------------------------------------------------ cargo (M009)

## A car's boot with Dutch's crate in it (a crate strapped on the luggage rack, seen from above).
func set_cargo(c: Car, on: bool) -> void:
	var s := c.get_node_or_null("Cargo") as Sprite2D
	if not on:
		if c.has_meta("cargo"):
			c.remove_meta("cargo")
		if s != null:
			s.queue_free()
		return
	c.set_meta("cargo", "crate")
	if s == null:
		s = Sprite2D.new()
		s.name = "Cargo"
		s.texture = game.resolver.get_texture("props/crate")
		s.scale = AssetCatalog.scale_for(s.texture, Vector2(17, 17))
		s.position = Vector2(-c.vehicle.size.x * 0.5 - 4.0, 0.0)
		c.add_child(s)


## A car with Dutch's crate in it, parked near `at` (null if none).
func crate_car_at(at: Vector2) -> Car:
	for c in cars:
		if c.has_meta("cargo") and not c.has_meta("away") and c.global_position.distance_to(at) < CRATE_DROP_REACH:
			return c
	return null


## The car nearest `at` within reach a crate could go into (not the squad car, not one put away).
func loadable_car_near(at: Vector2, reach: float) -> Car:
	var best: Car = null
	for c in cars:
		if c.has_meta("away") or c.vehicle.id == "police":
			continue
		if c.global_position.distance_to(at) < reach \
				and (best == null or c.global_position.distance_to(at) < best.global_position.distance_to(at)):
			best = c
	return best


## Whether any car carries a crate.
func any_cargo() -> bool:
	return cars.any(func(c: Car) -> bool: return c.has_meta("cargo"))


# ------------------------------------------------------------------ the save (M013)

## M013: whether a car could be put down at `p`: inside a district, on open
## ground (not in a building or the river) with room for its body.
func can_stand(c: Car, p: Vector2) -> bool:
	var d := game.world.district_at(p)
	if d == "":
		return false
	var l: DistrictLayout = game.world.layouts[d]
	return l.is_open_ground(p, minf(c.vehicle.size.y * 0.5, 12.0))


## M013: tonight's cars for the save: those moved from their parking places
## (where and which way), what is in a boot, which Danny took and which one he
## is sitting in - each by its lasting name.
func to_save() -> Dictionary:
	var moved := {}
	var taken := []
	for i in cars.size():
		if ids[i] == "":
			continue  # a car a test made by hand
		var c := cars[i]
		var spec: Dictionary = specs[i]
		var m := {}
		if c.global_position.distance_to(spec.pos) > 0.5 or absf(angle_difference(c.global_rotation, float(spec.rot))) > 0.002:
			m = {"x": c.global_position.x, "y": c.global_position.y, "rot": c.global_rotation}
		if c.has_meta("cargo"):
			m["cargo"] = String(c.get_meta("cargo"))
		if not m.is_empty():
			moved[ids[i]] = m
		if thefts.is_stolen(i):
			taken.append(ids[i])
	var driving := ""
	var player := game.player
	if player != null and player.car != null and cars.has(player.car):
		driving = ids[cars.find(player.car)]
	return {"night": game.rackets.night, "moved": moved, "taken": taken, "driving": driving}


## M013: where the cars stood tonight, as the save has it: a car moved from its
## parking place stands where it was left (in any district - a district not
## built yet keeps it put away until it is), a car Danny took tonight is still
## taken, a crate is still in its boot. Returns the car he was sitting in (or
## null). A saved place a car could not stand on (inside a building or the
## river, or outside the city) leaves it at its own parking place instead.
## `saved`: the save's "cars" ({} when it has none or it is from another night).
func restore(saved: Dictionary, ward_id: String) -> Car:
	var world := game.world
	var moved: Dictionary = saved.get("moved", {})
	var named := {}
	for id in moved.keys() + (saved.get("taken", []) as Array) + [String(saved.get("driving", ""))]:
		named[String(id).get_slice("/", 0)] = true
	for d in named:  # a neighbouring district's cars are made the first time they are needed
		if d != ward_id and world.layouts.has(d):
			district_cars(world.layouts[d])
	for id in moved:
		var i := ids.find(String(id))
		if i < 0:
			continue
		var m: Dictionary = moved[id]
		if m.has("x"):
			var p := Vector2(float(m.x), float(m.y))
			if can_stand(cars[i], p):
				cars[i].place(Transform2D(float(m.get("rot", 0.0)), p))
		if String(m.get("cargo", "")) != "":
			set_cargo(cars[i], true)
	for id in saved.get("taken", []):
		thefts.mark_taken(ids.find(String(id)))
	for c in cars:
		put_away(c, not world.is_ready(world.district_at(c.global_position)))
	var seat := ids.find(String(saved.get("driving", "")))
	return cars[seat] if seat >= 0 else null
