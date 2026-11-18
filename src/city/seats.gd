class_name Seats
extends RefCounted
## M010: where Danny can sit down - the benches in the street and the park,
## and in the rooms (and the café's chairs, later). A seat: {pos (where he
## sits), facing (which way he faces, radians), stand (where he stands up: in
## front of it, clear of it)}. Benches are drawn with their back at the top,
## so a bench at rotation r faces down-the-screen turned by r. Pure.

const KINDS := ["interiors/bench"]
## How far in front of a seat he stands, and how near he must be to sit.
const STAND_OFF := 28.0
const REACH := 36.0


static func of(layout: DistrictLayout) -> Array:
	var out := []
	for p in layout.props:
		if String(p.kind) in KINDS or String(p.get("seat", "")) != "":
			out.append(_seat(p.pos, float(p.get("rot", 0.0))))
	for plan in layout.interiors:
		for f in (plan as InteriorPlan).furniture:
			if String(f.kind) in KINDS:
				out.append(_seat(f.pos, float(f.get("rot", 0.0))))
	return out


static func _seat(pos: Vector2, rot: float) -> Dictionary:
	var face := Vector2.DOWN.rotated(rot)
	return {"pos": pos + face * 2.0, "facing": face.angle(), "stand": pos + face * STAND_OFF}


## The seat Danny stands at (within REACH of where he would stand up), or {}.
static func near(seats: Array, p: Vector2) -> Dictionary:
	var best := {}
	var best_d := REACH
	for s in seats:
		var dist := p.distance_to(s.stand)
		if dist < best_d:
			best_d = dist
			best = s
	return best
