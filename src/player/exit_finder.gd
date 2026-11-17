class_name ExitFinder
extends RefCounted
## Where a driver can step out of a car: beside the driver's door first, then
## the other door, behind, in front and the corners. A spot is only used when
## the caller's check says it is clear (open ground, nothing solid there, no
## wall between the seat and the spot). Pure apart from that check.

## Gap between the car's body and the person's centre when stepping out (px).
const CLEARANCE := 15.0


## Candidate spots in world space, in order of preference. half: half the
## car's body size (length / 2, width / 2), nose along +X; the driver sits on
## the left (-Y side when the nose points right).
static func candidates(car: Transform2D, half: Vector2, clearance: float = CLEARANCE) -> Array[Vector2]:
	var side := half.y + clearance
	var end := half.x + clearance
	var local: Array[Vector2] = [
		Vector2(4.0, -side), Vector2(4.0, side),
		Vector2(-end, 0.0), Vector2(end, 0.0),
		Vector2(-half.x * 0.6, -side), Vector2(-half.x * 0.6, side),
		Vector2(half.x * 0.6, -side), Vector2(half.x * 0.6, side),
		Vector2(-end, -side * 0.8), Vector2(-end, side * 0.8), Vector2(end, -side * 0.8), Vector2(end, side * 0.8),
	]
	var out: Array[Vector2] = []
	for o in local:
		out.append(car * o)
	return out


## The first clear spot, or null when there is no room anywhere round the car.
## is_clear: func(spot: Vector2) -> bool.
static func find(car: Transform2D, half: Vector2, is_clear: Callable) -> Variant:
	for p in candidates(car, half):
		if is_clear.call(p):
			return p
	return null
