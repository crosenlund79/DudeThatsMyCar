class_name Districts
extends RefCounted
## M014 (from main): what the game puts into a district while it is built
## (M008) and takes out again when the streamer lets it go - its passers-by and
## traffic, its parked cars (made the first time), its beat cop (or where he
## lies, if Danny shot him tonight), its rooms and their door plates (M012),
## its contacts (M009) - and what each district keeps for the night while it
## is not built. The ward's own street life and beat cop are made at start-up
## and are part of the same lists. Seats and works trucks per built district.

var game: Game
## Tests: no passers-by or traffic in the neighbouring districts either.
var quiet_streets := false
## Each district's street life while it is built: id -> StreetLife (the ward's first).
var _street := {}
## M010: the seats of each built district (benches in the street and the park, in the rooms).
var _seats := {}
## M010: the parked works trucks (scenery, not drivable) of every district, gathered once.
var _scenery_trucks: Array[Vector2] = []


func _init(p_game: Game) -> void:
	game = p_game


## The ward's street life (made at start-up).
func add_ward_street(s: StreetLife) -> void:
	_street[game.layout.id] = s


## The street life of the loaded districts (M008): the ward's first, then the
## others in the order they were first built (a district let go keeps its place).
func streets() -> Array[StreetLife]:
	var out: Array[StreetLife] = []
	for id in _street:
		var s: StreetLife = _street[id]
		if s != null and is_instance_valid(s):
			out.append(s)
	return out


## What the streamer builds for a district besides its city, a slice at a
## time: its passers-by and traffic, and (the first time) its parked cars.
func steps(l: DistrictLayout, node: Node2D) -> Array[Callable]:
	return [_district_street.bind(l, node), game.fleet.district_cars.bind(l)]


func _district_street(l: DistrictLayout, node: Node2D) -> void:
	var s := StreetLife.new()
	node.add_child(s)
	var others: Array[Walker] = [game.walker]
	for o in game.police.officers():
		others.append(o.body)
	s.setup(l, game.resolver, game.clock, Fleet.CAR_SCENE, Fleet.VEHICLES, game.fleet.cars, others)
	s.gun_shown = game.armoury.shown  # M015
	s.name = "StreetLife"
	if quiet_streets:
		s.clear()
	s.view = game.camera.view_rect()
	game.soundscape.track_traffic(s.traffic)
	_street[l.id] = s


## A district is complete: the camera may show it, the cars parked in it come
## back out, its rooms and plates and contacts are made, and its beat cop takes
## up his round (or lies where he fell tonight, if Danny shot him).
func ready(id: String) -> void:
	var world := game.world
	game.camera.set_bounds(world.bounds())
	if id == game.layout.id:
		return
	var l: DistrictLayout = world.layouts[id]
	var node: Node2D = world.loaded[id].node
	game.fleet.district_ready(l)
	game.missions.district_ready(id, l, node)  # M009: the contacts and errands made with it
	game.interiors.add_district(l, world.city_of(id), node)  # M012: its rooms
	game.plates.add_district(l, node)  # and the plates at its doors
	if l.police_beat.is_empty():
		return
	var o := PoliceOfficer.new()
	node.add_child(o)
	o.setup(game.resolver, game.police_rules, l.police_beat, world.navigator_of(id), game.player.body, game.bullets)
	o.home_area = l.play_area
	var police := game.police
	police.wire(o)
	police.wire_hud(o)
	var st: Dictionary = world.state.get(id, {})
	var past: Dictionary = st.get("officer", {})
	if past.get("down", false) and int(past.get("night", -1)) == game.rackets.night:
		o.body.place(past.pos, 0.0)
		o.body.condition.damage["torso"] = BodyCondition.MAX
		o.body.down = true
		o.body.lie_down()
		o.torch.visible = false
	police.set_district_officer(id, o)
	for s in streets():
		if not s.others.has(o.body):
			s.others.append(o.body)


## A district is about to be freed: its rooms and plates go, whatever was made
## with it goes, its beat cop's state is kept for tonight, the cars parked in it
## are put away (not the one Danny drives), bullets still flying there are let go.
func unloading(id: String) -> void:
	var world := game.world
	game.interiors.remove_district(id)  # M012: its rooms go with it
	game.people.district_unloading(id)  # Leon at Dutch's goes with the yards, a call-out with its room
	game.plates.remove_district(id)
	if not _street.has(id):
		return  # (never built)
	var police := game.police
	var o: PoliceOfficer = police.district_officer(id)
	if o != null and is_instance_valid(o):
		if not world.state.has(id):
			world.state[id] = {}
		world.state[id]["officer"] = {"down": o.is_down(), "pos": o.body.global_position, "night": game.rackets.night}
		for s in streets():
			s.others.erase(o.body)
	police.set_district_officer(id, null)
	_street[id] = null
	var b: Rect2 = world.layouts[id].bounds
	game.fleet.district_unloading(b)
	if game.incident_views != null:
		game.incident_views.drop_district(b)  # its incidents go on as state
	if game.missions != null:
		game.missions.district_unloading(id)  # M009: and they go with it
	game.bullets.drop_in(b)
	game.camera.set_bounds.call_deferred(world.bounds())


## Danny walked (or drove) into a district: its name on the HUD, its sound.
func entered(id: String) -> void:
	var l: DistrictLayout = game.world.layouts[id]
	if game.hud != null:
		game.hud.set_district(l.name)
	if game.soundscape != null:
		game.soundscape.layout = l


## A new night: the street life as at the start of every night; a new man on every beat.
func new_night() -> void:
	for s in streets():
		s.reset()
	var world := game.world
	for id in world.state:
		world.state[id].erase("officer")  # a new man on every beat


## M010: the seats of the built districts (benches in the street and the park, in the rooms).
func seats_near() -> Array:
	var world := game.world
	var out := []
	for id in world.ready_ids():
		if not _seats.has(id):
			_seats[id] = Seats.of(world.layouts[id])
		out.append_array(_seats[id])
	return out


## M010: one of the parked works trucks within reach of p (in a built district).
func scenery_truck_near(p: Vector2) -> bool:
	var world := game.world
	if _scenery_trucks.is_empty() and world != null:
		for id in world.order:
			for pr in (world.layouts[id] as DistrictLayout).props:
				if String(pr.kind).begins_with("props/truck"):
					_scenery_trucks.append(pr.pos)
		_scenery_trucks.append(Vector2.INF)  # gathered (even if there are none)
	for t in _scenery_trucks:
		if t.distance_to(p) < 72.0 and world.is_ready(world.district_at(t)):
			return true
	return false


# ------------------------------------------------------------------ the save (M008)

## M008: what each neighbouring district keeps for tonight - whether its beat
## cop is down, and where - from the live district if it is loaded.
func to_save() -> Dictionary:
	var world := game.world
	var out := {}
	for id in world.order:
		if id == game.layout.id:
			continue
		var o: PoliceOfficer = game.police.district_officer(id)
		var past: Dictionary = world.state.get(id, {}).get("officer", {})
		if o != null and is_instance_valid(o):
			past = {"down": o.is_down(), "pos": o.body.global_position, "night": game.rackets.night}
		if past.get("down", false):
			out[id] = {"officer": {"down": true, "x": past.pos.x, "y": past.pos.y, "night": int(past.night)}}
	return out


## M008: tonight's district state from the save (an earlier night's is forgotten).
func load_saved(ds: Dictionary) -> void:
	var world := game.world
	for id in ds:
		var o: Dictionary = ds[id].get("officer", {})
		if world.layouts.has(id) and int(o.get("night", -1)) == game.rackets.night and o.get("down", false):
			world.state[id] = {"officer": {"down": true, "pos": Vector2(float(o.x), float(o.y)), "night": game.rackets.night}}
