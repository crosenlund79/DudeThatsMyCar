class_name YardsInteriors
extends RefCounted
## M012: the rooms you can walk into in the Riverfront Yards (data only; see
## InteriorPlan), both in North Branch Freight's depot on Front Street. Written
## in the yards' own coordinates and moved with them (DistrictLayout.shift).
## Two rooms in one building: each plan's building_rect is its own part of the
## depot (together the whole of it), so each keeps the rest of its part solid.

const DEPOT := "North Branch Freight"


static func add_to(d: DistrictLayout) -> void:
	d.interiors.append(dispatch_office(d))
	d.interiors.append(freight_shed(d))


## The night dispatcher's office at the west end of the depot, its door on
## Front Street: the dispatch board chalked with car numbers, bays and times,
## the dispatcher's desk with its telephone and spike of waybills, a bench for
## the drivers who wait, a stove, the map of the yards. Leon Sobczak keeps the
## night desk: the company's man, who answers for every crate that goes out
## late.
static func dispatch_office(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("dispatch_office", "North Branch Freight - Dispatch")
	p.building = d.building_named(DEPOT)  # x 3481..4461, y 216..636 (the front on Front Street)
	p.building_rect = Rect2(3481, 216, 420, 420)  # its west part (the shed has the east): the rest stays solid
	p.room = Rect2(3481, 216, 250, 190)
	p.floor = "interiors/floor_boards"
	p.doors = [{"side": Vector2.UP, "at": 3560.0, "width": 28.0}]
	p.furniture = [
		{"kind": "interiors/chalkboard", "pos": Vector2(3492, 320), "rot": -PI / 2, "box": Vector2(66, 8)},
		{"kind": "interiors/desk", "pos": Vector2(3620, 300), "rot": PI, "box": Vector2(70, 32)},
		{"kind": "interiors/chair", "pos": Vector2(3620, 326), "rot": PI},
		{"kind": "interiors/bench", "pos": Vector2(3640, 232), "box": Vector2(66, 14)},
		{"kind": "interiors/wall_map", "pos": Vector2(3680, 223)},
		{"kind": "interiors/filing_cabinet", "pos": Vector2(3720, 290), "rot": PI / 2, "box": Vector2(22, 18)},
		{"kind": "interiors/filing_cabinet", "pos": Vector2(3720, 314), "rot": PI / 2, "box": Vector2(22, 18)},
		{"kind": "interiors/potbelly", "pos": Vector2(3700, 382), "radius": 11.0},
		{"kind": "interiors/coat_rack", "pos": Vector2(3497, 232), "radius": 6.0},
		{"kind": "interiors/spittoon", "pos": Vector2(3530, 390)},
		{"kind": "interiors/smoke", "pos": Vector2(3610, 320), "z": 11},
	]
	p.lamps = [
		{"pos": Vector2(3620, 300), "color": Color(1.0, 0.82, 0.55), "energy": 1.0, "radius": 120.0},  # the desk lamp
		{"pos": Vector2(3580, 360), "color": Color(1.0, 0.78, 0.52), "energy": 0.55, "radius": 130.0},
		{"pos": Vector2(3700, 382), "color": Color(1.0, 0.55, 0.3), "energy": 0.35, "radius": 50.0},  # the stove
	]
	p.people = [
		{"id": "leon", "name": "Leon Sobczak", "look": "characters/dispatcher", "pos": Vector2(3620, 328), "facing": -PI / 2},
	]
	p.spots = [
		{"id": "leon", "pos": Vector2(3620, 264), "radius": 20.0, "prompt": "Talk to the dispatcher"},
		{"id": "dispatch_board", "pos": Vector2(3512, 320), "radius": 18.0, "prompt": "Read the dispatch board"},
	]
	return p


## The freight shed at the east end of the depot, its wide door onto the
## loading yard: concrete, crates stacked to the beams, a hand truck, a stove
## the shed men keep going all night - and in the far corner, under a
## tarpaulin, a consignment that should have gone out. Walt Haney, the shed
## foreman, keeps it there.
const HELD_CRATES := Vector2(4140, 300)


static func freight_shed(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("freight_shed", "North Branch Freight - Shed")
	p.building = d.building_named(DEPOT)
	p.building_rect = Rect2(3901, 216, 560, 420)  # the depot's east part
	p.room = Rect2(4061, 216, 400, 420)
	p.floor = "interiors/floor_concrete"
	p.doors = [{"side": Vector2.RIGHT, "at": 560.0, "width": 44.0}]  # the loading door
	p.furniture = [
		{"kind": "interiors/freight_crates", "pos": HELD_CRATES, "box": Vector2(56, 40)},
		{"kind": "interiors/crate_stack", "pos": Vector2(4090, 245), "box": Vector2(28, 28)},
		{"kind": "interiors/crate_stack", "pos": Vector2(4090, 380), "box": Vector2(28, 28)},
		{"kind": "interiors/crate_stack", "pos": Vector2(4260, 245), "box": Vector2(28, 28)},
		{"kind": "interiors/crate_stack", "pos": Vector2(4294, 245), "box": Vector2(28, 28)},
		{"kind": "interiors/crate_stack", "pos": Vector2(4430, 245), "box": Vector2(28, 28)},
		{"kind": "interiors/crate_stack", "pos": Vector2(4430, 279), "box": Vector2(28, 28)},
		{"kind": "interiors/crate_stack", "pos": Vector2(4100, 600), "box": Vector2(28, 28)},
		{"kind": "interiors/crate_stack", "pos": Vector2(4134, 600), "box": Vector2(28, 28)},
		{"kind": "interiors/hand_truck", "pos": Vector2(4330, 520), "rot": 0.4, "radius": 6.0},
		{"kind": "interiors/potbelly", "pos": Vector2(4250, 430), "radius": 11.0},
		{"kind": "interiors/chalkboard", "pos": Vector2(4360, 224), "box": Vector2(66, 8)},
		{"kind": "interiors/bench", "pos": Vector2(4210, 470), "box": Vector2(66, 14)},
	]
	p.lamps = [
		{"pos": Vector2(4170, 300), "color": Color(1.0, 0.8, 0.55), "energy": 0.6, "radius": 170.0},
		{"pos": Vector2(4340, 480), "color": Color(1.0, 0.8, 0.55), "energy": 0.6, "radius": 170.0},
		{"pos": Vector2(4250, 430), "color": Color(1.0, 0.55, 0.3), "energy": 0.4, "radius": 60.0},  # the stove
	]
	p.people = [
		{"id": "walt", "name": "Walt Haney", "look": "characters/foreman", "pos": Vector2(4282, 430), "facing": PI},
		{"id": "shed_a", "name": "", "look": "characters/worker", "pos": Vector2(4190, 452), "facing": PI / 2},
		{"id": "shed_b", "name": "", "look": "characters/worker", "pos": Vector2(4226, 400), "facing": PI / 2},
	]
	p.spots = [
		{"id": "walt", "pos": Vector2(4310, 430), "radius": 20.0, "prompt": "Talk to the shed foreman"},
		{"id": "held_crates", "pos": HELD_CRATES + Vector2(0, 40), "radius": 20.0, "prompt": "Look at the crates under the tarpaulin"},
	]
	return p
