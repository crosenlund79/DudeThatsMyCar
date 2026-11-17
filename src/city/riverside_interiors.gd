class_name RiversideInteriors
extends RefCounted
## The rooms you can walk into in the Riverside Ward (data only; see
## InteriorPlan). Coordinates are world px; each room sits in an existing
## building of RiversideWard, which keeps its outside look.


static func add_to(d: DistrictLayout) -> void:
	d.interiors.append(copper_owl(d))


## The Copper Owl supper club: the bar along the back wall with Augie behind
## it, tables with white cloths, a baby grand on the bandstand, a back door to
## the alley where tonight's delivery stands.
static func copper_owl(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("copper_owl", "The Copper Owl")
	p.building = d.building_named("The Copper Owl")
	p.building_rect = d.buildings[p.building].rect  # x 2151..2431, y 168..439
	p.room = p.building_rect
	p.floor = "interiors/floor_parquet"
	p.doors = [
		{"side": Vector2.DOWN, "at": 2291.0, "width": 30.0},  # under the canopy on Marlowe Avenue
		{"side": Vector2.UP, "at": 2400.0, "width": 26.0},  # back door to the alley
	]
	p.furniture = [
		{"kind": "interiors/back_bar", "pos": Vector2(2249, 186), "box": Vector2(180, 18)},
		{"kind": "interiors/bar_counter", "pos": Vector2(2249, 222), "box": Vector2(180, 24)},
		{"kind": "interiors/bandstand", "pos": Vector2(2393, 305)},
		{"kind": "interiors/piano", "pos": Vector2(2395, 300), "rot": PI, "box": Vector2(50, 34), "z": 1},
		{"kind": "interiors/table_club", "pos": Vector2(2192, 305), "radius": 17.0},
		{"kind": "interiors/table_club", "pos": Vector2(2192, 392), "rot": 0.6, "radius": 17.0},
		{"kind": "interiors/table_club", "pos": Vector2(2318, 300), "rot": 1.2, "radius": 17.0},
		{"kind": "interiors/table_club", "pos": Vector2(2336, 392), "rot": 2.1, "radius": 17.0},
		{"kind": "interiors/palm", "pos": Vector2(2174, 416), "radius": 8.0},
		{"kind": "interiors/palm", "pos": Vector2(2410, 418), "radius": 8.0},
	]
	for x in [2180.0, 2210.0, 2240.0, 2270.0, 2300.0, 2330.0]:
		p.furniture.append({"kind": "interiors/stool", "pos": Vector2(x, 244)})
	p.lamps = [
		{"pos": Vector2(2249, 212), "color": Color(1.0, 0.78, 0.48), "energy": 1.25, "radius": 170.0},
		{"pos": Vector2(2200, 350), "color": Color(1.0, 0.74, 0.5), "energy": 1.05, "radius": 150.0},
		{"pos": Vector2(2325, 350), "color": Color(1.0, 0.74, 0.5), "energy": 1.05, "radius": 150.0},
		{"pos": Vector2(2392, 300), "color": Color(1.0, 0.62, 0.55), "energy": 1.0, "radius": 110.0},
	]
	p.people = [
		{"id": "augie", "name": "Augie", "look": "characters/bartender", "pos": Vector2(2240, 202), "facing": PI / 2},
		{"id": "patron_a", "name": "", "look": "characters/patron_man", "pos": Vector2(2172, 300), "facing": 0.0},
		{"id": "patron_b", "name": "", "look": "characters/patron_woman", "pos": Vector2(2210, 291), "facing": PI},
		{"id": "patron_c", "name": "", "look": "characters/patron_man", "pos": Vector2(2356, 400), "facing": PI + 0.4},
	]
	p.spots = [
		{"id": "augie", "pos": Vector2(2240, 252), "radius": 34.0, "prompt": "Talk to Augie"},
	]
	return p
