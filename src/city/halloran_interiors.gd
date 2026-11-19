class_name HalloranInteriors
extends RefCounted
## M012: the rooms you can walk into in Halloran Square (data only; see
## InteriorPlan). Written in the square's own coordinates, like the rest of
## HalloranSquare, and moved with it into the world (DistrictLayout.shift).
## Each room sits in an existing building, which keeps its outside look.


static func add_to(d: DistrictLayout) -> void:
	d.interiors.append(doran_office(d))
	d.interiors.append(city_hall(d))
	d.interiors.append(regulars_club(d))


## Alderman Martin J. Doran's ward office on Marlowe Avenue, across from the
## park: the front room where the ward's people wait their turn - chairs along
## the wall, a horsehair couch under the photographs (the alderman shaking
## hands, cutting ribbons, at the ward picnic) - and the precinct captain's
## desk; through a doorway the alderman's own office: his desk, the flag, a
## portrait, the filing cabinets and the safe. The alderman is out ("back
## Tuesday"); his precinct captain keeps the lamp burning late.
static func doran_office(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("doran_office", HalloranSquare.DORAN)
	p.building = d.building_named(HalloranSquare.DORAN)
	p.building_rect = d.buildings[p.building].rect  # x 1531..1831, y 1468..1739 (the front on Marlowe Avenue)
	p.room = Rect2(1531, 1551, 300, 188)  # the ground floor's front; the stairs and the rooms above stay shut
	p.floor = "interiors/floor_boards"
	p.doors = [{"side": Vector2.DOWN, "at": 1640.0, "width": 28.0}]  # off Marlowe Avenue
	p.partitions = [{"a": Vector2(1716, 1551), "b": Vector2(1716, 1739), "door_at": 1700.0, "door_width": 28.0}]
	p.furniture = [
		# the front room
		{"kind": "interiors/photo_wall", "pos": Vector2(1598, 1562)},
		{"kind": "interiors/couch", "pos": Vector2(1598, 1580), "box": Vector2(52, 16)},
		{"kind": "interiors/chair", "pos": Vector2(1550, 1626), "rot": -PI / 2},
		{"kind": "interiors/chair", "pos": Vector2(1550, 1650), "rot": -PI / 2},
		{"kind": "interiors/chair", "pos": Vector2(1550, 1674), "rot": -PI / 2},
		{"kind": "interiors/bench", "pos": Vector2(1580, 1720), "rot": PI, "box": Vector2(66, 14)},  # against the front wall, facing in
		{"kind": "interiors/coat_rack", "pos": Vector2(1700, 1722), "radius": 6.0},
		{"kind": "interiors/desk", "pos": Vector2(1660, 1625), "box": Vector2(70, 32)},
		{"kind": "interiors/chair", "pos": Vector2(1660, 1601)},
		{"kind": "interiors/spittoon", "pos": Vector2(1696, 1660)},
		# the alderman's office
		{"kind": "interiors/portrait", "pos": Vector2(1784, 1562)},
		{"kind": "interiors/flag_stand", "pos": Vector2(1734, 1574), "radius": 6.0},
		{"kind": "interiors/desk", "pos": Vector2(1784, 1606), "box": Vector2(70, 32)},
		{"kind": "interiors/chair", "pos": Vector2(1784, 1582)},
		{"kind": "interiors/chair", "pos": Vector2(1768, 1638), "rot": PI},
		{"kind": "interiors/chair", "pos": Vector2(1800, 1638), "rot": PI},
		{"kind": "interiors/filing_cabinet", "pos": Vector2(1814, 1668), "rot": PI / 2, "box": Vector2(22, 18)},
		{"kind": "interiors/filing_cabinet", "pos": Vector2(1814, 1692), "rot": PI / 2, "box": Vector2(22, 18)},
		{"kind": "interiors/safe", "pos": Vector2(1812, 1720), "box": Vector2(18, 18)},
		{"kind": "interiors/smoke", "pos": Vector2(1640, 1640), "z": 11},
	]
	p.lamps = [
		{"pos": Vector2(1660, 1625), "color": Color(0.9, 1.0, 0.76), "energy": 0.95, "radius": 115.0},  # the captain's green lamp
		{"pos": Vector2(1600, 1660), "color": Color(1.0, 0.78, 0.52), "energy": 0.7, "radius": 130.0},  # the front room's bulb
		{"pos": Vector2(1784, 1606), "color": Color(1.0, 0.8, 0.55), "energy": 0.55, "radius": 90.0},  # left on in the alderman's office
	]
	p.people = [
		{"id": "heeler", "name": "", "look": "characters/patron_man", "pos": Vector2(1660, 1601), "facing": PI / 2},
	]
	p.spots = [
		{"id": "heeler", "pos": Vector2(1660, 1654), "radius": 20.0, "prompt": "Talk to the precinct captain"},
		{"id": "doran_photos", "pos": Vector2(1598, 1604), "radius": 20.0, "prompt": "Look at the photographs"},
		{"id": "doran_desk", "pos": Vector2(1784, 1652), "radius": 20.0, "prompt": "Look over the alderman's desk"},
	]
	return p


## City Hall at night: the night door off the steps on Pruitt Street into the
## marble hall - columns, two flags, the portraits of mayors past, benches for
## whoever has business before morning, the noticeboard - and across the back
## the night clerk's counter behind its brass grille. The broad stair at the
## east end goes up to the Mayor's office, a velvet rope across its foot.
## Behind the hall, through a door at the end of the counter, the City Clerk's
## office (a desk, cabinets, the vault's iron door) and beyond it the records
## room (shelves of bound ledgers: births, deaths, permits, the ward rolls).
## Signs of power and paperwork; no politics to play.
const CITY_HALL_STAIRS := Vector2(2050, 3000)


static func city_hall(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("city_hall", HalloranSquare.CITY_HALL)
	p.building = d.building_named(HalloranSquare.CITY_HALL)
	p.building_rect = d.buildings[p.building].rect  # x 1531..2119, y 2931..3300 (the front on Pruitt Street)
	p.room = Rect2(1561, 2931, 528, 300)
	p.floor = "interiors/floor_marble"
	p.doors = [{"side": Vector2.UP, "at": 1825.0, "width": 34.0}]  # the night door, at the top of the steps
	p.partitions = [
		{"a": Vector2(1561, 3131), "b": Vector2(2089, 3131), "door_at": 1960.0, "door_width": 30.0},  # the hall / the offices
		{"a": Vector2(1781, 3131), "b": Vector2(1781, 3231), "door_at": 3181.0, "door_width": 28.0},  # the clerk's / the records
	]
	p.furniture = [
		# the hall
		{"kind": "interiors/column", "pos": Vector2(1700, 2985), "radius": 12.0},
		{"kind": "interiors/column", "pos": Vector2(1950, 2985), "radius": 12.0},
		{"kind": "interiors/column", "pos": Vector2(1700, 3060), "radius": 12.0},
		{"kind": "interiors/column", "pos": Vector2(1950, 3060), "radius": 12.0},
		{"kind": "interiors/clerk_counter", "pos": Vector2(1825, 3094), "rot": PI, "box": Vector2(150, 24)},
		{"kind": "interiors/flag_stand", "pos": Vector2(1733, 3100), "radius": 6.0},
		{"kind": "interiors/flag_stand", "pos": Vector2(1917, 3100), "radius": 6.0},
		{"kind": "interiors/portrait", "pos": Vector2(1640, 3121), "rot": PI},
		{"kind": "interiors/portrait", "pos": Vector2(2020, 3121), "rot": PI},
		{"kind": "interiors/noticeboard", "pos": Vector2(1650, 2944)},
		{"kind": "interiors/tall_clock", "pos": Vector2(2000, 2946)},
		{"kind": "interiors/bench", "pos": Vector2(1576, 3005), "rot": -PI / 2, "box": Vector2(66, 14)},
		{"kind": "interiors/bench", "pos": Vector2(1576, 3080), "rot": -PI / 2, "box": Vector2(66, 14)},
		{"kind": "interiors/spittoon", "pos": Vector2(1594, 3044)},
		{"kind": "interiors/staircase", "pos": CITY_HALL_STAIRS, "box": Vector2(56, 64)},
		# the City Clerk's office
		{"kind": "interiors/desk", "pos": Vector2(1900, 3180), "box": Vector2(70, 32)},
		{"kind": "interiors/chair", "pos": Vector2(1900, 3156)},
		{"kind": "interiors/filing_cabinet", "pos": Vector2(2078, 3160), "rot": PI / 2, "box": Vector2(22, 18)},
		{"kind": "interiors/filing_cabinet", "pos": Vector2(2078, 3184), "rot": PI / 2, "box": Vector2(22, 18)},
		{"kind": "interiors/safe", "pos": Vector2(2074, 3212), "box": Vector2(18, 18)},
		{"kind": "interiors/records_shelf", "pos": Vector2(2000, 3216), "rot": PI, "box": Vector2(66, 12)},
		# the records room
		{"kind": "interiors/records_shelf", "pos": Vector2(1610, 3146), "box": Vector2(66, 12)},
		{"kind": "interiors/records_shelf", "pos": Vector2(1720, 3146), "box": Vector2(66, 12)},
		{"kind": "interiors/records_shelf", "pos": Vector2(1610, 3216), "rot": PI, "box": Vector2(66, 12)},
		{"kind": "interiors/side_table", "pos": Vector2(1622, 3181), "radius": 10.0},
		{"kind": "interiors/chair", "pos": Vector2(1646, 3181), "rot": PI / 2},
	]
	p.lamps = [
		{"pos": Vector2(1825, 3020), "color": Color(1.0, 0.86, 0.62), "energy": 0.85, "radius": 230.0},  # the hall's chandelier
		{"pos": Vector2(1825, 3094), "color": Color(0.9, 1.0, 0.76), "energy": 0.8, "radius": 100.0},  # the clerk's green lamp
		{"pos": Vector2(1900, 3180), "color": Color(1.0, 0.8, 0.55), "energy": 0.55, "radius": 120.0},
		{"pos": Vector2(1640, 3181), "color": Color(1.0, 0.8, 0.55), "energy": 0.45, "radius": 110.0},
	]
	p.people = [
		{"id": "nightclerk", "name": "", "look": "characters/clerk", "pos": Vector2(1825, 3116), "facing": -PI / 2},
		{"id": "janitor", "name": "", "look": "characters/worker", "pos": Vector2(1630, 2990), "facing": 0.3},
	]
	p.spots = [
		{"id": "nightclerk", "pos": Vector2(1825, 3062), "radius": 20.0, "prompt": "Talk to the night clerk"},
		{"id": "city_board", "pos": Vector2(1650, 2968), "radius": 18.0, "prompt": "Read the notices"},
		{"id": "city_stairs", "pos": CITY_HALL_STAIRS + Vector2(0, 50), "radius": 20.0, "prompt": "The stairs to the Mayor's office"},
		{"id": "city_records", "pos": Vector2(1720, 3172), "radius": 18.0, "prompt": "Leaf through the records"},
	]
	return p


## The Halloran Square Regulars' Club on Marlowe Avenue, where the precinct
## men and the ward's friends take their ease: the lounge - cracked leather
## armchairs round small tables, a couch, the sideboard where the steward pours,
## old Mike Halloran in oils over the door - and through a doorway the billiard
## room under its green lamp. Old wood, older smoke. Members and their guests;
## nobody gambles here and nobody joins tonight.
static func regulars_club(d: DistrictLayout) -> InteriorPlan:
	var p := InteriorPlan.new("regulars_club", HalloranSquare.REGULARS)
	p.building = d.building_named(HalloranSquare.REGULARS)
	p.building_rect = d.buildings[p.building].rect  # x 420..890, y 2061..2332 (the front on Marlowe Avenue)
	p.room = Rect2(420, 2061, 470, 250)
	p.floor = "interiors/floor_carpet"
	p.doors = [{"side": Vector2.UP, "at": 545.0, "width": 28.0}]
	p.partitions = [{"a": Vector2(670, 2061), "b": Vector2(670, 2311), "door_at": 2230.0, "door_width": 28.0}]
	p.furniture = [
		# the lounge
		{"kind": "interiors/sideboard", "pos": Vector2(438, 2160), "rot": -PI / 2, "box": Vector2(56, 18)},
		{"kind": "interiors/portrait", "pos": Vector2(615, 2072)},
		{"kind": "interiors/coat_rack", "pos": Vector2(446, 2082), "radius": 6.0},
		{"kind": "interiors/side_table", "pos": Vector2(565, 2150), "radius": 10.0},
		{"kind": "interiors/armchair", "pos": Vector2(538, 2150), "rot": -PI / 2},  # a regular sits in it
		{"kind": "interiors/armchair", "pos": Vector2(592, 2150), "rot": PI / 2, "radius": 9.0},
		{"kind": "interiors/side_table", "pos": Vector2(565, 2240), "radius": 10.0},
		{"kind": "interiors/armchair", "pos": Vector2(538, 2240), "rot": -PI / 2, "radius": 9.0},
		{"kind": "interiors/armchair", "pos": Vector2(592, 2240), "rot": PI / 2},  # and another
		{"kind": "interiors/couch", "pos": Vector2(470, 2292), "rot": PI, "box": Vector2(52, 16)},
		{"kind": "interiors/spittoon", "pos": Vector2(510, 2200)},
		{"kind": "interiors/smoke", "pos": Vector2(565, 2195), "z": 11},
		# the billiard room
		{"kind": "interiors/billiard_table", "pos": Vector2(778, 2180), "rot": PI / 2, "box": Vector2(96, 56)},
		{"kind": "interiors/coat_rack", "pos": Vector2(870, 2082), "radius": 6.0},
		{"kind": "interiors/armchair", "pos": Vector2(866, 2280), "rot": PI / 2, "radius": 9.0},
		{"kind": "interiors/armchair", "pos": Vector2(866, 2250), "rot": PI / 2, "radius": 9.0},
		{"kind": "interiors/photo_wall", "pos": Vector2(780, 2072)},
		{"kind": "interiors/smoke", "pos": Vector2(778, 2180), "z": 11},
	]
	p.lamps = [
		{"pos": Vector2(560, 2190), "color": Color(1.0, 0.74, 0.46), "energy": 0.8, "radius": 170.0},
		{"pos": Vector2(778, 2180), "color": Color(0.92, 1.0, 0.8), "energy": 1.0, "radius": 115.0},  # over the billiard table
		{"pos": Vector2(446, 2160), "color": Color(1.0, 0.6, 0.35), "energy": 0.35, "radius": 60.0},  # the sideboard's lamp
	]
	p.people = [
		{"id": "steward", "name": "", "look": "characters/bartender", "pos": Vector2(462, 2190), "facing": 0.0},
		{"id": "regular_a", "name": "", "look": "characters/boss", "pos": Vector2(538, 2150), "facing": 0.0},
		{"id": "regular_b", "name": "", "look": "characters/patron_man", "pos": Vector2(592, 2240), "facing": PI},
		{"id": "regular_c", "name": "", "look": "characters/dealer", "pos": Vector2(828, 2140), "facing": PI},
	]
	p.spots = [
		{"id": "steward", "pos": Vector2(490, 2190), "radius": 18.0, "prompt": "Talk to the steward"},
		{"id": "regulars_portrait", "pos": Vector2(615, 2096), "radius": 18.0, "prompt": "Look at the portrait"},
	]
	return p
