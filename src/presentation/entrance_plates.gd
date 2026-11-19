class_name EntrancePlates
extends Node2D
## M012: a worn brass plate on the pavement before every street door Danny
## can try - flat on the ground, never floating - tinted by what the door
## does: warm brass where it opens on a room, cold pewter where it is shut for
## the night, amber where a bell brings someone to it (the mayor's gate). Dim
## from across the street, brighter as he comes up to it. Only street doors:
## a door between two rooms (the Copper Owl's back rooms) is nobody's
## business from outside. One small sprite a door; the ward's are made at
## start-up, a streamed district's with it (`add_district`, under its node).

const OPEN := Color(0.86, 0.68, 0.38)
const SHUT := Color(0.5, 0.55, 0.62)
const BELL := Color(0.9, 0.52, 0.24)
## How far off the plates start to brighten, and how dim they are beyond it.
const NEAR := 180.0
const FAR_ALPHA := 0.5

## Every plate built: {node: Sprite2D, kind: "open" | "shut" | "bell", pos, district}.
var plates: Array = []
var _resolver: AssetResolver
var _unshaded := PlaceMarkers.unshaded()


func setup(resolver: AssetResolver) -> void:
	name = "EntrancePlates"
	_resolver = resolver


## Plates for a district's doors under `parent` (the district's node, so they go with it).
func add_district(l: DistrictLayout, parent: Node) -> void:
	remove_district(l.id)
	for plan in l.interiors:
		var p: InteriorPlan = plan
		for i in p.doors.size():
			if p.doors[i].get("inner", false):
				continue
			var side: Vector2 = p.doors[i].side
			# under a shop's awning the plate would not be seen: it lies just past the awning's edge
			var out := 10.0
			for prop in l.props:
				var k := String(prop.kind)
				if (k.begins_with("props/awning") or k.begins_with("props/marquee")) \
						and (prop.pos as Vector2).distance_to(p.outside_door(i, 18.0)) < 80.0:
					out = 56.0 if k.begins_with("props/marquee") else 46.0
			_plate(parent, l.id, "open", p.outside_door(i, out), side, float(p.doors[i].width))
	for d in l.locked_doors:
		var kind := "bell" if String(d.get("talk", "")) != "" else "shut"
		_plate(parent, l.id, kind, d.pos, Vector2.ZERO, 28.0)


func remove_district(id: String) -> void:
	for i in range(plates.size() - 1, -1, -1):
		if plates[i].district == id:
			var n: Node = plates[i].node
			if is_instance_valid(n) and n.get_parent() == self:
				n.queue_free()
			plates.remove_at(i)


func _plate(parent: Node, district: String, kind: String, at: Vector2, side: Vector2, width: float) -> void:
	var s := Sprite2D.new()
	s.texture = _resolver.get_texture("ui/door_plate")
	s.position = at
	s.rotation = side.orthogonal().angle() if side != Vector2.ZERO else 0.0
	s.scale = AssetCatalog.scale_for(s.texture, Vector2(maxf(width, 24.0) + 10.0, 11.0))
	var glint := Sprite2D.new()  # a soft pool of its own colour round it, so it reads from across the street
	glint.texture = _resolver.get_texture("fx/glow")
	glint.material = DrawLayer.glow_material()
	glint.scale = AssetCatalog.scale_for(glint.texture, Vector2(maxf(width, 24.0) + 40.0, 30.0)) / s.scale
	glint.show_behind_parent = true
	s.add_child(glint)
	s.z_index = Layers.Z_DECAL + 1
	s.z_as_relative = false
	s.material = _unshaded  # its own glint: the night tint would swallow it
	var tint: Color = {"open": OPEN, "shut": SHUT, "bell": BELL}[kind]
	s.modulate = Color(tint, FAR_ALPHA)
	s.name = "Plate_%s_%d" % [kind, plates.size()]
	parent.add_child(s)
	plates.append({"node": s, "kind": kind, "pos": at, "district": district, "tint": tint})


## Every frame with where Danny is (INF in a car: the plates stay dim).
func update(p: Vector2) -> void:
	for e in plates:
		var s: Sprite2D = e.node
		if not is_instance_valid(s):
			continue
		var near := 0.0 if p == Vector2.INF else clampf(1.0 - (p.distance_to(e.pos) - 40.0) / NEAR, 0.0, 1.0)
		s.modulate = Color(e.tint, lerpf(FAR_ALPHA, 1.0, near))


## The plate nearest p ({} if none).
func nearest(p: Vector2) -> Dictionary:
	var best := {}
	var best_d := INF
	for e in plates:
		var dist := p.distance_to(e.pos)
		if dist < best_d:
			best = e
			best_d = dist
	return best
