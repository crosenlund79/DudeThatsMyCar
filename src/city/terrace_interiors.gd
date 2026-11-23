class_name TerraceInteriors
extends RefCounted
## M015: the rooms you can walk into in Lincoln Terrace (data only; see
## InteriorPlan), written in the terrace's own coordinates and moved with it.


static func add_to(d: DistrictLayout) -> void:
	d.interiors.append(belvedere_lobby(d))
	d.interiors.append(paradise(d))


## The Belvedere's lobby: marble, bronze and palms; the long front desk with
## the key rack behind it and the night manager at it; armchairs and couches
## round the columns where men who own aldermen sit up late; the grand stair
## roped off, the lift for residents and their guests. The rest of the hotel's
## eleven storeys stay shut.
static func belvedere_lobby(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("belvedere", LincolnTerrace.BELVEDERE)
	p.building = d.building_named(LincolnTerrace.BELVEDERE)
	p.building_rect = d.buildings[p.building].rect  # x 4229..4869, y 831..1339 (the front on Lincoln Boulevard)
	var r: Rect2 = p.building_rect
	p.room = Rect2(r.position.x, r.end.y - 250.0, r.size.x, 250.0)  # the ground floor's front
	var top := p.room.position.y
	var mid := r.get_center().x
	p.marker = "ui/marker_hotel"
	p.floor = "interiors/floor_marble"
	p.doors = [{"side": Vector2.DOWN, "at": mid, "width": 44.0}]
	p.furniture = [
		{"kind": "interiors/clerk_counter", "pos": Vector2(mid, top + 44.0), "box": Vector2(150, 20)},
		{"kind": "interiors/records_shelf", "pos": Vector2(mid, top + 14.0), "box": Vector2(60, 14)},  # the key rack
		{"kind": "interiors/staircase", "pos": Vector2(r.position.x + 40.0, top + 60.0), "box": Vector2(56, 90)},
		{"kind": "interiors/column", "pos": Vector2(mid - 170.0, top + 110.0), "radius": 10.0},
		{"kind": "interiors/column", "pos": Vector2(mid + 170.0, top + 110.0), "radius": 10.0},
		{"kind": "interiors/column", "pos": Vector2(mid - 170.0, top + 200.0), "radius": 10.0},
		{"kind": "interiors/column", "pos": Vector2(mid + 170.0, top + 200.0), "radius": 10.0},
		{"kind": "interiors/palm", "pos": Vector2(mid - 60.0, top + 224.0), "radius": 10.0},
		{"kind": "interiors/palm", "pos": Vector2(mid + 60.0, top + 224.0), "radius": 10.0},
		{"kind": "interiors/rug", "pos": Vector2(r.position.x + 150.0, top + 160.0)},
		{"kind": "interiors/armchair", "pos": Vector2(r.position.x + 110.0, top + 140.0), "rot": PI / 2, "box": Vector2(24, 24)},
		{"kind": "interiors/armchair", "pos": Vector2(r.position.x + 190.0, top + 140.0), "rot": PI / 2, "box": Vector2(24, 24)},
		{"kind": "interiors/couch", "pos": Vector2(r.position.x + 150.0, top + 200.0), "rot": -PI / 2 * 0.0, "box": Vector2(52, 16)},
		{"kind": "interiors/rug", "pos": Vector2(r.end.x - 150.0, top + 160.0)},
		{"kind": "interiors/armchair", "pos": Vector2(r.end.x - 110.0, top + 140.0), "rot": PI / 2, "box": Vector2(24, 24)},
		{"kind": "interiors/armchair", "pos": Vector2(r.end.x - 190.0, top + 140.0), "rot": PI / 2, "box": Vector2(24, 24)},
		{"kind": "interiors/side_table", "pos": Vector2(r.end.x - 150.0, top + 140.0), "radius": 8.0},
		{"kind": "interiors/portrait", "pos": Vector2(r.end.x - 120.0, top + 12.0)},
		{"kind": "interiors/tall_clock", "pos": Vector2(r.end.x - 24.0, top + 40.0), "radius": 7.0},
	]
	p.lamps = [
		{"pos": Vector2(mid, top + 130.0), "color": Color(1.0, 0.88, 0.65), "energy": 1.1, "radius": 260.0},  # the chandelier
		{"pos": Vector2(r.position.x + 150.0, top + 160.0), "color": Color(1.0, 0.82, 0.58), "energy": 0.6, "radius": 120.0},
		{"pos": Vector2(r.end.x - 150.0, top + 160.0), "color": Color(1.0, 0.82, 0.58), "energy": 0.6, "radius": 120.0},
	]
	p.people = [
		{"id": "pratt", "name": "Ellery Pratt", "look": "characters/clerk", "pos": Vector2(mid, top + 26.0), "facing": PI / 2},
		{"id": "bellboy", "name": "", "look": "characters/croupier", "pos": Vector2(mid + 120.0, top + 70.0), "facing": PI / 2},
		{"id": "guest_a", "name": "", "look": "characters/alderman", "pos": Vector2(r.end.x - 110.0, top + 140.0), "facing": PI},
		{"id": "guest_b", "name": "", "look": "characters/lady", "pos": Vector2(r.position.x + 190.0, top + 140.0), "facing": PI / 2},
	]
	p.spots = [
		{"id": "pratt", "pos": Vector2(mid, top + 74.0), "radius": 22.0, "prompt": "Talk to the night manager"},
		{"id": "belvedere_lift", "pos": Vector2(r.end.x - 40.0, top + 90.0), "radius": 20.0, "prompt": "Ring for the lift"},
	]
	return p


## The Paradise Ballroom: a sprung maple floor under a ceiling of painted
## stars, the bandstand at the back with its piano and music stands, little
## tables round the edge with ginger ale and what the waiters pour into it,
## the ticket booth by the door. Ruby Marchetti runs it: ten cents a dance
## with the hostesses, and nothing on the books that a policeman could read.
static func paradise(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("paradise", LincolnTerrace.PARADISE)
	p.building = d.building_named(LincolnTerrace.PARADISE)
	p.building_rect = d.buildings[p.building].rect  # x 4269..4869, y 2083..2429 (the front on Lake Street)
	var r: Rect2 = p.building_rect
	p.room = r
	var mid := r.get_center().x
	p.marker = "ui/marker_dance"
	p.floor = "interiors/floor_parquet"
	p.doors = [{"side": Vector2.DOWN, "at": mid, "width": 44.0}]
	p.furniture = [
		{"kind": "interiors/bandstand", "pos": Vector2(mid, r.position.y + 50.0), "box": Vector2(200, 60)},
		{"kind": "interiors/piano", "pos": Vector2(mid - 70.0, r.position.y + 40.0), "box": Vector2(44, 26)},
		{"kind": "interiors/microphone", "pos": Vector2(mid + 10.0, r.position.y + 86.0)},
		{"kind": "interiors/clerk_counter", "pos": Vector2(r.end.x - 160.0, r.end.y - 80.0), "box": Vector2(150, 20)},  # tickets
	]
	for k in 4:  # the little tables down both sides
		for side in [-1.0, 1.0]:
			var x: float = r.position.x + 40.0 if side < 0 else r.end.x - 40.0
			var y: float = r.position.y + 120.0 + k * 52.0
			p.furniture.append({"kind": "interiors/table_club", "pos": Vector2(x, y), "radius": 13.0})
			p.furniture.append({"kind": "interiors/chair", "pos": Vector2(x - side * 22.0, y), "rot": -side * PI / 2})
	p.lamps = [
		{"pos": Vector2(mid, r.position.y + 180.0), "color": Color(0.85, 0.8, 1.0), "energy": 0.9, "radius": 260.0},  # the stars
		{"pos": Vector2(mid, r.position.y + 50.0), "color": Color(1.0, 0.8, 0.5), "energy": 0.9, "radius": 140.0},  # the band
		{"pos": Vector2(r.end.x - 160.0, r.end.y - 80.0), "color": Color(1.0, 0.85, 0.6), "energy": 0.55, "radius": 80.0},
	]
	p.people = [
		{"id": "ruby", "name": "Ruby Marchetti", "look": "characters/singer", "pos": Vector2(r.end.x - 160.0, r.end.y - 104.0), "facing": PI / 2},
		{"id": "bandleader", "name": "", "look": "characters/croupier", "pos": Vector2(mid + 10.0, r.position.y + 66.0), "facing": PI / 2},
		{"id": "dancer_a", "name": "", "look": "characters/patron_man", "pos": Vector2(mid - 60.0, r.position.y + 170.0), "facing": 0.0},
		{"id": "dancer_b", "name": "", "look": "characters/patron_woman", "pos": Vector2(mid - 42.0, r.position.y + 170.0), "facing": PI},
		{"id": "dancer_c", "name": "", "look": "characters/alderman", "pos": Vector2(mid + 50.0, r.position.y + 220.0), "facing": 0.0},
		{"id": "dancer_d", "name": "", "look": "characters/lady", "pos": Vector2(mid + 68.0, r.position.y + 220.0), "facing": PI},
	]
	p.spots = [
		{"id": "ruby", "pos": Vector2(r.end.x - 160.0, r.end.y - 48.0), "radius": 22.0, "prompt": "Talk to the hostess"},
		{"id": "bandleader", "pos": Vector2(mid + 10.0, r.position.y + 108.0), "radius": 20.0, "prompt": "Talk to the bandleader"},
	]
	return p
