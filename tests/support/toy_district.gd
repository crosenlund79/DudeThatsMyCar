extends RefCounted
## M008 tests: a small made-up district (3000 x 1200 px in its own
## coordinates) with one street through it east-west, two blocks, a few
## buildings, lamps, a parked car and a beat - placed in the world at
## `origin`, with exits east and west into its neighbours.

const SIZE := 3000.0


static func make(id: String, origin: Vector2, west: String = "", east: String = "") -> DistrictLayout:
	var d := DistrictLayout.new()
	d.id = id
	d.name = id.capitalize()
	d.bounds = Rect2(0, 0, SIZE, 1200)
	d.play_area = Rect2(0, 200, SIZE, 800)
	d.streets.append({"name": "Toy Street", "avenue": false, "rect": Rect2(0, 515, SIZE, 170)})
	d.blocks.append(Rect2(0, 200, SIZE, 315))
	d.blocks.append(Rect2(0, 685, SIZE, 315))
	for k in 10:
		d.buildings.append({"rect": Rect2(60 + k * 290, 260, 220, 210), "storeys": 2 + k % 2, "facade": "brick_red",
			"roof": "tar", "front": Vector2.DOWN, "props": [{"kind": "roof/chimney", "pos": Vector2(100 + k * 290, 300), "rot": 0.0}],
			"signs": [], "name": "", "opts": {}})
	d.lamps = [Vector2(200, 505), Vector2(700, 505), Vector2(450, 695), Vector2(1500, 505), Vector2(2500, 695)]
	d.props.append({"kind": "props/hydrant", "pos": Vector2(300, 500), "rot": 0.0, "height": 0.0, "radius": 6.0})
	d.decals.append({"kind": "decals/manhole", "pos": Vector2(600, 600), "rot": 0.0, "scale": 1.0})
	d.cars.append({"type": "sedan", "paint": 0, "pos": Vector2(500, 560), "rot": 0.0, "owner": "somebody in " + id})
	d.police_beat = PackedVector2Array([Vector2(400, 505), Vector2(600, 505)])
	d.walk_routes = [PackedVector2Array([Vector2(100, 500), Vector2(2900, 500)])]
	d.spawn = Vector2(600, 600)
	if west != "":
		d.exits.append({"to": west, "rect": Rect2(0, 500, 6, 200)})
	if east != "":
		d.exits.append({"to": east, "rect": Rect2(SIZE - 6, 500, 6, 200)})
	d.landmarks.append({"pos": Vector2(600, 300), "label": "The %s Works" % id.capitalize()})
	return d.shift(origin)
