class_name DistrictLayout
extends RefCounted
## A hand-made district as plain data: streets, blocks, alleys, buildings,
## street furniture, lamps, parked cars and the player's start. The City node
## builds everything visible and solid from it. Pure (no scene), so its rules
## can be tested: buildings never overlap, cars start on open ground, and so on.

const STOREY := 44.0

var name := ""
## M008: which district this is ("riverside", ...), and where its own
## coordinates start in the one world they all share (the layout's data is
## kept in world coordinates once placed: see shift()).
var id := ""
var origin := Vector2.ZERO
## M008: the ways out into neighbouring districts: {to: district id, rect:
## Rect2 (world) - the opening on the border a street passes through}.
var exits: Array = []
## M008: named landmarks without a door of their own, for the maps: {pos, label}.
var landmarks: Array = []
## M008: how bright this district's street lamps burn (1 = the Riverside Ward),
## and smokestacks that smoke all night: {pos, height}.
var lamp_energy := 1.0
var smoke: Array = []
## M009: places the city's own small troubles happen: {id, kinds (["argument",
## "exchange", "stop"]), pos, along (the line two people stand on, a unit
## vector), local (the named person who notices how it ends and talks, or ""),
## place (how people name it: "outside Novak's Grocery")}.
var incident_spots: Array = []
## M009: the people Danny can take work from in this district, standing out
## in the street: {id, look (character sheet), pos, face (angle)}; and where
## their errands lie: {id ("crate", "film_can"), pos}.
var contacts: Array = []
var errands: Array = []
## Whole visible world (camera limits). Everything inside is drawn.
var bounds := Rect2()
## Where people and cars can be (exits are refused outside it).
var play_area := Rect2()
## {rect: Rect2, name: String, avenue: bool}
var streets: Array = []
## Curb outlines (Rect2); the sidewalk runs round the inside edge.
var blocks: Array = []
## {rect: Rect2, name: String}
var alleys: Array = []
## {rect: Rect2, kind: "lot" | "concrete"}: yards, forecourts, the dock apron.
var lots: Array = []
## Granite setts (Rect2) and streetcar tracks ([from, to]).
var cobbles: Array = []
var rails: Array = []
## River water (Rect2) and solid quay railings along it ([from, to]).
var water: Array = []
var quays: Array = []
## Solid board fences ([from, to]).
var fences: Array = []
## {rect, storeys, facade, roof, front (Vector2: the street side, ZERO = all
##  sides alike), props: [{kind, pos, rot}], signs: [{kind, pos, rot, lift}], name}
var buildings: Array = []
## Street furniture: {kind, pos, rot, radius (solid when > 0), height (raised when > 0)}
var props: Array = []
## Street lamp posts (Vector2) and dim wall lamps in the alleys (Vector2).
var lamps: Array = []
var alley_lamps: Array = []
## Flat details on the ground: {kind, pos, rot, scale}
var decals: Array = []
## Manholes that steam (Vector2).
var steam_vents: Array = []
## Warm light from shop windows on the pavement: {pos, size: Vector2, rot}
var spill: Array = []
## Rooms you can walk into (InteriorPlan), each inside one building.
var interiors: Array = []
## Street life (M003): sidewalk routes people stroll up and down
## (PackedVector2Array each), who walks them ({look, route, at: share along}),
## closed loops of right-hand lane points cars drive round, the cars on them
## ({type, paint, loop, segment, at}) and the street crossings (Rect2).
var walk_routes: Array = []
var walkers: Array = []
var drive_loops: Array = []
var traffic: Array = []
var junctions: Array = []
## Parked cars: {type: "sedan" | "coupe" | "police" | "dump_truck" | "school_bus" (M009), paint: int, pos, rot, owner}
## (M006: "danny" for Danny's own car, else who it belongs to).
var cars: Array = []
## The beat cop's round (he walks between these points and pauses at each).
var police_beat := PackedVector2Array()
var spawn := Vector2.ZERO
var spawn_facing := 0.0


func building_height(b: Dictionary) -> float:
	return float(b.storeys) * STOREY


func is_in_building(p: Vector2, margin: float = 0.0) -> bool:
	for b in buildings:
		if (b.rect as Rect2).grow(margin).has_point(p):
			return true
	return false


## The room built into building i, or null (the building is solid).
func interior_of(building_index: int) -> InteriorPlan:
	for plan in interiors:
		if (plan as InteriorPlan).building == building_index:
			return plan
	return null


## The room at p, or null.
func interior_at(p: Vector2) -> InteriorPlan:
	for plan in interiors:
		if (plan as InteriorPlan).contains(p):
			return plan
	return null


func building_named(building_name: String) -> int:
	for i in buildings.size():
		if buildings[i].name == building_name:
			return i
	return -1


func is_in_water(p: Vector2, margin: float = 0.0) -> bool:
	for w in water:
		if (w as Rect2).grow(margin).has_point(p):
			return true
	return false


## Open ground where a person may stand (not inside a building or the river).
func is_open_ground(p: Vector2, margin: float = 0.0) -> bool:
	return play_area.has_point(p) and not is_in_building(p, margin) and not is_in_water(p, margin)


## Pairs of building indices whose footprints overlap (touching is fine).
func overlapping_buildings() -> Array:
	var out := []
	for i in buildings.size():
		for j in range(i + 1, buildings.size()):
			var a: Rect2 = buildings[i].rect
			var b: Rect2 = buildings[j].rect
			if a.grow(-0.5).intersects(b.grow(-0.5)):
				out.append([i, j])
	return out


## Name of the place at p for the player's location line ("Marlowe Avenue",
## "Marlowe Ave & Kessler St", "Alley off Kessler St"), "" when none.
func place_name(p: Vector2) -> String:
	var on: Array = []
	for s in streets:
		if (s.rect as Rect2).grow(46.0).has_point(p):
			on.append(s)
	if on.size() >= 2:
		return "%s & %s" % [short_name(on[0].name), short_name(on[1].name)]
	if on.size() == 1:
		return on[0].name
	for a in alleys:
		if (a.rect as Rect2).has_point(p):
			return a.name
	return ""


## M008: moves every position in the layout by `offset` - a district is drawn
## up in its own coordinates (its top-left corner at 0, 0) and then placed in
## the world at its origin. Returns self.
func shift(offset: Vector2) -> DistrictLayout:
	origin += offset
	bounds.position += offset
	play_area.position += offset
	spawn += offset
	for s in streets:
		s.rect = _moved(s.rect, offset)
	for i in blocks.size():
		blocks[i] = _moved(blocks[i], offset)
	for a in alleys:
		a.rect = _moved(a.rect, offset)
	for l in lots:
		l.rect = _moved(l.rect, offset)
	for i in cobbles.size():
		cobbles[i] = _moved(cobbles[i], offset)
	for i in water.size():
		water[i] = _moved(water[i], offset)
	for i in junctions.size():
		junctions[i] = _moved(junctions[i], offset)
	for list in [rails, quays, fences]:
		for seg in list:
			seg[0] += offset
			seg[1] += offset
	for b in buildings:
		b.rect = _moved(b.rect, offset)
		for p in b.props:
			p.pos += offset
		for sg in b.signs:
			sg.pos += offset
	for list2 in [props, decals, spill, landmarks, smoke, cars, incident_spots, contacts, errands]:
		for item in list2:
			item.pos += offset
	for e in exits:
		e.rect = _moved(e.rect, offset)
	for i in lamps.size():
		lamps[i] += offset
	for i in alley_lamps.size():
		alley_lamps[i] += offset
	for i in steam_vents.size():
		steam_vents[i] += offset
	for i in walk_routes.size():
		walk_routes[i] = _moved_points(walk_routes[i], offset)
	for i in drive_loops.size():
		drive_loops[i] = _moved_points(drive_loops[i], offset)
	police_beat = _moved_points(police_beat, offset)
	assert(interiors.is_empty(), "rooms are laid out in world coordinates (the Riverside Ward only)")
	return self


static func _moved(r: Rect2, offset: Vector2) -> Rect2:
	return Rect2(r.position + offset, r.size)


static func _moved_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(p + offset)
	return out


## A world point in this district's own coordinates, and back (M008).
func to_local(world: Vector2) -> Vector2:
	return world - origin


func to_world(local: Vector2) -> Vector2:
	return local + origin


static func short_name(street: String) -> String:
	return street.replace(" Avenue", " Ave").replace(" Street", " St")
