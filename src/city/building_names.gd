class_name BuildingNames
extends RefCounted
## M010: what every building in a district is called on the city map: its own
## name where it has one (the Copper Owl, North Branch Freight, St. Brendan's),
## otherwise a plain designation and a street address made up from the street
## it faces - "Flats, 2214 Marlowe Ave", "Warehouse, 4520 Front St",
## "1406 Kessler St". Chicago numbers rising along the street, even on one
## side and odd on the other. Pure and deterministic; no rooms are implied.

const KIND := {"tenement": "Flats", "greystone": "Flats", "warehouse": "Warehouse", "factory": "Works",
	"stack": "Works stack", "garage": "Garage", "stone": "", "club": ""}
const SHORT := {" Street": " St", " Avenue": " Ave"}


## Every building's label, in the layout's order.
static func all(layout: DistrictLayout) -> Array[String]:
	var out: Array[String] = []
	for b in layout.buildings:
		out.append(label(layout, b))
	return out


static func label(layout: DistrictLayout, b: Dictionary) -> String:
	if String(b.get("name", "")) != "":
		return b.name
	var addr := address(layout, b)
	var kind: String = KIND.get(String(b.get("facade", "")), "")
	if kind == "" and int(b.get("storeys", 1)) >= 3 and String(b.get("facade", "")).begins_with("brick"):
		kind = "Flats"
	if addr == "":
		return kind if kind != "" else "Building"
	return "%s, %s" % [kind, addr] if kind != "" else addr


## A made-up street address: the street the front faces (or the nearest one),
## a number from the position along it (absolute world px, so neighbouring
## districts carry on the same numbering).
static func address(layout: DistrictLayout, b: Dictionary) -> String:
	var r: Rect2 = b.rect
	var front: Vector2 = b.get("front", Vector2.ZERO)
	var probe := r.get_center()
	if front != Vector2.ZERO:
		probe = r.get_center() + front * (absf(front.dot(r.size)) * 0.5 + 60.0)
	var best := {}
	var best_d := INF
	for st in layout.streets:
		var sr: Rect2 = st.rect
		var dx := maxf(0.0, maxf(sr.position.x - probe.x, probe.x - sr.end.x))
		var dy := maxf(0.0, maxf(sr.position.y - probe.y, probe.y - sr.end.y))
		var dist := Vector2(dx, dy).length()
		if dist < best_d:
			best_d = dist
			best = st
	if best.is_empty() or best_d > 260.0:
		return ""
	var sr2: Rect2 = best.rect
	var along_x := sr2.size.x >= sr2.size.y
	var t := r.get_center().x if along_x else r.get_center().y
	var number := int(floor((t + 6000.0) / 4.0)) * 2  # rising along the street, even
	var side := r.get_center().y < sr2.get_center().y if along_x else r.get_center().x < sr2.get_center().x
	if side:
		number += 1  # odd on the north / west side
	var street := String(best.name)
	for long in SHORT:
		street = street.replace(long, SHORT[long])
	return "%d %s" % [number, street]
