class_name DistrictLayout
extends RefCounted
## A hand-made district as plain data: streets, blocks, alleys, buildings,
## street furniture, lamps, parked cars and the player's start. The City node
## builds everything visible and solid from it. Pure (no scene), so its rules
## can be tested: buildings never overlap, cars start on open ground, and so on.

const STOREY := 44.0

var name := ""
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
## Parked cars: {type: "sedan" | "coupe", paint: int, pos, rot}
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


static func short_name(street: String) -> String:
	return street.replace(" Avenue", " Ave").replace(" Street", " St")
