extends GutTest
## M010 what Danny can have noticed of the city's incidents: a heated argument
## from a block off, a copper's questions from half a block, a handoff only up close.


func _inc(kind: String) -> Dictionary:
	return {"id": "x", "kind": kind, "spot": {"pos": Vector2.ZERO}}


func test_heard_or_seen() -> void:
	assert_true(IncidentNotice.noticed(_inc("argument"), "heated", Vector2(900, 0)), "shouting carries")
	assert_false(IncidentNotice.noticed(_inc("argument"), "talking", Vector2(900, 0)), "talking does not")
	assert_true(IncidentNotice.noticed(_inc("stop"), "questioning", Vector2(550, 0)))
	assert_false(IncidentNotice.noticed(_inc("exchange"), "handing", Vector2(400, 0)), "a quiet handoff is not given away")
	assert_true(IncidentNotice.noticed(_inc("exchange"), "handing", Vector2(150, 0)), "unless he is right there")
