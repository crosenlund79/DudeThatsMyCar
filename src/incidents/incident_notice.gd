class_name IncidentNotice
extends RefCounted
## M010: whether Danny could have noticed one of the city's incidents - by
## its noise or by seeing it - so the minimap may point it out. Two men
## arguing are heard from a block off once it gets heated; a copper
## questioning somebody from half a block; a quiet handoff only when Danny is
## right there (it is never given away from afar). Pure.

const REACH := {
	"argument": {"talking": 420.0, "heated": 950.0, "parting": 420.0},
	"exchange": {"waiting": 170.0, "handing": 200.0, "leaving": 0.0},
	"stop": {"questioning": 620.0, "searching": 620.0, "leaving": 300.0},
}


static func reach(kind: String, phase: String) -> float:
	return float((REACH.get(kind, {}) as Dictionary).get(phase, 0.0))


static func noticed(inc: Dictionary, phase: String, danny: Vector2) -> bool:
	return danny.distance_to(inc.spot.pos) <= reach(inc.kind, phase)
