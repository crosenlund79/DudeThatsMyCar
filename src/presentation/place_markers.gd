class_name PlaceMarkers
extends Node2D
## A painted badge floating over the main door of every place you can walk
## into (the same icons as on the minimap): faint from a block away, clearer
## and a little larger as you walk or drive closer, pulsing when you stand
## at the door, gone while you are inside. They mark places, not tasks.
## Presentation only: reads the player's position, changes nothing.

## Seen from this far (px); full strength from NEAR in.
const FAR := 950.0
const NEAR := 260.0
## How high over the door the badge floats (world px, in perspective).
const LIFT := 58.0
const BOB := 2.5

## One marker per marked room: {plan, door: Vector2, node: Node2D, icon: Sprite2D, glow: Sprite2D, phase}
var markers: Array = []
var _time := 0.0


static func unshaded() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return m


func setup(layout: DistrictLayout, resolver: AssetResolver) -> void:
	name = "PlaceMarkers"
	add_layout(layout, resolver)


## M015.12: the badges over the doors of another district's places (made once,
## from its plan; a badge only shows near its door, so a district not built
## costs nothing but the node).
func add_layout(layout: DistrictLayout, resolver: AssetResolver) -> void:
	var mat := unshaded()
	var k := markers.size()
	for plan in layout.interiors:
		var p: InteriorPlan = plan
		if p.marker == "" or p.doors.is_empty():
			continue
		var node := Node2D.new()
		node.name = "Marker_" + p.id
		node.z_index = Layers.Z_MIST + 3
		node.z_as_relative = false
		add_child(node)
		var glow := Sprite2D.new()
		glow.texture = resolver.get_texture("fx/glow")
		glow.material = DrawLayer.glow_material()
		glow.scale = AssetCatalog.scale_for(glow.texture, Vector2(64, 64))
		glow.modulate = Color(1.0, 0.75, 0.45, 0.0) if not p.is_home else Color(0.6, 0.95, 0.9, 0.0)
		node.add_child(glow)
		var icon := Sprite2D.new()
		icon.texture = resolver.get_texture(p.marker)
		icon.material = mat
		var size := AssetCatalog.display_size(p.marker)
		icon.scale = AssetCatalog.scale_for(icon.texture, size)
		icon.offset = Vector2(0, -icon.texture.get_height() * 0.5)  # the pin's point sits on the marker's position
		node.add_child(icon)
		markers.append({"plan": p, "door": p.outside_door(0, 14.0), "node": node, "icon": icon, "glow": glow,
			"phase": k * 1.7, "strength": 0.0})
		k += 1


## How strongly a marker shows for someone `d` px from its door (0..1).
static func strength_at(d: float) -> float:
	return 1.0 - smoothstep(NEAR, FAR, d)


func marker_of(plan_id: String) -> Dictionary:
	for m in markers:
		if (m.plan as InteriorPlan).id == plan_id:
			return m
	return {}


## Every frame: focus = the player (on foot or in his car), inside = the room
## he is in (null in the street), at_door = the room whose door he stands at.
func update_markers(delta: float, eye: Vector2, eye_height: float, focus: Vector2, inside: InteriorPlan,
		at_door: InteriorPlan) -> void:
	_time += delta
	for m in markers:
		var plan: InteriorPlan = m.plan
		var node: Node2D = m.node
		var door: Vector2 = m.door
		var s := 0.0 if plan == inside else strength_at(focus.distance_to(door))
		m.strength = s
		node.visible = s > 0.01
		if not node.visible:
			continue
		var active := plan == at_door
		var bob := sin(_time * 2.2 + float(m.phase)) * BOB * s
		node.position = Perspective.project(door, LIFT, eye, eye_height) + Vector2(0, bob)
		var pulse := 1.0 + (0.08 * sin(_time * 6.0) if active else 0.0)
		var grow := lerpf(0.75, 1.05, s) * pulse * (1.12 if active else 1.0)
		node.scale = Vector2(grow, grow)
		(m.icon as Sprite2D).modulate = Color(1, 1, 1, lerpf(0.0, 1.0, s))
		(m.glow as Sprite2D).modulate.a = (0.55 if active else 0.3) * s
		(m.glow as Sprite2D).position = Vector2(0, -AssetCatalog.display_size(plan.marker).y * 0.6)
